
import { Building, Professional, Syndic, Intervention, Mission, IncomingEmail, MaintenancePlan } from '@/types';

export const mockProfessionals: Professional[] = [
  {
    id: 'pro-1',
    companyName: 'AG BXL Plumbing',
    contactPerson: 'Jean Dupont',
    phone: '+32 470 11 22 33',
    landline: '+32 2 555 12 34',
    email: 'contact@ag-bxl.be',
    address: 'Rue de la Loi 1, 1000 Bruxelles'
  },
  {
    id: 'pro-2',
    companyName: 'ElectroVanakel',
    contactPerson: 'Marc Peeters',
    phone: '+32 480 99 88 77',
    landline: '+32 3 444 55 66',
    email: 'service@electrovanakel.be',
    address: 'Frankrijklei 10, 2000 Antwerpen'
  }
];

export const mockSyndics: Syndic[] = [
  {
    id: 'syn-1',
    companyName: 'ImmoTrust Syndic',
    contactPerson: 'Sophie Martens',
    phone: '32470123456', // Clean for WhatsApp
    landline: '+32 2 111 22 33',
    email: 'sophie@immotrust.be',
    address: 'Place Stéphanie 5, 1050 Ixelles'
  }
];

export const mockBuildings: Building[] = [
  {
    id: 'b-1',
    address: 'Avenue Louise 123',
    city: 'Brussels',
    tenants: [{ firstName: 'Alice', lastName: 'Vander', email: 'alice.vander@email.com' }, { firstName: 'Bob', lastName: 'Smith' }],
    phone: '+32 490 55 44 33',
    linkedProfessionalId: 'pro-1',
    linkedSyndicId: 'syn-1',
    adminNote: 'Old boiler needs checkup every 6 months.',
    imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=600',
    installationDate: '2015-05-20',
    devices: [
      { id: 'd-1', name: 'Gas Boiler X500', type: 'Heating', installationDate: '2015-05-20' }
    ]
  },
  {
    id: 'b-2',
    address: 'Kouter 45',
    city: 'Ghent',
    tenants: [{ firstName: 'Jan', lastName: 'Janssens', email: 'jan.j@telenet.be' }],
    phone: '+32 491 22 33 44',
    linkedProfessionalId: 'pro-2',
    linkedSyndicId: 'syn-1',
    adminNote: 'Electrical panel upgraded in 2022.',
    imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?q=80&w=600',
    installationDate: '2020-10-10',
    devices: [
      { id: 'd-2', name: 'Schneider Panel 200', type: 'Electricity', installationDate: '2022-01-15' }
    ]
  }
];

export const mockInterventions: Intervention[] = [
  {
    id: 'int-1',
    buildingId: 'b-1',
    title: 'Boiler Maintenance',
    category: 'Heating',
    sector: 'CHAUFFAGE',
    description: 'Annual boiler inspection and filter replacement.',
    scheduledDate: '2024-03-25T10:00:00',
    status: 'PENDING',
    notes: [
      { id: 'n-1', author: 'System', authorRole: 'ADMIN', content: 'Initial setup for routine maintenance.', timestamp: new Date().toISOString(), isInternal: false }
    ],
    photos: [],
    documents: [],
    proId: 'pro-1'
  },
  {
    id: 'int-2',
    buildingId: 'b-1',
    title: 'Leak Repair - Kitchen',
    category: 'Plumbing',
    sector: 'PLOMBERIE',
    description: 'Fixed leaking pipe under the main sink. Replaced seals.',
    scheduledDate: '2024-01-15T14:30:00',
    status: 'COMPLETED',
    completedAt: '2024-01-15T16:00:00',
    notes: [],
    photos: [],
    documents: [
      { id: 'doc-1', name: 'Invoice #2024-001', type: 'INVOICE', status: 'APPROVED', url: 'http://example.com/invoice.pdf', timestamp: '2024-01-16T09:00:00' }
    ],
    proId: 'pro-1'
  },
  {
    id: 'int-3',
    buildingId: 'b-2',
    title: 'Emergency Lighting Test',
    category: 'Electricity',
    sector: 'ELECTRICITE',
    description: 'Tested all emergency exit lights. Battery replacement required on 2nd floor.',
    scheduledDate: '2024-02-10T11:00:00',
    status: 'COMPLETED',
    completedAt: '2024-02-10T12:30:00',
    notes: [],
    photos: [],
    documents: [
      { id: 'doc-2', name: 'Compliance Report', type: 'REPORT', status: 'APPROVED', url: 'http://example.com/report.pdf', timestamp: '2024-02-11T10:00:00' }
    ],
    proId: 'pro-2'
  },
  {
    id: 'int-4',
    buildingId: 'b-1',
    title: 'Roof Inspection',
    category: 'Roofing',
    sector: 'AUTRE',
    description: 'Check for leaks after heavy rain.',
    scheduledDate: new Date().toISOString(),
    status: 'DELAYED',
    delayReason: 'weather', // MIGRATED: Added delay reason for testing
    delayedAt: new Date().toISOString(),
    notes: [],
    photos: [],
    documents: [],
    proId: 'pro-1'
  },
  {
    id: 'int-5',
    buildingId: 'b-2',
    title: 'Intercom Repair',
    category: 'Electricity',
    sector: 'ELECTRICITE',
    description: 'Intercom not ringing for apartment 3.',
    scheduledDate: new Date().toISOString(),
    status: 'PENDING', // MIGRATED: ON_HOLD -> PENDING as per requirement
    notes: [],
    photos: [],
    documents: [],
    proId: 'pro-2'
  }
];

