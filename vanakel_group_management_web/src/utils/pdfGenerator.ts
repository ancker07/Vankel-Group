import jsPDF from 'jspdf';
import 'jspdf-autotable';
import { Intervention, Building, Professional, Syndic, Language } from '@/types';
import { TRANSLATIONS } from '@/utils/constants';

// Extending jsPDF with autotable plugin
declare module 'jspdf' {
    interface jsPDF {
        autoTable: (options: any) => jsPDF;
    }
}

// Vanker Group Logo (Base64) - Placeholder for now, will be updated with actual base64 if needed
// Or dynamically loaded in ReportsPage.tsx
const LOGO_BASE64 = '';

export const generateInterventionPDF = async (
    intervention: Intervention,
    building: Building | undefined,
    professional: Professional | undefined,
    syndic: Syndic | undefined,
    lang: Language,
    logoBase64?: string,
    savePdf: boolean = true
) => {
    const t = TRANSLATIONS[lang];
    const doc = new jsPDF();
    const pageWidth = doc.internal.pageSize.getWidth();

    // 1. Header & Logo
    if (logoBase64) {
        try {
            doc.addImage(logoBase64, 'JPEG', 15, 10, 35, 35);
        } catch (e) {
            console.warn('Failed to add logo to PDF', e);
        }
    }

    doc.setFontSize(22);
    doc.setTextColor(0, 0, 0); // Black
    doc.text('VANAKEL GROUP', 60, 25);

    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text('Avenue Louise 523, 1050 Bruxelles', 60, 32);
    doc.text('+32 2 123 45 67 | info@vanakelgroup.com', 60, 37);
    doc.text('www.vanakelgroup.com', 60, 42);

    // Divider
    doc.setDrawColor(200);
    doc.line(15, 50, pageWidth - 15, 50);

    // 2. Report Title & Meta
    doc.setFontSize(18);
    doc.setTextColor(30, 30, 30);
    doc.text(t.reports_title || 'Intervention Report', 15, 65);

    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`${t.slip_id || 'Slip ID'}: ${intervention.id}`, 15, 75);
    doc.text(`${t.created_at || 'Date'}: ${new Date(intervention.createdAt || intervention.scheduledDate).toLocaleDateString()}`, 15, 80);
    doc.text(`${t.status || 'Status'}: ${t[`status_${intervention.status.toLowerCase()}`] || intervention.status}`, 15, 85);

    // 3. Main Content Sections
    let currentY = 100;

    // Section: Intervention Details
    doc.setFontSize(14);
    doc.setTextColor(0, 0, 0);
    doc.text(t.interventionTitle || 'Intervention Details', 15, currentY);
    doc.line(15, currentY + 2, 60, currentY + 2);

    currentY += 12;
    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text(intervention.title, 15, currentY);

    currentY += 8;
    doc.setFont('helvetica', 'normal');
    const descriptionLines = doc.splitTextToSize(intervention.description, pageWidth - 30);
    doc.text(descriptionLines, 15, currentY);
    currentY += (descriptionLines.length * 5) + 12;

    // Technical / Admin Notes
    if (intervention.adminFeedback) {
        doc.setFontSize(10);
        doc.setFont('helvetica', 'bold');
        doc.setTextColor(100);
        doc.text(t.adminNote || 'Admin Note', 15, currentY);
        currentY += 6;
        doc.setFont('helvetica', 'normal');
        doc.setTextColor(0);
        const adminLines = doc.splitTextToSize(intervention.adminFeedback, pageWidth - 30);
        doc.text(adminLines, 15, currentY);
        currentY += (adminLines.length * 5) + 10;
    }

    // Project Comments
    if (intervention.comment) {
        doc.setFontSize(10);
        doc.setFont('helvetica', 'bold');
        doc.setTextColor(100);
        doc.text(t.comment || 'Commentaire', 15, currentY);
        currentY += 6;
        doc.setFont('helvetica', 'normal');
        doc.setTextColor(0);
        const commentLines = doc.splitTextToSize(intervention.comment, pageWidth - 30);
        doc.text(commentLines, 15, currentY);
        currentY += (commentLines.length * 5) + 10;
    }

    // Delay Details
    if (intervention.status === 'DELAYED' && (intervention.delayReason || intervention.delayDetails)) {
        doc.setFontSize(10);
        doc.setFont('helvetica', 'bold');
        doc.setTextColor(230, 100, 0); // Orange-ish
        doc.text(t.delayTitle || 'Reason for delay', 15, currentY);
        currentY += 6;
        doc.setFont('helvetica', 'normal');
        doc.setTextColor(0);

        let delayText = '';
        if (intervention.delayReason) {
            delayText += `${t.delayReasonLabel || 'Reason'}: ${intervention.delayReason}\n`;
        }
        if (intervention.delayDetails) {
            delayText += `${intervention.delayDetails}`;
        }

        const delayLines = doc.splitTextToSize(delayText, pageWidth - 30);
        doc.text(delayLines, 15, currentY);
        currentY += (delayLines.length * 5) + 10;
    }

    currentY += 5;

    // Section: Building Information
    if (building) {
        doc.setFontSize(14);
        doc.setTextColor(0, 0, 0);
        doc.text(t.building_header || 'Building Information', 15, currentY);
        doc.line(15, currentY + 2, 65, currentY + 2);

        currentY += 12;
        doc.setFontSize(11);
        doc.text(`${t.address || 'Address'}: ${building.address}`, 15, currentY);
        currentY += 7;
        doc.text(`${t.city || 'City'}: ${building.city}`, 15, currentY);
        currentY += 15;
    }

    // Section: Professional / Syndic Details
    if (professional || syndic) {
        const leftX = 15;
        const rightX = pageWidth / 2 + 5;
        const startY = currentY;

        if (syndic) {
            doc.setFontSize(12);
            doc.text(t.syndic || 'Syndic', leftX, currentY);
            doc.setFontSize(10);
            currentY += 7;
            doc.text(syndic.companyName, leftX, currentY);
            currentY += 5;
            doc.text(syndic.contactPerson, leftX, currentY);
            currentY += 5;
            doc.text(syndic.email, leftX, currentY);
        }

        currentY = startY; // Reset Y for second column
        if (professional) {
            doc.setFontSize(12);
            doc.text(t.pro || 'Professional', rightX, currentY);
            doc.setFontSize(10);
            currentY += 7;
            doc.text(professional.companyName, rightX, currentY);
            currentY += 5;
            doc.text(professional.contactPerson, rightX, currentY);
            currentY += 5;
            doc.text(professional.email, rightX, currentY);
        }

        currentY = Math.max(currentY, startY + 25) + 20;
    }

    // 5. Footer
    const pageCountSource = (doc as any).internal.getNumberOfPages();
    for (let i = 1; i <= pageCountSource; i++) {
        doc.setPage(i);
        doc.setFontSize(9);
        doc.setTextColor(150);
        doc.text(`Page ${i} of ${pageCountSource}`, pageWidth / 2, doc.internal.pageSize.getHeight() - 10, { align: 'center' });
        doc.text('© Vanker Group 2024', 15, doc.internal.pageSize.getHeight() - 10);
    }

    // Save the PDF
    const fileName = `Intervention_Report_${intervention.id}_${new Date().toISOString().split('T')[0]}.pdf`;
    if (savePdf) {
        doc.save(fileName);
    }
    return doc;
};
