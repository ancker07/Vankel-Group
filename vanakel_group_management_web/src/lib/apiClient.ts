import axios from 'axios';

// The central configuration for our API
const BASE_URL = 'https://api.vanakelgroup.com/api';

export const apiClient = axios.create({
    baseURL: BASE_URL,
    headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    },
});

// We can add interceptors here later if we need to attach an auth token
// apiClient.interceptors.request.use(
//     (config) => {
//         const token = localStorage.getItem('vanakel_authToken');
//         if (token) {
//             config.headers.Authorization = `Bearer ${token}`;
//         }
//         return config;
//     }
// );
