
import React from 'react';
import { Clock, MapPin, ShieldCheck, User, ChevronRight } from 'lucide-react';
import { Intervention, Building, Syndic, Language } from '@/types';
import { URGENCY } from '@/utils/constants';


interface OngoingInterventionsProps {
    interventions: Intervention[];
    buildings: Building[];
    syndics: Syndic[];
    onSelect: (id: string) => void;
    t: any;
    lang: Language;
}

const OngoingInterventions: React.FC<OngoingInterventionsProps> = ({ interventions, buildings, syndics, onSelect, t, lang }) => {

    const ongoingItems = interventions.filter(i => i.status === 'PENDING' || i.status === 'DELAYED');

    return (
        <div className="space-y-6 animate-in fade-in duration-500 max-w-7xl mx-auto pb-12">
            <div className="flex justify-between items-center">
                <h2 className="text-2xl font-black text-white uppercase tracking-tight">{t.ongoing}</h2>
                <span className="bg-zinc-900 text-zinc-500 px-3 py-1 rounded-full text-xs font-bold border border-zinc-800">
                    {ongoingItems.length} Items
                </span>
            </div>

            {ongoingItems.length === 0 ? (
                <div className="p-12 text-center border border-dashed border-zinc-800 rounded-2xl bg-zinc-900/20">
                    <Clock size={48} className="mx-auto text-zinc-700 mb-4" />
                    <p className="text-zinc-500 font-medium">No ongoing interventions.</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {ongoingItems.map(i => {
                        const b = buildings.find(build => build.id === i.buildingId);
                        const s = syndics.find(syn => syn.id === b?.linkedSyndicId);
                        const isMaintenance = i.isMaintenanceOccurrence;

                        return (
                            <div
                                key={i.id}
                                onClick={() => onSelect(i.id)}
                                className={`bg-zinc-950 border ${isMaintenance ? 'border-orange-500/30' : 'border-zinc-800'} hover:border-brand-green/30 p-5 rounded-2xl cursor-pointer group transition-all flex flex-col`}
                            >
                                <div className="flex justify-between items-start mb-4">
                                    <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider ${i.status === 'DELAYED' ? 'bg-orange-500/10 text-orange-500 border border-orange-500/20' :
                                        isMaintenance ? 'bg-orange-500/10 text-orange-500 border border-orange-500/20' :
                                            'bg-zinc-800 text-zinc-400 border border-zinc-700'
                                        }`}>
                                        {isMaintenance ? (t.maintenance || 'Entretien') : (i.status === 'DELAYED' ? t.status_delayed : t.status_pending)}
                                    </span>
                                    <div className="flex flex-col items-end gap-1.5">
                                        <span className="text-[10px] font-mono text-zinc-600">{new Date(i.scheduledDate).toLocaleDateString()}</span>
                                        {i.urgency && (
                                            <span className={`px-2 py-0.5 rounded text-[8px] font-black uppercase tracking-wider bg-zinc-900 border border-zinc-800 ${URGENCY.find(u => u.id === i.urgency)?.color || 'text-zinc-500'}`}>
                                                {URGENCY.find(u => u.id === i.urgency)?.label[lang]}
                                            </span>
                                        )}
                                    </div>

                                </div>

                                <h4 className="font-bold text-white mb-1 truncate" title={i.title}>{i.title}{i.interventionNumber ? ` – ${i.interventionNumber}` : ''}</h4>
                                <p className="text-xs text-zinc-500 mb-4 line-clamp-2 min-h-[32px]">{i.description}</p>

                                <div className="mt-auto space-y-2 pt-4 border-t border-zinc-900">
                                    <div className="flex items-center gap-2 text-xs text-zinc-400">
                                        <MapPin size={12} className="text-brand-green" />
                                        <span className="truncate">{b?.address}, {b?.city}</span>
                                    </div>
                                    <div className="flex items-center gap-2 text-xs text-zinc-400">
                                        <ShieldCheck size={12} className="text-zinc-600" />
                                        <span className="truncate">{s?.companyName || t.unassigned}</span>
                                    </div>
                                    {(i.onSiteContactName || (b?.tenants && b.tenants.length > 0)) && (
                                        <div className="flex items-center gap-2 text-xs text-zinc-400">
                                            <User size={12} className="text-zinc-600" />
                                            <span className="truncate">
                                                {i.onSiteContactName || `${b?.tenants[0].firstName} ${b?.tenants[0].lastName}`}
                                            </span>
                                        </div>
                                    )}
                                </div>
                                <div className="pt-4 mt-2">
                                    <span className="text-[10px] font-black uppercase tracking-widest text-brand-green flex items-center gap-1 group-hover:gap-2 transition-all">
                                        {t.viewSlip} <ChevronRight size={12} />
                                    </span>
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
};

export default OngoingInterventions;
