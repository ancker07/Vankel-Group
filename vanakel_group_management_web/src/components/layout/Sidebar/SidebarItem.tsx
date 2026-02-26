
import React from 'react';

interface SidebarItemProps {
  icon: React.ReactNode;
  label: string;
  active?: boolean;
  onClick: () => void;
  badge?: number;
}

const SidebarItem: React.FC<SidebarItemProps> = ({ icon, label, active, onClick, badge }) => (
  <button
    onClick={onClick}
    className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all group ${active ? 'bg-brand-green/10 text-brand-green font-semibold border-l-4 border-brand-green' : 'text-zinc-400 hover:bg-zinc-900 hover:text-zinc-200'}`}
  >
    <span className={`${active ? 'text-brand-green' : 'text-zinc-500 group-hover:text-zinc-300'}`}>{icon}</span>
    <span className="flex-1 text-left">{label}</span>
    {badge && badge > 0 && (
      <span className="bg-brand-green text-brand-black text-[10px] font-bold px-1.5 py-0.5 rounded-full">
        {badge}
      </span>
    )}
  </button>
);

export default SidebarItem;
