
import React, { useState, useEffect } from 'react';
import { X, ChevronLeft, ChevronRight, Check } from 'lucide-react';

interface DatePickerModalProps {
  isOpen: boolean;
  onClose: () => void;
  onValidate: (date: string) => void;
  initialDate?: string;
  title?: string;
  cancelLabel?: string;
  validateLabel?: string;
}

const DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

const DatePickerModal: React.FC<DatePickerModalProps> = ({ 
  isOpen, 
  onClose, 
  onValidate, 
  initialDate, 
  title = "Select Date",
  cancelLabel = "Cancel",
  validateLabel = "Validate"
}) => {
  const [viewDate, setViewDate] = useState(new Date());
  const [selectedDate, setSelectedDate] = useState<Date | null>(null);

  useEffect(() => {
    if (isOpen) {
      const d = initialDate ? new Date(initialDate) : new Date();
      if (!isNaN(d.getTime())) {
        setViewDate(d);
        if (initialDate) setSelectedDate(d);
      } else {
        setViewDate(new Date());
        setSelectedDate(null);
      }
    }
  }, [isOpen, initialDate]);

  if (!isOpen) return null;

  const getDaysInMonth = (year: number, month: number) => new Date(year, month + 1, 0).getDate();
  const getFirstDayOfMonth = (year: number, month: number) => new Date(year, month, 1).getDay();

  const handlePrevMonth = () => {
    setViewDate(new Date(viewDate.getFullYear(), viewDate.getMonth() - 1, 1));
  };

  const handleNextMonth = () => {
    setViewDate(new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 1));
  };

  const handleDayClick = (day: number) => {
    const newDate = new Date(viewDate.getFullYear(), viewDate.getMonth(), day);
    setSelectedDate(newDate);
  };

  const handleValidate = () => {
    if (selectedDate) {
      // Return ISO string date part only or full ISO, but formatted locally to avoid timezone shifts affecting the day
      // We want YYYY-MM-DD for the input value
      const year = selectedDate.getFullYear();
      const month = String(selectedDate.getMonth() + 1).padStart(2, '0');
      const day = String(selectedDate.getDate()).padStart(2, '0');
      const dateString = `${year}-${month}-${day}`; // Keeps it simple for inputs
      onValidate(dateString);
      onClose();
    }
  };

  const daysInMonth = getDaysInMonth(viewDate.getFullYear(), viewDate.getMonth());
  const firstDay = getFirstDayOfMonth(viewDate.getFullYear(), viewDate.getMonth());
  
  // Create array for empty slots
  const blanks = Array(firstDay).fill(null);
  // Create array for days
  const days = Array.from({ length: daysInMonth }, (_, i) => i + 1);

  return (
    <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-zinc-950 border border-zinc-800 rounded-2xl w-full max-w-sm shadow-2xl overflow-hidden flex flex-col">
        {/* Header */}
        <div className="p-4 border-b border-zinc-900 flex items-center justify-between bg-zinc-900/50">
          <h3 className="font-bold text-white text-sm uppercase tracking-wider">{title}</h3>
          <button onClick={onClose} className="text-zinc-500 hover:text-white p-1">
            <X size={20} />
          </button>
        </div>

        {/* Calendar Controls */}
        <div className="p-4 pb-2 flex items-center justify-between">
          <button onClick={handlePrevMonth} className="p-2 hover:bg-zinc-900 rounded-lg text-zinc-400 hover:text-white transition-colors">
            <ChevronLeft size={20} />
          </button>
          <div className="font-bold text-white text-lg">
            {MONTHS[viewDate.getMonth()]} <span className="text-brand-green">{viewDate.getFullYear()}</span>
          </div>
          <button onClick={handleNextMonth} className="p-2 hover:bg-zinc-900 rounded-lg text-zinc-400 hover:text-white transition-colors">
            <ChevronRight size={20} />
          </button>
        </div>

        {/* Days Grid */}
        <div className="p-4 pt-0">
          <div className="grid grid-cols-7 mb-2">
            {DAYS.map(d => (
              <div key={d} className="text-center text-[10px] font-black text-zinc-600 uppercase tracking-widest py-2">
                {d}
              </div>
            ))}
          </div>
          <div className="grid grid-cols-7 gap-1">
            {blanks.map((_, i) => (
              <div key={`blank-${i}`} className="aspect-square"></div>
            ))}
            {days.map(d => {
              const isSelected = selectedDate && 
                selectedDate.getDate() === d && 
                selectedDate.getMonth() === viewDate.getMonth() && 
                selectedDate.getFullYear() === viewDate.getFullYear();
                
              return (
                <button
                  key={d}
                  onClick={() => handleDayClick(d)}
                  className={`aspect-square rounded-lg text-sm font-bold flex items-center justify-center transition-all ${
                    isSelected 
                      ? 'bg-brand-green text-brand-black shadow-lg shadow-brand-green/20 scale-105' 
                      : 'text-zinc-300 hover:bg-zinc-900 hover:text-white'
                  }`}
                >
                  {d}
                </button>
              );
            })}
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-zinc-900 bg-zinc-900/30 flex gap-3">
          <button 
            onClick={onClose}
            className="flex-1 py-3 bg-zinc-900 text-zinc-500 rounded-xl font-black text-xs uppercase tracking-widest hover:bg-zinc-800 transition-colors"
          >
            {cancelLabel}
          </button>
          <button 
            onClick={handleValidate}
            disabled={!selectedDate}
            className={`flex-1 py-3 rounded-xl font-black text-xs uppercase tracking-widest flex items-center justify-center gap-2 transition-all ${
              selectedDate 
                ? 'bg-brand-green text-brand-black hover:bg-brand-green-light shadow-lg shadow-brand-green/20' 
                : 'bg-zinc-900 text-zinc-600 cursor-not-allowed'
            }`}
          >
            <Check size={14} /> {validateLabel}
          </button>
        </div>
      </div>
    </div>
  );
};

export default DatePickerModal;
