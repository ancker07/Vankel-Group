import React from 'react';
import { Intervention, Mission, Language } from '@/types';
import { X, Calendar, MapPin, User, FileText, Download, CheckCircle2, AlertCircle, Clock, ShieldCheck, Phone, Mail } from 'lucide-react';
import { TRANSLATIONS } from '@/utils/constants';

interface HistoryEntryDetailModalProps {
  entry: Intervention | Mission;
  buildingAddress: string;
  buildingCity: string;
  onClose: () => void;
  lang: Language;
}

const HistoryEntryDetailModal: React.FC<HistoryEntryDetailModalProps> = ({ entry, buildingAddress, buildingCity, onClose, lang }) => {
  const t = TRANSLATIONS[lang];
  const isMission = (entry as any).requestedBy !== undefined;
  const entryType = isMission ? 'MISSION' : 'INTERVENTION';
  const date = new Date((entry as any).createdAt || (entry as any).timestamp || (entry as any).scheduledDate);

  const handleDownload = (docName: string, url?: string) => {
    if (url) {
      window.open(url, '_blank');
      return;
    }
    // Mock download logic as seen in GestionDetailsModal
    alert(`Downloading ${docName}...`);
  };

  return (
    <div className="fixed inset-0 z-[110] flex items-center justify-center p-4 bg-black/60 backdrop-blur-md animate-in fade-in zoom-in duration-200">
      <div className="bg-zinc-950 border border-zinc-800 w-full max-w-3xl rounded-3xl shadow-2xl flex flex-col relative overflow-hidden">
        
        {/* Header with Background Image */}
        <div className="relative h-48 bg-zinc-900 overflow-hidden">
           <img 
            src={(entry as any).imageUrl || "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=2070&auto=format&fit=crop"} 
            className="w-full h-full object-cover opacity-50" 
            alt="Detail Header" 
          />
          <div className="absolute inset-0 bg-gradient-to-t from-zinc-950 via-zinc-950/40 to-transparent"></div>
          
          <button 
            onClick={onClose}
            className="absolute top-4 right-4 bg-black/50 hover:bg-black text-white p-2 rounded-full transition-all z-20"
          >
            <X size={20} />
          </button>

          <div className="absolute bottom-6 left-8 right-8">
            <h2 className="text-3xl font-black text-white mb-2 leading-tight">{entry.title || (isMission ? 'Mission Request' : 'Manual Intervention')}</h2>
            <div className="flex flex-wrap items-center gap-4 text-sm font-medium text-zinc-300">
              <span className="flex items-center gap-1.5"><MapPin size={14} className="text-brand-green" /> {buildingAddress}, {buildingCity}</span>
            </div>
          </div>
        </div>

        {/* Content Area */}
        <div className="p-8 space-y-8 max-h-[60vh] overflow-y-auto custom-scrollbar">
          
          {/* Status & Contact Banner */}
          <div className="bg-brand-green/5 border border-brand-green/20 rounded-2xl p-5 flex flex-col md:flex-row gap-6">
            <div className="flex-1 space-y-4">
               <h3 className="text-[10px] font-black uppercase tracking-widest text-brand-green flex items-center gap-2">
                <ShieldCheck size={14} /> {t.syndic_contact_title}
              </h3>
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-full bg-brand-green/10 border border-brand-green/20 flex items-center justify-center text-brand-green shrink-0">
                  <User size={20} />
                </div>
                <div>
                  <p className="text-brand-green font-bold text-sm">{(entry as any).onSiteContactName || t.notProvided}</p>
                  <p className="text-brand-green/70 text-xs">ON-SITE CONTACT</p>
                </div>
              </div>
            </div>

            <div className="md:w-px md:h-16 bg-brand-green/20"></div>

            <div className="flex-1 flex flex-col justify-center space-y-2">
              <div className="flex items-center gap-2 text-sm text-brand-green/80">
                <Phone size={14} className="text-brand-green" />
                <span>{(entry as any).onSiteContactPhone || '--'}</span>
              </div>
              <div className="flex items-center gap-2 text-sm text-brand-green/80">
                <Mail size={14} className="text-brand-green" />
                <span className="truncate">{(entry as any).onSiteContactEmail || '--'}</span>
              </div>
            </div>
          </div>

          {/* Description Section */}
          <div className="space-y-4">
             <h3 className="text-[10px] font-black uppercase tracking-widest text-zinc-500 flex items-center gap-2">
              <FileText size={14} /> {t.description_label || 'DESCRIPTION'}
            </h3>
            <div className="bg-zinc-900/40 p-5 rounded-2xl border border-zinc-800">
              <p className="text-zinc-300 leading-relaxed italic">
                {entry.description || "No specific instructions or description provided for this activity."}
              </p>
            </div>
          </div>

          {/* Intervention Details / Documents */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="space-y-4">
               <h3 className="text-[10px] font-black uppercase tracking-widest text-zinc-500 flex items-center gap-2">
                <Calendar size={14} /> Activity Info
              </h3>
              <div className="space-y-3">
                <div className="flex justify-between items-center text-sm py-2 border-b border-zinc-900">
                  <span className="text-zinc-500">Scheduled Date</span>
                  <span className="text-white font-bold">{date.toLocaleDateString()}</span>
                </div>
                <div className="flex justify-between items-center text-sm py-2 border-b border-zinc-900">
                  <span className="text-zinc-500">Activity Type</span>
                  <span className="text-brand-green font-black tracking-widest text-[10px] uppercase">{entryType}</span>
                </div>
                <div className="flex justify-between items-center text-sm py-2">
                  <span className="text-zinc-500">Status</span>
                  <span className={`flex items-center gap-1.5 font-bold ${
                    entry.status === 'COMPLETED' ? 'text-green-500' : 'text-orange-500'
                  }`}>
                    {entry.status === 'COMPLETED' ? <CheckCircle2 size={14} /> : <AlertCircle size={14} />}
                    {entry.status}
                  </span>
                </div>
              </div>
            </div>

            <div className="space-y-4">
               <h3 className="text-[10px] font-black uppercase tracking-widest text-zinc-500 flex items-center gap-2">
                <FileText size={14} /> Attached Documents
              </h3>
              <div className="space-y-2">
                {(entry.documents || []).length === 0 ? (
                  <p className="text-zinc-600 text-xs italic p-4 text-center border border-dashed border-zinc-800 rounded-xl">No documents attached.</p>
                ) : (
                  (entry.documents || []).map(doc => (
                    <button
                      key={doc.id}
                      onClick={() => handleDownload(doc.name, doc.url)}
                      className="flex items-center justify-between w-full px-4 py-3 bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 rounded-xl group transition-all text-xs font-bold text-zinc-300 hover:text-white"
                    >
                      <span className="flex items-center gap-3">
                        <FileText size={16} className="text-zinc-500" /> {doc.name}
                      </span>
                      <Download size={16} className="text-zinc-600 group-hover:text-brand-green shrink-0" />
                    </button>
                  ))
                )}
              </div>
            </div>
          </div>
        </div>
        
        {/* Footer Actions */}
        <div className="p-6 bg-zinc-900/50 border-t border-zinc-800 flex justify-end gap-3">
           <button
            onClick={onClose}
            className="px-6 py-2.5 bg-zinc-800 hover:bg-zinc-700 text-white rounded-xl text-sm font-bold transition-all"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};

export default HistoryEntryDetailModal;
