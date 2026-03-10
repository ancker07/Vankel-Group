
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
        <div className="bg-zinc-900/50 border border-zinc-800 rounded-2xl overflow-hidden animate-in fade-in slide-in-from-top-4 duration-300">
            <div className="px-6 py-4 border-b border-zinc-800 flex items-center justify-between bg-zinc-900/80">
                <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-lg bg-brand-green/10 flex items-center justify-center text-brand-green">
                        <Send size={16} />
                    </div>
                    <h3 className="text-sm font-black uppercase tracking-widest text-white">Compose Reply</h3>
                </div>
                <button
                    onClick={onClose}
                    className="p-2 text-zinc-500 hover:text-white hover:bg-zinc-800 rounded-lg transition-all"
                >
                    <X size={18} />
                </button>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-6">
                {/* Account Selection */}
                <div className="space-y-3">
                    <label className="text-[10px] font-black uppercase tracking-widest text-zinc-500 ml-1">
                        Send From
                    </label>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                        <button
                            type="button"
                            onClick={() => setAccount('no-reply')}
                            className={`flex items-center gap-3 p-3 rounded-xl border transition-all text-left ${account === 'no-reply'
                                    ? 'bg-brand-green/10 border-brand-green/50 text-white ring-1 ring-brand-green/20'
                                    : 'bg-zinc-950/50 border-zinc-800 text-zinc-500 hover:border-zinc-700'
                                }`}
                        >
                            <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${account === 'no-reply' ? 'bg-brand-green/20 text-brand-green' : 'bg-zinc-900 text-zinc-600'}`}>
                                <Shield size={16} />
                            </div>
                            <div>
                                <p className="text-xs font-bold">no-reply@vanakelgroup.com</p>
                                <p className="text-[10px] opacity-60">Professional Management</p>
                            </div>
                        </button>

                        <button
                            type="button"
                            onClick={() => setAccount('redirection')}
                            className={`flex items-center gap-3 p-3 rounded-xl border transition-all text-left ${account === 'redirection'
                                    ? 'bg-blue-500/10 border-blue-500/50 text-white ring-1 ring-blue-500/20'
                                    : 'bg-zinc-950/50 border-zinc-800 text-zinc-500 hover:border-zinc-700'
                                }`}
                        >
                            <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${account === 'redirection' ? 'bg-blue-500/20 text-blue-400' : 'bg-zinc-900 text-zinc-600'}`}>
                                <Mail size={16} />
                            </div>
                            <div>
                                <p className="text-xs font-bold">Redirection@vanakelgroup.com</p>
                                <p className="text-[10px] opacity-60">Alternative Account</p>
                            </div>
                        </button>
                    </div>
                </div>

                {/* Message Body */}
                <div className="space-y-3">
                    <label className="text-[10px] font-black uppercase tracking-widest text-zinc-500 ml-1 font-mono">
                        Your Message
                    </label>
                    <textarea
                        value={body}
                        onChange={(e) => setBody(e.target.value)}
                        placeholder="Type your reply here..."
                        className="w-full min-h-[200px] bg-zinc-950 border border-zinc-800 rounded-2xl p-4 text-sm text-white placeholder:text-zinc-700 focus:outline-none focus:ring-2 focus:ring-brand-green/20 focus:border-brand-green/50 transition-all resize-none shadow-inner"
                    />
                </div>

                {error && (
                    <div className="flex items-center gap-3 p-4 bg-red-500/10 border border-red-500/20 rounded-xl text-red-500 text-xs animate-in fade-in zoom-in-95">
                        <AlertCircle size={16} />
                        <span className="font-bold">{error}</span>
                    </div>
                )}

                <div className="flex items-center justify-end gap-3 pt-2">
                    <button
                        type="button"
                        onClick={onClose}
                        className="px-6 py-2.5 text-xs font-bold uppercase tracking-widest text-zinc-500 hover:text-white transition-colors"
                    >
                        Cancel
                    </button>
                    <button
                        type="submit"
                        disabled={isSending || !body.trim()}
                        className={`flex items-center gap-2 px-8 py-2.5 bg-brand-green text-black font-black text-xs uppercase tracking-widest rounded-xl transition-all shadow-lg shadow-brand-green/10 active:scale-95 ${isSending || !body.trim() ? 'opacity-50 cursor-not-allowed grayscale' : 'hover:bg-white hover:shadow-white/10'
                            }`}
                    >
                        {isSending ? (
                            <>
                                <div className="w-3 h-3 border-2 border-black/20 border-t-black rounded-full animate-spin" />
                                Sending...
                            </>
                        ) : (
                            <>
                                <Send size={14} />
                                Send Reply
                            </>
                        )}
                    </button>
                </div>
            </form>
        </div>
    );
};

export default EmailReplyForm;
