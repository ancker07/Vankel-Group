import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { LayoutDashboard, Building2, Clock, ClipboardList, FileText, ShieldCheck, Mail, Settings, User } from 'lucide-react';

import { Role } from '@/types';

interface BottomNavProps {
    role: Role | null;
    stats: {
        ongoing: number;
        delayed: number;
        missions: number;
    };
    t: any;
}


const BottomNav: React.FC<BottomNavProps> = ({ role, stats, t }) => {

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
        <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-zinc-950 border-t border-zinc-800 flex justify-between px-2 py-2 z-50 safe-area-pb">
            {role === 'SUPERADMIN' ? (
                <>
                    <button
                        onClick={() => handleTabClick('super_admin')}
                        className={`flex-1 flex flex-col items-center gap-1 p-2 rounded-xl transition-all ${activeTab === 'super_admin' ? 'text-brand-green' : 'text-zinc-500'}`}
                    >
                        <ShieldCheck size={20} />
                        <span className="text-[9px] font-bold">{t.admin_short || 'Admin'}</span>


                    </button>
                    <button
                        onClick={() => handleTabClick('email_ingestion')}
                        className={`flex-1 flex flex-col items-center gap-1 p-2 rounded-xl transition-all ${activeTab === 'email_ingestion' ? 'text-brand-green' : 'text-zinc-500'}`}
                    >
                        <Mail size={20} />
                        <span className="text-[9px] font-bold">{t.emails_short || 'Emails'}</span>


                    </button>
                    <button
                        onClick={() => handleTabClick('settings')}
                        className={`flex-1 flex flex-col items-center gap-1 p-2 rounded-xl transition-all ${activeTab === 'settings' ? 'text-brand-green' : 'text-zinc-500'}`}
                    >
                        <Settings size={20} />
                        <span className="text-[9px] font-bold">{t.settings}</span>

                    </button>
                </>
            ) : (
                <>
                    <button
                        id="mobile-nav-dashboard"
                        onClick={() => handleTabClick('dashboard')}
                        className={`flex-1 flex flex-col items-center gap-1 p-2 rounded-xl transition-all ${activeTab === 'dashboard' ? 'text-brand-green' : 'text-zinc-500'}`}
                    >
                        <LayoutDashboard size={20} />
                        <span className="text-[10px] font-bold whitespace-nowrap">{t.dash_short || 'Dash'}</span>


                    </button>
                    {role !== 'SYNDIC' && (
                        <button
                            id="mobile-nav-management"
                            onClick={() => handleTabClick('management')}
                            className={`flex-1 flex flex-col items-center gap-1 p-2 rounded-xl transition-all ${activeTab === 'management' ? 'text-brand-green' : 'text-zinc-500'}`}
                        >
                            <Building2 size={20} />
                            <span className="text-[9px] font-bold">{t.management}</span>

                        </button>
                    )}
                    <button
                        id="mobile-nav-ongoing"
                        onClick={() => handleTabClick('ongoing')}
                        className={`flex-1 flex flex-col items-center gap-1 p-2 rounded-xl transition-all relative ${activeTab === 'ongoing' ? 'text-brand-green' : 'text-zinc-500'}`}
                    >
                        <div className="relative">
                            <Clock size={20} />
                            {(stats.ongoing + stats.delayed) > 0 && (
                                <span className="absolute -top-1 -right-2 bg-brand-green text-brand-black text-[9px] font-bold px-1 rounded-full min-w-[14px] flex items-center justify-center">
                                    {stats.ongoing + stats.delayed}
                                </span>
                            )}
                        </div>
                        <span className="text-[10px] font-bold whitespace-nowrap">{role === 'SYNDIC' ? (t.ongoing_short || 'Suivi') : 'Interv.'}</span>

                    </button>
                    <button
                        id="mobile-nav-missions"
                        onClick={() => handleTabClick('missions')}
                        className={`flex-1 flex flex-col items-center gap-1 p-2 rounded-xl transition-all relative ${activeTab === 'missions' ? 'text-brand-green' : 'text-zinc-500'}`}
                    >
                        <div className="relative">
                            <ClipboardList size={20} />
                            {stats.missions > 0 && (
                                <span className="absolute -top-1 -right-2 bg-blue-500 text-white text-[9px] font-bold px-1 rounded-full min-w-[14px] flex items-center justify-center">
                                    {stats.missions}
                                </span>
                            )}
                        </div>
                        <span className="text-[10px] font-bold whitespace-nowrap">{t.missions_short || 'Missions'}</span>

                    </button>
                    {role !== 'SYNDIC' ? (
                        <button
                            id="mobile-nav-reports"
                            onClick={() => handleTabClick('reports')}
                            className={`flex-1 flex flex-col items-center gap-1 p-2 rounded-xl transition-all ${activeTab === 'reports' ? 'text-brand-green' : 'text-zinc-500'}`}
                        >
                            <FileText size={20} />
                            <span className="text-[9px] font-bold">{t.reports}</span>

                        </button>
                    ) : (
                        <button
                            id="mobile-nav-profile"
                            onClick={() => handleTabClick('profile')}
                            className={`flex-1 flex flex-col items-center gap-1 p-2 rounded-xl transition-all ${activeTab === 'profile' ? 'text-brand-green' : 'text-zinc-500'}`}
                        >
                            <User size={20} />
                            <span className="text-[10px] font-bold whitespace-nowrap">{t.profile_short || 'Profil'}</span>

                        </button>
                    )}
                </>

            )}
        </nav>
    );
};

export default BottomNav;
