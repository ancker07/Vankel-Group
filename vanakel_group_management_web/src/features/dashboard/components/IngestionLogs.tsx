
import React from 'react';
import { EmailIngestionLog, Language } from '@/types';
import { CheckCircle2, XCircle, AlertCircle, Mail, FileText, Info } from 'lucide-react';
import { TRANSLATIONS } from '@/utils/constants';

interface IngestionLogsProps {
  logs: EmailIngestionLog[];
  lang: Language;
}

const IngestionLogs: React.FC<IngestionLogsProps> = ({ logs, lang }) => {
  const t = TRANSLATIONS[lang];

  const renderAddress = (addr: any) => {
    if (!addr) return 'N/A';
    if (typeof addr === 'string') return addr;
    return addr.raw || `${addr.street || ''} ${addr.number || ''} ${addr.city || ''}`.trim();
  };

  const renderContactName = (contact: any) => {
    if (!contact) return null;
    if (typeof contact.name === 'string') return contact.name;
    return contact.name?.value;
  };

  return (
    <div className="space-y-4 animate-in fade-in duration-500">
      <h3 className="text-lg font-bold text-white mb-4 flex items-center gap-2">
        <Mail className="text-brand-green" size={20} /> {t.email_logs_title}
      </h3>

      {logs.length === 0 && (
        <div className="p-8 text-center border border-dashed border-zinc-800 rounded-xl bg-zinc-900/20">
          <p className="text-zinc-500 text-sm">{t.email_logs_empty}</p>
        </div>
      )}

      <div className="max-h-[400px] overflow-y-auto space-y-3 pr-2 custom-scrollbar">
        {logs.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()).map(log => {
          const isError = log.status === 'ERROR';
          const isIgnored = log.status === 'IGNORED';
          const isProcessed = log.status === 'PROCESSED';

          return (
            <div key={log.id} className="bg-zinc-950 border border-zinc-800 p-4 rounded-xl flex items-start gap-4 hover:border-zinc-700 transition-colors">
              {/* Status Icon */}
              <div className={`mt-1 shrink-0 ${isProcessed ? 'text-green-500' :
                  isIgnored ? 'text-zinc-600' : 'text-red-500'
                }`}>
                {isProcessed ? <CheckCircle2 size={18} /> :
                  isIgnored ? <XCircle size={18} /> : <AlertCircle size={18} />}
              </div>

              {/* Log Content */}
              <div className="min-w-0 flex-1">
                {/* Meta Header */}
                <div className="flex items-center gap-2 mb-1">
                  <span className={`text-[9px] font-black uppercase tracking-widest px-1.5 py-0.5 rounded ${isProcessed ? 'bg-green-500/10 text-green-500' :
                      isIgnored ? 'bg-zinc-800 text-zinc-500' : 'bg-red-500/10 text-red-500'
                    }`}>
                    {log.status}
                  </span>
                  <span className="text-[10px] text-zinc-600 font-mono">
                    {new Date(log.receivedAt).toLocaleTimeString()}
                  </span>
                </div>

                {/* Main Subject/From */}
                <p className={`text-sm font-bold truncate ${isIgnored ? 'text-zinc-500' : 'text-white'}`}>
                  {log.subject}
                </p>
                <p className="text-xs text-zinc-500 truncate mb-2">From: {log.from}</p>

                {/* REASON / ERROR BLOCK */}
                {isError && (
                  <div className="bg-red-500/5 border border-red-500/10 rounded-lg p-2 mb-2">
                    <p className="text-xs text-red-400 font-bold flex items-center gap-1.5">
                      <Info size={12} /> {log.reason || "Unknown processing error"}
                    </p>
                    <p className="text-[10px] text-zinc-500 mt-1 pl-4 border-l border-zinc-800">
                      Hint: Check if the building address exists in the system or create the intervention manually.
                    </p>
                  </div>
                )}

                {isIgnored && (
                  <p className="text-xs text-zinc-600 italic">
                    {log.reason || "Ignored: No intervention-related keywords detected in content."}
                  </p>
                )}

                {/* EXTRACTED DATA PREVIEW */}
                {(log.extractedJson || (isError && !log.extractedJson)) && !isIgnored && (
                  <div className="bg-zinc-900/50 rounded border border-zinc-800/50 p-2 text-[10px] font-mono mt-1">
                    {log.extractedJson ? (
                      <>
                        <p className="text-brand-green font-bold mb-1 flex items-center gap-1">
                          <FileText size={10} /> Extracted Data
                        </p>
                        <div className="grid grid-cols-1 gap-0.5 text-zinc-400 pl-1">
                          <p>
                            <span className="text-zinc-600">Addr:</span> <span className="text-zinc-300">{renderAddress(log.extractedJson.address)}</span>
                          </p>
                          {renderContactName(log.extractedJson.contactOnSite) && (
                            <p>
                              <span className="text-zinc-600">Contact:</span> <span className="text-zinc-300">{renderContactName(log.extractedJson.contactOnSite)}</span>
                            </p>
                          )}
                          {log.extractedJson.syndic && (
                            <p>
                              <span className="text-zinc-600">Syndic:</span> <span className="text-zinc-300">{log.extractedJson.syndic}</span>
                            </p>
                          )}
                        </div>
                      </>
                    ) : (
                      <p className="text-zinc-600 italic">No usable data detected from email body/PDF.</p>
                    )}
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default IngestionLogs;
