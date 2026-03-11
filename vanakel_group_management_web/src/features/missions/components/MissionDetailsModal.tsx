
import React, { useState } from 'react';
import { X, Mail, MapPin, ShieldCheck, User, Phone, AtSign, FileText, Calendar, Clock, AlertCircle } from 'lucide-react';
import { Mission, Building, Syndic, Language, Document } from '@/types';
import { TRANSLATIONS, URGENCY } from '@/utils/constants';
import DocumentViewerModal from '@/components/common/DocumentViewerModal';

interface MissionDetailsModalProps {
    mission: Mission;
    building?: Building;
    syndic?: Syndic;
    lang: Language;
    onClose: () => void;
    onApprove?: (m: Mission) => void;
    onReject?: (m: Mission) => void;
    role?: string;
}

const MissionDetailsModal: React.FC<MissionDetailsModalProps> = ({
    mission,
    building,
    syndic,
    lang,
    onClose,
    onApprove,
    onReject,
    role
}) => {
    const t = TRANSLATIONS[lang] || TRANSLATIONS.EN;
    const [viewerData, setViewerData] = useState<{ docs: Document[], index: number } | null>(null);

    const isPending = mission.status === 'PENDING';
    const showActions = isPending && role !== 'SYNDIC';

    const urgencyInfo = mission.urgency ? (URGENCY.find(u => u.id === mission.urgency) || URGENCY[0]) : null;

    return (
        <div className="fixed inset-0 z-[150] flex items-center justify-center p-0 md:p-4 bg-black/80 backdrop-blur-sm animate-in fade-in duration-200">
            <div className="bg-zinc-950 border-t md:border border-zinc-800 w-full max-w-4xl h-[95dvh] md:h-auto md:max-h-[90dvh] rounded-t-3xl md:rounded-3xl shadow-2xl flex flex-col relative overflow-hidden">

                {/* Header with Image or Gradient */}
                <div className="h-32 md:h-40 bg-zinc-900 shrink-0 relative">
                    {building?.imageUrl ? (
                        <img src={building.imageUrl} className="w-full h-full object-cover opacity-40" alt="Building" />
                    ) : (
                        <div className="absolute inset-0 bg-gradient-to-br from-brand-green/10 via-zinc-900 to-zinc-950"></div>
                    )}
                    <div className="absolute inset-0 bg-gradient-to-t from-zinc-950 to-transparent"></div>

                    <button
                        onClick={onClose}
                        className="absolute top-4 right-4 bg-black/50 hover:bg-black text-white p-2 rounded-full transition-all z-20"
                    >
                        <X size={20} />
                    </button>

                    <div className="absolute bottom-4 left-6 right-6">
                        <div className="flex items-center gap-2 mb-1">
                            <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider ${mission.status === 'APPROVED' ? 'bg-green-500 text-white' :
                                mission.status === 'REJECTED' ? 'bg-red-500 text-white' :
                                    'bg-blue-500 text-white'
                                }`}>
                                {mission.status}
                            </span>
                            {mission.urgency && (
                                <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider bg-zinc-900 border border-zinc-800 ${urgencyInfo?.color || 'text-zinc-500'}`}>
                                    {urgencyInfo?.label[lang]}
                                </span>
                            )}
                        </div>
                        <h2 className="text-xl md:text-2xl font-black text-white leading-tight truncate">{mission.title || t.mission_request}</h2>
                    </div>
                </div>

                {/* Content */}
                <div className="flex-1 overflow-y-auto p-6 space-y-8">

                    {/* Main Info Grid */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-8">

                        {/* Left Side: Description & Docs */}
                        <div className="space-y-6">
                            <section>
                                <h3 className="text-[10px] font-black text-zinc-500 uppercase tracking-widest mb-3 flex items-center gap-2">
                                    <FileText size={14} className="text-brand-green" /> {t.description}
                                </h3>
                                <div className="bg-zinc-900/50 rounded-2xl p-5 border border-zinc-800">
                                    <p className="text-zinc-300 text-sm leading-relaxed whitespace-pre-wrap">{mission.description}</p>
                                </div>
                            </section>

                            {mission.documents && mission.documents.length > 0 && (
                                <section>
                                    <h3 className="text-[10px] font-black text-zinc-500 uppercase tracking-widest mb-3 flex items-center gap-2">
                                        <FileText size={14} className="text-zinc-600" /> {t.docs}
                                    </h3>
                                    <div className="grid grid-cols-1 gap-2">
                                        {mission.documents.map((doc, idx) => (
                                            <button
                                                key={doc.id || idx}
                                                onClick={() => setViewerData({ docs: mission.documents, index: idx })}
                                                className="flex items-center justify-between p-3 bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 rounded-xl group transition-all"
                                            >
                                                <div className="flex items-center gap-3 min-w-0">
                                                    <FileText size={16} className="text-zinc-500 group-hover:text-brand-green shrink-0" />
                                                    <span className="text-xs font-bold text-zinc-400 group-hover:text-white truncate">{doc.name}</span>
                                                </div>
                                                <span className="text-[9px] font-black text-zinc-600 uppercase group-hover:text-brand-green">{t.view || 'View'}</span>
                                            </button>
                                        ))}
                                    </div>
                                </section>
                            )}
                        </div>

                        {/* Right Side: Contact, Building, Email Source */}
                        <div className="space-y-6">

                            {/* Context Source (Email) */}
                            {mission.sourceType === 'EMAIL' && mission.sourceDetails && (
                                <section className="bg-brand-green/5 border border-brand-green/20 rounded-2xl p-5 space-y-4">
                                    <h3 className="text-[10px] font-black text-brand-green uppercase tracking-widest flex items-center gap-2">
                                        <Mail size={14} /> {t.automatic_import || 'Automatic Import'}
                                    </h3>
                                    <div className="space-y-3">
                                        <div className="flex flex-col">
                                            <span className="text-[9px] font-black text-zinc-600 uppercase tracking-tighter">From</span>
                                            <span className="text-xs font-bold text-zinc-300 break-all">{mission.sourceDetails.from}</span>
                                        </div>
                                        <div className="flex flex-col">
                                            <span className="text-[9px] font-black text-zinc-600 uppercase tracking-tighter">Subject</span>
                                            <span className="text-xs font-bold text-zinc-300">{mission.sourceDetails.subject}</span>
                                        </div>
                                        <div className="flex items-center gap-2 text-[9px] text-zinc-500 font-mono mt-1">
                                            <Clock size={10} /> {new Date(mission.sourceDetails.receivedAt).toLocaleString()}
                                        </div>
                                    </div>
                                </section>
                            )}

                            {/* Location & Syndic */}
                            <div className="relative z-10 p-5 space-y-4">
                                <h3 className="text-[10px] font-black text-zinc-500 uppercase tracking-widest flex items-center gap-2">
                                    <MapPin size={14} /> Location Details
                                </h3>
                                <div className="space-y-3">
                                    <div className="flex items-center justify-between gap-3">
                                        <div className="flex gap-3">
                                            <div className="w-8 h-8 rounded-lg bg-zinc-900/80 border border-zinc-800 flex items-center justify-center shrink-0 backdrop-blur-md">
                                                <MapPin size={16} className="text-zinc-500" />
                                            </div>
                                            <div>
                                                <p className="text-xs font-bold text-white shadow-black drop-shadow-sm">{building?.address || 'Standalone Request'}</p>
                                                <p className="text-[10px] text-zinc-400 font-bold">{building?.city || 'No city info'}</p>
                                            </div>
                                        </div>
                                        {building?.address && (
                                            <button
                                                onClick={() => {
                                                    window.open(`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${building?.address}, ${building?.city}`)}`, '_blank');
                                                }}
                                                className="p-2 bg-zinc-950/80 border border-zinc-800 rounded-lg text-zinc-400 hover:text-brand-green hover:border-brand-green/50 transition-all shrink-0 shadow-lg backdrop-blur-md"
                                                title={t.viewOnMaps}
                                            >
                                                <MapPin size={14} />
                                            </button>
                                        )}
                                    </div>
                                    {syndic && (
                                        <div className="flex gap-3 pt-2 border-t border-zinc-800/50 mt-2">
                                            <div className="w-8 h-8 rounded-lg bg-zinc-900/80 border border-zinc-800 flex items-center justify-center shrink-0 backdrop-blur-md">
                                                <ShieldCheck size={16} className="text-zinc-500" />
                                            </div>
                                            <div>
                                                <p className="text-[10px] font-black text-zinc-400 uppercase tracking-widest drop-shadow-sm">{t.syndic}</p>
                                                <p className="text-xs font-bold text-white shadow-black drop-shadow-sm">{syndic.companyName}</p>
                                            </div>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </section>

                        {/* Contact On Site */}
                        <section className="bg-zinc-900/30 border border-zinc-800 rounded-2xl p-5 space-y-4">
                            <h3 className="text-[10px] font-black text-zinc-500 uppercase tracking-widest flex items-center gap-2">
                                <User size={14} /> {t.onSiteContactLabel}
                            </h3>
                            <div className="space-y-3">
                                {mission.onSiteContactName ? (
                                    <>
                                        <div className="flex items-center gap-3">
                                            <User size={14} className="text-zinc-600" />
                                            <span className="text-xs font-bold text-zinc-300">{mission.onSiteContactName}</span>
                                        </div>
                                        {mission.onSiteContactPhone && (
                                            <div className="flex items-center gap-3">
                                                <Phone size={14} className="text-zinc-600" />
                                                <span className="text-xs font-bold text-zinc-300">{mission.onSiteContactPhone}</span>
                                            </div>
                                        )}
                                        {mission.onSiteContactEmail && (
                                            <div className="flex items-center gap-3">
                                                <AtSign size={14} className="text-zinc-600" />
                                                <span className="text-xs font-bold text-zinc-300">{mission.onSiteContactEmail}</span>
                                            </div>
                                        )}
                                    </>
                                ) : (
                                    <p className="text-xs text-zinc-600 italic">{t.notProvided}</p>
                                )}
                            </div>
                        </section>

                    </div>
                </div>
            </div>

            {/* Footer Actions */}
            {showActions && (
                <div className="p-6 bg-zinc-950 border-t border-zinc-900 flex gap-4">
                    <button
                        onClick={() => { onReject?.(mission); onClose(); }}
                        className="flex-1 py-4 bg-zinc-900 text-zinc-500 rounded-2xl font-black text-xs uppercase tracking-[0.2em] hover:bg-red-500/10 hover:text-red-500 border border-zinc-900 transition-all"
                    >
                        {t.reject}
                    </button>
                    <button
                        onClick={() => { onApprove?.(mission); onClose(); }}
                        className="flex-1 py-4 bg-brand-green text-brand-black rounded-2xl font-black text-xs uppercase tracking-[0.2em] hover:bg-brand-green-light hover:scale-[1.02] transition-all shadow-xl shadow-brand-green/10"
                    >
                        {t.approve}
                    </button>
                </div>
            )}

            {/* Close hint for mobile */}
            <div className="md:hidden py-4 text-center border-t border-zinc-900 bg-zinc-950">
                <button onClick={onClose} className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">
                    Swipe down or tap to close
                </button>
            </div>
        </div>

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

export default MissionDetailsModal;
