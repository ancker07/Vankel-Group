
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, Calendar, Search, RefreshCcw, Paperclip, Download, ChevronRight, Trash2, Clock, ArrowRight } from 'lucide-react';
import { parseISO, compareDesc } from 'date-fns';
import { Email, Language } from '@/types';
import { dataService } from '@/services/dataService';
import { TRANSLATIONS } from '@/utils/constants';
import { STORAGE_BASE_URL } from '@/lib/apiClient';
import ConfirmationModal from '@/components/common/ConfirmationModal';

interface EmailsPageProps {
    lang: Language;
}

const EmailsPage: React.FC<EmailsPageProps> = ({ lang }) => {
    const navigate = useNavigate();
    const t = TRANSLATIONS[lang];
    const [emails, setEmails] = useState<Email[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const [filter, setFilter] = useState<'all' | 'unread' | 'internal' | 'external'>('all');
    const [emailToDelete, setEmailToDelete] = useState<number | null>(null);
    const [isDeleting, setIsDeleting] = useState(false);
    const [isSyncing, setIsSyncing] = useState(false);

    const fetchEmails = async () => {
        setIsLoading(true);
        try {
            const response = await dataService.getEmails();
            if (response && response.emails) {
                setEmails(response.emails);
            }
        } catch (error) {
            console.error("Error fetching emails:", error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleSync = async () => {
        setIsSyncing(true);
        try {
            await dataService.syncEmails();
            await fetchEmails();
        } catch (error) {
            console.error("Error syncing emails:", error);
        } finally {
            setIsSyncing(false);
        }
    };

    useEffect(() => {
        fetchEmails();
    }, []);

    const handleDelete = async () => {
        if (emailToDelete === null) return;
        setIsDeleting(true);
        try {
            await dataService.deleteEmail(emailToDelete);
            setEmails(prev => prev.filter(e => e.id !== emailToDelete));
        } catch (error) {
            console.error("Error deleting email:", error);
        } finally {
            setIsDeleting(false);
            setEmailToDelete(null);
        }
    };

    const filteredEmails = emails
        .filter(email => {
            const matchesSearch = 
                email.subject?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                email.from_address?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                email.from_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                email.body_text?.toLowerCase().includes(searchTerm.toLowerCase());
            
            if (!matchesSearch) return false;

            if (filter === 'unread') return !email.is_read;
            if (filter === 'internal') return email.from_address.toLowerCase().includes('vanakelgroup.com');
            if (filter === 'external') return !email.from_address.toLowerCase().includes('vanakelgroup.com');
            
            return true;
        })
        .sort((a, b) => {
            // Primary sort: ID (highest first) - Most reliable for arrival order
            if (b.id !== a.id) return b.id - a.id;
            
            // Secondary sort: Received time (latest first)
            const dateA = a.received_at ? parseISO(a.received_at) : new Date(0);
            const dateB = b.received_at ? parseISO(b.received_at) : new Date(0);
            return compareDesc(dateA, dateB);
        });

    return (
        <div className="flex flex-col h-full space-y-6 animate-in fade-in duration-500 max-w-6xl mx-auto pb-32">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 px-4 md:px-0">
                <div>
                    <h1 className="text-2xl md:text-3xl font-black text-white flex items-center gap-3">
                        <Mail className="text-brand-green" size={28} />
                        {t.inbox_title || 'Inbox'}
                    </h1>
                    <p className="text-zinc-500 text-xs md:text-sm mt-1">{t.inbox_subtitle || 'Direct view of all incoming communication.'}</p>
                </div>

                <div className="flex flex-col md:flex-row items-stretch md:items-center gap-4 w-full md:w-auto">
                    <div className="flex bg-zinc-900/50 p-1 rounded-xl border border-zinc-800">
                        {(['all', 'unread', 'internal', 'external'] as const).map((f) => (
                            <button
                                key={f}
                                onClick={() => setFilter(f)}
                                className={`px-4 py-2 rounded-lg text-[10px] font-black uppercase tracking-widest transition-all ${
                                    filter === f 
                                    ? 'bg-brand-green text-black shadow-lg shadow-brand-green/20' 
                                    : 'text-zinc-500 hover:text-white hover:bg-zinc-800'
                                }`}
                            >
                                {f}
                            </button>
                        ))}
                    </div>

                    <div className="flex items-center gap-2">
                        <div className="relative flex-1 md:w-64">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500" size={16} />
                            <input
                                type="text"
                                placeholder={t.search_inbox || 'Search inbox...'}
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                                className="w-full bg-zinc-900 border border-zinc-800 rounded-xl py-3 pl-10 pr-4 text-xs md:text-sm text-white focus:border-brand-green focus:ring-1 focus:ring-brand-green outline-none transition-all"
                            />
                        </div>
                        <button
                            onClick={handleSync}
                            disabled={isSyncing || isLoading}
                            className="flex items-center gap-2 px-4 py-3 rounded-xl bg-brand-green text-brand-black font-black text-[10px] md:text-xs uppercase tracking-widest hover:bg-white transition-all disabled:opacity-50 shadow-lg shadow-brand-green/10 shrink-0"
                        >
                            {isSyncing ? (
                                <RefreshCcw size={14} className="animate-spin" />
                            ) : (
                                <Download size={14} />
                            )}
                            <span className="hidden sm:inline">{isSyncing ? (t.syncing || 'Syncing...') : (t.fetch || 'Fetch')}</span>
                        </button>
                        <button
                            onClick={fetchEmails}
                            disabled={isLoading || isSyncing}
                            className="p-3 rounded-xl bg-zinc-900 border border-zinc-800 text-zinc-400 hover:text-brand-green hover:border-brand-green transition-all disabled:opacity-50 shrink-0"
                        >
                            <RefreshCcw size={16} className={isLoading ? "animate-spin" : ""} />
                        </button>
                    </div>
                </div>
            </div>

            <div className="bg-zinc-950 md:rounded-2xl border-y md:border border-zinc-900 overflow-hidden flex flex-col flex-1 min-h-[500px]">
                <div className="p-4 border-b border-zinc-900 bg-zinc-950/50 flex justify-between items-center px-6">
                    <span className="text-[10px] font-black uppercase tracking-widest text-zinc-500">
                        {filteredEmails.length} {t.messages || 'messages'}
                    </span>
                    {!isSyncing && (
                        <div className="flex items-center gap-2">
                            <div className="w-1.5 h-1.5 rounded-full bg-brand-green animate-pulse"></div>
                            <span className="text-[10px] font-bold text-brand-green uppercase tracking-widest">{t.live || 'Live'}</span>
                        </div>
                    )}
                </div>

                <div className="flex-1 overflow-y-auto p-3 md:p-6 space-y-3">
                    {isLoading && emails.length === 0 ? (
                        <div className="py-20 text-center">
                            <div className="w-10 h-10 border-4 border-brand-green/20 border-t-brand-green rounded-full animate-spin mx-auto mb-4"></div>
                            <p className="text-zinc-500 text-sm font-medium">{t.checking_mail_server || 'Checking mail server...'}</p>
                        </div>
                    ) : filteredEmails.length === 0 ? (
                        <div className="py-20 text-center space-y-4">
                            <div className="w-16 h-16 bg-zinc-900 rounded-3xl flex items-center justify-center mx-auto border border-zinc-800">
                                <Mail size={32} className="text-zinc-700" />
                            </div>
                            <p className="text-zinc-500 font-bold uppercase text-[10px] tracking-widest">{t.no_matching_emails || 'No matching emails'}</p>
                        </div>
                    ) : (
                        filteredEmails.map(email => (
                            <div
                                key={email.id}
                                onClick={() => navigate(`${email.id}`)}
                                className="group p-4 md:p-5 bg-zinc-900/30 md:bg-zinc-900/40 rounded-2xl border border-zinc-800/50 hover:bg-zinc-900/60 hover:border-brand-green/30 transition-all cursor-pointer relative overflow-hidden"
                            >
                                <div className="absolute top-0 left-0 w-1 h-full bg-brand-green opacity-0 group-hover:opacity-100 transition-opacity"></div>
                                
                                <div className="flex flex-col gap-4">
                                    <div className="flex items-start justify-between gap-4">
                                        <div className="flex items-center gap-3 min-w-0">
                                            <div className="w-8 h-8 md:w-9 md:h-9 rounded-full bg-zinc-800 flex items-center justify-center text-xs font-black text-brand-green border border-zinc-700 shrink-0">
                                                {email.from_name ? email.from_name.charAt(0).toUpperCase() : '?'}
                                            </div>
                                            <div className="min-w-0">
                                                <div className="flex items-center gap-2 overflow-hidden">
                                                    <h3 className={`text-sm font-bold truncate ${email.is_read ? 'text-zinc-400' : 'text-white'}`}>
                                                        {email.from_name || t.system_name || 'System'}
                                                    </h3>
                                                    {!email.is_read && (
                                                        <span className="w-1.5 h-1.5 rounded-full bg-brand-green shrink-0"></span>
                                                    )}
                                                </div>
                                                <p className="text-[10px] text-zinc-500 truncate">{email.from_address}</p>
                                            </div>
                                        </div>
                                        
                                        <div className="flex flex-col items-end gap-1 shrink-0">
                                            <span className="text-[10px] font-black text-zinc-600 uppercase">
                                                {new Date(email.received_at).toLocaleDateString(undefined, { 
                                                    month: 'short', 
                                                    day: 'numeric' 
                                                })}
                                            </span>
                                            <div className="flex items-center gap-2">
                                                {email.attachments && email.attachments.length > 0 && (
                                                    <Paperclip size={12} className="text-zinc-600" />
                                                )}
                                                <button
                                                    onClick={(e) => {
                                                        e.stopPropagation();
                                                        setEmailToDelete(email.id);
                                                    }}
                                                    className="p-1 rounded-lg text-zinc-700 hover:text-red-500 hover:bg-red-500/10 transition-colors"
                                                >
                                                    <Trash2 size={12} />
                                                </button>
                                            </div>
                                        </div>
                                    </div>

                                    <div className="space-y-1">
                                        <h4 className={`text-sm font-bold leading-snug line-clamp-1 ${email.is_read ? 'text-zinc-500' : 'text-zinc-200'}`}>
                                            {email.subject || t.no_subject || '(No Subject)'}
                                        </h4>
                                        <p className="text-xs text-zinc-500 line-clamp-2 md:line-clamp-1 leading-relaxed">
                                            {email.body_text?.replace(/[\n\r]+/g, ' ')}
                                        </p>
                                    </div>

                                    <div className="flex items-center justify-between pt-2 border-t border-zinc-800/50">
                                        <div className="flex items-center gap-4">
                                            <div className="flex items-center gap-1.5 text-zinc-600">
                                                <Clock size={12} />
                                                <span className="text-[10px] font-bold">
                                                    {new Date(email.received_at).toLocaleTimeString(undefined, { 
                                                        hour: '2-digit', 
                                                        minute: '2-digit' 
                                                    })}
                                                </span>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-1.5 text-zinc-500 group-hover:text-brand-green transition-colors">
                                            <span className="text-[9px] font-black uppercase tracking-widest">{t.details_btn || 'Details'}</span>
                                            <ArrowRight size={12} className="group-hover:translate-x-1 transition-transform" />
                                        </div>
                                    </div>
                                </div>
                            </div>
                        ))
                    )}
                </div>
            </div>

            <ConfirmationModal
                isOpen={emailToDelete !== null}
                onClose={() => setEmailToDelete(null)}
                onConfirm={handleDelete}
                title={t.delete_email || 'Delete Email'}
                message={t.delete_email_confirm || 'Are you sure you want to delete this email? This will permanently remove it from the system and the mail server.'}
                confirmLabel={isDeleting ? (t.deleting || 'Deleting...') : (t.yes_delete || 'Yes, Delete')}
                cancelLabel={t.cancel || 'Cancel'}
                isDanger={true}
            />
        </div>
    );
};

export default EmailsPage;
