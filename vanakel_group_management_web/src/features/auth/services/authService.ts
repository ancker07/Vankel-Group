
import { SignupRequest } from '@/types';

// This is a mock implementation that simulates API calls to a Laravel backend
// In a real scenario, this would use axios or fetch to hit actual endpoints

const API_URL = 'http://localhost:8000/api';

export const authService = {
    signup: async (data: SignupRequest): Promise<{ success: boolean; message: string }> => {
        try {
            const response = await fetch(`${API_URL}/signup`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                body: JSON.stringify(data),
            });
            const result = await response.json();
            let errorMessage = result.message || 'Signup failed';
            if (!response.ok && result.errors) {
                const firstErrorKey = Object.keys(result.errors)[0];
                errorMessage = result.errors[firstErrorKey][0];
            }

            return {
                success: response.ok && (result.success !== false),
                message: errorMessage
            };
        } catch (error) {
            return { success: false, message: 'Could not connect to the server' };
        }
    },

    sendOtp: async (email: string): Promise<{ success: boolean; message: string }> => {
        try {
            const response = await fetch(`${API_URL}/send-otp`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                body: JSON.stringify({ email }),
            });
            const result = await response.json();
            return {
                success: response.ok && result.success,
                message: result.message || 'Failed to send OTP'
            };
        } catch (error) {
            return { success: false, message: 'Could not connect to the server' };
        }
    },

    verifyOtp: async (email: string, otp: string, userData?: any): Promise<{ success: boolean; message: string }> => {
        try {
            const response = await fetch(`${API_URL}/verify-otp`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                body: JSON.stringify({ email, otp, ...userData }),
            });
            const result = await response.json();
            return {
                success: response.ok && result.success,
                message: result.message || 'Invalid verification code'
            };
        } catch (error) {
            return { success: false, message: 'Could not connect to the server' };
        }
    }
};
