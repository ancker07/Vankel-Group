
import { Language } from '@/types';

export interface OnboardingStep {
  id: string;
  title: Record<Language, string>;
  description: Record<Language, string>;
  targetId?: string; // DOM ID to highlight
  requiredTab?: string; // 'dashboard', 'management', etc.
  placement?: 'top' | 'bottom' | 'left' | 'right' | 'center';
  mobileTargetId?: string; // Optional separate ID for mobile elements
}

export const ONBOARDING_STEPS: OnboardingStep[] = [
  {
    id: 'welcome',
    title: {
      EN: 'Welcome to Vanakel Group',
      FR: 'Bienvenue sur Vanakel Group',
      NL: 'Welkom bij Vanakel Group'
    },
    description: {
      EN: 'This platform helps you manage buildings, interventions, and missions efficiently. Let\'s take a quick tour.',
      FR: 'Cette plateforme vous aide à gérer efficacement bâtiments, interventions et missions. Faisons un tour rapide.',
      NL: 'Dit platform helpt u gebouwen, interventies en missies efficiënt te beheren. Laten we een snelle rondleiding nemen.'
    },
    placement: 'center'
  },
  {
    id: 'dashboard',
    title: {
      EN: 'Dashboard & Overview',
      FR: 'Tableau de Bord',
      NL: 'Dashboard & Overzicht'
    },
    description: {
      EN: 'Your central hub. View key statistics, urgent tasks, and quick actions.',
      FR: 'Votre hub central. Visualisez les statistiques clés, les tâches urgentes et les actions rapides.',
      NL: 'Uw centrale hub. Bekijk belangrijke statistieken, dringende taken en snelle acties.'
    },
    targetId: 'nav-dashboard',
    mobileTargetId: 'mobile-nav-dashboard',
    requiredTab: 'dashboard',
    placement: 'right'
  },
  {
    id: 'stats',
    title: {
      EN: 'Key Indicators',
      FR: 'Indicateurs Clés',
      NL: 'Kernindicatoren'
    },
    description: {
      EN: 'Track ongoing interventions, pending missions, and completed tasks at a glance.',
      FR: 'Suivez les interventions en cours, les missions en attente et les tâches terminées en un coup d\'œil.',
      NL: 'Volg lopende interventies, openstaande missies en voltooide taken in één oogopslag.'
    },
    targetId: 'dash-stats',
    requiredTab: 'dashboard',
    placement: 'bottom'
  },
  {
    id: 'management',
    title: {
      EN: 'Building Management',
      FR: 'Gestion Immobilière',
      NL: 'Gebouwenbeheer'
    },
    description: {
      EN: 'Access your full portfolio. Manage buildings, syndics, professionals, and tenants.',
      FR: 'Accédez à tout votre portefeuille. Gérez bâtiments, syndics, professionnels et locataires.',
      NL: 'Toegang tot uw volledige portefeuille. Beheer gebouwen, syndici, professionals en huurders.'
    },
    targetId: 'nav-management',
    mobileTargetId: 'mobile-nav-management',
    requiredTab: 'management',
    placement: 'right'
  },
  {
    id: 'ongoing',
    title: {
      EN: 'Ongoing Interventions',
      FR: 'Interventions en Cours',
      NL: 'Lopende Interventies'
    },
    description: {
      EN: 'Track active tickets. View status updates, delays, and technician feedback.',
      FR: 'Suivez les tickets actifs. Voir les statuts, retards et retours des techniciens.',
      NL: 'Volg actieve tickets. Bekijk statusupdates, vertragingen en feedback van technici.'
    },
    targetId: 'nav-ongoing',
    mobileTargetId: 'mobile-nav-ongoing',
    requiredTab: 'ongoing',
    placement: 'right'
  },
  {
    id: 'missions',
    title: {
      EN: 'Missions & Quotes',
      FR: 'Missions & Devis',
      NL: 'Missies & Offertes'
    },
    description: {
      EN: 'Approve or reject missions requested by syndics or clients. Plan execution dates.',
      FR: 'Approuvez ou rejetez les missions demandées par les syndics ou clients. Planifiez les dates d\'exécution.',
      NL: 'Keur missies aangevraagd door syndici of klanten goed of af. Plan uitvoeringsdata.'
    },
    targetId: 'nav-missions',
    mobileTargetId: 'mobile-nav-missions',
    requiredTab: 'missions',
    placement: 'right'
  },
  {
    id: 'reports',
    title: {
      EN: 'Reports & History',
      FR: 'Rapports & Historique',
      NL: 'Rapporten & Geschiedenis'
    },
    description: {
      EN: 'View consolidated history and generate PDF reports for interventions.',
      FR: 'Consultez l\'historique consolidé et générez des rapports PDF pour les interventions.',
      NL: 'Bekijk geconsolideerde geschiedenis en genereer PDF-rapporten voor interventies.'
    },
    targetId: 'nav-reports',
    mobileTargetId: 'mobile-nav-reports',
    requiredTab: 'reports',
    placement: 'right'
  },
  {
    id: 'settings',
    title: {
      EN: 'Settings & Notifications',
      FR: 'Paramètres & Notifications',
      NL: 'Instellingen & Meldingen'
    },
    description: {
      EN: 'Switch languages, manage your account, and view latest system notifications.',
      FR: 'Changez de langue, gérez votre compte et consultez les dernières notifications système.',
      NL: 'Wissel van taal, beheer uw account en bekijk de laatste systeemmeldingen.'
    },
    targetId: 'header-settings',
    requiredTab: 'dashboard',
    placement: 'bottom'
  },
  {
    id: 'help',
    title: {
      EN: 'Need Help?',
      FR: 'Besoin d\'aide ?',
      NL: 'Hulp Nodig?'
    },
    description: {
      EN: 'Click this button anytime to replay this tour or access support.',
      FR: 'Cliquez sur ce bouton à tout moment pour rejouer ce tour ou accéder au support.',
      NL: 'Klik op elk moment op deze knop om deze rondleiding opnieuw te spelen of toegang te krijgen tot ondersteuning.'
    },
    targetId: 'btn-help',
    placement: 'bottom'
  }
];
