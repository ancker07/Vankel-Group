
import React, { useState, useEffect, useRef } from 'react';
import {
  Intervention, Building, Professional, Syndic, Language, Role, InterventionStatus
} from '@/types';
import {
  X, Mail, MessageCircle, Sparkles, Upload, FileText, Camera, CheckCircle2, ChevronLeft, Save, Edit2, RotateCcw, Calendar, Clock, Smartphone, AtSign, User, AlertCircle, MapPin, Eye, Loader2, Briefcase
} from 'lucide-react';
import { TRANSLATIONS, DELAY_REASONS } from '@/utils/constants';
import { improveNote, optimizeIntervention } from '@/services/aiService';
import { dataService } from '@/services/dataService';
import { generateInterventionPDF } from '@/utils/pdfGenerator';
import vankerLogo from '@/assets/logo_vankel.jpeg';
import DocumentViewerModal from '@/components/common/DocumentViewerModal';

interface SlipProps {
  intervention: Intervention;
  building: Building;
  professional?: Professional;
  syndic?: Syndic;
  syndics?: Syndic[];
  professionals?: Professional[];
  lang: Language;
  onClose: () => void;
  onUpdate: (i: Intervention, skipApi?: boolean) => Promise<void>;
  onOpenMaintenance?: (buildingId: string) => void;
  role?: Role;
  readOnly?: boolean;
}


// --- Visual Helper for Extracted Content ---
const FormattedExtractedContent: React.FC<{ text: string }> = ({ text }) => {
  if (!text) return null;

  // Split lines
  const lines = text.split('\n');

  return (
    <div className="font-sans text-base md:text-xl text-zinc-200 leading-relaxed space-y-1">
      {lines.map((line, idx) => {
        const trimmed = line.trim();
        // Detect Headers (e.g. UPPERCASE words longer than 3 chars, or specific keywords)
        const isHeader = /^(?:ORDRE DE SERVICE|DESCRIPTION|REMARQUE|NOTE|OBJECT|OBJET)[:]?\s*$/i.test(trimmed);

        // Detect Key-Value (e.g. "Reference: ...")
        const isKeyValue = /^[\w\s]+[:]\s+.+/i.test(trimmed) && trimmed.length < 80;

        if (isHeader) {
          return <div key={idx} className="font-black text-brand-green uppercase tracking-wide mt-4 mb-1 text-sm">{trimmed}</div>;
        }

        if (isKeyValue) {
          const [key, ...valParts] = trimmed.split(':');
          const val = valParts.join(':');
          return (
            <div key={idx} className="flex flex-col sm:flex-row sm:gap-2">
              <span className="font-bold text-zinc-400 text-sm uppercase tracking-wider min-w-[100px]">{key}:</span>
              <span className="font-medium text-white">{val}</span>
            </div>
          );
        }

        return <div key={idx} className="whitespace-pre-wrap break-words min-h-[1.2em]">{line}</div>;
      })}
    </div>
  );
};

// --- Main Component ---

