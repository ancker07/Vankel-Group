import axios from 'axios';

// The central configuration for our API
// Local: http://localhost:8000
// Live: https://api.vanakelgroup.com
const API_HOST = 'https://api.vanakelgroup.com';

export const BASE_URL = `${API_HOST}/api`;
export const STORAGE_BASE_URL = `${API_HOST}/storage`;

export const apiClient = axios.create({
    baseURL: BASE_URL,
    headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    },
});


// Attach auth token if available
apiClient.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem('vanakel_authToken');
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error) => {
        return Promise.reject(error);
    }
);
