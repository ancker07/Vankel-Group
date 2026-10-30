// Tracks in-flight API requests so the UI can show a global loading indicator.
// Mutations (POST/PUT/PATCH/DELETE) are "actions": the user is waiting on them.
// GETs are tracked too, but are only surfaced if they take a while.

type Listener = () => void;

interface LoadingSnapshot {
  pending: number;
  pendingActions: number;
}

let pending = 0;
let pendingActions = 0;
let snapshot: LoadingSnapshot = { pending, pendingActions };
const listeners = new Set<Listener>();

const emit = () => {
  snapshot = { pending, pendingActions };
  listeners.forEach((l) => l());
};

export const isActionMethod = (method?: string) =>
  !!method && !['get', 'head', 'options'].includes(method.toLowerCase());

export const loadingStore = {
  start(method?: string) {
    pending++;
    if (isActionMethod(method)) pendingActions++;
    emit();
  },
  end(method?: string) {
    pending = Math.max(0, pending - 1);
    if (isActionMethod(method)) pendingActions = Math.max(0, pendingActions - 1);
    emit();
  },
  subscribe(listener: Listener) {
    listeners.add(listener);
    return () => {
      listeners.delete(listener);
    };
  },
  getSnapshot: () => snapshot,
};
