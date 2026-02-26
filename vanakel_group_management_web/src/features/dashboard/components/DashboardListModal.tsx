
import React, { useMemo, useState } from 'react';
import { X, Search, ChevronRight, AlertCircle } from 'lucide-react';
import { Intervention, Mission, Building, Syndic, Language } from '@/types';
import { TRANSLATIONS, DELAY_REASONS } from '@/utils/constants';

interface DashboardListModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  items: (Intervention | Mission)[];
  buildings: Building[];
  syndics: Syndic[];
  onItemClick: (id: string, type: 'INTERVENTION' | 'MISSION') => void;
  lang: Language;
}

const DashboardListModal: React.FC<DashboardListModalProps> = ({
  isOpen, onClose, title, items, buildings, syndics, onItemClick, lang
}) => {
  const [search, setSearch] = useState('');
  const t = TRANSLATIONS[lang];

  if (!isOpen) return null;

  const filteredItems = items.filter(item => {
    const b = buildings.find(b => b.id === item.buildingId);
    const s = syndics.find(syn => String(syn.id) === String(b?.linkedSyndicId || ('syndicId' in item ? item.syndicId : '')));
    const term = search.toLowerCase();

    return (
      item.title?.toLowerCase().includes(term) ||
      b?.address.toLowerCase().includes(term) ||
      s?.companyName.toLowerCase().includes(term)
    );
  });

  const getStatusBadge = (item: Intervention | Mission) => {
    // Handling Mission statuses
    if ('requestedBy' in item) {
      return <span className="text-[9px] font-black uppercase tracking-wider bg-blue-500/10 text-blue-400 px-1.5 py-0.5 rounded">Mission</span>;
    }

    // Handling Intervention statuses
    const int = item as Intervention;
    if (int.status === 'DELAYED') {
      return <span className="text-[9px] font-black uppercase tracking-wider bg-orange-500/10 text-orange-500 px-1.5 py-0.5 rounded">{t.status_delayed}</span>;
    }
    if (int.status === 'COMPLETED') {
      return <span className="text-[9px] font-black uppercase tracking-wider bg-green-500/10 text-green-500 px-1.5 py-0.5 rounded">{t.status_completed}</span>;
    }
    return <span className="text-[9px] font-black uppercase tracking-wider bg-zinc-800 text-zinc-400 px-1.5 py-0.5 rounded">{t.ongoing}</span>;
  };

  const getDelayLabel = (reasonKey?: string) => {
    if (!reasonKey) return null;
    const r = DELAY_REASONS.find(x => x.id === reasonKey);
    return r ? r[lang as keyof typeof r] : reasonKey;
  };

  return (
    <div className="fixed inset-0 z-[150] flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/80 backdrop-blur-sm" onClick={onClose}></div>
      <div className="bg-zinc-950 border border-zinc-800 w-full max-w-2xl h-[80vh] rounded-2xl shadow-2xl relative z-20 flex flex-col animate-in zoom-in-95 duration-200">

        {/* Header */}
        <div className="px-6 py-4 border-b border-zinc-900 flex justify-between items-center bg-zinc-900/50">
          <div>
            <h3 className="text-lg font-black uppercase tracking-widest text-white">{title}</h3>
            <p className="text-zinc-500 text-xs font-medium">{filteredItems.length} items</p>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-zinc-800 rounded-full text-zinc-500 hover:text-white transition-colors">
            <X size={20} />
          </button>
        </div>

        {/* Search */}
        <div className="p-4 border-b border-zinc-900 bg-zinc-900/30">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500" size={16} />
            <input
              type="text"
              placeholder={t.search}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full bg-zinc-950 border border-zinc-800 pl-10 pr-4 py-2.5 rounded-xl text-sm font-bold text-white focus:border-brand-green outline-none"
            />
          </div>
        </div>

        {/* List */}
        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {filteredItems.length === 0 ? (
            <div className="text-center py-10 text-zinc-500 text-sm">No items found.</div>
          ) : (
            filteredItems.map(item => {
              const b = buildings.find(b => String(b.id) === String(item.buildingId));
              const s = syndics.find(syn => String(syn.id) === String(b?.linkedSyndicId || ('syndicId' in item ? (item as Mission).syndicId : '')));
              const isIntervention = !('requestedBy' in item);

              return (
                <div
                  key={item.id}
                  onClick={() => onItemClick(item.id, isIntervention ? 'INTERVENTION' : 'MISSION')}
                  className="bg-zinc-900/40 border border-zinc-900 p-4 rounded-xl hover:border-brand-green/30 hover:bg-zinc-900 transition-all cursor-pointer group"
                >
                  <div className="flex justify-between items-start mb-2">
                    <div className="min-w-0 pr-4">
                      <div className="flex items-center gap-2 mb-1">
                        {getStatusBadge(item)}
                        <span className="text-[9px] font-bold text-zinc-500 uppercase tracking-wide truncate max-w-[150px]">{item.category}</span>
                      </div>
                      <h4 className="text-sm font-bold text-white truncate">{item.title}{'interventionNumber' in item && item.interventionNumber ? ` – ${item.interventionNumber}` : ''}</h4>

                      {/* Delay Reason Display */}
                      {isIntervention && (item as Intervention).status === 'DELAYED' && (item as Intervention).delayReason && (
                        <div className="mt-1 flex items-center gap-1.5 text-orange-500 text-xs font-medium">
                          <AlertCircle size={12} />
                          <span>{getDelayLabel((item as Intervention).delayReason)}</span>
                        </div>
                      )}

                      <div className="mt-2 flex flex-col gap-0.5">
                        <p className="text-xs text-zinc-400 truncate">{b?.address}, {b?.city}</p>
                        <p className="text-[10px] text-zinc-600 font-bold uppercase tracking-wider">{s?.companyName || t.unassigned || 'No Syndic'}</p>
                      </div>
                    </div>
                    <ChevronRight size={18} className="text-zinc-700 group-hover:text-brand-green transition-colors mt-1" />
                  </div>
                  <div className="flex justify-between items-end border-t border-zinc-800/50 pt-3 mt-1">
                    <span className="text-[9px] text-zinc-600 font-mono">
                      {new Date(('timestamp' in item) ? (item as Mission).timestamp : (item as Intervention).scheduledDate).toLocaleDateString()}
                    </span>
                  </div>
                </div>
              );
            })
          )}
        </div>

      </div>
    </div>
  );
};

export default DashboardListModal;
