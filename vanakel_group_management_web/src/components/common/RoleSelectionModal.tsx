import React from 'react';
import { Building2, ShieldCheck, Hammer, X, ArrowRight, UserCog } from 'lucide-react';
import { Role } from '@/types';

interface RoleSelectionModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSelect: (role: Role) => void;
    mode: 'LOGIN' | 'SIGNUP';
}

const RoleSelectionModal: React.FC<RoleSelectionModalProps> = ({ isOpen, onClose, onSelect, mode }) => {
    if (!isOpen) return null;

    const roles = [
        {
            id: 'SYNDIC' as Role,
            label: 'Property Manager',
            subLabel: 'For Syndics & Agencies',
            icon: <Building2 size={24} />,
            color: 'bg-blue-500',
            textColor: 'text-blue-500',
            borderColor: 'border-blue-500/20',
            hoverBg: 'hover:bg-blue-500/10'
        },
        {
            id: 'ADMIN' as Role,
            label: 'Administrator',
            subLabel: 'Platform Management',
            icon: <ShieldCheck size={24} />,
            color: 'bg-brand-green',
            textColor: 'text-brand-green',
            borderColor: 'border-brand-green/20',
            hoverBg: 'hover:bg-brand-green/10'
        }
    ];

    // Standard roles for portal access.

    return (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
            <div
                className="relative w-full max-w-lg bg-zinc-950 border border-zinc-800 rounded-3xl p-8 shadow-2xl shadow-black/50 animate-in zoom-in-95 slide-in-from-bottom-4 duration-300"
                onClick={(e) => e.stopPropagation()}
            >
                <button
                    onClick={onClose}
                    className="absolute top-4 right-4 p-2 rounded-full hover:bg-zinc-900 text-zinc-500 hover:text-white transition-colors"
                >
                    <X size={20} />
                </button>

                <div className="text-center mb-8">
                    <h2 className="text-2xl font-black text-white uppercase tracking-tight mb-2">
                        {mode === 'LOGIN' ? 'Welcome Back' : 'Get Started'}
                    </h2>
                    <p className="text-zinc-500 font-medium">
                        {mode === 'LOGIN'
                            ? 'Select your portal to continue'
                            : 'Choose your account type to register'}
                    </p>
                </div>

                <div className="space-y-3">
                    {roles.map((role) => (
                        <button
                            key={role.id}
                            onClick={() => onSelect(role.id)}
                            className={`w-full group flex items-center gap-4 p-4 rounded-2xl border border-zinc-900 bg-zinc-900/30 ${role.hoverBg} hover:border-zinc-700 transition-all duration-300`}
                        >
                            <div className={`w-12 h-12 rounded-xl bg-zinc-900 border ${role.borderColor} flex items-center justify-center ${role.textColor} group-hover:scale-110 transition-transform`}>
                                {role.icon}
                            </div>
                            <div className="flex-1 text-left">
                                <h3 className="font-bold text-white group-hover:text-white transition-colors">
                                    {role.label}
                                </h3>
                                <p className="text-xs text-zinc-500 font-medium group-hover:text-zinc-400">
                                    {role.subLabel}
                                </p>
                            </div>
                            <div className="text-zinc-600 group-hover:text-white transition-colors">
                                <ArrowRight size={18} />
                            </div>
                        </button>
                    ))}

                    {mode === 'LOGIN' && (
                        <button
                            onClick={() => onSelect('SUPERADMIN' as Role)}
                            className="w-full mt-4 py-2 text-xs font-bold text-zinc-600 hover:text-zinc-400 uppercase tracking-widest transition-colors"
                        >
                            Super Admin Access
                        </button>
                    )}
                </div>
            </div>
        </div>
    );
};

export default RoleSelectionModal;
