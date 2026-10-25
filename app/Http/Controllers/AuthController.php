<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Role;
use App\Models\User;
use App\Services\NotificationService as PushNotificationService;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

use App\Models\Email;
use App\Models\Building;
use App\Models\Intervention;
use App\Models\Notification;
use Illuminate\Support\Facades\Log;

class AuthController extends Controller
{
    protected $pushNotificationService;

    public function __construct(PushNotificationService $pushNotificationService)
    {
        $this->pushNotificationService = $pushNotificationService;
    }

    /**
     * Create a user account with any existing role (requires users.create).
     * The creator can only give a role whose permissions they hold themselves.
     */
    public function storeUser(Request $request)
    {
        $request->validate([
            'firstName' => 'required|string|max:255',
            'lastName' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'phone' => 'nullable|string|max:20',
            'role' => 'required|string|exists:roles,name',
            'companyName' => 'nullable|string|max:255',
        ]);

        $role = Role::where('name', $request->role)->firstOrFail();
        if ($message = User::roleLimitReached($role->name)) {
            return response()->json(['success' => false, 'message' => $message], 422);
        }
        if (!$request->user()->canAssignRole($role)) {
            return response()->json(['success' => false, 'message' => 'You cannot give this role: it has permissions you do not have.'], 403);
        }

        $user = User::create([
            'name' => $request->firstName . ' ' . $request->lastName,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => $request->role,
            'phone' => $request->phone,
            'company_name' => $request->companyName ?: ($role->portal === 'admin' ? 'Vankel Group' : null),
            'status' => 'APPROVED',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'User account created successfully.',
            'user' => $user
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
            'role' => ['required', 'string']
        ]);

        $user = User::where('email', $request->email)->first();

        if ($user && Hash::check($request->password, $user->password)) {
            $requestedRole = strtoupper($request->role);

            // The login screen picks a portal: SYNDIC = client app, ADMIN = staff app
            // (any staff role, incl. custom ones), SUPERADMIN = super admin only.
            $roleMatch = match ($requestedRole) {
                'SUPERADMIN' => $user->isSuperAdmin(),
                'SYNDIC' => $user->isClient(),
                default => !$user->isClient(),
            };

            if ($roleMatch) {
                // Check status
                if ($user->role !== 'SUPERADMIN' && $user->status === 'DEACTIVATED') {
                    return response()->json([
                        'success' => false,
                        'message' => 'Your account has been deactivated.'
                    ], 403);
                }

                return response()->json([
                    'success' => true,
                    'user' => $user->toAuthArray(),
                    'token' => $user->createToken('auth_token')->plainTextToken
                ]);
            }
        }

        return response()->json([
            'success' => false,
            'message' => 'Invalid credentials or role mismatch'
        ], 401);
    }

    /** The logged-in user with role, portal and permissions (apps refresh access with this). */
    public function me(Request $request)
    {
        return response()->json(['success' => true, 'user' => $request->user()->toAuthArray()]);
    }

    /** Change a user's role (requires users.update). */
    public function updateUserRole(Request $request, $id)
    {
        $request->validate(['role' => 'required|string|exists:roles,name']);

        $actor = $request->user();
        $user = User::findOrFail($id);
        $role = Role::where('name', $request->role)->firstOrFail();

        if ($user->isSuperAdmin() && !$actor->isSuperAdmin()) {
            return response()->json(['success' => false, 'message' => 'The super admin\'s role cannot be changed.'], 403);
        }
        if ($user->id === $actor->id) {
            return response()->json(['success' => false, 'message' => 'You cannot change your own role.'], 422);
        }
        if ($message = User::roleLimitReached($role->name, $user->id)) {
            return response()->json(['success' => false, 'message' => $message], 422);
        }
        if (!$actor->canAssignRole($role)) {
            return response()->json(['success' => false, 'message' => 'You cannot give this role: it has permissions you do not have.'], 403);
        }

        $user->update(['role' => $role->name]);
        // Sign the user out everywhere so the new access applies immediately
        $user->tokens()->delete();

        return response()->json(['success' => true, 'message' => 'Role updated.', 'user' => $user]);
    }

