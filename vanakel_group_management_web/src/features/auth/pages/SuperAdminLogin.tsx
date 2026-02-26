
import React, { useState } from 'react';
import { ShieldCheck, ArrowLeft, Lock, Mail, Loader2, AlertCircle, Eye, EyeOff } from 'lucide-react';
import { Language } from '@/types';
import { TRANSLATIONS } from '@/utils/constants';
import { authService } from '../services/authService';

interface SuperAdminLoginProps {
    onLogin: (name: string) => void;
    onBack: () => void;
    lang: Language;
}

const SuperAdminLogin: React.FC<SuperAdminLoginProps> = ({ onLogin, onBack, lang }) => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');
    const t = TRANSLATIONS[lang];

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!email) {
            setError('Email is required');
            return;
        }
        if (!password) {
            setError('Password is required');
            return;
        }

        setIsLoading(true);
        setError('');

        try {
            const data = await authService.login({
                email: email,
                password: password,
                role: 'SUPERADMIN'
            });

            if (data.success) {
                onLogin(data.user?.name || 'Super Admin');
            } else {
                setError(data.message || 'Invalid Super Admin credentials');
            }
        } catch (err) {
            setError('Could not connect to the authentication server');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-brand-black flex flex-col items-center justify-center p-4 relative overflow-hidden">
            {/* Decorative Elements */}
            <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-brand-green/10 rounded-full blur-[120px]"></div>
            <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-brand-green/10 rounded-full blur-[120px]"></div>

            <div className="w-full max-w-md z-10">
                <button
                    onClick={onBack}
                    className="flex items-center gap-2 text-zinc-500 hover:text-white transition-colors mb-8 group"
                >
                    <ArrowLeft size={18} className="group-hover:-translate-x-1 transition-transform" />
                    <span className="text-sm font-bold uppercase tracking-widest">{t.btnCancel}</span>
                </button>

                <div className="bg-zinc-950 border border-zinc-900 rounded-[2.5rem] p-8 md:p-10 shadow-2xl relative">
                    <div className="absolute -top-10 left-1/2 -translate-x-1/2 w-20 h-20 bg-brand-green rounded-3xl flex items-center justify-center shadow-2xl shadow-brand-green/20">
                        <ShieldCheck className="text-brand-black" size={40} />
                    </div>

                    <div className="text-center mt-10 mb-8">
                        <h2 className="text-2xl font-black text-white tracking-tight uppercase">{t.superAdmin}</h2>
                        <p className="text-zinc-500 text-sm mt-2">Secure access for platform administrators</p>
                    </div>

                    <form onSubmit={handleSubmit} className="space-y-6">
                        <div className="space-y-2">
                            <label className="text-[10px] font-black text-zinc-600 uppercase tracking-[0.2em] ml-2">Email Address</label>
                            <div className="relative group">
                                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-zinc-600 group-focus-within:text-brand-green transition-colors">
                                    <Mail size={18} />
                                </div>
                                <input
                                    type="email"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    placeholder="Enter admin email address"
                                    className="w-full bg-zinc-900 border border-zinc-800 rounded-2xl pl-12 pr-4 py-4 text-sm font-bold text-white outline-none focus:border-brand-green transition-all"
                                />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <label className="text-[10px] font-black text-zinc-600 uppercase tracking-[0.2em] ml-2">Security Password</label>
                            <div className="relative group">
                                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-zinc-600 group-focus-within:text-brand-green transition-colors">
                                    <Lock size={18} />
                                </div>
                                <input
                                    type={showPassword ? "text" : "password"}
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    placeholder="Enter secure password"
                                    className="w-full bg-zinc-900 border border-zinc-800 rounded-2xl pl-12 pr-12 py-4 text-sm font-bold text-white outline-none focus:border-brand-green transition-all"
                                    autoFocus
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                    className="absolute inset-y-0 right-0 pr-4 flex items-center text-zinc-600 hover:text-brand-green transition-colors"
                                >
                                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                                </button>
                            </div>
                            {error && (
                                <p className="text-red-500 text-[10px] font-bold mt-2 ml-2 flex items-center gap-1">
                                    <AlertCircle size={12} /> {error}
                                </p>
                            )}
                        </div>

                        <button
                            type="submit"
                            disabled={isLoading}
                            className="w-full bg-brand-green text-brand-black py-4 rounded-2xl font-black text-xs uppercase tracking-[0.2em] hover:bg-brand-green-light transition-all shadow-lg shadow-brand-green/20 flex items-center justify-center gap-2 disabled:opacity-50"
                        >
                            {isLoading ? (
                                <>
                                    <Loader2 size={18} className="animate-spin" />
                                    AUTHENTICATING...
                                </>
                            ) : (
                                'ENTER DASHBOARD'
                            )}
                        </button>
                    </form>

                    <p className="text-center text-[10px] text-zinc-700 mt-8 font-bold uppercase tracking-widest">
                        Vanakel Group Management Platform v1.0
                    </p>
                </div>
            </div>
        </div>
    );
};

export default SuperAdminLogin;
