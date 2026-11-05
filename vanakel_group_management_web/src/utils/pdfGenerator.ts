import jsPDF from 'jspdf';
import 'jspdf-autotable';
import { Intervention, Building, Professional, Syndic, Language } from '@/types';
import { TRANSLATIONS, DELAY_REASONS } from '@/utils/constants';

// Extending jsPDF with autotable plugin
declare module 'jspdf' {
    interface jsPDF {
        autoTable: (options: any) => jsPDF;
    }
}

const DATE_LOCALES: Record<string, string> = { EN: 'en-GB', FR: 'fr-BE', NL: 'nl-BE' };

const MARGIN = 15;
const BOTTOM_MARGIN = 22; // keeps text clear of the footer
const LINE = 5;

/**
 * jsPDF's built-in fonts only cover Latin-1. Emails and notes often contain
 * typographic quotes, dashes, "…" or emoji, which would come out as garbage.
 * Map the common ones to plain equivalents and replace anything else outside Latin-1.
 */
export const pdfSafeText = (value: unknown): string => {
    if (value === null || value === undefined) return '';
    return String(value)
        .replace(/[‘’‚′]/g, "'")
        .replace(/[“”„″]/g, '"')
        .replace(/[–—−]/g, '-')
        .replace(/…/g, '...')
        .replace(/€/g, 'EUR')
        .replace(/[   ]/g, ' ')
        .replace(/[​-‍﻿]/g, '')
        .replace(/\r\n?/g, '\n')
        .replace(/[^\n\t\x20-\x7E¡-ÿ]/gu, '?');
};

/** Title / description are stored in all three languages: use the report's language, else the original. */
const localizedField = (item: any, field: 'title' | 'description', lang: Language): string => {
    const translated = item?.[`${field}_${lang.toLowerCase()}`];
    return typeof translated === 'string' && translated.trim() ? translated : item?.[field] ?? '';
};

/** "no_access" -> "Accès impossible" / "Geen toegang" / "No access" (unknown values are kept). */
const delayReasonLabel = (reason: string | undefined, lang: Language): string => {
    if (!reason) return '';
    const found = DELAY_REASONS.find(r => r.id === String(reason).toLowerCase());
    return found ? found[lang] : String(reason);
};

const formatDate = (value: string | undefined, lang: Language): string => {
    if (!value) return '';
    const d = new Date(value);
    return isNaN(d.getTime()) ? '' : d.toLocaleDateString(DATE_LOCALES[lang] || 'en-GB');
};

/** Fetches an image (e.g. the bundled logo) as a data URL; undefined if it cannot be loaded. */
export const loadImageAsDataUrl = async (url: string): Promise<string | undefined> => {
    try {
        const response = await fetch(url);
        if (!response.ok) return undefined;
        const blob = await response.blob();
        return await new Promise<string | undefined>((resolve) => {
            const reader = new FileReader();
            reader.onloadend = () => resolve(typeof reader.result === 'string' ? reader.result : undefined);
            reader.onerror = () => resolve(undefined);
            reader.readAsDataURL(blob);
        });
    } catch {
        return undefined;
    }
};

const imageFormat = (dataUrl: string): 'PNG' | 'JPEG' => (dataUrl.startsWith('data:image/png') ? 'PNG' : 'JPEG');

/**
 * Shrinks a picture to at most `maxSide` px on its longest side (re-encoded as JPEG) so a report with
 * 5-6 phone photos stays a reasonable size. Returns the original if it cannot be processed.
 */
