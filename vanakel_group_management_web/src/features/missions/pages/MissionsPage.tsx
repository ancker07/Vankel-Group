
import React from 'react';
import { ClipboardList, Plus, MapPin, ShieldCheck, Mail, Check, X, FileText } from 'lucide-react';
import { Mission, Building, Syndic, Language } from '@/types';
import { URGENCY } from '@/utils/constants';


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
}


const MissionsPage: React.FC<MissionsPageProps> = ({ missions, buildings, syndics, onCreateClick, onApprove, onReject, t, role, lang }) => {

    const pendingMissions = missions.filter(m => m.status === 'PENDING');
    const approvedMissions = missions.filter(m => m.status === 'APPROVED');
    const rejectedMissions = missions.filter(m => m.status === 'REJECTED');

    const renderMissionList = (list: Mission[], emptyMsg: string) => (
        <div className="space-y-4">
            {list.length === 0 ? (
                <p className="text-center py-8 text-zinc-600 font-medium italic">{emptyMsg}</p>
            ) : (
                list.map(m => {
                    const b = buildings.find(build => String(build.id) === String(m.buildingId));
                    const s = syndics.find(syn => String(syn.id) === String(b?.linkedSyndicId || m.syndicId));

                    return (
                        <div key={m.id} className="bg-zinc-950 border border-zinc-800 p-5 rounded-2xl flex flex-col md:flex-row gap-6 hover:border-zinc-700 transition-all group">
                            <div className="flex-1">
                                <div className="flex items-center gap-2 mb-2">
                                    <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider ${m.status === 'APPROVED' ? 'bg-green-500/10 text-green-500' :
                                        m.status === 'REJECTED' ? 'bg-red-500/10 text-red-500' :
                                            'bg-blue-500/10 text-blue-400'
                                        }`}>
                                        {m.status}
                                    </span>
                                    {m.urgency && (
                                        <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider bg-zinc-900 border border-zinc-800 ${URGENCY.find(u => u.id === m.urgency)?.color || 'text-zinc-500'}`}>
                                            {URGENCY.find(u => u.id === m.urgency)?.label[lang]}
                                        </span>
                                    )}
                                    <span className="text-[10px] text-zinc-500 font-mono">{new Date(m.timestamp).toLocaleDateString()}</span>
                                </div>
                                <h4 className="text-lg font-bold text-white mb-2">{m.title || 'Mission Request'}</h4>
                                <p className="text-sm text-zinc-400 leading-relaxed mb-4">{m.description}</p>

                                {m.documents && m.documents.length > 0 && (
                                    <div className="flex flex-wrap gap-2 mb-4">
                                        {m.documents.map(doc => (
                                            <a
                                                key={doc.id}
                                                href={doc.url}
                                                target="_blank"
                                                rel="noopener noreferrer"
                                                className="flex items-center gap-1.5 px-3 py-1.5 bg-zinc-900 border border-zinc-800 rounded-lg text-xs text-zinc-400 hover:text-brand-green hover:border-brand-green transition-all"
                                            >
                                                <FileText size={14} />
                                                <span className="truncate max-w-[150px]">{doc.name}</span>
                                            </a>
                                        ))}
                                    </div>
                                )}

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

                            {role !== 'SYNDIC' && m.status === 'PENDING' && (
                                <div className="flex md:flex-col gap-2 justify-center shrink-0 min-w-[140px] border-t md:border-t-0 md:border-l border-zinc-900 pt-4 md:pt-0 md:pl-6">
                                    <button
                                        onClick={() => onApprove(m)}
                                        className="flex-1 md:flex-none py-3 px-4 bg-brand-green text-brand-black rounded-xl font-black text-xs uppercase tracking-widest hover:bg-brand-green-light transition-all flex items-center justify-center gap-2 shadow-lg shadow-brand-green/10"
                                    >
                                        <Check size={14} /> {t.approve}
                                    </button>
                                    <button
                                        onClick={() => onReject(m)}
                                        className="flex-1 md:flex-none py-3 px-4 bg-zinc-900 text-zinc-500 rounded-xl font-black text-xs uppercase tracking-widest hover:bg-red-500/10 hover:text-red-500 border border-zinc-800 transition-all flex items-center justify-center gap-2"
                                    >
                                        <X size={14} /> {t.reject}
                                    </button>
                                </div>
                            )}
                        </div>
                    );
                })
            )}
        </div>
    );

    return (
        <div className="space-y-6 animate-in fade-in duration-500 max-w-5xl mx-auto pb-12">
            <div className="flex justify-between items-center bg-zinc-950 p-6 rounded-3xl border border-zinc-900 shadow-xl">
                <div>
                    <h2 className="text-2xl font-black text-white uppercase tracking-tight">{t.missions}</h2>
                    <p className="text-zinc-600 text-xs mt-1">{t.missions_subtitle || 'Manage and track your building service requests'}</p>
                </div>
                <button
                    onClick={onCreateClick}
                    className="bg-brand-green text-brand-black px-6 py-3 rounded-xl font-black text-xs uppercase tracking-widest hover:bg-brand-green-light hover:scale-[1.02] active:scale-[0.98] transition-all shadow-lg shadow-brand-green/20 flex items-center gap-2 border border-brand-green/20"
                >
                    <Plus size={16} strokeWidth={3} /> {t.create_request || 'Create Request'}
                </button>

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
        </div>
    );
};

export default MissionsPage;
