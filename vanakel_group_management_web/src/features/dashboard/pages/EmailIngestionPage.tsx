
import React, { useState, useEffect } from 'react';
import { Mail, Clock, CheckCircle, AlertCircle, Play, PlayCircle, Loader2, CheckCircle2, XCircle, MessageSquare } from 'lucide-react';
import { dataService } from '@/services/dataService';
import { Email, Language } from '@/types';

const formatDate = (dateString: string) => {
    return new Intl.DateTimeFormat('fr-FR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    }).format(new Date(dateString));
};

interface EmailIngestionPageProps {
    lang: Language;
    t: any;
}

const EmailIngestionPage: React.FC<EmailIngestionPageProps> = ({ lang, t }) => {
    const [emails, setEmails] = useState<Email[]>([]);
    const [loading, setLoading] = useState(true);
    const [ingestingId, setIngestingId] = useState<number | null>(null);
    const [isBulkIngesting, setIsBulkIngesting] = useState(false);

    const fetchEmails = async () => {
        try {
            const response = await dataService.getEmails();
            if (response && response.emails) {
                setEmails(response.emails);
            }
        } catch (error) {
            console.error("Failed to fetch emails:", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchEmails();
    }, []);

    const handleIngest = async (id: number) => {
        setIngestingId(id);
        try {
            const result = await dataService.ingestEmail(id);
            if (result.success) {
                // Refresh list to update status
                await fetchEmails();
            }
        } catch (error) {
            console.error("Ingestion failed:", error);
        } finally {
            setIngestingId(null);
        }
    };

    const handleIngestAll = async () => {
        setIsBulkIngesting(true);
        try {
            await dataService.ingestAllEmails();
            await fetchEmails();
        } catch (error) {
            console.error("Bulk ingestion failed:", error);
        } finally {
            setIsBulkIngesting(false);
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center h-64">
                <Loader2 className="w-8 h-8 text-brand-green animate-spin" />
            </div>
        );
    }

    const sortedEmails = [...emails].sort((a, b) => 
        new Date(b.received_at).getTime() - new Date(a.received_at).getTime()
    );
    const pendingCount = emails.filter(e => !e.ingested_at || e.ingestion_status === 'PENDING').length;

    return (
        <div className="max-w-6xl mx-auto space-y-6 animate-in fade-in duration-500 pb-20">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center bg-zinc-900/50 p-6 rounded-2xl border border-zinc-800 gap-6">
                <div>
                    <h1 className="text-2xl font-black text-white">{t.ingestion_menu}</h1>
                    <p className="text-zinc-500 text-sm mt-1">{t.email_ingestion_subtitle}</p>
                </div>
                <div className="flex flex-col sm:flex-row gap-3 w-full md:w-auto">
                    <button
                        onClick={() => fetchEmails()}
                        className="flex-1 sm:flex-none px-4 py-2.5 bg-zinc-900 border border-zinc-800 rounded-xl text-zinc-400 hover:text-white transition-colors flex items-center justify-center gap-2"
                    >
                        <Clock size={16} />
                        {t.refresh || 'Refresh'}
                    </button>
                    <button
                        onClick={handleIngestAll}
                        disabled={isBulkIngesting || pendingCount === 0}
                        className="flex-1 sm:flex-none bg-brand-green text-brand-black px-6 py-3 rounded-xl font-black text-xs uppercase tracking-widest hover:bg-brand-green-light transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 shadow-lg shadow-brand-green/20"
                    >
                        {isBulkIngesting ? <Loader2 size={16} className="animate-spin" /> : <PlayCircle size={16} />}
                        {t.ingest_all} ({pendingCount})
                    </button>
                </div>
            </div>

            <div className="bg-zinc-900/30 rounded-2xl border border-zinc-800 overflow-hidden">
                {/* Desktop View Table */}
                <div className="hidden md:block overflow-x-auto">
                    <table className="w-full text-left">
                        <thead>
                            <tr className="border-b border-zinc-800 bg-zinc-900/50">
                                <th className="px-6 py-4 text-xs font-black text-zinc-500 uppercase">{t.subject}</th>
                                <th className="px-6 py-4 text-xs font-black text-zinc-500 uppercase">{t.from_label}</th>
                                <th className="px-6 py-4 text-xs font-black text-zinc-500 uppercase">{t.received}</th>
                                <th className="px-6 py-4 text-xs font-black text-zinc-500 uppercase">{t.status}</th>
                                <th className="px-6 py-4 text-xs font-black text-zinc-500 uppercase text-right">{t.action}</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-zinc-800/50">
                            {sortedEmails.length === 0 ? (
                                <tr>
                                    <td colSpan={5} className="px-6 py-12 text-center text-zinc-500">
                                        {t.no_processed_emails}
                                    </td>
                                </tr>
                            ) : (
                                sortedEmails.map((email) => (
                                    <React.Fragment key={email.id}>
                                        <tr className="hover:bg-zinc-800/20 transition-colors group">
                                            <td className="px-6 py-4">
                                                <div className="flex flex-col gap-1.5">
                                                    <div className="font-bold text-white truncate max-w-md">{email.subject}</div>
                                                    {email.thread_id && (
                                                        <div className="flex items-center gap-1.5 text-brand-green bg-brand-green/10 px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-widest w-fit border border-brand-green/20">
                                                            <MessageSquare size={10} />
                                                            Ongoing Conversation
                                                        </div>
                                                    )}
                                                    {email.attachments && email.attachments.length > 0 && (
                                                        <div className="text-[10px] text-zinc-500 flex gap-2">
                                                            {email.attachments.length} {t.attachments_count}
                                                        </div>
                                                    )}
                                                </div>
                                            </td>
                                            <td className="px-6 py-4">
                                                <div className="text-sm text-zinc-300">{email.from_name || email.from_address}</div>
                                                <div className="text-[10px] text-zinc-500">{email.from_address}</div>
                                            </td>
                                            <td className="px-6 py-4 text-sm text-zinc-400">
                                                {formatDate(email.received_at)}
                                            </td>
                                            <td className="px-6 py-4">
                                                <StatusBadge status={email.ingestion_status} reason={email.ingestion_reason} t={t} />
                                            </td>
                                            <td className="px-6 py-4 text-right">
                                                <div className="flex items-center justify-end gap-2">
                                                    {email.ingestion_reason && (
                                                        <button
                                                            onClick={() => {
                                                                const el = document.getElementById(`note-${email.id}`);
                                                                if (el) el.classList.toggle('hidden');
                                                            }}
                                                            className="p-2 bg-zinc-800 hover:bg-zinc-700 rounded-lg text-zinc-400 hover:text-white transition-all shadow-sm"
                                                            title="View AI Note"
                                                        >
                                                            <AlertCircle size={16} />
                                                        </button>
                                                    )}
                                                    {!email.ingested_at && (
                                                        <button
                                                            onClick={() => handleIngest(email.id)}
                                                            disabled={!!ingestingId}
                                                            className="bg-zinc-800 hover:bg-brand-green hover:text-brand-black p-2 rounded-lg transition-all text-zinc-400 disabled:opacity-50"
                                                            title={t.ingest_single}
                                                        >
                                                            {ingestingId === email.id ? <Loader2 size={16} className="animate-spin" /> : <Play size={16} />}
                                                        </button>
                                                    )}
                                                </div>
                                            </td>
                                        </tr>
                                        {/* Expandable Note Row */}
                                        {email.ingestion_reason && (
                                            <tr id={`note-${email.id}`} className="hidden bg-zinc-900/40 border-l-2 border-brand-green/30">
                                                <td colSpan={5} className="px-6 py-4">
                                                    <div className="bg-zinc-950/50 p-4 rounded-xl border border-zinc-800/50">
                                                        <div className="text-[10px] font-black text-brand-green uppercase tracking-widest mb-2 flex items-center gap-2">
                                                            <AlertCircle size={12} />
                                                            AI Ingestion Note
                                                        </div>
                                                        <p className="text-sm text-zinc-300 italic leading-relaxed">
                                                            {email.ingestion_reason}
                                                        </p>
                                                    </div>
                                                </td>
                                            </tr>
                                        )}
                                    </React.Fragment>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {/* Mobile View Cards */}
            <div className="md:hidden divide-y divide-zinc-800/50">
                {sortedEmails.length === 0 ? (
                    <div className="px-6 py-12 text-center text-zinc-500">
                        {t.no_processed_emails || 'No processed emails found.'}
                    </div>
                ) : (
                    sortedEmails.map((email) => (
                        <div key={email.id} className="p-4 space-y-4">
                            <div className="space-y-2">
                                <div className="font-bold text-white leading-tight break-words">{email.subject}</div>
                                {email.thread_id && (
                                    <div className="flex items-center gap-1.5 text-brand-green bg-brand-green/10 px-2 py-0.5 rounded text-[8px] font-black uppercase tracking-widest w-fit border border-brand-green/20">
                                        <MessageSquare size={10} />
                                        Ongoing Conversation
                                    </div>
                                )}
                                <div className="flex flex-col text-xs text-zinc-500">
                                    <span>{email.from_name || email.from_address}</span>
                                    <span className="opacity-60">{email.from_address}</span>
                                </div>
                            </div>

                            <div className="flex items-center justify-between gap-2">
                                <div className="text-[10px] text-zinc-600 font-mono">
                                    {formatDate(email.received_at)}
                                </div>
                                <StatusBadge status={email.ingestion_status} reason={email.ingestion_reason} t={t} />
                            </div>

                            {email.ingestion_reason && (
                                <button
                                    onClick={() => {
                                        const el = document.getElementById(`note-mob-${email.id}`);
                                        if (el) el.classList.toggle('hidden');
                                    }}
                                    className="w-full bg-zinc-900 border border-zinc-800 text-zinc-400 py-2 rounded-lg text-[10px] font-black uppercase tracking-widest hover:text-white transition-colors"
                                >
                                    Toggle AI Note
                                </button>
                            )}

                            {email.ingestion_reason && (
                                <div id={`note-mob-${email.id}`} className="hidden bg-zinc-950/50 p-3 rounded-xl border border-zinc-800/50">
                                    <div className="text-[9px] font-black text-brand-green uppercase tracking-widest mb-1.5 flex items-center gap-1.5">
                                        <AlertCircle size={10} />
                                        AI Ingestion Note
                                    </div>
                                    <p className="text-[11px] text-zinc-400 italic leading-relaxed">
                                        {email.ingestion_reason}
                                    </p>
                                </div>
                            )}

                            {!email.ingested_at && (
                                <button
                                    onClick={() => handleIngest(email.id)}
                                    disabled={!!ingestingId}
                                    className="w-full bg-zinc-900 border border-zinc-800 text-zinc-300 py-3 rounded-xl font-black text-[10px] uppercase tracking-widest flex items-center justify-center gap-2 hover:bg-brand-green hover:text-brand-black transition-all"
                                >
                                    {ingestingId === email.id ? <Loader2 size={14} className="animate-spin" /> : <Play size={14} />}
                                    {t.ingest_single || 'Process Email'}
                                </button>
                            )}
                        </div>
                    ))
                )}
            </div>
        </div>
    </div>
);
};

const StatusBadge: React.FC<{ status?: string, reason?: string, t: any }> = ({ status, reason, t }) => {
if (status === 'PROCESSED') {
    return (
        <div className="flex items-center gap-2 text-brand-green bg-brand-green/10 px-3 py-1 rounded-full w-fit">
            <CheckCircle2 size={14} />
            <span className="text-[10px] font-black uppercase tracking-wider">PROCESSED</span>
        </div>
    );
}
if (status === 'DEFERRED') {
    return (
        <div className="flex items-center gap-2 text-yellow-500 bg-yellow-500/10 px-3 py-1 rounded-full w-fit border border-yellow-500/20">
            <Clock size={14} />
            <span className="text-[10px] font-black uppercase tracking-wider">DEFERRED</span>
        </div>
    );
}
if (status === 'IGNORED') {
    return (
        <div className="flex items-center gap-2 text-zinc-500 bg-zinc-500/10 px-3 py-1 rounded-full w-fit border border-zinc-800">
            <XCircle size={14} />
            <span className="text-[10px] font-black uppercase tracking-wider">IGNORED</span>
        </div>
    );
}
if (status === 'ERROR' || status === 'NEEDS_REVIEW') {
    return (
        <div className={`flex items-center gap-2 px-3 py-1 rounded-full w-fit border ${status === 'ERROR' ? 'text-red-500 bg-red-500/10 border-red-500/20' : 'text-orange-500 bg-orange-500/10 border-orange-500/20'}`}>
            <AlertCircle size={14} />
            <span className="text-[10px] font-black uppercase tracking-wider">{status}</span>
        </div>
    );
}
return (
    <div className="flex items-center gap-2 text-zinc-500 bg-zinc-500/10 px-3 py-1 rounded-full w-fit">
        <Clock size={14} />
        <span className="text-[10px] font-black uppercase tracking-wider">{t.pending_ingestion || 'PENDING'}</span>
    </div>
);
};

export default EmailIngestionPage;

