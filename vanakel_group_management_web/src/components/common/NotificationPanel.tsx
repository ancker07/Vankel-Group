
import React from 'react';
import { X, Check } from 'lucide-react';
import { AppNotification } from '@/types';

interface NotificationPanelProps {
  notifications: AppNotification[];
  onClose: () => void;
  onMarkRead: (id: string) => void;
  onMarkAllRead: () => void;
  onSelect: (id: string) => void;
  title: string;
}

const NotificationPanel: React.FC<NotificationPanelProps> = ({
  notifications, onClose, onMarkRead, onMarkAllRead, onSelect, title
}) => {
  return (
    <div className="absolute top-full right-0 mt-2 w-screen max-w-sm md:w-96 bg-zinc-950 border border-zinc-800 rounded-b-2xl md:rounded-2xl shadow-2xl z-[100] overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200 flex flex-col max-h-[80vh] md:max-h-[600px]">
      <div className="p-4 border-b border-zinc-900 flex justify-between items-center bg-zinc-900/50 shrink-0">
        <h4 className="font-bold text-white text-sm">{title} ({notifications.filter(n => !n.read).length})</h4>
        <div className="flex items-center gap-3">
          <button
            onClick={onMarkAllRead}
            className="text-[10px] font-bold text-brand-green uppercase hover:underline flex items-center gap-1"
            title="Mark all as read"
          >
            <Check size={12} /> All Read
          </button>
          <button onClick={onClose} className="p-1 hover:bg-zinc-800 rounded-full transition-colors">
            <X size={16} className="text-zinc-500 hover:text-white" />
          </button>
        </div>
      </div>

      <div className="overflow-y-auto flex-1">
        {notifications.length === 0 && (
          <div className="flex flex-col items-center justify-center p-8 text-zinc-500">
            <p className="text-xs">No notifications yet.</p>
          </div>
        )}
        {notifications.map(n => (
          <div
            key={n.id}
            className={`p-4 border-b border-zinc-900 hover:bg-zinc-900/50 transition-colors cursor-pointer group ${!n.read ? 'bg-zinc-900/30' : ''}`}
            onClick={() => {
              if (n.interventionId) onSelect(n.interventionId);
              onMarkRead(n.id);
              onClose();
            }}
          >
            <div className="flex justify-between items-start mb-1">
              <p className={`text-[9px] font-black uppercase tracking-wider ${n.type === 'CREATED' ? 'text-brand-green' :
                  n.type === 'STATUS_CHANGE' ? 'text-orange-500' :
                    'text-blue-400'
                }`}>
                {n.type.replace('_', ' ')}
              </p>
              {!n.read && <div className="w-1.5 h-1.5 rounded-full bg-brand-green shrink-0 animate-pulse"></div>}
            </div>
            <p className={`text-sm mb-1 ${!n.read ? 'font-bold text-white' : 'font-medium text-zinc-300'}`}>
              {n.title}
            </p>
            <p className="text-xs text-zinc-500 truncate mb-1">{n.buildingAddress}</p>
            <p className="text-[10px] text-zinc-600 text-right font-mono">
              {new Date(n.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} · {new Date(n.timestamp).toLocaleDateString()}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
};

export default NotificationPanel;
