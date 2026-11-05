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
        $isTechnician = $request->role === 'PROFESSIONAL';

        $request->validate([
            'firstName' => 'required|string|max:255',
            'lastName' => 'nullable|string|max:255',
            // technicians sign in with a username (no real e-mail needed); everyone else uses an e-mail
            'email' => [$isTechnician ? 'nullable' : 'required', 'string', 'email', 'max:255', 'unique:users'],
            'username' => [$isTechnician ? 'required_without:email' : 'nullable', 'string', 'min:3', 'max:50', 'regex:/^[A-Za-z0-9._-]+$/'],
            'password' => 'required|string|min:8',
            'phone' => 'nullable|string|max:20',
            'role' => ['required', 'string', \Illuminate\Validation\Rule::in(\App\Support\PermissionCatalog::FIXED_ROLES)],
            'companyName' => 'nullable|string|max:255',
        ]);

        $email = $request->email;
        if ($isTechnician) {
            $username = strtolower(trim((string) $request->input('username')));
            $email = $request->filled('email') ? $request->email : $username . '@technician.vankel';
            $login = strtolower(explode('@', $email)[0]);
            if (User::technicianByLogin($login, true) || User::withTrashed()->where('email', $email)->exists()) {
                return response()->json([
                    'success' => false,
                    'message' => __('This username is already taken.'),
                    'errors' => ['username' => [__('This username is already taken.')]],
                ], 422);
            }
        }

        $role = Role::where('name', $request->role)->firstOrFail();
        if ($message = User::roleLimitReached($role->name)) {
            return response()->json(['success' => false, 'message' => $message], 422);
        }
        if (!$request->user()->canAssignRole($role)) {
            return response()->json(['success' => false, 'message' => __('Only a super admin can give this role.')], 403);
        }

        $user = User::create([
            'name' => trim($request->firstName . ' ' . $request->lastName),
            'email' => $email,
            'password' => Hash::make($request->password),
            'role' => $request->role,
            'phone' => $request->phone,
            'company_name' => $request->companyName ?: ($role->portal === 'admin' ? 'Vankel Group' : null),
            'status' => 'APPROVED',
        ]);

        return response()->json([
            'success' => true,
            'message' => __('User account created successfully.'),
            'user' => $user
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => ['nullable', 'string'],
            'username' => ['nullable', 'string'],
            'password' => ['required'],
            'role' => ['required', 'string'],
            'fcm_token' => ['nullable', 'string'],
            'app' => ['nullable', 'string'],
        ]);

        $identifier = trim((string) ($request->input('username') ?: $request->input('email')));
        if ($identifier === '') {
            throw ValidationException::withMessages(['email' => [__('Username or email is required.')]]);
        }

        $user = User::where('email', $identifier)->first();
        if (!$user && !str_contains($identifier, '@')) {
            $user = User::technicianByLogin(strtolower($identifier));
        }

        if ($user && Hash::check($request->password, $user->password)) {
            $requestedRole = strtoupper($request->role);

            // The login screens offer two choices: ADMIN = staff app (any staff role, incl. custom
            // ones) and PROFESSIONAL = technician accounts only. SUPERADMIN = super admin only.
            // (SYNDIC = client app is no longer offered, but is still understood by the server.)
            // The phone app is only for admins and technicians: each choice takes exactly that role.
            // (Super admins use the website; the legacy client role has no phone app any more.)
            $mobile = strtolower((string) $request->input('app')) === 'mobile';
            if ($mobile && !in_array($user->role, ['ADMIN', 'PROFESSIONAL'], true)) {
                return response()->json(['success' => false, 'message' => __('This account cannot sign in on the mobile app.')], 403);
            }

            $roleMatch = match (true) {
                $mobile => $requestedRole === 'PROFESSIONAL' ? $user->role === 'PROFESSIONAL' : $user->role === 'ADMIN',
                default => match ($requestedRole) {
                    'SUPERADMIN' => $user->isSuperAdmin(),
                    'SYNDIC' => $user->isClient(),
                    'PROFESSIONAL' => $user->role === 'PROFESSIONAL',
                    default => !$user->isClient(),
                },
            };

            if ($roleMatch) {
                $this->rememberLanguage($user, $request);

                // Check status
                if ($user->role !== 'SUPERADMIN' && $user->status === 'DEACTIVATED') {
                    return response()->json([
                        'success' => false,
                        'message' => __('Your account has been deactivated.')
                    ], 403);
                }

                // Register this phone for push right at login so it can't be lost to a later failed call
                if ($request->filled('fcm_token')) {
                    User::where('fcm_token', $request->fcm_token)->where('id', '!=', $user->id)->update(['fcm_token' => null]);
                    $user->update(['fcm_token' => $request->fcm_token]);
                    Log::info("FCM: token registered at login for {$user->email}");
                } else {
                    Log::warning("FCM: login without a device token for {$user->email}");
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
            'message' => __('Invalid credentials or role mismatch')
        ], 401);
    }

    /**
     * An account that has no saved language yet (e.g. a technician an admin created) gets the language the app is
     * showing, so push notifications and e-mails follow it from the first moment. A saved choice is never overwritten.
     */
    private function rememberLanguage(User $user, Request $request): void
    {
        if (!$user->locale) {
            $user->update(['locale' => \App\Http\Middleware\SetLocale::resolve($request)]);
        }
    }

    /** The logged-in user with role, portal and permissions (apps refresh access with this). */
    public function me(Request $request)
    {
        return response()->json(['success' => true, 'user' => $request->user()->toAuthArray()]);
    }

    /** Change a user's role (requires users.update). */
    public function updateUserRole(Request $request, $id)
    {
        $request->validate(['role' => ['required', 'string', \Illuminate\Validation\Rule::in(\App\Support\PermissionCatalog::FIXED_ROLES)]]);

        $actor = $request->user();
        $user = User::findOrFail($id);
        $role = Role::where('name', $request->role)->firstOrFail();

        if ($user->isSuperAdmin() && !$actor->isSuperAdmin()) {
            return response()->json(['success' => false, 'message' => __('The super admin\'s role cannot be changed.')], 403);
        }
        if ($user->id === $actor->id) {
            return response()->json(['success' => false, 'message' => __('You cannot change your own role.')], 422);
        }
        if (!$actor->canManageUser($user)) {
            return response()->json(['success' => false, 'message' => __('You cannot manage a user with more access than you.')], 403);
        }
        if ($message = User::roleLimitReached($role->name, $user->id)) {
            return response()->json(['success' => false, 'message' => $message], 422);
        }
        if (!$actor->canAssignRole($role)) {
            return response()->json(['success' => false, 'message' => __('Only a super admin can give this role.')], 403);
        }

        $user->update(['role' => $role->name]);
        // Sign the user out everywhere so the new access applies immediately
        $user->tokens()->delete();

        return response()->json(['success' => true, 'message' => __('Role updated.'), 'user' => $user]);
    }

    /** Admin sets a new password for a user (requires users.update). Self-service reset is disabled. */
    public function resetPassword(Request $request, $id)
    {
        $request->validate(['password' => 'required|string|min:8']);

        $actor = $request->user();
        $user = User::findOrFail($id);

        if ($user->isSuperAdmin() && !$actor->isSuperAdmin()) {
            return response()->json(['success' => false, 'message' => __('The super admin\'s password can only be reset by a super admin.')], 403);
        }
        if (!$actor->canManageUser($user)) {
            return response()->json(['success' => false, 'message' => __('You cannot manage a user with more access than you.')], 403);
        }

        $user->update(['password' => Hash::make($request->password)]);
        // Sign the user out everywhere so the old password stops working immediately
        $user->tokens()->delete();

        return response()->json(['success' => true, 'message' => __('Password reset.')]);
    }

    /** Soft-delete a user (requires users.update). Their data stays intact in intervention history. */
    public function deleteUser(Request $request, $id)
    {
        $actor = $request->user();
        $user = User::findOrFail($id);

        if ($user->id === $actor->id) {
            return response()->json(['success' => false, 'message' => __('You cannot delete your own account.')], 422);
        }
        if ($user->isSuperAdmin() && !$actor->isSuperAdmin()) {
            return response()->json(['success' => false, 'message' => __('The super admin\'s account cannot be deleted.')], 403);
        }
        if (!$actor->canManageUser($user)) {
            return response()->json(['success' => false, 'message' => __('You cannot manage a user with more access than you.')], 403);
        }

        $user->tokens()->delete();
        $user->delete();

        return response()->json(['success' => true, 'message' => __('User deleted.')]);
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

    public function approveUser(Request $request, $id)
    {
        $user = User::findOrFail($id);
        if (!$request->user()->canManageUser($user)) {
            return response()->json(['success' => false, 'message' => __('You cannot manage a user with more access than you.')], 403);
        }
        $user->update(['status' => 'APPROVED']);
        
        $title = 'Account Approved!';
        $body = 'Welcome to Vanakel Group. Your account has been approved by the Administrator.';
        $translated = (new \App\Services\AiService())->translateToFill($title, $body);

        if ($user->fcm_token) {
            $this->pushNotificationService->sendNotification(
                $user->fcm_token,
                PushNotificationService::localize($translated['title'] ?? [], $user->locale, $title),
                PushNotificationService::localize($translated['description'] ?? [], $user->locale, $body)
            );
        }

        Notification::createWithTranslation([
            'user_id' => $user->id,
            'title' => $title,
            'body' => $body,
            'type' => 'account',
        ]);
        
        return response()->json(['success' => true, 'message' => __('User approved'), 'user' => $user]);
    }

    public function rejectUser(Request $request, $id)
    {
        $user = User::findOrFail($id);
        if (!$request->user()->canManageUser($user)) {
            return response()->json(['success' => false, 'message' => __('You cannot manage a user with more access than you.')], 403);
        }
        $user->update(['status' => 'REJECTED']);

        $title = 'Account Status Update';
        $body = 'Your account registration request has been rejected by the Administrator.';
        $translated = (new \App\Services\AiService())->translateToFill($title, $body);

        if ($user->fcm_token) {
            $this->pushNotificationService->sendNotification(
                $user->fcm_token,
                PushNotificationService::localize($translated['title'] ?? [], $user->locale, $title),
                PushNotificationService::localize($translated['description'] ?? [], $user->locale, $body)
            );
        }

        Notification::createWithTranslation([
            'user_id' => $user->id,
            'title' => $title,
            'body' => $body,
            'type' => 'account',
        ]);

        return response()->json(['success' => true, 'message' => __('User rejected'), 'user' => $user]);
    }

    public function storeAdmin(Request $request)
    {
        $adminRole = Role::where('name', 'ADMIN')->first();
        if ($adminRole && !$request->user()->canAssignRole($adminRole)) {
            return response()->json(['success' => false, 'message' => __('You cannot create admin accounts.')], 403);
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
            'message' => __('Admin account created successfully.'),
            'user' => $user
        ]);
    }

    public function checkStatus(Request $request) 
    {
        $request->validate([
            'email' => 'nullable|string'
        ]);

        $user = $request->user();

        if ($user) {
            $this->rememberLanguage($user, $request);

            return response()->json([
                'success' => true,
                'status' => $user->status
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => __('User not found')
        ], 404);
    }

    public function updateProfile(Request $request)
    {
        $request->validate([
            'email' => 'nullable|string',
            'name' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:20',
            'bio' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:' . \App\Support\UploadRules::AVATAR_MAX_KB,
        ]);

        $user = $request->user();

        if (!$user) {
            return response()->json(['success' => false, 'message' => __('User not found')], 404);
        }

        if ($request->has('name')) $user->name = $request->name;
        if ($request->has('phone')) $user->phone = $request->phone;
        if ($request->has('bio')) $user->bio = $request->bio;
        
        // Handle profile image upload
        if ($request->hasFile('image')) {
            $previous = $user->image_url;
            try {
                $user->image_url = $request->file('image')->store('profiles', 'public');
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::error("Profile image upload failed for user {$user->id}: " . $e->getMessage());

                return response()->json(['success' => false, 'message' => __('The profile picture could not be saved. Please try again.')], 500);
            }
            // do not keep orphaned pictures
            if ($previous && $previous !== $user->image_url && str_starts_with($previous, 'profiles/')) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete($previous);
            }
        }

        $user->save();

        return response()->json([
            'success' => true,
            'message' => __('Profile updated successfully'),
            'user' => $user
        ]);
    }
    public function getProfile(Request $request)
    {
        $request->validate([
            'email' => 'nullable|string'
        ]);

        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => __('User not found')
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
            'email' => 'nullable|string',
            'current_password' => 'required',
            'new_password' => 'required|min:8|confirmed',
        ]);

        $user = $request->user();

        if (!$user || !Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => __('The current password provided is incorrect.')
            ], 422);
        }

        $user->update([
            'password' => Hash::make($request->new_password)
        ]);

        return response()->json([
            'success' => true,
            'message' => __('Password changed successfully.')
        ]);
    }

    /** Save the language the user picked during onboarding, used for all future notifications. */
    public function updateLocale(Request $request)
    {
        $request->validate([
            'locale' => 'required|string|in:en,fr,nl',
        ]);

        $user = $request->user();

        if (!$user) {
            return response()->json(['success' => false, 'message' => __('User not found')], 404);
        }

        $user->update(['locale' => $request->locale]);

        return response()->json([
            'success' => true,
            'message' => __('Locale updated successfully.'),
        ]);
    }

    public function updateFcmToken(Request $request)
    {
        $request->validate([
            'email' => 'nullable|string',
            'fcm_token' => 'present|nullable|string',
        ]);

        $user = $request->user();

        if (!$user) {
            Log::warning("FCM: Attempted token update for non-existent user: {$user?->email}");
            return response()->json([
                'success' => false,
                'message' => __('User not found')
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
            'message' => __('FCM token updated successfully.')
        ]);
    }
}
  
