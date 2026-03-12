
import React, { useState } from 'react';
import { Send, X, Shield, Mail, AlertCircle, CheckCircle2 } from 'lucide-react';
import { dataService } from '@/services/dataService';

interface EmailReplyFormProps {
    emailId: number;
    onClose: () => void;
    onSuccess: (message: string) => void;
}

const EmailReplyForm: React.FC<EmailReplyFormProps> = ({ emailId, onClose, onSuccess }) => {
    const [body, setBody] = useState('');
    const [account, setAccount] = useState<'no-reply' | 'redirection'>('no-reply');
    const [isSending, setIsSending] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!body.trim()) {
            setError('Please enter a message.');
            return;
        }

        setIsSending(true);
        setError(null);

        try {
            const response = await dataService.replyToEmail(emailId, body, account);
            onSuccess(response.message);
            onClose();
        } catch (err: any) {
            console.error("Error sending reply:", err);
            setError(err.response?.data?.error || 'Failed to send reply. Please try again.');
        } finally {
            setIsSending(false);
        }
    };

    return (
        <div className="bg-zinc-950/80 border border-zinc-800 rounded-[2.5rem] overflow-hidden animate-in fade-in slide-in-from-top-4 duration-500 shadow-[0_30px_60px_-15px_rgba(0,0,0,0.7)] backdrop-blur-2xl">
            <div className="px-10 py-6 border-b border-zinc-900 flex items-center justify-between bg-zinc-900/30">
                <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-2xl bg-brand-green/10 flex items-center justify-center text-brand-green border border-brand-green/20 shadow-[0_0_20px_rgba(34,197,94,0.1)]">
                        <Send size={22} />
                    </div>
                    <div>
                        <h3 className="text-lg font-black uppercase tracking-[0.25em] text-white">Compose Reply</h3>
                        <p className="text-[10px] text-zinc-500 font-black uppercase tracking-widest mt-0.5">Vankel Communications Engine</p>
                    </div>
                </div>
                <button
                    onClick={onClose}
                    className="w-12 h-12 flex items-center justify-center text-zinc-500 hover:text-white hover:bg-zinc-900 border border-transparent hover:border-zinc-800 rounded-2xl transition-all"
                >
                    <X size={24} />
                </button>
            </div>

            <form onSubmit={handleSubmit} className="p-10 space-y-10">
                {/* Account Selection */}
                <div className="space-y-5">
                    <div className="flex items-center gap-3 ml-1">
                        <div className="w-1.5 h-4 bg-brand-green rounded-full shadow-[0_0_10px_rgba(34,197,94,0.5)]"></div>
                        <label className="text-xs font-black uppercase tracking-[0.2em] text-zinc-500">
                            Sender Identity
                        </label>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <button
                            type="button"
                            onClick={() => setAccount('no-reply')}
                            className={`flex items-center gap-5 p-5 rounded-3xl border-2 transition-all text-left relative overflow-hidden group ${account === 'no-reply'
                                ? 'bg-brand-green/[0.03] border-brand-green/50 text-white shadow-[0_10px_30px_-10px_rgba(34,197,94,0.1)]'
                                : 'bg-zinc-900/30 border-zinc-800/50 text-zinc-500 hover:border-zinc-700 hover:bg-zinc-900/50'
                                }`}
                        >
                            {account === 'no-reply' && (
                                <div className="absolute top-0 right-0 p-2 bg-brand-green text-black rounded-bl-2xl shadow-lg">
                                    <CheckCircle2 size={14} />
                                </div>
                            )}
                            <div className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 border transition-all ${account === 'no-reply' ? 'bg-brand-green/20 text-brand-green border-brand-green/30 shadow-[0_0_20px_rgba(34,197,94,0.2)]' : 'bg-zinc-950 text-zinc-700 border-zinc-800'}`}>
                                <Shield size={22} />
                            </div>
                            <div className="min-w-0">
                                <p className={`text-sm font-black truncate transition-colors ${account === 'no-reply' ? 'text-white' : 'text-zinc-500'}`}>no-reply@vanakelgroup.com</p>
                                <p className="text-[10px] opacity-60 font-black uppercase tracking-tighter mt-1">Official Property Management</p>
                            </div>
                        </button>

                        <button
                            type="button"
                            onClick={() => setAccount('redirection')}
                            className={`flex items-center gap-5 p-5 rounded-3xl border-2 transition-all text-left relative overflow-hidden group ${account === 'redirection'
                                ? 'bg-blue-500/[0.03] border-blue-500/50 text-white shadow-[0_10px_30px_-10px_rgba(59,130,246,0.1)]'
                                : 'bg-zinc-900/30 border-zinc-800/50 text-zinc-500 hover:border-zinc-700 hover:bg-zinc-900/50'
                                }`}
                        >
                            {account === 'redirection' && (
                                <div className="absolute top-0 right-0 p-2 bg-blue-500 text-white rounded-bl-2xl shadow-lg">
                                    <CheckCircle2 size={14} />
                                </div>
                            )}
                            <div className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 border transition-all ${account === 'redirection' ? 'bg-blue-500/20 text-blue-400 border-blue-500/30' : 'bg-zinc-950 text-zinc-700 border-zinc-800'}`}>
                                <Mail size={22} />
                            </div>
                            <div className="min-w-0">
                                <p className={`text-sm font-black truncate transition-colors ${account === 'redirection' ? 'text-white' : 'text-zinc-500'}`}>Redirection@vanakelgroup.com</p>
                                <p className="text-[10px] opacity-60 font-black uppercase tracking-tighter mt-1">Direct Support Channel</p>
                            </div>
                        </button>
                    </div>
                </div>

                {/* Message Body */}
                <div className="space-y-5">
                    <div className="flex items-center gap-3 ml-1">
                        <div className="w-1.5 h-4 bg-brand-green rounded-full shadow-[0_0_10px_rgba(34,197,94,0.5)]"></div>
                        <label className="text-xs font-black uppercase tracking-[0.2em] text-zinc-500">
                            Message Content
                        </label>
                    </div>
                    <div className="relative group">
                        <div className="absolute -inset-1 bg-gradient-to-b from-brand-green/10 to-transparent rounded-[2rem] opacity-0 group-focus-within:opacity-100 transition-opacity blur-xl"></div>
                        <textarea
                            value={body}
                            onChange={(e) => setBody(e.target.value)}
                            placeholder="Describe your response in detail..."
                            className="relative w-full min-h-[300px] bg-black/40 border-2 border-zinc-800 rounded-[2rem] p-8 text-base text-zinc-200 placeholder:text-zinc-800 focus:outline-none focus:ring-0 focus:border-brand-green/40 transition-all resize-none shadow-[inset_0_4px_20px_rgba(0,0,0,0.4)] leading-relaxed font-medium"
                        />
                        <div className="absolute bottom-6 right-8 flex items-center gap-3">
                            <span className="px-3 py-1 rounded-full bg-zinc-950 border border-zinc-800 text-[9px] font-black font-mono text-zinc-600 uppercase tracking-widest">{body.length} CHARS</span>
                        </div>
                    </div>
                </div>

                {error && (
                    <div className="flex items-center gap-4 p-5 bg-red-500/5 border border-red-500/20 rounded-2xl text-red-500 text-xs animate-in slide-in-from-left-2 duration-300">
                        <AlertCircle size={20} className="shrink-0" />
                        <span className="font-bold">{error}</span>
                    </div>
                )}

                <div className="flex items-center justify-end gap-5 pt-6 border-t border-zinc-900/50">
                    <button
                        type="button"
                        onClick={onClose}
                        className="px-10 py-4 text-xs font-black uppercase tracking-[0.3em] text-zinc-600 hover:text-white transition-all hover:bg-zinc-900 rounded-2xl"
                    >
                        Discard
                    </button>
                    <button
                        type="submit"
                        disabled={isSending || !body.trim()}
                        className={`flex items-center gap-4 px-12 py-5 bg-brand-green text-black font-black text-sm uppercase tracking-[0.3em] rounded-2xl transition-all shadow-[0_20px_40px_-10px_rgba(34,197,94,0.3)] active:scale-95 ${isSending || !body.trim() ? 'opacity-30 cursor-not-allowed grayscale' : 'hover:bg-white hover:shadow-[0_20px_40px_-10px_rgba(255,255,255,0.2)] hover:-translate-y-1'
                            }`}
                    >
                        {isSending ? (
                            <>
                                <div className="w-5 h-5 border-[3px] border-black/20 border-t-black rounded-full animate-spin" />
                                Processing...
                            </>
                        ) : (
                            <>
                                <Send size={18} />
                                Dispatch Message
                            </>
                        )}
                    </button>
                </div>
            </form>
        </div>
    );
};

export default EmailReplyForm;
