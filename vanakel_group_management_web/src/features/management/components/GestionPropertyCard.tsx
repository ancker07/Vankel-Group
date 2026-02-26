
import React from 'react';
import { Building, Syndic } from '@/types';
import { MapPin, ShieldCheck, ClipboardList } from 'lucide-react';

interface GestionPropertyCardProps {
  building: Building;
  syndic?: Syndic;
  interventionCount: number;
  onClick: () => void;
}

const GestionPropertyCard: React.FC<GestionPropertyCardProps> = ({ building, syndic, interventionCount, onClick }) => {
  return (
    <div className="bg-zinc-950 border border-zinc-800 rounded-2xl overflow-hidden flex flex-col hover:border-zinc-700 transition-all group shadow-lg">
      {/* Thumbnail Section */}
      <div className="h-40 relative overflow-hidden bg-zinc-900">
        {building.imageUrl ? (
          <img
            src={building.imageUrl}
            alt={building.address}
            className="w-full h-full object-cover opacity-80 group-hover:opacity-100 transition-opacity duration-500"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-zinc-700">
            <MapPin size={48} strokeWidth={1} />
          </div>
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-zinc-950 via-transparent to-transparent opacity-90"></div>

        <div className="absolute bottom-3 left-4 right-4">
          <h3 className="text-lg font-bold text-white leading-tight truncate shadow-black drop-shadow-md">{building.address}</h3>
          <div className="flex items-center gap-1.5 mt-1 text-zinc-300 text-xs">
            <MapPin size={12} className="text-brand-green" />
            <span>{building.city}</span>
          </div>
        </div>
      </div>

      {/* Info Content */}
      <div className="p-5 flex-1 flex flex-col">
        <div className="mb-4">
          <p className="text-[10px] uppercase tracking-widest text-zinc-500 font-bold mb-1">Syndic</p>
          <div className="flex items-center gap-2 text-sm text-zinc-300 font-medium">
            <ShieldCheck size={16} className="text-zinc-500" />
            <span className="truncate">{syndic?.companyName || 'Not provided'}</span>
          </div>
        </div>

        <div className="mt-auto pt-4 border-t border-zinc-900 flex items-center justify-between gap-3">
          <div className="bg-brand-green/10 text-brand-green border border-brand-green/20 px-2.5 py-1 rounded-md text-[10px] font-black uppercase tracking-wider flex items-center gap-1.5">
            <ClipboardList size={12} />
            <span>{interventionCount} Interventions</span>
          </div>

          <button
            onClick={onClick}
            className="bg-zinc-100 text-zinc-950 hover:bg-white hover:scale-105 transition-all text-[10px] font-black uppercase tracking-wide px-3 py-2 rounded-lg shadow-xl shadow-white/5"
          >
            Interventions effectuées
          </button>
        </div>
      </div>
    </div>
  );
};

export default GestionPropertyCard;
