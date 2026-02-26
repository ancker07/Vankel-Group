
import React, { useState } from 'react';
import { X } from 'lucide-react';
import { Syndic, Language } from '@/types';
import { TRANSLATIONS } from '@/utils/constants';

interface CreateSyndicModalProps {
  isOpen: boolean;
  onClose: () => void;
  onCreate: (syndic: Syndic) => void;
  lang: Language;
}

const CreateSyndicModal: React.FC<CreateSyndicModalProps> = ({ isOpen, onClose, onCreate, lang }) => {
  const t = TRANSLATIONS[lang];
  const [companyName, setCompanyName] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [gsm, setGsm] = useState('');
  const [email, setEmail] = useState('');

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!companyName || !firstName || !lastName || !gsm || !email) return;

    const newSyndic: Syndic = {
      id: `syn-new-${Date.now()}`,
      companyName,
      contactPerson: `${firstName} ${lastName}`,
      phone: gsm,
      landline: '',
      email,
      address: '' // Optional in this flow
    };

    onCreate(newSyndic);
    // Reset form
    setCompanyName('');
    setFirstName('');
    setLastName('');
    setGsm('');
    setEmail('');
  };

  return (
    <div className="fixed inset-0 z-[120] flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={onClose}></div>
      <div className="bg-zinc-950 border border-zinc-800 w-full max-w-md rounded-2xl shadow-2xl relative z-10 overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-200">

        {/* Header */}
        <div className="px-6 py-4 border-b border-zinc-900 flex justify-between items-center bg-zinc-900/50">
          <h3 className="text-sm font-black uppercase tracking-widest text-brand-green">{t.createSyndic}</h3>
          <button onClick={onClose} className="p-1 hover:text-white text-zinc-500 transition-colors">
            <X size={18} />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div className="space-y-1.5">
            <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.companyName} *</label>
            <input
              type="text"
              required
              value={companyName}
              onChange={e => setCompanyName(e.target.value)}
              className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2.5 text-sm font-bold text-white focus:border-brand-green outline-none transition-all"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.contactFirstName} *</label>
              <input
                type="text"
                required
                value={firstName}
                onChange={e => setFirstName(e.target.value)}
                className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2.5 text-sm font-bold text-white focus:border-brand-green outline-none transition-all"
              />
            </div>
            <div className="space-y-1.5">
              <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.contactLastName} *</label>
              <input
                type="text"
                required
                value={lastName}
                onChange={e => setLastName(e.target.value)}
                className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2.5 text-sm font-bold text-white focus:border-brand-green outline-none transition-all"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.gsm} *</label>
            <input
              type="tel"
              required
              placeholder="+32..."
              value={gsm}
              onChange={e => setGsm(e.target.value)}
              className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2.5 text-sm font-bold text-white focus:border-brand-green outline-none transition-all"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.email} *</label>
            <input
              type="email"
              required
              value={email}
              onChange={e => setEmail(e.target.value)}
              className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2.5 text-sm font-bold text-white focus:border-brand-green outline-none transition-all"
            />
          </div>

          <div className="pt-4 flex gap-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-3 bg-zinc-900 border border-zinc-800 rounded-xl font-black text-xs uppercase tracking-widest hover:bg-zinc-800 transition-colors text-zinc-400"
            >
              {t.cancel}
            </button>
            <button
              type="submit"
              className="flex-1 py-3 bg-brand-green text-brand-black rounded-xl font-black text-xs uppercase tracking-widest hover:bg-brand-green-light transition-colors shadow-lg shadow-brand-green/10"
            >
              {t.save}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CreateSyndicModal;
