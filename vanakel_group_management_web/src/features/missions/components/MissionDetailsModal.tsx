
import React, { useState } from 'react';
import { X, Mail, MapPin, ShieldCheck, User, Phone, AtSign, FileText, Calendar, Clock, AlertCircle, Edit2, Save, Undo2 } from 'lucide-react';
import { Mission, Building, Syndic, Language, Document, Urgency, Sector } from '@/types';
import { TRANSLATIONS, URGENCY, SECTORS } from '@/utils/constants';
import DocumentViewerModal from '@/components/common/DocumentViewerModal';

interface MissionDetailsModalProps {
    mission: Mission;
    building?: Building;
    syndic?: Syndic;
    buildings?: Building[];
    lang: Language;
    onClose: () => void;
    onApprove?: (m: Mission) => void;
    onReject?: (m: Mission) => void;
    onUpdate?: (id: string, payload: any) => void;
    role?: string;
}

const MissionDetailsModal: React.FC<MissionDetailsModalProps> = ({
    mission,
    building,
    syndic,
    buildings = [],
    lang,
    onClose,
    onApprove,
    onReject,
    onUpdate,
    role
}) => {
    const t = TRANSLATIONS[lang] || TRANSLATIONS.EN;
    const [viewerData, setViewerData] = useState<{ docs: Document[], index: number } | null>(null);
    const [isEditing, setIsEditing] = useState(false);
    const [isSaving, setIsSaving] = useState(false);

    // Editable state
    const [editData, setEditData] = useState({
        title: mission.title || '',
        description: mission.description || '',
        urgency: mission.urgency || 'MEDIUM',
        sector: mission.sector || 'GENERAL',
        buildingId: String(mission.buildingId || ''),
        onSiteContactName: mission.onSiteContactName || '',
        onSiteContactPhone: mission.onSiteContactPhone || '',
        onSiteContactEmail: mission.onSiteContactEmail || ''
    });

    const isPending = mission.status === 'PENDING';
    const showAdminActions = isPending && role !== 'SYNDIC';
    const canEdit = role === 'SUPERADMIN' || role === 'ADMIN';

    const urgencyInfo = editData.urgency ? (URGENCY.find(u => u.id === editData.urgency) || URGENCY[0]) : null;

    const handleSave = async () => {
        if (!onUpdate) return;
        setIsSaving(true);
        try {
            await onUpdate(mission.id, editData);
            setIsEditing(false);
        } finally {
            setIsSaving(false);
        }
    };

    const getLocalizedField = (obj: any, field: 'title' | 'description') => {
        if (lang === 'EN') return obj[`${field}_en`] || obj[field];
        if (lang === 'NL') return obj[`${field}_nl`] || obj[field];
        return obj[`${field}_fr`] || obj[field];
    };

    const currentBuilding = buildings.find(b => String(b.id) === editData.buildingId) || building;

    return (
        <div className="fixed inset-0 z-[150] flex items-center justify-center p-0 md:p-4 bg-black/80 backdrop-blur-sm animate-in fade-in duration-200">
            <div className="bg-zinc-950 border-t md:border border-zinc-800 w-full max-w-4xl h-[95dvh] md:h-auto md:max-h-[90dvh] rounded-t-3xl md:rounded-3xl shadow-2xl flex flex-col relative overflow-hidden">

                {/* Header with Image or Gradient */}
                <div className="h-32 md:h-40 bg-zinc-900 shrink-0 relative">
                    {currentBuilding?.imageUrl ? (
                        <img src={currentBuilding.imageUrl} className="w-full h-full object-cover opacity-40" alt="Building" />
                    ) : (
                        <div className="absolute inset-0 bg-gradient-to-br from-brand-green/10 via-zinc-900 to-zinc-950"></div>
                    )}
                    <div className="absolute inset-0 bg-gradient-to-t from-zinc-950 to-transparent"></div>

                    <div className="absolute top-4 right-4 flex gap-2 z-20">
                        {canEdit && isPending && (
                            <button
                                onClick={() => setIsEditing(!isEditing)}
                                className={`p-2 rounded-full transition-all ${isEditing ? 'bg-brand-green text-brand-black' : 'bg-black/50 hover:bg-black text-white'}`}
                                title={isEditing ? "Cancel Editing" : "Edit Mission"}
                            >
                                {isEditing ? <Undo2 size={20} /> : <Edit2 size={20} />}
                            </button>
                        )}
                        <button
                            onClick={onClose}
                            className="bg-black/50 hover:bg-black text-white p-2 rounded-full transition-all"
                        >
                            <X size={20} />
                        </button>
                    </div>

                    <div className="absolute bottom-4 left-6 right-6">
                        <div className="flex items-center gap-2 mb-1">
                            <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider ${mission.status === 'APPROVED' ? 'bg-green-500 text-white' :
                                mission.status === 'REJECTED' ? 'bg-red-500 text-white' :
                                    'bg-blue-500 text-white'
                                }`}>
                                {mission.status}
                            </span>
                            {!isEditing ? (
                                mission.urgency && (
                                    <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider bg-zinc-900 border border-zinc-800 ${urgencyInfo?.color || 'text-zinc-500'}`}>
                                        {urgencyInfo?.label[lang]}
                                    </span>
                                )
                            ) : (
                                <select
                                    value={editData.urgency}
                                    onChange={(e) => setEditData({ ...editData, urgency: e.target.value as Urgency })}
                                    className="bg-zinc-950 border border-zinc-800 rounded px-2 py-0.5 text-[9px] font-black uppercase text-white outline-none focus:border-brand-green"
                                >
                                    {URGENCY.map(u => (
                                        <option key={u.id} value={u.id}>{u.label[lang]}</option>
                                    ))}
                                </select>
                            )}
                        </div>
                        {isEditing ? (
                            <input
                                type="text"
                                value={editData.title}
                                onChange={(e) => setEditData({ ...editData, title: e.target.value })}
                                className="w-full bg-zinc-900/80 border border-zinc-700 rounded-lg px-3 py-1 text-lg md:text-xl font-black text-white outline-none focus:border-brand-green"
                                placeholder={t.title || "Title"}
                            />
                        ) : (
                            <h2 className="text-xl md:text-2xl font-black text-white leading-tight truncate">{getLocalizedField(mission, 'title') || t.mission_request}</h2>
                        )}
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
                                    {isEditing ? (
                                        <textarea
                                            value={editData.description}
                                            onChange={(e) => setEditData({ ...editData, description: e.target.value })}
                                            className="w-full bg-transparent text-zinc-300 text-sm leading-relaxed outline-none min-h-[150px] resize-none"
                                            placeholder={t.description || "Description"}
                                        />
                                    ) : (
                                        <p className="text-zinc-300 text-sm leading-relaxed whitespace-pre-wrap">{getLocalizedField(mission, 'description')}</p>
                                    )}
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

                            {/* Sector/Category (Editable) */}
                            {isEditing && (
                                <section className="bg-zinc-900/30 border border-zinc-800 rounded-2xl p-5 space-y-4">
                                    <h3 className="text-[10px] font-black text-zinc-500 uppercase tracking-widest flex items-center gap-2">
                                        <ShieldCheck size={14} /> Sector
                                    </h3>
                                    <select
                                        value={editData.sector}
                                        onChange={(e) => setEditData({ ...editData, sector: e.target.value as Sector })}
                                        className="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-4 py-2.5 text-xs font-bold text-white outline-none focus:border-brand-green transition-all"
                                    >
                                        {SECTORS.map(s => (
                                            <option key={s.id} value={s.id}>{s.label[lang]}</option>
                                        ))}
                                    </select>
                                </section>
                            )}

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
                            <section className="bg-zinc-900/30 border border-zinc-800 rounded-2xl relative overflow-hidden group">
                                {/* Subtle Map Background */}
                                {!isEditing && (
                                    <>
                                        <div className="absolute inset-0 z-0 opacity-60 group-hover:opacity-100 transition-all duration-500 pointer-events-none">
                                            <iframe
                                                width="100%"
                                                height="100%"
                                                frameBorder="0"
                                                style={{ border: 0 }}
                                                src={`https://maps.google.com/maps?q=${encodeURIComponent(`${currentBuilding?.address}, ${currentBuilding?.city}`)}&t=&z=13&ie=UTF8&iwloc=&output=embed`}
                                            ></iframe>
                                        </div>
                                        <div className="absolute inset-0 bg-gradient-to-t from-zinc-950/80 to-zinc-950/20 z-0 pointer-events-none"></div>
                                    </>
                                )}

                                <div className="relative z-10 p-5 space-y-4">
                                    <h3 className="text-[10px] font-black text-zinc-500 uppercase tracking-widest flex items-center gap-2">
                                        <MapPin size={14} /> Location Details
                                    </h3>
                                    <div className="space-y-3">
                                        {isEditing ? (
                                            <div className="space-y-3">
                                                <div className="flex flex-col gap-1.5">
                                                    <span className="text-[9px] font-black text-zinc-600 uppercase tracking-widest">Assign Building</span>
                                                    <select
                                                        value={editData.buildingId}
                                                        onChange={(e) => setEditData({ ...editData, buildingId: e.target.value })}
                                                        className="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-4 py-2.5 text-xs font-bold text-white outline-none focus:border-brand-green transition-all"
                                                    >
                                                        <option value="">{t.select_building || "Select Building"}</option>
                                                        {buildings.map(b => (
                                                            <option key={b.id} value={b.id}>{b.address}</option>
                                                        ))}
                                                    </select>
                                                </div>
                                            </div>
                                        ) : (
                                            <div className="flex items-center justify-between gap-3">
                                                <div className="flex gap-3">
                                                    <div className="w-8 h-8 rounded-lg bg-zinc-900/80 border border-zinc-800 flex items-center justify-center shrink-0 backdrop-blur-md">
                                                        <MapPin size={16} className="text-zinc-500" />
                                                    </div>
                                                    <div>
                                                        <p className="text-xs font-bold text-white shadow-black drop-shadow-sm">{currentBuilding?.address || 'Standalone Request'}</p>
                                                        <p className="text-[10px] text-zinc-400 font-bold">{currentBuilding?.city || 'No city info'}</p>
                                                    </div>
                                                </div>
                                                {currentBuilding?.address && (
                                                    <button
                                                        onClick={() => {
                                                            window.open(`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${currentBuilding?.address}, ${currentBuilding?.city}`)}`, '_blank');
                                                        }}
                                                        className="p-2 bg-zinc-950/80 border border-zinc-800 rounded-lg text-zinc-400 hover:text-brand-green hover:border-brand-green/50 transition-all shrink-0 shadow-lg backdrop-blur-md"
                                                        title={t.viewOnMaps}
                                                    >
                                                        <MapPin size={14} />
                                                    </button>
                                                )}
                                            </div>
                                        )}
                                        {(syndic || mission.extractedSyndicName) && !isEditing && (
                                            <div className="flex gap-3 pt-2 border-t border-zinc-800/50 mt-2">
                                                <div className="w-8 h-8 rounded-lg bg-zinc-900/80 border border-zinc-800 flex items-center justify-center shrink-0 backdrop-blur-md">
                                                    <ShieldCheck size={16} className="text-zinc-500" />
                                                </div>
                                                <div>
                                                    <p className="text-[10px] font-black text-zinc-400 uppercase tracking-widest drop-shadow-sm">{t.syndic}</p>
                                                    <p className="text-xs font-bold text-white shadow-black drop-shadow-sm">{syndic ? syndic.companyName : mission.extractedSyndicName}</p>
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
                                    {isEditing ? (
                                        <div className="space-y-4">
                                            <div className="space-y-1.5">
                                                <label className="text-[9px] font-black text-zinc-600 uppercase tracking-widest">{t.name || "Name"}</label>
                                                <input
                                                    type="text"
                                                    value={editData.onSiteContactName}
                                                    onChange={(e) => setEditData({ ...editData, onSiteContactName: e.target.value })}
                                                    className="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-4 py-2.5 text-xs font-bold text-white outline-none focus:border-brand-green"
                                                    placeholder="Name"
                                                />
                                            </div>
                                            <div className="space-y-1.5">
                                                <label className="text-[9px] font-black text-zinc-600 uppercase tracking-widest">{t.phone || "Phone"}</label>
                                                <input
                                                    type="text"
                                                    value={editData.onSiteContactPhone}
                                                    onChange={(e) => setEditData({ ...editData, onSiteContactPhone: e.target.value })}
                                                    className="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-4 py-2.5 text-xs font-bold text-white outline-none focus:border-brand-green"
                                                    placeholder="Phone"
                                                />
                                            </div>
                                            <div className="space-y-1.5">
                                                <label className="text-[9px] font-black text-zinc-600 uppercase tracking-widest">{t.email || "Email"}</label>
                                                <input
                                                    type="email"
                                                    value={editData.onSiteContactEmail}
                                                    onChange={(e) => setEditData({ ...editData, onSiteContactEmail: e.target.value })}
                                                    className="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-4 py-2.5 text-xs font-bold text-white outline-none focus:border-brand-green"
                                                    placeholder="Email"
                                                />
                                            </div>
                                        </div>
                                    ) : (
                                        mission.onSiteContactName || mission.onSiteContactPhone || mission.onSiteContactEmail ? (
                                            <>
                                                {mission.onSiteContactName && (
                                                    <div className="flex items-center gap-3">
                                                        <User size={14} className="text-zinc-600" />
                                                        <span className="text-xs font-bold text-zinc-300">{mission.onSiteContactName}</span>
                                                    </div>
                                                )}
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
                                        )
                                    )}
                                </div>
                            </section>

                        </div>
                    </div>
                </div>

                {/* Footer Actions */}
                <div className="p-6 bg-zinc-950 border-t border-zinc-900 flex flex-col gap-4 shrink-0">
                    {isEditing ? (
                        <button
                            onClick={handleSave}
                            disabled={isSaving}
                            className="w-full py-4 bg-brand-green text-brand-black rounded-2xl font-black text-xs uppercase tracking-[0.2em] hover:bg-brand-green-light hover:scale-[1.01] transition-all shadow-xl shadow-brand-green/10 flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            {isSaving ? (
                                <>
                                    <Clock className="animate-spin" size={16} />
                                    SAVING...
                                </>
                            ) : (
                                <>
                                    <Save size={16} />
                                    SAVE UPDATES
                                </>
                            )}
                        </button>
                    ) : (
                        showAdminActions && (
                            <div className="flex gap-4">
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
                        )
                    )}

                    {/* Close hint for mobile */}
                    <div className="md:hidden pt-2 text-center">
                        <button onClick={onClose} className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">
                            Swipe down or tap to close
                        </button>
                    </div>
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
