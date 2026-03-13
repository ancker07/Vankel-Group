import React from "react";
import { Globe, Mail, Info } from "lucide-react";

const Footer: React.FC = () => {
  return (
    <footer className="mt-16 border-t border-zinc-900 bg-zinc-950">
      <div className="max-w-6xl mx-auto px-4 py-6 flex flex-col md:flex-row items-center justify-between gap-4">

        {/* Left */}
        <div className="text-sm text-zinc-500">
          © {new Date().getFullYear()} Codysterie. All rights reserved.
        </div>

        {/* Center */}
        <div className="flex items-center gap-4 text-sm text-zinc-400">

          <a
            href="https://codysterie.be/"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 hover:text-brand-green transition"
          >
            <Globe size={16} />
            codysterie.be
          </a>

          <span className="text-zinc-700">|</span>

          <span className="flex items-center gap-2">
            <Info size={16} />
            Admin Dashboard
          </span>

        </div>

        {/* Right */}
        <div className="text-xs text-zinc-600">
          Contact submissions management
        </div>

      </div>
    </footer>
  );
};

export default Footer;