    /** Admin sets a new password for a user (requires users.update). Self-service reset is disabled. */
    public function resetPassword(Request $request, $id)
    {
        $request->validate(['password' => 'required|string|min:8']);

        $actor = $request->user();
        $user = User::findOrFail($id);

        if ($user->isSuperAdmin() && !$actor->isSuperAdmin()) {
            return response()->json(['success' => false, 'message' => 'The super admin\'s password can only be reset by a super admin.'], 403);
        }

        $user->update(['password' => Hash::make($request->password)]);
        // Sign the user out everywhere so the old password stops working immediately
        $user->tokens()->delete();

        return response()->json(['success' => true, 'message' => 'Password reset.']);
    }

    public function getPendingUsers()
    {
        $users = User::where('status', 'PENDING')
                     ->where('role', 'ADMIN')
                     ->get();
        return response()->json($users);
    }

    public function getSuperAdminStats()
    {
        return response()->json([
            'total_admins' => User::where('role', 'ADMIN')->where('status', 'APPROVED')->count(),
            'total_syndics' => User::where('role', 'SYNDIC')->where('status', 'APPROVED')->count(),
            'total_professionals' => User::where('role', 'PROFESSIONAL')->where('status', 'APPROVED')->count(),
            'pending_registrations' => User::where('status', 'PENDING')->count(),
            'total_emails' => Email::count(),
            'total_buildings' => Building::count(),
            'total_interventions' => Intervention::count(),
        ]);
    }

    public function getAllUsers(Request $request)
    {
        // Super admins see each other; nobody else sees super admin accounts
        $users = User::with('roleModel')
                     ->unless($request->user()->isSuperAdmin(), fn ($q) => $q->where('role', '!=', 'SUPERADMIN'))
                     ->whereKeyNot($request->user()->id)
                     ->orderBy('created_at', 'desc')
                     ->get()
                     ->each(function ($user) {
                         $user->setAttribute('role_label', $user->roleModel?->label ?? $user->role);
                         $user->setAttribute('portal', $user->portal());
                         $user->unsetRelation('roleModel');
                     });
        
        return response()->json($users);
    }

    public function approveUser($id)
    {
        $user = User::findOrFail($id);
        $user->update(['status' => 'APPROVED']);
        
        $title = 'Account Approved!';
        $body = 'Welcome to Vanakel Group. Your account has been approved by the Administrator.';

        if ($user->fcm_token) {
            $this->pushNotificationService->sendNotification(
                $user->fcm_token,
                $title,
                $body
            );
        }

        Notification::createWithTranslation([
            'user_id' => $user->id,
            'title' => $title,
            'body' => $body,
            'type' => 'account',
        ]);
        
        return response()->json(['success' => true, 'message' => 'User approved', 'user' => $user]);
    }

    public function rejectUser($id)
    {
        $user = User::findOrFail($id);
        $user->update(['status' => 'REJECTED']);

        $title = 'Account Status Update';
        $body = 'Your account registration request has been rejected by the Administrator.';

        if ($user->fcm_token) {
            $this->pushNotificationService->sendNotification(
                $user->fcm_token,
                $title,
                $body
            );
        }

        Notification::createWithTranslation([
            'user_id' => $user->id,
            'title' => $title,
            'body' => $body,
            'type' => 'account',
        ]);

        return response()->json(['success' => true, 'message' => 'User rejected', 'user' => $user]);
    }