export const mockMissions: Mission[] = [
  {
    id: 'm-1',
    buildingId: 'b-2',
    requestedBy: 'SYNDIC',
    syndicId: 'syn-1',
    title: 'Basement Lighting',
    category: 'Electricity',
    sector: 'ELECTRICITE',
    description: 'Suggested upgrade for emergency lighting in basement due to flickering lights.',
    status: 'PENDING',
    timestamp: new Date().toISOString()
  }
];

export const mockMaintenancePlans: MaintenancePlan[] = [
  {
    id: 'mp-1',
    buildingId: 'b-1',
    title: 'Entretien Chaudière',
    description: 'Entretien annuel obligatoire gaz.',
    recurrence: {
      frequency: 'YEARLY',
      interval: 1,
      startDate: '2023-10-15T09:00:00.000Z',
      endDate: '2028-10-15T09:00:00.000Z'
    },
    createdAt: '2023-10-01T10:00:00.000Z',
    status: 'ACTIVE',
    syndicId: 'syn-1'
  }
];

// --- MOCK EMAILS FOR INGESTION TESTING ---
export const mockEmails: IncomingEmail[] = [
  {
    messageId: 'msg-001',
    from: 'sophie@immotrust.be',
    subject: 'Urgence: Fuite d\'eau',
    body: 'Bonjour, nous avons une fuite importante dans le hall d\'entrée au 123 Avenue Louise. Merci d\'intervenir rapidement.',
    receivedAt: new Date(Date.now() - 1000 * 60 * 10).toISOString(), // 10 mins ago
    attachments: []
  },
  {
    messageId: 'msg-002',
    from: 'jan.j@telenet.be',
    subject: 'Ordre de service #4451',
    body: 'Veuillez trouver ci-joint l\'ordre de service pour la réparation de la toiture.',
    receivedAt: new Date(Date.now() - 1000 * 60 * 60).toISOString(), // 1 hour ago
    attachments: [
      {
        filename: 'OS_Toiture.pdf',
        mimeType: 'application/pdf',
        url: '#',
        // SIMULATED OCR CONTENT
        content: `
          ORDRE DE SERVICE
          Référence : OS-2024-99
          Objet : Réparation fuite toiture plate forme
          Adresse : Rue de la Loi 155, 1000 Bruxelles
          Date : 20/03/2024
          
          Description:
          Infiltration constatée au 3ème étage. Merci de vérifier le roofing et les corniches.
          Contact sur place : M. Dubuc (0470 12 34 56)
        `
      }
    ]
  },
  {
    messageId: 'msg-003',
    from: 'spam@marketing.com',
    subject: 'Offre spéciale maintenance',
    body: 'Découvrez nos tarifs pour 2025!',
    receivedAt: new Date(Date.now() - 1000 * 60 * 120).toISOString(), // 2 hours ago
    attachments: []
  }
];