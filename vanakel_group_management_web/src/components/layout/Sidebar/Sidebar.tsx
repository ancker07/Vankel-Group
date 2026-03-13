import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { HelpCircle, LogOut } from 'lucide-react';

import SidebarContent from './SidebarContent';

import SidebarItem from './SidebarItem';
import { Role } from '@/types';
import logo from '@/assets/vankel_bg_2.png';

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
        if (tab === 'contact_us') {
            window.open('/#contact', '_blank');
            return;
        }
        let prefix = 'admin';
        if (role === 'SYNDIC') prefix = 'syndic';
        else if (role === 'SUPERADMIN') prefix = 'superadmin';

        if (tab === 'dashboard') navigate(`/${prefix}/dashboard`);
        else navigate(`/${prefix}/${tab}`);
    };

    return (
        <aside className="hidden md:flex w-64 flex-col bg-zinc-950 border-r border-zinc-800 shrink-0">
            <div className="py-8 flex items-center justify-center">
                <img src={logo} alt="Vankel Logo" className="h-12 w-auto object-contain" />
            </div>

            <SidebarContent
                role={role}
                stats={stats}
                t={t}
                isIngesting={isIngesting}
                activeTab={activeTab}
                handleTabClick={handleTabClick}
            />

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
