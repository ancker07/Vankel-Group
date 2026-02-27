
import { apiClient } from '@/lib/apiClient';

export const dataService = {
    getBuildings: async () => {
        const response = await apiClient.get('/buildings');
        return response.data;
    },
    getSyndics: async () => {
        const response = await apiClient.get('/syndics');
        return response.data;
    },
    getMissions: async () => {
        const response = await apiClient.get('/missions');
        return response.data;
    },
    getInterventions: async () => {
        const response = await apiClient.get('/interventions');
        return response.data;
    },
    createIntervention: async (formData: FormData) => {
        const response = await apiClient.post('/interventions', formData, {
            headers: {
                'Content-Type': 'multipart/form-data'
            }
        });
        return response.data;
    },
    approveMission: async (id: string, scheduledDate?: string) => {
        const response = await apiClient.post(`/missions/${id}/approve`, { scheduled_date: scheduledDate });
        return response.data;
    },
    rejectMission: async (id: string) => {
        const response = await apiClient.post(`/missions/${id}/reject`);
        return response.data;
    },
    updateIntervention: async (id: string, payload: any) => {
        const response = await apiClient.put(`/interventions/${id}`, payload);
        return response.data;
    },
    getPendingUsers: async () => {
        const response = await apiClient.get('/users/pending');
        return response.data;
    },
    approveUser: async (id: string) => {
        const response = await apiClient.post(`/users/${id}/approve`);
        return response.data;
    },
    rejectUser: async (id: string) => {
        const response = await apiClient.post(`/users/${id}/reject`);
        return response.data;
    },
    sendInterventionReport: async (id: string) => {
        const response = await apiClient.post(`/interventions/${id}/send-report`);
        return response.data;
    }
};

