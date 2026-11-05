/**
 * Server speech-to-text for dictation: the microphone is cut into speech segments at natural
 * pauses, and each segment is transcribed and appended exactly once, in the order spoken.
 * Text already delivered is never rewritten, so it cannot disappear or be duplicated.
 */

const MAX_SEGMENT_MS = 25000;
const PAUSE_MS = 800;
const MIN_SPEECH_MS = 200;
const TICK_MS = 100;
/** Total about one minute, so short network drops lose nothing: audio waits here meanwhile. */
const RETRY_DELAYS_MS = [1000, 2000, 4000, 8000, 15000, 30000];

export type GateAction = 'cut' | 'discard' | null;

/** Decides where to cut, from the microphone level. Adapts to background noise. */
export class SpeechGate {
    private elapsedMs = 0;
    private speechMs = 0;
    private silenceMs = 0;
    private noiseFloor = 0.002;

    feed(level: number, dtMs: number): GateAction {
        this.elapsedMs += dtMs;
        this.noiseFloor = level < this.noiseFloor ? level : this.noiseFloor * 1.002;
        if (level > Math.max(0.01, this.noiseFloor * 3)) {
            this.speechMs += dtMs;
            this.silenceMs = 0;
        } else {
            this.silenceMs += dtMs;
        }

        const heardSpeech = this.speechMs >= MIN_SPEECH_MS;
        if (heardSpeech && this.silenceMs >= PAUSE_MS) return this.reset('cut');
        if (this.elapsedMs >= MAX_SEGMENT_MS) return this.reset(heardSpeech ? 'cut' : 'discard');
        return null;
    }

    get hasSpeech() {
        return this.speechMs >= MIN_SPEECH_MS;
    }

    private reset(action: GateAction): GateAction {
        this.elapsedMs = this.speechMs = this.silenceMs = 0;
        return action;
    }
}

export type FailureKind = 'retry' | 'skip' | 'unavailable';

export const classifyFailure = (error: any): FailureKind => {
    const status = error?.response?.status;
    if (status === 422 || status === 413) return 'skip';
    if (status === 401 || status === 403 || status === 503) return 'unavailable';
    return 'retry'; // no response (offline), rate limit, temporary server problem
};

export interface QueueEvents {
    onText: (text: string) => void;
    /** A segment could not be transcribed even after retrying. */
    onLost: () => void;
    /** The server cannot transcribe at all: use the browser's recognition instead. */
    onUnavailable: () => void;
}

/** Uploads one segment at a time, which keeps the text in the spoken order. */
export class SegmentQueue<T> {
    private items: T[] = [];
    private running = false;
    private stopped = false;
    private idleWaiters: Array<() => void> = [];
    private lostInARow = 0;

    constructor(
        private transcribe: (item: T) => Promise<string>,
        private events: QueueEvents,
        private delays: number[] = RETRY_DELAYS_MS,
        private sleep: (ms: number) => Promise<void> = ms => new Promise(r => setTimeout(r, ms))
    ) {}

    add(item: T) {
        if (this.stopped) return;
        this.items.push(item);
        void this.run();
    }

    /** Resolves once everything queued so far is delivered. */
    whenIdle(): Promise<void> {
        if (!this.running) return Promise.resolve();
        return new Promise(resolve => this.idleWaiters.push(resolve));
    }

    cancel() {
        this.stopped = true;
        this.items = [];
    }

    private async run() {
        if (this.running) return;
        this.running = true;
        while (this.items.length && !this.stopped) {
            await this.process(this.items.shift() as T);
        }
        this.running = false;
        this.idleWaiters.splice(0).forEach(resolve => resolve());
    }

    private async process(item: T) {
        for (let attempt = 0; ; attempt++) {
            try {
                const text = (await this.transcribe(item)).trim();
                this.lostInARow = 0;
                if (text && !this.stopped) this.events.onText(text);
                return;
            } catch (error) {
                const kind = classifyFailure(error);
                if (kind === 'unavailable') {
                    this.cancel();
                    this.events.onLost();
                    this.events.onUnavailable();
                    return;
                }
                if (kind === 'skip' || attempt >= this.delays.length) {
                    this.events.onLost();
                    // Two in a row means the server route is not working: stop relying on it.
                    if (++this.lostInARow >= 2) {
                        this.cancel();
                        this.events.onUnavailable();
                    }
                    return;
                }
                await this.sleep(this.delays[attempt]);
                if (this.stopped) return;
            }
        }
    }
}

