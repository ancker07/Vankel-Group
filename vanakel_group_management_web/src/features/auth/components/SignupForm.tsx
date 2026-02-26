import React, { useState, useRef, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { User, Mail, Phone, Building2, ChevronRight, ArrowLeft, CheckCircle2, ShieldCheck, KeyRound, RefreshCw, Loader2, Lock, Eye, EyeOff } from 'lucide-react';
import { Language, Role } from '@/types';
import { TRANSLATIONS } from '@/utils/constants';
import { authService } from '../services/authService';

interface SignupFormProps {
    lang: Language;
    onBack: () => void;
    onSubmit: (request: any) => void;
}

type SignupStep = 'DETAILS' | 'OTP' | 'SUCCESS';

const SignupForm: React.FC<SignupFormProps> = ({ lang, onBack, onSubmit }) => {
    const t = TRANSLATIONS[lang];
    const location = useLocation();
    const [role, setRole] = useState<Role>((location.state as any)?.role || 'SYNDIC');
    const [step, setStep] = useState<SignupStep>('DETAILS');
    const [isLoading, setIsLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [formData, setFormData] = useState({
        firstName: '',
        lastName: '',
        email: '',
        password: '',
        phone: '',
        companyName: ''
    });

    // ... existing OTP logic ...
    const [otp, setOtp] = useState(['', '', '', '', '', '']);
    const otpRefs = useRef<(HTMLInputElement | null)[]>([]);

    useEffect(() => {
        if (step === 'OTP' && otpRefs.current[0]) {
            otpRefs.current[0].focus();
        }
    }, [step]);

    const handleInitialSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsLoading(true);
        setError(null);

        try {
            const result = await authService.signup({
                ...formData,
                role,
                id: `req-${Date.now()}`,
                timestamp: new Date().toISOString(),
                status: 'PENDING'
            });

            if (result.success) {
                if (role === 'SYNDIC') {
                    await authService.sendOtp(formData.email);
                    setStep('OTP');
                } else {
                    onSubmit({ ...formData, role });
                }
            } else {
                setError(result.message);
            }
        } catch (err) {
            setError(lang === 'FR' ? 'Une erreur est survenue.' : 'An error occurred.');
        } finally {
            setIsLoading(false);
        }
    };

    const handleOtpChange = (index: number, value: string) => {
        if (value.length > 1) value = value.slice(-1);
        if (!/^\d*$/.test(value)) return;

        const newOtp = [...otp];
        newOtp[index] = value;
        setOtp(newOtp);

        if (value && index < 5) {
            otpRefs.current[index + 1]?.focus();
        }
    };

    const handleKeyDown = (index: number, e: React.KeyboardEvent) => {
        if (e.key === 'Backspace' && !otp[index] && index > 0) {
            otpRefs.current[index - 1]?.focus();
        }
    };

    const handleVerifyOtp = async () => {
        const otpString = otp.join('');
        if (otpString.length !== 6) return;

        setIsLoading(true);
        setError(null);

        try {
            // Pass the details to create the user upon success
            const result = await authService.verifyOtp(formData.email, otpString, {
                ...formData,
                role
            });
            if (result.success) {
                onSubmit({ ...formData, role });
            } else {
                setError(t.otpError || 'Invalid code');
            }
        } catch (err) {
            setError(lang === 'FR' ? 'Erreur de vérification.' : 'Verification error.');
        } finally {
            setIsLoading(false);
        }
    };

    const handleResendOtp = async () => {
        setIsLoading(true);
        try {
            await authService.sendOtp(formData.email);
            // Optional: toast success
        } catch (err) {
            // Optional: toast error
        } finally {
            setIsLoading(false);
        }
    };

    if (step === 'SUCCESS') {
        return (
            <div className="min-h-screen bg-brand-black flex flex-col items-center justify-center p-6 text-center animate-in fade-in zoom-in duration-500">
                <div className="w-24 h-24 bg-brand-green/10 rounded-3xl flex items-center justify-center mb-8 border border-brand-green/20 shadow-2xl shadow-brand-green/10">
                    <CheckCircle2 className="text-brand-green w-12 h-12" />
                </div>
                <h2 className="text-3xl font-black text-white mb-4 tracking-tight uppercase">{t.signupSuccess}</h2>
                <p className="text-zinc-500 max-w-sm mb-10 font-medium">
                    {role === 'SYNDIC'
                        ? (lang === 'FR' ? 'Votre compte a été vérifié. Vous recevrez un e-mail une fois approuvé.' : 'Your account has been verified. You will receive an email once approved.')
                        : 'Your request has been sent to our administrators. You will receive an email once approved.'}
                </p>
                <button
                    onClick={onBack}
                    className="bg-brand-green text-brand-black px-10 py-4 rounded-3xl font-black uppercase tracking-widest hover:scale-105 transition-all shadow-xl shadow-brand-green/20"
                >
                    {t.backToLogin}
                </button>
            </div>
        );
    }

    if (step === 'OTP') {
        return (
            <div className="min-h-screen bg-brand-black flex items-center justify-center p-6 lg:p-12 relative overflow-hidden">
                <div className="absolute top-[10%] left-[-10%] w-[50%] h-[50%] bg-brand-green/5 rounded-full blur-[120px]"></div>

                <div className="w-full max-w-md z-10 space-y-12">
                    <button
                        onClick={() => setStep('DETAILS')}
                        className="flex items-center gap-2 text-zinc-500 hover:text-white transition-colors group"
                    >
                        <ArrowLeft size={18} className="group-hover:-translate-x-1 transition-transform" />
                        <span className="text-[10px] font-black uppercase tracking-widest">{t.back}</span>
                    </button>

                    <div className="text-center space-y-4">
                        <div className="w-16 h-16 bg-zinc-900 border border-zinc-800 rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-xl">
                            <KeyRound className="text-brand-green" size={28} />
                        </div>
                        <h2 className="text-3xl font-black text-white tracking-tight uppercase">{t.otpTitle || 'Verify Email'}</h2>
                        <p className="text-zinc-500 font-medium text-sm px-4 leading-relaxed">
                            {t.otpSubtitle || 'Enter the 6-digit code sent to'} <br />
                            <span className="text-white font-bold">{formData.email}</span>
                        </p>
                    </div>

                    <div className="space-y-8">
                        <div className="flex justify-between gap-2 sm:gap-4">
                            {otp.map((digit, idx) => (
                                <input
                                    key={idx}
                                    ref={(el) => (otpRefs.current[idx] = el)}
                                    type="text"
                                    maxLength={1}
                                    value={digit}
                                    onChange={(e) => handleOtpChange(idx, e.target.value)}
                                    onKeyDown={(e) => handleKeyDown(idx, e)}
                                    className="w-12 h-14 sm:w-14 sm:h-16 bg-zinc-900 border-2 border-zinc-800 rounded-xl text-center text-xl font-black text-white focus:border-brand-green focus:outline-none transition-all"
                                />
                            ))}
                        </div>

                        {error && (
                            <div className="bg-red-500/10 border border-red-500/20 text-red-500 px-4 py-3 rounded-2xl text-xs font-bold text-center animate-in fade-in slide-in-from-top-2">
                                {error}
                            </div>
                        )}

                        <div className="space-y-4">
                            <button
                                onClick={handleVerifyOtp}
                                disabled={isLoading || otp.join('').length !== 6}
                                className="w-full bg-brand-green text-brand-black py-5 rounded-[1.75rem] font-black uppercase tracking-[0.2em] text-xs hover:scale-[1.02] active:scale-[0.98] transition-all shadow-2xl shadow-brand-green/20 flex items-center justify-center gap-3 disabled:opacity-50 disabled:hover:scale-100"
                            >
                                {isLoading ? <Loader2 className="animate-spin" size={18} /> : (t.verify || 'Verify')}
                            </button>

                            <button
                                onClick={handleResendOtp}
                                disabled={isLoading}
                                className="w-full text-zinc-500 hover:text-white py-2 font-black uppercase tracking-widest text-[10px] transition-colors flex items-center justify-center gap-2"
                            >
                                <RefreshCw size={14} className={isLoading ? 'animate-spin' : ''} />
                                {t.resendCode || 'Resend Code'}
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        );
    }

    const accentColor = 'text-brand-green';
    const bgColor = 'bg-brand-green';
    const shadowColor = 'shadow-brand-green/20';
    const borderColor = 'focus:border-brand-green';

    return (
        <div className="min-h-screen bg-brand-black flex overflow-hidden lg:flex-row flex-col">
            {/* Left Side: Visual/Imagery */}
            <div className="lg:w-2/5 w-full lg:h-auto h-48 relative overflow-hidden group">
                <img
                    src="https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=2069&auto=format&fit=crop"
                    alt="Workplace"
                    className="absolute inset-0 w-full h-full object-cover transition-transform duration-10000 group-hover:scale-110"
                />
                <div className={`absolute inset-0 bg-gradient-to-t from-brand-black via-brand-black/40 to-transparent lg:bg-gradient-to-r`}></div>

                <div className="absolute inset-x-8 bottom-8 lg:inset-x-12 lg:bottom-12 z-20">
                    <div className="flex items-center gap-3 mb-6">
                        <div className={`w-10 h-10 ${bgColor} rounded-xl flex items-center justify-center shadow-lg transition-colors duration-500`}>
                            {role === 'SYNDIC' ? <Building2 className="text-brand-black" size={24} /> : <ShieldCheck className="text-brand-black" size={24} />}
                        </div>
                        <div>
                            <span className="text-xl font-black tracking-tighter text-white block leading-none">VANAKEL</span>
                            <span className={`${accentColor} font-bold text-[10px] uppercase tracking-[0.3em] block transition-colors duration-500`}>Management</span>
                        </div>
                    </div>
                    <h1 className="text-2xl lg:text-4xl font-black text-white leading-none tracking-tighter max-w-xs mb-4 uppercase">
                        Join the <br />
                        <span className="text-zinc-500">{role === 'SYNDIC' ? 'Manager Portal' : 'Admin Portal'}</span>
                    </h1>
                </div>
            </div>

            {/* Right Side: Signup Form */}
            <div className="lg:w-3/5 w-full flex flex-col items-center justify-center p-8 md:p-16 relative overflow-y-auto">
                <div className="absolute top-[5%] right-[-5%] w-[40%] h-[40%] bg-brand-green/5 rounded-full blur-[100px]"></div>

                <div className="w-full max-w-2xl z-10">
                    <button
                        onClick={onBack}
                        className="flex items-center gap-2 text-zinc-500 hover:text-white transition-colors mb-12 group"
                    >
                        <ArrowLeft size={18} className="group-hover:-translate-x-1 transition-transform" />
                        <span className="text-[10px] font-black uppercase tracking-widest">Back to portal</span>
                    </button>

                    <div className="mb-12">
                        <h2 className="text-4xl font-black text-white tracking-tight uppercase mb-3">
                            {role === 'SYNDIC' ? 'Manager Registration' : 'Admin Registration'}
                        </h2>
                        <p className="text-zinc-500 font-medium">Register your interest to join the Vanakel Group ecosystem.</p>
                    </div>

                    <form onSubmit={handleInitialSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-6">
                        {/* Role selection toggle removed to respect initial choice */}

                        <div className="space-y-2">
                            <label className="text-[10px] uppercase font-black tracking-widest text-zinc-500 ml-1">{t.firstName || 'First Name'}</label>
                            <div className="relative group/field">
                                <User className="absolute left-5 top-1/2 -translate-y-1/2 text-zinc-600 group-focus-within/field:text-white transition-colors" size={18} />
                                <input
                                    required
                                    type="text"
                                    value={formData.firstName}
                                    onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
                                    className={`w-full bg-zinc-900 border border-zinc-800 rounded-3xl py-5 pl-12 pr-5 text-white placeholder:text-zinc-700 outline-none ${borderColor} transition-all`}
                                    placeholder="e.g. Jean"
                                />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <label className="text-[10px] uppercase font-black tracking-widest text-zinc-500 ml-1">{t.lastName || 'Last Name'}</label>
                            <div className="relative group/field">
                                <User className="absolute left-5 top-1/2 -translate-y-1/2 text-zinc-600 group-focus-within/field:text-white transition-colors" size={18} />
                                <input
                                    required
                                    type="text"
                                    value={formData.lastName}
                                    onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
                                    className={`w-full bg-zinc-900 border border-zinc-800 rounded-3xl py-5 pl-12 pr-5 text-white placeholder:text-zinc-700 outline-none ${borderColor} transition-all`}
                                    placeholder="e.g. Dupont"
                                />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <label className="text-[10px] uppercase font-black tracking-widest text-zinc-500 ml-1">{t.emailAddress || 'Email Address'}</label>
                            <div className="relative group/field">
                                <Mail className="absolute left-5 top-1/2 -translate-y-1/2 text-zinc-600 group-focus-within/field:text-white transition-colors" size={18} />
                                <input
                                    required
                                    type="email"
                                    value={formData.email}
                                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                    className={`w-full bg-zinc-900 border border-zinc-800 rounded-3xl py-5 pl-12 pr-5 text-white placeholder:text-zinc-700 outline-none ${borderColor} transition-all`}
                                    placeholder="email@example.com"
                                />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <label className="text-[10px] uppercase font-black tracking-widest text-zinc-500 ml-1">{t.gsm || 'Mobile / GSM'}</label>
                            <div className="relative group/field">
                                <Phone className="absolute left-5 top-1/2 -translate-y-1/2 text-zinc-600 group-focus-within/field:text-white transition-colors" size={18} />
                                <input
                                    required
                                    type="tel"
                                    value={formData.phone}
                                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                                    className={`w-full bg-zinc-900 border border-zinc-800 rounded-3xl py-5 pl-12 pr-5 text-white placeholder:text-zinc-700 outline-none ${borderColor} transition-all`}
                                    placeholder="+32"
                                />
                            </div>
                        </div>

                        {role === 'SYNDIC' && (
                            <div className="col-span-1 md:col-span-2 space-y-2 animate-in slide-in-from-top-4 duration-500">
                                <label className="text-[10px] uppercase font-black tracking-widest text-zinc-500 ml-1">{t.companyName || 'Company Name'}</label>
                                <div className="relative group/field">
                                    <Building2 className="absolute left-5 top-1/2 -translate-y-1/2 text-zinc-600 group-focus-within/field:text-white transition-colors" size={18} />
                                    <input
                                        required
                                        type="text"
                                        value={formData.companyName}
                                        onChange={(e) => setFormData({ ...formData, companyName: e.target.value })}
                                        className={`w-full bg-zinc-900 border border-zinc-800 rounded-3xl py-5 pl-12 pr-5 text-white placeholder:text-zinc-700 outline-none ${borderColor} transition-all`}
                                        placeholder="Organization Name"
                                    />
                                </div>
                            </div>
                        )}

                        <div className="col-span-1 md:col-span-2 space-y-2">
                            <label className="text-[10px] uppercase font-black tracking-widest text-zinc-500 ml-1">Secure Password</label>
                            <div className="relative group/field">
                                <Lock className="absolute left-5 top-1/2 -translate-y-1/2 text-zinc-600 group-focus-within/field:text-white transition-colors" size={18} />
                                <input
                                    required
                                    type={showPassword ? "text" : "password"}
                                    value={formData.password}
                                    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                                    className={`w-full bg-zinc-900 border border-zinc-800 rounded-3xl py-5 pl-12 pr-12 text-white placeholder:text-zinc-700 outline-none ${borderColor} transition-all`}
                                    placeholder="••••••••"
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                    className="absolute right-5 top-1/2 -translate-y-1/2 text-zinc-600 hover:text-white transition-colors"
                                >
                                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                                </button>
                            </div>
                        </div>

                        {error && (
                            <div className="col-span-1 md:col-span-2 bg-red-500/10 border border-red-500/20 text-red-500 px-4 py-3 rounded-2xl text-xs font-bold text-center">
                                {error}
                            </div>
                        )}

                        <button
                            type="submit"
                            disabled={isLoading}
                            className={`col-span-1 md:col-span-2 w-full ${bgColor} text-brand-black py-5 rounded-[1.75rem] font-black uppercase tracking-[0.2em] text-xs hover:scale-[1.02] active:scale-[0.98] transition-all shadow-2xl ${shadowColor} flex items-center justify-center gap-3 mt-6 disabled:opacity-50`}
                        >
                            {isLoading ? <Loader2 className="animate-spin" size={18} /> : (t.submitRequest || 'Submit Request')}
                            {!isLoading && <ChevronRight size={18} strokeWidth={3} />}
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default SignupForm;
