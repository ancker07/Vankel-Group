import React, { useEffect, useRef, useState } from 'react';
import { Mic, MicOff } from 'lucide-react';
import { Language } from '@/types';

// Browser speech recognition (Chrome / Edge / Safari). Not in TypeScript's DOM types.
const SpeechRecognitionImpl: any =
    typeof window !== 'undefined' ? (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition : null;

const SPEECH_LANG: Record<string, string> = { FR: 'fr-BE', NL: 'nl-BE', EN: 'en-GB' };

interface DictationButtonProps {
    lang: Language;
    /** Receives each finished sentence; the caller appends it to its text. */
    onText: (text: string) => void;
    disabled?: boolean;
    t: any;
}

/** Microphone button: speak and the words are written into the note (then "Improve with AI" can polish it). */
const DictationButton: React.FC<DictationButtonProps> = ({ lang, onText, disabled, t }) => {
    const [isListening, setIsListening] = useState(false);
    const [error, setError] = useState('');
    const recognitionRef = useRef<any>(null);
    const onTextRef = useRef(onText);
    onTextRef.current = onText;

    useEffect(() => () => recognitionRef.current?.abort(), []);

    const toggle = () => {
        if (!SpeechRecognitionImpl) {
            setError(t.dictate_unsupported || 'Voice dictation is not supported in this browser. Use Chrome or Edge.');
            return;
        }
        if (isListening) {
            recognitionRef.current?.stop();
            return;
        }

        const recognition = new SpeechRecognitionImpl();
        recognition.lang = SPEECH_LANG[lang] || 'fr-BE';
        recognition.continuous = true;
        recognition.interimResults = false;
        recognition.onresult = (event: any) => {
            for (let i = event.resultIndex; i < event.results.length; i++) {
                if (event.results[i].isFinal) onTextRef.current(event.results[i][0].transcript.trim());
            }
        };
        recognition.onerror = (event: any) => {
            if (event.error === 'not-allowed') setError('Microphone access was refused.');
        };
        recognition.onend = () => setIsListening(false);

        setError('');
        recognitionRef.current = recognition;
        recognition.start();
        setIsListening(true);
    };

    return (
        <span className="inline-flex flex-col items-end">
            <button
                type="button"
                onClick={toggle}
                disabled={disabled}
                title={isListening ? (t.dictate_stop || 'Stop dictation') : (t.dictate || 'Dictate')}
                className={`flex items-center gap-1.5 text-[9px] font-black uppercase tracking-widest px-2 py-1 rounded border transition-all disabled:opacity-50 min-h-[30px] ${isListening
                    ? 'bg-red-500/10 border-red-500/40 text-red-400 animate-pulse'
                    : 'bg-zinc-900 border-zinc-800 text-zinc-500 hover:text-white'}`}
            >
                {isListening ? <MicOff size={12} /> : <Mic size={12} />}
                {isListening ? (t.dictate_listening || 'Listening…') : (t.dictate || 'Dictate')}
            </button>
            {error && <span className="text-[10px] text-red-400 mt-1 max-w-[220px] text-right">{error}</span>}
        </span>
    );
};

export default DictationButton;
