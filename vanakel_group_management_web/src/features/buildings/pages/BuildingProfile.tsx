
import React, { useState, useMemo } from 'react';
import {
  Building, Professional, Syndic, Intervention, Language, Note as NoteType, Document, Device, Role, Sector, MaintenancePlan
} from '@/types';
import {
  X, User, MapPin, Phone, History, StickyNote, CalendarPlus, FileText, QrCode, Sparkles,
  Trash2, Plus, ArrowRight, CheckCircle2, AlertCircle, Clock, FileWarning, Camera, Upload,
  ChevronRight, Bell, Briefcase, ShieldCheck, Loader2, Calendar as CalendarIcon, RotateCcw
} from 'lucide-react';
import { TRANSLATIONS, CATEGORIES, SECTORS } from '@/utils/constants';
import { improveNote, optimizeIntervention } from '@/services/gemini';
import DatePickerModal from '@/components/common/DatePickerModal';
import ConfirmationModal from '@/components/common/ConfirmationModal';

interface ProfileProps {
  building: Building;
  professionals: Professional[];
  syndics: Syndic[];
  interventions: Intervention[];
  onClose: () => void;
  lang: Language;
  onUpdateBuilding: (b: Building) => void;
  onAddIntervention: (i: Intervention) => void;
  onUpdateIntervention: (i: Intervention) => void;
  onOpenIntervention?: (id: string) => void;
  initialTab?: 'data' | 'history' | 'notes' | 'plan' | 'docs' | 'entretien';
  maintenancePlans?: MaintenancePlan[];
}

