
import React from 'react';
import { useNavigate } from 'react-router-dom';

import {
    Building2,
    ShieldCheck,
    Briefcase,
    User,
    ArrowRight,
    CheckCircle2,
    Zap,
    BarChart3,
    Mail,
    MapPin,
    FileText,
    LayoutDashboard,
    Menu,
    X
} from 'lucide-react';
import { Role, Language } from '@/types';
import { TRANSLATIONS } from '@/utils/constants';
import RoleSelectionModal from '@/components/common/RoleSelectionModal';

interface HomePageProps {
    onSelect: (role: Role) => void;
    lang: Language;
    setLang: (l: Language) => void;
    onSignup: (role?: Role) => void;
    onSuperAdminLogin: () => void;
    role?: Role | null;
    isApproved?: boolean;
    userName?: string;
}

const HomePage: React.FC<HomePageProps> = ({ onSelect, lang, setLang, onSignup, onSuperAdminLogin, role, isApproved, userName }) => {

    const t = TRANSLATIONS[lang];
    const navigate = useNavigate();
    const [isMenuOpen, setIsMenuOpen] = React.useState(false);
    const [roleSelectionMode, setRoleSelectionMode] = React.useState<'LOGIN' | 'SIGNUP' | null>(null);

    const getDashboardPath = () => {
        if (!role) return '/';
        if (role === 'SUPERADMIN') return '/admin/dashboard';
        if (!isApproved) return '/pending-approval';
        return role === 'SYNDIC' ? '/syndic/dashboard' : '/admin/dashboard';
    };


    const handleRoleSelect = (role: Role) => {
        setRoleSelectionMode(null);
        if (roleSelectionMode === 'LOGIN') {
            if (role === 'SUPERADMIN') onSuperAdminLogin();
            else onSelect(role);
        } else if (roleSelectionMode === 'SIGNUP') {
            onSignup(role);
        }
    };

    return (
        <div className="min-h-screen bg-brand-black text-white selection:bg-brand-green/30 overflow-x-hidden font-sans">

            {/* Navigation */}
            <nav className="fixed top-0 left-0 right-0 z-50 bg-brand-black/80 backdrop-blur-md border-b border-zinc-800">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex items-center justify-between h-20">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 bg-brand-green rounded-xl flex items-center justify-center shadow-lg shadow-brand-green/20">
                                <Building2 className="text-brand-black w-6 h-6" />
                            </div>
                            <div>
                                <span className="text-xl font-black tracking-tighter leading-none block">VANAKEL</span>
                                <span className="text-brand-green font-bold text-[10px] uppercase tracking-[0.3em] block">Group</span>
                            </div>
                        </div>

                        <div className="hidden md:flex items-center gap-8">
                            <a href="#features" className="text-sm font-bold text-zinc-400 hover:text-white transition-colors">{t.features}</a>
                            <a href="#workflow" className="text-sm font-bold text-zinc-400 hover:text-white transition-colors">{t.workflow}</a>
                            <a href="#portals" className="text-sm font-bold text-zinc-400 hover:text-white transition-colors">{t.portals}</a>

                            <div className="flex items-center gap-4 ml-4">
                                <div className="flex bg-zinc-900 rounded-lg p-1 border border-zinc-800">
                                    {['FR', 'EN', 'NL'].map(l => (
                                        <button
                                            key={l}
                                            onClick={() => setLang(l as Language)}
                                            className={`px-3 py-1 rounded-md text-[10px] font-black transition-all ${lang === l ? 'bg-brand-green text-brand-black' : 'text-zinc-500 hover:text-zinc-300'}`}
                                        >
                                            {l}
                                        </button>
                                    ))}
                                </div>
                                {role ? (
                                    <div className="flex items-center gap-4">
                                        <div className="hidden lg:flex flex-col items-end">
                                            <span className="text-[10px] font-black uppercase text-zinc-500 tracking-widest">{t.welcome || 'Welcome'}</span>
                                            <span className="text-xs font-bold text-white">{userName}</span>
                                        </div>
                                        <button
                                            onClick={() => navigate(getDashboardPath())}
                                            className="bg-brand-green text-brand-black px-5 py-2.5 rounded-full text-xs font-black uppercase tracking-widest hover:bg-brand-green-light transition-all shadow-lg shadow-brand-green/20 flex items-center gap-2 group"
                                        >
                                            <LayoutDashboard size={14} className="group-hover:rotate-12 transition-transform" /> {t.dashboard || 'Dashboard'}
                                        </button>
                                    </div>
                                ) : (

                                    <>
                                        <button onClick={() => setRoleSelectionMode('SIGNUP')} className="text-sm font-bold text-white hover:text-brand-green transition-colors">
                                            {t.get_started || 'Get Started'}
                                        </button>
                                        <button onClick={() => setRoleSelectionMode('LOGIN')} className="bg-white text-black px-5 py-2.5 rounded-full text-xs font-black uppercase tracking-widest hover:bg-zinc-200 transition-all">
                                            {t.login || 'Login'}
                                        </button>
                                    </>
                                )}

                            </div>
                        </div>

                        <button onClick={() => setIsMenuOpen(!isMenuOpen)} className="md:hidden text-zinc-400 hover:text-white">
                            {isMenuOpen ? <X /> : <Menu />}
                        </button>
                    </div>
                </div>

                {/* Mobile Menu */}
                {isMenuOpen && (
                    <div className="md:hidden bg-zinc-950 border-b border-zinc-800 p-4 space-y-4">
                        <a href="#features" className="block text-sm font-bold text-zinc-400 hover:text-white" onClick={() => setIsMenuOpen(false)}>{t.features}</a>
                        <a href="#workflow" className="block text-sm font-bold text-zinc-400 hover:text-white" onClick={() => setIsMenuOpen(false)}>{t.workflow}</a>
                        <div className="pt-4 border-t border-zinc-900 flex flex-col gap-3">
                            <div className="flex bg-zinc-900 rounded-lg p-1 border border-zinc-800 mb-2 justify-center">
                                {['FR', 'EN', 'NL'].map(l => (
                                    <button
                                        key={l}
                                        onClick={() => { setLang(l as Language); setIsMenuOpen(false); }}
                                        className={`px-4 py-2 rounded-md text-sm font-black transition-all flex-1 ${lang === l ? 'bg-brand-green text-brand-black shadow-sm' : 'text-zinc-500 hover:text-zinc-300'}`}
                                    >
                                        {l}
                                    </button>
                                ))}
                            </div>

                            {role ? (
                                <button
                                    onClick={() => { navigate(getDashboardPath()); setIsMenuOpen(false); }}
                                    className="w-full bg-brand-green text-brand-black px-5 py-3 rounded-xl text-xs font-black uppercase tracking-widest text-center flex items-center justify-center gap-2"
                                >
                                    <LayoutDashboard size={16} /> {t.dashboard || 'Dashboard'}
                                </button>
                            ) : (
                                <>
                                    <button onClick={() => setRoleSelectionMode('SIGNUP')} className="w-full text-left text-sm font-bold text-white hover:text-brand-green">{t.get_started || 'Get Started'}</button>
                                    <button onClick={() => setRoleSelectionMode('LOGIN')} className="w-full bg-white text-black px-5 py-3 rounded-xl text-xs font-black uppercase tracking-widest text-center">{t.login || 'Login'}</button>
                                </>
                            )}
                        </div>

                    </div>
                )}
            </nav>

            {/* Hero Section */}
            <section className="relative pt-32 pb-20 md:pt-48 md:pb-32 px-4 overflow-hidden">
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[500px] bg-brand-green/10 rounded-[100%] blur-[120px] -z-10 pointer-events-none"></div>

                <div className="max-w-5xl mx-auto text-center relative z-10">
                    <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-zinc-900/50 border border-zinc-800 text-brand-green text-[10px] font-black uppercase tracking-widest mb-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
                        <span className="w-2 h-2 rounded-full bg-brand-green"></span>
                        AI-Powered Building Management
                    </div>

                    <h1 className="text-5xl md:text-7xl lg:text-8xl font-black tracking-tighter text-white mb-8 leading-[0.9] animate-in fade-in slide-in-from-bottom-8 duration-700 delay-100">
                        {t.hero_title_1} <br />
                        <span className="text-transparent bg-clip-text bg-gradient-to-r from-brand-green to-emerald-600">{t.hero_title_2}</span>
                    </h1>

                    <p className="max-w-2xl mx-auto text-lg md:text-xl text-zinc-400 leading-relaxed mb-12 animate-in fade-in slide-in-from-bottom-8 duration-700 delay-200">
                        {t.hero_desc}
                    </p>

                    <div className="flex flex-col md:flex-row items-center justify-center gap-4 animate-in fade-in slide-in-from-bottom-8 duration-700 delay-300">
                        {role ? (
                            <button
                                onClick={() => navigate(getDashboardPath())}
                                className="group relative px-8 py-4 bg-brand-green text-brand-black rounded-full font-black text-sm uppercase tracking-widest hover:bg-brand-green-light transition-all shadow-[0_0_40px_-10px_rgba(34,197,94,0.3)] hover:shadow-[0_0_60px_-15px_rgba(34,197,94,0.5)] flex items-center gap-2"
                            >
                                {t.goToDashboard || 'Go to Dashboard'} <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                            </button>
                        ) : (
                            <button
                                onClick={() => setRoleSelectionMode('SIGNUP')}
                                className="group relative px-8 py-4 bg-brand-green text-brand-black rounded-full font-black text-sm uppercase tracking-widest hover:bg-brand-green-light transition-all shadow-[0_0_40px_-10px_rgba(34,197,94,0.3)] hover:shadow-[0_0_60px_-15px_rgba(34,197,94,0.5)] flex items-center gap-2"
                            >
                                {t.get_started} <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                            </button>
                        )}

                        <button
                            onClick={() => {
                                const el = document.getElementById('features');
                                el?.scrollIntoView({ behavior: 'smooth' });
                            }}
                            className="px-8 py-4 bg-zinc-900 text-white border border-zinc-800 rounded-full font-black text-sm uppercase tracking-widest hover:bg-zinc-800 transition-all"
                        >
                            {t.learn_more}
                        </button>
                    </div>
                </div>
            </section>

            {/* Admin Features */}
            <section id="features" className="py-24 bg-zinc-950 relative">
                <div className="max-w-7xl mx-auto px-4">
                    <div className="text-center mb-20">
                        <h2 className="text-3xl md:text-5xl font-black tracking-tight mb-6">{t.features_title}</h2>
                        <p className="text-zinc-400 max-w-2xl mx-auto">{t.features_subtitle}</p>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                        <FeatureCard
                            icon={<Mail className="text-brand-green" />}
                            title={t.feature_email_title}
                            desc={t.feature_email_desc}
                        />
                        <FeatureCard
                            icon={<Zap className="text-brand-green" />}
                            title={t.feature_mission_title}
                            desc={t.feature_mission_desc}
                        />
                        <FeatureCard
                            icon={<LayoutDashboard className="text-brand-green" />}
                            title={t.feature_dashboard_title}
                            desc={t.feature_dashboard_desc}
                        />
                        <FeatureCard
                            icon={<MapPin className="text-brand-green" />}
                            title={t.feature_map_title}
                            desc={t.feature_map_desc}
                        />
                        <FeatureCard
                            icon={<FileText className="text-brand-green" />}
                            title={t.feature_report_title}
                            desc={t.feature_report_desc}
                        />
                        <FeatureCard
                            icon={<BarChart3 className="text-brand-green" />}
                            title={t.feature_analytics_title}
                            desc={t.feature_analytics_desc}
                        />
                    </div>
                </div>
            </section>

            {/* Syndic Portal */}
            <section id="portals" className="py-24 bg-brand-black border-t border-zinc-900">
                <div className="max-w-7xl mx-auto px-4">
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
                        <div>
                            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-[10px] font-black uppercase tracking-widest mb-6">
                                <Briefcase size={12} /> Syndic Portal
                            </div>
                            <h2 className="text-3xl md:text-5xl font-black tracking-tight mb-6">{t.syndic_portal_title}</h2>
                            <p className="text-zinc-400 text-lg mb-8 leading-relaxed">
                                {t.syndic_portal_desc}
                            </p>

                            <ul className="space-y-4 mb-10">
                                <CheckItem text={t.syndic_check_1} />
                                <CheckItem text={t.syndic_check_2} />
                                <CheckItem text={t.syndic_check_3} />
                                <CheckItem text={t.syndic_check_4} />
                            </ul>

                            <button onClick={() => onSelect('SYNDIC')} className="px-8 py-4 bg-white text-black rounded-xl font-black text-xs uppercase tracking-widest hover:bg-zinc-200 transition-all flex items-center gap-2">
                                {t.access_portal} <ArrowRight size={16} />
                            </button>
                        </div>

                        <div className="relative">
                            <div className="absolute inset-0 bg-gradient-to-tr from-blue-500/20 to-purple-500/20 rounded-3xl blur-3xl -z-10"></div>
                            <div className="bg-zinc-900 border border-zinc-800 rounded-3xl p-8 shadow-2xl">
                                {/* Mock UI for Syndic Portal */}
                                <div className="flex justify-between items-center mb-8 border-b border-zinc-800 pb-4">
                                    <div>
                                        <h4 className="font-bold text-white">Syndic Dashboard</h4>
                                        <p className="text-xs text-zinc-500">Welcome, Immoweb Syndic</p>
                                    </div>
                                    <div className="w-8 h-8 rounded-full bg-zinc-800"></div>
                                </div>
                                <div className="space-y-4">
                                    <div className="bg-zinc-950 p-4 rounded-xl border border-zinc-800 flex justify-between items-center">
                                        <div>
                                            <p className="text-xs text-zinc-500 mb-1">Active Interventions</p>
                                            <p className="text-2xl font-black text-white">12</p>
                                        </div>
                                        <div className="p-3 bg-blue-500/10 rounded-lg text-blue-500"><LayoutDashboard size={20} /></div>
                                    </div>
                                    <div className="bg-zinc-950 p-4 rounded-xl border border-zinc-800 flex justify-between items-center">
                                        <div>
                                            <p className="text-xs text-zinc-500 mb-1">Pending Requests</p>
                                            <p className="text-2xl font-black text-white">5</p>
                                        </div>
                                        <div className="p-3 bg-orange-500/10 rounded-lg text-orange-500"><ClockIcon /></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {/* Workflow */}
            <section id="workflow" className="py-24 bg-zinc-950 border-t border-zinc-900">
                <div className="max-w-7xl mx-auto px-4">
                    <div className="text-center mb-20">
                        <h2 className="text-3xl md:text-5xl font-black tracking-tight mb-6">{t.workflow_title}</h2>
                        <p className="text-zinc-400">{t.workflow_subtitle}</p>
                    </div>

                    <div className="relative">
                        {/* Line Connector */}
                        <div className="hidden md:block absolute top-1/2 left-0 right-0 h-0.5 bg-zinc-800 -translate-y-1/2 z-0"></div>

                        <div className="grid grid-cols-2 md:grid-cols-6 gap-6 relative z-10">
                            <WorkflowStep num="01" title={t.wf_step_1_title} desc={t.wf_step_1_desc} />
                            <WorkflowStep num="02" title={t.wf_step_2_title} desc={t.wf_step_2_desc} />
                            <WorkflowStep num="03" title={t.wf_step_3_title} desc={t.wf_step_3_desc} />
                            <WorkflowStep num="04" title={t.wf_step_4_title} desc={t.wf_step_4_desc} />
                            <WorkflowStep num="05" title={t.wf_step_5_title} desc={t.wf_step_5_desc} />
                            <WorkflowStep num="06" title={t.wf_step_6_title} desc={t.wf_step_6_desc} />
                        </div>
                    </div>
                </div>
            </section>

            {/* Footer */}
            <footer className="py-12 bg-brand-black border-t border-zinc-900">
                <div className="max-w-7xl mx-auto px-4 flex flex-col md:flex-row justify-between items-center gap-8">
                    <div className="flex items-center gap-2">
                        <div className="w-8 h-8 bg-zinc-800 rounded-lg flex items-center justify-center">
                            <Building2 className="text-zinc-400 w-4 h-4" />
                        </div>
                        <span className="font-bold text-zinc-500 tracking-tight">VANAKEL GROUP</span>
                    </div>

                    <div className="flex gap-8 text-sm font-medium text-zinc-500">
                        <button onClick={() => onSelect('ADMIN')} className="hover:text-white transition-colors">Admin Login</button>
                        <button onClick={onSuperAdminLogin} className="hover:text-white transition-colors">{t.superAdmin}</button>
                    </div>

                    <p className="text-xs text-zinc-600">© 2024 Vanakel Group. All rights reserved.</p>
                </div>
            </footer>

            <RoleSelectionModal
                isOpen={!!roleSelectionMode}
                onClose={() => setRoleSelectionMode(null)}
                onSelect={handleRoleSelect}
                mode={roleSelectionMode || 'LOGIN'}
            />

        </div>
    );
};

