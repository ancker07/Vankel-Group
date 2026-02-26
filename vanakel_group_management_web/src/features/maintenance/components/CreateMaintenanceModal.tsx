
import React, { useState } from 'react';
import { X, Calendar } from 'lucide-react';
import { Building, MaintenancePlan, MaintenanceFrequency } from '@/types';
import { TRANSLATIONS } from '@/utils/constants';

interface CreateMaintenanceModalProps {
  isOpen: boolean;
  onClose: () => void;
  onCreate: (plan: Omit<MaintenancePlan, 'id' | 'createdAt' | 'status'>) => void;
  buildings: Building[];
  initialBuildingId?: string;
  lang: string;
}

const CreateMaintenanceModal: React.FC<CreateMaintenanceModalProps> = ({
  isOpen, onClose, onCreate, buildings, initialBuildingId, lang
}) => {
  const [buildingId, setBuildingId] = useState(initialBuildingId || '');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [startDate, setStartDate] = useState(new Date().toISOString().split('T')[0]);
  const [frequency, setFrequency] = useState<MaintenanceFrequency>('YEARLY');

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!buildingId || !title || !startDate) return;

    // Calculate End Date (Start + 5 Years)
    const start = new Date(startDate);
    const end = new Date(start);
    end.setFullYear(start.getFullYear() + 5);

    const selectedBuilding = buildings.find(b => b.id === buildingId);

    onCreate({
      buildingId,
      title,
      description,
      recurrence: {
        frequency,
        interval: 1,
        startDate: new Date(startDate).toISOString(),
        endDate: end.toISOString()
      },
      syndicId: selectedBuilding?.linkedSyndicId
    });
    onClose();
  };

  const t = TRANSLATIONS[lang as keyof typeof TRANSLATIONS];

  return (
    <div className="fixed inset-0 z-[150] flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/80 backdrop-blur-sm" onClick={onClose}></div>
      <div className="bg-zinc-950 border border-zinc-800 w-full max-w-lg rounded-2xl shadow-2xl relative z-10 overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-200">

        <div className="px-6 py-5 border-b border-zinc-800 flex justify-between items-center bg-zinc-900/50">
          <h3 className="text-lg font-black uppercase tracking-widest text-orange-500">{t.createMaintPlan || 'Create Maintenance Plan'}</h3>
          <button onClick={onClose} className="p-2 hover:bg-zinc-800 rounded-full transition-colors text-zinc-500 hover:text-white">
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-5">

          <div className="space-y-1.5">
            <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.building_header || 'Building'} *</label>
            <select
              value={buildingId}
              onChange={(e) => setBuildingId(e.target.value)}
              required
              className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-3 text-sm font-bold text-white focus:border-orange-500 outline-none transition-all appearance-none"
            >
              <option value="">{t.selectOrTypeAddress || 'Select address...'}</option>
              {buildings.map(b => (
                <option key={b.id} value={b.id}>{b.address}, {b.city}</option>
              ))}
            </select>
          </div>

          <div className="space-y-1.5">
            <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.maintTitle || 'Maintenance Title'} *</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
              placeholder="e.g. Entretien Chaudière"
              className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-3 text-sm font-bold text-white focus:border-orange-500 outline-none transition-all"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.startDate || 'Start Date'} *</label>
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                required
                className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-3 text-sm font-bold text-white focus:border-orange-500 outline-none transition-all"
              />
            </div>
            <div className="space-y-1.5">
              <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.frequency || 'Frequency'}</label>
              <select
                value={frequency}
                onChange={(e) => setFrequency(e.target.value as MaintenanceFrequency)}
                className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-3 text-sm font-bold text-white focus:border-orange-500 outline-none transition-all"
              >
                <option value="YEARLY">Yearly</option>
                <option value="QUARTERLY">Quarterly</option>
                <option value="MONTHLY">Monthly</option>
              </select>
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.description} (Optional)</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Technical details..."
              className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-3 text-sm text-zinc-300 focus:border-orange-500 outline-none transition-all min-h-[80px]"
            />
          </div>

          <div className="p-4 bg-orange-500/5 border border-orange-500/10 rounded-xl flex items-start gap-3">
            <Calendar className="text-orange-500 shrink-0 mt-0.5" size={16} />
            <div>
              <p className="text-xs font-bold text-orange-200">{t.planSummary || 'Maintenance Plan Summary'}</p>
              <p className="text-[10px] text-zinc-400 mt-1 leading-relaxed">
                {t.plannedDuration || 'Planned for the next 5 years'}.
                {t.autoWeekBefore || 'Interventions will be created automatically 1 week before each due date.'}
              </p>
            </div>
          </div>

          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-3 bg-zinc-900 border border-zinc-800 rounded-xl font-bold text-xs uppercase tracking-widest text-zinc-400 hover:text-white transition-colors"
            >
              {t.cancel}
            </button>
            <button
              type="submit"
              className="flex-1 py-3 bg-orange-500 text-white rounded-xl font-bold text-xs uppercase tracking-widest hover:bg-orange-600 transition-colors shadow-lg shadow-orange-500/20"
            >
              {t.confirm}
            </button>
          </div>

        </form>
      </div>
    </div>
  );
};

export default CreateMaintenanceModal;
