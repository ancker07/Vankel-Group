
import React from 'react';
import { Mail, Clock } from 'lucide-react';
import IngestionLogs from '../components/IngestionLogs';

interface EmailIngestionPageProps {
    isIngesting: boolean;
    onIngestClick: () => void;
    emailLogs: any[];
    lang: string;
    t: any;
}

const EmailIngestionPage: React.FC<EmailIngestionPageProps> = ({ isIngesting, onIngestClick, emailLogs, lang, t }) => {
    return (
        <div className="max-w-4xl mx-auto space-y-6 animate-in fade-in duration-500">
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-2xl font-black text-white">Email Ingestion</h1>
                    <p className="text-zinc-500 text-sm mt-1">Simulate incoming emails from syndics/clients.</p>
                </div>
                <button
                    onClick={onIngestClick}
                    disabled={isIngesting}
                    className="bg-brand-green text-brand-black px-6 py-3 rounded-xl font-black text-xs uppercase tracking-widest hover:bg-brand-green-light transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                >
                    {isIngesting ? <Clock size={16} className="animate-spin" /> : <Mail size={16} />}
                    {isIngesting ? t.ingest_button_working : t.ingest_button_idle}
                </button>
            </div>
            <IngestionLogs logs={emailLogs} lang={lang as any} />
        </div>
    );
};

export default EmailIngestionPage;
