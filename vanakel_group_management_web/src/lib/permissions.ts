import { useSyncExternalStore } from 'react';

// Permissions of the logged-in user, as returned by the API (/login, /me).
// The backend enforces every permission; this only shows / hides UI.

const STORAGE_KEY = 'vanakel_permissions';
const ROLE_LABEL_KEY = 'vanakel_roleLabel';
const USER_ID_KEY = 'vanakel_userId';

/** Id of the logged-in user (the users list does not include yourself). */
export const getAuthUserId = (): string | undefined => {
    try { return localStorage.getItem(USER_ID_KEY) || undefined; } catch { return undefined; }
};

const read = (): string[] => {
    try {
        return JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
    } catch {
        return [];
    }
};

let permissions: string[] = read();
const listeners = new Set<() => void>();

const notify = () => listeners.forEach(l => l());

export const setAuthUser = (user: { id?: number | string; permissions?: string[]; role_label?: string } | null) => {
    permissions = user?.permissions || [];
    try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(permissions));
        if (user?.role_label) localStorage.setItem(ROLE_LABEL_KEY, user.role_label);
        if (user?.id !== undefined && user?.id !== null) localStorage.setItem(USER_ID_KEY, String(user.id));
    } catch { /* storage unavailable */ }
    notify();
};

export const clearAuthUser = () => {
    permissions = [];
    try {
        localStorage.removeItem(STORAGE_KEY);
        localStorage.removeItem(ROLE_LABEL_KEY);
        localStorage.removeItem(USER_ID_KEY);
    } catch { /* storage unavailable */ }
    notify();
};

/** True if the user has at least one of the given permissions. */
export const can = (...keys: string[]) => keys.some(k => permissions.includes(k));

const subscribe = (listener: () => void) => {
    listeners.add(listener);
    return () => listeners.delete(listener);
};

/** Re-renders the component when the permissions change; returns `can`. */
export const usePermissions = () => {
    useSyncExternalStore(subscribe, () => permissions);
    return can;
};