const pickMimeType = (): string | null => {
    const types = ['audio/webm;codecs=opus', 'audio/webm', 'audio/mp4'];
    return types.find(type => MediaRecorder.isTypeSupported(type)) ?? null;
};

export const cloudDictationSupported = (): boolean =>
    typeof MediaRecorder !== 'undefined' && !!navigator.mediaDevices?.getUserMedia && pickMimeType() !== null;

/** Microphone + segmenting + queue. start() rejects with the getUserMedia error if the mic is refused. */
export class CloudDictation {
    private stream: MediaStream | null = null;
    private audioContext: AudioContext | null = null;
    private timer: ReturnType<typeof setInterval> | null = null;
    private recorder: MediaRecorder | null = null;
    private finishing: Promise<void>[] = [];
    private queue: SegmentQueue<Blob>;
    private gate = new SpeechGate();
    private events: QueueEvents;

    constructor(transcribe: (audio: Blob) => Promise<string>, events: QueueEvents) {
        this.events = events;
        this.queue = new SegmentQueue(transcribe, events);
    }

    async start() {
        this.stream = await navigator.mediaDevices.getUserMedia({
            audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true },
        });
        this.audioContext = new AudioContext();
        await this.audioContext.resume();
        const analyser = this.audioContext.createAnalyser();
        analyser.fftSize = 2048;
        this.audioContext.createMediaStreamSource(this.stream).connect(analyser);
        const samples = new Float32Array(analyser.fftSize);

        // Microphone unplugged or taken by another app: hand over to the browser's recognition.
        this.stream.getAudioTracks().forEach(track => {
            track.onended = () => {
                if (this.timer) this.handOver();
            };
        });

        this.recorder = this.newRecorder();
        this.timer = setInterval(() => {
            analyser.getFloatTimeDomainData(samples);
            const level = Math.sqrt(samples.reduce((sum, s) => sum + s * s, 0) / samples.length);
            const action = this.gate.feed(level, TICK_MS);
            if (!action) return;
            try {
                this.rotate(action === 'cut');
            } catch {
                this.handOver();
            }
        }, TICK_MS);
    }

    /** Stops listening; resolves when every spoken segment has been delivered. */
    async stop() {
        const keep = this.gate.hasSpeech;
        this.stopTimer();
        const last = this.recorder;
        this.recorder = null;
        if (last) this.finish(last, keep);
        this.releaseMic();
        await Promise.all(this.finishing);
        await this.queue.whenIdle();
    }

    /** Stops immediately: the screen is closing or another engine is taking over. */
    abort() {
        this.queue.cancel();
        this.stopTimer();
        const last = this.recorder;
        this.recorder = null;
        if (last) this.finish(last, false);
        this.releaseMic();
    }

    private handOver() {
        this.stopTimer();
        this.events.onUnavailable();
    }

    /** The next recorder starts before the old one stops, so no audio falls between segments. */
    private rotate(keep: boolean) {
        const previous = this.recorder;
        this.recorder = this.newRecorder();
        if (previous) this.finish(previous, keep);
    }

    private newRecorder(): MediaRecorder {
        const mimeType = pickMimeType() as string;
        const recorder = new MediaRecorder(this.stream as MediaStream, { mimeType });
        const chunks: Blob[] = [];
        recorder.ondataavailable = event => {
            if (event.data.size) chunks.push(event.data);
        };
        (recorder as any).chunks = chunks;
        recorder.start();
        return recorder;
    }

    private finish(recorder: MediaRecorder, keep: boolean) {
        const chunks: Blob[] = (recorder as any).chunks;
        this.finishing.push(
            new Promise(resolve => {
                recorder.onstop = () => {
                    if (keep && chunks.length) this.queue.add(new Blob(chunks, { type: recorder.mimeType }));
                    resolve();
                };
                if (recorder.state === 'inactive') resolve();
                else recorder.stop();
            })
        );
    }

    private stopTimer() {
        if (this.timer) clearInterval(this.timer);
        this.timer = null;
    }

    private releaseMic() {
        this.stream?.getTracks().forEach(track => track.stop());
        this.stream = null;
        void this.audioContext?.close().catch(() => undefined);
        this.audioContext = null;
    }
}