const BuildingProfile: React.FC<ProfileProps> = ({
  building, professionals, syndics, interventions, onClose, lang, onUpdateBuilding, onAddIntervention, onUpdateIntervention, onOpenIntervention, initialTab, maintenancePlans = []
}) => {
  const [activeTab, setActiveTab] = useState<'data' | 'history' | 'notes' | 'plan' | 'docs' | 'entretien'>(initialTab || 'data');
  const t = TRANSLATIONS[lang];
  const pro = professionals.find(p => p.id === building.linkedProfessionalId);
  const syn = syndics.find(s => s.id === building.linkedSyndicId);

  const [notes, setNotes] = useState<NoteType[]>([]);
  const [newNote, setNewNote] = useState('');
  const [isImproving, setIsImproving] = useState(false);

  const [planTitle, setPlanTitle] = useState('');
  const [planSector, setPlanSector] = useState<Sector>('PLOMBERIE');
  const [planDate, setPlanDate] = useState('');
  const [planDescription, setPlanDescription] = useState('');
  const [isOptimizingPlan, setIsOptimizingPlan] = useState(false);
  const [optimizationError, setOptimizationError] = useState<string | null>(null);
  const [dateError, setDateError] = useState(false); // To show inline error

  // Date Picker State
  const [showDatePicker, setShowDatePicker] = useState(false);

  // Confirmation Modal State
  const [confirmModal, setConfirmModal] = useState<{
    isOpen: boolean;
    noteId?: string;
  }>({ isOpen: false });

  const handleImprove = async () => {
    if (!newNote) return;
    setIsImproving(true);
    const improved = await improveNote(newNote);
    setNewNote(improved);
    setIsImproving(false);
  };

  const handleOptimizePlan = async () => {
    if (!planTitle && !planDescription) return;
    setIsOptimizingPlan(true);
    setOptimizationError(null);
    try {
      const result = await optimizeIntervention(planTitle, planDescription);
      if (result.title) setPlanTitle(result.title);
      if (result.description) setPlanDescription(result.description);
    } catch (error) {
      setOptimizationError('AI Optimization failed. Please try again.');
    } finally {
      setIsOptimizingPlan(false);
    }
  };

  const addNote = () => {
    if (!newNote) return;
    const note: NoteType = {
      id: Date.now().toString(),
      author: 'Admin',
      authorRole: 'ADMIN',
      content: newNote,
      timestamp: new Date().toISOString(),
      isInternal: false
    };
    setNotes([note, ...notes]);
    setNewNote('');
  };

  const deleteNote = () => {
    if (confirmModal.noteId) {
      setNotes(notes.filter(n => n.id !== confirmModal.noteId));
    }
  };

  const createIntervention = () => {
    setDateError(false);
    if (!planTitle) {
      alert("Please provide an intervention title.");
      return;
    }
    if (!planDescription) {
      alert("Please provide an intervention description.");
      return;
    }
    // Mandatory Date Check
    if (!planDate) {
      setDateError(true);
      return;
    }

    const i: Intervention = {
      id: 'int-' + Math.random().toString(36).substr(2, 9),
      buildingId: building.id,
      title: planTitle,
      category: SECTORS.find(s => s.id === planSector)?.label[lang] || planSector,
      sector: planSector,
      description: planDescription,
      scheduledDate: new Date(planDate).toISOString(),
      status: 'PENDING',
      notes: [],
      photos: [],
      documents: [],
      proId: building.linkedProfessionalId
    };
    onAddIntervention(i);
    setPlanTitle('');
    setPlanDescription('');
    setPlanDate('');
    setActiveTab('history');
  };

  return (
    <div className="bg-zinc-950 border border-zinc-800 rounded-2xl md:rounded-3xl overflow-hidden shadow-2xl animate-in slide-in-from-right duration-500 mb-20 lg:mb-0">
      {/* Profile Header */}
      <div className="relative h-48 md:h-64">
        <img src={building.imageUrl} className="w-full h-full object-cover grayscale-[0.3]" />
        <div className="absolute inset-0 bg-gradient-to-t from-zinc-950 via-zinc-950/20 to-transparent"></div>
        <button onClick={onClose} className="absolute top-4 right-4 p-2 bg-black/60 hover:bg-black rounded-full text-white transition-colors z-20 min-h-[44px] min-w-[44px] flex items-center justify-center">
          <X size={20} />
        </button>

        <div className="absolute bottom-4 md:bottom-6 left-4 md:left-8 right-4 md:right-8 flex flex-col md:flex-row justify-between items-start md:items-end gap-3 md:gap-6 z-10">
          <div className="space-y-0.5 md:space-y-1">
            <h2 className="text-2xl md:text-4xl font-black text-white">{building.address}</h2>
            <div className="flex flex-wrap items-center gap-3">
              <p className="text-zinc-300 text-sm md:text-base font-medium flex items-center gap-1.5 md:gap-2">
                <MapPin size={14} className="text-brand-green" /> {building.city}, BE
              </p>
              {syn && (
                <p className="bg-brand-green/20 text-brand-green px-3 py-1 rounded-full text-[10px] md:text-xs font-black uppercase tracking-widest border border-brand-green/30">
                  {t.syndic}: {syn.companyName}
                </p>
              )}
            </div>
          </div>

          <div className="flex gap-2 md:gap-4 flex-wrap w-full md:w-auto items-center">
            {pro && (
              <div className="bg-zinc-900/90 backdrop-blur border border-zinc-800 px-3 md:px-4 py-1.5 md:py-2 rounded-xl flex items-center gap-2 md:gap-3 flex-1 md:flex-none">
                <Briefcase size={14} className="text-brand-green shrink-0" />
                <div className="min-w-0">
                  <p className="text-[7px] md:text-[8px] font-black text-zinc-500 uppercase tracking-widest">{t.pro}</p>
                  <p className="text-[10px] md:text-xs font-bold text-white truncate max-w-[80px] md:max-w-[120px]">{pro.companyName}</p>
                </div>
              </div>
            )}

            <button
              onClick={() => setActiveTab('plan')}
              className="bg-brand-green text-brand-black w-10 h-10 md:w-12 md:h-12 rounded-xl hover:bg-brand-green-light transition-all shrink-0 flex items-center justify-center shadow-xl shadow-brand-green/20 min-h-[44px] min-w-[44px]"
              title={t.newIntervention}
            >
              <Plus size={24} strokeWidth={3} />
            </button>

            <button className="bg-zinc-900 text-zinc-400 p-2.5 md:p-3 rounded-xl hover:bg-zinc-800 transition-all shrink-0 min-h-[44px] min-w-[44px] flex items-center justify-center">
              <QrCode size={18} />
            </button>
          </div>
        </div>
      </div>

      {/* Tabs - Scrollable on mobile */}
      <div className="flex border-b border-zinc-800 px-2 md:px-4 bg-zinc-950 sticky top-0 z-10 overflow-x-auto no-scrollbar whitespace-nowrap">
        <TabButton icon={<User size={18} />} label={t.tabs_data} active={activeTab === 'data'} onClick={() => setActiveTab('data')} />
        <TabButton icon={<History size={18} />} label={t.tabs_history} active={activeTab === 'history'} onClick={() => setActiveTab('history')} />
        <TabButton icon={<RotateCcw size={18} />} label={t.maintenance || 'Entretien'} active={activeTab === 'entretien'} onClick={() => setActiveTab('entretien')} />
        <TabButton icon={<StickyNote size={18} />} label={t.tabs_notes} active={activeTab === 'notes'} onClick={() => setActiveTab('notes')} />
        <TabButton icon={<CalendarPlus size={18} />} label={t.tabs_plan} active={activeTab === 'plan'} onClick={() => setActiveTab('plan')} />
        <TabButton icon={<FileText size={18} />} label={t.tabs_docs} active={activeTab === 'docs'} onClick={() => setActiveTab('docs')} />
      </div>

      <div className="p-4 md:p-8 min-h-[400px]">
        {activeTab === 'data' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8 md:gap-12 animate-in fade-in duration-300">
            <div className="space-y-6 md:space-y-8">
              <section>
                <h4 className="text-[10px] font-black text-zinc-600 uppercase tracking-widest mb-3 md:mb-4">{t.residentInfo}</h4>
                <div className="space-y-3">
                  {building.tenants.map((tItem, idx) => (
                    <div key={idx} className="flex items-center gap-3 p-3.5 bg-zinc-900/40 rounded-xl border border-zinc-900">
                      <div className="w-9 h-9 rounded-full bg-brand-green/10 text-brand-green flex items-center justify-center font-black text-sm">
                        {tItem.firstName[0]}{tItem.lastName[0]}
                      </div>
                      <div className="min-w-0">
                        <p className="font-bold text-sm truncate">{tItem.firstName} {tItem.lastName}</p>
                        <p className="text-zinc-600 text-[10px] font-black uppercase">{t.tenant}</p>
                      </div>
                    </div>
                  ))}
                  <div className="flex items-center gap-3 p-3.5 bg-zinc-900/40 rounded-xl border border-zinc-900">
                    <div className="w-9 h-9 rounded-full bg-zinc-800 text-zinc-500 flex items-center justify-center font-bold">
                      <Phone size={16} />
                    </div>
                    <div className="min-w-0">
                      <p className="font-bold text-sm truncate">{building.phone}</p>
                      <p className="text-zinc-600 text-[10px] font-black uppercase tracking-widest">{t.directContact}</p>
                    </div>
                  </div>
                </div>
              </section>
            </div>

            <div className="space-y-6 md:space-y-8">
              <section>
                <h4 className="text-[10px] font-black text-zinc-600 uppercase tracking-widest mb-3 md:mb-4">{t.linkedPro}</h4>
                {pro ? (
                  <div className="p-5 bg-zinc-950 border border-zinc-900 rounded-2xl space-y-3">
                    <h5 className="text-lg font-black text-brand-green">{pro.companyName}</h5>
                    <div className="space-y-1.5 text-xs text-zinc-500 font-medium">
                      <p>{t.contact}: <span className="text-zinc-300">{pro.contactPerson}</span></p>
                      <p>{t.email}: <span className="text-zinc-300 truncate block">{pro.email}</span></p>
                      <p>{t.phone}: <span className="text-zinc-300">{pro.phone}</span></p>
                    </div>
                  </div>
                ) : <p className="text-zinc-600 italic text-sm">{t.noneLinked}</p>}
              </section>

              <section>
                <h4 className="text-[10px] font-black text-zinc-600 uppercase tracking-widest mb-3 md:mb-4">{t.linkedSyndic}</h4>
                {syn ? (
                  <div className="p-5 bg-zinc-950 border border-zinc-900 rounded-2xl space-y-3">
                    <h5 className="text-lg font-black text-white">{syn.companyName}</h5>
                    <div className="space-y-1.5 text-xs text-zinc-500 font-medium">
                      <p>{t.managerName}: <span className="text-zinc-300">{syn.contactPerson}</span></p>
                      <p>{t.email}: <span className="text-zinc-300 truncate block">{syn.email}</span></p>
                      <p>{t.phone}: <span className="text-zinc-300">{syn.phone}</span></p>
                    </div>
                  </div>
                ) : <p className="text-zinc-600 italic text-sm">{t.noneLinked}</p>}
              </section>
            </div>
          </div>
        )}

        {activeTab === 'entretien' && (
          <div className="space-y-4 animate-in fade-in duration-300">
            <h4 className="text-[10px] font-black text-zinc-600 uppercase tracking-widest mb-4">{t.maintenance || 'Entretien'}</h4>
            {maintenancePlans.length === 0 ? (
              <p className="text-zinc-500 text-sm italic">No active maintenance plans.</p>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {maintenancePlans.map(plan => (
                  <div key={plan.id} className="bg-zinc-900/30 border border-orange-500/20 p-4 rounded-xl hover:bg-zinc-900/50 transition-colors">
                    <div className="flex justify-between items-start mb-2">
                      <h5 className="text-sm font-bold text-white">{plan.title}</h5>
                      <span className="text-[9px] font-black uppercase bg-orange-500/10 text-orange-500 px-2 py-0.5 rounded">{plan.recurrence.frequency}</span>
                    </div>
                    <p className="text-xs text-zinc-400 mb-3">{plan.description}</p>
                    <div className="flex items-center gap-2 text-[10px] text-zinc-500 font-mono">
                      <CalendarIcon size={12} className="text-orange-500" />
                      <span>{new Date(plan.recurrence.startDate).toLocaleDateString()}</span>
                      <ArrowRight size={10} />
                      <span>{new Date(plan.recurrence.endDate).toLocaleDateString()}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {activeTab === 'history' && (
          <div className="space-y-4 md:space-y-6 animate-in fade-in duration-300">
            {interventions.filter(i => i.status === 'COMPLETED').length === 0 && <p className="text-center text-zinc-600 py-12 text-sm font-medium">{t.noCompletedInt}</p>}
            <div className="space-y-3">
              {interventions.filter(i => i.status === 'COMPLETED').sort((a, b) => new Date(b.completedAt || 0).getTime() - new Date(a.completedAt || 0).getTime()).map(i => {
                // Determine contact string
                const contactName = i.onSiteContactName;
                const contactPhone = i.onSiteContactPhone;
                const contactEmail = i.onSiteContactEmail;
                const parts: string[] = [];
                if (contactName) parts.push(contactName);
                if (contactPhone) parts.push(contactPhone);
                if (contactEmail) parts.push(contactEmail);

                const contactString = parts.length > 0 ? parts.join(' · ') : t.notProvided;
                const hasContact = parts.length > 0;

                return (
                  <div
                    key={i.id}
                    onClick={() => onOpenIntervention?.(i.id)}
                    className="bg-zinc-900/40 border border-zinc-900 p-4 rounded-xl group hover:border-brand-green/30 transition-all flex flex-col md:flex-row justify-between items-start md:items-center gap-4 cursor-pointer"
                  >
                    <div className="min-w-0">
                      <div className="flex items-center gap-2 mb-1.5">
                        <span className="text-brand-green font-black text-[9px] uppercase tracking-[0.2em]">{i.category}</span>
                        <span className="bg-green-500/10 text-green-500 text-[8px] px-1.5 py-0.5 rounded font-black uppercase tracking-wider">{t.status_completed}</span>
                      </div>
                      <h4 className="text-sm md:text-base font-bold text-white mb-1">{i.title}</h4>
                      <p className="text-zinc-400 text-xs truncate pr-4 italic">{i.description}</p>
                      <p className="text-zinc-600 text-[10px] mt-1 font-medium uppercase tracking-tighter">{t.closedOn} {new Date(i.completedAt!).toLocaleDateString()}</p>

                      {/* On-site Contact Info Line */}
                      <p className="text-zinc-500 text-[10px] mt-1 font-medium truncate">
                        <span className="uppercase tracking-wide mr-1 font-bold">{t.onSiteContactLabel}:</span>
                        <span className={hasContact ? "text-zinc-300" : "text-zinc-600 italic"}>{contactString}</span>
                      </p>
                    </div>
                    <ChevronRight size={20} className="hidden md:block text-zinc-600 group-hover:text-white transition-colors" />
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        onOpenIntervention?.(i.id);
                      }}
                      className="md:hidden w-full py-2 bg-zinc-900 border border-zinc-800 rounded-lg text-[10px] font-black uppercase tracking-widest text-zinc-500 min-h-[44px] hover:text-white hover:border-zinc-600 transition-all"
                    >
                      {t.viewSlip}
                    </button>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {activeTab === 'notes' && (
          <div className="max-w-3xl mx-auto space-y-6 md:space-y-8 animate-in fade-in duration-300 pb-12">
            <div className="bg-zinc-900/40 p-4 md:p-6 rounded-2xl border border-zinc-800 space-y-4">
              <div className="flex justify-between items-center mb-1">
                <h5 className="font-black text-zinc-600 uppercase text-[9px] tracking-widest">{t.postNote}</h5>
                <button
                  onClick={handleImprove}
                  disabled={isImproving || !newNote}
                  className="flex items-center gap-1.5 text-brand-green text-[9px] font-black uppercase tracking-widest hover:bg-brand-green/10 px-2 py-1 rounded transition-all disabled:opacity-50 min-h-[30px]"
                >
                  <Sparkles size={12} /> {isImproving ? t.wait : t.improveAI}
                </button>
              </div>
              <textarea
                value={newNote}
                onChange={e => setNewNote(e.target.value)}
                className="w-full bg-zinc-950 border border-zinc-900 rounded-xl p-3.5 min-h-[100px] md:min-h-[120px] focus:border-brand-green outline-none text-sm text-zinc-300 leading-relaxed"
                placeholder="Technical update, monthly management note..."
              />
              <div className="flex justify-end">
                <button onClick={addNote} className="w-full md:w-auto px-8 py-3 bg-brand-green text-brand-black font-black uppercase tracking-widest text-xs rounded-xl hover:bg-brand-green-light transition-all shadow-lg shadow-brand-green/10 min-h-[44px]">
                  {t.post}
                </button>
              </div>
            </div>

            <div className="space-y-4">
              {notes.map(note => (
                <div key={note.id} className="bg-zinc-950 p-4 rounded-xl border border-zinc-900">
                  <div className="flex justify-between items-start mb-3">
                    <div className="flex items-center gap-2.5">
                      <div className="w-7 h-7 rounded-full bg-zinc-900 border border-zinc-800 flex items-center justify-center font-black text-zinc-500 text-[10px]">A</div>
                      <div>
                        <p className="font-bold text-xs">{note.author} <span className="text-[9px] text-zinc-600 font-black ml-1.5 uppercase tracking-wider">{note.authorRole}</span></p>
                        <p className="text-[9px] text-zinc-600 font-medium tracking-tighter">{new Date(note.timestamp).toLocaleString()}</p>
                      </div>
                    </div>
                    <button
                      onClick={() => setConfirmModal({ isOpen: true, noteId: note.id })}
                      className="text-zinc-700 hover:text-red-500 transition-colors p-1"
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                  <p className="text-zinc-400 text-sm leading-relaxed">{note.content}</p>
                </div>
              ))}
            </div>
          </div>
        )}

        {activeTab === 'plan' && (
          <div className="max-w-xl mx-auto bg-zinc-950 border border-zinc-800 p-5 md:p-8 rounded-2xl md:rounded-[2rem] shadow-2xl animate-in slide-in-from-bottom-4 duration-300 pb-12">
            <div className="flex justify-between items-center mb-6 md:mb-8">
              <h4 className="text-xl md:text-2xl font-black uppercase tracking-widest">{t.newIntervention}</h4>
              <button
                onClick={handleOptimizePlan}
                disabled={isOptimizingPlan || (!planTitle && !planDescription)}
                className="flex items-center gap-1.5 text-brand-green text-[9px] md:text-[10px] font-black uppercase tracking-widest border border-brand-green/20 bg-brand-green/5 hover:bg-brand-green/10 px-3 py-1.5 rounded-lg transition-all disabled:opacity-50 disabled:grayscale min-h-[30px]"
              >
                {isOptimizingPlan ? <Loader2 size={12} className="animate-spin" /> : <Sparkles size={12} />}
                {t.optimizeAI}
              </button>
            </div>
            <div className="space-y-6">
              {optimizationError && (
                <p className="text-red-500 text-[10px] font-bold animate-pulse">{optimizationError}</p>
              )}
              {/* New Intervention Title Field */}
              <div className="space-y-1.5">
                <label className="text-[9px] font-black text-zinc-600 uppercase tracking-widest">{t.interventionTitle} *</label>
                <input
                  type="text"
                  value={planTitle}
                  onChange={e => setPlanTitle(e.target.value)}
                  required
                  className="w-full bg-zinc-900 border border-zinc-800 px-4 py-3 rounded-xl focus:border-brand-green outline-none text-sm font-bold min-h-[44px]"
                  placeholder="e.g. Repair leak, Annual boiler service..."
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-[9px] font-black text-zinc-600 uppercase tracking-widest">{t.description} *</label>
                <textarea
                  value={planDescription}
                  onChange={e => setPlanDescription(e.target.value)}
                  required
                  className="w-full bg-zinc-900 border border-zinc-800 px-4 py-3 rounded-xl focus:border-brand-green outline-none min-h-[100px] text-sm"
                  placeholder="Describe specific technical scope..."
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-6">
                <div className="space-y-1.5">
                  <label className="text-[9px] font-black text-zinc-600 uppercase tracking-widest">{t.sector || t.category}</label>
                  <select
                    value={planSector}
                    onChange={e => setPlanSector(e.target.value as Sector)}
                    className="w-full bg-zinc-900 border border-zinc-800 px-4 py-3 rounded-xl focus:border-brand-green outline-none text-sm min-h-[44px]"
                  >
                    {SECTORS.map(s => <option key={s.id} value={s.id}>{s.label[lang]}</option>)}
                  </select>
                </div>
                <div className="space-y-1.5">
                  <label className="text-[9px] font-black text-zinc-600 uppercase tracking-widest">{t.dateTime} *</label>
                  <div
                    onClick={() => setShowDatePicker(true)}
                    className={`w-full bg-zinc-900 border ${dateError ? 'border-red-500' : 'border-zinc-800'} px-4 py-3 rounded-xl cursor-pointer flex items-center justify-between hover:border-brand-green transition-all min-h-[44px]`}
                  >
                    <span className={`text-sm ${planDate ? 'text-white font-bold' : 'text-zinc-500'}`}>
                      {planDate ? new Date(planDate).toLocaleDateString() : t.select_date}
                    </span>
                    <CalendarIcon size={16} className="text-zinc-500" />
                  </div>
                  {dateError && (
                    <p className="text-red-500 text-[10px] font-bold">Date required.</p>
                  )}
                </div>
              </div>

              <div className="p-3.5 bg-brand-green/5 border border-brand-green/10 rounded-xl flex items-start gap-3 mt-2">
                <div className="p-1.5 bg-brand-green/10 rounded-full text-brand-green shrink-0">
                  <Clock size={14} />
                </div>
                <div className="space-y-1">
                  <p className="text-[10px] text-zinc-500 font-medium leading-tight">
                    {t.autoNotify} <span className="text-zinc-300 font-bold">{pro ? pro.companyName : t.unassigned}</span>
                  </p>
                  <p className="text-[9px] text-brand-green font-bold">{t.hoursBefore}</p>
                </div>
              </div>

              <div className="pt-4 flex justify-end">
                <button
                  onClick={createIntervention}
                  className="w-full md:w-auto px-8 py-4 bg-brand-green text-brand-black rounded-xl font-black text-xs uppercase tracking-widest hover:bg-brand-green-light transition-all shadow-xl shadow-brand-green/20 min-h-[50px] flex items-center justify-center gap-2"
                >
                  {t.createPlan} <ArrowRight size={14} />
                </button>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'docs' && (
          <div className="space-y-4 md:space-y-6 animate-in fade-in duration-300">
            <h4 className="text-[10px] font-black text-zinc-600 uppercase tracking-widest mb-2">{t.docRepo}</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="p-12 border border-dashed border-zinc-800 rounded-2xl flex flex-col items-center justify-center text-zinc-500 bg-zinc-900/20 hover:bg-zinc-900/40 hover:border-brand-green/30 transition-all cursor-pointer group">
                <FileWarning size={32} className="mb-2 group-hover:scale-110 transition-transform text-zinc-600 group-hover:text-brand-green" />
                <p className="text-xs font-bold">Drag & Drop</p>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Modals */}
      <DatePickerModal
        isOpen={showDatePicker}
        onClose={() => setShowDatePicker(false)}
        onValidate={(d) => setPlanDate(d)}
        initialDate={planDate}
        title={t.select_date}
        cancelLabel={t.cancel}
        validateLabel={t.validate}
      />

      <ConfirmationModal
        isOpen={confirmModal.isOpen}
        onClose={() => setConfirmModal({ isOpen: false })}
        onConfirm={deleteNote}
        title={t.confirmDeleteTitle}
        message={t.confirmDeleteMsg}
        confirmLabel={t.btnDelete}
        cancelLabel={t.btnCancel}
        isDanger={true}
      />
    </div>
  );
};

// Internal Helper for Tabs
const TabButton: React.FC<{ icon: React.ReactNode; label: string; active?: boolean; onClick: () => void }> = ({ icon, label, active, onClick }) => (
  <button
    onClick={onClick}
    className={`flex items-center gap-2 px-4 md:px-6 py-4 md:py-5 text-[10px] md:text-xs font-black uppercase tracking-widest border-b-2 transition-all shrink-0 ${active ? 'border-brand-green text-brand-green' : 'border-transparent text-zinc-500 hover:text-zinc-300'}`}
  >
    {icon} {label}
  </button>
);

export default BuildingProfile;
