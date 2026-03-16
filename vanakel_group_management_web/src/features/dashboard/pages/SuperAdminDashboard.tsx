import React, { useState, useEffect } from 'react';
import { SignupRequest, AdminUser, Language, Email, Intervention, Mission, Building } from '@/types';
import {
    Users,
    ShieldCheck,
    Check,
    X,
    ArrowLeft,
    UserPlus,
    Plus,
    Mail,
    Phone,
    Building2,
    AlertCircle,
    Calendar,
    MessageSquare,
    History,
    Clock,
    FileText,
    ChevronRight,
    RefreshCw,
    CheckCircle2,
    XCircle
} from 'lucide-react';
import { TRANSLATIONS } from '@/utils/constants';
import { dataService } from '@/services/dataService';

interface SuperAdminDashboardProps {
    requests: SignupRequest[];
    admins: AdminUser[];
    allUsers: any[];
    stats: any;
    interventions: Intervention[];
    missions: Mission[];
    buildings: Building[];
    onApprove: (request: SignupRequest) => void;
    onReject: (requestId: string) => void;
    onCreateAdmin: (admin: Omit<AdminUser, 'id' | 'createdAt'>) => void;
    onRefresh: () => void;
    lang: Language;
}

const SuperAdminDashboard: React.FC<SuperAdminDashboardProps> = ({
    requests,
    admins,
    allUsers,
    stats,
    interventions,
    missions,
    buildings,
    onApprove,
    onReject,
    onCreateAdmin,
    onRefresh,
    lang
}) => {
    const t = TRANSLATIONS[lang];
    const getLocalizedField = (obj: any, field: 'title' | 'description') => {
        if (lang === 'EN') return obj[`${field}_en`] || obj[field];
        if (lang === 'NL') return obj[`${field}_nl`] || obj[field];
        return obj[`${field}_fr`] || obj[field];
    };

    const [activeTab, setActiveTab] = useState<'requests' | 'admins' | 'all_users' | 'history' | 'emails'>('requests');
    const [showCreateAdminModal, setShowCreateAdminModal] = useState(false);
    const [emails, setEmails] = useState<Email[]>([]);
    const [isLoadingEmails, setIsLoadingEmails] = useState(false);
    const [newAdmin, setNewAdmin] = useState({
        firstName: '',
        lastName: '',
        email: '',
        phone: ''
    });

    useEffect(() => {
        if (activeTab === 'emails') {
            fetchEmails();
        }
    }, [activeTab]);

    const fetchEmails = async () => {
        setIsLoadingEmails(true);
        try {
            const response = await dataService.getEmails();
            if (response && response.emails) {
                setEmails(response.emails);
            }
        } catch (error) {
            console.error("Error fetching emails:", error);
        } finally {
            setIsLoadingEmails(false);
        }
    };

    const handleCreateSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        onCreateAdmin(newAdmin);
        setNewAdmin({ firstName: '', lastName: '', email: '', phone: '' });
        setShowCreateAdminModal(false);
    };

    return (
        <div className="flex flex-col h-full space-y-8 animate-in fade-in duration-500 max-w-7xl mx-auto">
            <div className="flex flex-col md:flex-row md:justify-between md:items-end gap-6 px-2">
                <div>
                    <h1 className="text-2xl md:text-3xl font-black text-white">{t.superAdmin}</h1>
                    <p className="text-zinc-500 text-xs md:text-sm mt-1">{t.overview_subtitle}</p>
                </div>
                <button
                    onClick={onRefresh}
                    className="flex items-center gap-2 px-6 py-3 bg-zinc-950 hover:bg-zinc-900 border border-zinc-900 hover:border-brand-green/30 rounded-[1.25rem] text-zinc-400 hover:text-brand-green transition-all text-[10px] md:text-xs font-black uppercase tracking-[0.2em] group shadow-2xl"
                >
                    <RefreshCw size={16} className="group-hover:rotate-180 transition-transform duration-700 ease-in-out" />
                    {t.refresh || 'Refresh'}
                </button>
            </div>
            <div className="flex border-b border-zinc-900 bg-zinc-950/50 sticky top-0 z-10 overflow-x-auto no-scrollbar whitespace-nowrap px-4 md:px-0">
                <button
                    onClick={() => setActiveTab('requests')}
                    className={`px-6 py-4 text-[10px] md:text-xs font-black uppercase tracking-widest transition-all relative shrink-0 ${activeTab === 'requests' ? 'text-brand-green' : 'text-zinc-500 hover:text-zinc-300'}`}
                >
                    {t.pendingRequests} ({requests.length})
                    {activeTab === 'requests' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-brand-green"></div>}
                </button>
                <button
                    onClick={() => setActiveTab('admins')}
                    className={`px-6 py-4 text-[10px] md:text-xs font-black uppercase tracking-widest transition-all relative shrink-0 ${activeTab === 'admins' ? 'text-brand-green' : 'text-zinc-500 hover:text-zinc-300'}`}
                >
                    {t.adminList} ({admins.length})
                    {activeTab === 'admins' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-brand-green"></div>}
                </button>
                <button
                    onClick={() => setActiveTab('all_users')}
                    className={`px-6 py-4 text-[10px] md:text-xs font-black uppercase tracking-widest transition-all relative shrink-0 ${activeTab === 'all_users' ? 'text-brand-green' : 'text-zinc-500 hover:text-zinc-300'}`}
                >
                    {t.allUsers || 'Users'} ({allUsers.length})
                    {activeTab === 'all_users' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-brand-green"></div>}
                </button>
                <button
                    onClick={() => setActiveTab('history')}
                    className={`px-6 py-4 text-[10px] md:text-xs font-black uppercase tracking-widest transition-all relative shrink-0 ${activeTab === 'history' ? 'text-brand-green' : 'text-zinc-500 hover:text-zinc-300'}`}
                >
                    {t.tabs_history || 'History'}
                    {activeTab === 'history' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-brand-green"></div>}
                </button>
                <button
                    onClick={() => setActiveTab('emails')}
                    className={`px-6 py-4 text-[10px] md:text-xs font-black uppercase tracking-widest transition-all relative shrink-0 ${activeTab === 'emails' ? 'text-brand-green' : 'text-zinc-500 hover:text-zinc-300'}`}
                >
                    {t.emails || 'Emails'} ({emails.length})
                    {activeTab === 'emails' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-brand-green"></div>}
                </button>
                <button
                    onClick={() => setActiveTab('settings')}
                    className={`px-6 py-4 text-[10px] md:text-xs font-black uppercase tracking-widest transition-all relative shrink-0 ${activeTab === 'settings' ? 'text-brand-green' : 'text-zinc-500 hover:text-zinc-300'}`}
                >
                    {t.superadmin_ai_settings || 'AI Settings'}
                    {activeTab === 'settings' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-brand-green"></div>}
                </button>
            </div>

            {/* Stats Overview */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <div className="bg-zinc-950 p-6 rounded-[2rem] border border-zinc-900 shadow-xl group hover:border-brand-green/30 transition-all">
                    <div className="flex justify-between items-start mb-4">
                        <div className="w-12 h-12 bg-brand-green/10 rounded-2xl flex items-center justify-center border border-brand-green/20 group-hover:scale-110 transition-transform">
                            <ShieldCheck className="text-brand-green" size={24} />
                        </div>
                        <span className="text-[10px] font-black text-zinc-600 uppercase tracking-widest bg-zinc-900 px-2 py-1 rounded">{t.superadmin_system || 'System'}</span>
                    </div>
                    <div className="space-y-1">
                        <h3 className="text-3xl font-black text-white">{stats?.total_admins || 0}</h3>
                        <p className="text-zinc-500 text-xs font-bold uppercase tracking-tight">{t.adminList || 'Administrators'}</p>
                    </div>
                </div>

                <div className="bg-zinc-950 p-6 rounded-[2rem] border border-zinc-900 shadow-xl group hover:border-blue-500/30 transition-all">
                    <div className="flex justify-between items-start mb-4">
                        <div className="w-12 h-12 bg-blue-500/10 rounded-2xl flex items-center justify-center border border-blue-500/20 group-hover:scale-110 transition-transform">
                            <Users className="text-blue-500" size={24} />
                        </div>
                        <span className="text-[10px] font-black text-zinc-600 uppercase tracking-widest bg-zinc-900 px-2 py-1 rounded">{t.superadmin_active_users || 'Active'}</span>
                    </div>
                    <div className="space-y-1">
                        <h3 className="text-3xl font-black text-white">{(stats?.total_syndics || 0) + (stats?.total_professionals || 0)}</h3>
                        <p className="text-zinc-500 text-xs font-bold uppercase tracking-tight">{t.allUsers || 'Total Users'}</p>
                    </div>
                </div>

                <div className="bg-zinc-950 p-6 rounded-[2rem] border border-zinc-900 shadow-xl group hover:border-orange-500/30 transition-all">
                    <div className="flex justify-between items-start mb-4">
                        <div className="w-12 h-12 bg-orange-500/10 rounded-2xl flex items-center justify-center border border-orange-500/20 group-hover:scale-110 transition-transform">
                            <AlertCircle className="text-orange-500" size={24} />
                        </div>
                        <span className="text-[10px] font-black text-zinc-600 uppercase tracking-widest bg-zinc-900 px-2 py-1 rounded">{t.superadmin_pending_badge || 'Pending'}</span>
                    </div>
                    <div className="space-y-1">
                        <h3 className="text-3xl font-black text-white">{stats?.pending_registrations || 0}</h3>
                        <p className="text-zinc-500 text-xs font-bold uppercase tracking-tight">{t.pendingRequests || 'Pending Requests'}</p>
                    </div>
                </div>

                <div className="bg-zinc-950 p-6 rounded-[2rem] border border-zinc-900 shadow-xl group hover:border-zinc-500/30 transition-all">
                    <div className="flex justify-between items-start mb-4">
                        <div className="w-12 h-12 bg-zinc-500/10 rounded-2xl flex items-center justify-center border border-zinc-500/20 group-hover:scale-110 transition-transform">
                            <Mail className="text-zinc-400" size={24} />
                        </div>
                        <span className="text-[10px] font-black text-zinc-600 uppercase tracking-widest bg-zinc-900 px-2 py-1 rounded">{t.superadmin_logs_badge || 'Logs'}</span>
                    </div>
                    <div className="space-y-1">
                        <h3 className="text-3xl font-black text-white">{stats?.total_emails || 0}</h3>
                        <p className="text-zinc-500 text-xs font-bold uppercase tracking-tight">{t.email_logs_title || 'Emails Fetched'}</p>
                    </div>
                </div>
            </div>

            <div className="flex-1 overflow-hidden">
                {activeTab === 'requests' && (
                    <div className="bg-zinc-950 rounded-2xl border border-zinc-800 overflow-hidden flex flex-col h-full">
                        <div className="p-6 border-b border-zinc-900 bg-zinc-950/50">
                            <h3 className="font-bold text-white flex items-center gap-2">
                                <AlertCircle className="text-orange-500" size={18} />
                                {t.pendingRequests}
                            </h3>
                        </div>
                        <div className="flex-1 overflow-y-auto p-6 space-y-4">
                            {requests.length === 0 ? (
                                <div className="py-20 text-center space-y-4">
                                    <ShieldCheck size={48} className="mx-auto text-zinc-800" />
                                    <p className="text-zinc-500">{t.noPendingRequests}</p>
                                </div>
                            ) : (
                                <div className="space-y-4">
                                    {requests.map(req => (
                                        <div key={req.id} className="p-4 md:p-6 bg-zinc-900/50 rounded-2xl border border-zinc-800/50 flex flex-col md:flex-row justify-between items-start md:items-center gap-4 md:gap-6 hover:border-zinc-700 transition-colors">
                                            <div className="flex gap-3 md:gap-4 w-full md:w-auto">
                                                <div className="w-10 h-10 md:w-12 md:h-12 bg-zinc-950 rounded-xl flex items-center justify-center border border-zinc-800 shrink-0">
                                                    {req.role === 'ADMIN' ? <ShieldCheck className="text-brand-green" size={18} /> : <Building2 className="text-blue-400" size={18} />}
                                                </div>
                                                <div className="min-w-0">
                                                    <div className="flex items-center gap-2 flex-wrap">
                                                        <h4 className="font-bold text-white truncate">{req.firstName} {req.lastName}</h4>
                                                        <span className={`text-[8px] font-black px-1.5 py-0.5 rounded uppercase ${req.role === 'ADMIN' ? 'bg-brand-green/10 text-brand-green' : 'bg-blue-400/10 text-blue-400'}`}>
                                                            {req.role}
                                                        </span>
                                                    </div>
                                                    <div className="flex flex-col md:flex-row md:gap-4 mt-1.5 md:mt-2 text-[11px] md:text-xs text-zinc-500 gap-1">
                                                        <span className="flex items-center gap-1 truncate"><Mail size={12} className="shrink-0" /> {req.email}</span>
                                                        <span className="flex items-center gap-1"><Phone size={12} className="shrink-0" /> {req.phone}</span>
                                                    </div>
                                                    {req.companyName && (
                                                        <p className="text-[11px] text-zinc-600 mt-1 italic flex items-center gap-1">
                                                            <Building2 size={12} /> {req.companyName}
                                                        </p>
                                                    )}
                                                </div>
                                            </div>
                                            <div className="flex gap-2 w-full md:w-auto pt-2 md:pt-0 border-t border-zinc-900 md:border-t-0 mt-2 md:mt-0">
                                                <button
                                                    onClick={() => onReject(req.id)}
                                                    className="flex-1 md:flex-none px-4 py-2.5 rounded-xl border border-zinc-800 hover:bg-red-500/10 hover:border-red-500/50 hover:text-red-500 transition-all text-[10px] md:text-xs font-bold uppercase"
                                                >
                                                    <X size={14} className="inline-block md:mr-2" /> {t.reject}
                                                </button>
                                                <button
                                                    onClick={() => onApprove(req)}
                                                    className="flex-1 md:flex-none px-4 py-2.5 rounded-xl bg-brand-green text-brand-black hover:scale-105 transition-all text-[10px] md:text-xs font-black uppercase"
                                                >
                                                    <Check size={14} className="inline-block md:mr-2" strokeWidth={3} /> {t.approve}
                                                </button>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    </div>
                )}

                {activeTab === 'admins' && (
                    <div className="space-y-6 flex flex-col h-full animate-in slide-in-from-bottom-4 duration-500">
                        <div className="flex justify-between items-center">
                            <h3 className="font-bold text-white flex items-center gap-2 px-2">
                                <ShieldCheck className="text-brand-green" size={20} />
                                {t.adminList}
                            </h3>
                            <button
                                onClick={() => setShowCreateAdminModal(true)}
                                className="bg-brand-green text-brand-black px-6 py-3 rounded-xl font-black text-xs uppercase tracking-widest hover:bg-brand-green-light transition-all shadow-lg flex items-center gap-2"
                            >
                                <Plus size={16} strokeWidth={3} /> {t.createAdmin}
                            </button>
                        </div>

                        <div className="flex-1 overflow-y-auto">
                            {/* Desktop Table */}
                            <div className="hidden md:block">
                                <div className="bg-zinc-950 rounded-2xl border border-zinc-900 overflow-hidden shadow-2xl">
                                    <table className="w-full text-left">
                                        <thead className="bg-zinc-900/50 border-b border-zinc-900">
                                            <tr>
                                                <th className="px-8 py-5 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.contact_name}</th>
                                                <th className="px-8 py-5 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.email}</th>
                                                <th className="px-8 py-5 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.gsm}</th>
                                                <th className="px-8 py-5 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.created_at}</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-zinc-900">
                                            {admins.length === 0 ? (
                                                <tr><td colSpan={4} className="px-8 py-20 text-center"><p className="text-zinc-500 text-sm">{t.superadmin_no_admins_found || 'No administrators found.'}</p></td></tr>
                                            ) : (
                                                admins.map(admin => (
                                                    <tr key={admin.id} className="hover:bg-zinc-900/30 transition-colors group">
                                                        <td className="px-8 py-5">
                                                            <div className="flex items-center gap-4">
                                                                <div className="w-10 h-10 rounded-xl bg-zinc-900 flex items-center justify-center text-xs font-bold text-zinc-400 group-hover:bg-brand-green group-hover:text-brand-black border border-zinc-800 transition-all">
                                                                    {(admin.firstName?.[0] || '')}{(admin.lastName?.[0] || '')}
                                                                </div>
                                                                <span className="font-bold text-white group-hover:text-brand-green transition-colors">{admin.firstName} {admin.lastName}</span>
                                                            </div>
                                                        </td>
                                                        <td className="px-8 py-5 text-sm text-zinc-400 font-medium">{admin.email}</td>
                                                        <td className="px-8 py-5 text-sm text-zinc-400 font-medium">{admin.phone}</td>
                                                        <td className="px-8 py-5 text-[10px] text-zinc-600 font-mono tracking-tighter uppercase">
                                                            {new Date(admin.createdAt).toLocaleDateString()}
                                                        </td>
                                                    </tr>
                                                ))
                                            )}
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            {/* Mobile Cards */}
                            <div className="md:hidden space-y-4 px-2">
                                {admins.length === 0 ? (
                                    <div className="py-20 text-center text-zinc-500 italic">{t.superadmin_no_admins_found || 'No administrators found.'}</div>
                                ) : (
                                    admins.map(admin => (
                                        <div key={admin.id} className="p-5 bg-zinc-950/50 rounded-2xl border border-zinc-900 space-y-4">
                                            <div className="flex items-center gap-4">
                                                <div className="w-12 h-12 rounded-xl bg-zinc-900 flex items-center justify-center text-sm font-bold text-brand-green border border-brand-green/20">
                                                    {(admin.firstName?.[0] || '')}{(admin.lastName?.[0] || '')}
                                                </div>
                                                <div>
                                                    <h4 className="font-bold text-white text-lg">{admin.firstName} {admin.lastName}</h4>
                                                    <p className="text-[10px] text-zinc-600 font-black uppercase tracking-widest">{t.superadmin_date || 'Added'} {new Date(admin.createdAt).toLocaleDateString()}</p>
                                                </div>
                                            </div>
                                            <div className="space-y-2 pt-2 border-t border-zinc-900">
                                                <div className="flex items-center gap-3 text-xs text-zinc-400">
                                                    <Mail size={14} className="text-zinc-600" />
                                                    {admin.email}
                                                </div>
                                                <div className="flex items-center gap-3 text-xs text-zinc-400">
                                                    <Phone size={14} className="text-zinc-600" />
                                                    {admin.phone}
                                                </div>
                                            </div>
                                        </div>
                                    ))
                                )}
                            </div>
                        </div>
                    </div>
                )}

                {activeTab === 'all_users' && (
                    <div className="space-y-6 flex flex-col h-full animate-in slide-in-from-bottom-4 duration-500">
                        <div className="flex justify-between items-center">
                            <h3 className="font-bold text-white flex items-center gap-2 px-2">
                                <Users className="text-blue-500" size={20} />
                                {t.allUsers || 'System Participants'}
                            </h3>
                        </div>

                        <div className="flex-1 overflow-y-auto">
                            {/* Desktop Table */}
                            <div className="hidden md:block">
                                <div className="bg-zinc-950 rounded-2xl border border-zinc-900 overflow-hidden shadow-2xl">
                                    <table className="w-full text-left">
                                        <thead className="bg-zinc-900/50 border-b border-zinc-900">
                                            <tr>
                                                <th className="px-8 py-5 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.superadmin_participant || 'Participant'}</th>
                                                <th className="px-8 py-5 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.superadmin_role || 'Role'}</th>
                                                <th className="px-8 py-5 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.status || 'Status'}</th>
                                                <th className="px-8 py-5 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.superadmin_company_org || 'Company / Org'}</th>
                                                <th className="px-8 py-5 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.superadmin_contact_info || 'Contact Info'}</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-zinc-900">
                                            {allUsers.length === 0 ? (
                                                <tr><td colSpan={5} className="px-8 py-20 text-center"><p className="text-zinc-500 text-sm">{t.superadmin_no_users_found || 'No users found.'}</p></td></tr>
                                            ) : (
                                                allUsers.map(user => (
                                                    <tr key={user.id} className="hover:bg-zinc-900/30 transition-colors group">
                                                        <td className="px-8 py-5">
                                                            <div className="flex items-center gap-4">
                                                                <div className={`w-10 h-10 rounded-xl bg-zinc-900 flex items-center justify-center text-xs font-bold border transition-all ${user.role === 'ADMIN' ? 'text-brand-green border-brand-green/20' : user.role === 'SYNDIC' ? 'text-blue-400 border-blue-400/20' : 'text-purple-400 border-purple-400/20'}`}>
                                                                    {(user.firstName?.[0] || '')}{(user.lastName?.[0] || '')}
                                                                </div>
                                                                <div>
                                                                    <span className="font-bold text-white block">{user.firstName} {user.lastName}</span>
                                                                    <span className="text-[10px] text-zinc-600 font-mono tracking-widest uppercase truncate max-w-[150px]">{t.superadmin_joined} {new Date(user.createdAt).toLocaleDateString()}</span>
                                                                </div>
                                                            </div>
                                                        </td>
                                                        <td className="px-8 py-5">
                                                            <span className={`text-[9px] font-black px-2 py-1 rounded-lg border uppercase tracking-widest ${user.role === 'ADMIN' ? 'bg-brand-green/10 text-brand-green' : user.role === 'SYNDIC' ? 'bg-blue-400/10 text-blue-400' : 'bg-purple-400/10 text-purple-400'}`}>
                                                                {user.role}
                                                            </span>
                                                        </td>
                                                        <td className="px-8 py-5">
                                                            <div className="flex items-center gap-2">
                                                                <div className={`w-1.5 h-1.5 rounded-full ${user.status === 'APPROVED' ? 'bg-brand-green' : 'bg-orange-500'}`}></div>
                                                                <span className="text-[10px] font-bold uppercase text-zinc-400">{user.status}</span>
                                                            </div>
                                                        </td>
                                                        <td className="px-8 py-5 text-sm text-zinc-500 italic truncate max-w-[150px]">{user.companyName || '---'}</td>
                                                        <td className="px-8 py-5">
                                                            <div className="text-[11px] text-zinc-400 space-y-0.5">
                                                                <p className="flex items-center gap-1.5"><Mail size={10} /> {user.email}</p>
                                                                <p className="flex items-center gap-1.5"><Phone size={10} /> {user.phone}</p>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                ))
                                            )}
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            {/* Mobile Cards */}
                            <div className="md:hidden space-y-4 px-2">
                                {allUsers.length === 0 ? (
                                    <div className="py-20 text-center text-zinc-500 italic">{t.superadmin_no_users_found || 'No users found.'}</div>
                                ) : (
                                    allUsers.map(user => (
                                        <div key={user.id} className="p-5 bg-zinc-950/50 rounded-2xl border border-zinc-900 space-y-4">
                                            <div className="flex items-center justify-between">
                                                <div className="flex items-center gap-3">
                                                    <div className={`w-10 h-10 rounded-xl bg-zinc-900 flex items-center justify-center text-xs font-bold border ${user.role === 'ADMIN' ? 'text-brand-green' : user.role === 'SYNDIC' ? 'text-blue-400' : 'text-purple-400'}`}>
                                                        {(user.firstName?.[0] || '')}{(user.lastName?.[0] || '')}
                                                    </div>
                                                    <div>
                                                        <h4 className="font-bold text-white text-sm">{user.firstName} {user.lastName}</h4>
                                                        <p className="text-[10px] text-zinc-600 mt-0.5 font-bold uppercase">{user.role}</p>
                                                    </div>
                                                </div>
                                                <span className={`text-[8px] font-black px-1.5 py-0.5 rounded border ${user.status === 'APPROVED' ? 'text-brand-green border-brand-green/20' : 'text-orange-500 border-orange-500/20'}`}>
                                                    {user.status}
                                                </span>
                                            </div>
                                            <div className="space-y-2 pt-3 border-t border-zinc-900">
                                                {user.companyName && (
                                                    <p className="text-[11px] text-zinc-400 flex items-center gap-2">
                                                        <Building2 size={12} className="text-zinc-600" /> {user.companyName}
                                                    </p>
                                                )}
                                                <p className="text-[11px] text-zinc-500 flex items-center gap-2">
                                                    <Mail size={12} className="text-zinc-600" /> {user.email}
                                                </p>
                                                <p className="text-[11px] text-zinc-500 flex items-center gap-2">
                                                    <Phone size={12} className="text-zinc-600" /> {user.phone}
                                                </p>
                                            </div>
                                        </div>
                                    ))
                                )}
                            </div>
                        </div>
                    </div>
                )}

                {activeTab === 'history' && (
                    <div className="space-y-6 flex flex-col h-full animate-in slide-in-from-bottom-4 duration-500">
                        <div className="flex justify-between items-center">
                            <h3 className="font-bold text-white flex items-center gap-2 px-2">
                                <History className="text-brand-green" size={20} />
                                {t.tabs_history || 'System-Wide History'}
                            </h3>
                            <button
                                onClick={onRefresh}
                                className="flex items-center gap-2 px-4 py-2 bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 rounded-xl text-zinc-400 hover:text-white transition-all text-xs font-bold"
                            >
                                <RefreshCw size={14} />
                                {t.refresh || 'Refresh Data'}
                            </button>
                        </div>

                        <div className="flex-1 overflow-y-auto">
                            {/* Desktop Table View */}
                            <div className="hidden md:block">
                                <div className="bg-zinc-950 rounded-2xl border border-zinc-900 overflow-hidden shadow-2xl">
                                    <table className="w-full text-left">
                                        <thead className="bg-zinc-900/50 border-b border-zinc-900">
                                            <tr>
                                                <th className="px-8 py-5 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.superadmin_entry_header || 'Entry'}</th>
                                                <th className="px-8 py-5 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.superadmin_type_header || 'Type'}</th>
                                                <th className="px-8 py-5 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.superadmin_location_header || 'Location'}</th>
                                                <th className="px-8 py-5 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.superadmin_status_header || 'Status'}</th>
                                                <th className="px-8 py-5 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.superadmin_date_header || 'Date'}</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-zinc-900">
                                            {[...interventions.map(i => ({ ...i, entryType: 'INTERVENTION' })), ...missions.map(m => ({ ...m, entryType: 'MISSION' }))]
                                                .sort((a, b) => new Date(b.createdAt || '').getTime() - new Date(a.createdAt || '').getTime()).length === 0 ? (
                                                <tr><td colSpan={5} className="px-8 py-20 text-center"><p className="text-zinc-500 text-sm">No history found.</p></td></tr>
                                            ) : (
                                                [...interventions.map(i => ({ ...i, entryType: 'INTERVENTION' })), ...missions.map(m => ({ ...m, entryType: 'MISSION' }))]
                                                    .sort((a, b) => new Date(b.createdAt || '').getTime() - new Date(a.createdAt || '').getTime())
                                                    .map(entry => {
                                                        const building = buildings.find(b => b.id === (entry as any).buildingId);
                                                        return (
                                                            <tr key={entry.id} className="hover:bg-zinc-900/30 transition-colors group">
                                                                <td className="px-8 py-5">
                                                                    <span className="font-bold text-white block truncate max-w-[200px]">{getLocalizedField(entry, 'title') || 'Untitled'}</span>
                                                                    <span className="text-[9px] text-zinc-600 font-mono uppercase tracking-tighter">ID: {entry.id}</span>
                                                                </td>
                                                                <td className="px-8 py-5">
                                                                    <span className={`text-[9px] font-black px-2 py-1 rounded-lg border uppercase tracking-widest ${entry.entryType === 'INTERVENTION' ? 'bg-blue-500/10 text-blue-400 border-blue-500/20' : 'bg-brand-green/10 text-brand-green border-brand-green/20'}`}>
                                                                        {entry.entryType}
                                                                    </span>
                                                                </td>
                                                                <td className="px-8 py-5">
                                                                    <div className="flex items-center gap-2">
                                                                        <Building2 size={14} className="text-zinc-600 shrink-0" />
                                                                        <div className="min-w-0">
                                                                            <span className="text-xs text-zinc-400 block truncate">{building?.address || 'Standalone Site'}</span>
                                                                            <span className="text-[10px] text-zinc-600 block">{building?.city}</span>
                                                                        </div>
                                                                    </div>
                                                                </td>
                                                                <td className="px-8 py-5">
                                                                    <span className={`text-[10px] font-bold uppercase tracking-tight ${entry.status === 'COMPLETED' || entry.status === 'APPROVED' ? 'text-brand-green' : entry.status === 'REJECTED' || entry.status === 'DELAYED' ? 'text-red-400' : 'text-orange-400'}`}>
                                                                        {entry.status}
                                                                    </span>
                                                                </td>
                                                                <td className="px-8 py-5 text-xs text-zinc-500">{new Date(entry.createdAt || '').toLocaleDateString()}</td>
                                                            </tr>
                                                        );
                                                    })
                                            )}
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            {/* Mobile Card View */}
                            <div className="md:hidden space-y-4 px-2">
                                {[...interventions.map(i => ({ ...i, entryType: 'INTERVENTION' })), ...missions.map(m => ({ ...m, entryType: 'MISSION' }))]
                                    .sort((a, b) => new Date(b.createdAt || '').getTime() - new Date(a.createdAt || '').getTime()).length === 0 ? (
                                    <div className="py-20 text-center text-zinc-500 italic">No history found.</div>
                                ) : (
                                    [...interventions.map(i => ({ ...i, entryType: 'INTERVENTION' })), ...missions.map(m => ({ ...m, entryType: 'MISSION' }))]
                                        .sort((a, b) => new Date(b.createdAt || '').getTime() - new Date(a.createdAt || '').getTime())
                                        .map(entry => {
                                            const building = buildings.find(b => b.id === (entry as any).buildingId);
                                            return (
                                                <div key={entry.id} className="p-5 bg-zinc-950/50 rounded-2xl border border-zinc-900 space-y-4">
                                                    <div className="flex justify-between items-start">
                                                        <div className="space-y-1 flex-1 min-w-0">
                                                            <span className={`text-[8px] font-black px-1.5 py-0.5 rounded border mb-1.5 inline-block uppercase tracking-widest ${entry.entryType === 'INTERVENTION' ? 'bg-blue-500/10 text-blue-400 border-blue-400/20' : 'bg-brand-green/10 text-brand-green border-brand-green/20'}`}>
                                                                {entry.entryType}
                                                            </span>
                                                            <h4 className="font-bold text-white text-base truncate">{getLocalizedField(entry, 'title') || 'Untitled'}</h4>
                                                        </div>
                                                        <span className={`text-[9px] font-black uppercase tracking-tight ${entry.status === 'COMPLETED' || entry.status === 'APPROVED' ? 'text-brand-green' : entry.status === 'REJECTED' || entry.status === 'DELAYED' ? 'text-red-400' : 'text-orange-400'}`}>
                                                            {entry.status}
                                                        </span>
                                                    </div>
                                                    <div className="space-y-2 pt-3 border-t border-zinc-900">
                                                        <p className="text-[11px] text-zinc-400 flex items-center gap-2">
                                                            <Building2 size={12} className="text-zinc-600" /> {building?.address || 'Standalone Site'}
                                                        </p>
                                                        <p className="text-[11px] text-zinc-500 flex items-center gap-2">
                                                            <Clock size={12} className="text-zinc-600" /> {new Date(entry.createdAt || '').toLocaleDateString()}
                                                        </p>
                                                    </div>
                                                </div>
                                            );
                                        })
                                )}
                            </div>
                        </div>
                    </div>
                )}

                {activeTab === 'emails' && (
                    <div className="bg-zinc-950 rounded-2xl border border-zinc-800 overflow-hidden flex flex-col h-full">
                        <div className="p-6 border-b border-zinc-900 bg-zinc-950/50 flex justify-between items-center">
                            <h3 className="font-bold text-white flex items-center gap-2">
                                <Mail className="text-brand-green" size={18} />
                                {t.email_logs_title || 'Emails Fetched'}
                            </h3>
                            <button
                                onClick={fetchEmails}
                                className="text-[10px] font-black uppercase tracking-widest text-brand-green hover:text-brand-green-light transition-colors"
                            >
                                {t.refresh}
                            </button>
                        </div>
                        <div className="flex-1 overflow-y-auto p-6 space-y-4">
                            {isLoadingEmails ? (
                                <div className="py-20 text-center">
                                    <div className="w-8 h-8 border-4 border-brand-green/20 border-t-brand-green rounded-full animate-spin mx-auto mb-4"></div>
                                    <p className="text-zinc-500 text-sm">{t.superadmin_fetching_emails_server}</p>
                                </div>
                            ) : emails.length === 0 ? (
                                <div className="py-20 text-center space-y-4">
                                    <Mail size={48} className="mx-auto text-zinc-800" />
                                    <p className="text-zinc-500">{t.superadmin_no_emails_fetched}</p>
                                </div>
                            ) : (
                                emails.map(email => {
                                    const isProcessed = email.ingestion_status === 'PROCESSED';
                                    const isIgnored = email.ingestion_status === 'IGNORED';
                                    const isNeedsReview = email.ingestion_status === 'NEEDS_REVIEW';
                                    const isError = email.ingestion_status === 'ERROR';

                                    const extractedData = email.extracted_data?.mission || {};
                                    const address = typeof extractedData.address === 'string' ? extractedData.address : extractedData.address?.raw || '';
                                    const contact = extractedData.contactOnSite?.name || '';

                                    return (
                                        <div key={email.id} className="p-6 bg-zinc-900/50 rounded-3xl border border-zinc-800/50 space-y-6 hover:border-zinc-700 transition-all group overflow-hidden relative">
                                            <div className="flex items-start gap-4">
                                                <div className="shrink-0 mt-1">
                                                    {isProcessed ? (
                                                        <CheckCircle2 className="text-brand-green" size={20} />
                                                    ) : isIgnored ? (
                                                        <XCircle className="text-zinc-600" size={20} />
                                                    ) : (
                                                        <Clock className="text-zinc-500" size={20} />
                                                    )}
                                                </div>

                                                <div className="flex-1 space-y-4">
                                                    <div className="flex justify-between items-start">
                                                        <div className="space-y-1">
                                                            <div className="flex items-center gap-3">
                                                                <span className={`text-[10px] font-black px-2.5 py-1 rounded-md uppercase tracking-widest ${isProcessed ? 'bg-brand-green/10 text-brand-green' :
                                                                    isIgnored ? 'bg-zinc-800 text-zinc-500' :
                                                                        'bg-zinc-800 text-zinc-400'
                                                                    }`}>
                                                                    {email.ingestion_status || 'PENDING'}
                                                                </span>
                                                                <span className="text-[10px] font-mono text-zinc-600">
                                                                    {new Date(email.received_at).toLocaleTimeString()}
                                                                </span>
                                                            </div>
                                                            <h4 className={`font-black text-lg tracking-tight ${isIgnored ? 'text-zinc-600' : 'text-white'}`}>
                                                                {email.subject}
                                                            </h4>
                                                            <p className={`text-xs ${isIgnored ? 'text-zinc-700' : 'text-zinc-500'}`}>
                                                                {t.from_label}: {email.from_address}
                                                            </p>
                                                        </div>
                                                    </div>

                                                    {isProcessed && (address || contact) && (
                                                        <div className="bg-zinc-950/80 rounded-2xl border border-zinc-800/80 p-5 space-y-3">
                                                            <div className="flex items-center gap-2 text-brand-green mb-1">
                                                                <FileText size={14} />
                                                                <span className="text-[10px] font-black uppercase tracking-widest">{t.extracted_data || 'Extracted Data'}</span>
                                                            </div>
                                                            <div className="grid gap-2">
                                                                {address && (
                                                                    <div className="flex gap-2 text-xs">
                                                                        <span className="text-zinc-600 font-bold shrink-0">{t.superadmin_addr || 'Addr:'}</span>
                                                                        <span className="text-zinc-400 leading-tight">{address}</span>
                                                                    </div>
                                                                )}
                                                                {contact && (
                                                                    <div className="flex gap-2 text-xs">
                                                                        <span className="text-zinc-600 font-bold shrink-0">{t.superadmin_contact_label || 'Contact:'}</span>
                                                                        <span className="text-zinc-400">{contact}</span>
                                                                    </div>
                                                                )}
                                                            </div>
                                                        </div>
                                                    )}

                                                    {isIgnored && email.ingestion_reason && (
                                                        <p className="text-xs italic text-zinc-700 leading-relaxed font-medium">
                                                            {email.ingestion_reason}
                                                        </p>
                                                    )}
                                                </div>
                                            </div>
                                        </div>
                                    );
                                })
                            )}
                        </div>
                    </div>
                )}
            </div>

            {showCreateAdminModal && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
                    <div className="absolute inset-0 bg-brand-black/95 backdrop-blur-md" onClick={() => setShowCreateAdminModal(false)}></div>
                    <div className="z-10 w-full max-w-lg bg-zinc-950 border border-zinc-900 rounded-[2rem] p-6 md:p-8 shadow-2xl max-h-[90vh] overflow-y-auto">
                        <div className="flex justify-between items-start mb-6">
                            <h3 className="text-xl md:text-2xl font-black text-white uppercase tracking-tight">{t.createAdmin}</h3>
                            <button onClick={() => setShowCreateAdminModal(false)} className="md:hidden p-2 text-zinc-500 hover:text-white transition-colors">
                                <X size={20} />
                            </button>
                        </div>
                        <form onSubmit={handleCreateSubmit} className="space-y-4 md:space-y-6">
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div className="space-y-2">
                                    <label className="text-[10px] font-black uppercase text-zinc-500 ml-2">{t.contactFirstName}</label>
                                    <input required value={newAdmin.firstName} onChange={e => setNewAdmin({ ...newAdmin, firstName: e.target.value })} type="text" className="w-full bg-zinc-900 border border-zinc-800 rounded-xl py-2.5 px-4 text-white text-sm focus:border-brand-green outline-none transition-all" />
                                </div>
                                <div className="space-y-2">
                                    <label className="text-[10px] font-black uppercase text-zinc-500 ml-2">{t.contactLastName}</label>
                                    <input required value={newAdmin.lastName} onChange={e => setNewAdmin({ ...newAdmin, lastName: e.target.value })} type="text" className="w-full bg-zinc-900 border border-zinc-800 rounded-xl py-2.5 px-4 text-white text-sm focus:border-brand-green outline-none transition-all" />
                                </div>
                            </div>
                            <div className="space-y-2">
                                <label className="text-[10px] font-black uppercase text-zinc-500 ml-2">{t.email}</label>
                                <input required value={newAdmin.email} onChange={e => setNewAdmin({ ...newAdmin, email: e.target.value })} type="email" className="w-full bg-zinc-900 border border-zinc-800 rounded-xl py-2.5 px-4 text-white text-sm focus:border-brand-green outline-none transition-all" />
                            </div>
                            <div className="space-y-2">
                                <label className="text-[10px] font-black uppercase text-zinc-500 ml-2">{t.gsm}</label>
                                <input required value={newAdmin.phone} onChange={e => setNewAdmin({ ...newAdmin, phone: e.target.value })} type="tel" className="w-full bg-zinc-900 border border-zinc-800 rounded-xl py-2.5 px-4 text-white text-sm focus:border-brand-green outline-none transition-all" />
                            </div>

                            <div className="flex flex-col md:flex-row gap-3 pt-4">
                                <button type="button" onClick={() => setShowCreateAdminModal(false)} className="order-2 md:order-1 flex-1 py-3.5 rounded-xl border border-zinc-800 font-bold uppercase text-[10px] md:text-xs text-zinc-500 hover:bg-zinc-900 transition-all">{t.cancel}</button>
                                <button type="submit" className="order-1 md:order-2 flex-1 py-3.5 rounded-xl bg-brand-green text-brand-black font-black uppercase text-[10px] md:text-xs tracking-widest hover:scale-105 transition-all shadow-xl shadow-brand-green/20">{t.create}</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

export default SuperAdminDashboard;

