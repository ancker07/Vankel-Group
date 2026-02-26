
import React from 'react';
import { CheckCircle2, AlertCircle, FileText } from 'lucide-react';
import { Mission } from '@/types';

interface MissionActionModalProps {
    type: 'APPROVE' | 'REJECT';
    mission: Mission;
    missionDate: string;
    setMissionDate: (date: string) => void;
    onCancel: () => void;
    onConfirm: () => void;
    t: any;
}

const MissionActionModal: React.FC<MissionActionModalProps> = ({
    type,
    mission,
    missionDate,
    setMissionDate,
    onCancel,
    onConfirm,
    t
}) => {
    return (
        <div className="fixed inset-0 z-[160] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-in fade-in duration-200">
            <div className="bg-zinc-950 border border-zinc-800 w-full max-w-sm rounded-2xl shadow-2xl relative z-20 overflow-hidden p-6 text-center">
                <div className={`w-14 h-14 rounded-full flex items-center justify-center mx-auto mb-4 ${type === 'APPROVE' ? 'bg-brand-green/10 text-brand-green' : 'bg-red-500/10 text-red-500'}`}>
                    {type === 'APPROVE' ? <CheckCircle2 size={24} /> : <AlertCircle size={24} />}
                </div>
                <h4 className="text-lg font-bold text-white mb-2">
                    {type === 'APPROVE' ? t.confirm : t.confirmRejectTitle}
                </h4>
                <p className="text-zinc-400 text-sm mb-6 leading-relaxed">
                    {type === 'APPROVE' ? t.confirmApproveMsg : t.confirmRejectMsg}
                </p>
                <div className="mb-4 text-left p-2 bg-zinc-900/50 rounded-lg border border-zinc-800">
                    <p className="text-[10px] font-black uppercase text-zinc-500 mb-1">{t.missionLabel || 'Mission'}</p>
                    <p className="text-xs font-bold text-white truncate">{mission.title}</p>
                </div>

                {mission.documents && mission.documents.length > 0 && (
                    <div className="mb-6 text-left space-y-2">
                        <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest flex items-center gap-1.5">
                            <FileText size={12} /> {t.verify_docs || 'Review Documents'}
                        </label>
                        <div className="space-y-2">
                            {mission.documents.map(doc => (
                                <a
                                    key={doc.id}
                                    href={doc.url}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="flex items-center justify-between p-3 bg-zinc-900 border border-zinc-800 rounded-xl hover:border-brand-green group transition-all"
                                >
                                    <span className="text-xs font-bold text-zinc-400 group-hover:text-white truncate max-w-[200px]">{doc.name}</span>
                                    <span className="text-[10px] font-black text-brand-green uppercase tracking-tighter">{t.view || 'View'}</span>
                                </a>
                            ))}
                        </div>
                    </div>
                )}
                {type === 'APPROVE' && (
                    <div className="mb-6 text-left space-y-1.5">
                        <label className="text-[9px] font-black text-zinc-600 uppercase tracking-widest">{t.interventionDateOptional || "Date d'intervention (optionnel)"}</label>
                        <input
                            type="date"
                            value={missionDate}
                            onChange={e => setMissionDate(e.target.value)}
                            className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2.5 text-sm font-bold text-white focus:border-brand-green outline-none transition-all"
                        />
                    </div>
                )}
                <div className="flex gap-3">
                    <button onClick={onCancel} className="flex-1 py-3 bg-zinc-900 text-zinc-400 border border-zinc-800 rounded-xl font-bold text-xs uppercase tracking-widest hover:bg-zinc-800 hover:text-white transition-colors">{t.btnCancel}</button>
                    <button onClick={onConfirm} className={`flex-1 py-3 rounded-xl font-bold text-xs uppercase tracking-widest transition-colors ${type === 'APPROVE' ? 'bg-brand-green text-brand-black hover:bg-brand-green-light' : 'bg-red-500 text-white hover:bg-red-600'}`}>{type === 'APPROVE' ? t.confirm : t.btnReject}</button>
                </div>
            </div>
        </div>
    );
};

export default MissionActionModal;
