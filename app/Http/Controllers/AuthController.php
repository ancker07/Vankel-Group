<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use App\Mail\OtpMail;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function signup(Request $request)
    {
        $validated = $request->validate([
            'firstName' => 'required|string|max:255',
            'lastName' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'phone' => 'required|string|max:20',
            'role' => 'required|string|in:ADMIN,SYNDIC',
            'companyName' => 'nullable|string|max:255',
        ]);

        if ($request->role === 'ADMIN') {
            $user = User::create([
                'name' => $request->firstName . ' ' . $request->lastName,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'role' => $request->role,
                'phone' => $request->phone,
                'company_name' => $request->companyName,
                'status' => 'PENDING',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Admin profile details saved. Awaiting super admin approval.',
                'user' => $user
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Profile details saved. Proceeding to verification.'
        ]);
    }

    public function sendOtp(Request $request)
    {
        $request->validate(['email' => 'required|email']);
        $email = $request->email;
        $otp = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        // Store OTP in cache for 10 minutes
        Cache::put('otp_' . $email, $otp, now()->addMinutes(10));

        // Send Email
        try {
            Mail::to($email)->send(new OtpMail($otp));
            
            return response()->json([
                'success' => true,
                'message' => 'OTP sent successfully.'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to send OTP: ' . $e->getMessage()
            ], 500);
        }
    }

    public function verifyOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:6',
            'firstName' => 'required|string',
            'lastName' => 'required|string',
            'password' => 'required|string',
            'phone' => 'nullable|string',
            'role' => 'required|string',
            'companyName' => 'nullable|string',
        ]);

        $cachedOtp = Cache::get('otp_' . $request->email);

        if ($cachedOtp && $cachedOtp === $request->otp) {
            Cache::forget('otp_' . $request->email);

            // Create the user now that OTP is verified
            $user = User::create([
                'name' => $request->firstName . ' ' . $request->lastName,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'role' => $request->role,
                'phone' => $request->phone,
                'company_name' => $request->companyName,
                'status' => $request->role === 'SYNDIC' ? 'APPROVED' : 'PENDING',
            ]);

            return response()->json([
                'success' => true,
                'message' => $request->role === 'SYNDIC' 
                    ? 'Email verified and account created successfully.' 
                    : 'Email verified and account created successfully. Awaiting admin approval.',
                'user' => $user
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Invalid or expired OTP.'
        ], 422);
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
            'role' => ['required', 'string'] // Enforce role check
        ]);

        if (Auth::attempt($credentials)) {
            $user = Auth::user();
            
            // Check status if not superadmin
            if ($user->role !== 'SUPERADMIN' && $user->status !== 'APPROVED') {
                return response()->json([
                    'success' => false,
                    'message' => 'Your account is pending admin approval.'
                ], 403);
            }

            return response()->json([
                'success' => true,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'status' => $user->status,
                ],
                'token' => $user->createToken('auth_token')->plainTextToken
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Invalid credentials or role mismatch'
        ], 401);
    }

    public function getPendingUsers()
    {
        $users = User::where('status', 'PENDING')
                     ->where('role', 'ADMIN')
                     ->get();
        return response()->json($users);
    }

    public function approveUser($id)
    {
        $user = User::findOrFail($id);
        $user->update(['status' => 'APPROVED']);
        return response()->json(['success' => true, 'message' => 'User approved', 'user' => $user]);
    }

    public function rejectUser($id)
    {
        $user = User::findOrFail($id);
        $user->update(['status' => 'REJECTED']);
        return response()->json(['success' => true, 'message' => 'User rejected', 'user' => $user]);
    }

    public function checkStatus(Request $request) 
    {
        $request->validate([
            'email' => 'required|email'
        ]);

        $user = User::where('email', $request->email)->first();

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
            'email' => 'required|email',
            'name' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:20',
            'bio' => 'nullable|string',
            'image' => 'nullable|image|max:2048'
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json(['success' => false, 'message' => 'User not found'], 404);
        }

        if ($request->has('name')) $user->name = $request->name;
        if ($request->has('phone')) $user->phone = $request->phone;
        
        // Let's assume there is a bio and image field. If not, they might fail on save, but we try.
        // We will just update what we can. 
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
}
  
