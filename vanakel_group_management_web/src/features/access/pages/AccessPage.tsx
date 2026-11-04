import React, { useEffect, useMemo, useState } from 'react';
import { KeyRound, Users, Plus, Trash2, X, ShieldCheck, Lock, Search, RotateCcw } from 'lucide-react';
import { dataService } from '@/services/dataService';
import { TRANSLATIONS } from '@/utils/constants';
import { Language } from '@/types';
import { usePermissions } from '@/lib/permissions';

interface RoleRow {
    id: number;
    name: string;
    label: string;
    description: string | null;
    portal: 'admin' | 'syndic';
    is_system: boolean;
    is_super_admin: boolean;
    assignable: boolean;
    full: boolean;
    users_count: number;
    permissions: string[];
}

interface UserRow {
    id: number;
    name: string;
    email: string;
    phone: string | null;
    role: string;
    role_label?: string;
    status: string;
}

const inputClass = 'w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2.5 text-sm text-white focus:border-brand-green outline-none transition-all';
const labelClass = 'text-[10px] font-black text-zinc-500 uppercase tracking-widest';

const errorMessage = (e: any) =>
    e?.response?.data?.message || Object.values(e?.response?.data?.errors || {}).flat()[0] || 'Something went wrong.';

const AccessPage: React.FC<{ lang: Language }> = ({ lang }) => {
    const t = TRANSLATIONS[lang];
    const can = usePermissions();

    const [tab, setTab] = useState<'users' | 'roles'>('users');
    const [roles, setRoles] = useState<RoleRow[]>([]);
    const [users, setUsers] = useState<UserRow[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState('');
    const [search, setSearch] = useState('');

    const [userForm, setUserForm] = useState<Record<string, string> | null>(null);
    const [confirmDeleteUser, setConfirmDeleteUser] = useState<UserRow | null>(null);
    const [resetPasswordUser, setResetPasswordUser] = useState<UserRow | null>(null);
    const [newPassword, setNewPassword] = useState('');
    const [isSaving, setIsSaving] = useState(false);

    const load = async () => {
        setIsLoading(true);
        setError('');
        try {
            const [r, u] = await Promise.all([
                dataService.getRoles(),
                dataService.getAllUsers(),
            ]);
            setRoles(r);
            setUsers(u);
        } catch (e) {
            setError(errorMessage(e));
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => { load(); }, []);

    const assignableRoles = roles.filter(r => r.assignable);
    const creatableRoles = assignableRoles.filter(r => !r.full);
    const isTechnician = userForm?.role === 'PROFESSIONAL';
    // technician accounts use an internal address; show their username instead
    const displayLogin = (u: UserRow) => u.email.endsWith('@technician.vankel') ? `@${u.email.split('@')[0]}` : u.email;

    const filteredUsers = useMemo(() => users.filter(u =>
        `${u.name} ${u.email} ${u.role_label || u.role}`.toLowerCase().includes(search.toLowerCase())
    ), [users, search]);

    const saveUser = async () => {
        if (!userForm) return;
        setIsSaving(true);
        setError('');
        try {
            await dataService.createUser(userForm as any);
            setUserForm(null);
            await load();
        } catch (e) {
            setError(errorMessage(e));
        } finally {
            setIsSaving(false);
        }
    };

    const changeUserRole = async (user: UserRow, role: string) => {
        setError('');
        try {
            await dataService.updateUserRole(String(user.id), role);
            await load();
        } catch (e) {
            setError(errorMessage(e));
        }
    };

    const deleteUser = async (user: UserRow) => {
        setError('');
        try {
            await dataService.deleteUser(String(user.id));
            setConfirmDeleteUser(null);
            await load();
        } catch (e) {
            setConfirmDeleteUser(null);
            setError(errorMessage(e));
        }
    };

    const resetPassword = async () => {
        if (!resetPasswordUser || newPassword.length < 8) return;
        setIsSaving(true);
        setError('');
        try {
            await dataService.resetUserPassword(String(resetPasswordUser.id), newPassword);
            setResetPasswordUser(null);
            setNewPassword('');
        } catch (e) {
            setError(errorMessage(e));
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <div className="space-y-6 animate-in fade-in duration-500 max-w-6xl mx-auto pb-12 px-4 md:px-0">
            <div>
                <h2 className="text-2xl font-black text-white uppercase tracking-tight flex items-center gap-2">
                    <KeyRound className="text-brand-green" /> {t.access_title || 'Users & roles'}
                </h2>
                <p className="text-zinc-500 text-sm font-medium">{t.access_subtitle || 'Create users and see what each of the three roles can do.'}</p>
            </div>

            <div className="flex gap-2 border-b border-zinc-800">
                {(
                    <button onClick={() => setTab('users')} className={`px-4 py-3 text-xs font-black uppercase tracking-widest flex items-center gap-2 ${tab === 'users' ? 'text-brand-green border-b-2 border-brand-green' : 'text-zinc-500 hover:text-zinc-300'}`}>
                        <Users size={14} /> {t.access_users || 'Users'} ({users.length})
                    </button>
                )}
                {(
                    <button onClick={() => setTab('roles')} className={`px-4 py-3 text-xs font-black uppercase tracking-widest flex items-center gap-2 ${tab === 'roles' ? 'text-brand-green border-b-2 border-brand-green' : 'text-zinc-500 hover:text-zinc-300'}`}>
                        <ShieldCheck size={14} /> {t.access_roles || 'Roles'} ({roles.length})
                    </button>
                )}
            </div>

            {error && (
                <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 text-sm flex justify-between gap-4">
                    <span>{error}</span>
                    <button onClick={() => setError('')}><X size={16} /></button>
                </div>
            )}

            {isLoading ? (
                <div className="flex items-center justify-center p-20">
                    <div className="w-8 h-8 border-4 border-brand-green border-t-transparent rounded-full animate-spin"></div>
                </div>
            ) : tab === 'users' ? (
                <div className="space-y-4">
                    <div className="flex flex-col md:flex-row gap-3 justify-between">
                        <div className="relative w-full md:w-72">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-600" size={16} />
                            <input value={search} onChange={e => setSearch(e.target.value)} placeholder={t.search || 'Search...'} className={`${inputClass} pl-9`} />
                        </div>
                        {can('users.create') && (
                            <button
                                onClick={() => { setError(''); setUserForm({ firstName: '', lastName: '', email: '', username: '', password: '', phone: '', role: creatableRoles[0]?.name || '', companyName: '' }); }}
                                className="px-4 py-2.5 bg-brand-green text-brand-black rounded-xl font-black text-xs uppercase tracking-widest flex items-center justify-center gap-2"
                            >
                                <Plus size={16} /> {t.access_create_user || 'Create user'}
                            </button>
                        )}
                    </div>
                    <div className="bg-zinc-950 border border-zinc-800 rounded-2xl divide-y divide-zinc-900">
                        {filteredUsers.map(u => (
                            <div key={u.id} className="p-4 flex flex-col md:flex-row md:items-center gap-3 justify-between">
                                <div className="min-w-0">
                                    <p className="font-bold text-white truncate">{u.name}</p>
                                    <p className="text-xs text-zinc-500 truncate">{displayLogin(u)}{u.phone ? ` · ${u.phone}` : ''} · {u.status}</p>
                                </div>
                                <div className="flex items-center gap-2">
                                    {can('users.update') ? (
                                        <select value={u.role} onChange={e => changeUserRole(u, e.target.value)} className={`${inputClass} md:w-56`}>
                                            {!roles.some(r => r.name === u.role) && <option value={u.role}>{u.role_label || u.role}</option>}
                                            {assignableRoles.map(r => <option key={r.name} value={r.name}>{r.label}</option>)}
                                        </select>
                                    ) : (
                                        <span className="px-2 py-1 rounded text-[10px] font-black uppercase bg-brand-green/10 text-brand-green border border-brand-green/20">{u.role_label || u.role}</span>
                                    )}
                                    {can('users.update') && (
                                        <button
                                            onClick={() => { setError(''); setNewPassword(''); setResetPasswordUser(u); }}
                                            className="px-3 py-2.5 rounded-xl text-zinc-400 hover:text-brand-green hover:bg-zinc-900 border border-zinc-800 shrink-0 flex items-center gap-2"
                                            title={t.access_reset_password || 'Change password'}
                                            aria-label={t.access_reset_password || 'Change password'}
                                        >
                                            <RotateCcw size={16} />
                                            <span className="hidden sm:inline text-[10px] font-black uppercase tracking-widest">{t.access_reset_password || 'Change password'}</span>
                                        </button>
                                    )}
                                    {can('users.update') && (
                                        <button
                                            onClick={() => { setError(''); setConfirmDeleteUser(u); }}
                                            className="p-2.5 rounded-xl text-zinc-400 hover:text-red-500 hover:bg-zinc-900 border border-zinc-800 shrink-0"
                                            title={t.delete || 'Delete'}
                                            aria-label={t.delete || 'Delete'}
                                        >
                                            <Trash2 size={16} />
                                        </button>
                                    )}
                                </div>
                            </div>
                        ))}
                        {filteredUsers.length === 0 && <p className="p-8 text-center text-zinc-600 text-sm">{t.access_no_users || 'No users found.'}</p>}
                    </div>
                    {can('users.update') && (
                        <p className="text-xs text-zinc-600">{t.access_role_change_note || 'Changing a role signs that user out so their new access applies right away.'}</p>
                    )}
                </div>
            ) : (
                <div className="space-y-4">
                    <p className="text-xs text-zinc-500">{t.access_fixed_roles_note || 'The three roles are fixed and cannot be changed.'}</p>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {roles.map(r => (
                            <div key={r.id} className="bg-zinc-950 border border-zinc-800 rounded-2xl p-5 space-y-3">
                                <div className="flex items-start justify-between gap-2">
                                    <div className="min-w-0">
                                        <h4 className="font-bold text-white text-lg flex items-center gap-2">
                                            {r.label} {r.is_system && <Lock size={12} className="text-zinc-600" />}
                                        </h4>
                                        <p className="text-[10px] font-mono text-zinc-600">{r.name}</p>
                                    </div>
                                </div>
                                {r.description && <p className="text-sm text-zinc-400">{r.description}</p>}
                                <div className="flex gap-4 text-xs text-zinc-500">
                                    <span>{r.users_count} {t.access_users_count || 'user(s)'}</span>
                                    <span>{r.is_super_admin ? (t.access_all_permissions || 'All permissions') : `${r.permissions.length} ${t.access_permissions_count || 'permission(s)'}`}</span>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {/* Create user */}
            {userForm && (
                <div className="fixed inset-0 z-[160] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
                    <div className="bg-zinc-950 border border-zinc-800 w-full max-w-lg max-h-[90vh] overflow-y-auto rounded-2xl p-6 space-y-4">
                        <div className="flex justify-between items-center">
                            <h3 className="text-lg font-black text-white uppercase">{t.access_create_user || 'Create user'}</h3>
                            <button onClick={() => setUserForm(null)} className="text-zinc-500 hover:text-white"><X size={20} /></button>
                        </div>
                        <div className="grid grid-cols-2 gap-3">
                            <div className="space-y-1.5 col-span-2">
                                <label className={labelClass}>{t.access_role || 'Role'}</label>
                                <select value={userForm.role} onChange={e => setUserForm({ ...userForm, role: e.target.value })} className={inputClass}>
                                    {assignableRoles.map(r => (
                                        <option key={r.name} value={r.name} disabled={r.full}>
                                            {r.label}{r.full ? ` (${t.access_role_full || 'limit reached'})` : ''}
                                        </option>
                                    ))}
                                </select>
                            </div>
                            {([
                                ['firstName', t.firstName || 'First name', 'text'],
                                ['lastName', t.lastName || 'Last name', 'text'],
                                isTechnician
                                    ? ['username', t.access_username || 'Username (used to sign in)', 'text']
                                    : ['email', t.email || 'Email', 'email'],
                                ['phone', t.phone || 'Phone', 'tel'],
                                ['password', t.access_initial_password || 'Initial password (min. 8)', 'text'],
                                ['companyName', t.companyName || 'Company', 'text'],
                            ] as const).map(([key, label, type]) => (
                                <div key={key} className="space-y-1.5">
                                    <label className={labelClass}>{label}</label>
                                    <input
                                        type={type}
                                        autoCapitalize={key === 'username' ? 'none' : undefined}
                                        value={userForm[key] ?? ''}
                                        onChange={e => setUserForm({ ...userForm, [key]: e.target.value })}
                                        className={inputClass}
                                    />
                                </div>
                            ))}
                        </div>
                        {error && <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 text-sm">{error}</div>}
                        <p className="text-xs text-zinc-500">{t.access_password_note || 'Share this password with the user privately and ask them to change it after their first login.'}</p>
                        <div className="flex gap-3">
                            <button onClick={() => setUserForm(null)} className="flex-1 py-3 bg-zinc-900 text-zinc-400 border border-zinc-800 rounded-xl font-bold text-xs uppercase tracking-widest">{t.btnCancel || 'Cancel'}</button>
                            <button
                                disabled={isSaving || !userForm.firstName || !userForm.lastName || (isTechnician ? userForm.username.trim().length < 3 : !userForm.email) || userForm.password.length < 8 || !userForm.role}
                                onClick={saveUser}
                                className="flex-1 py-3 bg-brand-green text-brand-black rounded-xl font-bold text-xs uppercase tracking-widest disabled:opacity-50"
                            >
                                {t.access_create_user || 'Create user'}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Reset password */}
            {resetPasswordUser && (
                <div className="fixed inset-0 z-[160] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
                    <div className="bg-zinc-950 border border-zinc-800 w-full max-w-sm rounded-2xl p-6 space-y-4">
                        <div className="flex justify-between items-center">
                            <h3 className="text-lg font-black text-white uppercase">{t.access_reset_password || 'Change password'}</h3>
                            <button onClick={() => setResetPasswordUser(null)} className="text-zinc-500 hover:text-white"><X size={20} /></button>
                        </div>
                        <p className="text-sm text-zinc-400">{resetPasswordUser.name} · {displayLogin(resetPasswordUser)}</p>
                        <div className="space-y-1.5">
                            <label className={labelClass}>{t.access_new_password || 'New password (min. 8)'}</label>
                            <input type="text" value={newPassword} onChange={e => setNewPassword(e.target.value)} className={inputClass} />
                        </div>
                        {error && <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 text-sm">{error}</div>}
                        <p className="text-xs text-zinc-500">{t.access_reset_password_note || 'This signs the user out everywhere. Share the new password with them privately.'}</p>
                        <div className="flex gap-3">
                            <button onClick={() => setResetPasswordUser(null)} className="flex-1 py-3 bg-zinc-900 text-zinc-400 border border-zinc-800 rounded-xl font-bold text-xs uppercase tracking-widest">{t.btnCancel || 'Cancel'}</button>
                            <button disabled={isSaving || newPassword.length < 8} onClick={resetPassword} className="flex-1 py-3 bg-brand-green text-brand-black rounded-xl font-bold text-xs uppercase tracking-widest disabled:opacity-50">{t.save || 'Save'}</button>
                        </div>
                    </div>
                </div>
            )}

            {/* Delete user confirmation (in-app, no browser dialog) */}
            {confirmDeleteUser && (
                <div className="fixed inset-0 z-[170] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
                    <div className="bg-zinc-950 border border-zinc-800 w-full max-w-sm rounded-2xl p-6 text-center space-y-4">
                        <h4 className="text-lg font-bold text-white">{t.access_delete_user || 'Delete this user?'}</h4>
                        <p className="text-sm text-zinc-400">{confirmDeleteUser.name}</p>
                        <p className="text-xs text-zinc-600">{t.access_delete_user_note || 'Their account is deactivated but their data stays visible in intervention history.'}</p>
                        <div className="flex gap-3">
                            <button onClick={() => setConfirmDeleteUser(null)} className="flex-1 py-3 bg-zinc-900 text-zinc-400 border border-zinc-800 rounded-xl font-bold text-xs uppercase">{t.btnCancel || 'Cancel'}</button>
                            <button onClick={() => deleteUser(confirmDeleteUser)} className="flex-1 py-3 bg-red-500 text-white rounded-xl font-bold text-xs uppercase">{t.delete || 'Delete'}</button>
                        </div>
                    </div>
                </div>
            )}

        </div>
    );
};

export default AccessPage;
