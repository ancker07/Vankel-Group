
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
        const response = await apiClient.post('/interventions', formData);
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
        let method = 'PUT';
        let body = payload;

        if (payload instanceof FormData) {
            payload.append('_method', 'PUT');
            method = 'POST';
        }

        const response = await (method === 'POST'
            ? apiClient.post(`/interventions/${id}`, body)
            : apiClient.put(`/interventions/${id}`, body));

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
    },
    getEmails: async () => {
        const response = await apiClient.get('/emails');
        return response.data;
    },
    getEmailById: async (id: number) => {
        const response = await apiClient.get(`/emails/${id}`);
        return response.data;
    },
    deleteEmail: async (id: number) => {
        const response = await apiClient.delete(`/emails/${id}`);
        return response.data;
    },
    replyToEmail: async (id: number, body: string, account: 'no-reply' | 'redirection') => {
        const response = await apiClient.post(`/emails/${id}/reply`, { body, account });
        return response.data;
    },
    getAiSettings: async () => {
        const response = await apiClient.get('/settings/ai');
        return response.data;
    },
    updateAiSettings: async (settings: { model: string, apiKey: string }) => {
        const response = await apiClient.post('/settings/ai', settings);
        return response.data;
    },

    syncEmails: async () => {
        const response = await apiClient.post('/emails/sync');
        return response.data;
    },
    ingestEmail: async (id: number) => {
        const response = await apiClient.post(`/emails/${id}/ingest`);
        return response.data;
    },
    ingestAllEmails: async () => {
        const response = await apiClient.post('/emails/ingest-all');
        return response.data;
    },
    getSuperAdminStats: async () => {
        const response = await apiClient.get('/superadmin/stats');
        return response.data;
    },
    getAllUsers: async () => {
        const response = await apiClient.get('/users/all');
        return response.data;
    },
    createAdmin: async (adminData: any) => {
        const response = await apiClient.post('/superadmin/admins', adminData);
        return response.data;
    }
};

