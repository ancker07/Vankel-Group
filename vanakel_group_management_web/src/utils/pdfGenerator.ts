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
    const photos = (await Promise.all(photoUrls.map(loadImageAsDataUrl))).filter((photo): photo is string => !!photo);

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
        for (const photo of photos) {
            try {
                const properties = doc.getImageProperties(photo);
                const width = contentWidth;
                const height = Math.min(120, (properties.height * width) / properties.width);
                ensureSpace(height + 8);
                doc.addImage(photo, imageFormat(photo), MARGIN, y, width, height);
                y += height + 8;
            } catch (error) {
                console.warn('Failed to add intervention photo to PDF', error);
            }
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
