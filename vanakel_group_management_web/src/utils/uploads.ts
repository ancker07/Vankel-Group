// Client-side mirror of the server's upload policy (App\Support\UploadRules).
// Checking here tells the user right away, instead of failing the whole form after submit.

export const MAX_UPLOAD_MB = 10;
export const MAX_AVATAR_MB = 5;
export const DOCUMENT_EXTENSIONS = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'jpg', 'jpeg', 'png', 'webp'];
export const IMAGE_EXTENSIONS = ['jpg', 'jpeg', 'png', 'webp'];

const extensionOf = (name: string) => (name.split('.').pop() || '').toLowerCase();

export interface FilterResult {
    accepted: File[];
    rejected: string[];
}

/** Splits files into the ones the server will accept and the ones it would reject. */
export const filterUploads = (
    files: File[],
    allowed: string[] = DOCUMENT_EXTENSIONS,
    maxMb: number = MAX_UPLOAD_MB
): FilterResult => {
    const accepted: File[] = [];
    const rejected: string[] = [];
    for (const file of files) {
        const okType = allowed.includes(extensionOf(file.name));
        const okSize = file.size <= maxMb * 1024 * 1024;
        if (okType && okSize) accepted.push(file);
        else rejected.push(file.name || 'file');
    }
    return { accepted, rejected };
};

/**
 * Shrinks a large photo in the browser (phone cameras produce 5-12 MB images).
 * Returns the original file if it is already small or cannot be decoded (e.g. HEIC outside Safari).
 */
export const compressImage = async (file: File, maxDimension = 1920, quality = 0.8): Promise<File> => {
    if (!file.type.startsWith('image/') || file.type === 'image/gif' || file.size < 600 * 1024) return file;
    try {
        const bitmap = await createImageBitmap(file);
        const scale = Math.min(1, maxDimension / Math.max(bitmap.width, bitmap.height));
        const canvas = document.createElement('canvas');
        canvas.width = Math.round(bitmap.width * scale);
        canvas.height = Math.round(bitmap.height * scale);
        const ctx = canvas.getContext('2d');
        if (!ctx) return file;
        ctx.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
        bitmap.close?.();
        const blob = await new Promise<Blob | null>(resolve => canvas.toBlob(resolve, 'image/jpeg', quality));
        if (!blob || blob.size >= file.size) return file;
        return new File([blob], file.name.replace(/\.[^.]+$/, '') + '.jpg', { type: 'image/jpeg', lastModified: Date.now() });
    } catch {
        return file;
    }
};

/** Human message for rejected files, in the app language. */
export const rejectedMessage = (template: string | undefined, rejected: string[]) =>
    (template || 'Not uploaded (allowed: PDF, Word, Excel, text and images, max 10 MB each): {files}').replace('{files}', rejected.join(', '));
