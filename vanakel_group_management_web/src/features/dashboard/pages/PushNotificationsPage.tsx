import React, { useState, useEffect } from 'react';
import { Bell, Send, History, CheckCircle2, AlertCircle, Users, User, Trash2, Copy, Eye, X } from 'lucide-react';
import { dataService } from '@/services/dataService';
import { TRANSLATIONS } from '@/utils/constants';
import { Language } from '@/types';

interface PushNotificationsPageProps {
    lang: Language;
}

const PushNotificationsPage: React.FC<PushNotificationsPageProps> = ({ lang }) => {
    const t = TRANSLATIONS[lang];
    const [title, setTitle] = useState('');
    const [body, setBody] = useState('');
    const [target, setTarget] = useState<'all' | 'specific'>('all');
    const [selectedUsers, setSelectedUsers] = useState<number[]>([]);
    const [allUsers, setAllUsers] = useState<any[]>([]);
    const [history, setHistory] = useState<any[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [isHistoryLoading, setIsHistoryLoading] = useState(false);
    const [statusMessage, setStatusMessage] = useState<{ type: 'success' | 'error', text: string } | null>(null);
    const [viewingToken, setViewingToken] = useState<string | null>(null);
    const [copySuccess, setCopySuccess] = useState<number | null>(null);

    useEffect(() => {
        fetchHistory();
        fetchAllUsers();
    }, []);

    const fetchHistory = async () => {
        setIsHistoryLoading(true);
        try {
            const data = await dataService.getNotificationHistory();
            setHistory(data);
        } catch (error) {
            console.error("Error fetching history:", error);
        } finally {
            setIsHistoryLoading(false);
        }
    };

    const fetchAllUsers = async () => {
        try {
            const data = await dataService.getAllUsers();
            setAllUsers(data.filter((u: any) => u.fcm_token)); // Only show users who can receive notifications
        } catch (error) {
            console.error("Error fetching users:", error);
        }
    };

    const handleSend = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!title || !body) {
            setStatusMessage({ type: 'error', text: t.fill_required || 'Please fill in all required fields.' });
            return;
        }

        if (target === 'specific' && selectedUsers.length === 0) {
            setStatusMessage({ type: 'error', text: t.select_recipients_error || 'Please select at least one recipient.' });
            return;
        }

        setIsLoading(true);
        setStatusMessage(null);

        try {
            const response = await dataService.sendPushNotification({
                title,
                body,
                target,
                user_ids: target === 'specific' ? selectedUsers : undefined
            });

            setStatusMessage({ type: 'success', text: response.message || t.notification_sent_success || 'Notification sent successfully!' });
            setTitle('');
            setBody('');
            setSelectedUsers([]);
            fetchHistory();
        } catch (error: any) {
            setStatusMessage({ 
                type: 'error', 
                text: error.response?.data?.message || t.notification_sent_error || 'Failed to send notification. Please try again.' 
            });
        } finally {
            setIsLoading(false);
        }
    };

    const toggleUserSelection = (userId: number) => {
        setSelectedUsers(prev => 
            prev.includes(userId) 
                ? prev.filter(id => id !== userId) 
                : [...prev, userId]
        );
    };

    const handleCopy = (token: string, id: number) => {
        navigator.clipboard.writeText(token);
        setCopySuccess(id);
        setTimeout(() => setCopySuccess(null), 2000);
    };

    return (
        <div className="p-6 max-w-7xl mx-auto space-y-8">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-black text-white flex items-center gap-3">
                        <Bell className="text-brand-green" />
                        {t.push_notifications_title || 'Push Notifications'}
                    </h1>
                    <p className="text-zinc-400 mt-1">{t.push_notifications_subtitle || 'Broadcast messages to mobile application users'}</p>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Send Form */}
                <div className="lg:col-span-2 space-y-6">
                    <div className="bg-zinc-900/50 border border-zinc-800 rounded-3xl p-8 backdrop-blur-sm">
                        <h2 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
                            <Send size={20} className="text-brand-green" />
                            {t.compose_notification || 'Compose Notification'}
                        </h2>

                        <form onSubmit={handleSend} className="space-y-6">
                            <div className="space-y-4">
                                <div>
                                    <label className="block text-sm font-medium text-zinc-400 mb-2">{t.target_audience || 'Target Audience'}</label>
                                    <div className="flex gap-4 p-1 bg-zinc-950 rounded-xl border border-zinc-800 w-fit">
                                        <button
                                            type="button"
                                            onClick={() => setTarget('all')}
                                            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold transition-all ${target === 'all' ? 'bg-brand-green text-zinc-950 shadow-lg shadow-brand-green/20' : 'text-zinc-500 hover:text-zinc-300'}`}
                                        >
                                            <Users size={16} />
                                            {t.all_registered_devices || 'All Registered Devices'}
                                        </button>
                                        <button
                                            type="button"
                                            onClick={() => setTarget('specific')}
                                            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold transition-all ${target === 'specific' ? 'bg-brand-green text-zinc-950 shadow-lg shadow-brand-green/20' : 'text-zinc-500 hover:text-zinc-300'}`}
                                        >
                                            <User size={16} />
                                            {t.specific_users || 'Specific Users'}
                                        </button>
                                    </div>
                                </div>

                                {target === 'specific' && (
                                    <div className="space-y-3">
                                        <label className="block text-sm font-medium text-zinc-400">{t.select_recipients || 'Select Recipients'} ({selectedUsers.length} selected)</label>
                                        <div className="max-h-60 overflow-y-auto grid grid-cols-1 md:grid-cols-2 gap-2 pr-2 custom-scrollbar">
                                            {allUsers.length > 0 ? (
                                                allUsers.map(user => (
                                                    <div 
                                                        key={user.id}
                                                        className={`relative flex items-center gap-3 p-3 rounded-xl border transition-all ${selectedUsers.includes(user.id) ? 'bg-brand-green/10 border-brand-green/50' : 'bg-zinc-950 border-zinc-800 hover:border-zinc-700'}`}
                                                    >
                                                        <div 
                                                            onClick={() => toggleUserSelection(user.id)}
                                                            className={`w-4 h-4 rounded border flex items-center justify-center cursor-pointer ${selectedUsers.includes(user.id) ? 'bg-brand-green border-brand-green' : 'border-zinc-700'}`}
                                                        >
                                                            {selectedUsers.includes(user.id) && <CheckCircle2 size={12} className="text-zinc-950" />}
                                                        </div>
                                                        <div className="flex-1 overflow-hidden" onClick={() => toggleUserSelection(user.id)}>
                                                            <p className="text-sm font-bold text-white truncate">{user.name}</p>
                                                            <p className="text-xs text-zinc-500 truncate">{user.role} • {user.email}</p>
                                                            <p className="text-[10px] text-zinc-600 truncate font-mono mt-1">FCM: {user.fcm_token?.substring(0, 20)}...</p>
                                                        </div>
                                                        <div className="flex flex-col gap-1">
                                                            <button 
                                                                type="button"
                                                                onClick={(e) => { e.stopPropagation(); handleCopy(user.fcm_token, user.id); }}
                                                                className={`p-1.5 rounded-lg transition-colors ${copySuccess === user.id ? 'text-brand-green bg-brand-green/10' : 'text-zinc-500 hover:text-white hover:bg-zinc-800'}`}
                                                                title="Copy FCM Token"
                                                            >
                                                                {copySuccess === user.id ? <CheckCircle2 size={14} /> : <Copy size={14} />}
                                                            </button>
                                                            <button 
                                                                type="button"
                                                                onClick={(e) => { e.stopPropagation(); setViewingToken(user.fcm_token); }}
                                                                className="p-1.5 rounded-lg text-zinc-500 hover:text-white hover:bg-zinc-800 transition-colors"
                                                                title="View Full Token"
                                                            >
                                                                <Eye size={14} />
                                                            </button>
                                                        </div>
                                                    </div>
                                                ))
                                            ) : (
                                                <p className="text-zinc-500 text-sm italic col-span-2 p-4 text-center">{t.no_devices_found || 'No devices found with FCM tokens.'}</p>
                                            )}
                                        </div>
                                    </div>
                                )}

                                <div>
                                    <label className="block text-sm font-medium text-zinc-400 mb-2">{t.notification_title_label || 'Notification Title'}</label>
                                    <input
                                        type="text"
                                        value={title}
                                        onChange={(e) => setTitle(e.target.value)}
                                        placeholder={t.notification_title_placeholder || 'e.g., Important Update'}
                                        className="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-4 py-3 text-white placeholder-zinc-600 focus:outline-none focus:ring-2 focus:ring-brand-green/20 focus:border-brand-green transition-all"
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-zinc-400 mb-2">{t.message_body_label || 'Message Body'}</label>
                                    <textarea
                                        value={body}
                                        onChange={(e) => setBody(e.target.value)}
                                        placeholder={t.message_body_placeholder || 'Enter the notification content here...'}
                                        rows={4}
                                        className="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-4 py-3 text-white placeholder-zinc-600 focus:outline-none focus:ring-2 focus:ring-brand-green/20 focus:border-brand-green transition-all resize-none"
                                    />
                                </div>
                            </div>

                            {statusMessage && (
                                <div className={`flex items-center gap-3 p-4 rounded-xl text-sm font-bold ${statusMessage.type === 'success' ? 'bg-brand-green/10 text-brand-green' : 'bg-red-500/10 text-red-500'}`}>
                                    {statusMessage.type === 'success' ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
                                    {statusMessage.text}
                                </div>
                            )}

                            <button
                                type="submit"
                                disabled={isLoading}
                                className="w-full bg-brand-green hover:bg-brand-green-hover disabled:bg-zinc-800 disabled:text-zinc-500 text-zinc-900 font-black py-4 rounded-xl transition-all shadow-lg shadow-brand-green/10 flex items-center justify-center gap-2 group"
                            >
                                {isLoading ? (
                                    <div className="w-5 h-5 border-2 border-zinc-950 border-t-transparent rounded-full animate-spin" />
                                ) : (
                                    <>
                                        {t.send_notification_btn || 'Send Notification'}
                                        <Send size={18} className="group-hover:translate-x-1 group-hover:-translate-y-1 transition-transform" />
                                    </>
                                )}
                            </button>
                        </form>
                    </div>
                </div>

                {/* History */}
                <div className="space-y-6">
                    <div className="bg-zinc-900/50 border border-zinc-800 rounded-3xl p-6 backdrop-blur-sm h-full flex flex-col">
                        <div className="flex items-center justify-between mb-6">
                            <h2 className="text-xl font-bold text-white flex items-center gap-2">
                                <History size={20} className="text-brand-green" />
                                {t.recent_history || 'Recent History'}
                            </h2>
                            <button 
                                onClick={fetchHistory}
                                className="text-xs font-bold text-brand-green hover:underline cursor-pointer"
                            >
                                {t.refresh || 'Refresh'}
                            </button>
                        </div>

                        <div className="flex-1 space-y-4 overflow-y-auto pr-2 custom-scrollbar">
                            {isHistoryLoading ? (
                                <div className="space-y-4">
                                    {[1, 2, 3].map(i => (
                                        <div key={i} className="h-24 bg-zinc-950/50 rounded-2xl animate-pulse" />
                                    ))}
                                </div>
                            ) : history.length > 0 ? (
                                history.map((log: any) => (
                                    <div key={log.id} className="bg-zinc-950 border border-zinc-800/50 rounded-2xl p-4 hover:border-zinc-700 transition-colors">
                                        <div className="flex justify-between items-start mb-2">
                                            <span className={`text-[10px] font-black uppercase px-2 py-0.5 rounded-full ${log.target === 'all' ? 'bg-blue-500/10 text-blue-400' : 'bg-purple-500/10 text-purple-400'}`}>
                                                {log.target === 'all' ? (t.broadcast_badge || 'Broadcast') : (t.targeted_badge || 'Targeted')}
                                            </span>
                                            <span className="text-[10px] text-zinc-600 font-bold">
                                                {new Date(log.created_at).toLocaleDateString()}
                                            </span>
                                        </div>
                                        <p className="text-sm font-bold text-white truncate">{log.title}</p>
                                        <p className="text-xs text-zinc-500 line-clamp-2 mt-1 mb-3">{log.body}</p>
                                        <div className="flex items-center justify-between pt-3 border-t border-zinc-900">
                                            <div className="flex items-center gap-1.5">
                                                <Users size={12} className="text-brand-green" />
                                                <span className="text-[10px] font-black text-brand-green">
                                                    {log.success_count}/{log.total_recipients} {t.received_status || 'Received'}
                                                </span>
                                            </div>
                                            <div className="w-16 h-1 bg-zinc-900 rounded-full overflow-hidden">
                                                <div 
                                                    className="h-full bg-brand-green" 
                                                    style={{ width: `${(log.success_count / log.total_recipients) * 100}%` }}
                                                />
                                            </div>
                                        </div>
                                    </div>
                                ))
                            ) : (
                                <div className="flex flex-col items-center justify-center py-12 text-center">
                                    <History size={48} className="text-zinc-800 mb-4" />
                                    <p className="text-zinc-500 text-sm">{t.no_history_yet || 'No notification history yet.'}</p>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            </div>
            {/* Token Modal */}
            {viewingToken && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-in fade-in duration-200">
                    <div className="bg-zinc-900 border border-zinc-800 rounded-3xl p-8 max-w-2xl w-full shadow-2xl animate-in zoom-in-95 duration-200">
                        <div className="flex items-center justify-between mb-6">
                            <h3 className="text-xl font-bold text-white flex items-center gap-2">
                                <Bell className="text-brand-green" />
                                {t.device_fcm_token || 'Device FCM Token'}
                            </h3>
                            <button 
                                onClick={() => setViewingToken(null)}
                                className="p-2 hover:bg-zinc-800 rounded-full text-zinc-500 hover:text-white transition-colors"
                            >
                                <X size={20} />
                            </button>
                        </div>
                        
                        <div className="bg-zinc-950 border border-zinc-800 rounded-2xl p-6 mb-6">
                            <p className="text-xs font-mono text-zinc-400 break-all leading-relaxed select-all">
                                {viewingToken}
                            </p>
                        </div>
                        
                        <div className="flex gap-4">
                            <button
                                onClick={() => {
                                    navigator.clipboard.writeText(viewingToken);
                                    // Could add a toast here
                                }}
                                className="flex-1 bg-brand-green hover:bg-brand-green-hover text-zinc-950 font-black py-4 rounded-xl transition-all flex items-center justify-center gap-2"
                            >
                                <Copy size={18} />
                                {t.copy_full_token || 'Copy Full Token'}
                            </button>
                            <button
                                onClick={() => setViewingToken(null)}
                                className="flex-1 bg-zinc-800 hover:bg-zinc-700 text-white font-bold py-4 rounded-xl transition-all"
                            >
                                {t.close || 'Close'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default PushNotificationsPage;
