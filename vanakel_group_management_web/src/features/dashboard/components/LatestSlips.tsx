
import React from 'react';
import { Intervention } from '@/types';
import { URGENCY } from '@/utils/constants';


interface LatestSlipsProps {
    interventions: Intervention[];
    onSelect: (id: string) => void;
    viewAll: () => void;
    t: any;
    className?: string;
    hideTitle?: boolean;
}


const LatestSlips: React.FC<LatestSlipsProps> = ({ interventions, onSelect, viewAll, t, className, hideTitle }) => {
    return (
        <div className={`bg-zinc-950 border border-zinc-800 rounded-2xl p-4 md:p-6 flex flex-col ${className}`}>
            {!hideTitle && <h3 className="font-bold text-white mb-4">{t.latest_slips}</h3>}

            <div className="flex-1 overflow-y-auto space-y-3 pr-2 custom-scrollbar">
                {interventions.slice(0, 5).map(int => (
                    <div
                        key={int.id}
                        onClick={() => onSelect(int.id)}
                        className="p-3 bg-zinc-900/50 rounded-xl hover:bg-zinc-900 transition-colors cursor-pointer border border-transparent hover:border-zinc-800"
                    >
                        <div className="flex justify-between items-start">
                            <p className="text-xs font-bold text-white truncate w-32">{int.title}{int.interventionNumber ? ` – ${int.interventionNumber}` : ''}</p>
                            <span className={`text-[8px] px-1.5 py-0.5 rounded font-black uppercase ${int.status === 'COMPLETED' ? 'bg-green-500/10 text-green-500' : 'bg-zinc-800 text-zinc-500'}`}>{int.status}</span>
                        </div>
                        <div className="flex justify-between items-center mt-1">
                            <p className="text-[10px] text-zinc-500">{new Date(int.scheduledDate).toLocaleDateString()}</p>
                            {int.urgency && (
                                <div className="flex items-center gap-1.5">
                                    <div className={`w-1.5 h-1.5 rounded-full ${URGENCY.find(u => u.id === int.urgency)?.color.replace('text-', 'bg-') || 'bg-zinc-600'}`} />
                                    <span className={`text-[8px] font-black uppercase ${URGENCY.find(u => u.id === int.urgency)?.color || 'text-zinc-500'}`}>
                                        {int.urgency}
                                    </span>
                                </div>
                            )}
                        </div>

                    </div>
                ))}
            </div>
            <button
                onClick={viewAll}
                className="mt-4 w-full py-2 text-xs font-black uppercase text-zinc-500 hover:text-white border border-zinc-800 rounded-lg hover:bg-zinc-900 transition-all"
            >
                {t.view} {t.full_history}
            </button>
        </div>
    );
};

export default LatestSlips;
