import { Intervention, Building, Professional, Syndic, Language } from '@/types';
import { TRANSLATIONS } from '@/utils/constants';
import { generateInterventionPDF, loadImageAsDataUrl } from '@/utils/pdfGenerator';
import vankerLogo from '@/assets/report_logo.jpeg';

/** What the PDF report needs besides the intervention itself. */
export interface ReportPdfContext {
  buildings: Building[];
  professionals: Professional[];
  syndics: Syndic[];
  lang: Language;
}

/** Builds the PDF report of an intervention (no photos: they stay separate uploads). */
export const buildReportPdf = async (intervention: Intervention, ctx: ReportPdfContext, save: boolean) => {
  const building = ctx.buildings.find(b => b.id === intervention.buildingId);
  const professional = ctx.professionals.find(p => p.id === intervention.proId);
  const syndic = ctx.syndics.find(s => s.id === intervention.syndicId);
  const logoBase64 = await loadImageAsDataUrl(vankerLogo);
  return generateInterventionPDF(intervention, building as any, professional, syndic, ctx.lang, logoBase64, save);
};

const failed = (ctx: ReportPdfContext) => alert((TRANSLATIONS[ctx.lang] as any).pdf_generation_failed || 'PDF generation failed');

/** Downloads the PDF report. */
export const downloadReportPdf = async (intervention: Intervention, ctx: ReportPdfContext) => {
  try {
    await buildReportPdf(intervention, ctx, true);
  } catch (e) {
    console.error(e);
    failed(ctx);
  }
};

/** Opens the PDF report in a new tab (what a report card does, not the detail screen). */
export const openReportPdf = async (intervention: Intervention, ctx: ReportPdfContext) => {
  // The tab is opened right away, inside the click: browsers (Safari on iPad most of all) block a tab opened
  // after the PDF is built
  const tab = window.open('', '_blank');
  try {
    const doc = await buildReportPdf(intervention, ctx, false);
    const url = String(doc.output('bloburl'));
    if (tab) {
      tab.location.href = url;
    } else {
      window.location.href = url; // pop-ups blocked: show it in this tab instead
    }
  } catch (e) {
    console.error(e);
    tab?.close();
    failed(ctx);
  }
};
