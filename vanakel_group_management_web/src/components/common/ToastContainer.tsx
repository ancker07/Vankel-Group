
import React, { useEffect, useState } from 'react';
import { Bell, X } from 'lucide-react';

interface ToastMessage {
  id: string;
  title: string;
  message: string;
}

interface ToastContainerProps {
  toasts: ToastMessage[];
  onRemove: (id: string) => void;
}

const ToastContainer: React.FC<ToastContainerProps> = ({ toasts, onRemove }) => {
  return (
    <div className="fixed bottom-4 right-4 z-[200] flex flex-col gap-2 pointer-events-none w-full max-w-sm px-4 md:px-0">
      {toasts.map(toast => (
        <Toast key={toast.id} toast={toast} onRemove={onRemove} />
      ))}
    </div>
  );
};

const Toast: React.FC<{ toast: ToastMessage, onRemove: (id: string) => void }> = ({ toast, onRemove }) => {
  useEffect(() => {
    const timer = setTimeout(() => {
      onRemove(toast.id);
    }, 5000);
    return () => clearTimeout(timer);
  }, [toast.id, onRemove]);

  return (
    <div className="bg-zinc-950 border border-brand-green/30 text-white p-4 rounded-xl shadow-2xl shadow-black/50 flex items-start gap-3 animate-in slide-in-from-bottom-5 fade-in duration-300 pointer-events-auto">
      <div className="p-2 bg-brand-green/10 rounded-full text-brand-green shrink-0">
        <Bell size={16} />
      </div>
      <div className="flex-1 min-w-0">
        <h5 className="font-bold text-sm mb-0.5">{toast.title}</h5>
        <p className="text-xs text-zinc-400 line-clamp-2">{toast.message}</p>
      </div>
      <button onClick={() => onRemove(toast.id)} className="text-zinc-500 hover:text-white transition-colors">
        <X size={14} />
      </button>
    </div>
  );
};

export default ToastContainer;