    public function storeAdmin(Request $request)
    {
        $adminRole = Role::where('name', 'ADMIN')->first();
        if ($adminRole && !$request->user()->canAssignRole($adminRole)) {
            return response()->json(['success' => false, 'message' => 'You cannot create admin accounts.'], 403);
        }
        if ($message = User::roleLimitReached('ADMIN')) {
            return response()->json(['success' => false, 'message' => $message], 422);
        }

        $validated = $request->validate([
            'firstName' => 'required|string|max:255',
            'lastName' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'phone' => 'nullable|string|max:20',
        ]);

        $user = User::create([
            'name' => $request->firstName . ' ' . $request->lastName,
            'email' => $request->email,
            'password' => Hash::make('Vanakel2024!'), // Default password
            'role' => 'ADMIN',
            'phone' => $request->phone,
            'status' => 'APPROVED',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Admin account created successfully.',
            'user' => $user
        ]);
    }

    public function checkStatus(Request $request) 
    {
        $request->validate([
            'email' => 'nullable|email'
        ]);

        $user = $request->user();

        if ($user) {
            return response()->json([
                'success' => true,
                'status' => $user->status
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'User not found'
        ], 404);
    }

    public function updateProfile(Request $request)
    {
        $request->validate([
            'email' => 'nullable|email',
            'name' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:20',
            'bio' => 'nullable|string',
            'image' => 'nullable|image|max:2048'
        ]);

        $user = $request->user();

        if (!$user) {
            return response()->json(['success' => false, 'message' => 'User not found'], 404);
        }

        if ($request->has('name')) $user->name = $request->name;
        if ($request->has('phone')) $user->phone = $request->phone;
        if ($request->has('bio')) $user->bio = $request->bio;
        
        // Handle profile image upload
        try {
            if ($request->hasFile('image')) {
                $path = $request->file('image')->store('profiles', 'public');
                $user->image_url = $path;
            }
        } catch (\Exception $e) {}

        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully',
            'user' => $user
        ]);
    }
    public function getProfile(Request $request)
    {
        $request->validate([
            'email' => 'nullable|email'
        ]);

        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'phone' => $user->phone,
                'bio' => $user->bio,
                'image_url' => $user->image_url ? asset('storage/' . $user->image_url) : null,
                'company_name' => $user->company_name,
                'status' => $user->status,
                'role_label' => $user->roleModel?->label ?? $user->role,
                'portal' => $user->portal(),
                'permissions' => $user->permissionKeys(),
                'created_at' => $user->created_at,
                'properties_count' => \App\Models\Building::where('syndic_id', $user->id)->count(),
                'interventions_count' => \App\Models\Intervention::whereHas('building', function($q) use ($user) {
                    $q->where('syndic_id', $user->id);
                })->count(),
            ]
        ]);
    }

    public function changePassword(Request $request)
    {
        $request->validate([
            'email' => 'nullable|email',
            'current_password' => 'required',
            'new_password' => 'required|min:8|confirmed',
        ]);

        $user = $request->user();

        if (!$user || !Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'The current password provided is incorrect.'
            ], 422);
        }

        $user->update([
            'password' => Hash::make($request->new_password)
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Password changed successfully.'
        ]);
    }

    public function updateFcmToken(Request $request)
    {
        $request->validate([
            'email' => 'nullable|email',
            'fcm_token' => 'present|nullable|string',
        ]);

        $user = $request->user();

        if (!$user) {
            Log::warning("FCM: Attempted token update for non-existent user: {$user?->email}");
            return response()->json([
                'success' => false,
                'message' => 'User not found'
            ], 404);
        }

        $token = $request->fcm_token ?: null;

        if ($token) {
            // One phone belongs to one account: detach it from anyone else who used it before
            User::where('fcm_token', $token)->where('id', '!=', $user->id)->update(['fcm_token' => null]);
        }

        Log::info("FCM: Updating token for {$user->email}: " . ($token ? substr($token, 0, 15) . '...' : 'cleared'));
        $user->update(['fcm_token' => $token]);

        return response()->json([
            'success' => true,
            'message' => 'FCM token updated successfully.'
        ]);
    }
}
  
