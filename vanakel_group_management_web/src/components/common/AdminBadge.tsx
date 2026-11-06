import React from 'react';
import { ShieldCheck } from 'lucide-react';

/**
 * Blue badge shown on every task / intervention that is assigned to an admin (the admin does it themselves).
 * `large` is a full-width banner, used inside cards and details (never on top of a map).
 */
const AdminBadge: React.FC<{ show?: boolean; label: string; className?: string; large?: boolean }> = ({ show, label, className = '', large }) => {
    if (!show) return null;
    if (large) {
        return (
            <div
                title={label}
                className={`flex items-center justify-center gap-2 w-full px-4 py-2.5 rounded-xl bg-sky-500 text-white text-xs md:text-sm font-black uppercase tracking-widest shadow-lg shadow-sky-500/20 ${className}`}
            >
                <ShieldCheck size={18} /> {label}
            </div>
        );
    }
    return (
        <span
            title={label}
            className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-sky-500 text-white text-[10px] font-black uppercase tracking-widest whitespace-nowrap shrink-0 ${className}`}
        >
            <ShieldCheck size={14} /> {label}
        </span>
    );
};

export default AdminBadge;
