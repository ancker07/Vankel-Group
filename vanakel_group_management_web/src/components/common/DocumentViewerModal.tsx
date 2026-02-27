import React, { useEffect, useState } from 'react';
import { X, ChevronLeft, ChevronRight, Download, ExternalLink, FileText, Loader2 } from 'lucide-react';
import { Document } from '@/types';

interface DocumentViewerModalProps {
    isOpen: boolean;
    onClose: () => void;
    documents: Document[];
    initialIndex: number;
}

const DocumentViewerModal: React.FC<DocumentViewerModalProps> = ({ isOpen, onClose, documents, initialIndex }) => {
    const [currentIndex, setCurrentIndex] = useState(initialIndex);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        if (isOpen) {
            setCurrentIndex(initialIndex);
            setIsLoading(true);
        }
    }, [isOpen, initialIndex]);

    useEffect(() => {
        setIsLoading(true);
    }, [currentIndex]);

    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if (!isOpen) return;
            if (e.key === 'Escape') onClose();
            if (e.key === 'ArrowLeft') handlePrev();
            if (e.key === 'ArrowRight') handleNext();
        };
        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, [isOpen, currentIndex]);

    if (!isOpen || documents.length === 0) return null;

    const currentDoc = documents[currentIndex];
    const isImage = /\.(jpg|jpeg|png|webp|gif|svg)$/i.test(currentDoc.url);
    const isPDF = /\.pdf$/i.test(currentDoc.url);

    const handlePrev = () => {
        setCurrentIndex((prev) => (prev > 0 ? prev - 1 : documents.length - 1));
    };

    const handleNext = () => {
        setCurrentIndex((prev) => (prev < documents.length - 1 ? prev + 1 : 0));
    };

    return (
        <div className="fixed inset-0 z-[9999] flex flex-col bg-black/95 backdrop-blur-sm animate-in fade-in duration-200">
            {/* Header */}
            <div className="flex items-center justify-between p-4 border-b border-zinc-900 bg-zinc-950/50">
                <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-lg bg-zinc-900 flex items-center justify-center text-zinc-400">
                        <FileText size={20} />
                    </div>
                    <div>
                        <h4 className="text-sm font-bold text-white truncate max-w-[200px] md:max-w-md">{currentDoc.name}</h4>
                        <p className="text-[10px] text-zinc-500 uppercase font-black tracking-widest">{currentIndex + 1} / {documents.length}</p>
                    </div>
                </div>

                <div className="flex items-center gap-2">
                    <a
                        href={currentDoc.url}
                        download
                        target="_blank"
                        rel="noopener noreferrer"
                        className="p-2.5 text-zinc-400 hover:text-white hover:bg-zinc-900 rounded-xl transition-all"
                        title="Download"
                    >
                        <Download size={20} />
                    </a>
                    <a
                        href={currentDoc.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="p-2.5 text-zinc-400 hover:text-white hover:bg-zinc-900 rounded-xl transition-all"
                        title="Open in new tab"
                    >
                        <ExternalLink size={20} />
                    </a>
                    <button
                        onClick={onClose}
                        className="p-2.5 text-zinc-400 hover:text-white hover:bg-zinc-900 rounded-xl transition-all ml-2"
                    >
                        <X size={24} />
                    </button>
                </div>
            </div>

            {/* Content Viewer */}
            <div className="flex-1 relative flex items-center justify-center p-4 md:p-8">
                {documents.length > 1 && (
                    <>
                        <button
                            onClick={handlePrev}
                            className="absolute left-4 z-10 p-3 rounded-full bg-zinc-950/50 text-white hover:bg-zinc-900 transition-all border border-zinc-800"
                        >
                            <ChevronLeft size={24} />
                        </button>
                        <button
                            onClick={handleNext}
                            className="absolute right-4 z-10 p-3 rounded-full bg-zinc-950/50 text-white hover:bg-zinc-900 transition-all border border-zinc-800"
                        >
                            <ChevronRight size={24} />
                        </button>
                    </>
                )}

                <div className="w-full h-full flex items-center justify-center relative">
                    {/* Loading Indicator */}
                    {isLoading && (isImage || isPDF) && (
                        <div className="absolute inset-0 flex flex-col items-center justify-center gap-4 z-20">
                            <Loader2 className="w-12 h-12 text-brand-green animate-spin" />
                            <p className="text-zinc-500 text-[10px] font-black uppercase tracking-[0.2em] animate-pulse">Chargement...</p>
                        </div>
                    )}

                    <div className={`w-full h-full flex items-center justify-center transition-all duration-300 ${isLoading ? 'opacity-0 scale-95' : 'opacity-100 scale-100'}`}>
                        {isImage ? (
                            <img
                                src={currentDoc.url}
                                alt={currentDoc.name}
                                className="max-w-full max-h-full object-contain rounded-lg shadow-2xl"
                                onLoad={() => setIsLoading(false)}
                                onError={() => setIsLoading(false)}
                            />
                        ) : isPDF ? (
                            <iframe
                                src={`${currentDoc.url}#toolbar=0`}
                                className="w-full h-full max-w-5xl rounded-lg bg-white shadow-2xl"
                                title={currentDoc.name}
                                onLoad={() => setIsLoading(false)}
                            />
                        ) : (
                            <div className="bg-zinc-950 border border-zinc-800 p-12 rounded-3xl flex flex-col items-center gap-6 text-center max-w-sm">
                                <div className="w-20 h-20 rounded-2xl bg-zinc-900 flex items-center justify-center text-zinc-600">
                                    <FileText size={40} />
                                </div>
                                <div>
                                    <h3 className="text-xl font-bold text-white mb-2 underline decoration-brand-green/30">Preview Unavailable</h3>
                                    <p className="text-zinc-500 text-sm">We cannot preview this file type in-app. Please download it or open it in a new tab.</p>
                                </div>
                                <a
                                    href={currentDoc.url}
                                    download
                                    className="w-full py-4 bg-brand-green text-brand-black rounded-xl font-black text-xs uppercase tracking-widest hover:bg-brand-green-light transition-all shadow-lg shadow-brand-green/20 text-center"
                                >
                                    Download File
                                </a>
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* Thumbnails / Strip */}
            {documents.length > 1 && (
                <div className="p-4 bg-zinc-950/50 border-t border-zinc-900 flex justify-center gap-2 overflow-x-auto">
                    {documents.map((doc, idx) => {
                        const isDocImage = /\.(jpg|jpeg|png|webp|gif|svg)$/i.test(doc.url);
                        return (
                            <button
                                key={doc.id || idx}
                                onClick={() => setCurrentIndex(idx)}
                                className={`w-12 h-12 rounded-lg border-2 transition-all flex-shrink-0 overflow-hidden ${idx === currentIndex ? 'border-brand-green ring-2 ring-brand-green/20' : 'border-zinc-800 opacity-50 hover:opacity-100'
                                    }`}
                            >
                                {isDocImage ? (
                                    <img src={doc.url} className="w-full h-full object-cover" alt="" />
                                ) : (
                                    <div className="w-full h-full bg-zinc-900 flex items-center justify-center">
                                        <FileText size={16} className="text-zinc-600" />
                                    </div>
                                )}
                            </button>
                        );
                    })}
                </div>
            )}
        </div>
    );
};

export default DocumentViewerModal;
