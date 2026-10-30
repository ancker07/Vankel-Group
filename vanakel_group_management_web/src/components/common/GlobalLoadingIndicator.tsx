import React, { useEffect, useState, useSyncExternalStore } from 'react';
import { Loader2 } from 'lucide-react';
import { loadingStore } from '@/lib/loadingStore';

// Wait a moment before showing anything so fast requests don't flicker
const BAR_DELAY_MS = 150;
const PILL_DELAY_MS = 600;

const useDelayedFlag = (active: boolean, delayMs: number) => {
  const [shown, setShown] = useState(false);
  useEffect(() => {
    if (!active) {
      setShown(false);
      return;
    }
    const timer = setTimeout(() => setShown(true), delayMs);
    return () => clearTimeout(timer);
  }, [active, delayMs]);
  return shown;
};

/**
 * App-wide loading feedback, driven by in-flight API requests:
 *  - a slim animated bar at the top for any request
 *  - a "Working…" pill for saves/sends/other actions (or slow loads)
 */
const GlobalLoadingIndicator: React.FC = () => {
  const { pending, pendingActions } = useSyncExternalStore(
    loadingStore.subscribe,
    loadingStore.getSnapshot
  );

  const showBar = useDelayedFlag(pending > 0, BAR_DELAY_MS);
  const actionPending = useDelayedFlag(pendingActions > 0, BAR_DELAY_MS);
  const slowLoad = useDelayedFlag(pending > 0, PILL_DELAY_MS * 2);
  const showPill = actionPending || slowLoad;

  return (
    <>
      <div
        aria-hidden={!showBar}
        className={`fixed top-0 left-0 right-0 z-[10000] h-1 overflow-hidden pointer-events-none transition-opacity duration-200 ${showBar ? 'opacity-100' : 'opacity-0'}`}
      >
        <div className="h-full w-1/3 bg-brand-green rounded-full animate-[global-loading-slide_1.1s_ease-in-out_infinite]" />
      </div>

      {showPill && (
        <div
          role="status"
          aria-live="polite"
          className="fixed bottom-24 md:bottom-6 left-1/2 -translate-x-1/2 z-[10000] flex items-center gap-2 px-4 py-2.5 rounded-full bg-zinc-900/95 border border-zinc-700 text-white text-xs font-bold shadow-xl pointer-events-none"
        >
          <Loader2 size={14} className="animate-spin text-brand-green" />
          Loading…
        </div>
      )}
      <style>{`@keyframes global-loading-slide { 0% { transform: translateX(-100%); } 100% { transform: translateX(400%); } }`}</style>
    </>
  );
};

export default GlobalLoadingIndicator;
