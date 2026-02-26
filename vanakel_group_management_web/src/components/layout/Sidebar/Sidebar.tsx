import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Building2, LayoutDashboard, ShieldCheck, Clock, ClipboardList, RotateCcw, FileText, Mail, Settings, HelpCircle, LogOut, User } from 'lucide-react';

import SidebarItem from './SidebarItem';
import { Role } from '@/types';

interface SidebarProps {
    role: Role | null;
    stats: {
        ongoing: number;
        delayed: number;
        missions: number;
    };
    t: any;
    isIngesting: boolean;
    setIsTourActive: (active: boolean) => void;
    setRole: (role: Role | null) => void;
}

const Sidebar: React.FC<SidebarProps> = ({
    role,
    stats,
    t,
    isIngesting,
    setIsTourActive,
    setRole
}) => {
    const navigate = useNavigate();
    const location = useLocation();

    const getActiveTab = () => {
        const path = location.pathname;
        const parts = path.split('/');
        if (parts.length > 2 && parts[2] === 'dashboard') return 'dashboard';
        return parts.pop() || 'dashboard';
    };


    const activeTab = getActiveTab();

    const handleTabClick = (tab: string) => {
        const prefix = role === 'SYNDIC' ? 'syndic' : 'admin';
        if (tab === 'dashboard') navigate(`/${prefix}/dashboard`);
        else navigate(`/${prefix}/${tab}`);
    };

    return (
        <aside className="hidden md:flex w-64 flex-col bg-zinc-950 border-r border-zinc-800 shrink-0">
            <div className="p-6 flex items-center gap-3">
                <div className="w-8 h-8 bg-brand-green rounded-lg flex items-center justify-center">
                    <Building2 className="text-brand-black" size={20} />
                </div>
                <span className="font-black text-lg tracking-tight text-white">VANAKEL</span>
            </div>

            <nav className="flex-1 px-4 space-y-2 overflow-y-auto">
                {/* Navigation Items */}
                {role === 'SUPERADMIN' ? (
                    <>
                        <div id="nav-super-admin">
                            <SidebarItem
                                icon={<ShieldCheck size={20} className="text-brand-green" />}
                                label={t.superAdmin}
                                active={activeTab === 'super_admin'}
                                onClick={() => handleTabClick('super_admin')}
                            />
                        </div>

                        <div className="pt-6 mt-6 border-t border-zinc-800">
                            <p className="px-4 mb-2 text-[10px] font-black uppercase text-zinc-600 tracking-widest">System Tools</p>
                            <SidebarItem
                                icon={<Mail size={20} className={isIngesting ? "animate-pulse text-brand-green" : ""} />}
                                label="Email Ingestion"
                                active={activeTab === 'email_ingestion'}
                                onClick={() => handleTabClick('email_ingestion')}
                            />
                            <div id="header-settings">
                                <SidebarItem icon={<Settings size={20} />} label={t.settings} active={activeTab === 'settings'} onClick={() => handleTabClick('settings')} />
                            </div>
                        </div>
                    </>
                ) : (
                    <>
                        <div id="nav-dashboard">
                            <SidebarItem icon={<LayoutDashboard size={20} />} label={t.dashboard} active={activeTab === 'dashboard'} onClick={() => handleTabClick('dashboard')} />
                        </div>

                        {role === 'SYNDIC' ? (
                            <>
                                <div id="nav-missions">
                                    <SidebarItem icon={<ClipboardList size={20} />} label={t.missions} active={activeTab === 'missions'} onClick={() => handleTabClick('missions')} badge={stats.missions} />
                                </div>
                                <div id="nav-ongoing">
                                    <SidebarItem icon={<Clock size={20} />} label={t.interventions || 'Interventions'} active={activeTab === 'ongoing'} onClick={() => handleTabClick('ongoing')} badge={stats.ongoing + stats.delayed} />
                                </div>
                                <div id="nav-management">
                                    <SidebarItem icon={<FileText size={20} />} label={t.management || 'History & Documents'} active={activeTab === 'management'} onClick={() => handleTabClick('management')} />
                                </div>
                                <div id="nav-notifications">
                                    <SidebarItem icon={<Settings size={20} />} label={t.notifications || 'Notifications'} active={activeTab === 'notifications'} onClick={() => handleTabClick('notifications')} />
                                </div>
                                <div id="nav-profile">
                                    <SidebarItem icon={<User size={20} />} label={t.profile || 'Profil'} active={activeTab === 'profile'} onClick={() => handleTabClick('profile')} />
                                </div>
                            </>
                        ) : (
                            <>
                                <div id="nav-management">
                                    <SidebarItem icon={<Building2 size={20} />} label={t.management} active={activeTab === 'management'} onClick={() => handleTabClick('management')} />
                                </div>
                                <div id="nav-ongoing">
                                    <SidebarItem icon={<Clock size={20} />} label={t.ongoing} active={activeTab === 'ongoing'} onClick={() => handleTabClick('ongoing')} badge={stats.ongoing + stats.delayed} />
                                </div>
                                <div id="nav-missions">
                                    <SidebarItem icon={<ClipboardList size={20} />} label={t.missions} active={activeTab === 'missions'} onClick={() => handleTabClick('missions')} badge={stats.missions} />
                                </div>
                                {/* Entretien Item */}
                                <div className="pl-4">
                                    <SidebarItem
                                        icon={<RotateCcw size={18} className="text-orange-500" />}
                                        label={t.maintenance || 'Entretien'}
                                        active={activeTab === 'entretien_list'}
                                        onClick={() => handleTabClick('entretien_list')}
                                    />
                                </div>
                                <div id="nav-reports">
                                    <SidebarItem icon={<FileText size={20} />} label={t.reports} active={activeTab === 'reports'} onClick={() => handleTabClick('reports')} />
                                </div>
                            </>
                        )}


                    </>
                )}
            </nav>

            <div className="p-4 border-t border-zinc-800">
                <button
                    id="btn-help"
                    onClick={() => setIsTourActive(true)}
                    className="flex items-center gap-3 px-4 py-3 w-full rounded-xl text-zinc-500 hover:bg-zinc-900 hover:text-white transition-colors mb-2"
                >
                    <HelpCircle size={20} />
                    <span className="text-sm font-medium">{t.help_tutorial || 'Help & Tutorial'}</span>

                </button>
                <button onClick={() => setRole(null)} className="flex items-center gap-3 px-4 py-3 w-full rounded-xl text-red-500 hover:bg-red-500/10 transition-colors">
                    <LogOut size={20} />
                    <span className="text-sm font-bold">{t.logout}</span>
                </button>

            </div>
        </aside>
    );
};

export default Sidebar;
