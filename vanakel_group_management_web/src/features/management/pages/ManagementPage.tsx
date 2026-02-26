
import React, { useState, useMemo } from 'react';
import { Building, Syndic, Intervention, Professional, Language } from '@/types';
import { Search, Filter, Briefcase, ChevronDown } from 'lucide-react';
import { TRANSLATIONS } from '@/utils/constants';
import GestionPropertyCard from '../components/GestionPropertyCard';
import GestionDetailsModal from '../components/GestionDetailsModal';

interface GestionPageProps {
  buildings: Building[];
  syndics: Syndic[];
  interventions: Intervention[];
  professionals: Professional[];
  lang: Language;
}

const GestionPage: React.FC<GestionPageProps> = ({ buildings, syndics, interventions, professionals, lang }) => {
  const t = TRANSLATIONS[lang];
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedBuildingId, setSelectedBuildingId] = useState<string | null>(null);

  // Syndic Filter State
  const [selectedSyndicId, setSelectedSyndicId] = useState<string>('ALL');

  // Group completed interventions by building
  const completedInterventions = useMemo(() => {
    return interventions.filter(i => i.status === 'COMPLETED');
  }, [interventions]);

  const buildingInterventionMap = useMemo(() => {
    const map: Record<string, Intervention[]> = {};
    completedInterventions.forEach(i => {
      if (!map[i.buildingId]) map[i.buildingId] = [];
      map[i.buildingId].push(i);
    });
    return map;
  }, [completedInterventions]);

  // Filter buildings: Must have at least one completed intervention + match search + match syndic filter
  const filteredBuildings = useMemo(() => {
    return buildings.filter(b => {
      // 1. Must have completed interventions
      const hasCompleted = buildingInterventionMap[b.id] && buildingInterventionMap[b.id].length > 0;
      if (!hasCompleted) return false;

      // 2. Syndic Filter
      if (selectedSyndicId !== 'ALL' && b.linkedSyndicId !== selectedSyndicId) {
        return false;
      }

      // 3. Search Filter
      const q = searchQuery.toLowerCase();
      const syndic = syndics.find(s => s.id === b.linkedSyndicId);

      const matchesSearch =
        b.address.toLowerCase().includes(q) ||
        b.city.toLowerCase().includes(q) ||
        (syndic?.companyName.toLowerCase().includes(q) || false);

      return matchesSearch;
    });
  }, [buildings, buildingInterventionMap, searchQuery, syndics, selectedSyndicId]);

  const selectedBuilding = selectedBuildingId ? buildings.find(b => b.id === selectedBuildingId) : null;
  const selectedBuildingSyndic = selectedBuilding ? syndics.find(s => s.id === selectedBuilding.linkedSyndicId) : undefined;
  const selectedBuildingInterventions = selectedBuildingId
    ? (buildingInterventionMap[selectedBuildingId] || []).sort((a, b) => new Date(b.scheduledDate).getTime() - new Date(a.scheduledDate).getTime())
    : [];

  return (
    <div className="min-h-full space-y-8 animate-in fade-in duration-500">

      {/* Header & Controls */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-3xl font-black text-white tracking-tight">{t.gestion_title}</h1>
          <p className="text-zinc-500 text-sm font-medium mt-1">{t.gestion_subtitle}</p>
        </div>

        <div className="flex flex-col sm:flex-row gap-3 w-full md:w-auto">
          {/* Syndic Filter Dropdown */}
          <div className="relative group w-full md:w-60">
            <select
              value={selectedSyndicId}
              onChange={(e) => setSelectedSyndicId(e.target.value)}
              className="w-full appearance-none bg-zinc-900 border border-zinc-800 text-sm font-bold pl-4 pr-10 py-3 rounded-xl focus:border-brand-green outline-none text-white cursor-pointer hover:border-zinc-700 transition-all"
            >
              <option value="ALL">{t.all_syndics}</option>
              {syndics.map(s => (
                <option key={s.id} value={s.id}>{s.companyName}</option>
              ))}
            </select>
            <ChevronDown className="absolute right-4 top-1/2 -translate-y-1/2 text-zinc-500 pointer-events-none" size={16} />
          </div>

          <div className="relative group w-full md:w-80">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500 group-hover:text-white transition-colors" size={18} />
            <input
              type="text"
              placeholder={t.search}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-zinc-900 border border-zinc-800 text-sm font-medium pl-10 pr-4 py-3 rounded-xl focus:border-brand-green focus:ring-1 focus:ring-brand-green/50 outline-none transition-all"
            />
          </div>
        </div>
      </div>

      {/* Main Grid Content */}
      {filteredBuildings.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-4 gap-6">
          {filteredBuildings.map(building => {
            const syndic = syndics.find(s => s.id === building.linkedSyndicId);
            const count = buildingInterventionMap[building.id]?.length || 0;
            return (
              <GestionPropertyCard
                key={building.id}
                building={building}
                syndic={syndic}
                interventionCount={count}
                onClick={() => setSelectedBuildingId(building.id)}
              />
            );
          })}
        </div>
      ) : (
        <div className="flex flex-col items-center justify-center py-20 border border-dashed border-zinc-800 rounded-3xl bg-zinc-900/20">
          <Briefcase size={48} className="text-zinc-700 mb-4" />
          <h3 className="text-lg font-bold text-white">{t.no_properties_title}</h3>
          <p className="text-zinc-500 text-sm max-w-md text-center mt-2">
            {t.no_properties_desc}
          </p>
        </div>
      )}

      {/* Detail Modal */}
      {selectedBuilding && (
        <GestionDetailsModal
          building={selectedBuilding}
          syndic={selectedBuildingSyndic}
          interventions={selectedBuildingInterventions}
          onClose={() => setSelectedBuildingId(null)}
          lang={lang}
        />
      )}
    </div>
  );
};

export default GestionPage;
