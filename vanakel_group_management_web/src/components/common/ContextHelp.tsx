
import React, { useState } from 'react';
import { Info } from 'lucide-react';

interface ContextHelpProps {
  text: string;
}

const ContextHelp: React.FC<ContextHelpProps> = ({ text }) => {
  const [isVisible, setIsVisible] = useState(false);

  return (
    <div 
      className="relative inline-flex items-center ml-1.5"
      onMouseEnter={() => setIsVisible(true)}
      onMouseLeave={() => setIsVisible(false)}
      onClick={() => setIsVisible(!isVisible)}
    >
      <Info size={12} className="text-zinc-500 hover:text-brand-green cursor-pointer transition-colors" />
      {isVisible && (
        <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-48 p-2 bg-zinc-900 border border-zinc-800 rounded-lg shadow-xl z-50 animate-in fade-in zoom-in-95 duration-200 pointer-events-none">
          <p className="text-[10px] text-zinc-300 leading-tight text-center font-medium">
            {text}
          </p>
          <div className="absolute top-full left-1/2 -translate-x-1/2 -mt-1 border-4 border-transparent border-t-zinc-900"></div>
        </div>
      )}
    </div>
  );
};

export default ContextHelp;
