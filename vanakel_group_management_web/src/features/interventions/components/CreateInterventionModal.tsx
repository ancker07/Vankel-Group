
import React, { useState, useMemo } from 'react';
import { X, Plus, MapPin, Search } from 'lucide-react';
import { Building, Syndic, Language, InterventionStatus, Sector, Urgency } from '@/types';
import { TRANSLATIONS, SECTORS, URGENCY } from '@/utils/constants';
import { Upload, Paperclip } from 'lucide-react';
import CreateSyndicModal from '@/features/management/components/CreateSyndicModal';

interface CreateInterventionPayload {
  title: string;
  status: InterventionStatus;
  receptionDate: string;
  description: string;
  addressFull: string;
  syndicId: string;
  sector: Sector;
  urgency: Urgency;
  onSiteContactName: string;
  onSiteContactPhone: string;
  onSiteContactEmail: string;
  files?: File[];
}


interface CreateInterventionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onCreate: (payload: CreateInterventionPayload) => void;
  onSyndicCreate: (syndic: Syndic) => void;
  buildings: Building[];
  syndics: Syndic[];
  lang: Language;
  role?: string;
  userName: string;
}


const CreateInterventionModal: React.FC<CreateInterventionModalProps> = ({
  isOpen, onClose, onCreate, onSyndicCreate, buildings, syndics, lang, role, userName
}) => {

  const t = TRANSLATIONS[lang];

  // Form State
  const [title, setTitle] = useState('');
  const [addressInput, setAddressInput] = useState('');
  const [selectedSyndicId, setSelectedSyndicId] = useState(role === 'SYNDIC' && syndics.length > 0 ? syndics[0].id : '');
  const [selectedSector, setSelectedSector] = useState<Sector | ''>('');

  const [status, setStatus] = useState<InterventionStatus>('PENDING');
  const [receptionDate, setReceptionDate] = useState(new Date().toISOString().split('T')[0]);
  const [description, setDescription] = useState('');
  const [urgency, setUrgency] = useState<Urgency | ''>('');
  const [attachedFiles, setAttachedFiles] = useState<File[]>([]);

  // Contact Sur Place (Hidden/Defaulted)
  const [contactPhone, setContactPhone] = useState('');
  const [contactEmail, setContactEmail] = useState('');


  // Sub-modal state
  const [isSyndicModalOpen, setIsSyndicModalOpen] = useState(false);
  const [showAddressDropdown, setShowAddressDropdown] = useState(false);

  if (!isOpen) return null;

  // Address Autocomplete Logic
  const filteredBuildings = useMemo(() => {
    if (addressInput.length < 2) return [];
    const q = addressInput.toLowerCase();
    return buildings.filter(b => b.address.toLowerCase().includes(q));
  }, [addressInput, buildings]);

  const handleAddressSelect = (addr: string, syndicId: string) => {
    setAddressInput(addr);
    // If building exists, pre-select its syndic if not already set
    if (syndicId && !selectedSyndicId) {
      setSelectedSyndicId(syndicId);
    }
    setShowAddressDropdown(false);
  };

  // Validation
  // If role is ADMIN and no syndic selected, we default to the first one available to allow submission since the field is hidden
  const effectiveSyndicId = selectedSyndicId || (role !== 'SYNDIC' && syndics.length > 0 ? syndics[0].id : '');
  const isValid = true; // Temporary for troubleshooting - forcing the button to be enabled



  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!isValid) return;

    onCreate({
      title,
      status,
      receptionDate,
      description,
      addressFull: addressInput,
      syndicId: effectiveSyndicId,
      sector: selectedSector || 'GENERAL',

      urgency: urgency as Urgency,
      onSiteContactName: userName,
      onSiteContactPhone: contactPhone,
      onSiteContactEmail: contactEmail,
      files: attachedFiles
    });
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      setAttachedFiles(Array.from(e.target.files));
    }
  };


  const handleNewSyndicCreated = (newSyndic: Syndic) => {
    onSyndicCreate(newSyndic);
    setSelectedSyndicId(newSyndic.id);
    setIsSyndicModalOpen(false);
  };

  // Determine if creating new building
  const isNewBuilding = !buildings.some(b => b.address.toLowerCase() === addressInput.toLowerCase());

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-0 md:p-4">
      <div className="absolute inset-0 bg-black/80 backdrop-blur-sm" onClick={onClose}></div>
      <div className="bg-zinc-950 border-x md:border border-zinc-800 w-full max-w-2xl h-full md:h-auto md:max-h-[90dvh] md:rounded-3xl shadow-2xl relative z-10 overflow-hidden flex flex-col animate-in fade-in slide-in-from-bottom-4 duration-300">

        {/* Header */}
        <div className="px-6 py-5 border-b border-zinc-800 flex justify-between items-center bg-zinc-900/50">
          <h3 className="text-xl font-black uppercase tracking-widest text-brand-green">
            {t.request}
          </h3>


          <button onClick={onClose} className="p-2 bg-zinc-800 hover:bg-zinc-700 rounded-full transition-colors text-white">
            <X size={20} />
          </button>
        </div>

        {/* Form Content */}
        <div className="flex-1 overflow-y-auto p-6 md:p-8 space-y-6">
          <form id="create-intervention-form" onSubmit={handleSubmit} className="space-y-6">

            {/* Subject (Title) */}
            <div className="space-y-1.5">
              <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.subject} *</label>
              <input
                type="text"
                required
                value={title}
                onChange={e => setTitle(e.target.value)}
                placeholder={t.subject}
                className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-3 text-sm font-bold text-white focus:border-brand-green outline-none transition-all"
              />
            </div>


            {/* Address with Autocomplete */}
            <div className="space-y-1.5 relative">
              <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.address} *</label>
              <div className="relative">
                <MapPin className="absolute left-4 top-1/2 -translate-y-1/2 text-zinc-500 pointer-events-none" size={16} />
                <input
                  type="text"
                  required
                  value={addressInput}
                  onChange={e => { setAddressInput(e.target.value); setShowAddressDropdown(true); }}
                  onFocus={() => setShowAddressDropdown(true)}
                  onBlur={() => setTimeout(() => setShowAddressDropdown(false), 200)}
                  placeholder={t.selectOrTypeAddress}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-xl pl-11 pr-4 py-3 text-sm font-bold text-white focus:border-brand-green outline-none transition-all"
                />
              </div>
              {showAddressDropdown && addressInput.length > 1 && filteredBuildings.length > 0 && (
                <div className="absolute top-full left-0 right-0 mt-1 bg-zinc-900 border border-zinc-800 rounded-xl shadow-2xl z-20 max-h-48 overflow-y-auto">
                  {filteredBuildings.map(b => (
                    <button
                      key={b.id}
                      type="button"
                      onClick={() => handleAddressSelect(b.address, b.linkedSyndicId)}
                      className="w-full text-left px-4 py-3 hover:bg-zinc-800 text-sm font-medium text-zinc-300 border-b border-zinc-800/50 last:border-0"
                    >
                      {b.address}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Syndic (Hidden - handled via address autocomplete or auto-selected) */}


            {/* Description */}
            {/* Description */}
            <div className="space-y-1.5">
              <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.description} *</label>
              <textarea
                required
                value={description}
                onChange={e => setDescription(e.target.value)}
                placeholder={t.description}
                className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-3 text-sm font-medium text-zinc-300 focus:border-brand-green outline-none transition-all min-h-[120px]"
              />
            </div>
            <div className="space-y-1.5">
              <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.phone || 'Phone Number'} *</label>
              <input
                type="text"
                required
                value={contactPhone}
                onChange={e => setContactPhone(e.target.value)}
                placeholder="+32 ..."
                className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-3 text-sm font-bold text-white focus:border-brand-green outline-none transition-all"
              />
            </div>



            {/* Urgency (Interactive Buttons) */}
            <div className="space-y-3">
              <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.urgency} *</label>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                {URGENCY.map(u => {
                  const isActive = urgency === u.id;
                  // Map urgency colors to more vibrant states when active
                  const activeClass = u.id === 'LOW' ? 'bg-zinc-800 border-zinc-500 text-white' :
                    u.id === 'MEDIUM' ? 'bg-blue-500/10 border-blue-500/50 text-blue-400' :
                      u.id === 'HIGH' ? 'bg-orange-500/10 border-orange-500/50 text-orange-400' :
                        'bg-red-500/10 border-red-500/50 text-red-500';

                  return (
                    <button
                      key={u.id}
                      type="button"
                      onClick={() => setUrgency(u.id as Urgency)}
                      className={`py-3 px-2 rounded-xl border text-[10px] font-black uppercase tracking-wider transition-all duration-300 flex flex-col items-center justify-center gap-1 ${isActive ? activeClass : 'bg-zinc-900/50 border-zinc-800 text-zinc-600 hover:border-zinc-700'
                        }`}
                    >
                      <div className={`w-2 h-2 rounded-full mb-1 ${isActive ? u.color.replace('text-', 'bg-') : 'bg-zinc-800'}`} />
                      {u.label[lang]}
                    </button>
                  );
                })}
              </div>
            </div>



            {/* Document Selection */}
            <div className="space-y-3">
              <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.attachDocuments}</label>
              <div className="flex flex-col gap-3">
                <label className={`group flex flex-col items-center justify-center border-2 border-dashed rounded-3xl py-10 px-4 bg-zinc-900/30 cursor-pointer transition-all duration-300 ${attachedFiles.length > 0 ? 'border-brand-green/30 bg-brand-green/5' : 'border-zinc-800 hover:border-brand-green/50'
                  }`}>
                  <div className={`p-4 rounded-2xl transition-all duration-300 mb-3 ${attachedFiles.length > 0 ? 'bg-brand-green text-brand-black scale-110 shadow-lg shadow-brand-green/20' : 'bg-zinc-800 text-zinc-500 group-hover:bg-brand-green/10 group-hover:text-brand-green group-hover:scale-110'
                    }`}>
                    <Upload size={28} />
                  </div>
                  <span className={`text-sm font-black uppercase tracking-widest transition-colors ${attachedFiles.length > 0 ? 'text-brand-green' : 'text-zinc-500 group-hover:text-zinc-300'
                    }`}>
                    {attachedFiles.length > 0 ? `${attachedFiles.length} ${t.files_selected || 'Files Selected'}` : t.upload || 'Upload Document'}
                  </span>
                  <input type="file" multiple className="hidden" onChange={handleFileChange} />
                </label>


                {attachedFiles.length > 0 && (
                  <div className="grid grid-cols-4 sm:grid-cols-5 gap-3 mt-4">
                    {attachedFiles.map((f, i) => {
                      const isImage = f.type.startsWith('image/');
                      return (
                        <div key={i} className="relative group aspect-square">
                          {isImage ? (
                            <img
                              src={URL.createObjectURL(f)}
                              alt={f.name}
                              className="w-full h-full object-cover rounded-xl border border-zinc-800 bg-zinc-900"
                            />
                          ) : (
                            <div className="w-full h-full rounded-xl border border-zinc-800 bg-zinc-900 flex flex-col items-center justify-center p-2 text-center">
                              <Paperclip size={16} className="text-zinc-500 mb-1" />
                              <span className="text-[8px] font-bold text-zinc-500 truncate w-full">{f.name}</span>
                            </div>
                          )}
                          <button
                            type="button"
                            onClick={() => setAttachedFiles(prev => prev.filter((_, idx) => idx !== i))}
                            className="absolute -top-1.5 -right-1.5 p-1 bg-red-500 text-white rounded-full shadow-lg opacity-0 group-hover:opacity-100 transition-opacity z-10"
                          >
                            <X size={10} />
                          </button>
                        </div>
                      );
                    })}
                  </div>
                )}

              </div>
            </div>


          </form>
        </div>

        {/* Footer Actions */}
        <div className="px-6 py-5 border-t border-zinc-800 bg-zinc-900/50 flex gap-3">
          <button
            onClick={onClose}
            className="flex-1 py-4 bg-zinc-900 border border-zinc-800 rounded-xl font-black text-xs uppercase tracking-widest hover:bg-zinc-800 transition-colors text-zinc-400"
          >
            {t.cancel}
          </button>
          <button
            type="submit"
            form="create-intervention-form"
            className={`flex-1 py-4 rounded-xl font-black text-sm uppercase tracking-widest transition-all duration-300 shadow-xl bg-brand-green text-brand-black hover:bg-brand-green-light hover:scale-[1.02] active:scale-[0.98] shadow-brand-green/20`}
          >
            {role === 'SYNDIC' ? (t.sendRequest || 'Create Request') : (t.create || 'Create Request')}
          </button>


        </div>

        {/* Sub Modal */}
        <CreateSyndicModal
          isOpen={isSyndicModalOpen}
          onClose={() => setIsSyndicModalOpen(false)}
          onCreate={handleNewSyndicCreated}
          lang={lang}
        />

      </div>
    </div>
  );
};

export default CreateInterventionModal;
