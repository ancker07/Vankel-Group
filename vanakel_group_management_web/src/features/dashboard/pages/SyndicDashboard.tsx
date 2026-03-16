import React from 'react';
import { Intervention } from '@/types';
import { PenTool, Wrench, ChevronRight } from 'lucide-react';

interface SyndicDashboardProps {
    stats: any;
    allInterventions: Intervention[];
    chartData?: any[];
    onCreateIntervention: () => void;
    onSelectIntervention: (id: string) => void;
    onViewFullHistory: () => void;
    onRefresh: () => void;
    isRefreshing?: boolean;
    lang: string;
    t: any;
}

const SyndicDashboard: React.FC<SyndicDashboardProps> = ({
    allInterventions,
    onCreateIntervention,
    onSelectIntervention,
    onRefresh,
    isRefreshing,
    lang,
    t
}) => {
    const getLocalizedField = (obj: any, field: 'title' | 'description') => {
        if (lang === 'EN') return obj[`${field}_en`] || obj[field];
        if (lang === 'NL') return obj[`${field}_nl`] || obj[field];
        return obj[`${field}_fr`] || obj[field];
    };

    return (
        <div className="space-y-6 md:space-y-8 animate-in fade-in duration-500 max-w-4xl mx-auto pb-12 px-4 md:px-0">
            <div className="flex justify-between items-end mb-4">
                <div>
                    <h1 className="text-2xl md:text-3xl font-black text-white uppercase tracking-tight">{t.syndic_portal || 'Syndic Portal'}</h1>
                </div>
                <div className="flex gap-2">
                    <button
                        onClick={onRefresh}
                        disabled={isRefreshing}
                        className={`p-2 bg-zinc-900 border border-zinc-800 text-zinc-400 hover:text-white rounded-xl transition-all ${isRefreshing ? 'opacity-50 cursor-wait' : 'hover:border-zinc-700'}`}
                        title="Refresh"
                    >
                        <svg className={`w-5 h-5 ${isRefreshing ? 'animate-spin text-brand-green' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                        </svg>
                    </button>
                    <button
                        onClick={onCreateIntervention}
                        className="p-2 bg-brand-green/10 text-brand-green hover:bg-brand-green hover:text-black rounded-xl transition-all"
                    >
                        <PenTool size={20} />
                    </button>
                </div>
            </div>

            {/* Banner Section */}
            <div className="p-6 md:p-8 rounded-2xl border border-brand-green/30 bg-gradient-to-br from-brand-green/20 to-brand-black shadow-lg shadow-brand-green/5 flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
                <div className="space-y-2 flex-1">
                    <h2 className="text-lg md:text-xl font-bold text-white">
                        {t.needIntervention || 'Need an intervention?'}
                    </h2>
                    <p className="text-sm text-zinc-300 max-w-lg leading-relaxed">
                        {t.createRequestDesc || 'Create a request in seconds and follow its progress in real time.'}
                    </p>
                </div>
                <button
                    onClick={onCreateIntervention}
                    className="shrink-0 bg-brand-green text-brand-black px-6 py-3 rounded-xl font-black text-sm uppercase tracking-widest hover:bg-brand-green-light hover:scale-105 active:scale-95 transition-all w-full md:w-auto text-center"
                >
                    {t.request || 'Request'}
                </button>
            </div>

            {/* Interventions Section */}
            <div className="mt-8 space-y-4">
                <h3 className="text-xl font-bold text-white">{t.my_interventions || 'My Interventions'}</h3>

                <div className="space-y-3">
                    {allInterventions.length === 0 ? (
                        <p className="text-center py-8 text-zinc-600 font-medium">{t.no_interventions_found || 'No interventions found.'}</p>
                    ) : (
                        allInterventions.map((int) => (
                            <div
                                key={int.id}
                                onClick={() => onSelectIntervention(int.id)}
                                className="p-4 bg-zinc-950 border border-zinc-800 rounded-xl hover:border-brand-green/30 transition-colors flex items-center justify-between cursor-pointer group"
                            >
                                <div className="flex items-center gap-4 min-w-0">
                                    <div className="p-2 md:p-3 bg-zinc-900 rounded-lg shrink-0">
                                        <Wrench size={20} className="text-zinc-500 group-hover:text-brand-green transition-colors" />
                                    </div>
                                    <div className="min-w-0 flex-1">
                                        <h4 className="font-bold text-white text-sm md:text-base truncate leading-tight">{getLocalizedField(int, 'title')}</h4>
                                        <div className="flex items-center gap-2 mt-1">
                                            <span className="text-[10px] md:text-xs text-zinc-500 font-mono truncate max-w-[150px] md:max-w-none">
                                                {new Date(int.createdAt || int.scheduledDate || '').toLocaleDateString()}
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                <div className="flex items-center gap-4 shrink-0 pl-2">
                                    <div className={`px-2 md:px-3 py-1 bg-brand-green/10 border border-brand-green/20 rounded-lg hidden sm:block ${int.status === 'COMPLETED' ? 'bg-green-500/10 border-green-500/20 text-green-500' :
                                        int.status === 'DELAYED' ? 'bg-orange-500/10 border-orange-500/20 text-orange-500' :
                                            'bg-blue-500/10 border-blue-500/20 text-brand-green'
                                        }`}>
                                        <span className="text-[9px] md:text-[10px] font-black uppercase tracking-wider">
                                            {int.status}
                                        </span>
                                    </div>
                                    <ChevronRight size={18} className="text-zinc-600 group-hover:text-brand-green transition-colors" />
                                </div>
                            </div>
                        ))
                    )}
                </div>
            </div>
        </div>
    );
};

export default SyndicDashboard;
