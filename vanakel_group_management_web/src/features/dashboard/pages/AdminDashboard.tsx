
import React from 'react';
import { Plus } from 'lucide-react';
import DashboardStats from '../components/DashboardStats';
import ActivityChart from '../components/ActivityChart';
import LatestSlips from '../components/LatestSlips';
import { Intervention } from '@/types';

interface AdminDashboardProps {
    stats: any;
    chartData: any[];
    showCompare: boolean;
    setShowCompare: (show: boolean) => void;
    allInterventions: Intervention[];
    onStatClick: (type: any) => void;
    onCreateIntervention: () => void;
    onSelectIntervention: (id: string) => void;
    onViewFullHistory: () => void;
    lang: string;
    t: any;
}

const AdminDashboard: React.FC<AdminDashboardProps> = ({
    stats,
    chartData,
    showCompare,
    setShowCompare,
    allInterventions,
    onStatClick,
    onCreateIntervention,
    onSelectIntervention,
    onViewFullHistory,
    lang,
    t
}) => {
    return (
        <div className="space-y-6 md:space-y-8 animate-in fade-in duration-500 max-w-7xl mx-auto">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4">
                <div>
                    <h1 className="text-2xl md:text-3xl font-black text-white">{t.dashboard}</h1>
                    <p className="text-zinc-500 text-sm mt-1">{t.g_dash_stats}</p>
                </div>
                <button
                    id="btn-create-intervention"
                    onClick={onCreateIntervention}
                    className="bg-brand-green text-brand-black px-4 md:px-6 py-3 rounded-xl font-black text-xs uppercase tracking-widest hover:bg-brand-green-light transition-all shadow-lg shadow-brand-green/20 flex items-center gap-2"
                >
                    <Plus size={16} strokeWidth={3} /> {t.createIntervention}
                </button>
            </div>

            <div id="dash-stats">
                <DashboardStats stats={stats} t={t} onCardClick={onStatClick} />
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 md:gap-8">
                <ActivityChart
                    data={chartData}
                    showCompare={showCompare}
                    setShowCompare={setShowCompare}
                    lang={lang}
                    t={t}
                />
                <LatestSlips
                    interventions={allInterventions}
                    onSelect={onSelectIntervention}
                    viewAll={onViewFullHistory}
                    t={t}
                />
            </div>
        </div>
    );
};

export default AdminDashboard;
