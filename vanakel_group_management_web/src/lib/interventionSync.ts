import { Intervention, InterventionStatus, Sector, Urgency } from '@/types';
import { STORAGE_BASE_URL } from '@/lib/apiClient';

const fileUrl = (raw: string | undefined | null): string => {
  let path = raw || '';
  if (path.includes('localhost')) {
    path = path.replace(/http:\/\/localhost(:\d+)?\/storage\//, '').replace(/http:\/\/localhost(:\d+)?\//, '');
  }
  return path.startsWith('http') ? path : `${STORAGE_BASE_URL}/${path}`;
};

/**
 * One intervention as the server sends it (list and save answers alike) -> what the screens use.
 * The list and the save go through the same mapping, so a save never leaves a half-mapped item on screen
 * (raw photo paths, snake_case fields...).
 */
export const mapApiIntervention = (i: any): Intervention => ({
  id: String(i.id),
  buildingId: String(i.building_id),
  title: i.title,
  title_en: i.title_en,
  title_fr: i.title_fr,
  title_nl: i.title_nl,
  category: i.category,
  sector: i.sector as Sector,
  description: i.description,
  description_en: i.description_en,
  description_fr: i.description_fr,
  description_nl: i.description_nl,
  scheduledDate: i.scheduled_date || i.created_at,
  createdAt: i.created_at,
  updatedAt: i.updated_at || undefined,
  status: i.status as InterventionStatus,
  notes: i.notes || [],
  photos: (i.photos || []).map((p: string) => fileUrl(p)),
  documents: (i.documents || []).map((d: any) => ({
    id: String(d.id),
    name: d.file_name,
    type: 'OTHER',
    status: 'APPROVED',
    url: d.url || fileUrl(d.file_path),
    timestamp: d.created_at,
  })),
  proId: String(i.pro_id || i.professional_id || ''),
  assignedToAdmin: !!i.assigned_to_admin,
  professional: i.professional ? {
    id: String(i.professional.id),
    name: i.professional.name,
    email: i.professional.email,
    phone: i.professional.phone,
    role: i.professional.role,
    company_name: i.professional.company_name,
  } as any : undefined,
  urgency: i.urgency as Urgency,
  onSiteContactName: i.on_site_contact_name,
  onSiteContactPhone: i.on_site_contact_phone,
  onSiteContactEmail: i.on_site_contact_email,
  sourceType: i.source_type || 'MANUAL',
  syndicId: i.syndic_id ? String(i.syndic_id) : undefined,
  adminFeedback: i.admin_feedback,
  submittedAt: i.submitted_at || undefined,
  submittedByName: i.submitter?.name,
  delayReason: i.delay_reason,
  delayDetails: i.delay_details,
  delayedRescheduleDate: i.delayed_reschedule_date,
  delayedAt: i.delayed_at,
  completedAt: i.completed_at,
} as Intervention);

/**
 * The fresh list, reusing the objects that did not change. An open slip re-reads its photos when the
 * intervention's arrays change, so a background refresh must not hand it new-but-equal arrays (that would
 * drop photos the user added and has not saved yet).
 */
export const keepUnchanged = (prev: Intervention[], next: Intervention[]): Intervention[] => {
  const byId = new Map(prev.map(i => [i.id, i]));
  let same = prev.length === next.length;
  const merged = next.map((n, index) => {
    const old = byId.get(n.id);
    if (old && JSON.stringify(old) === JSON.stringify(n)) {
      if (prev[index] !== old) same = false;
      return old;
    }
    same = false;
    return n;
  });
  return same ? prev : merged;
};

const time = (value?: string) => {
  const t = value ? new Date(value).getTime() : NaN;
  return Number.isNaN(t) ? 0 : t;
};

/** When the report was last written: the latest save, else when it was completed / delayed / created. */
export const reportTime = (i: Intervention): number =>
  Math.max(time(i.updatedAt), time(i.completedAt), time(i.delayedAt), time(i.submittedAt)) ||
  time(i.createdAt) || time(i.scheduledDate);

export const isReport = (i: Intervention) => i.status === 'COMPLETED' || i.status === 'DELAYED';

/** Reports (completed or delayed work), the most recently written first: the dashboard and the Reports page. */
export const latestReports = (interventions: Intervention[]): Intervention[] =>
  interventions.filter(isReport).sort((a, b) => reportTime(b) - reportTime(a));
