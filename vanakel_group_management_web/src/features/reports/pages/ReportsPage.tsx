import React, { useState, useMemo } from 'react';
import { Intervention, Building, Professional, Syndic, Language } from '@/types';
import { Search, Download, Eye, ChevronRight, FileText, Calendar, CheckCircle2, MapPin } from 'lucide-react';
import { TRANSLATIONS } from '@/utils/constants';

interface ReportsPageProps {
  interventions: Intervention[];
  buildings: Building[];
  professionals: Professional[];
  syndics: Syndic[];
  onViewIntervention: (id: string) => void;
  lang: Language;
}

const ReportsPage: React.FC<ReportsPageProps> = ({
  interventions, buildings, professionals, syndics, onViewIntervention, lang
}) => {
  const t = TRANSLATIONS[lang];
  const [filterSearch, setFilterSearch] = useState('');
  const [visibleCount, setVisibleCount] = useState(20);

  // Sorting: Newest createdAt first, fallback to scheduledDate
  const sortedInterventions = useMemo(() => {
    return [...interventions].sort((a, b) => {
      const dateA = new Date(a.createdAt || a.scheduledDate).getTime();
      const dateB = new Date(b.createdAt || b.scheduledDate).getTime();
      return dateB - dateA;
    });
  }, [interventions]);

  // Latest Slips (Top 10) - Filtered for COMPLETED only
  const latestSlips = sortedInterventions.filter(i => i.status === 'COMPLETED').slice(0, 10);

  // Filtered History - ONLY COMPLETED
  const filteredHistory = useMemo(() => {
    return sortedInterventions.filter(i => {
      // STRICT RULE: ONLY COMPLETED
      if (i.status !== 'COMPLETED') return false;

      const b = buildings.find(build => build.id === i.buildingId);
      const searchLower = filterSearch.toLowerCase();
      const matchesSearch =
        i.title.toLowerCase().includes(searchLower) ||
        (i.id && i.id.toLowerCase().includes(searchLower)) ||
        (b?.address.toLowerCase().includes(searchLower)) ||
        (b?.city.toLowerCase().includes(searchLower));

      return matchesSearch;
    });
  }, [sortedInterventions, filterSearch, buildings]);

  const displayedHistory = filteredHistory.slice(0, visibleCount);

  // Stats - Show counts relative to the History view (Completed)
  const stats = {
    total: interventions.length,
    completed: interventions.filter(i => i.status === 'COMPLETED').length,
  };

  const handleDownloadPDF = () => {
    try {
      const validPdfBase64 = "JVBERi0xLjcKCjEgMCBvYmogPDwvVHlwZS9DYXRhbG9nL1BhZ2VzIDIgMCBSPj4gZW5kb2JqCjIgMCBvYmogPDwvVHlwZS9QYWdlcy9LaWRzWzMgMCBSXS9Db3VudCAxPj4gZW5kb2JqCjMgMCBvYmogPDwvVHlwZS9QYWdlL01lZGlhQm94WzAgMCA1OTUgODQyXS9QYXJlbnQgMiAwIFIvUmVzb3VyY2VzPDw+Pi9Db250ZW50cyA0IDAgUj4+IGVuZG9iago0IDAgb2JqIDw8L0xlbmd0aCAwPj4gc3RyZWFtCmVuZHN0cmVhbQplbmRvYmoKeHJlZgowIDUKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDEwIDAwMDAwIG4gCjAwMDAwMDAwNjAgMDAwMDAgbiAKMDAwMDAwMDExNyAwMDAwMCBuIAowMDAwMDAwMjE4IDAwMDAwIG4gCnRyYWlsZXIgPDwvU2l6ZSA1L1Jvb3QgMSAwIFI+PgpzdGFydHhyZWYKMjY0CiUlRU9G";
      const cleanBase64 = validPdfBase64.replace(/\s/g, '');
      const byteCharacters = atob(cleanBase64);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      const blob = new Blob([byteArray], { type: 'application/pdf' });
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `Intervention_Report_${new Date().toISOString().split('T')[0]}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);
    } catch (e) {
      alert("PDF Generation Failed");
    }
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-500 pb-12">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white">{t.reports_title}</h2>
          <p className="text-zinc-500 text-sm mt-1">{t.reports_subtitle}</p>
        </div>
        <div className="flex gap-4 text-xs font-medium text-zinc-400 bg-zinc-950 p-2 rounded-xl border border-zinc-800">
          <div className="flex flex-col items-center px-2">
            <span className="text-white font-bold">{stats.total}</span>
            <span className="text-[9px] uppercase tracking-wider">{t.total}</span>
          </div>
          <div className="w-px bg-zinc-800"></div>
          <div className="flex flex-col items-center px-2 text-green-500">
            <span className="font-bold">{stats.completed}</span>
            <span className="text-[9px] uppercase tracking-wider">{t.completed}</span>
          </div>
        </div>
      </div>

      {/* Latest Slips Panel */}
      <section className="bg-zinc-950 border border-zinc-800 rounded-2xl overflow-hidden">
        <div className="px-6 py-4 border-b border-zinc-800 flex items-center justify-between bg-zinc-900/50">
          <h3 className="font-bold text-white flex items-center gap-2">
            <FileText size={18} className="text-brand-green" /> {t.latest_slips}
          </h3>
        </div>
        <div className="p-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {latestSlips.length === 0 ? (
            <div className="col-span-full text-center py-8 text-zinc-500 text-sm">
              No completed slips available.
            </div>
          ) : (
            latestSlips.map(slip => {
              const building = buildings.find(b => b.id === slip.buildingId);
              return (
                <div key={slip.id} className="bg-zinc-900/30 border border-zinc-800 p-4 rounded-xl hover:border-zinc-700 transition-all group flex flex-col gap-3">
                  <div className="flex justify-between items-start">
                    <div className="min-w-0">
                      <p className="text-[10px] text-zinc-500 font-mono mb-1">{slip.id}</p>
                      <h4 className="font-bold text-sm text-white truncate" title={slip.title}>{slip.title}</h4>
                    </div>
                    <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider bg-green-500/10 text-green-500 border border-green-500/20">
                      <CheckCircle2 size={10} /> {t.status_completed}
                    </span>
                  </div>

                  <div className="flex items-center gap-2 text-xs text-zinc-400">
                    <MapPin size={12} className="shrink-0" />
                    <span className="truncate">{building?.address || 'Unknown Address'}</span>
                  </div>

                  <div className="mt-auto pt-3 border-t border-zinc-800/50 flex items-center justify-between">
                    <span className="text-[10px] text-zinc-600 font-medium">
                      {new Date(slip.createdAt || slip.scheduledDate).toLocaleDateString()}
                    </span>
                    <button
                      onClick={() => onViewIntervention(slip.id)}
                      className="text-[10px] font-black uppercase tracking-widest text-brand-green hover:underline flex items-center gap-1"
                    >
                      {t.view} <ChevronRight size={10} />
                    </button>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </section>

      {/* Full History Table */}
      <section className="bg-zinc-950 border border-zinc-800 rounded-2xl overflow-hidden flex flex-col">
        <div className="px-6 py-4 border-b border-zinc-800 bg-zinc-900/50 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
          <h3 className="font-bold text-white flex items-center gap-2">
            <Calendar size={18} className="text-zinc-400" /> {t.full_history}
          </h3>

          <div className="flex flex-col sm:flex-row gap-3 w-full md:w-auto">
            {/* Search */}
            <div className="relative group">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500 group-hover:text-white transition-colors" size={14} />
              <input
                type="text"
                placeholder={t.search_placeholder}
                value={filterSearch}
                onChange={(e) => setFilterSearch(e.target.value)}
                className="bg-zinc-900 border border-zinc-800 text-xs font-medium pl-9 pr-4 py-2 rounded-lg focus:border-brand-green outline-none w-full sm:w-64 text-white placeholder:text-zinc-600"
              />
            </div>

            {/* Status Filter Removed - Strict View */}
          </div>
        </div>

        {/* Desktop Table Header */}
        <div className="hidden md:grid grid-cols-12 gap-4 px-6 py-3 bg-zinc-900/30 text-[10px] font-black uppercase tracking-widest text-zinc-500 border-b border-zinc-800">
          <div className="col-span-2">{t.slip_id}</div>
          <div className="col-span-3">{t.interventionTitle}</div>
          <div className="col-span-3">{t.building_header}</div>
          <div className="col-span-2">{t.created_at}</div>
          <div className="col-span-2 text-right">{t.status}</div>
        </div>

        <div className="divide-y divide-zinc-800/50">
          {displayedHistory.length === 0 ? (
            <div className="p-12 text-center">
              <p className="text-zinc-500 text-sm mb-4">{t.no_interventions_yet}</p>
            </div>
          ) : (
            displayedHistory.map(item => {
              const building = buildings.find(b => b.id === item.buildingId);
              return (
                <div key={item.id} className="group hover:bg-zinc-900/30 transition-colors">
                  {/* Desktop Row */}
                  <div className="hidden md:grid grid-cols-12 gap-4 px-6 py-4 items-center">
                    <div className="col-span-2 text-xs font-mono text-zinc-500 truncate">{item.id}</div>
                    <div className="col-span-3 font-bold text-white text-sm truncate pr-4" title={item.title}>{item.title}</div>
                    <div className="col-span-3 text-xs text-zinc-400 truncate pr-4">
                      <span className="block text-zinc-300 font-medium truncate">{building?.address}</span>
                      <span className="text-[10px] text-zinc-600">{building?.city}</span>
                    </div>
                    <div className="col-span-2 text-xs text-zinc-500">
                      {new Date(item.createdAt || item.scheduledDate).toLocaleDateString()}
                    </div>
                    <div className="col-span-2 flex justify-end gap-3 items-center">
                      <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider bg-green-500/10 text-green-500 border border-green-500/20">
                        <CheckCircle2 size={10} /> {t.status_completed}
                      </span>
                      <button onClick={() => onViewIntervention(item.id)} className="p-1.5 text-zinc-500 hover:text-white bg-zinc-900 hover:bg-zinc-800 rounded-lg transition-all" title={t.view}>
                        <Eye size={14} />
                      </button>
                      <button onClick={handleDownloadPDF} className="p-1.5 text-zinc-500 hover:text-brand-green bg-zinc-900 hover:bg-zinc-800 rounded-lg transition-all" title={t.download_pdf}>
                        <Download size={14} />
                      </button>
                    </div>
                  </div>

                  {/* Mobile Card */}
                  <div className="md:hidden p-4 flex flex-col gap-3">
                    <div className="flex justify-between items-start">
                      <div>
                        <span className="text-[10px] font-mono text-zinc-500 block mb-1">{item.id}</span>
                        <h4 className="font-bold text-white text-sm">{item.title}</h4>
                      </div>
                      <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider bg-green-500/10 text-green-500 border border-green-500/20">
                        <CheckCircle2 size={10} /> {t.status_completed}
                      </span>
                    </div>
                    <div className="text-xs text-zinc-400">
                      <MapPin size={12} className="inline mr-1 text-zinc-600" />
                      {building?.address}, {building?.city}
                    </div>
                    <div className="flex justify-between items-center pt-2 border-t border-zinc-800/50 mt-1">
                      <span className="text-[10px] text-zinc-600">{new Date(item.createdAt || item.scheduledDate).toLocaleDateString()}</span>
                      <div className="flex gap-2">
                        <button onClick={handleDownloadPDF} className="p-2 bg-zinc-900 rounded-lg text-zinc-400 hover:text-white"><Download size={14} /></button>
                        <button onClick={() => onViewIntervention(item.id)} className="px-3 py-2 bg-zinc-900 rounded-lg text-xs font-bold text-white hover:bg-brand-green hover:text-black transition-colors">{t.view}</button>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {filteredHistory.length > visibleCount && (
          <div className="p-4 border-t border-zinc-800 bg-zinc-900/30 flex justify-center">
            <button
              onClick={() => setVisibleCount(prev => prev + 20)}
              className="text-xs font-bold text-zinc-400 hover:text-white flex items-center gap-2 px-4 py-2 hover:bg-zinc-800 rounded-lg transition-all"
            >
              {t.load_more}
            </button>
          </div>
        )}
      </section>
    </div>
  );
};

export default ReportsPage;