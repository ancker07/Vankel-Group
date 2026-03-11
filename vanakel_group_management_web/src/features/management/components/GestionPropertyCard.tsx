import React, { useState } from 'react';
import { Building, Syndic, Language } from '@/types';
import { MapPin, ShieldCheck, ClipboardList } from 'lucide-react';
import { TRANSLATIONS } from '@/utils/constants';

interface GestionPropertyCardProps {
  building: Building;
  syndic?: Syndic;
  interventionCount: number;
  onClick: () => void;
  lang: Language;
}

const GestionPropertyCard: React.FC<GestionPropertyCardProps> = ({ building, syndic, interventionCount, onClick, lang }) => {
  const t = TRANSLATIONS[lang];
  const [isImgLoading, setIsImgLoading] = useState(true);

  return (
    <div className="bg-zinc-950 border border-zinc-800 rounded-2xl overflow-hidden flex flex-col hover:border-zinc-700 transition-all group shadow-lg">
      {/* Thumbnail Section */}
      <div className="h-40 relative overflow-hidden bg-zinc-900 group">
        <div className="absolute inset-0 z-0">
          <iframe
            width="100%"
            height="100%"
            frameBorder="0"
            style={{ border: 0, opacity: 0.6 }}
            src={`https://maps.google.com/maps?q=${encodeURIComponent(`${building.address}, ${building.city}`)}&t=&z=13&ie=UTF8&iwloc=&output=embed`}
            allowFullScreen
            className="pointer-events-none group-hover:opacity-80 transition-opacity duration-500"
          ></iframe>
        </div>

        <div className="absolute inset-0 bg-gradient-to-t from-zinc-950 via-zinc-950/20 to-transparent z-10"></div>

        <div className="absolute bottom-3 left-4 right-4 z-20 flex justify-between items-end gap-2">
          <div className="min-w-0 flex-1">
            <h3 className="text-lg font-bold text-white leading-tight truncate shadow-black drop-shadow-md">{building.address}</h3>
            <div className="flex items-center gap-1.5 mt-1 text-zinc-300 text-xs">
              <MapPin size={12} className="text-brand-green" />
              <span>{building.city}</span>
            </div>
          </div>
          <button
            onClick={(e) => {
              e.stopPropagation();
              window.open(`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${building.address}, ${building.city}`)}`, '_blank');
            }}
            className="p-2 bg-zinc-900/80 border border-zinc-700/50 rounded-xl text-zinc-400 hover:text-brand-green hover:border-brand-green/30 transition-all shadow-lg backdrop-blur-sm"
            title={t.viewOnMaps}
          >
            <MapPin size={14} />
          </button>
        </div>
      </div>

      {/* Info Content */}
      <div className="p-5 flex-1 flex flex-col">
        <div className="mb-4">
          <p className="text-[10px] uppercase tracking-widest text-zinc-500 font-bold mb-1">{t.syndic}</p>
          <div className="flex items-center gap-2 text-sm text-zinc-300 font-medium">
            <ShieldCheck size={16} className="text-zinc-500" />
            <span className="truncate">{syndic?.companyName || t.notProvided}</span>
          </div>
        </div>

        <div className="mt-auto pt-4 border-t border-zinc-900 flex items-center justify-between gap-3">
          <div className="bg-brand-green/10 text-brand-green border border-brand-green/20 px-2.5 py-1 rounded-md text-[10px] font-black uppercase tracking-wider flex items-center gap-1.5">
            <ClipboardList size={12} />
            <span>{interventionCount} {t.tabs_history}</span>
          </div>

          <button
            onClick={onClick}
            className="bg-zinc-100 text-zinc-950 hover:bg-white hover:scale-105 transition-all text-[10px] font-black uppercase tracking-wide px-3 py-2 rounded-lg shadow-xl shadow-white/5"
          >
            {t.full_history}
          </button>
        </div>
      </div>
    </div>
  );
};

export default GestionPropertyCard;
