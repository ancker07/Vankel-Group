
import React from 'react';
import { Building, Syndic, Intervention, Language } from '@/types';
import { X, MapPin, Phone, Mail, User, ShieldCheck, Download, FileText, Calendar, CheckCircle2, AlertCircle } from 'lucide-react';
import { TRANSLATIONS } from '@/utils/constants';

interface GestionDetailsModalProps {
  building: Building;
  syndic?: Syndic;
  interventions: Intervention[];
  onClose: () => void;
  lang: Language;
}

const GestionDetailsModal: React.FC<GestionDetailsModalProps> = ({ building, syndic, interventions, onClose, lang }) => {
  const t = TRANSLATIONS[lang];

  const handleDownload = (docName: string) => {
    try {
      // Minimal valid PDF Base64 (Blank Page) - Single line to prevent formatting issues
      const validPdfBase64 = "JVBERi0xLjcKCjEgMCBvYmogPDwvVHlwZS9DYXRhbG9nL1BhZ2VzIDIgMCBSPj4gZW5kb2JqCjIgMCBvYmogPDwvVHlwZS9QYWdlcy9LaWRzWzMgMCBSXS9Db3VudCAxPj4gZW5kb2JqCjMgMCBvYmogPDwvVHlwZS9QYWdlL01lZGlhQm94WzAgMCA1OTUgODQyXS9QYXJlbnQgMiAwIFIvUmVzb3VyY2VzPDw+Pi9Db250ZW50cyA0IDAgUj4+IGVuZG9iago0IDAgb2JqIDw8L0xlbmd0aCAwPj4gc3RyZWFtCmVuZHN0cmVhbQplbmRvYmoKeHJlZgowIDUKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDEwIDAwMDAwIG4gCjAwMDAwMDAwNjAgMDAwMDAgbiAKMDAwMDAwMDExNyAwMDAwMCBuIAowMDAwMDAwMjE4IDAwMDAwIG4gCnRyYWlsZXIgPDwvU2l6ZSA1L1Jvb3QgMSAwIFI+PgpzdGFydHhyZWYKMjY0CiUlRU9G";

      // Strict cleaning of whitespace/newlines
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
      link.setAttribute('download', docName);
      document.body.appendChild(link);
      link.click();

      // Cleanup
      link.remove();
      window.URL.revokeObjectURL(url);

    } catch (e) {
      console.error("Download error:", e);
      const errorMsg = lang === 'FR' ? "Erreur de téléchargement" : lang === 'NL' ? "Downloadfout" : "Download error";
      alert(`${errorMsg}: ${(e as Error).message}`);
    }
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-end md:items-center justify-center p-0 md:p-4 bg-black/80 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-zinc-950 border-t md:border border-zinc-800 w-full max-w-5xl h-[90dvh] md:h-auto md:max-h-[90dvh] rounded-t-3xl md:rounded-3xl shadow-2xl flex flex-col relative overflow-hidden">

        {/* Header Section */}
        <div className="relative h-48 md:h-56 bg-zinc-900 shrink-0">
          <img src={building.imageUrl} className="w-full h-full object-cover opacity-60" alt="Building Header" />
          <div className="absolute inset-0 bg-gradient-to-t from-zinc-950 to-transparent"></div>

          <button
            onClick={onClose}
            className="absolute top-4 right-4 bg-black/50 hover:bg-black text-white p-2 rounded-full transition-all z-20"
          >
            <X size={20} />
          </button>

          <div className="absolute bottom-6 left-6 right-6 z-10">
            <h2 className="text-xl md:text-4xl font-black text-white mb-2 leading-tight">{building.address}</h2>
            <div className="flex flex-wrap items-center gap-2 md:gap-4 text-xs md:text-sm font-medium text-zinc-300">
              <span className="flex items-center gap-1.5"><MapPin size={14} className="text-brand-green" /> {building.city}</span>
              {syndic && (
                <span className="flex items-center gap-1.5 bg-zinc-900/80 px-2 md:px-3 py-1 rounded-full border border-zinc-700">
                  <ShieldCheck size={12} /> {syndic.companyName}
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Scrollable Content */}
        <div className="flex-1 overflow-y-auto p-4 md:p-8 space-y-6 md:space-y-8">

          {/* Contacts Section */}
          <div className="grid grid-cols-1 gap-6">
            <div className="bg-brand-green/5 border border-brand-green/20 rounded-2xl p-4 md:p-5">
              <h3 className="text-[10px] md:text-xs font-black uppercase tracking-widest text-brand-green mb-4 flex items-center gap-2">
                <ShieldCheck size={14} /> {t.syndic_contact_title}
              </h3>
              {syndic ? (
                <div className="flex flex-col md:flex-row md:items-center gap-4 md:gap-8">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 md:w-12 md:h-12 rounded-full bg-brand-green/10 border border-brand-green/20 flex items-center justify-center text-brand-green shrink-0">
                      <User size={18} />
                    </div>
                    <div>
                      <p className="text-brand-green font-bold text-sm">{syndic.contactPerson}</p>
                      <p className="text-brand-green/70 text-xs truncate max-w-[200px]">{syndic.companyName}</p>
                    </div>
                  </div>
                  <div className="space-y-2 text-sm text-brand-green/80 border-t md:border-t-0 md:border-l border-brand-green/20 pt-3 md:pt-0 md:pl-6">
                    <div className="flex items-center gap-2">
                      <Phone size={14} className="text-brand-green shrink-0" />
                      <a href={`tel:${syndic.phone}`} className="hover:text-white transition-colors">{syndic.phone || 'N/A'}</a>
                    </div>
                    <div className="flex items-center gap-2">
                      <Mail size={14} className="text-brand-green shrink-0" />
                      <a href={`mailto:${syndic.email}`} className="hover:text-white transition-colors truncate">{syndic.email}</a>
                    </div>
                  </div>
                </div>
              ) : (
                <p className="text-brand-green/60 text-sm italic">{t.no_syndic_linked}</p>
              )}
            </div>
          </div>

          {/* Intervention History */}
          <div>
            <h3 className="text-lg font-black text-white mb-4 md:mb-6 flex items-center gap-2">
              <CheckCircle2 className="text-brand-green" size={20} />
              {t.history_title}
            </h3>

            <div className="space-y-4">
              {interventions.length === 0 && (
                <div className="p-8 text-center border border-dashed border-zinc-800 rounded-2xl bg-zinc-900/20">
                  <p className="text-zinc-500 text-sm">{t.no_history_found}</p>
                </div>
              )}

              {interventions.map((intervention) => {
                const contactParts = [
                  intervention.onSiteContactName,
                  intervention.onSiteContactPhone,
                  intervention.onSiteContactEmail
                ].filter(Boolean);

                const contactString = contactParts.length > 0 ? contactParts.join(' · ') : t.notProvided;
                const hasContact = contactParts.length > 0;

                return (
                  <div key={intervention.id} className="bg-zinc-950 border border-zinc-800 rounded-xl p-4 md:p-5 hover:border-zinc-700 transition-all flex flex-col md:flex-row gap-4 md:gap-6">
                    {/* Status & Date */}
                    <div className="flex flex-row md:flex-col justify-between items-center md:items-start md:w-48 shrink-0 gap-2">
                      <div className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-wider ${intervention.status === 'COMPLETED' ? 'bg-green-500/10 text-green-500 border border-green-500/20' :
                          intervention.status === 'DELAYED' ? 'bg-orange-500/10 text-orange-500 border border-orange-500/20' :
                            'bg-zinc-700/20 text-zinc-500 border border-zinc-700/20'
                        }`}>
                        {intervention.status === 'COMPLETED' ? <CheckCircle2 size={12} /> :
                          intervention.status === 'DELAYED' ? <AlertCircle size={12} /> : <CheckCircle2 size={12} />}
                        {intervention.status === 'PENDING' ? t.status_pending : intervention.status === 'DELAYED' ? t.status_delayed : t.status_completed}
                      </div>
                      <div className="flex items-center gap-2 text-zinc-400 text-xs font-medium">
                        <Calendar size={14} />
                        {new Date(intervention.scheduledDate).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })}
                      </div>
                    </div>

                    {/* Details */}
                    <div className="flex-1 min-w-0">
                      <h4 className="text-sm md:text-base font-bold text-white mb-1.5 break-words">{intervention.title}</h4>
                      <p className="text-xs md:text-sm text-zinc-400 leading-relaxed mb-3 line-clamp-2">{intervention.description}</p>

                      <div className="flex items-center gap-2 text-xs">
                        <User size={12} className="text-zinc-500 shrink-0" />
                        <span className="text-zinc-500 font-bold uppercase tracking-wider shrink-0">{t.onSiteContactLabel}:</span>
                        <span className={`truncate ${hasContact ? 'text-zinc-300' : 'text-zinc-600 italic'}`}>
                          {contactString}
                        </span>
                      </div>
                    </div>

                    {/* Documents Action Area */}
                    <div className="w-full md:w-64 shrink-0 flex flex-col gap-2 justify-center border-t md:border-t-0 md:border-l border-zinc-900 pt-4 md:pt-0 md:pl-6">
                      <p className="text-[10px] font-black text-zinc-600 uppercase tracking-widest mb-1">{t.docs}</p>

                      <button
                        onClick={() => {
                          const cleanAddr = building.address.replace(/[\/\\:*?"<>|]/g, "-").trim();
                          const cleanSyndic = syndic ? syndic.companyName.replace(/[\/\\:*?"<>|]/g, "-").trim() : 'NoSyndic';
                          const filename = `Bon_INT - ${cleanAddr} - ${cleanSyndic}.pdf`;
                          handleDownload(filename);
                        }}
                        className="flex items-center justify-between w-full px-3 py-2 bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 rounded-lg group transition-all text-xs font-bold text-zinc-300 hover:text-white"
                      >
                        <span className="flex items-center gap-2">
                          <FileText size={14} className="text-brand-green" /> {t.intervention_slip_doc}
                        </span>
                        <Download size={14} className="text-zinc-600 group-hover:text-brand-green" />
                      </button>

                      {intervention.documents.map(doc => (
                        <button
                          key={doc.id}
                          onClick={() => handleDownload(doc.name)}
                          className="flex items-center justify-between w-full px-3 py-2 bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 rounded-lg group transition-all text-xs font-bold text-zinc-300 hover:text-white"
                        >
                          <span className="flex items-center gap-2 truncate pr-2">
                            <FileText size={14} className="text-zinc-500" /> {doc.name}
                          </span>
                          <Download size={14} className="text-zinc-600 group-hover:text-brand-green shrink-0" />
                        </button>
                      ))}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

        </div>
      </div>
    </div>
  );
};

export default GestionDetailsModal;
