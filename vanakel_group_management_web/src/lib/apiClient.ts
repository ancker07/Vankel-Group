import axios from 'axios';
import { loadingStore } from '@/lib/loadingStore';

// The central configuration for our API
// Local: http://localhost:8000
// Live: https://api.vanakelgroup.com
const API_HOST = 'https://api.vanakelgroup.com';

export const BASE_URL = `${API_HOST}/api`;
export const STORAGE_BASE_URL = `${API_HOST}/storage`;

export const apiClient = axios.create({
    baseURL: BASE_URL,
    headers: {
        'Accept': 'application/json',
    },
});


/** The server answers (validation errors, messages) in the language the page is showing. */
export const setApiLanguage = (lang: string) => {
    apiClient.defaults.headers.common['Accept-Language'] = lang.toLowerCase();
};

// Attach auth token if available
apiClient.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem('vanakel_authToken');
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        // Background work (dictation uploads) must not flash the loading indicator
        if (!(config as any).silent) loadingStore.start(config.method);
        return config;
    },
    (error) => {
        return Promise.reject(error);
    }
);

// Every request that started must end, whether it succeeded or failed
apiClient.interceptors.response.use(
    (response) => {
        if (!(response.config as any)?.silent) loadingStore.end(response.config?.method);
        return response;
    },
    (error) => {
        if (!error?.config?.silent) loadingStore.end(error?.config?.method);
        return Promise.reject(error);
    }
);
