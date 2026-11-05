import React, { useEffect, useRef, useState } from 'react';
import { Mic, MicOff } from 'lucide-react';
import { Language } from '@/types';
import { dataService } from '@/services/dataService';
import { CloudDictation, cloudDictationSupported } from '@/services/cloudDictation';

// Browser speech recognition (Chrome / Edge / Safari). Not in TypeScript's DOM types.
const SpeechRecognitionImpl: any =
    typeof window !== 'undefined' ? (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition : null;

const SPEECH_LANG: Record<string, string> = { FR: 'fr-FR', NL: 'nl-NL', EN: 'en-GB' };

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
    const [isProcessing, setIsProcessing] = useState(false);
    const recognitionRef = useRef<any>(null);
    const cloudRef = useRef<CloudDictation | null>(null);
    const startingRef = useRef(false);
    const networkErrors = useRef(0);
    const wantListening = useRef(false); // true until the user stops (or a real error happens)
    const onTextRef = useRef(onText);
    onTextRef.current = onText;

    useEffect(
        () => () => {
            wantListening.current = false;
            recognitionRef.current?.abort();
            cloudRef.current?.abort();
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
                    if (text) {
                        networkErrors.current = 0;
                        onTextRef.current(text);
                    }
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
                    // Often a passing drop: onend restarts the session a few times before giving up
                    if (++networkErrors.current <= 3) break;
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
                    // the previous session was still closing: try once more shortly
                    setTimeout(() => {
                        if (!wantListening.current) return;
                        try {
                            startSession();
                        } catch {
                            wantListening.current = false;
                            setIsListening(false);
                            setError(t.dictate_retry || 'Voice dictation stopped. Please try again.');
                        }
                    }, 400);
                    return;
                }
            }
            setIsListening(false);
        };

        recognitionRef.current = recognition;
        recognition.start();
    };

    const startNative = () => {
        if (!SpeechRecognitionImpl) {
            setError(t.dictate_unsupported || 'Voice dictation is not supported in this browser. Use Chrome, Edge or Safari.');
            setIsListening(false);
            return;
        }
        wantListening.current = true;
        try {
            startSession();
            setIsListening(true);
        } catch {
            wantListening.current = false;
            setIsListening(false);
            setError(t.dictate_retry || 'Voice dictation stopped. Please try again.');
        }
    };

    /** French and Dutch use server transcription; false means "use the browser's recognition". */
    const startCloud = async (): Promise<boolean> => {
        if (lang === 'EN' || !cloudDictationSupported()) return false;
        try {
            const { available } = await dataService.getTranscriptionStatus();
            if (!available) return false;
        } catch (e: any) {
            // no permission for it: browser recognition. Merely offline: record now, upload when back.
            if (e?.response) return false;
        }

        const cloud = new CloudDictation(audio => dataService.transcribeAudio(audio, lang.toLowerCase()), {
            onText: text => onTextRef.current(text),
            onLost: () => setError(t.dictate_lost || 'Part of the dictation could not be transcribed. Please repeat it.'),
            onUnavailable: () => {
                cloud.abort();
                if (cloudRef.current === cloud) {
                    cloudRef.current = null;
                    setIsProcessing(false);
                    startNative();
                }
            },
        });
        try {
            await cloud.start();
        } catch (e: any) {
            cloud.abort();
            if (e?.name === 'NotAllowedError') {
                setError(window.isSecureContext
                    ? (t.dictate_denied || 'Microphone access was refused. Allow it in the browser address bar.')
                    : (t.dictate_insecure || 'Voice dictation only works on a secure (https) page.'));
                return true;
            }
            if (e?.name === 'NotFoundError') {
                setError(t.dictate_no_mic || 'No microphone was found.');
                return true;
            }
            return false;
        }
        cloudRef.current = cloud;
        setIsListening(true);
        return true;
    };

    const toggle = async () => {
        if (startingRef.current || isProcessing) return;

        if (isListening) {
            setIsListening(false);
            const cloud = cloudRef.current;
            if (cloud) {
                cloudRef.current = null; // the user stopped: no fallback may restart the microphone
                setIsProcessing(true);
                await cloud.stop();
                setIsProcessing(false);
                return;
            }
            wantListening.current = false;
            recognitionRef.current?.stop();
            return;
        }

        setError('');
        startingRef.current = true;
        try {
            if (!(await startCloud())) startNative();
        } finally {
            startingRef.current = false;
        }
    };

    return (
        <span className="inline-flex flex-col items-end">
            <button
                type="button"
                onClick={toggle}
                disabled={disabled || isProcessing}
                title={isListening ? (t.dictate_stop || 'Stop dictation') : (t.dictate || 'Dictate')}
                className={`flex items-center gap-1.5 text-[9px] font-black uppercase tracking-widest px-2 py-1 rounded border transition-all disabled:opacity-50 min-h-[30px] ${isListening
                    ? 'bg-red-500/10 border-red-500/40 text-red-400 animate-pulse'
                    : 'bg-zinc-900 border-zinc-800 text-zinc-500 hover:text-white'}`}
            >
                {isListening ? <MicOff size={12} /> : <Mic size={12} />}
                {isProcessing
                    ? (t.dictate_processing || 'Transcribing…')
                    : isListening ? (t.dictate_listening || 'Listening…') : (t.dictate || 'Dictate')}
            </button>
            {error && <span className="text-[10px] text-red-400 mt-1 max-w-[220px] text-right">{error}</span>}
        </span>
    );
};

export default DictationButton;