const InterventionSlip: React.FC<SlipProps> = ({
  intervention, building, professional, syndic, syndics = [], professionals = [], lang, onClose, onUpdate, onOpenMaintenance, role, readOnly
}) => {

  const t = TRANSLATIONS[lang];
  const [status, setStatus] = useState<InterventionStatus>(intervention.status);
  const [delayedDate, setDelayedDate] = useState(intervention.delayedRescheduleDate || (intervention as any).delayed_reschedule_date || '');
  const [adminNote, setAdminNote] = useState(intervention.adminFeedback || (intervention as any).admin_feedback || '');

  // Delay Reason State
  const [delayReason, setDelayReason] = useState(intervention.delayReason || (intervention as any).delay_reason || '');
  const [delayDetails, setDelayDetails] = useState(intervention.delayDetails || (intervention as any).delay_details || '');

  // Contact Sur Place State (Per Intervention)
  const [contactName, setContactName] = useState(intervention.onSiteContactName || (intervention as any).on_site_contact_name || '');
  const [contactPhone, setContactPhone] = useState(intervention.onSiteContactPhone || (intervention as any).on_site_contact_phone || '');
  const [contactEmail, setContactEmail] = useState(intervention.onSiteContactEmail || (intervention as any).on_site_contact_email || '');
  const [internalSyndicId, setInternalSyndicId] = useState(intervention.syndicId || (intervention as any).syndic_id || building.linkedSyndicId || '');
  const [internalProId, setInternalProId] = useState(intervention.proId || (intervention as any).pro_id || building.linkedProfessionalId || '');

  // Derived syndic for display
  const currentSyndic = syndics.find(s => s.id === internalSyndicId) || syndic;
  const currentProfessional = professionals.find(p => p.id === internalProId) || professional;

  const [photos, setPhotos] = useState<{ url: string, file?: File }[]>(
    (intervention.photos || []).map(url => ({ url }))
  );
  const [documents, setDocuments] = useState<{ id: string, name: string, url: string, file?: File, type?: any, status?: any, timestamp?: any }[]>(
    (intervention.documents || []).map(d => ({ ...d }))
  );

  const photoInputRef = useRef<HTMLInputElement>(null);
  const docInputRef = useRef<HTMLInputElement>(null);

  const [isImproving, setIsImproving] = useState(false);
  const [isImprovingDetails, setIsImprovingDetails] = useState(false);
  const isSyndic = role === 'SYNDIC';
  const [isEditable, setIsEditable] = useState(!readOnly && intervention.status !== 'COMPLETED' && !isSyndic);
  const [isSaving, setIsSaving] = useState(false);
  const [isSendingEmail, setIsSendingEmail] = useState(false);
  const [showSavePrompt, setShowSavePrompt] = useState(false);
  const [viewerData, setViewerData] = useState<{ docs: any[], index: number } | null>(null);

  const [showEditConfirm, setShowEditConfirm] = useState(false);

  // Sync internal status with prop if it changes from outside
  useEffect(() => {
    setStatus(intervention.status);
  }, [intervention.status]);

  // Sync photos and documents from props
  useEffect(() => {
    setPhotos((intervention.photos || []).map(url => ({ url })));
    setDocuments((intervention.documents || []).map(d => ({ ...d })));
  }, [intervention.photos, intervention.documents]);

  // Auto-fill logic from description if fields are empty
  useEffect(() => {
    // Only run if fields are empty and we have a description
    if ((!contactName && !contactPhone) && intervention.description) {
      const pattern = /(?:contact|sur place|contact sur place)\s*[:]\s*([^\d\n(]+)(?:\(([^)]+)\))?/i;
      const match = intervention.description.match(pattern);
      if (match) {
        let name = match[1].trim();
        name = name.replace(/^(M\.|Mr\.|Mme\.|Mle\.)\s*/i, '');
        const phone = match[2] ? match[2].trim().replace(/[^\d+]/g, '') : '';

        if (name) setContactName(name);
        if (phone) setContactPhone(phone);
      }
    }
  }, [intervention.description]);

  const handleImprove = async () => {
    if (!adminNote) return;
    setIsImproving(true);
    const improved = await improveNote(adminNote);
    setAdminNote(improved);
    setIsImproving(false);
  };

  const handleImproveDelayDetails = async () => {
    if (!delayDetails) return;
    setIsImprovingDetails(true);
    const improved = await improveNote(delayDetails);
    setDelayDetails(improved);
    setIsImprovingDetails(false);
  };

  const handleStatusChange = (newStatus: InterventionStatus) => {
    setStatus(newStatus);
  };

  // Auto-set status to DELAYED if a reason is selected
  useEffect(() => {
    if (delayReason && status !== 'DELAYED' && status !== 'COMPLETED') {
      setStatus('DELAYED');
    }
  }, [delayReason, status]);

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files) return;

    const newFiles = (Array.from(files) as File[]).map(file => ({
      url: URL.createObjectURL(file),
      file
    }));
    setPhotos(prev => [...prev, ...newFiles]);
  };

  const handleDocUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files) return;

    const newFiles = (Array.from(files) as File[]).map(file => ({
      id: `new-${Math.random().toString(36).substr(2, 9)}`,
      name: file.name,
      type: 'OTHER',
      status: 'PENDING',
      url: URL.createObjectURL(file), // Used for internal preview only
      file,
      timestamp: new Date().toISOString()
    }));
    setDocuments(prev => [...prev, ...newFiles]);
  };

  const executeSave = async (mode: 'NONE' | 'EMAIL' | 'WHATSAPP') => {
    // Validation: If Delayed, Reason is required.
    if (status === 'DELAYED' && !delayReason) {
      alert(t.delayError);
      setShowSavePrompt(false);
      return;
    }

    setIsSaving(true);
    try {
      let updatedInterventionData = {
        ...intervention,
        status,
        adminFeedback: adminNote,
        delayedRescheduleDate: status === 'DELAYED' ? delayedDate : undefined,
        completedAt: status === 'COMPLETED' ? new Date().toISOString() : intervention.completedAt,
        delayReason: status === 'DELAYED' ? delayReason : undefined,
        delayDetails: status === 'DELAYED' ? delayDetails : undefined,
        delayedAt: status === 'DELAYED' && !intervention.delayedAt ? new Date().toISOString() : (status === 'DELAYED' ? intervention.delayedAt : undefined),
        onSiteContactName: contactName,
        onSiteContactPhone: contactPhone,
        onSiteContactEmail: contactEmail,
        syndicId: internalSyndicId,
        proId: internalProId,
      };

      const formData = new FormData();

      // Mapping for Laravel Backend (snake_case)
      formData.append('status', status);
      formData.append('admin_feedback', adminNote);
      formData.append('on_site_contact_name', contactName);
      formData.append('on_site_contact_phone', contactPhone);
      formData.append('on_site_contact_email', contactEmail);
      formData.append('syndic_id', internalSyndicId);
      formData.append('pro_id', internalProId);

      if (status === 'DELAYED') {
        if (delayReason) formData.append('delay_reason', delayReason);
        if (delayDetails) formData.append('delay_details', delayDetails);
        if (delayedDate) formData.append('delayed_reschedule_date', delayedDate);
      }

      if (status === 'COMPLETED') {
        formData.append('completed_at', new Date().toISOString());
      }

      // Add scheduled date if available to avoid backend validation error on missing/stale data
      if (intervention.scheduledDate) {
        formData.append('scheduled_date', intervention.scheduledDate);
      }

      // Handle existing photos/documents (keeping paths)
      // Note: Backend might need specific handling for existing vs new

      // Handle New Manual Uploads
      photos.filter(p => !!p.file).forEach(p => formData.append('photos[]', p.file!));
      documents.filter(d => !!d.file).forEach(d => formData.append('files[]', d.file!));

      // GENERATE AND APPEND PDF REPORT IF SENDING
      // IMPORTANT: PDF report does NOT include photos - photos remain as separate file uploads
      if (mode === 'EMAIL' || mode === 'WHATSAPP') {
        try {
          const response = await fetch(vankerLogo);
          const blobLogo = await response.blob();
          const reader = new FileReader();
          const logoBase64 = await new Promise<string>((resolve) => {
            reader.onloadend = () => resolve(reader.result as string);
            reader.readAsDataURL(blobLogo);
          });

          const pdfDoc = await generateInterventionPDF(
            updatedInterventionData as any,
            building,
            professional,
            syndic,
            lang,
            logoBase64,
            false // Don't save to file automatically
          );

          const pdfBlob = pdfDoc.output('blob');
          const pdfFile = new File([pdfBlob], `Intervention_Report_${intervention.id}.pdf`, { type: 'application/pdf' });
          formData.append('files[]', pdfFile);
        } catch (pdfErr) {
          console.error("Failed to generate PDF for attachment:", pdfErr);
        }
      }

      const result = await dataService.updateIntervention(intervention.id, formData);
      const savedIntervention = result.intervention;

      if (onUpdate && savedIntervention) {
        // We notify parent to refresh its global state
        // Result from backend is snake_case, handleInterventionUpdate in App.tsx maps it
        await onUpdate(savedIntervention, true); // IMPORTANT: skipApi=true to avoid double save
      }

      if (status === 'COMPLETED') onClose();
      else {
        setIsEditable(false);
      }

      // Handle Email/WhatsApp after successful save
      if (mode === 'EMAIL') {
        setIsSendingEmail(true);
        try {
          await dataService.sendInterventionReport(intervention.id);
          alert(t.emailSent || "Report sent successfully!");
        } catch (error: any) {
          console.error("Failed to send email:", error);
          const serverError = error.response?.data?.error || error.response?.data?.message;
          alert(serverError ? `Email Error: ${serverError}` : (t.sendEmailError || "Failed to send email. Please check your SMTP settings."));
        } finally {
          setIsSendingEmail(false);
        }
      }

      if (mode === 'WHATSAPP') handleSendWhatsApp(savedIntervention);

    } catch (err) {
      console.error("Save failed:", err);
    } finally {
      setIsSaving(false);
      setShowSavePrompt(false);
    }
  };

  const handleSendEmail = () => {
    const recipients = ['admin@vanakel.com']; // Admin always receives
    if (syndic?.email) recipients.push(syndic.email);
    if (professional?.email) recipients.push(professional.email);
    if (contactEmail) recipients.push(contactEmail);

    if (recipients.length === 0 || (recipients.length === 1 && recipients[0] === 'admin@vanakel.com' && !contactEmail && !syndic?.email && !professional?.email)) {
      alert(t.sendEmailError || "No recipients found");
      return;
    }

    const subject = encodeURIComponent(`Intervention: ${intervention.title} - ${building.address}`);

    // Resolve delay reason label for email
    const reasonLabel = DELAY_REASONS.find(r => r.id === delayReason)?.[lang] || delayReason;

    // Use i18n keys for template
    const body = encodeURIComponent(
      `*** ${t.ticketHeader.toUpperCase()} ***\n\n` +
      `${t.email_template_title}: ${intervention.title}\n` +
      `${t.email_template_status}: ${status}\n` +
      `${t.address.toUpperCase()}: ${building.address}, ${building.city}\n\n` +
      `${t.email_template_desc}:\n${intervention.description}\n\n` +
      `${t.email_template_contact}:\n` +
      `Name: ${contactName || 'N/A'}\n` +
      `Phone: ${contactPhone || 'N/A'}\n\n` +
      `${t.email_template_note}:\n${adminNote || 'N/A'}\n\n` +
      (status === 'DELAYED' ? `${t.email_template_delay}: ${reasonLabel || 'N/A'}\n` : '') +
      (status === 'DELAYED' && delayDetails ? `DETAILS: ${delayDetails}\n` : '') +
      (status === 'DELAYED' && delayedDate ? `${t.email_template_new_date}: ${new Date(delayedDate).toLocaleDateString()}\n\n` : '\n') +
      `--- ENTITIES ---\n` +
      `${t.syndic.toUpperCase()}: ${syndic ? `${syndic.companyName} (${syndic.contactPerson})` : t.unassigned}\n` +
      `${t.pro.toUpperCase()}: ${professional ? `${professional.companyName} (${professional.contactPerson})` : t.unassigned}\n\n` +
      `${t.email_template_footer}`
    );

    setTimeout(() => {
      window.location.href = `mailto:${recipients.join(',')}?subject=${subject}&body=${body}`;
      alert(t.emailClientOpened);
    }, 500);
  };

  const handleSendWhatsApp = (updatedIntervention?: any) => {
    const targetPhone = contactPhone || syndic?.phone;
    if (!targetPhone) {
      alert(t.sendWhatsappError || "No phone number available");
      return;
    }

    const currentInt = updatedIntervention || intervention;
    const reasonLabel = DELAY_REASONS.find(r => r.id === delayReason)?.[lang] || delayReason;

    // Find the latest PDF report URL if it was uploaded
    const reportDoc = currentInt.documents?.find((d: any) =>
      (d.file_name || d.name)?.toLowerCase().includes('report') ||
      (d.file_type || d.type) === 'application/pdf'
    );
    const reportUrl = reportDoc ? (reportDoc.file_path ? `${import.meta.env.VITE_API_URL}/storage/${reportDoc.file_path}` : reportDoc.url) : null;

    const text = encodeURIComponent(
      `*VANAKEL GROUP - ${t.ticketHeader.toUpperCase()}*\n\n` +
      `*${t.email_template_title}:* ${currentInt.title}\n` +
      `*${t.building_header}:* ${building.address}\n` +
      `*${t.status}:* ${status}\n\n` +
      `*${t.description}:* ${currentInt.description}\n` +
      `*${t.adminNote}:* ${adminNote || 'N/A'}\n` +
      (status === 'DELAYED' ? `\n*${t.status_delayed}:* ${reasonLabel}\n` : '') +
      (status === 'DELAYED' && delayedDate ? `*${t.email_template_new_date}:* ${new Date(delayedDate).toLocaleDateString()}\n` : '') +
      (reportUrl ? `\n*${t.download_pdf}:* ${reportUrl}\n` : '') +
      `\n_Powered by Vanakel Group_`
    );

    window.open(`https://wa.me/${targetPhone.replace(/\s+/g, '')}?text=${text}`, '_blank');
  };

  return (
    <div className="fixed inset-0 z-[100] bg-brand-black flex flex-col h-[100dvh] overflow-hidden animate-in slide-in-from-bottom duration-300">
      <header className="px-4 md:px-6 py-4 border-b border-zinc-800 flex items-center justify-between bg-zinc-950 shrink-0">
        <button onClick={onClose} className="flex items-center gap-1.5 text-zinc-500 hover:text-white transition-colors text-sm font-bold min-h-[44px]">
          <ChevronLeft size={20} /> <span className="hidden sm:inline">{t.back}</span>
        </button>
        <div className="flex flex-col items-center flex-1 min-w-0 px-4">
          <h2 className="text-xs md:text-sm font-black uppercase tracking-[0.2em] text-brand-green truncate w-full text-center">{t.ticketHeader}</h2>
          <h3 className="text-sm md:text-lg font-bold text-white truncate w-full text-center">
            {intervention.title}{intervention.interventionNumber ? ` – ${intervention.interventionNumber}` : ''}
          </h3>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => onOpenMaintenance?.(building.id)}
            className="flex items-center gap-2 bg-zinc-900 border border-zinc-800 text-zinc-400 px-3 py-1.5 rounded-lg text-xs font-black uppercase tracking-widest hover:border-brand-green hover:text-brand-green transition-all min-h-[44px]"
          >
            <RotateCcw size={14} /> <span className="hidden md:inline">{t.maintenance}</span>
          </button>
          {!isEditable && !isSyndic && !readOnly && (
            <button
              onClick={() => setShowEditConfirm(true)}
              className="flex-1 px-3 py-1.5 rounded-lg text-xs font-black uppercase tracking-widest hover:bg-brand-green hover:text-brand-black transition-all min-h-[44px] bg-brand-green/10 text-brand-green flex items-center justify-center gap-2"
            >
              <Edit2 size={14} /> <span className="hidden md:inline">{t.modifier}</span>
            </button>
          )}

        </div>
      </header>

      <div className="flex-1 overflow-y-auto p-4 md:p-8 space-y-6 md:space-y-10 max-w-5xl mx-auto w-full pb-32">
        {/* Entity Summary */}
        <div className="bg-zinc-900/50 border border-zinc-800 rounded-2xl overflow-hidden relative group">
          <div className="absolute inset-0 z-0">
            <iframe
              width="100%"
              height="100%"
              frameBorder="0"
              style={{ border: 0, opacity: 0.15 }}
              src={`https://maps.google.com/maps?q=${encodeURIComponent(`${building.address}, ${building.city}`)}&t=&z=13&ie=UTF8&iwloc=&output=embed`}
              allowFullScreen
              className="pointer-events-none group-hover:opacity-30 transition-opacity duration-500"
            ></iframe>
            <div className="absolute inset-0 bg-gradient-to-r from-zinc-950 via-zinc-950/80 to-zinc-950/40"></div>
          </div>

          <div className="relative z-10 p-5 md:p-8 grid grid-cols-1 md:grid-cols-2 gap-6 md:gap-10">
            <div className="space-y-5 md:space-y-6">
              <div>
                <p className="text-[9px] md:text-[10px] font-black text-zinc-500 uppercase tracking-widest mb-1.5">{t.building_header}</p>
                <div className="flex items-center gap-3 mb-3">
                  <h3 className="text-lg md:text-2xl font-black text-white leading-tight">{building.address}</h3>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      window.open(`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${building.address}, ${building.city}`)}`, '_blank');
                    }}
                    className="p-1.5 bg-zinc-950/80 rounded-lg text-zinc-400 hover:text-brand-green transition-colors border border-zinc-800 shrink-0 backdrop-blur-sm shadow-lg hover:border-brand-green/50"
                    title={t.viewOnMaps}
                  >
                    <MapPin size={16} />
                  </button>
                </div>
                <div className="flex flex-wrap items-center gap-3">
                  <p className="text-zinc-300 text-sm md:text-base font-medium flex items-center gap-1.5 md:gap-2">
                    <MapPin size={14} className="text-brand-green" /> {building.city}, BE
                  </p>
                  {currentSyndic && (
                    <p className="bg-brand-green/10 text-brand-green px-3 py-1 rounded-full text-[10px] md:text-xs font-black uppercase tracking-widest border border-brand-green/20 backdrop-blur-sm">
                      {t.syndic}: {currentSyndic.companyName}
                    </p>
                  )}
                </div>
              </div>
              <div>
                <p className="text-[9px] md:text-[10px] font-black text-zinc-500 uppercase tracking-widest mb-1.5">{t.syndic}</p>
                <p className="font-bold text-brand-green text-sm md:text-lg drop-shadow-sm">{currentSyndic ? currentSyndic.companyName : t.unassigned}</p>
                <div className="flex flex-col md:items-start gap-1 mt-1">
                  <p className="text-zinc-400 text-[10px] font-bold uppercase">{currentSyndic ? currentSyndic.contactPerson : '-'}</p>
                  {currentSyndic?.phone && <p className="text-zinc-500 text-[10px] flex items-center gap-1.5"><Smartphone size={10} /> {currentSyndic.phone}</p>}
                  {currentSyndic?.email && <p className="text-zinc-500 text-[10px] flex items-center gap-1.5"><Mail size={10} /> {currentSyndic.email}</p>}
                </div>
              </div>
            </div>
            <div className="space-y-5 md:space-y-6 md:text-right border-t md:border-t-0 border-zinc-800/50 pt-5 md:pt-0 relative z-10">
              <div>
                <p className="text-[9px] md:text-[10px] font-black text-zinc-600 uppercase tracking-widest mb-1.5">{t.pro}</p>
                <p className="font-bold text-sm md:text-lg">{currentProfessional ? currentProfessional.companyName : t.unassigned}</p>
                <p className="text-zinc-500 text-[10px] font-black uppercase mt-0.5">{currentProfessional ? currentProfessional.contactPerson : '-'}</p>
              </div>
              <div>
                <p className="text-[9px] md:text-[10px] font-black text-zinc-600 uppercase tracking-widest mb-1.5">{t.scheduled_maintenance}</p>
                <p className="font-bold text-zinc-400 text-sm md:text-base">{new Date(intervention.scheduledDate).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })}</p>

                {/* Delayed Status Visual in Header */}
                {intervention.status === 'DELAYED' && (
                  <div className="mt-2 flex flex-col md:items-end gap-1 text-orange-500">
                    <div className="flex items-center gap-1.5 font-bold">
                      <AlertCircle size={14} />
                      <span className="text-xs uppercase tracking-widest">{t.status_delayed}</span>
                    </div>
                    {intervention.delayReason && (
                      <p className="text-[10px] opacity-80">{DELAY_REASONS.find(r => r.id === intervention.delayReason)?.[lang as keyof { EN: string, FR: string, NL: string }] || intervention.delayReason}</p>
                    )}
                  </div>
                )}
              </div>

              {/* SOURCE DETAILS - ONLY FOR EMAIL INTERVENTIONS */}
              {intervention.sourceType === 'EMAIL' && intervention.sourceDetails && (
                <div className="bg-brand-green/5 border border-brand-green/20 p-4 rounded-xl text-left md:text-right">
                  <div className="flex items-center md:justify-end gap-1.5 mb-2 text-brand-green">
                    <AtSign size={14} />
                    <span className="text-[9px] font-black uppercase tracking-widest">{t.automatic_import}</span>
                  </div>
                    <div className="space-y-1">
                      <p className="text-xs font-bold text-white truncate" title={intervention.sourceDetails.subject}>{intervention.sourceDetails.subject}</p>
                      <p className="text-[10px] text-zinc-400">{t.from_label}: {intervention.sourceDetails.from}</p>
                      <p className="text-[10px] text-zinc-500">{new Date(intervention.sourceDetails.receivedAt).toLocaleString()}</p>
                    </div>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* CONTACT SUR PLACE - INTERVENTION SPECIFIC */}
        <div className="bg-zinc-950 border border-zinc-900 rounded-2xl p-5 md:p-8 relative overflow-hidden">
          <div className="absolute top-0 left-0 w-1 h-full bg-brand-green/20"></div>
          <h4 className="text-[10px] font-black text-zinc-600 uppercase tracking-widest mb-4 flex items-center gap-2">
            <User size={14} /> {t.onSiteContactLabel}
          </h4>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <label className="text-[9px] font-black text-zinc-600 uppercase tracking-widest">{t.contact_name}</label>
              <input
                type="text"
                value={contactName}
                onChange={(e) => setContactName(e.target.value)}
                disabled={!isEditable}
                placeholder={t.contact_name}
                className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2.5 text-sm font-bold text-white focus:border-brand-green outline-none transition-all disabled:opacity-60 disabled:cursor-not-allowed"
              />
            </div>
            <div className="space-y-1.5">
              <label className="text-[9px] font-black text-zinc-600 uppercase tracking-widest">{t.contact_gsm}</label>
              <input
                type="text"
                value={contactPhone}
                onChange={(e) => setContactPhone(e.target.value)}
                disabled={!isEditable}
                placeholder="+32 ..."
                className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2.5 text-sm font-bold text-white focus:border-brand-green outline-none transition-all disabled:opacity-60 disabled:cursor-not-allowed"
              />
            </div>
            <div className="space-y-1.5 md:col-span-2">
              <label className="text-[9px] font-black text-zinc-600 uppercase tracking-widest">{t.contact_email_opt}</label>
              <input
                type="email"
                value={contactEmail}
                onChange={(e) => setContactEmail(e.target.value)}
                disabled={!isEditable}
                placeholder="contact@email.com"
                className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2.5 text-sm font-bold text-white focus:border-brand-green outline-none transition-all disabled:opacity-60 disabled:cursor-not-allowed"
              />
            </div>
          </div>

          {/* Syndic / Manager / Customer Footer */}
          {(currentSyndic || (isEditable && !isSyndic)) && (
            <div className="mt-8 pt-6 border-t border-zinc-900/50">
              {isEditable && !isSyndic ? (
                <div className="space-y-3">
                  <div className="flex justify-between items-center">
                    <label className="text-[9px] font-black text-zinc-500 uppercase tracking-widest">{t.syndic} / {t.customer_info}</label>
                    {internalSyndicId && (
                      <button
                        onClick={() => setInternalSyndicId('')}
                        className="text-[9px] font-bold text-red-500 uppercase hover:underline"
                      >
                        {t.cancel}
                      </button>
                    )}
                  </div>
                  <select
                    value={internalSyndicId}
                    onChange={(e) => setInternalSyndicId(e.target.value)}
                    className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-3 text-xs font-bold text-white focus:border-brand-green outline-none transition-all"
                  >
                    <option value="">{t.select_customer}</option>
                    {syndics.map(s => (
                      <option key={s.id} value={s.id}>{s.companyName} ({s.contactPerson})</option>
                    ))}
                  </select>

                  {currentSyndic && (
                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-brand-green/5 p-4 rounded-xl border border-brand-green/20 mt-3">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-brand-green/10 flex items-center justify-center text-brand-green border border-brand-green/20">
                          <User size={18} />
                        </div>
                        <div>
                          <p className="text-[9px] font-black text-zinc-500 uppercase tracking-[0.2em] leading-none mb-1.5">{t.syndic} / {t.manager_label}</p>
                          <p className="text-xs font-black text-white">{currentSyndic.companyName}</p>
                          <p className="text-[10px] text-zinc-500 font-bold uppercase tracking-wider">{currentSyndic.contactPerson}</p>
                        </div>
                      </div>
                      <div className="flex flex-col md:items-end justify-center gap-1.5">
                        {currentSyndic.phone && (
                          <p className="text-[10px] font-bold text-zinc-400 flex items-center gap-2">
                            <Smartphone size={12} className="text-brand-green" /> {currentSyndic.phone}
                          </p>
                        )}
                        {currentSyndic.email && (
                          <p className="text-[10px] font-medium text-zinc-500 flex items-center gap-2">
                            <Mail size={12} /> {currentSyndic.email}
                          </p>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              ) : currentSyndic ? (
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-zinc-900/30 p-4 rounded-xl border border-zinc-800/50">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-brand-green/10 flex items-center justify-center text-brand-green border border-brand-green/20">
                      <User size={18} />
                    </div>
                    <div>
                      <p className="text-[9px] font-black text-zinc-500 uppercase tracking-[0.2em] leading-none mb-1.5">{t.syndic} / {t.manager_label}</p>
                      <p className="text-xs font-black text-white">{currentSyndic.companyName}</p>
                      <p className="text-[10px] text-zinc-500 font-bold uppercase tracking-wider">{currentSyndic.contactPerson}</p>
                    </div>
                  </div>
                  <div className="flex flex-col md:items-end justify-center gap-1.5">
                    {currentSyndic.phone && (
                      <a href={`tel:${currentSyndic.phone}`} className="text-xs font-bold text-zinc-300 hover:text-brand-green transition-colors flex items-center gap-2">
                        <Smartphone size={12} className="text-brand-green" /> {currentSyndic.phone}
                      </a>
                    )}
                    {currentSyndic.email && (
                      <a href={`mailto:${currentSyndic.email}`} className="text-xs font-medium text-zinc-500 hover:text-white transition-colors flex items-center gap-2">
                        <Mail size={12} /> {currentSyndic.email}
                      </a>
                    )}
                  </div>
                </div>
              ) : null}
            </div>
          )}


        </div>

        {/* Description Section */}
        <div className="bg-zinc-950 border border-zinc-900 rounded-2xl p-5 md:p-8 mb-6">
          <h4 className="text-[10px] font-black text-brand-green uppercase tracking-widest mb-4">{t.description}</h4>
          {/* Replaced raw description with formatted component */}
          <FormattedExtractedContent text={intervention.description} />
        </div>

        {/* Original Attachments Display prominently below description */}
        {intervention.documents && intervention.documents.length > 0 && (
          <div className="bg-zinc-950 border border-zinc-900 rounded-2xl p-5 md:p-8 mb-6">
            <h4 className="text-[10px] font-black text-brand-green uppercase tracking-widest mb-4">{t.attachDocuments}</h4>
            <div className="flex flex-wrap gap-3">
              {intervention.documents.map((doc: any, idx: number) => {
                const isImg = /\.(jpg|jpeg|png|webp|gif|svg)$/i.test(doc.url);
                return (
                  <div
                    key={`orig-doc-${doc.id || idx}`}
                    className="group relative flex items-center gap-3 p-3 bg-zinc-900 border border-zinc-800 hover:border-brand-green/50 rounded-xl cursor-pointer transition-all overflow-hidden"
                    onClick={() => {
                      setViewerData({ docs: intervention.documents || [], index: idx });
                    }}
                  >
                    {isImg ? (
                      <div className="w-10 h-10 rounded overflow-hidden shrink-0 border border-zinc-800 bg-black">
                        <img src={doc.url} alt="" className="w-full h-full object-cover group-hover:scale-110 transition-transform" />
                      </div>
                    ) : (
                      <div className="w-10 h-10 rounded shrink-0 border border-zinc-800 bg-zinc-800/50 flex items-center justify-center text-zinc-500">
                        <FileText size={20} />
                      </div>
                    )}
                    <div className="flex flex-col max-w-[150px] sm:max-w-[200px]">
                      <span className="text-xs font-bold text-zinc-200 truncate" title={doc.name}>{doc.name}</span>
                      <span className="text-[10px] text-zinc-500 uppercase tracking-wider">{isImg ? 'Photo' : 'Document'}</span>
                    </div>
                    <div className="absolute inset-0 bg-brand-green/5 opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none" />
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Controls Section */}
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-6 md:gap-10">
          <div className="space-y-8">
            <div className="space-y-3" id="slip-status">
              <label className="inline-block px-2 py-0.5 bg-brand-green text-brand-black text-[10px] font-black uppercase tracking-widest rounded mb-2">{t.updateStatus}</label>
              <div className="grid grid-cols-3 gap-2 md:gap-3">
                {[
                  { id: 'PENDING', label: t.status_pending, activeColor: 'bg-zinc-600 text-white border-zinc-600', baseColor: 'bg-transparent border-zinc-800 text-zinc-500' },
                  { id: 'DELAYED', label: t.status_delayed, activeColor: 'bg-brand-orange text-white border-brand-orange', baseColor: 'bg-transparent border-brand-orange/40 text-brand-orange' },
                  { id: 'COMPLETED', label: t.status_completed, activeColor: 'bg-brand-green text-brand-black border-brand-green', baseColor: 'bg-transparent border-brand-green/40 text-brand-green' }
                ].map(s => (
                  <button
                    key={s.id}
                    disabled={!isEditable}
                    onClick={() => handleStatusChange(s.id as any)}
                    className={`py-3 md:py-4 rounded-2xl border font-black text-[9px] md:text-[10px] tracking-widest transition-all min-h-[44px] ${status === s.id ? s.activeColor : 'bg-brand-black ' + s.baseColor} ${!isEditable ? 'cursor-default' : ''}`}
                  >
                    {s.label}
                  </button>
                ))}
              </div>

              {/* REASON FOR DELAY - NEW SECTION */}
              <div className={`mt-4 p-5 bg-zinc-900/50 border ${status === 'DELAYED' ? 'border-orange-500/50' : 'border-zinc-800'} rounded-2xl transition-all ${status !== 'DELAYED' ? 'hidden' : 'block'}`}>
                <h5 className={`text-[10px] font-black uppercase tracking-widest mb-3 flex items-center gap-2 ${status === 'DELAYED' ? 'text-orange-500' : 'text-zinc-500'}`}>
                  <AlertCircle size={14} /> {t.delayTitle}
                </h5>

                <div className="space-y-4">
                  <div className="space-y-1.5">
                    <label className="text-[9px] font-bold text-zinc-600 uppercase tracking-wide">{t.delayReasonLabel}</label>
                    <select
                      value={delayReason}
                      onChange={(e) => setDelayReason(e.target.value)}
                      disabled={!isEditable}
                      className={`w-full bg-zinc-950 border ${status === 'DELAYED' && !delayReason ? 'border-red-500' : 'border-zinc-800'} px-4 py-3 rounded-xl text-sm font-medium text-white outline-none focus:border-orange-500 transition-all appearance-none`}
                    >
                      <option value="">{t.selectReason}</option>
                      {DELAY_REASONS.map(r => (
                        <option key={r.id} value={r.id}>{r[lang]}</option>
                      ))}
                    </select>
                  </div>

                  <div className="space-y-1.5">
                    <div className="flex justify-between items-center">
                      <label className="text-[9px] font-bold text-zinc-600 uppercase tracking-wide">{t.delayDetailsLabel} {delayReason === 'other' && '*'}</label>
                      {isEditable && (
                        <button
                          onClick={handleImproveDelayDetails}
                          disabled={isImprovingDetails || !delayDetails}
                          className="flex items-center gap-1.5 text-brand-green text-[9px] font-black uppercase tracking-widest hover:bg-brand-green/10 px-2 py-1 rounded transition-all disabled:opacity-50 min-h-[30px]"
                        >
                          {isImprovingDetails ? <Loader2 size={12} className="animate-spin" /> : <Sparkles size={12} />} {isImprovingDetails ? t.working : t.improveAI_text}
                        </button>
                      )}
                    </div>
                    <textarea
                      value={delayDetails}
                      onChange={(e) => setDelayDetails(e.target.value)}
                      disabled={!isEditable}
                      placeholder={t.delayDetailsPlaceholder}
                      className="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-4 py-2 text-sm text-zinc-300 outline-none focus:border-orange-500 min-h-[80px]"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-[9px] font-bold text-zinc-600 uppercase tracking-wide">{t.rescheduleDate} (Optionnel)</label>
                    <div className="relative">
                      <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500 pointer-events-none" size={16} />
                      <input
                        type="date"
                        value={delayedDate}
                        onChange={(e) => setDelayedDate(e.target.value)}
                        onClick={(e) => (e.target as any).showPicker?.()}
                        disabled={!isEditable}
                        className="w-full bg-zinc-950 border border-zinc-800 px-10 py-2.5 rounded-xl text-sm outline-none focus:border-orange-500 transition-all text-white cursor-pointer"
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="space-y-3" id="slip-notes">
              <div className="flex justify-between items-center">
                <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.adminNote}</label>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => photoInputRef.current?.click()}
                    disabled={!isEditable}
                    className="flex items-center gap-1.5 text-zinc-500 hover:text-white text-[9px] font-black uppercase tracking-widest bg-zinc-900 border border-zinc-800 px-2 py-1 rounded transition-all disabled:opacity-50"
                  >
                    <Camera size={12} /> {t.photos}
                  </button>
                  <button
                    onClick={() => docInputRef.current?.click()}
                    disabled={!isEditable}
                    className="flex items-center gap-1.5 text-zinc-500 hover:text-white text-[9px] font-black uppercase tracking-widest bg-zinc-900 border border-zinc-800 px-2 py-1 rounded transition-all disabled:opacity-50"
                  >
                    <Upload size={12} /> {t.docs}
                  </button>
                  {isEditable && (
                    <button
                      onClick={handleImprove}
                      disabled={isImproving || !adminNote}
                      className="flex items-center gap-1.5 text-brand-green text-[9px] font-black uppercase tracking-widest hover:bg-brand-green/10 px-2 py-1 rounded transition-all disabled:opacity-50 min-h-[30px]"
                    >
                      {isImproving ? <Loader2 size={14} className="animate-spin" /> : <Sparkles size={14} />} {isImproving ? t.working : t.improveAI}
                    </button>
                  )}
                </div>
              </div>
              {isEditable ? (
                <textarea
                  value={adminNote}
                  onChange={e => setAdminNote(e.target.value)}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-2xl p-4 min-h-[160px] md:min-h-[200px] outline-none focus:border-brand-green transition-all text-sm text-zinc-300 leading-relaxed"
                  placeholder={t.technical_feedback_placeholder}
                />
              ) : (
                <div className="w-full bg-zinc-900 border border-zinc-800 rounded-2xl p-4 min-h-[100px] text-sm text-zinc-300 leading-relaxed italic">
                  {adminNote ? (
                    <div className="whitespace-pre-wrap">{adminNote}</div>
                  ) : (
                    <span className="text-zinc-500">{t.no_technical_observations}</span>
                  )}
                </div>
              )}
              {photos.filter(p => !!p.file).length > 0 && (
                <div className="flex gap-2 overflow-x-auto py-2 scrollbar-none">
                  {photos.filter(p => !!p.file).map((photo, idx) => (
                    <div key={`new-p-${idx}`} className="relative shrink-0 w-16 h-16 rounded-xl border border-brand-green/30 overflow-hidden group">
                      <img src={photo.url} alt="" className="w-full h-full object-cover" />
                      <button
                        onClick={() => setPhotos(prev => prev.filter(p => p.url !== photo.url))}
                        className="absolute inset-0 bg-red-500/80 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
                      >
                        <X size={14} className="text-white" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          <div className="space-y-8">
            <div className="space-y-3" id="slip-media">
              <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">{t.mediaAudit}</label>

              <input
                type="file"
                ref={photoInputRef}
                className="hidden"
                accept="image/*"
                multiple
                onChange={handlePhotoUpload}
              />
              <input
                type="file"
                ref={docInputRef}
                className="hidden"
                accept=".pdf,.doc,.docx,.xls,.xlsx"
                multiple
                onChange={handleDocUpload}
              />

              <div className="grid grid-cols-2 gap-3 md:gap-4">
                <button
                  onClick={() => photoInputRef.current?.click()}
                  disabled={!isEditable}
                  className="flex flex-col items-center justify-center p-8 bg-zinc-900/30 border border-dashed border-zinc-800 rounded-2xl text-zinc-500 hover:text-brand-green hover:border-brand-green transition-all group min-h-[140px] disabled:opacity-50"
                >
                  <div className="w-12 h-12 rounded-full bg-zinc-950 flex items-center justify-center mb-3 border border-zinc-800 group-hover:border-brand-green/50 transition-all shadow-inner">
                    <Camera size={24} className="group-hover:scale-110 transition-transform" />
                  </div>
                  <span className="text-[10px] font-black uppercase tracking-[0.2em]">{t.photos}</span>
                </button>
                <button
                  onClick={() => docInputRef.current?.click()}
                  disabled={!isEditable}
                  className="flex flex-col items-center justify-center p-8 bg-zinc-900/30 border border-dashed border-zinc-800 rounded-2xl text-zinc-500 hover:text-brand-green hover:border-brand-green transition-all group min-h-[140px] disabled:opacity-50"
                >
                  <div className="w-12 h-12 rounded-full bg-zinc-950 flex items-center justify-center mb-3 border border-zinc-800 group-hover:border-brand-green/50 transition-all shadow-inner">
                    <Upload size={24} className="group-hover:scale-110 transition-transform" />
                  </div>
                  <span className="text-[10px] font-black uppercase tracking-[0.2em]">{t.docs}</span>
                </button>
              </div>

              {/* Media Gallery Preview */}
              {(photos.length > 0 || documents.length > 0) && (
                <div className="grid grid-cols-1 gap-4 mt-6">
                  {photos.length > 0 && (
                    <div className="space-y-2">
                      <p className="text-[9px] font-black text-zinc-600 uppercase tracking-widest">{t.photos} ({photos.length})</p>
                      <div className="flex flex-wrap gap-2">
                        {photos.map((photo, idx) => (
                          <div key={idx} className="relative group w-20 h-20 md:w-24 md:h-24 rounded-xl overflow-hidden border border-zinc-800 bg-zinc-900">
                            <img
                              src={photo.url}
                              alt={`upload-${idx}`}
                              className="w-full h-full object-cover cursor-pointer hover:scale-110 transition-transform"
                              onClick={() => {
                                // Prepare unified list: Photos first, then Docs
                                const photoDocs = photos.map((p, i) => ({ id: `photo-${i}`, name: `Photo ${i + 1}`, url: p.url, type: 'OTHER', status: 'APPROVED', timestamp: '' } as any));
                                const unifiedDocs = [...photoDocs, ...documents];
                                setViewerData({ docs: unifiedDocs, index: idx });
                              }}
                            />
                            {isEditable && (
                              <button
                                onClick={() => setPhotos(prev => prev.filter((_, i) => i !== idx))}
                                className="absolute top-1 right-1 p-1 bg-black/60 text-white rounded-full opacity-0 group-hover:opacity-100 transition-opacity"
                              >
                                <X size={12} />
                              </button>
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {documents.length > 0 && (
                    <div className="space-y-2">
                      <p className="text-[9px] font-black text-zinc-600 uppercase tracking-widest">{t.docs} ({documents.length})</p>
                      <div className="space-y-2">
                        {documents.map((doc, idx) => (
                          <div key={doc.id || idx} className="flex items-center justify-between p-3 bg-zinc-900 border border-zinc-800 rounded-xl group hover:border-zinc-700 transition-all">
                            <div className="flex items-center gap-3 overflow-hidden">
                              <FileText size={16} className="text-zinc-500 shrink-0" />
                              <span className="text-xs font-medium text-zinc-300 truncate">{doc.name}</span>
                            </div>
                            <div className="flex items-center gap-2">
                              <button
                                onClick={() => {
                                  const photoDocs = photos.map((p, i) => ({ id: `photo-${i}`, name: `Photo ${i + 1}`, url: p.url, type: 'OTHER', status: 'APPROVED', timestamp: '' } as any));
                                  const unifiedDocs = [...photoDocs, ...documents];
                                  setViewerData({ docs: unifiedDocs, index: photos.length + idx });
                                }}
                                className="p-1.5 text-zinc-400 hover:text-brand-green transition-colors"
                                title="Preview"
                              >
                                <Eye size={16} />
                              </button>
                              <a
                                href={doc.url}
                                download
                                className="p-1.5 text-zinc-400 hover:text-white transition-colors"
                              >
                                <FileText size={14} />
                              </a>
                              {isEditable && (
                                <button
                                  onClick={() => setDocuments(prev => prev.filter((_, i) => i !== idx))}
                                  className="p-1.5 text-zinc-500 hover:text-red-500 transition-colors"
                                >
                                  <X size={14} />
                                </button>
                              )}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>

            <div className="p-6 bg-brand-green/5 border border-brand-green/10 rounded-2xl relative overflow-hidden">
              <div className="absolute top-0 left-0 w-1 h-full bg-brand-green/20"></div>
              <p className="text-[9px] font-black text-brand-green uppercase tracking-[0.2em] mb-4">{t.auditTrace}</p>
              <div className="space-y-4">
                <div className="flex gap-3">
                  <div className="shrink-0 w-8 h-8 rounded-lg bg-brand-green/10 flex items-center justify-center text-brand-green text-[10px] font-black border border-brand-green/20">
                    <CheckCircle2 size={16} />
                  </div>
                  <div>
                    <p className="text-xs font-black text-zinc-300 uppercase tracking-widest mb-0.5">{t.intInitialized}</p>
                    <p className="text-[10px] text-zinc-500 font-mono">{new Date(intervention.createdAt || intervention.scheduledDate).toLocaleString()}</p>
                  </div>
                </div>
                {intervention.status === 'COMPLETED' && intervention.completedAt && (
                  <div className="flex gap-3">
                    <div className="shrink-0 w-8 h-8 rounded-lg bg-brand-green flex items-center justify-center text-brand-black text-[10px] font-black border border-brand-green/20">
                      <CheckCircle2 size={16} />
                    </div>
                    <div>
                      <p className="text-xs font-black text-brand-green uppercase tracking-widest mb-0.5">{t.status_completed}</p>
                      <p className="text-[10px] text-zinc-500 font-mono">{new Date(intervention.completedAt).toLocaleString()}</p>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Save Actions */}
            {!isSyndic && (
              <div className="space-y-3 pt-6 border-t border-zinc-800" id="slip-save">
                <button
                  onClick={() => setShowSavePrompt(true)}
                  disabled={!isEditable || isSaving}
                  className="w-full py-4 bg-brand-green text-brand-black rounded-xl font-black text-sm uppercase tracking-widest hover:bg-brand-green-light transition-all shadow-xl shadow-brand-green/20 disabled:opacity-50 disabled:shadow-none flex items-center justify-center gap-2 min-h-[56px]"
                >
                  {isSaving ? <Loader2 size={16} className="animate-spin" /> : <Save size={16} />}
                  {isSaving ? t.saving || "Enregistrement..." : t.saveRegister}
                </button>

                {showSavePrompt && (
                  <div className="fixed inset-0 z-[110] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-in fade-in duration-200">
                    <div className="bg-zinc-950 border border-zinc-800 w-full max-w-sm rounded-2xl p-6 shadow-2xl relative">
                      <button onClick={() => setShowSavePrompt(false)} className="absolute top-4 right-4 text-zinc-500 hover:text-white"><X size={20} /></button>
                      <h4 className="text-lg font-bold text-white mb-4 text-center">{t.saveModalTitle}</h4>
                      <p className="text-zinc-500 text-xs text-center mb-6">{t.saveMode}</p>

                      <div className="space-y-3">
                        <button onClick={() => executeSave('NONE')} disabled={isSaving || isSendingEmail} className="w-full py-3 bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 rounded-xl font-bold text-xs uppercase text-zinc-300 transition-all flex items-center justify-center gap-2 disabled:opacity-50">
                          {isSaving ? <Loader2 className="animate-spin" size={16} /> : <Save size={16} />}
                          {isSaving ? t.saving || "Enregistrement..." : t.saveOnly}
                        </button>
                        <button onClick={() => executeSave('EMAIL')} disabled={isSaving || isSendingEmail} className="w-full py-3 bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 rounded-xl font-bold text-xs uppercase text-zinc-300 transition-all flex items-center justify-center gap-2 disabled:opacity-50">
                          {isSendingEmail ? <Loader2 className="animate-spin" size={16} /> : <Mail size={16} />}
                          {isSendingEmail ? t.sending || "Envoi..." : t.saveEmail}
                        </button>
                        <button onClick={() => executeSave('WHATSAPP')} disabled={isSaving || isSendingEmail} className="w-full py-3 bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 rounded-xl font-bold text-xs uppercase text-zinc-300 transition-all flex items-center justify-center gap-2 disabled:opacity-50">
                          <MessageCircle size={16} /> {t.saveWhatsapp}
                        </button>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )}

          </div>
        </div>
      </div>

      {/* Edit Confirmation Modal */}
      {showEditConfirm && (
        <div className="fixed inset-0 z-[110] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-zinc-950 border border-zinc-800 w-full max-w-sm rounded-2xl p-6 shadow-2xl text-center">
            <div className="w-12 h-12 bg-zinc-900 rounded-full flex items-center justify-center mx-auto mb-4 text-zinc-400">
              <Edit2 size={24} />
            </div>
            <h4 className="text-lg font-bold text-white mb-2">{t.editConfirmTitle}</h4>
            <p className="text-zinc-500 text-sm mb-6">{t.editConfirmDesc}</p>
            <div className="flex gap-3">
              <button onClick={() => setShowEditConfirm(false)} className="flex-1 py-3 bg-zinc-900 text-zinc-400 rounded-xl font-bold text-xs uppercase">{t.cancel}</button>
              <button
                onClick={() => {
                  setIsEditable(true);
                  setShowEditConfirm(false);
                }}
                className="flex-1 py-3 bg-brand-green text-brand-black rounded-xl font-bold text-xs uppercase"
              >
                {t.yesEdit}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Document Viewer Modal */}
      {viewerData && (
        <DocumentViewerModal
          isOpen={!!viewerData}
          onClose={() => setViewerData(null)}
          documents={viewerData.docs}
          initialIndex={viewerData.index}
        />
      )}
    </div>
  );
};

export default InterventionSlip;