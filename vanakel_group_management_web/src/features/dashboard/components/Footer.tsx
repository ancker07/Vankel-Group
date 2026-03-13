import React from 'react';
import { Globe, Mail, Phone, MapPin, Linkedin, Facebook, ArrowUpRight, Shield, MessageSquare, Briefcase, Zap, FileText } from 'lucide-react';
import logo from '@/assets/vankel_bg_2.png';

interface FooterProps {
    t: any;
}

const Footer: React.FC<FooterProps> = ({ t }) => {
    const currentYear = new Date().getFullYear();

    const scrollToSection = (id: string) => {
        const el = document.getElementById(id);
        if (el) {
            el.scrollIntoView({ behavior: 'smooth' });
        } else {
            window.location.href = `/#${id}`;
        }
    };

    return (
        <footer className="relative bg-zinc-950 pt-24 pb-12 border-t border-zinc-900 overflow-hidden">
            {/* Background Accent */}
            <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-[800px] h-[300px] bg-brand-green/5 rounded-[100%] blur-[120px] -z-10 pointer-events-none"></div>

            <div className="max-w-7xl mx-auto px-4 relative z-10">
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12 mb-20">
                    
                    {/* Brand Section */}
                    <div className="space-y-8">
                        <img src={logo} alt="Vankel Logo" className="h-12 w-auto object-contain grayscale opacity-80 hover:grayscale-0 transition-all duration-500" />
                        <p className="text-zinc-500 text-sm leading-relaxed max-w-xs">
                           {t.hero_desc || 'AI-powered building management ecosystem designed for the next generation of property management.'}
                        </p>
                        {/* <div className="flex gap-3">
                            <SocialIcon icon={<Linkedin size={18} />} href="#" />
                            <SocialIcon icon={<Facebook size={18} />} href="#" />
                            <SocialIcon icon={<Globe size={18} />} href="https://vanakelgroup.be" />
                        </div> */}
                    </div>

                    {/* Navigation */}
                    <div>
                        <h4 className="text-white font-black uppercase tracking-widest text-[10px] mb-8 flex items-center gap-2">
                             Navigation
                        </h4>
                        <ul className="space-y-4">
                            <FooterLink onClick={() => scrollToSection('features')} label={t.features} icon={<Zap size={14}/>} />
                            <FooterLink onClick={() => scrollToSection('workflow')} label={t.workflow} icon={<ArrowUpRight size={14}/>} />
                            <FooterLink onClick={() => scrollToSection('portals')} label={t.portals} icon={<Briefcase size={14}/>} />
                            <FooterLink onClick={() => scrollToSection('contact')} label={t.contact_us} icon={<MessageSquare size={14}/>} />
                        </ul>
                    </div>

                    {/* Company */}
                    <div>
                        <h4 className="text-white font-black uppercase tracking-widest text-[10px] mb-8 flex items-center gap-2">
                            {t.footer_company}
                        </h4>
                        <ul className="space-y-4">
                            <FooterLink href="#" label={t.footer_about} />
                            <FooterLink href="#" label={t.footer_careers} />
                            <FooterLink href="#" label={t.footer_privacy} />
                            <FooterLink href="#" label={t.footer_terms} />
                        </ul>
                    </div>

                    {/* Contact & Support */}
                    <div className="space-y-6">
                        <h4 className="text-white font-black uppercase tracking-widest text-[10px] mb-8">
                            {t.footer_contact}
                        </h4>
                        <div className="space-y-4">
                            <div className="flex items-center gap-3 text-zinc-500 text-sm group cursor-pointer hover:text-white transition-colors">
                                <div className="w-8 h-8 rounded-lg bg-zinc-900 flex items-center justify-center border border-zinc-800 text-brand-green">
                                    <Mail size={14} />
                                </div>
                                <span className="font-medium">info@vanakelgroup.be</span>
                            </div>
                            <div className="flex items-center gap-3 text-zinc-500 text-sm group cursor-pointer hover:text-white transition-colors">
                                <div className="w-8 h-8 rounded-lg bg-zinc-900 flex items-center justify-center border border-zinc-800 text-brand-green">
                                    <Phone size={14} />
                                </div>
                                <span className="font-medium">+32 475 99 99 09</span>
                            </div>
                            <div className="flex items-start gap-3 text-zinc-500 text-sm group cursor-pointer hover:text-white transition-colors">
                                <div className="w-8 h-8 rounded-lg bg-zinc-900 flex items-center justify-center border border-zinc-800 text-brand-green shrink-0">
                                    <MapPin size={14} />
                                </div>
                                <span className="font-medium leading-relaxed">Excelsiorlaan 36-38,1930 Zaventem</span>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Bottom Bar */}
                <div className="pt-12 border-t border-zinc-900/50 flex flex-col md:flex-row justify-between items-center gap-6">
                    <div className="text-zinc-600 text-[10px] font-black uppercase tracking-[0.2em]">
                        © {currentYear} VANAKEL GROUP — {t.footer_all_rights || 'ALL RIGHTS RESERVED.'}
                    </div>

                    <div className="flex items-center gap-2 text-zinc-600 text-[10px] font-black uppercase tracking-widest">
                        <span className="opacity-50">{t.footer_made_by || 'DESIGNED BY'}</span>
                        <a 
                            href="https://codysterie.be/" 
                            target="_blank" 
                            rel="noopener noreferrer"
                            className="bg-brand-green/10 text-brand-green px-2 py-1 rounded hover:bg-brand-green hover:text-brand-black transition-all flex items-center gap-1 border border-brand-green/20"
                        >
                            CODYSTERIE
                        </a>
                    </div>
                </div>
            </div>
        </footer>
    );
};

const FooterLink = ({ href, onClick, label, icon }: { href?: string; onClick?: () => void; label: string; icon?: React.ReactNode }) => (
    <li>
        {href ? (
            <a 
                href={href} 
                className="text-zinc-500 hover:text-brand-green text-sm transition-all flex items-center gap-3 group"
            >
                {icon && <span className="opacity-0 group-hover:opacity-100 -ml-5 group-hover:ml-0 transition-all text-brand-green">{icon}</span>}
                {label}
            </a>
        ) : (
            <button 
                onClick={onClick}
                className="text-zinc-500 hover:text-brand-green text-sm transition-all flex items-center gap-3 group text-left"
            >
                {icon && <span className="opacity-0 group-hover:opacity-100 -ml-5 group-hover:ml-0 transition-all text-brand-green">{icon}</span>}
                {label}
            </button>
        )}
    </li>
);

const SocialIcon = ({ icon, href }: { icon: React.ReactNode; href: string }) => (
    <a 
        href={href}
        className="w-10 h-10 rounded-xl bg-zinc-900 border border-zinc-800 flex items-center justify-center text-zinc-500 hover:text-white hover:border-brand-green hover:bg-brand-green/5 transition-all duration-300"
    >
        {icon}
    </a>
);

export default Footer;