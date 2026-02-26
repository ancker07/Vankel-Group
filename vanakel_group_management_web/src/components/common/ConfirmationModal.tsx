
import React, { useEffect, useRef } from 'react';
import { AlertTriangle, X } from 'lucide-react';

interface ConfirmationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  message: string;
  confirmLabel: string;
  cancelLabel: string;
  isDanger?: boolean;
}

const ConfirmationModal: React.FC<ConfirmationModalProps> = ({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmLabel,
  cancelLabel,
  isDanger = true
}) => {
  const cancelRef = useRef<HTMLButtonElement>(null);

  // Focus cancel button on mount for safety
  useEffect(() => {
    if (isOpen && cancelRef.current) {
      cancelRef.current.focus();
    }
  }, [isOpen]);

  // Handle ESC key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-in fade-in duration-200">
      <div 
        className="bg-zinc-950 border border-zinc-800 w-full max-w-sm rounded-2xl shadow-2xl relative z-20 overflow-hidden p-6 text-center"
        role="dialog"
        aria-modal="true"
        aria-labelledby="modal-title"
        aria-describedby="modal-desc"
      >
        <div className={`w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 ${isDanger ? 'bg-red-500/10 text-red-500' : 'bg-zinc-800 text-zinc-400'}`}>
          <AlertTriangle size={28} strokeWidth={2.5} />
        </div>
        
        <h4 id="modal-title" className="text-lg font-bold text-white mb-2">{title}</h4>
        <p id="modal-desc" className="text-zinc-400 text-sm mb-6 leading-relaxed">{message}</p>
        
        <div className="flex gap-3">
          <button 
            ref={cancelRef}
            onClick={onClose}
            className="flex-1 py-3 bg-zinc-900 text-zinc-400 border border-zinc-800 rounded-xl font-bold text-xs uppercase tracking-widest hover:bg-zinc-800 hover:text-white transition-colors focus:ring-2 focus:ring-brand-green outline-none"
          >
            {cancelLabel}
          </button>
          <button 
            onClick={() => {
              onConfirm();
              onClose();
            }}
            className={`flex-1 py-3 rounded-xl font-bold text-xs uppercase tracking-widest transition-colors focus:ring-2 focus:ring-offset-2 focus:ring-offset-zinc-950 outline-none ${
              isDanger 
                ? 'bg-red-500 text-white hover:bg-red-600 focus:ring-red-500' 
                : 'bg-brand-green text-brand-black hover:bg-brand-green-light focus:ring-brand-green'
            }`}
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ConfirmationModal;
