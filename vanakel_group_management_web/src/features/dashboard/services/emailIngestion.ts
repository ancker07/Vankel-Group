
import { IncomingEmail, EmailIngestionLog, Intervention, Mission, Building, Syndic, ExtractionField, Sector, Language } from '@/types';
import { mockEmails, mockSyndics, mockBuildings } from '@/utils/mockData';
import { TRANSLATIONS } from '@/utils/constants';
import { extractEmailData, EmailExtractionResult } from '@/services/gemini';

// --- Helper: Text Extraction ---

const normalizeAddress = (addr: string): string => {
  return addr.toLowerCase().replace(/[^\w\s]/g, '').replace(/\s+/g, ' ').trim();
};

const extractCity = (addr: string): string => {
  // Simple heuristic: looks for 4 digits followed by word (BE zip format)
  const match = addr.match(/\b\d{4}\b\s+(\w+)/);
  return match ? match[1] : 'Unknown';
};

const hasStreetNumber = (addr: string): boolean => {
  return /\d+/.test(addr);
};

// --- Main Service ---

export const runEmailIngestion = async (
  buildings: Building[],
  interventions: Intervention[],
  existingMissions: Mission[],
  processedIds: string[],
  lang: Language
): Promise<{ newBuildings: Building[], newMissions: Mission[], logs: EmailIngestionLog[] }> => {

  const logs: EmailIngestionLog[] = [];
  const newMissions: Mission[] = [];
  const newBuildings: Building[] = [];

  // --- DEDUPLICATION PREPARATION ---
  // Build a set of signatures from existing records to prevent duplicates
  // Signature format: "REF:<code>" or "CONTENT:<subject>|<from>"
  const existingSignatures = new Set<string>();

  const generateSignatures = (item: Intervention | Mission) => {
    const sigs = [];
    // Priority 1: Reference Number
    if (item.interventionNumber) {
      sigs.push(`REF:${item.interventionNumber.toLowerCase().trim()}`);
    }
    // Priority 2: Source Content (Subject + Sender) - only for email-sourced items to avoid manual false positives
    if (item.sourceDetails && item.sourceDetails.subject && item.sourceDetails.from) {
      sigs.push(`CONTENT:${item.sourceDetails.subject.toLowerCase().trim()}|${item.sourceDetails.from.toLowerCase().trim()}`);
    }
    return sigs;
  };

  [...interventions, ...existingMissions].forEach(item => {
    generateSignatures(item).forEach(sig => existingSignatures.add(sig));
  });

  // Filter unprocessed emails
  let emailsToProcess = mockEmails.filter(e => !processedIds.includes(e.messageId));

  // SIMULATION LOGIC: If all emails processed, process them all again to allow demo to work
  if (emailsToProcess.length === 0) {
    emailsToProcess = mockEmails.map(e => ({
      ...e,
      messageId: `${e.messageId}_${Date.now()}` // Unique ID for this run
    }));
  }

  for (const email of emailsToProcess) {
    let status: 'PROCESSED' | 'IGNORED' | 'ERROR' | 'NEEDS_REVIEW' = 'IGNORED';
    let reason = '';
    let missionId: string | undefined;
    let extractedData: any = {};

    try {
      const content = (email.subject + "\n" + email.body + "\n" + (email.attachments?.map(a => a.content).join("\n") || "")).trim();

      // PHASE 1: Pre-filter (Marketing / Spam Rules)
      const marketingRegex = /(promo|offre|newsletter|unsubscribe|marketing|soldes|black friday|deal|campaign|utm_)/i;
      const isMarketing = marketingRegex.test(email.from) || marketingRegex.test(email.subject);

      // Urgent Override for marketing filter
      const urgentRegex = /(urgence|fuite|panne|dringend|lek|urgent|leak|sinistre)/i;
      const isUrgent = urgentRegex.test(email.subject) || urgentRegex.test(email.body.substring(0, 200));

      if (isMarketing && !isUrgent) {
        status = 'IGNORED';
        reason = 'Marketing/Newsletter detected by pre-filter.';
      } else {

        // PHASE 2: Intent Detection (Keywords)
        const missionKeywords = [
          'urgence', 'fuite', 'panne', 'intervention', 'réparation', 'devis', 'sinistre', 'dégât des eaux', 'ascenseur', 'chauffage', 'électricité',
          'dringend', 'lek', 'storing', 'interventie', 'herstelling',
          'urgent', 'leak', 'repair', 'maintenance', 'inspection'
        ];
        const hasKeywords = missionKeywords.some(k => content.toLowerCase().includes(k.toLowerCase()));

        if (!hasKeywords) {
          status = 'IGNORED';
          reason = 'No intervention-related keywords found.';
        } else {

          // PHASE 3: AI Extraction
          const aiResult: EmailExtractionResult = await extractEmailData(content);

          // --- DEDUPLICATION CHECK ---
          const emailRefSig = aiResult.mission?.reference ? `REF:${aiResult.mission.reference.toLowerCase().trim()}` : null;
          const emailContentSig = `CONTENT:${email.subject.toLowerCase().trim()}|${email.from.toLowerCase().trim()}`;

          const isDuplicate = (emailRefSig && existingSignatures.has(emailRefSig)) ||
            existingSignatures.has(emailContentSig);

          if (isDuplicate) {
            status = 'IGNORED';
            reason = 'Duplicate: Intervention already exists (matched reference or content).';
            extractedData = aiResult.mission;
          } else if (aiResult.classification === 'NON_MISSION') {
            status = 'IGNORED';
            reason = aiResult.reasons.join(', ') || 'Classified as NON_MISSION by AI.';
          } else if (aiResult.classification === 'NEEDS_REVIEW') {
            status = 'NEEDS_REVIEW';
            reason = `Ambiguous: ${aiResult.reasons.join(', ')}`;
            extractedData = aiResult.mission;
          } else {
            // CLASSIFICATION IS MISSION
            const rawAddress = aiResult.mission?.address?.raw ||
              (aiResult.mission?.address?.street ? `${aiResult.mission.address.street} ${aiResult.mission.address.number || ''}, ${aiResult.mission.address.postalCode || ''} ${aiResult.mission.address.city || ''}` : '');

            if (!rawAddress || rawAddress.trim().length < 5) {
              status = 'NEEDS_REVIEW';
              reason = 'Mission detected but address is missing or too vague.';
              extractedData = aiResult.mission;
            } else {
              // Try matching or creating building
              let matchedBuilding = buildings.find(b => {
                if (content.toLowerCase().includes(b.address.toLowerCase())) return true;
                if (normalizeAddress(b.address) === normalizeAddress(rawAddress)) return true;
                return false;
              });

              let buildingCreated = false;
              if (!matchedBuilding && hasStreetNumber(rawAddress)) {
                // Avoid duplicate creation in same batch
                const alreadyCreated = newBuildings.find(nb => normalizeAddress(nb.address) === normalizeAddress(rawAddress));
                if (alreadyCreated) {
                  matchedBuilding = alreadyCreated;
                } else {
                  const newId = `b-auto-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
                  const city = extractCity(rawAddress);
                  const newBuilding: Building = {
                    id: newId,
                    address: rawAddress,
                    city: aiResult.mission?.address?.city || city,
                    tenants: [],
                    phone: aiResult.mission?.contactOnSite?.phone || '',
                    linkedProfessionalId: '',
                    linkedSyndicId: '',
                    adminNote: `Auto-created via Email Ingestion. Source: ${email.subject}`,
                    imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=600',
                    installationDate: new Date().toISOString(),
                    devices: []
                  };
                  newBuildings.push(newBuilding);
                  matchedBuilding = newBuilding;
                  buildingCreated = true;
                }
              }

              if (matchedBuilding) {
                status = 'PROCESSED';
                reason = buildingCreated ? 'New building entity created automatically.' : 'Linked to existing building.';

                missionId = `miss-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
                const newMission: Mission = {
                  id: missionId,
                  buildingId: matchedBuilding.id,
                  requestedBy: 'SYNDIC',
                  syndicId: matchedBuilding.linkedSyndicId,
                  title: aiResult.mission?.title || email.subject,
                  category: 'General',
                  sector: 'AUTRE',
                  description: aiResult.mission?.description || content,
                  status: 'PENDING',
                  timestamp: new Date().toISOString(),
                  sourceType: 'EMAIL',
                  sourceMessageId: email.messageId,
                  sourceDetails: {
                    from: email.from,
                    subject: email.subject,
                    receivedAt: email.receivedAt
                  },
                  onSiteContactName: aiResult.mission?.contactOnSite?.name || undefined,
                  onSiteContactPhone: aiResult.mission?.contactOnSite?.phone || undefined,
                  onSiteContactEmail: aiResult.mission?.contactOnSite?.email || undefined,
                  interventionNumber: aiResult.mission?.reference || undefined,
                };

                newMissions.push(newMission);
                extractedData = aiResult.mission;

                // Add to current batch dedupe set to prevent double creation in this loop
                if (newMission.interventionNumber) existingSignatures.add(`REF:${newMission.interventionNumber.toLowerCase().trim()}`);
                if (newMission.sourceDetails) existingSignatures.add(`CONTENT:${newMission.sourceDetails.subject.toLowerCase().trim()}|${newMission.sourceDetails.from.toLowerCase().trim()}`);

              } else {
                status = 'NEEDS_REVIEW';
                reason = 'Valid address found but could not match or create building (vague address?).';
                extractedData = aiResult.mission;
              }
            }
          }
        }
      }
    } catch (e) {
      status = 'ERROR';
      reason = (e as Error).message || "Unknown error";
    }

    logs.push({
      id: `log-${Date.now()}-${Math.random()}`,
      messageId: email.messageId,
      receivedAt: email.receivedAt,
      from: email.from,
      subject: email.subject,
      status,
      reason,
      createdMissionId: missionId,
      extractedJson: status === 'PROCESSED' || status === 'NEEDS_REVIEW' ? extractedData : undefined,
      createdAt: new Date().toISOString()
    });
  }

  return { newBuildings, newMissions, logs };
};