const shrinkImage = (dataUrl: string, maxSide = 1400, quality = 0.82): Promise<string> =>
    new Promise((resolve) => {
        const img = new Image();
        img.onload = () => {
            const scale = Math.min(1, maxSide / Math.max(img.width, img.height));
            if (scale === 1 && dataUrl.startsWith('data:image/jpeg')) return resolve(dataUrl);
            try {
                const canvas = document.createElement('canvas');
                canvas.width = Math.round(img.width * scale);
                canvas.height = Math.round(img.height * scale);
                const ctx = canvas.getContext('2d');
                if (!ctx) return resolve(dataUrl);
                ctx.fillStyle = '#ffffff'; // transparent PNGs would turn black as JPEG
                ctx.fillRect(0, 0, canvas.width, canvas.height);
                ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
                resolve(canvas.toDataURL('image/jpeg', quality));
            } catch {
                resolve(dataUrl);
            }
        };
        img.onerror = () => resolve(dataUrl);
        img.src = dataUrl;
    });

export const generateInterventionPDF = async (
    intervention: Intervention,
    building: Building | undefined,
    professional: Professional | undefined,
    syndic: Syndic | undefined,
    lang: Language,
    logoBase64?: string,
    savePdf: boolean = true,
    fileName?: string
) => {
    const t: any = TRANSLATIONS[lang] || TRANSLATIONS.EN;
    const doc = new jsPDF();
    const pageWidth = doc.internal.pageSize.getWidth();
    const pageHeight = doc.internal.pageSize.getHeight();
    const contentWidth = pageWidth - MARGIN * 2;

    let y = 0;

    /** Starts a new page when `needed` mm do not fit any more. */
    const ensureSpace = (needed: number) => {
        if (y + needed > pageHeight - BOTTOM_MARGIN) {
            doc.addPage();
            y = MARGIN + 5;
        }
    };

    /** Writes wrapped text line by line, continuing on the next page when needed. */
    const writeParagraph = (text: unknown, x = MARGIN, width = contentWidth) => {
        const clean = pdfSafeText(text).trim();
        if (!clean) return;
        const lines: string[] = doc.splitTextToSize(clean, width);
        for (const line of lines) {
            ensureSpace(LINE);
            doc.text(line, x, y);
            y += LINE;
        }
    };

    const sectionHeading = (label: string, underline = 45) => {
        ensureSpace(20);
        doc.setFont('helvetica', 'bold');
        doc.setFontSize(14);
        doc.setTextColor(0, 0, 0);
        doc.text(pdfSafeText(label), MARGIN, y);
        doc.setDrawColor(200);
        doc.line(MARGIN, y + 2, MARGIN + underline, y + 2);
        doc.setFont('helvetica', 'normal');
        y += 12;
    };

    const subHeading = (label: string, color: [number, number, number] = [0, 0, 0]) => {
        ensureSpace(14);
        doc.setFont('helvetica', 'bold');
        doc.setFontSize(10);
        doc.setTextColor(...color);
        doc.text(pdfSafeText(label), MARGIN, y);
        doc.setFont('helvetica', 'normal');
        doc.setTextColor(0);
        y += 6;
    };

    const photoUrls = [...new Set([
        ...(intervention.photos || []),
        // only the pictures we attached to the intervention: the ones copied from the original
        // request (client e-mail / mission) get the same timestamp as the intervention itself
        ...(intervention.documents || [])
            .filter(document => /^image\//i.test(document.type || '') || /\.(jpe?g|png|webp|gif)$/i.test(document.url || ''))
            .filter(document => {
                const attachedAt = new Date(document.timestamp as any).getTime();
                const createdAt = new Date(intervention.createdAt as any).getTime();
                return !Number.isFinite(attachedAt) || !Number.isFinite(createdAt) || attachedAt - createdAt > 5000;
            })
            .map(document => document.url),
    ].filter(Boolean))];
    const photos = (await Promise.all(photoUrls.map(async url => {
        const dataUrl = await loadImageAsDataUrl(url);
        return dataUrl ? shrinkImage(dataUrl) : undefined;
    }))).filter((photo): photo is string => !!photo);

    // 1. Header & Logo
    if (logoBase64) {
        try {
            doc.addImage(logoBase64, imageFormat(logoBase64), MARGIN, 10, 35, 35);
        } catch (e) {
            console.warn('Failed to add logo to PDF', e);
        }
    }

    doc.setFontSize(22);
    doc.setTextColor(0, 0, 0);
    doc.setFont('helvetica', 'bold');
    doc.text('Vanakel Group', 60, 25);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(12);
    doc.setTextColor(150, 150, 150);
    doc.text('(SRL)', 115, 25);

    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text('Excelsiorlaan 36-38, 1930 Zaventem', 60, 32);
    doc.text('+32 475 99 99 09 | info@vanakelgroup.be', 60, 37);
    doc.text('www.vanakelgroup.be', 60, 42);

    doc.setDrawColor(200);
    doc.line(MARGIN, 50, pageWidth - MARGIN, 50);

    // 2. Report Title & Meta
    doc.setFontSize(18);
    doc.setTextColor(30, 30, 30);
    doc.text(pdfSafeText(t.pdf_report_title || t.reports_title || 'Intervention Report'), MARGIN, 65);

    const status = String(intervention.status || '');
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(pdfSafeText(`${t.slip_id || 'Slip ID'}: ${intervention.id ?? ''}`), MARGIN, 75);
    doc.text(pdfSafeText(`${t.created_at || 'Date'}: ${formatDate(intervention.createdAt || intervention.scheduledDate, lang)}`), MARGIN, 80);
    doc.text(pdfSafeText(`${t.status || 'Status'}: ${t[`status_${status.toLowerCase()}`] || status}`), MARGIN, 85);

    y = 100;
    doc.setTextColor(0);

    // 3. Intervention details (long descriptions continue on the next pages)
    sectionHeading(t.interventionTitle || 'Intervention Details', 45);
    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    writeParagraph(localizedField(intervention, 'title', lang));
    y += 3;
    doc.setFont('helvetica', 'normal');
    writeParagraph(localizedField(intervention, 'description', lang));
    y += 8;

    // Technical / Admin notes
    const adminNote =
        intervention.adminFeedback ||
        (intervention as any).admin_feedback ||
        (intervention.notes && intervention.notes.length > 0 ? intervention.notes[intervention.notes.length - 1]?.content : '');
    if (adminNote) {
        subHeading(t.adminNote || 'Admin Note');
        doc.setFontSize(10);
        writeParagraph(adminNote);
        y += 6;
    }

    // Delay details
    const delayReason = intervention.delayReason || (intervention as any).delay_reason;
    const delayDetails = intervention.delayDetails || (intervention as any).delay_details;
    if (status === 'DELAYED' && (delayReason || delayDetails)) {
        subHeading(t.delayTitle || 'Reason for delay', [230, 100, 0]);
        doc.setFontSize(10);
        if (delayReason) writeParagraph(`${t.delayReasonLabel || 'Reason'}: ${delayReasonLabel(delayReason, lang)}`);
        if (delayDetails) writeParagraph(delayDetails);
        y += 6;
    }

    // On-site contact
    const contact = [intervention.onSiteContactName, intervention.onSiteContactPhone, intervention.onSiteContactEmail].filter(Boolean);
    if (contact.length > 0) {
        subHeading(t.onSiteContactLabel || 'On-site contact');
        doc.setFontSize(10);
        writeParagraph(contact.join('  |  '));
        y += 6;
    }

    y += 4;

    // 4. Building information
    if (building) {
        sectionHeading(t.building_header || 'Building Information', 50);
        doc.setFontSize(11);
        writeParagraph(`${t.address || 'Address'}: ${building.address ?? ''}`);
        if (building.city) writeParagraph(`${t.city || 'City'}: ${building.city}`);
        y += 10;
    }

    // 5. Professional / Syndic details (two columns, kept together on one page)
    if (professional || syndic) {
        ensureSpace(40);
        const leftX = MARGIN;
        const rightX = pageWidth / 2 + 5;
        const colWidth = pageWidth / 2 - MARGIN - 5;
        const startY = y;

        const column = (x: number, heading: string, party: { companyName?: string; contactPerson?: string; email?: string }) => {
            let cy = startY;
            doc.setFont('helvetica', 'bold');
            doc.setFontSize(12);
            doc.setTextColor(0);
            doc.text(pdfSafeText(heading), x, cy);
            doc.setFont('helvetica', 'normal');
            doc.setFontSize(10);
            cy += 7;
            for (const value of [party.companyName, party.contactPerson, party.email]) {
                const text = pdfSafeText(value).trim();
                if (!text) continue;
                for (const line of doc.splitTextToSize(text, colWidth) as string[]) {
                    doc.text(line, x, cy);
                    cy += LINE;
                }
            }
            return cy;
        };

        const leftEnd = syndic ? column(leftX, t.syndic || 'Syndic', syndic) : startY;
        const rightEnd = professional ? column(rightX, t.pro || 'Professional', professional) : startY;
        y = Math.max(leftEnd, rightEnd, startY + 25) + 10;
    }

    if (photos.length > 0) {
        sectionHeading(t.intervention_photos || t.photos || 'Intervention Photos', 55);

        // One picture is shown large; two or more go in a two-column grid, each fitted into its cell
        // without stretching, with a small label. Rows move to a new page when they do not fit.
        const columns = photos.length === 1 ? 1 : 2;
        const gap = 6;
        const cellWidth = (contentWidth - gap * (columns - 1)) / columns;
        const maxImageHeight = columns === 1 ? 150 : 85;
        const captionHeight = 6;
        const label = pdfSafeText(t.photo || 'Photo');

        for (let rowStart = 0; rowStart < photos.length; rowStart += columns) {
            const row = photos.slice(rowStart, rowStart + columns).map((photo, offset) => {
                try {
                    const properties = doc.getImageProperties(photo);
                    const scale = Math.min(cellWidth / properties.width, maxImageHeight / properties.height);
                    return { photo, number: rowStart + offset + 1, width: properties.width * scale, height: properties.height * scale };
                } catch (error) {
                    console.warn('Failed to add intervention photo to PDF', error);
                    return null;
                }
            }).filter((item): item is { photo: string; number: number; width: number; height: number } => item !== null);
            if (row.length === 0) continue;

            const rowHeight = Math.max(...row.map(item => item.height)) + captionHeight;
            ensureSpace(rowHeight + 6);

            row.forEach((item, column) => {
                const cellX = MARGIN + column * (cellWidth + gap);
                const imageX = cellX + (cellWidth - item.width) / 2;
                doc.addImage(item.photo, imageFormat(item.photo), imageX, y, item.width, item.height);
                doc.setDrawColor(210);
                doc.rect(imageX, y, item.width, item.height);
                doc.setFont('helvetica', 'normal');
                doc.setFontSize(8);
                doc.setTextColor(120);
                doc.text(`${label} ${item.number}`, cellX + cellWidth / 2, y + item.height + 4.5, { align: 'center' });
                doc.setTextColor(0);
            });
            y += rowHeight + 6;
        }
    }

    // 6. Footer on every page
    const pageCount = doc.getNumberOfPages();
    const currentYear = new Date().getFullYear();
    for (let i = 1; i <= pageCount; i++) {
        doc.setPage(i);
        doc.setFontSize(9);
        doc.setTextColor(150);
        const pageText = t.pdf_page_of
            ? String(t.pdf_page_of).replace('{current}', String(i)).replace('{total}', String(pageCount))
            : `Page ${i} of ${pageCount}`;
        doc.text(pdfSafeText(pageText), pageWidth / 2, pageHeight - 10, { align: 'center' });
        doc.text(`\u00A9 Vanakel Group (SRL) ${currentYear}`, MARGIN, pageHeight - 10);
    }

    if (savePdf) {
        doc.save(fileName || `Intervention_Report_${intervention.id}_${new Date().toISOString().split('T')[0]}.pdf`);
    }

    return doc;
};
