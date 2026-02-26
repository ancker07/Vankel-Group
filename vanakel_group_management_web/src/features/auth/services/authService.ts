
import { SignupRequest } from '@/types';
import { apiClient } from '@/lib/apiClient';

export const authService = {
    login: async (credentials: any) => {
        const response = await apiClient.post('/login', credentials);
        return response.data;
    },

    checkStatus: async (email: string) => {
        const response = await apiClient.post('/check-status', { email });
        return response.data;
    },

    signup: async (data: SignupRequest): Promise<{ success: boolean; message: string }> => {
        try {
            const response = await apiClient.post('/signup', data);
            const result = response.data;

            return {
                success: result.success !== false,
                message: result.message || 'Signup successful'
            };
        } catch (error: any) {
            let errorMessage = 'Could not connect to the server';

            if (error.response && error.response.data) {
                const result = error.response.data;
                errorMessage = result.message || 'Signup failed';

                if (result.errors) {
                    const firstErrorKey = Object.keys(result.errors)[0];
                    errorMessage = result.errors[firstErrorKey][0];
                }
            }

            return { success: false, message: errorMessage };
        }
    },

    sendOtp: async (email: string): Promise<{ success: boolean; message: string }> => {
        try {
            const response = await apiClient.post('/send-otp', { email });
            const result = response.data;

            return {
                success: result.success,
                message: result.message || 'OTP sent successfully'
            };
        } catch (error: any) {
            const msg = error.response?.data?.message || 'Could not connect to the server';
            return { success: false, message: msg };
        }
    },

    verifyOtp: async (email: string, otp: string, userData?: any): Promise<{ success: boolean; message: string }> => {
        try {
            const response = await apiClient.post('/verify-otp', { email, otp, ...userData });
            const result = response.data;

            return {
                success: result.success,
                message: result.message || 'Verification successful'
            };
        } catch (error: any) {
            const msg = error.response?.data?.message || 'Invalid verification code';
            return { success: false, message: msg };
        }
    },

    updateProfile: async (formData: FormData): Promise<{ success: boolean; message: string; user?: any }> => {
        try {
            const response = await apiClient.post('/profile/update', formData, {
                headers: {
                    'Content-Type': 'multipart/form-data'
                }
            });
            const result = response.data;
            return {
                success: result.success,
                message: result.message || 'Profile updated successfully',
                user: result.user
            };
        } catch (error: any) {
            const msg = error.response?.data?.message || 'Failed to update profile';
            return { success: false, message: msg };
        }
    },

    getProfile: async (email: string): Promise<{ success: boolean; user?: any; message?: string }> => {
        try {
            const response = await apiClient.post('/profile/details', { email });
            return response.data;
        } catch (error: any) {
            const msg = error.response?.data?.message || 'Failed to fetch profile';
            return { success: false, message: msg };
        }
    }
};



