
import React from 'react';
import { ShieldCheck, HardHat, Building2, User, ChevronRight, Briefcase } from 'lucide-react';
import { Role, Language } from '@/types';
import { TRANSLATIONS } from '@/utils/constants';

interface LandingPageProps {
  onSelect: (role: Role) => void;
  lang: Language;
  setLang: (l: Language) => void;
  onSignup: () => void;
  onSuperAdminLogin: () => void;
}

const LandingPage: React.FC<LandingPageProps> = ({ onSelect, lang, setLang, onSignup, onSuperAdminLogin }) => {
  const t = TRANSLATIONS[lang];

  return (
    <div className="min-h-[100dvh] bg-brand-black flex flex-col items-center justify-center p-4 md:p-6 relative overflow-hidden">
      {/* Decorative Blur BG */}
      <div className="absolute top-[-5%] left-[-5%] w-[60%] h-[60%] bg-brand-green/5 rounded-full blur-[80px] md:blur-[120px]"></div>
      <div className="absolute bottom-[-5%] right-[-5%] w-[60%] h-[60%] bg-brand-green/5 rounded-full blur-[80px] md:blur-[120px]"></div>

      <div className="z-10 text-center mb-8 md:mb-16 max-w-2xl px-2">
        <div className="inline-flex items-center gap-3 mb-4 md:mb-6">
          <div className="w-10 h-10 md:w-14 md:h-14 bg-brand-green rounded-xl md:rounded-2xl flex items-center justify-center shadow-2xl shadow-brand-green/20">
            <Building2 className="text-brand-black w-6 h-6 md:w-8 md:h-8" />
          </div>
          <div className="text-left">
            <h1 className="text-2xl md:text-4xl font-black tracking-tighter leading-none text-white">VANAKEL</h1>
            <p className="text-brand-green font-bold text-[8px] md:text-xs uppercase tracking-[0.3em] mt-1">{t.groupMgmt}</p>
          </div>
        </div>
        <p className="text-zinc-400 text-sm md:text-lg leading-relaxed">
          {t.ecosystemDesc}
        </p>
      </div>

      <div className="z-10 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4 md:gap-6 w-full max-w-6xl">
        <button
          onClick={() => onSelect('PROFESSIONAL')}
          className="group relative bg-zinc-950 border border-zinc-900 p-6 md:p-8 rounded-2xl md:rounded-[2rem] text-left hover:border-brand-green/50 hover:bg-zinc-900/50 transition-all duration-500 overflow-hidden min-h-[160px]"
        >
          <div className="w-10 h-10 md:w-12 md:h-12 bg-zinc-900 rounded-xl flex items-center justify-center mb-4 md:mb-6 border border-zinc-800 group-hover:bg-brand-green group-hover:text-brand-black transition-all">
            <HardHat className="w-5 h-5 md:w-6 md:h-6" />
          </div>
          <h3 className="text-lg md:text-xl font-bold mb-1 md:mb-2 flex items-center gap-2 text-white group-hover:text-brand-green transition-colors">
            {t.proSelection} <ChevronRight size={16} className="group-hover:translate-x-1 transition-transform" />
          </h3>
          <p className="text-zinc-600 group-hover:text-zinc-400 transition-colors text-xs md:text-sm leading-relaxed">
            {t.proSub}
          </p>
        </button>

        <button
          onClick={() => onSelect('SYNDIC')}
          className="group relative bg-zinc-950 border border-zinc-900 p-6 md:p-8 rounded-2xl md:rounded-[2rem] text-left hover:border-brand-green/50 hover:bg-zinc-900/50 transition-all duration-500 overflow-hidden min-h-[160px]"
        >
          <div className="w-10 h-10 md:w-12 md:h-12 bg-zinc-900 rounded-xl flex items-center justify-center mb-4 md:mb-6 border border-zinc-800 group-hover:bg-brand-green group-hover:text-brand-black transition-all">
            <Briefcase className="w-5 h-5 md:w-6 md:h-6" />
          </div>
          <h3 className="text-lg md:text-xl font-bold mb-1 md:mb-2 flex items-center gap-2 text-white group-hover:text-brand-green transition-colors">
            {t.syndicSelection} <ChevronRight size={16} className="group-hover:translate-x-1 transition-transform" />
          </h3>
          <p className="text-zinc-600 group-hover:text-zinc-400 transition-colors text-xs md:text-sm leading-relaxed">
            {t.syndicSub}
          </p>
        </button>

        <button
          onClick={() => onSelect('CLIENT')}
          className="group relative bg-zinc-950 border border-zinc-900 p-6 md:p-8 rounded-2xl md:rounded-[2rem] text-left hover:border-brand-green/50 hover:bg-zinc-900/50 transition-all duration-500 overflow-hidden md:col-span-2 xl:col-span-1 min-h-[160px]"
        >
          <div className="w-10 h-10 md:w-12 md:h-12 bg-zinc-900 rounded-xl flex items-center justify-center mb-4 md:mb-6 border border-zinc-800 group-hover:bg-brand-green group-hover:text-brand-black transition-all">
            <User className="w-5 h-5 md:w-6 md:h-6" />
          </div>
          <h3 className="text-lg md:text-xl font-bold mb-1 md:mb-2 flex items-center gap-2 text-white group-hover:text-brand-green transition-colors">
            {t.clientSelection} <ChevronRight size={16} className="group-hover:translate-x-1 transition-transform" />
          </h3>
          <p className="text-zinc-600 group-hover:text-zinc-400 transition-colors text-xs md:text-sm leading-relaxed">
            {t.clientSub}
          </p>
        </button>
      </div>

      <div className="mt-8 md:mt-12 z-10 flex flex-col items-center gap-4 md:gap-6">
        <div className="flex gap-4">
          <button
            onClick={() => onSelect('ADMIN')}
            className="bg-zinc-900 border border-zinc-800 text-zinc-600 px-5 py-2 rounded-full text-[10px] md:text-sm font-black uppercase tracking-widest hover:bg-zinc-800 hover:text-brand-green transition-all min-h-[44px]"
          >
            {t.adminEntry} (Dev Mode)
          </button>

          <button
            onClick={onSuperAdminLogin}
            className="bg-zinc-900 border border-zinc-800 text-zinc-600 px-5 py-2 rounded-full text-[10px] md:text-sm font-black uppercase tracking-widest hover:bg-zinc-800 hover:text-brand-green transition-all min-h-[44px]"
          >
            {t.superAdmin} Portal
          </button>
        </div>

        <button
          onClick={onSignup}
          className="text-brand-green font-black uppercase tracking-widest text-[10px] md:text-xs hover:underline decoration-2 underline-offset-8"
        >
          {t.signup}
        </button>

        <div className="flex gap-4">
          {['FR', 'EN', 'NL'].map(l => (
            <button
              key={l}
              onClick={() => setLang(l as Language)}
              className={`text-xs font-black tracking-[0.2em] transition-all p-2 ${lang === l ? 'text-brand-green border-b-2 border-brand-green' : 'text-zinc-700 hover:text-zinc-500'}`}
            >
              {l}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};

export default LandingPage;
