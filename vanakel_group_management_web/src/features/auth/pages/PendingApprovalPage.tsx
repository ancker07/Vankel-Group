
import React, { useEffect } from 'react';
import { Clock, ShieldCheck, Mail, ArrowLeft, LogOut } from 'lucide-react';
import { Language } from '@/types';
import { TRANSLATIONS } from '@/utils/constants';
import { authService } from '../services/authService';

interface PendingApprovalPageProps {
    lang: Language;
    onLogout: () => void;
    onApproved: () => void;
}

const PendingApprovalPage: React.FC<PendingApprovalPageProps> = ({ lang, onLogout, onApproved }) => {
    const t = TRANSLATIONS[lang];

    const [checkError, setCheckError] = React.useState<string | null>(null);
    const [savedEmail, setSavedEmail] = React.useState<string | null>(null);

    const checkStatus = React.useCallback(async () => {
        const email = localStorage.getItem('vanakel_userEmail');
        setSavedEmail(email);

        if (!email) {
            setCheckError("Email not found in local session. Please try logging in again.");
            return;
        }

        try {
            setCheckError(null);
            const data = await authService.checkStatus(email);

            if (data.success && data.status === 'APPROVED') {
                onApproved();
            } else if (data.success) {
                // Just log to console or silently succeed
                console.log(`Current status for ${email}: ${data.status}`);
            } else {
                setCheckError(data.message || 'Unknown status');
            }
        } catch (err: any) {
            console.error('Failed to check status', err);
            setCheckError(`Network Error: ${err.message}`);
        }
    }, [onApproved]);

    useEffect(() => {
        checkStatus();
        const interval = setInterval(checkStatus, 5000); // Check every 5s
        return () => clearInterval(interval);
    }, [checkStatus]);

    return (
        <div className="min-h-screen bg-brand-black flex flex-col items-center justify-center p-6 relative overflow-hidden">
            {/* Background Aesthetics */}
            <div className="absolute top-[-10%] right-[-10%] w-[60%] h-[60%] bg-brand-green/5 rounded-full blur-[120px]"></div>
            <div className="absolute bottom-[-10%] left-[-10%] w-[40%] h-[40%] bg-brand-green/5 rounded-full blur-[100px]"></div>

            <div className="max-w-md w-full z-10 text-center space-y-10 animate-in fade-in slide-in-from-bottom-8 duration-700">
                <div className="relative inline-block">
                    <div className="w-24 h-24 bg-zinc-900 border border-zinc-800 rounded-[2rem] flex items-center justify-center mx-auto shadow-2xl relative z-10">
                        <Clock className="text-brand-green animate-pulse" size={40} />
                    </div>
                    <div className="absolute inset-0 bg-brand-green/20 blur-2xl rounded-full scale-110"></div>
                </div>

                <div className="space-y-4">
                    <h1 className="text-4xl font-black text-white tracking-tighter uppercase leading-none">
                        Pending <br />
                        <span className="text-brand-green">Approval</span>
                    </h1>
                    <p className="text-zinc-500 font-medium leading-relaxed">
                        Your account has been successfully created. For security reasons, an administrator must review and approve your access before you can enter the workplace.
                    </p>
                    {savedEmail && (
                        <p className="text-brand-green text-[10px] font-black uppercase tracking-widest mt-2">
                            Checking status for: {savedEmail}
                        </p>
                    )}
                    {checkError && (
                        <p className="text-red-500 text-xs font-bold bg-red-500/10 p-2 rounded-xl mt-2">
                            {checkError}
                        </p>
                    )}
                </div>

                <div className="bg-zinc-900/50 border border-zinc-800 rounded-3xl p-6 space-y-4 text-left">
                    <div className="flex items-start gap-4">
                        <div className="w-8 h-8 rounded-lg bg-brand-green/10 flex items-center justify-center shrink-0">
                            <ShieldCheck size={18} className="text-brand-green" />
                        </div>
                        <div>
                            <p className="text-xs font-black text-white uppercase tracking-widest mb-1">Status Verification</p>
                            <p className="text-[10px] text-zinc-500 font-medium">We are currently verifying your professional credentials.</p>
                        </div>
                    </div>
                    <div className="flex items-start gap-4">
                        <div className="w-8 h-8 rounded-lg bg-zinc-800 flex items-center justify-center shrink-0">
                            <Mail size={18} className="text-zinc-400" />
                        </div>
                        <div>
                            <p className="text-xs font-black text-white uppercase tracking-widest mb-1">Email Confirmation</p>
                            <p className="text-[10px] text-zinc-500 font-medium">You will receive an email notification as soon as your account is activated.</p>
                        </div>
                    </div>
                </div>

                <div className="pt-6 border-t border-zinc-900 flex flex-col gap-4">
                    <p className="text-[10px] font-black text-zinc-600 uppercase tracking-[0.2em]">Need help? contact@vanakel.be</p>

                    <button
                        onClick={onLogout}
                        className="flex items-center justify-center gap-2 group text-zinc-500 hover:text-white transition-colors py-2"
                    >
                        <LogOut size={16} className="group-hover:-translate-x-1 transition-transform" />
                        <span className="text-[10px] font-black uppercase tracking-widest">{t.logout || 'Sign Out'}</span>
                    </button>
                </div>
            </div>

            {/* Brand Watermark */}
            <div className="absolute bottom-12 flex items-center gap-2 opacity-20">
                <span className="text-sm font-black tracking-tighter text-white">VANAKEL</span>
                <div className="w-1 h-1 bg-brand-green rounded-full"></div>
                <span className="text-brand-green font-bold text-[8px] uppercase tracking-[0.3em]">Management</span>
            </div>
        </div>
    );
};

export default PendingApprovalPage;
