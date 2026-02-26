
import React from 'react';
import { RotateCcw, Plus, MapPin, ShieldCheck, Trash2 } from 'lucide-react';
import { MaintenancePlan, Building, Syndic } from '@/types';

interface MaintenancePageProps {
    maintenancePlans: MaintenancePlan[];
    buildings: Building[];
    syndics: Syndic[];
    onCreateClick: (buildingId?: string) => void;
    onDeleteClick: (id: string) => void;
    t: any;
}

const MaintenancePage: React.FC<MaintenancePageProps> = ({ maintenancePlans, buildings, syndics, onCreateClick, onDeleteClick, t }) => {
    return (
        <div className="space-y-6 animate-in fade-in duration-500 max-w-5xl mx-auto pb-12">
            <div className="flex justify-between items-center">
                <h2 className="text-2xl font-black text-white uppercase tracking-tight flex items-center gap-2">
                    <RotateCcw className="text-orange-500" /> {t.maintenance || 'Entretien'}
                </h2>
                <button
                    onClick={() => onCreateClick()}
                    className="bg-zinc-900 text-white px-4 py-2 rounded-xl text-xs font-bold hover:bg-zinc-800 transition-all border border-zinc-800 flex items-center gap-2"
                >
                    <Plus size={14} /> {t.create || 'Create'}
                </button>
            </div>

            {maintenancePlans.length === 0 ? (
                <div className="p-12 text-center border border-dashed border-zinc-800 rounded-2xl bg-zinc-900/20">
                    <RotateCcw size={48} className="mx-auto text-zinc-700 mb-4" />
                    <p className="text-zinc-500 font-medium">No maintenance plans.</p>
                </div>
            ) : (
                <div className="space-y-4">
                    {maintenancePlans.map(mp => {
                        const b = buildings.find(build => build.id === mp.buildingId);
                        const s = syndics.find(syn => syn.id === b?.linkedSyndicId);

                        return (
                            <div key={mp.id} className="bg-zinc-950 border border-orange-500/20 p-5 rounded-2xl flex flex-col md:flex-row gap-6 shadow-lg shadow-orange-500/5">
                                <div className="flex-1">
                                    <div className="flex items-center gap-2 mb-2">
                                        <span className="px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider bg-orange-500/10 text-orange-500 border border-orange-500/20">
                                            {mp.recurrence.frequency}
                                        </span>
                                        <span className="text-[10px] text-zinc-500 font-mono">Next: {new Date(mp.recurrence.startDate).toLocaleDateString()}</span>
                                    </div>
                                    <h4 className="text-lg font-bold text-white mb-2">{mp.title}</h4>
                                    <p className="text-sm text-zinc-400 leading-relaxed mb-4">{mp.description || 'Routine maintenance plan.'}</p>

                                    <div className="flex flex-wrap gap-4 text-xs text-zinc-500">
                                        <div className="flex items-center gap-1.5">
                                            <MapPin size={12} className="text-zinc-600" />
                                            <span>{b?.address}</span>
                                        </div>
                                        <div className="flex items-center gap-1.5">
                                            <ShieldCheck size={12} className="text-zinc-600" />
                                            <span>{s?.companyName || 'No Syndic'}</span>
                                        </div>
                                    </div>
                                </div>

                                <div className="flex md:flex-col gap-2 justify-center shrink-0 min-w-[100px] border-t md:border-t-0 md:border-l border-zinc-900 pt-4 md:pt-0 md:pl-6">
                                    <button
                                        onClick={() => onDeleteClick(mp.id)}
                                        className="flex-1 md:flex-none py-3 px-4 bg-zinc-900 text-zinc-500 rounded-xl font-black text-xs uppercase tracking-widest hover:bg-red-500/10 hover:text-red-500 border border-zinc-800 transition-all flex items-center justify-center gap-2"
                                    >
                                        <Trash2 size={14} /> {t.btnDelete || 'Delete'}
                                    </button>
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
};

export default MaintenancePage;
