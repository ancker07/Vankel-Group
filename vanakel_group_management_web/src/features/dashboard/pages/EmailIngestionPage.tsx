
import React, { useState, useEffect } from 'react';
import { Mail, Clock, CheckCircle, AlertCircle, Play, PlayCircle, Loader2 } from 'lucide-react';
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

    const pendingEmails = emails.filter(e => !e.ingested_at);

    return (
        <div className="max-w-6xl mx-auto space-y-6 animate-in fade-in duration-500">
            <div className="flex justify-between items-center bg-zinc-900/50 p-6 rounded-2xl border border-zinc-800">
                <div>
                    <h1 className="text-2xl font-black text-white">{t.ingestion_menu}</h1>
                    <p className="text-zinc-500 text-sm mt-1">Review and process incoming emails with AI extraction.</p>
                </div>
                <div className="flex gap-4">
                    <button
                        onClick={() => fetchEmails()}
                        className="px-4 py-2 text-zinc-400 hover:text-white transition-colors flex items-center gap-2"
                    >
                        <Clock size={16} />
                        Refresh
                    </button>
                    <button
                        onClick={handleIngestAll}
                        disabled={isBulkIngesting || pendingEmails.length === 0}
                        className="bg-brand-green text-brand-black px-6 py-3 rounded-xl font-black text-xs uppercase tracking-widest hover:bg-brand-green-light transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                    >
                        {isBulkIngesting ? <Loader2 size={16} className="animate-spin" /> : <PlayCircle size={16} />}
                        {t.ingest_all} ({pendingEmails.length})
                    </button>
                </div>
            </div>

            <div className="bg-zinc-900/30 rounded-2xl border border-zinc-800 overflow-hidden">
                <div className="overflow-x-auto">
                    <table className="w-full text-left">
                        <thead>
                            <tr className="border-b border-zinc-800 bg-zinc-900/50">
                                <th className="px-6 py-4 text-xs font-black text-zinc-500 uppercase">{t.subject}</th>
                                <th className="px-6 py-4 text-xs font-black text-zinc-500 uppercase">From</th>
                                <th className="px-6 py-4 text-xs font-black text-zinc-500 uppercase">Received</th>
                                <th className="px-6 py-4 text-xs font-black text-zinc-500 uppercase">Status</th>
                                <th className="px-6 py-4 text-xs font-black text-zinc-500 uppercase text-right">Action</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-zinc-800/50">
                            {emails.length === 0 ? (
                                <tr>
                                    <td colSpan={5} className="px-6 py-12 text-center text-zinc-500">
                                        {t.no_emails_found}
                                    </td>
                                </tr>
                            ) : (
                                emails.map((email) => (
                                    <tr key={email.id} className="hover:bg-zinc-800/20 transition-colors group">
                                        <td className="px-6 py-4">
                                            <div className="font-bold text-white truncate max-w-md">{email.subject}</div>
                                            {email.attachments && email.attachments.length > 0 && (
                                                <div className="text-[10px] text-zinc-500 mt-1 flex gap-2">
                                                    {email.attachments.length} attachment(s)
                                                </div>
                                            )}
                                        </td>
                                        <td className="px-6 py-4">
                                            <div className="text-sm text-zinc-300">{email.from_name || email.from_address}</div>
                                            <div className="text-[10px] text-zinc-500">{email.from_address}</div>
                                        </td>
                                        <td className="px-6 py-4 text-sm text-zinc-400">
                                            {formatDate(email.received_at)}
                                        </td>
                                        <td className="px-6 py-4">
                                            {email.ingested_at ? (
                                                <div className="flex items-center gap-2 text-brand-green bg-brand-green/10 px-3 py-1 rounded-full w-fit">
                                                    <CheckCircle size={14} />
                                                    <span className="text-[10px] font-black uppercase tracking-wider">{t.ingested_at}</span>
                                                </div>
                                            ) : (
                                                <div className="flex items-center gap-2 text-zinc-500 bg-zinc-500/10 px-3 py-1 rounded-full w-fit">
                                                    <Clock size={14} />
                                                    <span className="text-[10px] font-black uppercase tracking-wider">{t.pending_ingestion}</span>
                                                </div>
                                            )}
                                        </td>
                                        <td className="px-6 py-4 text-right">
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
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
};

export default EmailIngestionPage;
