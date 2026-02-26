import React, { useState, useEffect, useLayoutEffect, useRef } from 'react';
import { X, ChevronRight, ChevronLeft, Check } from 'lucide-react';
import { Language } from '@/types';
import { ONBOARDING_STEPS } from '@/utils/onboardingSteps';

interface OnboardingTourProps {
  isActive: boolean;
  onClose: (finished: boolean) => void;
  lang: Language;
  currentTab: string;
  onTabChange: (tabId: string) => void;
}

const STORAGE_KEY = 'vanakel_onboarding_completed';
const MARGIN = 16; // Safe distance from screen edges
const TOOLTIP_MAX_WIDTH = 360;

const OnboardingTour: React.FC<OnboardingTourProps> = ({
  isActive, onClose, lang, currentTab, onTabChange
}) => {
  const [stepIndex, setStepIndex] = useState(0);
  const [rect, setRect] = useState<DOMRect | null>(null);
  const [isReady, setIsReady] = useState(false);
  const tooltipRef = useRef<HTMLDivElement>(null);

  // Force update for resize events
  const [, forceUpdate] = useState({});

  const currentStep = ONBOARDING_STEPS[stepIndex];
  const totalSteps = ONBOARDING_STEPS.length;

  // Persistence check
  useEffect(() => {
    if (!isActive) return;
    // We assume parent controls visibility based on storage for auto-start
  }, [isActive]);

  // Navigate Tab if needed
  useEffect(() => {
    if (!isActive || !currentStep) return;

    if (currentStep.requiredTab && currentStep.requiredTab !== currentTab) {
      setIsReady(false);
      onTabChange(currentStep.requiredTab);
    } else {
      setIsReady(true);
    }
  }, [isActive, stepIndex, currentStep, currentTab, onTabChange]);

  // Find Target Element logic
  const findTarget = () => {
    if (!isActive || !currentStep) return;

    let el: HTMLElement | null = null;

    // 1. Try Desktop ID
    if (currentStep.targetId) {
      el = document.getElementById(currentStep.targetId);
    }

    // 2. Try Mobile ID fallback
    if (!el && currentStep.mobileTargetId) {
      el = document.getElementById(currentStep.mobileTargetId);
    }

    if (el) {
      const r = el.getBoundingClientRect();
      // Ensure element is actually in view and has size
      if (r.width > 0 && r.height > 0) {
        setRect(r);
        // Scroll target into view on ALL devices to ensure visibility
        el.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'center' });
      } else {
        setRect(null);
      }
    } else {
      setRect(null); // Fallback to center
    }
  };

  // Poll for target visibility (handles animations/mounting delays)
  useEffect(() => {
    if (!isActive || !isReady) return;

    // Immediate attempt
    findTarget();

    // Retry loop
    const interval = setInterval(findTarget, 200);
    const timeout = setTimeout(() => clearInterval(interval), 2000); // Stop looking after 2s

    const handleResize = () => {
      findTarget();
      forceUpdate({});
    };

    window.addEventListener('resize', handleResize);
    window.addEventListener('scroll', handleResize, true); // Capture scroll

    return () => {
      clearInterval(interval);
      clearTimeout(timeout);
      window.removeEventListener('resize', handleResize);
      window.removeEventListener('scroll', handleResize, true);
    };
  }, [isActive, isReady, stepIndex, currentStep]);

  const handleNext = () => {
    if (stepIndex < totalSteps - 1) {
      setStepIndex(prev => prev + 1);
    } else {
      handleComplete();
    }
  };

  const handlePrev = () => {
    if (stepIndex > 0) {
      setStepIndex(prev => prev - 1);
    }
  };

  const handleSkip = () => {
    localStorage.setItem(STORAGE_KEY, 'true');
    onClose(false);
  };

  const handleComplete = () => {
    localStorage.setItem(STORAGE_KEY, 'true');
    onClose(true);
  };

  // Calculate Viewport-Safe Position
  const getTooltipStyle = (): React.CSSProperties => {
    if (typeof window !== 'undefined' && window.innerWidth < 640) {
      // MOBILE: Smart Bottom Sheet / Top Sheet
      // If the highlighted element is in the bottom half, show tip at top.
      // If in top half, show tip at bottom.

      const isBottomHalf = rect && (rect.top > window.innerHeight / 2);
      const verticalStyle: React.CSSProperties = isBottomHalf
        ? { top: 16, bottom: 'auto' } // Show at top
        : { bottom: 16, top: 'auto' }; // Show at bottom

      return {
        position: 'fixed',
        left: '50%',
        transform: 'translateX(-50%)',
        width: '92vw',
        maxWidth: 420,
        maxHeight: '40vh',
        margin: 0,
        zIndex: 10000,
        ...verticalStyle
      };
    }

    if (!rect) {
      return {
        position: 'fixed',
        top: '50%',
        left: '50%',
        transform: 'translate(-50%, -50%)',
        maxWidth: TOOLTIP_MAX_WIDTH,
        zIndex: 10000
      };
    }

    // 2. Desktop Target Positioning
    const placement = currentStep.placement || 'bottom';
    const viewportW = window.innerWidth;
    const viewportH = window.innerHeight;

    // Estimated dimensions
    const tooltipH = tooltipRef.current?.offsetHeight || 300;
    const tooltipW = Math.min(TOOLTIP_MAX_WIDTH, viewportW - (MARGIN * 2));

    let top = 0;
    let left = 0;

    // Preferred Positions
    switch (placement) {
      case 'top':
        top = rect.top - tooltipH - MARGIN;
        left = rect.left + (rect.width / 2) - (tooltipW / 2);
        break;
      case 'bottom':
        top = rect.bottom + MARGIN;
        left = rect.left + (rect.width / 2) - (tooltipW / 2);
        break;
      case 'left':
        top = rect.top + (rect.height / 2) - (tooltipH / 2);
        left = rect.left - tooltipW - MARGIN;
        break;
      case 'right':
        top = rect.top + (rect.height / 2) - (tooltipH / 2);
        left = rect.right + MARGIN;
        break;
      case 'center':
      default:
        top = (viewportH / 2) - (tooltipH / 2);
        left = (viewportW / 2) - (tooltipW / 2);
    }

    // 3. Flip Logic (Simple)
    if (placement === 'bottom' && (top + tooltipH > viewportH - MARGIN)) {
      top = rect.top - tooltipH - MARGIN;
    }
    if (placement === 'top' && (top < MARGIN)) {
      top = rect.bottom + MARGIN;
    }

    // 4. Clamping (Hard Limits)
    left = Math.max(MARGIN, Math.min(left, viewportW - tooltipW - MARGIN));
    top = Math.max(MARGIN, Math.min(top, viewportH - tooltipH - MARGIN));

    return {
      position: 'fixed',
      top: top,
      left: left,
      width: tooltipW,
      maxWidth: '92vw',
      maxHeight: `calc(100vh - ${MARGIN * 2}px)`,
      zIndex: 10000,
    };
  };

  if (!isActive) return null;

  return (
    <div className="fixed inset-0 z-[9999] pointer-events-none">
      {/* 
        Spotlight Overlay 
        - blocks interaction except through the hole
      */}
      <div
        className="absolute inset-0 bg-black/70 pointer-events-auto transition-all duration-300 ease-out"
        style={{
          clipPath: rect
            ? `polygon(
                0% 0%, 0% 100%, 
                ${rect.left}px 100%, 
                ${rect.left}px ${rect.top}px, 
                ${rect.right}px ${rect.top}px, 
                ${rect.right}px ${rect.bottom}px, 
                ${rect.left}px ${rect.bottom}px, 
                ${rect.left}px 100%, 
                100% 100%, 100% 0%
              )`
            : undefined
        }}
      />

      {/* Target Highlight Border & Glow - Ensure High Visibility on Mobile */}
      {rect && (
        <div
          className="absolute border-2 border-brand-green rounded-xl shadow-[0_0_30px_rgba(34,197,94,0.9)] transition-all duration-300 ease-out pointer-events-none animate-pulse"
          style={{
            top: rect.top - 4,
            left: rect.left - 4,
            width: rect.width + 8,
            height: rect.height + 8,
            zIndex: 10001
          }}
        />
      )}

      {/* 
        Tooltip Card 
      */}
      <div
        ref={tooltipRef}
        className="bg-zinc-950 border border-zinc-800 rounded-2xl shadow-2xl pointer-events-auto flex flex-col transition-all duration-300 ease-out"
        style={getTooltipStyle()}
      >
        {/* Header */}
        <div className="flex-shrink-0 p-4 md:p-5 pb-2 flex justify-between items-start">
          <div className="flex items-center gap-2">
            <span className="text-[10px] font-black text-brand-green uppercase tracking-widest bg-brand-green/10 px-2 py-1 rounded">
              {t.tip || 'TIP'} {stepIndex + 1}/{totalSteps}
            </span>
          </div>
          <button
            onClick={handleSkip}
            className="text-zinc-500 hover:text-white transition-colors p-1 -mr-2 -mt-2"
            title={t.close || 'Close'}
          >
            <X size={18} />
          </button>
        </div>

        {/* Scrollable Content */}
        <div className="flex-1 overflow-y-auto px-4 md:px-5 py-2">
          <h3 className="text-base md:text-xl font-bold text-white mb-2 md:mb-3 leading-tight">
            {currentStep.title[lang]}
          </h3>
          <p className="text-xs md:text-sm text-zinc-300 leading-relaxed">
            {currentStep.description[lang]}
          </p>
        </div>

        {/* Footer */}
        <div className="flex-shrink-0 p-4 md:p-5 pt-3 md:pt-4 border-t border-zinc-900 bg-zinc-900/30 flex flex-col-reverse sm:flex-row sm:items-center justify-between gap-3 rounded-b-2xl">
          <button
            onClick={handleSkip}
            className="text-xs font-bold text-zinc-500 hover:text-white transition-colors px-2 py-2 text-center sm:text-left hidden sm:block"
          >
            {t.close || 'Passer'}
          </button>

          <div className="flex gap-2 w-full sm:w-auto">
            {stepIndex > 0 && (
              <button
                onClick={handlePrev}
                className="flex-1 sm:flex-none px-4 py-2.5 bg-zinc-800 hover:bg-zinc-700 text-white rounded-xl font-bold transition-colors flex items-center justify-center"
              >
                <ChevronLeft size={16} />
              </button>
            )}

            <button
              onClick={handleNext}
              className="flex-1 sm:flex-none px-6 py-2.5 bg-brand-green text-brand-black hover:bg-brand-green-light rounded-xl font-black text-xs uppercase tracking-wider transition-colors shadow-lg shadow-brand-green/10 flex items-center justify-center gap-2"
            >
              {stepIndex === totalSteps - 1 ? (t.finish || 'Terminer') : (t.continue || 'Continuer')}
              {stepIndex === totalSteps - 1 ? <Check size={14} /> : <ChevronRight size={14} />}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

// Fallback translations inside component to avoid breaking if constants missing
const t = {
  tip: 'TIP',
  close: 'Passer',
  finish: 'Terminer',
  continue: 'Continuer'
};

export default OnboardingTour;