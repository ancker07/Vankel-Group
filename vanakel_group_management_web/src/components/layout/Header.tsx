
import React from 'react';
import { Bell } from 'lucide-react';
import { Role, Language as LangType, AppNotification } from '@/types';
import NotificationPanel from '@/components/common/NotificationPanel';

interface HeaderProps {
    role: Role | null;
    lang: LangType;
    setLang: (lang: LangType) => void;
    notifications: AppNotification[];
    setNotifications: React.Dispatch<React.SetStateAction<AppNotification[]>>;
    showNotifications: boolean;
    setShowNotifications: (show: boolean) => void;
    setSelectedInterventionId: (id: string | null) => void;
    t: any;
    userName?: string;
}

import UserAvatar from '@/components/common/UserAvatar';

const Header: React.FC<HeaderProps> = ({
    role,
    lang,
    setLang,
    notifications,
    setNotifications,
    showNotifications,
    setShowNotifications,
    setSelectedInterventionId,
    t,
    userName = 'Vanakel User'
}) => {
    return (
        <header className="h-16 md:h-20 border-b border-zinc-800 flex items-center justify-between px-4 md:px-8 bg-zinc-950/80 backdrop-blur-xl shrink-0 z-20 sticky top-0">
            <div className="flex items-center gap-4 md:hidden">
                <span className="font-black text-lg text-white">VANAKEL</span>
            </div>

            <div className="hidden md:flex items-center gap-2">
                <span className="text-xs font-bold text-zinc-500 uppercase tracking-widest">{t.currentRole}:</span>
                <span className="px-2 py-1 bg-zinc-800 rounded text-xs font-black text-white">{role}</span>
                {role === 'SUPERADMIN' && <span className="ml-2 px-2 py-1 bg-brand-green text-brand-black rounded text-[10px] font-black uppercase">{t.superAdmin}</span>}
            </div>

            <div className="flex items-center gap-3 md:gap-6">
                <div className="relative">
                    <button
                        onClick={() => setShowNotifications(!showNotifications)}
                        className="p-2 md:p-2.5 rounded-full hover:bg-zinc-800 text-zinc-400 hover:text-white transition-colors relative"
                    >
                        <Bell size={20} />
                        {notifications.filter(n => !n.read).length > 0 && (
                            <span className="absolute top-2 right-2 w-2 h-2 bg-brand-green rounded-full"></span>
                        )}
                    </button>
                    {showNotifications && (
                        <NotificationPanel
                            notifications={notifications}
                            onClose={() => setShowNotifications(false)}
                            onMarkRead={(id) => setNotifications(prev => prev.map(n => n.id === id ? { ...n, read: true } : n))}
                            onMarkAllRead={() => setNotifications(prev => prev.map(n => ({ ...n, read: true })))}
                            onSelect={(id) => setSelectedInterventionId(id)}
                            title="Notifications"
                        />
                    )}
                </div>

                <div className="flex gap-2">
                    {(['EN', 'FR', 'NL'] as LangType[]).map(l => (
                        <button
                            key={l}
                            onClick={() => setLang(l)}
                            className={`text-[10px] md:text-xs font-black px-2 py-1 rounded transition-colors ${lang === l ? 'bg-brand-green text-brand-black' : 'text-zinc-600 hover:text-zinc-300'}`}
                        >
                            {l}
                        </button>
                    ))}
                </div>

                <UserAvatar name={userName} size="md" />
            </div>
        </header>
    );
};

export default Header;
