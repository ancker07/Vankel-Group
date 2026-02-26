
import React from 'react';
import { Building, Professional, Syndic, Language } from '../types';
import { MapPin, User, ChevronRight, ShieldCheck, RotateCcw } from 'lucide-react';
import { TRANSLATIONS } from '../constants';

interface BuildingCardProps {
  building: Building;
  pro?: Professional;
  syndic?: Syndic;
  onClick: () => void;
  lang?: Language;
  hasActiveMaintenance?: boolean;
}

const BuildingCard: React.FC<BuildingCardProps> = ({ building, pro, syndic, onClick, lang = 'FR', hasActiveMaintenance }) => {
  const t = TRANSLATIONS[lang];
  return (
    <div 
      onClick={onClick}
      className="bg-zinc-950 border border-zinc-800 rounded-2xl overflow-hidden group hover:border-brand-green/50 cursor-pointer transition-all hover:translate-y-[-4px] shadow-lg hover:shadow-brand-green/10 relative"
    >
      {/* Maintenance Badge */}
      {hasActiveMaintenance && (
        <div className="absolute top-2 right-2 z-20 bg-orange-500 text-white w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-black shadow-lg border border-orange-400" title={t.maintenance}>
          E
        </div>
      )}

      <div className="flex h-24 md:h-32 border-b border-zinc-900/50">
        <div className="w-1/2 relative overflow-hidden border-r border-zinc-900/50">
          <img src={building.imageUrl} alt={building.address} className="w-full h-full object-cover grayscale-[0.5] group-hover:grayscale-0 transition-all duration-500" />
          <div className="absolute inset-0 bg-gradient-to-t from-zinc-950/20 to-transparent"></div>
          <div className="absolute bottom-1 left-1 flex items-center gap-1">
            <span className={`text-[7px] md:text-[8px] font-black px-1 py-0.5 rounded uppercase tracking-tighter ${pro ? 'bg-brand-green text-brand-black' : 'bg-zinc-800 text-zinc-500'}`}>
              {pro ? `${t.pro}: ${pro.companyName.split(' ')[0]}` : t.unassigned}
            </span>
          </div>
        </div>
        <div className="w-1/2 p-2.5 md:p-3 flex flex-col justify-center bg-zinc-900/10">
          <div className="flex items-center gap-1.5 mb-0.5">
            <ShieldCheck size={10} className="text-brand-green shrink-0" />
            <p className="text-[8px] font-black text-zinc-600 uppercase tracking-widest">{t.syndic}</p>
          </div>
          <p className="text-[10px] md:text-xs font-bold text-white leading-tight truncate">
            {syndic ? syndic.companyName : t.noneLinked}
          </p>
        </div>
      </div>

      <div className="p-4 space-y-3">
        <div>
          <h4 className="text-sm md:text-base font-bold truncate group-hover:text-brand-green transition-colors">{building.address}</h4>
          <div className="flex items-center gap-1 text-zinc-500 text-[10px] md:text-xs font-medium">
            <MapPin size={12} />
            <span>{building.city}, BE</span>
          </div>
        </div>
        
        <div className="flex items-center gap-3 py-2 border-y border-zinc-900">
          <div className="w-7 h-7 rounded-full bg-zinc-900 flex items-center justify-center border border-zinc-800 shrink-0">
            <User size={12} className="text-zinc-500" />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-[8px] text-zinc-600 font-black uppercase tracking-[0.1em]">{t.primaryTenant}</p>
            <p className="text-xs font-bold truncate">
              {building.tenants.length > 0 ? `${building.tenants[0].firstName} ${building.tenants[0].lastName}` : t.missingInfo}
            </p>
          </div>
        </div>

        <div className="flex items-center justify-between pt-1">
          <div className="flex -space-x-1.5">
             {[1,2].map(i => (
               <div key={i} className="w-5 h-5 rounded-full bg-zinc-800 border-2 border-zinc-950 flex items-center justify-center text-[7px] font-bold shrink-0">
                 {i}
               </div>
             ))}
          </div>
          <span className="text-[10px] font-black text-zinc-500 group-hover:text-brand-green flex items-center gap-1 transition-all uppercase tracking-widest">
            {t.details} <ChevronRight size={12} className="group-hover:translate-x-1 transition-transform"/>
          </span>
        </div>
      </div>
    </div>
  );
};

export default BuildingCard;
