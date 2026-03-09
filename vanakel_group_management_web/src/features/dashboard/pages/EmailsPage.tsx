
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, Calendar, Search, RefreshCcw, Paperclip, Download, ChevronRight } from 'lucide-react';
import { Email, Language } from '@/types';
import { dataService } from '@/services/dataService';
import { TRANSLATIONS } from '@/utils/constants';
import { STORAGE_BASE_URL } from '@/lib/apiClient';

interface EmailsPageProps {
    lang: Language;
}

const EmailsPage: React.FC<EmailsPageProps> = ({ lang }) => {
    const navigate = useNavigate();
    const t = TRANSLATIONS[lang];
    const [emails, setEmails] = useState<Email[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');

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

    useEffect(() => {
        fetchEmails();
    }, []);

    const filteredEmails = emails.filter(email =>
        email.subject?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        email.from_address?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        email.from_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        email.body_text?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="flex flex-col h-full space-y-6 animate-in fade-in duration-500 max-w-6xl mx-auto">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                <div>
                    <h1 className="text-3xl font-black text-white">Incoming Emails</h1>
                    <p className="text-zinc-500 text-sm mt-1">Direct view of all emails fetched from the IMAP server.</p>
                </div>

                <div className="flex items-center gap-3 w-full md:w-auto">
                    <div className="relative flex-1 md:w-64">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500" size={16} />
                        <input
                            type="text"
                            placeholder="Search emails..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="w-full bg-zinc-900 border border-zinc-800 rounded-xl py-2.5 pl-10 pr-4 text-sm text-white focus:border-brand-green focus:ring-1 focus:ring-brand-green outline-none transition-all"
                        />
                    </div>
                    <button
                        onClick={fetchEmails}
                        disabled={isLoading}
                        className="p-2.5 rounded-xl bg-zinc-900 border border-zinc-800 text-zinc-400 hover:text-brand-green hover:border-brand-green transition-all disabled:opacity-50"
                    >
                        <RefreshCcw size={20} className={isLoading ? "animate-spin" : ""} />
                    </button>
                </div>
            </div>

            <div className="bg-zinc-950 rounded-2xl border border-zinc-800 overflow-hidden flex flex-col flex-1 min-h-0">
                <div className="p-4 border-b border-zinc-900 bg-zinc-950/50 flex justify-between items-center">
                    <span className="text-xs font-black uppercase tracking-widest text-zinc-500">
                        {filteredEmails.length} Emails Found
                    </span>
                </div>

                <div className="flex-1 overflow-y-auto p-4 space-y-3">
                    {isLoading && emails.length === 0 ? (
                        <div className="py-20 text-center">
                            <div className="w-10 h-10 border-4 border-brand-green/20 border-t-brand-green rounded-full animate-spin mx-auto mb-4"></div>
                            <p className="text-zinc-500">Connecting to database...</p>
                        </div>
                    ) : filteredEmails.length === 0 ? (
                        <div className="py-20 text-center space-y-4">
                            <div className="w-16 h-16 bg-zinc-900 rounded-2xl flex items-center justify-center mx-auto border border-zinc-800">
                                <Mail size={32} className="text-zinc-700" />
                            </div>
                            <p className="text-zinc-500 font-medium">No emails match your search.</p>
                        </div>
                    ) : (
                        filteredEmails.map(email => (
                            <div
                                key={email.id}
                                onClick={() => navigate(`${email.id}`)}
                                className="group p-5 bg-zinc-900/40 rounded-2xl border border-zinc-800/50 hover:bg-zinc-900/60 hover:border-brand-green/30 transition-all cursor-pointer relative overflow-hidden"
                            >
                                <div className="absolute top-0 left-0 w-1 h-full bg-brand-green opacity-0 group-hover:opacity-100 transition-opacity"></div>

                                <div className="flex justify-between items-start gap-4">
                                    <div className="flex gap-4 min-w-0 flex-1">
                                        <div className="w-12 h-12 bg-zinc-950 rounded-xl flex items-center justify-center border border-zinc-800 shrink-0 group-hover:border-brand-green/30 transition-colors shadow-inner">
                                            <Mail className="text-zinc-500 group-hover:text-brand-green transition-colors" size={24} />
                                        </div>
                                        <div className="min-w-0 flex-1">
                                            <h4 className="font-bold text-white text-base group-hover:text-brand-green transition-colors truncate pr-8">
                                                {email.subject || '(No Subject)'}
                                            </h4>
                                            <div className="flex items-center gap-2 mt-1">
                                                <span className="text-sm text-zinc-300 font-medium truncate">{email.from_name || email.from_address}</span>
                                                <span className="text-xs text-zinc-500 truncate hidden sm:inline">({email.from_address})</span>
                                            </div>
                                        </div>
                                    </div>

                                    <div className="text-right shrink-0 flex flex-col items-end gap-2">
                                        <div className="flex items-center gap-2 text-[10px] text-zinc-500 font-mono bg-zinc-950 px-2 py-1 rounded-lg border border-zinc-900 shadow-sm">
                                            <Calendar size={12} className="text-zinc-600" />
                                            {new Date(email.received_at).toLocaleString(undefined, {
                                                day: '2-digit',
                                                month: 'short',
                                                hour: '2-digit',
                                                minute: '2-digit'
                                            })}
                                        </div>
                                        <ChevronRight size={16} className="text-zinc-700 group-hover:text-brand-green group-hover:translate-x-1 transition-all" />
                                    </div>
                                </div>

                                <div className="mt-4 bg-zinc-950/40 rounded-xl border border-zinc-900/50 p-4 group-hover:bg-zinc-950/60 transition-colors relative">
                                    <p className="text-xs text-zinc-400 line-clamp-2 leading-relaxed whitespace-pre-wrap">
                                        {email.body_text || 'No text content available.'}
                                    </p>
                                </div>

                                {email.attachments && email.attachments.length > 0 && (
                                    <div className="mt-4 pt-4 border-t border-zinc-900/50">
                                        <p className="text-[10px] font-black uppercase tracking-widest text-zinc-600 mb-2 flex items-center gap-2">
                                            <Paperclip size={12} />
                                            Attachments ({email.attachments.length})
                                        </p>
                                        <div className="flex flex-wrap gap-2">
                                            {email.attachments.map(att => (
                                                <div
                                                    key={att.id}
                                                    className="flex items-center gap-2 px-3 py-1.5 bg-zinc-950 border border-zinc-900 rounded-lg text-xs text-zinc-400 group/att"
                                                    onClick={(e) => e.stopPropagation()}
                                                >
                                                    <Paperclip size={12} className="text-zinc-600" />
                                                    <span className="truncate max-w-[150px]">{att.file_name}</span>
                                                    <a
                                                        href={`${STORAGE_BASE_URL}/${att.file_path}`}
                                                        target="_blank"
                                                        rel="noopener noreferrer"
                                                        className="hover:text-brand-green transition-colors ml-1"
                                                    >
                                                        <Download size={12} />
                                                    </a>
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                )}

                                <div className="mt-3 flex items-center justify-between">
                                    <span className="text-[9px] font-black uppercase tracking-tighter text-zinc-700 font-mono">
                                        MSG_ID: {email.message_id}
                                    </span>
                                    {email.body_html && (
                                        <span className="text-[9px] font-black uppercase px-2 py-0.5 rounded bg-zinc-800 text-zinc-500 border border-zinc-700">
                                            HTML Content Available
                                        </span>
                                    )}
                                </div>
                            </div>
                        ))
                    )}
                </div>
            </div>
        </div>
    );
};

export default EmailsPage;
