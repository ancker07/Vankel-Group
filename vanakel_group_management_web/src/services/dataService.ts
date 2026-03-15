
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
    getEmailThread: async (threadId: string) => {
        const response = await apiClient.get(`/emails/threads/${encodeURIComponent(threadId)}`);
        return response.data;
    },
    deleteEmail: async (id: number) => {
        const response = await apiClient.delete(`/emails/${id}`);
        return response.data;
    },
    replyToEmail: async (id: number, body: string, account: 'no-reply' | 'redirection', attachments: File[] = []) => {
        const formData = new FormData();
        formData.append('body', body);
        formData.append('account', account);
        attachments.forEach((file, index) => {
            formData.append(`attachments[${index}]`, file);
        });

        const response = await apiClient.post(`/emails/${id}/reply`, formData, {
            headers: {
                'Content-Type': 'multipart/form-data',
            },
        });
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
    },
    getMaintenancePlans: async () => {
        const response = await apiClient.get('/maintenance-plans');
        return response.data;
    },
    createMaintenancePlan: async (planData: any) => {
        const response = await apiClient.post('/maintenance-plans', planData);
        return response.data;
    },
    updateMaintenancePlan: async (id: string, planData: any) => {
        const response = await apiClient.put(`/maintenance-plans/${id}`, planData);
        return response.data;
    },
    deleteMaintenancePlan: async (id: string) => {
        const response = await apiClient.delete(`/maintenance-plans/${id}`);
        return response.data;
    },
    submitContact: async (contact: any) => {
        const response = await apiClient.post('/contacts', contact);
        return response.data;
    },
    getContacts: async () => {
        const response = await apiClient.get('/contacts');
        return response.data;
    },
    deleteContact: async (id: string) => {
        const response = await apiClient.delete(`/contacts/${id}`);
        return response.data;
    },
    sendPushNotification: async (payload: { title: string, body: string, target: 'all' | 'specific', user_ids?: number[] }) => {
        const response = await apiClient.post('/superadmin/send-notification', payload);
        return response.data;
    },
    getNotificationHistory: async () => {
        const response = await apiClient.get('/superadmin/notifications/history');
        return response.data;
    },
    sendTestNotification: async (payload: { token: string, title: string, body: string }) => {
        const response = await apiClient.post('/superadmin/test-notification', payload);
        return response.data;
    }
};

