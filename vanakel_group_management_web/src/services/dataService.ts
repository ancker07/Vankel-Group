
const API_URL = 'vanakelgroup.com/api';

export const dataService = {
    getBuildings: async () => {
        const response = await fetch(`${API_URL}/buildings`);
        return response.json();
    },
    getSyndics: async () => {
        const response = await fetch(`${API_URL}/syndics`);
        return response.json();
    },
    getMissions: async () => {
        const response = await fetch(`${API_URL}/missions`);
        return response.json();
    },
    getInterventions: async () => {
        const response = await fetch(`${API_URL}/interventions`);
        return response.json();
    },
    approveMission: async (id: string, scheduledDate?: string) => {
        const response = await fetch(`${API_URL}/missions/${id}/approve`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ scheduled_date: scheduledDate })
        });
        return response.json();
    },
    rejectMission: async (id: string) => {
        const response = await fetch(`${API_URL}/missions/${id}/reject`, { method: 'POST' });
        return response.json();
    },
    updateIntervention: async (id: string, payload: any) => {
        const response = await fetch(`${API_URL}/interventions/${id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        return response.json();
    },
    getPendingUsers: async () => {
        const response = await fetch(`${API_URL}/users/pending`);
        return response.json();
    },
    approveUser: async (id: string) => {
        const response = await fetch(`${API_URL}/users/${id}/approve`, { method: 'POST' });
        return response.json();
    },
    rejectUser: async (id: string) => {
        const response = await fetch(`${API_URL}/users/${id}/reject`, { method: 'POST' });
        return response.json();
    }
}
