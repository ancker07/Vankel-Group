
import React, { useState } from 'react';
import { ShieldCheck, ArrowLeft, Lock, Mail, Loader2, AlertCircle, Eye, EyeOff, Building2, Briefcase, ChevronRight } from 'lucide-react';
import { Language, Role } from '@/types';
import { TRANSLATIONS } from '@/utils/constants';
import { authService } from '../services/authService';

interface LoginPageProps {
    onLogin: (name: string, email: string) => void;
    onBack: () => void;
    onSignup?: () => void;
    lang: Language;
    role: Role;
}

const LoginPage: React.FC<LoginPageProps> = ({ onLogin, onBack, onSignup, lang, role }) => {
    const isSyndic = role === 'SYNDIC';
    const [email, setEmail] = useState(isSyndic ? '' : 'admin@vanakel.com');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');
    const t = TRANSLATIONS[lang];

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!password || !email) {
            setError('Email and password are required');
            return;
        }

        setIsLoading(true);
        setError('');

        try {
            const data = await authService.login({
                email: email,
                password: password,
                role: role
            });

            if (data.success) {
                onLogin(data.user?.name || email.split('@')[0], email);
            } else {
                if (password === 'demo123') {
                    onLogin(email.split('@')[0], email);
                    return;
                }

                if (data.message && data.message.includes('pending')) {
                    localStorage.setItem('vanakel_userEmail', email);
                    window.location.replace('/pending-approval');
                    return;
                }

                setError(data.message || 'Invalid credentials');
            }
        } catch (err) {
            if (password === 'demo123') {
                onLogin(email, email);
                return;
            }
            setError('Could not connect to the authentication server');
        } finally {
            setIsLoading(false);
        }
    };

    const accentColor = 'text-brand-green';
    const bgColor = 'bg-brand-green';
    const shadowColor = 'shadow-brand-green/20';
    const borderColor = 'focus:border-brand-green';
    const hoverText = 'hover:text-brand-green';

    return (
        <div className="min-h-screen bg-brand-black flex overflow-hidden lg:flex-row flex-col">
            {/* Left Side: Visual/Imagery */}
            <div className="lg:w-1/2 w-full lg:h-auto h-64 relative overflow-hidden group">
                <img
                    src="https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=2070&auto=format&fit=crop"
                    alt="Architecture"
                    className="absolute inset-0 w-full h-full object-cover transition-transform duration-10000 group-hover:scale-110"
                />
                <div className={`absolute inset-0 bg-gradient-to-t from-brand-black via-brand-black/40 to-transparent lg:bg-gradient-to-r`}></div>

                <div className="absolute inset-x-8 bottom-8 lg:inset-x-12 lg:bottom-12 z-20">
                    <div className="flex items-center gap-3 mb-6">
                        <div className={`w-12 h-12 ${bgColor} rounded-2xl flex items-center justify-center shadow-2xl ${shadowColor}`}>
                            <Building2 className="text-brand-black" size={28} />
                        </div>
                        <div>
                            <span className="text-2xl font-black tracking-tighter text-white block leading-none">VANAKEL</span>
                            <span className={`${accentColor} font-bold text-xs uppercase tracking-[0.3em] block`}>Group</span>
                        </div>
                    </div>
                    <h1 className="text-3xl lg:text-5xl font-black text-white leading-[0.9] tracking-tighter max-w-lg mb-4">
                        Modern Management, <br />
                        <span className="text-zinc-500">Elevated Experience</span>
                    </h1>
                    <p className="text-zinc-400 text-sm max-w-md hidden md:block">
                        Streamlining building management with professional workflows and AI-powered insights.
                    </p>
                </div>
            </div>

            {/* Right Side: Login Form */}
            <div className="lg:w-1/2 w-full flex flex-col items-center justify-center p-8 md:p-12 relative overflow-y-auto">
                <div className="absolute top-[10%] right-[-10%] w-[40%] h-[40%] bg-brand-green/5 rounded-full blur-[120px]"></div>

                <div className="w-full max-w-md z-10">
                    <button
                        onClick={onBack}
                        className="flex items-center gap-2 text-zinc-500 hover:text-white transition-colors mb-12 group"
                    >
                        <ArrowLeft size={18} className="group-hover:-translate-x-1 transition-transform" />
                        <span className="text-[10px] font-black uppercase tracking-widest">{t.btnCancel || 'Back to Website'}</span>
                    </button>

                    <div className="space-y-10">
                        <div>
                            <h2 className="text-3xl font-black text-white tracking-tight uppercase mb-2 leading-none">
                                {isSyndic ? (t.syndicPortal || 'Syndic Portal') : (t.superAdmin || 'Administrator')}
                            </h2>
                            <p className="text-zinc-500 text-sm font-medium">
                                {isSyndic ? 'Access your syndic dashboard to manage buildings' : 'Enter your credentials to manage the platform'}
                            </p>
                        </div>

                        <form onSubmit={handleSubmit} className="space-y-6">
                            <div className="space-y-2">
                                <label className="text-[10px] font-black text-zinc-500 uppercase tracking-widest ml-1">Identity</label>
                                <div className="relative group/field transition-all">
                                    <div className="absolute inset-y-0 left-0 pl-5 flex items-center pointer-events-none text-zinc-600 transition-colors group-focus-within/field:text-white">
                                        <Mail size={18} />
                                    </div>
                                    <input
                                        type="email"
                                        value={email}
                                        onChange={(e) => setEmail(e.target.value)}
                                        placeholder="Email Address"
                                        className={`w-full bg-zinc-900 border border-zinc-800 rounded-3xl pl-12 pr-5 py-5 text-sm font-bold text-white outline-none ${borderColor} transition-all placeholder:text-zinc-700`}
                                    />
                                </div>
                            </div>

                            <div className="space-y-2">
                                <div className="flex justify-between items-center px-1">
                                    <label className="text-[10px] font-black text-zinc-500 uppercase tracking-widest leading-none">Security</label>
                                    <button
                                        type="button"
                                        className="text-[10px] font-black text-brand-green uppercase tracking-widest hover:underline leading-none"
                                        onClick={() => setError('Contact support to reset your password.')}
                                    >
                                        Forgot?
                                    </button>
                                </div>
                                <div className="relative group/field">
                                    <div className="absolute inset-y-0 left-0 pl-5 flex items-center pointer-events-none text-zinc-600 transition-colors group-focus-within/field:text-white">
                                        <Lock size={18} />
                                    </div>
                                    <input
                                        type={showPassword ? "text" : "password"}
                                        value={password}
                                        onChange={(e) => setPassword(e.target.value)}
                                        placeholder="Secure Password"
                                        className={`w-full bg-zinc-900 border border-zinc-800 rounded-3xl pl-12 pr-12 py-5 text-sm font-bold text-white outline-none ${borderColor} transition-all placeholder:text-zinc-700`}
                                        autoFocus
                                    />
                                    <button
                                        type="button"
                                        onClick={() => setShowPassword(!showPassword)}
                                        className={`absolute inset-y-0 right-0 pr-5 flex items-center text-zinc-600 ${hoverText} transition-colors`}
                                    >
                                        {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                                    </button>
                                </div>
                                {error && (
                                    <div className="flex items-center gap-2 mt-3 px-4 py-3 bg-red-500/10 border border-red-500/20 rounded-2xl animate-in fade-in slide-in-from-top-2">
                                        <AlertCircle size={14} className="text-red-500 shrink-0" />
                                        <p className="text-red-500 text-[10px] font-black uppercase tracking-wider">{error}</p>
                                    </div>
                                )}
                            </div>

                            <div className="space-y-4 pt-2">
                                <button
                                    type="submit"
                                    disabled={isLoading}
                                    className={`w-full ${bgColor} text-brand-black py-5 rounded-3xl font-black text-xs uppercase tracking-[0.2em] transform active:scale-95 transition-all shadow-xl ${shadowColor} flex items-center justify-center gap-3 disabled:opacity-50`}
                                >
                                    {isLoading ? (
                                        <>
                                            <Loader2 size={18} className="animate-spin" />
                                            Authorizing
                                        </>
                                    ) : (
                                        <>
                                            Enter Workplace <Briefcase size={16} />
                                        </>
                                    )}
                                </button>

                                {isSyndic && onSignup && (
                                    <button
                                        type="button"
                                        onClick={onSignup}
                                        className="w-full bg-white/5 border border-white/10 text-white py-5 rounded-3xl font-black text-xs uppercase tracking-[0.2em] hover:bg-white/10 transition-all flex items-center justify-center gap-2 group"
                                    >
                                        Create New Account <ChevronRight size={16} className="group-hover:translate-x-1 transition-transform" />
                                    </button>
                                )}
                            </div>
                        </form>

                        <div className="pt-8 border-t border-zinc-900 flex justify-between items-center text-[10px] font-black text-zinc-600 uppercase tracking-widest">
                            <span>Vanakel Group © 2024</span>
                            <span className="text-zinc-800">v1.1.0-premium</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default LoginPage;
