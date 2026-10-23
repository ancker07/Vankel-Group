import React, { useMemo, useState } from 'react';
import { CheckCircle2, MapPin, User, Calendar, Search, ChevronRight, Lock } from 'lucide-react';
import { Intervention, Building, Professional, Language } from '@/types';
import { TRANSLATIONS } from '@/utils/constants';

interface CompletedMissionsPageProps {
    interventions: Intervention[];
    buildings: Building[];
    professionals: Professional[];
    onSelect: (id: string) => void;
    lang: Language;
}

/** "End of mission": every completed intervention, newest first. They are read-only except for admins. */
const CompletedMissionsPage: React.FC<CompletedMissionsPageProps> = ({ interventions, buildings, professionals, onSelect, lang }) => {
    const t = TRANSLATIONS[lang];
    const [search, setSearch] = useState('');

    const completed = useMemo(() => interventions
        .filter(i => i.status === 'COMPLETED')
        .filter(i => {
            const b = buildings.find(b => b.id === i.buildingId);
            return `${i.title} ${b?.address || ''} ${b?.city || ''}`.toLowerCase().includes(search.toLowerCase());
        })
        .sort((a, b) => new Date(b.completedAt || b.scheduledDate).getTime() - new Date(a.completedAt || a.scheduledDate).getTime()),
        [interventions, buildings, search]);

    const localizedTitle = (i: any) =>
        (lang === 'EN' ? i.title_en : lang === 'NL' ? i.title_nl : i.title_fr) || i.title;

    return (
        <div className="space-y-6 animate-in fade-in duration-500 max-w-6xl mx-auto pb-12 px-4 md:px-0">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                <div>
                    <h2 className="text-2xl font-black text-white uppercase tracking-tight flex items-center gap-2">
                        <CheckCircle2 className="text-brand-green" /> {t.end_of_mission || 'End of mission'} ({completed.length})
                    </h2>
                    <p className="text-zinc-500 text-sm font-medium flex items-center gap-1.5">
                        <Lock size={12} /> {t.end_of_mission_subtitle || 'Completed missions are locked. Only an admin can change them.'}
                    </p>
                </div>
                <div className="relative w-full md:w-72">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-600" size={16} />
                    <input
                        value={search}
                        onChange={e => setSearch(e.target.value)}
                        placeholder={t.search || 'Search...'}
                        className="w-full bg-zinc-950 border border-zinc-800 rounded-xl pl-9 pr-4 py-2.5 text-sm text-white focus:border-brand-green outline-none"
                    />
                </div>
            </div>

            {completed.length === 0 ? (
                <div className="p-16 text-center text-zinc-600 text-sm bg-zinc-950 border border-zinc-800 rounded-2xl">
                    {t.end_of_mission_empty || 'No completed missions yet.'}
                </div>
            ) : (
                <div className="bg-zinc-950 border border-zinc-800 rounded-2xl divide-y divide-zinc-900">
                    {completed.map(i => {
                        const b = buildings.find(b => b.id === i.buildingId);
                        const pro = professionals.find(p => p.id === i.proId);
                        return (
                            <button key={i.id} onClick={() => onSelect(i.id)} className="w-full text-left p-4 flex items-center gap-4 hover:bg-zinc-900/50 transition-colors">
                                <CheckCircle2 size={20} className="text-brand-green shrink-0" />
                                <div className="min-w-0 flex-1 space-y-1">
                                    <p className="font-bold text-white truncate">{localizedTitle(i)}</p>
                                    <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-zinc-500">
                                        <span className="flex items-center gap-1 min-w-0"><MapPin size={12} className="shrink-0" /> <span className="truncate">{b ? `${b.address}, ${b.city}` : '-'}</span></span>
                                        <span className="flex items-center gap-1"><Calendar size={12} /> {new Date(i.completedAt || i.scheduledDate).toLocaleDateString()}</span>
                                        {pro && <span className="flex items-center gap-1"><User size={12} /> {pro.contactPerson}</span>}
                                    </div>
                                </div>
                                <ChevronRight size={16} className="text-zinc-600 shrink-0" />
                            </button>
                        );
                    })}
                </div>
            )}
        </div>
    );
};

export default CompletedMissionsPage;
