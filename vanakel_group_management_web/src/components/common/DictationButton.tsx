import React, { useEffect, useRef, useState } from 'react';
import { Mic, MicOff } from 'lucide-react';
import { Language } from '@/types';

// Browser speech recognition (Chrome / Edge / Safari). Not in TypeScript's DOM types.
const SpeechRecognitionImpl: any =
    typeof window !== 'undefined' ? (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition : null;

const SPEECH_LANG: Record<string, string> = { FR: 'fr-BE', NL: 'nl-BE', EN: 'en-GB' };

// Phones: Android Chrome repeats words in "continuous" mode, so there each phrase is one
// recognition session and a new one is started automatically until the user stops.
const IS_MOBILE = typeof navigator !== 'undefined' && /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);

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
    const wantListening = useRef(false); // true until the user stops (or a real error happens)
    const onTextRef = useRef(onText);
    onTextRef.current = onText;

    useEffect(
        () => () => {
            wantListening.current = false;
            recognitionRef.current?.abort();
        },
        []
    );

    const fail = (message: string) => {
        wantListening.current = false;
        setError(message);
    };

    const startSession = () => {
        const recognition = new SpeechRecognitionImpl();
        recognition.lang = SPEECH_LANG[lang] || 'fr-BE';
        recognition.continuous = !IS_MOBILE;
        recognition.interimResults = false;

        recognition.onresult = (event: any) => {
            for (let i = event.resultIndex; i < event.results.length; i++) {
                if (event.results[i].isFinal) {
                    const text = event.results[i][0].transcript.trim();
                    if (text) onTextRef.current(text);
                }
            }
        };

        recognition.onerror = (event: any) => {
            switch (event.error) {
                case 'no-speech': // silence: the session just ends
                case 'aborted':
                    break;
                case 'not-allowed':
                case 'service-not-allowed':
                    fail(window.isSecureContext
                        ? (t.dictate_denied || 'Microphone access was refused. Allow it in the browser address bar.')
                        : (t.dictate_insecure || 'Voice dictation only works on a secure (https) page.'));
                    break;
                case 'audio-capture':
                    fail(t.dictate_no_mic || 'No microphone was found.');
                    break;
                case 'network':
                    fail(t.dictate_network || 'Voice recognition needs an internet connection.');
                    break;
                case 'language-not-supported':
                    fail(t.dictate_language || 'This language is not supported for voice dictation in this browser.');
                    break;
                default:
                    fail(t.dictate_retry || 'Voice dictation stopped. Please try again.');
            }
        };

        recognition.onend = () => {
            // Browsers end a session after a pause; keep listening until the user presses stop
            if (wantListening.current) {
                try {
                    startSession();
                    return;
                } catch {
                    wantListening.current = false;
                }
            }
            setIsListening(false);
        };

        recognitionRef.current = recognition;
        recognition.start();
    };

    const toggle = () => {
        if (!SpeechRecognitionImpl) {
            setError(t.dictate_unsupported || 'Voice dictation is not supported in this browser. Use Chrome, Edge or Safari.');
            return;
        }
        if (isListening) {
            wantListening.current = false;
            recognitionRef.current?.stop();
            setIsListening(false);
            return;
        }

        setError('');
        wantListening.current = true;
        try {
            startSession();
            setIsListening(true);
        } catch {
            wantListening.current = false;
            setError(t.dictate_retry || 'Voice dictation stopped. Please try again.');
        }
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
