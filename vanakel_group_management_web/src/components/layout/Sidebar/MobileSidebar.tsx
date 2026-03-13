import React from 'react';
import { X, HelpCircle, LogOut } from 'lucide-react';
import SidebarContent from './SidebarContent';
import { Role } from '@/types';
import logo from '@/assets/vankel_bg_2.png';

interface MobileSidebarProps {
    isOpen: boolean;
    onClose: () => void;
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
    activeTab: string;
    handleTabClick: (tab: string) => void;
}

const MobileSidebar: React.FC<MobileSidebarProps> = ({
    isOpen,
    onClose,
    role,
    stats,
    t,
    isIngesting,
    setIsTourActive,
    setRole,
    activeTab,
    handleTabClick
}) => {
    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[60] md:hidden">
            {/* Overlay */}
            <div 
                className="absolute inset-0 bg-black/60 backdrop-blur-sm transition-opacity"
                onClick={onClose}
            />
            
            {/* Drawer */}
            <aside 
                className={`absolute inset-y-0 left-0 w-72 bg-zinc-950 border-r border-zinc-800 flex flex-col shadow-2xl transition-transform duration-300 ease-in-out ${isOpen ? 'translate-x-0' : '-translate-x-full'}`}
            >
                <div className="flex items-center justify-between p-6">
                    <img src={logo} alt="Vankel Logo" className="h-10 w-auto object-contain" />
                    <button 
                        onClick={onClose}
                        className="p-2 rounded-full bg-zinc-900 text-zinc-400 hover:text-white transition-colors"
                    >
                        <X size={20} />
                    </button>
                </div>

                <div className="flex-1 overflow-y-auto px-2">
                    <SidebarContent
                        role={role}
                        stats={stats}
                        t={t}
                        isIngesting={isIngesting}
                        activeTab={activeTab}
                        handleTabClick={(tab) => {
                            handleTabClick(tab);
                            onClose();
                        }}
                    />
                </div>

                <div className="p-4 border-t border-zinc-800 bg-zinc-950/50">
                    <button
                        onClick={() => {
                            setIsTourActive(true);
                            onClose();
                        }}
                        className="flex items-center gap-3 px-4 py-3 w-full rounded-xl text-zinc-500 hover:bg-zinc-900 hover:text-white transition-colors mb-2"
                    >
                        <HelpCircle size={20} />
                        <span className="text-sm font-medium">{t.help_tutorial || 'Help & Tutorial'}</span>
                    </button>
                    <button 
                        onClick={() => {
                            setRole(null);
                            onClose();
                        }} 
                        className="flex items-center gap-3 px-4 py-3 w-full rounded-xl text-red-500 hover:bg-red-500/10 transition-colors"
                    >
                        <LogOut size={20} />
                        <span className="text-sm font-bold">{t.logout}</span>
                    </button>
                </div>
            </aside>
        </div>
    );
};

export default MobileSidebar;
