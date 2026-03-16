
import React, { useState } from 'react';
import { ClipboardList, Plus, MapPin, ShieldCheck, Mail, Check, X, FileText, RotateCcw, ChevronRight, Search, Filter, Calendar, MessageSquare } from 'lucide-react';
import { Mission, Building, Syndic, Language, Document } from '@/types';
import { URGENCY, SECTORS } from '@/utils/constants';
import DocumentViewerModal from '@/components/common/DocumentViewerModal';
import MissionDetailsModal from '../components/MissionDetailsModal';


interface MissionsPageProps {
    missions: Mission[];
    buildings: Building[];
    syndics: Syndic[];
    onCreateClick: () => void;
    onApprove: (mission: Mission) => void;
    onReject: (mission: Mission) => void;
    t: any;
    role?: string;
    lang: Language;
    onRefresh: () => void;
    isRefreshing: boolean;
}


const MissionsPage: React.FC<MissionsPageProps> = ({ missions, buildings, syndics, onCreateClick, onApprove, onReject, t, role, lang, onRefresh, isRefreshing }) => {
    const [viewerData, setViewerData] = useState<{ docs: Document[], index: number } | null>(null);
    const [selectedMission, setSelectedMission] = useState<Mission | null>(null);
    const [expandedDescIds, setExpandedDescIds] = useState<Record<string, boolean>>({});

    // Filter States
    const [searchQuery, setSearchQuery] = useState('');
    const [selectedSector, setSelectedSector] = useState('');
    const [selectedUrgency, setSelectedUrgency] = useState('');
    const [selectedBuilding, setSelectedBuilding] = useState('');
    const [selectedDate, setSelectedDate] = useState('');

    const sortedMissions = [...missions].sort((a, b) => {
        const dateA = new Date(a.timestamp || a.created_at || (a as any).received_at || 0).getTime();
        const dateB = new Date(b.timestamp || b.created_at || (b as any).received_at || 0).getTime();
        return dateB - dateA;
    });

    const filteredMissions = sortedMissions.filter(m => {
        const matchesSearch = !searchQuery ||
            m.title?.toLowerCase().includes(searchQuery.toLowerCase()) ||
            m.description?.toLowerCase().includes(searchQuery.toLowerCase());

        const matchesSector = !selectedSector || m.sector === selectedSector;
        const matchesUrgency = !selectedUrgency || m.urgency === selectedUrgency;
        const matchesBuilding = !selectedBuilding || String(m.buildingId) === String(selectedBuilding);

        const missionDate = new Date(m.timestamp).toISOString().split('T')[0];
        const matchesDate = !selectedDate || missionDate === selectedDate;

        return matchesSearch && matchesSector && matchesUrgency && matchesBuilding && matchesDate;
    });

    const pendingMissions = filteredMissions.filter(m => m.status === 'PENDING');
    const approvedMissions = filteredMissions.filter(m => m.status === 'APPROVED');
    const rejectedMissions = filteredMissions.filter(m => m.status === 'REJECTED');

    const getLocalizedField = (obj: any, field: 'title' | 'description') => {
        if (lang === 'EN') return obj[`${field}_en`] || obj[field];
        if (lang === 'NL') return obj[`${field}_nl`] || obj[field];
        return obj[`${field}_fr`] || obj[field];
    };

    const renderMissionList = (list: Mission[], emptyMsg: string) => (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {list.length === 0 ? (
                <p className="text-center py-8 text-zinc-600 font-medium italic">{emptyMsg}</p>
            ) : (
                list.map(m => {
                    const b = buildings.find(build => String(build.id) === String(m.buildingId));
                    const s = syndics.find(syn => String(syn.id) === String(b?.linkedSyndicId || m.syndicId));

                    return (
                        <div
                            key={m.id}
                            onClick={(e) => {
                                // Prevent modal if clicking buttons or specific file attachments
                                if ((e.target as HTMLElement).closest('button')) return;
                                setSelectedMission(m);
                            }}
                            className="bg-zinc-950 border border-zinc-800 rounded-2xl flex flex-col hover:border-brand-green/30 transition-all group cursor-pointer overflow-hidden"
                        >
                            {/* Top Thumbnail Map Area */}
                            <div className="h-40 relative shrink-0">
                                <div className="absolute inset-0 z-0 opacity-60 group-hover:opacity-100 transition-all duration-500 pointer-events-none">
                                    <iframe
                                        width="100%"
                                        height="100%"
                                        frameBorder="0"
                                        style={{ border: 0 }}
                                        src={`https://maps.google.com/maps?q=${encodeURIComponent(`${b?.address}, ${b?.city}`)}&t=&z=13&ie=UTF8&iwloc=&output=embed`}
                                    ></iframe>
                                </div>
                                <div className="absolute inset-0 bg-gradient-to-t from-zinc-950 via-zinc-950/20 to-transparent z-0 pointer-events-none"></div>

                                <div className="relative z-10 p-5 h-full flex flex-col justify-between">
                                    <div className="flex justify-between items-start">
                                        <div className="flex items-center gap-2 mb-2">
                                            <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider backdrop-blur-md shadow-lg ${m.status === 'APPROVED' ? 'bg-green-500/20 text-green-500 border border-green-500/30' :
                                                m.status === 'REJECTED' ? 'bg-red-500/20 text-red-500 border border-red-500/30' :
                                                    'bg-blue-500/20 text-blue-400 border border-blue-500/30'
                                                }`}>
                                                {m.status}
                                            </span>
                                        </div>
                                        <div className="flex flex-col items-end gap-1.5">
                                            <span className="text-[10px] font-mono text-white/90 bg-black/50 border border-white/10 px-2 py-0.5 rounded backdrop-blur-md">{new Date((m as any).timestamp || (m as any).created_at || (m as any).received_at || Date.now()).toLocaleDateString()}</span>
                                            {m.urgency && (
                                                <span className={`px-2 py-0.5 rounded text-[8px] font-black uppercase tracking-wider bg-black/50 border border-white/10 backdrop-blur-md ${URGENCY.find(u => u.id === m.urgency)?.color || 'text-zinc-500'}`}>
                                                    {URGENCY.find(u => u.id === m.urgency)?.label[lang]}
                                                </span>
                                            )}
                                        </div>
                                    </div>

                                    <div className="pr-12">
                                        <h4 className="font-bold text-white mb-1 truncate drop-shadow-md text-lg" title={getLocalizedField(m, 'title') || t.mission_request}>{getLocalizedField(m, 'title') || t.mission_request}</h4>
                                        <div className="flex items-center gap-1.5 text-zinc-300 text-xs font-medium">
                                            <MapPin size={12} className="text-brand-green drop-shadow-sm shrink-0" />
                                            <span className="truncate drop-shadow-md">{b?.address || 'Standalone Request'}</span>
                                        </div>
                                    </div>
                                </div>

                                {b?.address && (
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
                                )}
                            </div>

                            <div className="flex flex-col flex-1 bg-zinc-950 relative z-10">
                                <div className="flex-1 p-5 flex flex-col justify-between space-y-4">
                                    <div>
                                        <p 
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                setExpandedDescIds(prev => ({ ...prev, [m.id]: !prev[m.id] }));
                                            }}
                                            className={`text-sm text-zinc-400 leading-relaxed mb-4 cursor-pointer hover:text-zinc-300 transition-colors ${expandedDescIds[m.id] ? '' : 'line-clamp-2'}`}
                                            title={expandedDescIds[m.id] ? "Click to collapse" : "Click to expand"}
                                        >
                                            {getLocalizedField(m, 'description')}
                                        </p>

                                        {/* Email Source Banner */}
                                        {m.sourceType === 'EMAIL' && m.sourceDetails && (
                                            <div className="mb-4 p-3 bg-brand-green/10 border border-brand-green/20 rounded-xl flex flex-col gap-1.5 shadow-inner">
                                                <div className="flex items-center gap-1.5 text-brand-green">
                                                    <Mail size={12} className="animate-pulse" />
                                                    <span className="text-[10px] font-black uppercase tracking-[0.1em]">{t.automatic_import || 'Automatic Import'}</span>
                                                </div>
                                                <div className="flex flex-col gap-0.5 text-[11px] text-zinc-400">
                                                    <span className="truncate"><span className="text-zinc-600 font-bold mr-1">FROM:</span> {m.sourceDetails.from}</span>
                                                    <span className="truncate"><span className="text-zinc-600 font-bold mr-1">SUBJ:</span> {m.sourceDetails.subject}</span>
                                                </div>
                                            </div>
                                        )}
                                        
                                        {m.sourceType === 'CONTACT_FORM' && m.sourceDetails && (
                                            <div className="mb-4 p-3 bg-blue-500/10 border border-blue-500/20 rounded-xl flex flex-col gap-1.5 shadow-inner">
                                                <div className="flex items-center gap-1.5 text-blue-400">
                                                    <MessageSquare size={12} className="animate-pulse" />
                                                    <span className="text-[10px] font-black uppercase tracking-[0.1em]">{t.contact_form_import || 'Contact Form Import'}</span>
                                                </div>
                                                <div className="flex flex-col gap-0.5 text-[11px] text-zinc-400">
                                                    <span className="truncate"><span className="text-zinc-600 font-bold mr-1">FROM:</span> {m.sourceDetails.from}</span>
                                                    <span className="truncate"><span className="text-zinc-600 font-bold mr-1">SUBJ:</span> {m.sourceDetails.subject}</span>
                                                </div>
                                            </div>
                                        )}

                                        {m.documents && m.documents.length > 0 && (
                                            <div className="flex flex-wrap gap-2 mb-4">
                                                {m.documents.map((doc, idx) => (
                                                    <button
                                                        key={doc.id || idx}
                                                        onClick={(e) => {
                                                            e.stopPropagation();
                                                            setViewerData({ docs: m.documents, index: idx });
                                                        }}
                                                        className="flex items-center gap-1.5 px-3 py-1.5 bg-zinc-900 border border-zinc-800 rounded-lg text-xs text-zinc-400 hover:text-brand-green hover:border-brand-green transition-all shadow-sm"
                                                    >
                                                        <FileText size={14} />
                                                        <span className="truncate max-w-[100px]">{doc.name}</span>
                                                    </button>
                                                ))}
                                            </div>
                                        )}
                                    </div>

                                    <div className="mt-auto pt-4 border-t border-zinc-900/50 flex items-center justify-between text-xs text-zinc-500">
                                        <div className="flex items-center gap-1.5 min-w-0">
                                            <ShieldCheck size={12} className="text-zinc-600 shrink-0" />
                                            <span className="truncate">{s?.companyName || t.no_syndic}</span>
                                        </div>
                                        <div className="flex items-center gap-1 text-brand-green font-black uppercase text-[10px] tracking-widest shrink-0">
                                            {t.view || 'View'} <ChevronRight size={14} />
                                        </div>
                                    </div>
                                </div>

                                {/* Action Buttons - Moved to bottom and stacked/row based on width */}
                                {role !== 'SYNDIC' && m.status === 'PENDING' && (
                                    <div className="flex gap-2 p-4 border-t border-zinc-900/50 bg-zinc-950/50">
                                        <button
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                onApprove(m);
                                            }}
                                            className="flex-1 py-2.5 px-4 bg-brand-green text-brand-black rounded-xl font-black text-[10px] uppercase tracking-widest hover:bg-brand-green-light transition-all flex items-center justify-center gap-2 shadow-lg shadow-brand-green/10"
                                        >
                                            <Check size={14} /> {t.approve}
                                        </button>
                                        <button
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                onReject(m);
                                            }}
                                            className="flex-1 py-2.5 px-4 bg-zinc-900 text-zinc-500 rounded-xl font-black text-[10px] uppercase tracking-widest hover:bg-red-500/10 hover:text-red-500 border border-zinc-800 transition-all flex items-center justify-center gap-2"
                                        >
                                            <X size={14} /> {t.reject}
                                        </button>
                                    </div>
                                )}
                            </div>
                        </div>
                    );
                })
            )}
        </div>
    );

    return (
        <div className="space-y-6 animate-in fade-in duration-500 max-w-5xl mx-auto pb-12 px-4 md:px-0">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-6 bg-zinc-950 p-6 rounded-3xl border border-zinc-900 shadow-xl">
                <div className="flex items-center gap-4">
                    <div>
                        <h2 className="text-2xl font-black text-white uppercase tracking-tight">{t.missions}</h2>
                        <p className="text-zinc-600 text-xs mt-1">{t.missions_subtitle || 'Manage and track your building service requests'}</p>
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
                <button
                    onClick={onCreateClick}
                    className="w-full sm:w-auto bg-brand-green text-brand-black px-6 py-3 rounded-xl font-black text-xs uppercase tracking-widest hover:bg-brand-green-light hover:scale-[1.02] active:scale-[0.98] transition-all shadow-lg shadow-brand-green/20 flex items-center justify-center gap-2 border border-brand-green/20"
                >
                    <Plus size={16} strokeWidth={3} /> {t.create_request || 'Create Request'}
                </button>
            </div>

            {/* Filter Bar */}
            <div className="bg-zinc-950 border border-zinc-900 p-4 rounded-2xl shadow-lg flex flex-wrap items-center gap-4">
                <div className="relative flex-1 min-w-[200px]">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500" size={16} />
                    <input
                        type="text"
                        placeholder={t.search_placeholder || "Search missions..."}
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

            <div className="space-y-12">
                <section>
                    <h3 className="text-[10px] font-black uppercase text-zinc-500 tracking-[0.2em] mb-4 flex items-center gap-2">
                        <div className="w-1.5 h-1.5 rounded-full bg-blue-500 shadow-[0_0_8px_rgba(59,130,246,0.5)]"></div>
                        {t.pending || 'Pending Requests'}
                    </h3>
                    {renderMissionList(pendingMissions, t.no_pending || 'No pending requests.')}
                </section>

                <section>
                    <h3 className="text-[10px] font-black uppercase text-zinc-500 tracking-[0.2em] mb-4 flex items-center gap-2">
                        <div className="w-1.5 h-1.5 rounded-full bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.5)]"></div>
                        {t.status_accepted || 'Accepted'}
                    </h3>
                    {renderMissionList(approvedMissions, t.no_accepted || 'No accepted missions yet.')}
                </section>

                <section>
                    <h3 className="text-[10px] font-black uppercase text-zinc-500 tracking-[0.2em] mb-4 flex items-center gap-2">
                        <div className="w-1.5 h-1.5 rounded-full bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.5)]"></div>
                        {t.status_rejected || 'Rejected'}
                    </h3>
                    {renderMissionList(rejectedMissions, t.no_rejected || 'No rejected missions.')}
                </section>
            </div>

            {
                selectedMission && (
                    <MissionDetailsModal
                        mission={selectedMission}
                        onClose={() => setSelectedMission(null)}
                        building={buildings.find(b => String(b.id) === String(selectedMission.buildingId))}
                        syndic={syndics.find(s => String(s.id) === String(selectedMission.syndicId || buildings.find(b => String(b.id) === String(selectedMission.buildingId))?.linkedSyndicId))}
                        lang={lang}
                        onApprove={onApprove}
                        onReject={onReject}
                        role={role}
                    />
                )
            }

            {
                viewerData && (
                    <DocumentViewerModal
                        isOpen={!!viewerData}
                        onClose={() => setViewerData(null)}
                        documents={viewerData.docs}
                        initialIndex={viewerData.index}
                    />
                )
            }
        </div >
    );
};

export default MissionsPage;
