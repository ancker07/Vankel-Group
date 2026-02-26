
import React from 'react';
import { Clock, CheckCircle2, AlertCircle, Calendar, PauseCircle } from 'lucide-react';
import { Language } from '@/types';

interface StatsProps {
  stats: {
    missions: number;
    ongoing: number;
    delayed: number;
    completed: number;
  };
  t: any;
  onCardClick: (type: 'MISSIONS' | 'ONGOING' | 'DELAYED' | 'COMPLETED') => void;
}

const DashboardStats: React.FC<StatsProps> = ({ stats, t, onCardClick }) => {
  return (
    <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 md:gap-4">
      <StatCard
        label={t.kpi_missions}
        value={stats.missions}
        icon={<Calendar size={18} className="text-blue-400 md:size-[20px]" />}
        color="border-blue-500/20"
        liveText={t.live}
        onClick={() => onCardClick('MISSIONS')}
      />
      <StatCard
        label={t.kpi_ongoing}
        value={stats.ongoing}
        icon={<Clock size={18} className="text-brand-green md:size-[20px]" />}
        color="border-brand-green/20"
        liveText={t.live}
        onClick={() => onCardClick('ONGOING')}
      />
      {/* DELAYED - Now Orange */}
      <StatCard
        label={t.kpi_delayed}
        value={stats.delayed}
        icon={<AlertCircle size={18} className="text-orange-500 md:size-[20px]" />}
        color="border-orange-500/20"
        liveText={t.live}
        onClick={() => onCardClick('DELAYED')}
      />
      <StatCard
        label={t.kpi_completed}
        value={stats.completed}
        icon={<CheckCircle2 size={18} className="text-green-400 md:size-[20px]" />}
        color="border-green-500/20"
        liveText={t.live}
        onClick={() => onCardClick('COMPLETED')}
      />
    </div>
  );
};

const StatCard: React.FC<{ label: string; value: number; icon: React.ReactNode; color: string; liveText: string; onClick: () => void }> = ({ label, value, icon, color, liveText, onClick }) => (
  <div
    onClick={onClick}
    className={`bg-zinc-950 p-4 rounded-xl md:rounded-2xl border ${color} shadow-lg transition-all hover:scale-[1.02] cursor-pointer hover:bg-zinc-900 group`}
  >
    <div className="flex items-center justify-between mb-1.5 md:mb-2">
      <div className="p-1.5 md:p-2 bg-zinc-900 rounded-lg group-hover:bg-zinc-800 transition-colors">{icon}</div>
      <span className="text-[7px] md:text-[9px] font-black text-zinc-700 uppercase tracking-widest">{liveText}</span>
    </div>
    <p className="text-zinc-600 text-[8px] md:text-[10px] font-black uppercase tracking-wider mb-1 truncate">{label}</p>
    <h4 className="text-xl md:text-3xl font-black">{value}</h4>
  </div>
);

export default DashboardStats;