// Sub-components
const FeatureCard = ({ icon, title, desc }: { icon: React.ReactNode, title: string, desc: string }) => (
    <div className="bg-zinc-900/50 border border-zinc-800 p-8 rounded-3xl hover:bg-zinc-900 hover:border-brand-green/30 transition-all group">
        <div className="w-12 h-12 bg-zinc-950 rounded-2xl flex items-center justify-center mb-6 border border-zinc-800 group-hover:scale-110 transition-transform duration-500">
            {icon}
        </div>
        <h3 className="text-xl font-bold text-white mb-3">{title}</h3>
        <p className="text-zinc-500 leading-relaxed text-sm">{desc}</p>
    </div>
);

const CheckItem = ({ text }: { text: string }) => (
    <li className="flex items-start gap-3">
        <CheckCircle2 size={18} className="text-brand-green shrink-0 mt-0.5" />
        <span className="text-zinc-300 font-medium">{text}</span>
    </li>
);

const WorkflowStep = ({ num, title, desc }: { num: string, title: string, desc: string }) => (
    <div className="bg-zinc-950 border border-zinc-800 p-6 rounded-2xl text-center hover:border-brand-green transition-colors group">
        <span className="text-xs font-black text-zinc-700 block mb-2 group-hover:text-brand-green transition-colors">{num}</span>
        <h4 className="font-bold text-white mb-1">{title}</h4>
        <p className="text-xs text-zinc-500">{desc}</p>
    </div>
);

const ClockIcon = () => (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="12" cy="12" r="10" />
        <polyline points="12 6 12 12 16 14" />
    </svg>
);

export default HomePage;

