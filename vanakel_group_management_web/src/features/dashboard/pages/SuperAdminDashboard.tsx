
import React, { useState } from 'react';
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
    AlertCircle
} from 'lucide-react';
import { SignupRequest, AdminUser, Language } from '@/types';
import { TRANSLATIONS } from '@/utils/constants';

interface SuperAdminDashboardProps {
    requests: SignupRequest[];
    admins: AdminUser[];
    onApprove: (request: SignupRequest) => void;
    onReject: (requestId: string) => void;
    onCreateAdmin: (admin: Omit<AdminUser, 'id' | 'createdAt'>) => void;
    lang: Language;
}

const SuperAdminDashboard: React.FC<SuperAdminDashboardProps> = ({
    requests,
    admins,
    onApprove,
    onReject,
    onCreateAdmin,
    lang
}) => {
    const t = TRANSLATIONS[lang];
    const [activeTab, setActiveTab] = useState<'requests' | 'admins'>('requests');
    const [showCreateAdminModal, setShowCreateAdminModal] = useState(false);
    const [newAdmin, setNewAdmin] = useState({
        firstName: '',
        lastName: '',
        email: '',
        phone: ''
    });

    const handleCreateSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        onCreateAdmin(newAdmin);
        setNewAdmin({ firstName: '', lastName: '', email: '', phone: '' });
        setShowCreateAdminModal(false);
    };

    return (
        <div className="flex flex-col h-full space-y-8 animate-in fade-in duration-500 max-w-7xl mx-auto">
            <div className="flex justify-between items-end gap-4">
                <div>
                    <h1 className="text-3xl font-black text-white">{t.superAdmin}</h1>
                    <p className="text-zinc-500 text-sm mt-1">{t.overview_subtitle}</p>
                </div>
                <div className="flex gap-2 bg-zinc-950 p-1 rounded-xl border border-zinc-800">
                    <button
                        onClick={() => setActiveTab('requests')}
                        className={`px-4 py-2 rounded-lg text-xs font-black uppercase tracking-widest transition-all ${activeTab === 'requests' ? 'bg-zinc-800 text-white' : 'text-zinc-500 hover:text-zinc-300'}`}
                    >
                        {t.pendingRequests} ({requests.length})
                    </button>
                    <button
                        onClick={() => setActiveTab('admins')}
                        className={`px-4 py-2 rounded-lg text-xs font-black uppercase tracking-widest transition-all ${activeTab === 'admins' ? 'bg-zinc-800 text-white' : 'text-zinc-500 hover:text-zinc-300'}`}
                    >
                        {t.adminList} ({admins.length})
                    </button>
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
                                requests.map(req => (
                                    <div key={req.id} className="p-6 bg-zinc-900/50 rounded-2xl border border-zinc-800/50 flex flex-col md:flex-row justify-between items-start md:items-center gap-6 hover:border-zinc-700 transition-colors">
                                        <div className="flex gap-4">
                                            <div className="w-12 h-12 bg-zinc-950 rounded-xl flex items-center justify-center border border-zinc-800 shrink-0">
                                                {req.role === 'ADMIN' ? <ShieldCheck className="text-brand-green" /> : <Building2 className="text-blue-400" />}
                                            </div>
                                            <div>
                                                <div className="flex items-center gap-2">
                                                    <h4 className="font-bold text-white">{req.firstName} {req.lastName}</h4>
                                                    <span className={`text-[8px] font-black px-1.5 py-0.5 rounded uppercase ${req.role === 'ADMIN' ? 'bg-brand-green/10 text-brand-green' : 'bg-blue-400/10 text-blue-400'}`}>
                                                        {req.role}
                                                    </span>
                                                </div>
                                                <div className="flex gap-4 mt-2 text-xs text-zinc-500">
                                                    <span className="flex items-center gap-1"><Mail size={12} /> {req.email}</span>
                                                    <span className="flex items-center gap-1"><Phone size={12} /> {req.phone}</span>
                                                </div>
                                                {req.companyName && (
                                                    <p className="text-xs text-zinc-500 mt-1 italic flex items-center gap-1">
                                                        <Building2 size={12} /> {req.companyName}
                                                    </p>
                                                )}
                                            </div>
                                        </div>
                                        <div className="flex gap-2 w-full md:w-auto">
                                            <button
                                                onClick={() => onReject(req.id)}
                                                className="flex-1 md:flex-none px-4 py-2.5 rounded-xl border border-zinc-800 hover:bg-red-500/10 hover:border-red-500/50 hover:text-red-500 transition-all text-xs font-bold uppercase"
                                            >
                                                <X size={16} className="inline-block mr-2" /> {t.reject}
                                            </button>
                                            <button
                                                onClick={() => onApprove(req)}
                                                className="flex-1 md:flex-none px-4 py-2.5 rounded-xl bg-brand-green text-brand-black hover:scale-105 transition-all text-xs font-black uppercase"
                                            >
                                                <Check size={16} className="inline-block mr-2" strokeWidth={3} /> {t.approve}
                                            </button>
                                        </div>
                                    </div>
                                ))
                            )}
                        </div>
                    </div>
                )}

                {activeTab === 'admins' && (
                    <div className="space-y-6 flex flex-col h-full">
                        <div className="flex justify-end">
                            <button
                                onClick={() => setShowCreateAdminModal(true)}
                                className="bg-brand-green text-brand-black px-6 py-3 rounded-xl font-black text-xs uppercase tracking-widest hover:bg-brand-green-light transition-all shadow-lg flex items-center gap-2"
                            >
                                <Plus size={16} strokeWidth={3} /> {t.createAdmin}
                            </button>
                        </div>

                        <div className="bg-zinc-950 rounded-2xl border border-zinc-800 overflow-hidden flex-1 flex flex-col">
                            <table className="w-full text-left">
                                <thead className="bg-zinc-900/50 border-b border-zinc-800">
                                    <tr>
                                        <th className="px-6 py-4 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.contact_name}</th>
                                        <th className="px-6 py-4 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.email}</th>
                                        <th className="px-6 py-4 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.gsm}</th>
                                        <th className="px-6 py-4 text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.created_at}</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-zinc-900">
                                    {admins.map(admin => (
                                        <tr key={admin.id} className="hover:bg-zinc-900/30 transition-colors group">
                                            <td className="px-6 py-4">
                                                <div className="flex items-center gap-3">
                                                    <div className="w-8 h-8 rounded-full bg-zinc-800 flex items-center justify-center text-[10px] font-bold text-zinc-400 group-hover:bg-brand-green group-hover:text-brand-black transition-colors">
                                                        {admin.firstName[0]}{admin.lastName[0]}
                                                    </div>
                                                    <span className="font-bold text-white">{admin.firstName} {admin.lastName}</span>
                                                </div>
                                            </td>
                                            <td className="px-6 py-4 text-xs text-zinc-400">{admin.email}</td>
                                            <td className="px-6 py-4 text-xs text-zinc-400">{admin.phone}</td>
                                            <td className="px-6 py-4 text-[10px] text-zinc-600 font-mono capitalize">
                                                {new Date(admin.createdAt).toLocaleDateString()}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                )}
            </div>

            {showCreateAdminModal && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
                    <div className="absolute inset-0 bg-brand-black/90 backdrop-blur-md" onClick={() => setShowCreateAdminModal(false)}></div>
                    <div className="z-10 w-full max-w-lg bg-zinc-950 border border-zinc-900 rounded-[2rem] p-8 shadow-2xl">
                        <h3 className="text-2xl font-black text-white mb-6 uppercase tracking-tight">{t.createAdmin}</h3>
                        <form onSubmit={handleCreateSubmit} className="space-y-6">
                            <div className="grid grid-cols-2 gap-4">
                                <div className="space-y-2">
                                    <label className="text-[10px] font-black uppercase text-zinc-500 ml-2">{t.contactFirstName}</label>
                                    <input required value={newAdmin.firstName} onChange={e => setNewAdmin({ ...newAdmin, firstName: e.target.value })} type="text" className="w-full bg-zinc-900 border border-zinc-800 rounded-xl py-3 px-4 text-white focus:border-brand-green outline-none transition-all" />
                                </div>
                                <div className="space-y-2">
                                    <label className="text-[10px] font-black uppercase text-zinc-500 ml-2">{t.contactLastName}</label>
                                    <input required value={newAdmin.lastName} onChange={e => setNewAdmin({ ...newAdmin, lastName: e.target.value })} type="text" className="w-full bg-zinc-900 border border-zinc-800 rounded-xl py-3 px-4 text-white focus:border-brand-green outline-none transition-all" />
                                </div>
                            </div>
                            <div className="space-y-2">
                                <label className="text-[10px] font-black uppercase text-zinc-500 ml-2">{t.email}</label>
                                <input required value={newAdmin.email} onChange={e => setNewAdmin({ ...newAdmin, email: e.target.value })} type="email" className="w-full bg-zinc-900 border border-zinc-800 rounded-xl py-3 px-4 text-white focus:border-brand-green outline-none transition-all" />
                            </div>
                            <div className="space-y-2">
                                <label className="text-[10px] font-black uppercase text-zinc-500 ml-2">{t.gsm}</label>
                                <input required value={newAdmin.phone} onChange={e => setNewAdmin({ ...newAdmin, phone: e.target.value })} type="tel" className="w-full bg-zinc-900 border border-zinc-800 rounded-xl py-3 px-4 text-white focus:border-brand-green outline-none transition-all" />
                            </div>

                            <div className="flex gap-4 pt-4">
                                <button type="button" onClick={() => setShowCreateAdminModal(false)} className="flex-1 py-4 rounded-xl border border-zinc-800 font-bold uppercase text-xs text-zinc-500 hover:bg-zinc-900 transition-all">{t.cancel}</button>
                                <button type="submit" className="flex-1 py-4 rounded-xl bg-brand-green text-brand-black font-black uppercase text-xs tracking-widest hover:scale-105 transition-all shadow-xl shadow-brand-green/20">{t.create}</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

export default SuperAdminDashboard;
