
export type Role = 'SUPERADMIN' | 'ADMIN' | 'PROFESSIONAL' | 'SYNDIC' | 'CLIENT';
export type Language = 'EN' | 'FR' | 'NL';
export type Urgency = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';


export interface AdminUser {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  createdAt: string;
}

export interface SignupRequest {
  id: string;
  role: 'ADMIN' | 'SYNDIC';
  firstName: string;
  lastName: string;
  email: string;
  password?: string;
  phone: string;
  companyName?: string; // For Syndics
  timestamp: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
}

// ON_HOLD removed
export type InterventionStatus = 'PENDING' | 'DELAYED' | 'COMPLETED';

export type Sector =
  | 'ELECTRICITE'
  | 'CARRELAGE'
  | 'SANITAIRE'
  | 'CHAUFFAGE'
  | 'PLOMBERIE'
  | 'PEINTURE'
  | 'MENUISERIE'
  | 'GENERAL'
  | 'AUTRE';

export interface Tenant {
  firstName: string;
  lastName: string;
  email?: string;
  phone?: string;
}

export interface Building {
  id: string;
  address: string;
  city: string;
  tenants: Tenant[];
  phone: string;
  linkedProfessionalId: string;
  linkedSyndicId: string;
  adminNote: string;
  imageUrl?: string;
  installationDate: string; // ISO date for predictive
  devices: Device[];
}

export interface Device {
  id: string;
  name: string;
  type: string;
  installationDate: string;
  lastMaintenance?: string;
}

export interface Professional {
  id: string;
  companyName: string;
  contactPerson: string;
  phone: string;
  landline: string;
  email: string;
  address: string;
}

export interface Syndic {
  id: string;
  companyName: string;
  contactPerson: string;
  phone: string; // Used for WhatsApp
  landline: string;
  email: string;
  address: string;
}

export interface Intervention {
  id: string;
  buildingId: string;
  title: string; // Mandatory title
  category: string; // Legacy category field, kept for compatibility but UI should favor sector
  sector: Sector; // New mandatory sector field
  description: string; // Mandatory technical description
  scheduledDate: string;
  createdAt?: string; // New field for tracking creation time
  status: InterventionStatus;
  notes: Note[];
  photos: string[];
  documents: Document[];
  proId: string;
  signature?: string;
  completedAt?: string;
  adminFeedback?: string;

  // Delay Management (New)
  delayedRescheduleDate?: string; // Optional rescheduling
  delayReason?: string; // Enum Key
  delayDetails?: string; // Free text
  delayedAt?: string; // Timestamp

  // Sector Metadata
  sectorSource?: 'MANUAL' | 'SYSTEM';
  sectorConfidence?: 'HIGH' | 'MEDIUM' | 'LOW';

  // Contact Sur Place (Specific to this intervention)
  onSiteContactName?: string;
  onSiteContactPhone?: string;
  onSiteContactEmail?: string;

  // Source Tracking for Email Automation
  sourceType?: 'MANUAL' | 'EMAIL' | 'MAINTENANCE_PLAN'; // Added MAINTENANCE_PLAN
  sourceMessageId?: string;
  sourceDetails?: {
    from: string;
    subject: string;
    receivedAt: string;
  };

  // Link to Maintenance Plan
  maintenancePlanId?: string;
  isMaintenanceOccurrence?: boolean;

  // Intervention Number (e.g. OS-123)
  interventionNumber?: string;
  urgency?: Urgency;
}


export interface Note {
  id: string;
  author: string;
  authorRole: Role;
  content: string;
  timestamp: string;
  isInternal: boolean;
}

export interface Document {
  id: string;
  name: string;
  type: 'OFFER' | 'INVOICE' | 'REPORT' | 'OTHER' | 'EMAIL_ATTACHMENT';
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  url: string;
  timestamp: string;
}

export interface Mission {
  id: string;
  buildingId: string;
  requestedBy: Role;
  title?: string; // Optional title for missions
  proId?: string;
  syndicId?: string;
  category: string;
  sector: Sector; // Mandatory
  description: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  timestamp: string;

  // Sector Metadata
  sectorSource?: 'MANUAL' | 'SYSTEM';
  sectorConfidence?: 'HIGH' | 'MEDIUM' | 'LOW';

  // Contact Sur Place (Specific to this mission)
  onSiteContactName?: string;
  onSiteContactPhone?: string;
  onSiteContactEmail?: string;

  // Source Tracking
  sourceType?: 'MANUAL' | 'EMAIL';
  sourceMessageId?: string;
  sourceDetails?: {
    from: string;
    subject: string;
    receivedAt: string;
  };

  // Intervention Number (e.g. OS-123)
  interventionNumber?: string;
  urgency?: Urgency;
  documents: Document[];
}


export type MaintenanceFrequency = 'MONTHLY' | 'QUARTERLY' | 'YEARLY';

export interface MaintenancePlan {
  id: string;
  buildingId: string;
  title: string;
  description?: string;
  recurrence: {
    frequency: MaintenanceFrequency;
    interval: number; // e.g., 1
    startDate: string; // ISO
    endDate: string; // ISO (startDate + 5 years)
  };
  createdAt: string;
  status: 'ACTIVE' | 'CANCELLED';
  syndicId?: string; // Cache for easier display
}

export interface MaintenanceRule {
  id: string;
  buildingId: string;
  deviceId?: string;
  label: string;
  cycleDays: number;
  lastRun?: string;
}

export interface AppNotification {
  id: string;
  targetIds: string[]; // List of IDs (Admin, specific Pro ID, specific Syndic ID)
  buildingId: string;
  buildingAddress: string;
  interventionId?: string;
  title: string;
  type: 'CREATED' | 'UPDATED' | 'STATUS_CHANGE' | 'MISSION_DECISION' | 'MAINTENANCE_AUTO' | 'EMAIL_INGESTION' | 'EMAIL_INGESTION_ERROR';
  timestamp: string;
  read: boolean;
}

// --- EMAIL AUTOMATION TYPES ---

export interface IncomingEmail {
  messageId: string;
  from: string;
  subject: string;
  body: string;
  receivedAt: string;
  attachments?: {
    filename: string;
    mimeType: string;
    content?: string; // Simulated text content for PDF parsing
    url: string;
  }[];
}

export interface ExtractionField<T> {
  value: T;
  confidence: 'HIGH' | 'MEDIUM' | 'LOW';
  source: 'EMAIL_BODY' | 'PDF_ATTACHMENT' | 'SIGNATURE' | 'UNKNOWN';
  evidence?: string;
}

export interface EmailIngestionLog {
  id: string;
  messageId: string;
  receivedAt: string;
  from: string;
  subject: string;
  status: 'PROCESSED' | 'IGNORED' | 'ERROR' | 'NEEDS_REVIEW';
  reason?: string;
  createdMissionId?: string; // Changed from createdInterventionId
  extractedJson?: {
    address?: string | { raw?: string; street?: string; number?: string; city?: string;[key: string]: any };
    title?: string;
    sector?: Sector;
    description?: string;
    requestedDate?: string;
    reference?: string;
    contactOnSite?: {
      name?: string | ExtractionField<string>;
      phone?: string | ExtractionField<string>;
      email?: string | ExtractionField<string>;
      alternatives?: any[];
    };
    syndic?: string;
  };
  createdAt: string;
}