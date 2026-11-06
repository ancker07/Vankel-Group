import React from 'react';
import { ShieldCheck } from 'lucide-react';

/** Blue badge shown on every task / intervention that is assigned to an admin (the admin does it themselves). */
const AdminBadge: React.FC<{ show?: boolean; label: string; className?: string }> = ({ show, label, className = '' }) => {
    if (!show) return null;
    return (
        <span
            title={label}
            className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-sky-950/85 border border-sky-400/60 text-sky-300 text-[9px] font-black uppercase tracking-widest whitespace-nowrap shrink-0 ${className}`}
        >
            <ShieldCheck size={11} /> {label}
        </span>
    );
};

export default AdminBadge;
