
import React from 'react';
import { Bell, CheckCircle2, XCircle, Clock, AlertTriangle, ChevronRight } from 'lucide-react';
import { AppNotification, Language } from '@/types';
import { TRANSLATIONS } from '@/utils/constants';

interface SyndicNotificationsPageProps {
    notifications: AppNotification[];
    onNotificationClick: (id: string, interventionId?: string) => void;
    lang: Language;
    t: any;
}

const SyndicNotificationsPage: React.FC<SyndicNotificationsPageProps> = ({
    notifications,
    onNotificationClick,
    lang,
    t
}) => {
    return (
        <div className="space-y-6 md:space-y-8 animate-in fade-in duration-500 max-w-4xl mx-auto">
            <div className="flex justify-between items-end">
                <div>
                    <h1 className="text-2xl md:text-3xl font-black text-white uppercase tracking-tight">{t.notifications || 'Notifications'}</h1>
                    <p className="text-zinc-500 text-sm mt-1">Stay updated on your mission requests and intervention progress</p>
                </div>
                <div className="bg-zinc-900 px-3 py-1 rounded-full text-[10px] font-black uppercase text-zinc-500 border border-zinc-800">
                    {notifications.length} Alerts
                </div>
            </div>

            <div className="bg-zinc-950 border border-zinc-800 rounded-3xl overflow-hidden shadow-2xl">
                <div className="divide-y divide-zinc-900">
                    {notifications.length === 0 ? (
                        <div className="p-16 text-center">
                            <Bell size={48} className="mx-auto text-zinc-800 mb-4 opacity-20" />
                            <p className="text-zinc-600 font-medium">No new notifications.</p>
                        </div>
                    ) : (
                        notifications.map(n => (
                            <div
                                key={n.id}
                                onClick={() => onNotificationClick(n.id, n.interventionId)}
                                className={`p-6 flex gap-4 hover:bg-zinc-900/50 transition-all cursor-pointer group ${!n.read ? 'bg-brand-green/5' : ''}`}
                            >
                                <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${n.type === 'MISSION_DECISION' && n.title.includes('Accepted') ? 'bg-green-500/10 text-green-500' :
                                        n.type === 'MISSION_DECISION' && n.title.includes('Rejected') ? 'bg-red-500/10 text-red-500' :
                                            n.type === 'STATUS_CHANGE' && n.title.includes('Completed') ? 'bg-brand-green/10 text-brand-green' :
                                                n.type === 'STATUS_CHANGE' && n.title.includes('Delayed') ? 'bg-orange-500/10 text-orange-500' :
                                                    'bg-zinc-900 text-zinc-500'
                                    }`}>
                                    {n.type === 'MISSION_DECISION' && n.title.includes('Accepted') ? <CheckCircle2 size={20} /> :
                                        n.type === 'MISSION_DECISION' && n.title.includes('Rejected') ? <XCircle size={20} /> :
                                            n.type === 'STATUS_CHANGE' && n.title.includes('Completed') ? <CheckCircle2 size={20} /> :
                                                n.type === 'STATUS_CHANGE' && n.title.includes('Delayed') ? <AlertTriangle size={20} /> :
                                                    <Bell size={20} />}
                                </div>
                                <div className="flex-1 min-w-0">
                                    <div className="flex justify-between items-start mb-1">
                                        <h4 className={`text-sm font-bold ${!n.read ? 'text-white' : 'text-zinc-400'}`}>{n.title}</h4>
                                        <span className="text-[10px] font-mono text-zinc-600">{new Date(n.timestamp).toLocaleDateString()}</span>
                                    </div>
                                    <p className="text-xs text-zinc-500 line-clamp-2 mb-2">{n.buildingAddress}</p>
                                    <div className="flex items-center gap-1 text-[10px] font-black uppercase tracking-widest text-brand-green opacity-0 group-hover:opacity-100 transition-opacity">
                                        View Details <ChevronRight size={12} />
                                    </div>
                                </div>
                                {!n.read && (
                                    <div className="w-2 h-2 rounded-full bg-brand-green mt-2 border border-brand-green/50 shadow-[0_0_8px_rgba(74,222,128,0.5)]"></div>
                                )}
                            </div>
                        ))
                    )}
                </div>
            </div>
        </div>
    );
};

export default SyndicNotificationsPage;
