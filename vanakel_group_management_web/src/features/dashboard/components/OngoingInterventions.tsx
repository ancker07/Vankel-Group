import React, { useState } from 'react';
import { Clock, MapPin, ShieldCheck, User, ChevronRight, FileText, Eye, RotateCcw, Search, Filter, Calendar } from 'lucide-react';
import { Intervention, Building, Syndic, Language, Document } from '@/types';
import { URGENCY, SECTORS } from '@/utils/constants';
import DocumentViewerModal from '@/components/common/DocumentViewerModal';


interface OngoingInterventionsProps {
    interventions: Intervention[];
    buildings: Building[];
    syndics: Syndic[];
    onSelect: (id: string) => void;
    t: any;
    lang: Language;
    onRefresh: () => void;
    isRefreshing: boolean;
}

const OngoingInterventions: React.FC<OngoingInterventionsProps> = ({ interventions, buildings, syndics, onSelect, t, lang, onRefresh, isRefreshing }) => {
    const [viewerData, setViewerData] = useState<{ docs: Document[], index: number } | null>(null);

    // Filter States
    const [searchQuery, setSearchQuery] = useState('');
    const [selectedSector, setSelectedSector] = useState('');
    const [selectedUrgency, setSelectedUrgency] = useState('');
    const [selectedBuilding, setSelectedBuilding] = useState('');
    const [selectedDate, setSelectedDate] = useState('');

    const sortedInterventions = [...interventions].sort((a, b) =>
        new Date(b.scheduledDate).getTime() - new Date(a.scheduledDate).getTime()
    );

    const filteredInterventions = sortedInterventions.filter(i => {
        const matchesSearch = !searchQuery ||
            i.title?.toLowerCase().includes(searchQuery.toLowerCase()) ||
            i.description?.toLowerCase().includes(searchQuery.toLowerCase());

        const matchesSector = !selectedSector || i.sector === selectedSector;
        const matchesUrgency = !selectedUrgency || i.urgency === selectedUrgency;
        const matchesBuilding = !selectedBuilding || String(i.buildingId) === String(selectedBuilding);

        const intDate = new Date(i.scheduledDate).toISOString().split('T')[0];
        const matchesDate = !selectedDate || intDate === selectedDate;

        return matchesSearch && matchesSector && matchesUrgency && matchesBuilding && matchesDate;
    });

    const ongoingItems = filteredInterventions.filter(i => i.status === 'PENDING');

    return (
        <div className="space-y-6 animate-in fade-in duration-500 max-w-7xl mx-auto pb-12">
            <div className="flex justify-between items-center bg-zinc-950 p-6 rounded-3xl border border-zinc-900 shadow-xl mb-8">
                <div className="flex items-center gap-4">
                    <div>
                        <h2 className="text-2xl font-black text-white uppercase tracking-tight">{t.ongoing}</h2>
                        <p className="text-zinc-600 text-xs mt-1">{t.ongoing_subtitle || 'Track your active maintenance and repair tasks'}</p>
                    </div>
                    <button
                        onClick={onRefresh}
                        disabled={isRefreshing}
                        className={`p-2 rounded-xl bg-zinc-900 border border-zinc-800 text-zinc-400 hover:text-brand-green hover:border-brand-green/30 transition-all ${isRefreshing ? 'animate-spin' : ''}`}
                        title="Refresh Data"
                    >
                        <RotateCcw size={18} />
                    </button>
                </div>
                <div className="flex flex-col items-end gap-1">
                    <span className="bg-zinc-900 text-zinc-500 px-3 py-1 rounded-full text-xs font-bold border border-zinc-800">
                        {ongoingItems.length} {t.items || 'Items'}
                    </span>
                </div>
            </div>

            {/* Filter Bar */}
            <div className="bg-zinc-950 border border-zinc-900 p-4 rounded-2xl shadow-lg flex flex-wrap items-center gap-4 mb-6">
                <div className="relative flex-1 min-w-[200px]">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500" size={16} />
                    <input
                        type="text"
                        placeholder={t.search_placeholder || "Search interventions..."}
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full bg-zinc-900 border border-zinc-800 rounded-xl py-2 pl-10 pr-4 text-sm text-white focus:outline-none focus:border-brand-green/50 transition-colors"
                    />
                </div>

                <div className="flex items-center gap-2 flex-wrap">
                    <div className="flex items-center gap-2 px-3 py-2 bg-zinc-900 border border-zinc-800 rounded-xl shrink-0">
                        <Filter size={14} className="text-zinc-500" />
                        <select
                            value={selectedSector}
                            onChange={(e) => setSelectedSector(e.target.value)}
                            className="bg-transparent text-xs text-zinc-300 focus:outline-none border-none p-0 cursor-pointer"
                        >
                            <option value="">{t.all_sectors || "All Sectors"}</option>
                            {SECTORS.map(s => (
                                <option key={s.id} value={s.id}>{s.label[lang]}</option>
                            ))}
                        </select>
                    </div>

                    <div className="flex items-center gap-2 px-3 py-2 bg-zinc-900 border border-zinc-800 rounded-xl shrink-0">
                        <select
                            value={selectedUrgency}
                            onChange={(e) => setSelectedUrgency(e.target.value)}
                            className="bg-transparent text-xs text-zinc-300 focus:outline-none border-none p-0 cursor-pointer"
                        >
                            <option value="">{t.all_urgency || "All Urgency"}</option>
                            {URGENCY.map(u => (
                                <option key={u.id} value={u.id}>{u.label[lang]}</option>
                            ))}
                        </select>
                    </div>

                    <div className="flex items-center gap-2 px-3 py-2 bg-zinc-900 border border-zinc-800 rounded-xl shrink-0">
                        <select
                            value={selectedBuilding}
                            onChange={(e) => setSelectedBuilding(e.target.value)}
                            className="bg-transparent text-xs text-zinc-300 focus:outline-none border-none p-0 cursor-pointer max-w-[150px]"
                        >
                            <option value="">{t.all_buildings || "All Buildings"}</option>
                            {buildings.map(b => (
                                <option key={b.id} value={b.id}>{b.address}</option>
                            ))}
                        </select>
                    </div>

                    <div className="flex items-center gap-2 px-3 py-2 bg-zinc-900 border border-zinc-800 rounded-xl shrink-0">
                        <Calendar size={14} className="text-zinc-500" />
                        <input
                            type="date"
                            value={selectedDate}
                            onChange={(e) => setSelectedDate(e.target.value)}
                            className="bg-transparent text-xs text-zinc-300 focus:outline-none border-none p-0 cursor-pointer"
                            title="Filter by Date"
                        />
                    </div>

                    {(searchQuery || selectedSector || selectedUrgency || selectedBuilding || selectedDate) && (
                        <button
                            onClick={() => {
                                setSearchQuery('');
                                setSelectedSector('');
                                setSelectedUrgency('');
                                setSelectedBuilding('');
                                setSelectedDate('');
                            }}
                            className="p-2 text-zinc-500 hover:text-red-500 transition-colors"
                            title="Reset Filters"
                        >
                            <RotateCcw size={16} />
                        </button>
                    )}
                </div>
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
                                className={`bg-zinc-950 border ${isMaintenance ? 'border-orange-500/30' : 'border-zinc-800'} hover:border-brand-green/30 rounded-2xl cursor-pointer group transition-all flex flex-col h-full relative overflow-hidden`}
                            >
                                {/* Top Thumbnail Map Area */}
                                <div className="h-40 relative shrink-0">
                                    <div className="absolute inset-0 z-0 opacity-40 group-hover:opacity-60 transition-opacity pointer-events-none">
                                        <iframe
                                            width="100%"
                                            height="100%"
                                            frameBorder="0"
                                            style={{ border: 0 }}
                                            src={`https://maps.google.com/maps?q=${encodeURIComponent(`${b?.address}, ${b?.city}`)}&t=&z=13&ie=UTF8&iwloc=&output=embed`}
                                        ></iframe>
                                    </div>
                                    <div className="absolute inset-0 bg-gradient-to-t from-zinc-950 via-zinc-950/60 to-black/30 z-0 pointer-events-none"></div>

                                    <div className="relative z-10 p-4 h-full flex flex-col justify-between">
                                        <div className="flex justify-between items-start">
                                            <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider backdrop-blur-md shadow-lg ${i.status === 'DELAYED' ? 'bg-orange-500/20 text-orange-500 border border-orange-500/30' :
                                                isMaintenance ? 'bg-orange-500/20 text-orange-500 border border-orange-500/30' :
                                                    'bg-zinc-900/80 text-zinc-300 border border-zinc-700/50'
                                                }`}>
                                                {isMaintenance ? (t.maintenance || 'Entretien') : (i.status === 'DELAYED' ? t.status_delayed : t.status_pending)}
                                            </span>
                                            <div className="flex flex-col items-end gap-1.5">
                                                <span className="text-[10px] font-mono text-white/90 bg-black/50 border border-white/10 px-2 py-0.5 rounded backdrop-blur-md">{new Date(i.scheduledDate).toLocaleDateString()}</span>
                                                {i.urgency && (
                                                    <span className={`px-2 py-0.5 rounded text-[8px] font-black uppercase tracking-wider bg-black/50 border border-white/10 backdrop-blur-md ${URGENCY.find(u => u.id === i.urgency)?.color || 'text-zinc-500'}`}>
                                                        {URGENCY.find(u => u.id === i.urgency)?.label[lang]}
                                                    </span>
                                                )}
                                            </div>
                                        </div>

                                        <div className="pr-12">
                                            <h4 className="font-bold text-white mb-1 truncate drop-shadow-md text-lg" title={i.title}>{i.title}{i.interventionNumber ? ` – ${i.interventionNumber}` : ''}</h4>
                                            <div className="flex items-center gap-1.5 text-zinc-300 text-xs font-medium">
                                                <MapPin size={12} className="text-brand-green drop-shadow-sm shrink-0" />
                                                <span className="truncate drop-shadow-md" title={b?.address}>{b?.address}, {b?.city}</span>
                                            </div>
                                        </div>
                                    </div>

                                    <button
                                        onClick={(e) => {
                                            e.stopPropagation();
                                            window.open(`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${b?.address}, ${b?.city}`)}`, '_blank');
                                        }}
                                        className="absolute bottom-4 right-4 p-2 bg-zinc-950/80 border border-zinc-800 rounded-lg text-zinc-400 hover:text-brand-green hover:border-brand-green/50 transition-all z-20 shadow-lg backdrop-blur-md"
                                        title={t.viewOnMaps}
                                    >
                                        <MapPin size={14} />
                                    </button>
                                </div>

                                <div className="p-5 flex-1 flex flex-col relative z-10 bg-zinc-950">
                                    <p className="text-xs text-zinc-400 mb-4 line-clamp-3 min-h-[48px] leading-relaxed">{i.description}</p>

                                    {i.documents && i.documents.length > 0 && (
                                        <div className="flex flex-wrap gap-2 mb-4">
                                            {i.documents.slice(0, 4).map((doc, idx) => {
                                                const isImg = /\.(jpg|jpeg|png|webp|gif|svg)$/i.test(doc.url);
                                                return (
                                                    <div
                                                        key={doc.id || idx}
                                                        className="w-10 h-10 rounded-lg bg-zinc-900 border border-zinc-800 flex items-center justify-center overflow-hidden shrink-0 relative group/file"
                                                        title={doc.name}
                                                        onClick={(e) => {
                                                            e.stopPropagation();
                                                            setViewerData({ docs: i.documents, index: idx });
                                                        }}
                                                    >
                                                        {isImg ? (
                                                            <img src={doc.url} className="w-full h-full object-cover opacity-60 group-hover:opacity-100 transition-opacity" alt="" />
                                                        ) : (
                                                            <FileText size={16} className="text-zinc-600 group-hover:text-zinc-400 transition-colors" />
                                                        )}
                                                        <div className="absolute inset-0 bg-black/40 opacity-0 group-hover/file:opacity-100 flex items-center justify-center transition-opacity">
                                                            <Eye size={12} className="text-white" />
                                                        </div>
                                                    </div>
                                                );
                                            })}
                                            {i.documents.length > 4 && (
                                                <div className="w-10 h-10 rounded-lg bg-zinc-900 border border-zinc-800 flex items-center justify-center text-[10px] font-black text-zinc-600 uppercase tracking-tighter">
                                                    +{i.documents.length - 4}
                                                </div>
                                            )}
                                        </div>
                                    )}

                                    <div className="mt-auto space-y-2 pt-4 border-t border-zinc-900/50">
                                        <div className="flex items-center gap-2 text-xs text-zinc-400">
                                            <ShieldCheck size={12} className="text-zinc-600 shrink-0" />
                                            <span className="truncate">{s?.companyName || t.unassigned}</span>
                                        </div>
                                        {(i.onSiteContactName || (b?.tenants && b.tenants.length > 0)) && (
                                            <div className="flex items-center gap-2 text-xs text-zinc-400">
                                                <User size={12} className="text-zinc-600 shrink-0" />
                                                <span className="truncate">
                                                    {i.onSiteContactName || `${b?.tenants[0].firstName} ${b?.tenants[0].lastName}`}
                                                </span>
                                            </div>
                                        )}
                                    </div>
                                    <div className="pt-4 mt-4 border-t border-zinc-900/50">
                                        <span className="text-[10px] font-black uppercase tracking-widest text-brand-green flex items-center gap-1 group-hover:gap-2 transition-all">
                                            {t.viewSlip || 'VIEW SLIP'} <ChevronRight size={12} />
                                        </span>
                                    </div>
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}

            {viewerData && (
                <DocumentViewerModal
                    isOpen={!!viewerData}
                    onClose={() => setViewerData(null)}
                    documents={viewerData.docs}
                    initialIndex={viewerData.index}
                />
            )}
        </div>
    );
};

export default OngoingInterventions;
