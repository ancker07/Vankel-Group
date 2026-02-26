import React, { useState, useEffect, useMemo, useRef } from 'react';
import { Routes, Route, Navigate, useNavigate, useLocation } from 'react-router-dom';
import HomePage from '@/features/home/pages/HomePage';
import Header from '@/components/layout/Header';
import Sidebar from '@/components/layout/Sidebar/Sidebar';
import BottomNav from '@/components/layout/BottomNav';
import SyndicDashboard from '@/features/dashboard/pages/SyndicDashboard';
import AdminDashboard from '@/features/dashboard/pages/AdminDashboard';
import SyndicNotificationsPage from '@/features/dashboard/pages/SyndicNotificationsPage';


import GestionPage from '@/features/management/pages/ManagementPage';
import OngoingInterventions from '@/features/dashboard/components/OngoingInterventions';
import MissionsPage from '@/features/missions/pages/MissionsPage';
import MaintenancePage from '@/features/maintenance/pages/MaintenancePage';
import ReportsPage from '@/features/reports/pages/ReportsPage';
import EmailIngestionPage from '@/features/dashboard/pages/EmailIngestionPage';
import SuperAdminDashboard from '@/features/dashboard/pages/SuperAdminDashboard';
import SuperAdminLogin from '@/features/auth/pages/SuperAdminLogin';
import LoginPage from '@/features/auth/pages/LoginPage';
import SignupForm from '@/features/auth/components/SignupForm';
import ProfilePage from '@/features/auth/pages/ProfilePage';

import BuildingProfile from '@/features/buildings/pages/BuildingProfile';
import InterventionSlip from '@/features/interventions/components/InterventionSlip';
import CreateInterventionModal from '@/features/interventions/components/CreateInterventionModal';
import CreateMaintenanceModal from '@/features/maintenance/components/CreateMaintenanceModal';
import PendingApprovalPage from '@/features/auth/pages/PendingApprovalPage';

import DashboardListModal from '@/features/dashboard/components/DashboardListModal';
import MissionActionModal from '@/features/missions/components/MissionActionModal';
import ConfirmationModal from '@/components/common/ConfirmationModal';
import ToastContainer from '@/components/common/ToastContainer';
import OnboardingTour from '@/features/dashboard/components/OnboardingTour';
import { dataService } from '@/services/dataService';
import { authService } from '@/features/auth/services/authService';

import {
  mockSyndics,
  mockProfessionals
} from '@/utils/mockData';
import {
  Role,
  Language,
  Building,
  Intervention,
  Mission,
  Syndic,
  Professional,
  AppNotification,
  EmailIngestionLog,
  MaintenancePlan,
  SignupRequest,
  AdminUser,
  Urgency,
  InterventionStatus,
  Sector
} from '@/types';


import { TRANSLATIONS } from '@/utils/constants';
import { runEmailIngestion } from '@/features/dashboard/services/emailIngestion';


const App: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();

  // Global State
  const [role, setRole] = useState<Role | null>(() => {
    const savedRole = localStorage.getItem('vanakel_role');
    if (savedRole) return savedRole as Role;
    return null;
  });
  const [lang, setLang] = useState<Language>('FR');
  const [userName, setUserName] = useState<string>(() => localStorage.getItem('vanakel_userName') || 'Vanakel User');
  const [isApproved, setIsApproved] = useState<boolean>(() => {
    const saved = localStorage.getItem('vanakel_isApproved');
    return saved === 'true';
  });
  const [fullUserData, setFullUserData] = useState<any>(null);

  useEffect(() => {
    const fetchProfile = async () => {
      const email = localStorage.getItem('vanakel_userEmail');
      if (email && (role === 'ADMIN' || role === 'SYNDIC')) {
        try {
          const response = await authService.getProfile(email);
          if (response.success) {
            setFullUserData(response.user);
          }
        } catch (error) {
          console.error("Error fetching profile:", error);
        }
      }
    };

    fetchProfile();
  }, [role]);


  // Data State
  const [buildings, setBuildings] = useState<Building[]>([]);
  const [interventions, setInterventions] = useState<Intervention[]>([]);
  const [missions, setMissions] = useState<Mission[]>([]);
  const [maintenancePlans, setMaintenancePlans] = useState<MaintenancePlan[]>([]);
  const [syndics, setSyndics] = useState<Syndic[]>([]);
  const [professionals, setProfessionals] = useState<Professional[]>([]);
  const [signupRequests, setSignupRequests] = useState<SignupRequest[]>([]);
  const [admins, setAdmins] = useState<AdminUser[]>([]);

  // Feature State
  const [notifications, setNotifications] = useState<AppNotification[]>([]);
  const [emailLogs, setEmailLogs] = useState<EmailIngestionLog[]>([]);
  const [processedEmailIds, setProcessedEmailIds] = useState<string[]>(() => {
    try {
      return JSON.parse(localStorage.getItem('vanakel_processed_emails') || '[]');
    } catch { return []; }
  });

  const [showNotifications, setShowNotifications] = useState(false);
  const [toastMessages, setToastMessages] = useState<{ id: string, title: string, message: string }[]>([]);
  const [isIngesting, setIsIngesting] = useState(false);
  const lastErrorRef = useRef<{ hash: string, time: number } | null>(null);

  // Selection & Selection Modals
  const [selectedBuildingId, setSelectedBuildingId] = useState<string | null>(null);
  const [selectedInterventionId, setSelectedInterventionId] = useState<string | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showCreateMaintenanceModal, setShowCreateMaintenanceModal] = useState(false);
  const [preSelectedBuildingForMaintenance, setPreSelectedBuildingForMaintenance] = useState<string | undefined>(undefined);
  const [deletePlanId, setDeletePlanId] = useState<string | null>(null);
  const [profileInitialTab, setProfileInitialTab] = useState<'data' | 'history' | 'notes' | 'plan' | 'docs' | 'entretien'>('data');
  const [missionActionModal, setMissionActionModal] = useState<{ type: 'APPROVE' | 'REJECT'; mission: Mission } | null>(null);
  const [missionDate, setMissionDate] = useState('');
  const [listModal, setListModal] = useState<{ isOpen: boolean; title: string; items: (Intervention | Mission)[] }>({ isOpen: false, title: '', items: [] });
  const [isTourActive, setIsTourActive] = useState(false);
  const [showCompare, setShowCompare] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [apiBuildings, apiMissions, apiInterventions, apiSyndics, apiPendingUsers] = await Promise.all([
          dataService.getBuildings(),
          dataService.getMissions(),
          dataService.getInterventions(),
          dataService.getSyndics(),
          dataService.getPendingUsers()
        ]);

        if (apiBuildings) {
          const mappedBuildings: Building[] = apiBuildings.map((b: any) => ({
            id: String(b.id),
            address: b.address,
            city: b.city || 'Unknown',
            tenants: b.tenants || [],
            phone: b.phone || '',
            linkedProfessionalId: b.linked_professional_id || '',
            linkedSyndicId: String(b.syndic_id || ''),
            adminNote: b.admin_note || '',
            imageUrl: b.image_url || 'https://images.unsplash.com/photo-1460317442991-0ec2aa5a1199?q=80&w=600',
            installationDate: b.created_at,
            devices: b.devices || []
          }));
          setBuildings(mappedBuildings);
        }

        if (apiMissions) {
          const mappedMissions: Mission[] = apiMissions.map((m: any) => ({
            id: String(m.id),
            buildingId: String(m.building_id),
            requestedBy: m.requested_by,
            title: m.title,
            category: m.category,
            sector: m.sector as Sector,
            description: m.description,
            status: m.status,
            timestamp: m.created_at,
            urgency: m.urgency as Urgency,
            onSiteContactName: m.on_site_contact_name,
            onSiteContactPhone: m.on_site_contact_phone,
            onSiteContactEmail: m.on_site_contact_email,
            syndicId: String(m.syndic_id || ''),
            documents: (m.documents || []).map((d: any) => ({
              id: String(d.id),
              name: d.file_name,
              type: 'OTHER',
              status: 'APPROVED',
              url: `http://localhost:8000/storage/${d.file_path}`,
              timestamp: d.created_at
            }))
          }));
          setMissions(mappedMissions);
        }

        if (apiInterventions) {
          const mappedInterventions: Intervention[] = apiInterventions.map((i: any) => ({
            id: String(i.id),
            buildingId: String(i.building_id),
            title: i.title,
            category: i.category,
            sector: i.sector as Sector,
            description: i.description,
            scheduledDate: i.scheduled_date || i.created_at,
            createdAt: i.created_at,
            status: i.status as InterventionStatus,
            notes: i.notes || [],
            photos: i.photos || [],
            documents: (i.documents || []).map((d: any) => ({
              id: String(d.id),
              name: d.file_name,
              type: 'OTHER',
              status: 'APPROVED',
              url: `http://localhost:8000/storage/${d.file_path}`,
              timestamp: d.created_at
            })),
            proId: String(i.professional_id || ''),
            urgency: i.urgency as Urgency,
            onSiteContactName: i.on_site_contact_name,
            onSiteContactPhone: i.on_site_contact_phone,
            onSiteContactEmail: i.on_site_contact_email,
            sourceType: i.source_type || 'MANUAL'
          }));
          setInterventions(mappedInterventions);
        }

        if (apiSyndics) {
          const mappedSyndics: Syndic[] = apiSyndics.map((s: any) => ({
            id: String(s.id),
            companyName: s.company_name,
            contactPerson: s.contact_person,
            phone: s.phone,
            email: s.email,
            landline: s.landline || '',
            address: s.address || ''
          }));
          setSyndics(mappedSyndics);
        }

        if (apiPendingUsers) {
          const mappedUsers: SignupRequest[] = apiPendingUsers.map((u: any) => ({
            id: String(u.id),
            role: u.role,
            firstName: u.name.split(' ')[0] || '',
            lastName: u.name.split(' ').slice(1).join(' ') || '',
            email: u.email,
            phone: u.phone || '',
            companyName: u.company_name || '',
            timestamp: u.created_at,
            status: u.status
          }));
          setSignupRequests(mappedUsers);
        }

      } catch (error) {
        console.error("Failed to fetch dynamic data:", error);
      }
    };

    fetchData();
  }, []);





  useEffect(() => {
    localStorage.setItem('vanakel_processed_emails', JSON.stringify(processedEmailIds));
  }, [processedEmailIds]);

  useEffect(() => {
    localStorage.setItem('vanakel_signup_requests', JSON.stringify(signupRequests));
  }, [signupRequests]);

  useEffect(() => {
    localStorage.setItem('vanakel_admins', JSON.stringify(admins));
  }, [admins]);

  // --- Derived Data & Maintenance Occurrences Logic ---
  const t = TRANSLATIONS[lang];

  const getUpcomingOccurrences = (plan: MaintenancePlan): Intervention[] => {
    const occurrences: Intervention[] = [];
    const now = new Date();
    const startDate = new Date(plan.recurrence.startDate);
    const endDate = new Date(plan.recurrence.endDate);
    let currentDate = startDate;

    while (currentDate <= endDate) {
      const scheduledTime = currentDate.getTime();
      const visibleFromTime = scheduledTime - (7 * 24 * 60 * 60 * 1000);
      const nowTime = now.getTime();

      if (nowTime >= visibleFromTime && nowTime <= (scheduledTime + (24 * 60 * 60 * 1000))) {
        occurrences.push({
          id: `occ-${plan.id}-${scheduledTime}`,
          buildingId: plan.buildingId,
          title: plan.title,
          category: 'General',
          sector: 'GENERAL',
          description: plan.description || 'Maintenance recurrent',
          scheduledDate: currentDate.toISOString(),
          status: 'PENDING',
          notes: [],
          photos: [],
          documents: [],
          proId: '',
          sourceType: 'MAINTENANCE_PLAN',
          maintenancePlanId: plan.id,
          isMaintenanceOccurrence: true
        });
      }

      if (plan.recurrence.frequency === 'YEARLY') {
        currentDate = new Date(currentDate.setFullYear(currentDate.getFullYear() + 1));
      } else if (plan.recurrence.frequency === 'MONTHLY') {
        currentDate = new Date(currentDate.setMonth(currentDate.getMonth() + 1));
      } else if (plan.recurrence.frequency === 'QUARTERLY') {
        currentDate = new Date(currentDate.setMonth(currentDate.getMonth() + 3));
      } else { break; }
    }
    return occurrences;
  };

  const allInterventions = useMemo(() => {
    const occurrences = maintenancePlans.filter(p => p.status === 'ACTIVE').flatMap(getUpcomingOccurrences);
    return [...interventions, ...occurrences];
  }, [interventions, maintenancePlans]);

  const stats = useMemo(() => ({
    missions: missions.filter(m => m.status === 'PENDING').length,
    ongoing: allInterventions.filter(i => i.status === 'PENDING').length,
    delayed: allInterventions.filter(i => i.status === 'DELAYED').length,
    completed: allInterventions.filter(i => i.status === 'COMPLETED').length
  }), [missions, allInterventions]);

  const chartData = useMemo(() => {
    const months = 6;
    const data = [];
    const now = new Date();
    for (let i = months - 1; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthLabel = d.toLocaleString(lang === 'FR' ? 'fr-FR' : lang === 'NL' ? 'nl-NL' : 'en-US', { month: 'short' });
      const count = interventions.filter(int => {
        const intDate = new Date(int.createdAt || int.scheduledDate);
        return intDate.getMonth() === d.getMonth() && intDate.getFullYear() === d.getFullYear();
      }).length;
      data.push({ name: monthLabel, value: count, comparison: Math.floor(Math.random() * 5) + 2 });
    }
    return data;
  }, [interventions, lang]);

  const handleLogout = () => {
    setRole(null);
    localStorage.removeItem('vanakel_role');
    localStorage.removeItem('vanakel_userName');
    localStorage.removeItem('vanakel_isApproved');
    navigate('/');
  };

  const handleProfileUpdate = async (formData: FormData) => {
    try {
      const response = await authService.updateProfile(formData);
      if (response.success) {
        const newName = formData.get('name') as string;
        if (newName) {
          setUserName(newName);
          localStorage.setItem('vanakel_userName', newName);
        }
        addToast("Profile Updated", response.message || "Your profile has been saved successfully.");
      } else {
        addToast("Update Failed", response.message || "Could not update your profile.");
      }
    } catch (error) {
      addToast("Error", "An unexpected error occurred while updating your profile.");
    }
  };


  // --- Handlers ---
  const addToast = (title: string, message: string) => {
    const id = Date.now().toString();
    setToastMessages(prev => [...prev, { id, title, message }]);
  };

  const handleEmailIngestion = async () => {
    setIsIngesting(true);
    try {
      const result = await runEmailIngestion(buildings, interventions, missions, processedEmailIds, lang);
      setBuildings(prev => [...prev, ...result.newBuildings]);
      setMissions(prev => [...prev, ...result.newMissions]);
      setEmailLogs(prev => [...prev, ...result.logs]);
      setProcessedEmailIds(prev => [...prev, ...result.logs.filter(l => l.status === 'PROCESSED' || l.status === 'NEEDS_REVIEW' || l.status === 'IGNORED').map(l => l.messageId)]);

      const errorLogs = result.logs.filter(l => l.status === 'ERROR');
      if (errorLogs.length > 0) {
        errorLogs.forEach(err => {
          const hash = `${err.from}-${err.subject}-${err.reason}`;
          const now = Date.now();
          if (!lastErrorRef.current || lastErrorRef.current.hash !== hash || (now - lastErrorRef.current.time > 60000)) {
            setNotifications(prev => [{
              id: `err-notif-${now}`, targetIds: ['ADMIN'], buildingId: '', buildingAddress: 'System',
              title: 'Erreur de lecture email', type: 'EMAIL_INGESTION_ERROR', timestamp: new Date().toISOString(), read: false
            }, ...prev]);
            lastErrorRef.current = { hash, time: now };
          }
        });
      }

      if (result.newMissions.length > 0) {
        addToast(t.email_ingestion_mission, `${result.newMissions.length} new mission(s) created from emails.`);
        setNotifications(prev => [{
          id: Date.now().toString(), targetIds: ['ADMIN'], buildingId: '', buildingAddress: 'New Locations',
          title: 'New Missions via Email', type: 'EMAIL_INGESTION', timestamp: new Date().toISOString(), read: false
        }, ...prev]);
      } else {
        addToast("Ingestion Complete", "No new relevant missions found.");
      }
    } catch (e) {
      addToast("Error", "Critical ingestion failure.");
    } finally { setIsIngesting(false); }
  };

  const handleSignupSubmit = (request: SignupRequest) => {
    setSignupRequests(prev => [...prev, request]);

    const name = `${request.firstName} ${request.lastName}`;
    setRole(request.role);
    localStorage.setItem('vanakel_role', request.role);
    setUserName(name);
    localStorage.setItem('vanakel_userName', name);
    localStorage.setItem('vanakel_userEmail', request.email);

    // Set initial approval status - SYNDIC is auto-approved
    const isSyndic = request.role === 'SYNDIC';
    setIsApproved(isSyndic);
    localStorage.setItem('vanakel_isApproved', isSyndic ? 'true' : 'false');

    setIsTourActive(true);
    addToast(t.signup, t.signupSuccess);

    if (isSyndic) {
      navigate('/syndic/dashboard');
    } else {
      navigate('/pending-approval');
    }
  };



  const handleApproveRequest = async (request: SignupRequest) => {
    try {
      await dataService.approveUser(request.id);

      if (request.role === 'ADMIN') {
        setAdmins(prev => [...prev, {
          id: request.id, firstName: request.firstName, lastName: request.lastName,
          email: request.email, phone: request.phone, createdAt: new Date().toISOString()
        }]);
      } else {
        setSyndics(prev => [...prev, {
          id: request.id, companyName: request.companyName || `${request.firstName} ${request.lastName}`,
          contactPerson: `${request.firstName} ${request.lastName}`, email: request.email, phone: request.phone,
          address: '', landline: ''
        }]);
      }
      setSignupRequests(prev => prev.filter(r => r.id !== request.id));
      addToast(t.approve, t.createAdminSuccess || 'User approved successfully.');
    } catch (error) {
      console.error('Failed to approve user', error);
      addToast('Error', 'Failed to approve user.');
    }
  };

  const handleRejectRequest = async (requestId: string) => {
    try {
      await dataService.rejectUser(requestId);
      setSignupRequests(prev => prev.filter(r => r.id !== requestId));
      addToast('Success', 'User rejected.');
    } catch (error) {
      console.error('Failed to reject user', error);
      addToast('Error', 'Failed to reject user.');
    }
  };

  const handleCreateAdmin = (adminData: Omit<AdminUser, 'id' | 'createdAt'>) => {
    setAdmins(prev => [...prev, { ...adminData, id: `admin-${Date.now()}`, createdAt: new Date().toISOString() }]);
    addToast(t.createAdmin, t.createAdminSuccess);
  };

  const handleInterventionUpdate = async (updated: Intervention) => {
    try {
      await dataService.updateIntervention(updated.id, {
        status: updated.status,
        pro_id: updated.proId,
        scheduled_date: updated.scheduledDate,
        admin_feedback: updated.adminFeedback,
        on_site_contact_name: updated.onSiteContactName,
        on_site_contact_phone: updated.onSiteContactPhone,
        on_site_contact_email: updated.onSiteContactEmail,
        delay_reason: updated.delayReason,
        delay_details: updated.delayDetails,
        delayed_reschedule_date: updated.delayedRescheduleDate,
        completed_at: updated.completedAt
      });
      setInterventions(prev => prev.map(i => i.id === updated.id ? updated : i));
    } catch (error) {
      console.error('Failed to update intervention:', error);
      addToast('Error', 'Failed to update intervention on server. Action aborted.');
    }
  };

  const handleCreateIntervention = async (payload: any) => {
    try {
      const formData = new FormData();
      formData.append('title', payload.title);
      formData.append('description', payload.description);
      formData.append('addressFull', payload.addressFull);
      formData.append('urgency', payload.urgency);
      formData.append('role', role || 'SYNDIC');
      formData.append('syndicId', payload.syndicId || '');
      formData.append('status', payload.status || 'PENDING');
      formData.append('sector', payload.sector || 'GENERAL');
      formData.append('onSiteContactName', payload.onSiteContactName || '');
      formData.append('onSiteContactPhone', payload.onSiteContactPhone || '');
      formData.append('onSiteContactEmail', payload.onSiteContactEmail || '');

      if (payload.files && payload.files.length > 0) {
        payload.files.forEach((f: File) => {
          formData.append('files[]', f);
        });
      }

      const result = await dataService.createIntervention(formData);
      const serverData = result.data;

      if (result.type === 'mission') {
        const newMission: Mission = {
          id: String(serverData.id),
          buildingId: String(serverData.building_id),
          requestedBy: serverData.requested_by,
          title: serverData.title,
          category: serverData.category,
          sector: serverData.sector,
          description: serverData.description,
          status: serverData.status as any,
          timestamp: serverData.created_at,
          urgency: serverData.urgency as Urgency,
          onSiteContactName: serverData.on_site_contact_name,
          onSiteContactPhone: serverData.on_site_contact_phone,
          onSiteContactEmail: serverData.on_site_contact_email,
          documents: (serverData.documents || []).map((d: any) => ({
            id: String(d.id),
            name: d.file_name,
            type: 'OTHER',
            status: 'APPROVED',
            url: `http://localhost:8000/storage/${d.file_path}`,
            timestamp: d.created_at
          }))
        };
        setMissions(prev => [newMission, ...prev]);
        addToast(t.mission_approved, newMission.title || 'Mission requested');
      } else {
        const newInt: Intervention = {
          id: String(serverData.id),
          buildingId: String(serverData.building_id),
          title: serverData.title,
          category: serverData.category,
          sector: serverData.sector,
          description: serverData.description,
          scheduledDate: serverData.scheduled_date || new Date().toISOString(),
          createdAt: serverData.created_at,
          status: serverData.status as InterventionStatus,
          notes: [],
          photos: [],
          documents: (serverData.documents || []).map((d: any) => ({
            id: String(d.id),
            name: d.file_name,
            type: 'OTHER',
            status: 'PENDING',
            url: `http://localhost:8000/storage/${d.file_path}`,
            timestamp: d.created_at
          })),
          proId: '',
          urgency: serverData.urgency as Urgency,
          onSiteContactName: serverData.on_site_contact_name,
          onSiteContactPhone: serverData.on_site_contact_phone,
          onSiteContactEmail: serverData.on_site_contact_email,
          sourceType: 'MANUAL'
        };
        setInterventions(prev => [newInt, ...prev]);
        addToast(t.manual_intervention_created, newInt.title);
      }

      // Re-fetch data to sync auto-created buildings
      const apiBuildings = await dataService.getBuildings();
      if (apiBuildings && apiBuildings.length > 0) setBuildings(apiBuildings);

      setShowCreateModal(false);
    } catch (error) {
      console.error('Backend failed:', error);
      addToast("Error", "Action failed. Please try again later.");
      setShowCreateModal(false);
    }
  };






  const handleCreateMaintenance = (plan: Omit<MaintenancePlan, 'id' | 'createdAt' | 'status'>) => {
    setMaintenancePlans(prev => [...prev, { id: `mp-${Date.now()}`, createdAt: new Date().toISOString(), status: 'ACTIVE', ...plan }]);
    addToast(t.maintenance || 'Maintenance', 'Plan recurrent créé.');
  };

  const handleDeleteMaintenance = () => {
    if (deletePlanId) {
      setMaintenancePlans(prev => prev.filter(p => p.id !== deletePlanId));
      setDeletePlanId(null);
      addToast(t.maintenance || 'Maintenance', 'Plan supprimé.');
    }
  };

  const handleApproveMission = async (mission: Mission, scheduledDate?: string) => {
    try {
      const response = await dataService.approveMission(mission.id, scheduledDate);
      const serverIntervention = response.intervention;

      const newInt: Intervention = {
        id: String(serverIntervention.id),
        buildingId: String(serverIntervention.building_id),
        title: serverIntervention.title,
        category: serverIntervention.category,
        sector: serverIntervention.sector as Sector,
        description: serverIntervention.description,
        scheduledDate: serverIntervention.scheduled_date || new Date().toISOString(),
        createdAt: serverIntervention.created_at,
        status: serverIntervention.status as InterventionStatus,
        notes: [],
        photos: [],
        documents: (serverIntervention.documents || []).map((d: any) => ({
          id: String(d.id),
          name: d.file_name,
          type: 'OTHER',
          status: 'APPROVED',
          url: `http://localhost:8000/storage/${d.file_path}`,
          timestamp: d.created_at
        })),
        proId: '',
        urgency: serverIntervention.urgency as Urgency,
        onSiteContactName: serverIntervention.on_site_contact_name,
        onSiteContactPhone: serverIntervention.on_site_contact_phone,
        onSiteContactEmail: serverIntervention.on_site_contact_email,
        sourceType: 'MANUAL'
      };

      setInterventions(prev => [newInt, ...prev]);
      setMissions(prev => prev.filter(m => m.id !== mission.id));
      addToast(t.mission_approved, mission.title || 'Mission approved');
    } catch (error) {
      console.error('Failed to approve mission:', error);
      addToast("Error", "Action failed. Please try again later.");
    }
  };

  const handleRejectMission = async (missionId: string) => {
    try {
      await dataService.rejectMission(missionId);
      setMissions(prev => prev.filter(m => m.id !== missionId));
      addToast(t.mission_rejected, 'Mission rejected');
    } catch (error) {
      console.error('Failed to reject mission:', error);
      addToast("Error", "Action failed. Please try again later.");
    }
  };

  const handleStatClick = (type: any) => {
    let title = '';
    let items: (Intervention | Mission)[] = [];
    if (type === 'MISSIONS') { title = t.kpi_missions; items = missions.filter(m => m.status === 'PENDING'); }
    else if (type === 'ONGOING') { title = t.ongoing; items = allInterventions.filter(i => i.status === 'PENDING'); }
    else if (type === 'DELAYED') { title = t.delayed; items = allInterventions.filter(i => i.status === 'DELAYED'); }
    else if (type === 'COMPLETED') { title = t.completed; items = allInterventions.filter(i => i.status === 'COMPLETED'); }
    setListModal({ isOpen: true, title, items });
  };

  const handleOpenMaintenance = (buildingId: string) => {
    setSelectedInterventionId(null);
    setPreSelectedBuildingForMaintenance(buildingId);
    setShowCreateMaintenanceModal(true);
  };



  // --- Render ---
  const selectedBuilding = selectedBuildingId ? buildings.find(b => b.id === selectedBuildingId) : null;
  const selectedIntervention = selectedInterventionId ? allInterventions.find(i => i.id === selectedInterventionId) : null;
  const selectedIntBuilding = selectedIntervention ? buildings.find(b => b.id === selectedIntervention.buildingId) : undefined;
  const selectedIntPro = selectedIntBuilding?.linkedProfessionalId ? professionals.find(p => p.id === selectedIntBuilding.linkedProfessionalId) : undefined;
  const selectedIntSyndic = selectedIntBuilding?.linkedSyndicId ? syndics.find(s => s.id === selectedIntBuilding.linkedSyndicId) : undefined;

  return (
    <>
      <Routes>
        {/* Public Routes */}
        <Route path="/" element={
          <HomePage
            onSelect={(r) => navigate(`/login/${r.toLowerCase()}`)}
            lang={lang}
            setLang={setLang}
            onSignup={(role) => navigate('/signup', { state: { role } })}
            onSuperAdminLogin={() => navigate('/superadmin/login')}
            role={role}
            isApproved={isApproved}
            userName={userName}
          />

        } />


        <Route path="/login/:roleLabel" element={
          <LoginPage
            role={location.pathname.includes('syndic') ? 'SYNDIC' : 'ADMIN'}
            lang={lang}
            onLogin={(name) => {
              const r = location.pathname.includes('syndic') ? 'SYNDIC' : 'ADMIN';
              setRole(r);
              localStorage.setItem('vanakel_role', r);
              setUserName(name || 'Vanakel User');
              localStorage.setItem('vanakel_userName', name || 'Vanakel User');
              setIsApproved(true);
              localStorage.setItem('vanakel_isApproved', 'true');
              setIsTourActive(true);
              navigate(r === 'SYNDIC' ? '/syndic/dashboard' : '/admin/dashboard');
            }}
            onSignup={() => {
              const r = location.pathname.includes('syndic') ? 'SYNDIC' : 'ADMIN';
              navigate('/signup', { state: { role: r } });
            }}
            onBack={() => navigate('/')}
          />
        } />

        <Route path="/signup" element={
          <SignupForm
            onSubmit={handleSignupSubmit}
            onBack={() => navigate('/')}
            lang={lang}
          />
        } />

        <Route path="/superadmin/login" element={
          <SuperAdminLogin
            onLogin={(name) => {
              setRole('SUPERADMIN');
              localStorage.setItem('vanakel_role', 'SUPERADMIN');
              setUserName(name || 'Super Admin');
              localStorage.setItem('vanakel_userName', name || 'Super Admin');
              setIsApproved(true);
              localStorage.setItem('vanakel_isApproved', 'true');
              setIsTourActive(true);
              navigate('/admin/super_admin');
            }}
            onBack={() => navigate('/')}
            lang={lang}
          />
        } />

        <Route path="/pending-approval" element={
          role && !isApproved ? (
            <PendingApprovalPage
              lang={lang}
              onLogout={handleLogout}
              onApproved={() => {
                localStorage.setItem('vanakel_isApproved', 'true');
                window.location.replace(role === 'SYNDIC' ? '/syndic/dashboard' : '/admin/dashboard');
              }}
            />
          ) : (
            <Navigate to="/" replace />
          )
        } />

        <Route path="/:rolePrefix/*" element={
          !role ? <Navigate to="/" replace /> : (
            !isApproved && role !== 'SUPERADMIN' ? <Navigate to="/pending-approval" replace /> : (
              <div className="flex h-screen bg-brand-black text-zinc-300 font-sans selection:bg-brand-green/30 overflow-hidden">
                <Sidebar
                  role={role}
                  stats={stats}
                  t={t}
                  isIngesting={isIngesting}
                  setIsTourActive={setIsTourActive}
                  setRole={handleLogout}
                />
                <div className="flex-1 flex flex-col h-full min-w-0 bg-brand-black">
                  <Header
                    role={role}
                    lang={lang}
                    setLang={setLang}
                    notifications={notifications}
                    setNotifications={setNotifications}
                    showNotifications={showNotifications}
                    setShowNotifications={setShowNotifications}
                    setSelectedInterventionId={setSelectedInterventionId}
                    t={t}
                    userName={userName}
                  />

                  <main className="flex-1 overflow-y-auto p-4 md:p-8 pb-24 md:pb-8 relative scroll-smooth">
                    <Routes>
                      <Route path="dashboard" element={
                        role === 'SYNDIC' ? (
                          <SyndicDashboard
                            stats={stats}
                            allInterventions={allInterventions}
                            chartData={chartData}
                            onCreateIntervention={() => setShowCreateModal(true)}
                            onSelectIntervention={setSelectedInterventionId}
                            onViewFullHistory={() => navigate('/syndic/management')}
                            lang={lang}
                            t={t}
                          />

                        ) : role === 'SUPERADMIN' ? (
                          <Navigate to="../super_admin" replace />
                        ) : (
                          <AdminDashboard
                            stats={stats}
                            chartData={chartData}
                            showCompare={showCompare}
                            setShowCompare={setShowCompare}
                            allInterventions={allInterventions}
                            onStatClick={handleStatClick}
                            onCreateIntervention={() => setShowCreateModal(true)}
                            onSelectIntervention={setSelectedInterventionId}
                            onViewFullHistory={() => navigate('/admin/reports')}
                            lang={lang}
                            t={t}
                          />
                        )
                      } />
                      <Route index element={<Navigate to="dashboard" replace />} />

                      <Route path="super_admin" element={role === 'SUPERADMIN' ? <SuperAdminDashboard requests={signupRequests} admins={admins} onApprove={handleApproveRequest} onReject={handleRejectRequest} onCreateAdmin={handleCreateAdmin} lang={lang} /> : <Navigate to="dashboard" replace />} />
                      <Route path="management" element={
                        role === 'SYNDIC' ? (
                          <ReportsPage interventions={allInterventions} buildings={buildings} professionals={professionals} syndics={syndics} onViewIntervention={setSelectedInterventionId} lang={lang} />
                        ) : (
                          <GestionPage buildings={buildings} interventions={interventions} syndics={syndics} professionals={professionals} lang={lang} />
                        )
                      } />
                      <Route path="reports" element={role !== 'SYNDIC' ? <ReportsPage interventions={allInterventions} buildings={buildings} professionals={professionals} syndics={syndics} onViewIntervention={setSelectedInterventionId} lang={lang} /> : <Navigate to="/syndic/management" replace />} />
                      <Route path="email_ingestion" element={role !== 'SYNDIC' ? <EmailIngestionPage isIngesting={isIngesting} onIngestClick={handleEmailIngestion} emailLogs={emailLogs} lang={lang} t={t} /> : <Navigate to="dashboard" replace />} />
                      <Route path="notifications" element={
                        <SyndicNotificationsPage
                          notifications={notifications}
                          onNotificationClick={(id, intId) => {
                            setNotifications(prev => prev.map(n => n.id === id ? { ...n, read: true } : n));
                            if (intId) setSelectedInterventionId(intId);
                          }}
                          lang={lang}
                          t={t}
                        />
                      } />


                      <Route path="ongoing" element={<OngoingInterventions interventions={allInterventions} buildings={buildings} syndics={syndics} onSelect={setSelectedInterventionId} t={t} lang={lang} />} />

                      <Route path="missions" element={
                        <MissionsPage
                          missions={missions}
                          buildings={buildings}
                          syndics={syndics}
                          onCreateClick={() => setShowCreateModal(true)}
                          onApprove={(m) => setMissionActionModal({ type: 'APPROVE', mission: m })}
                          onReject={(m) => setMissionActionModal({ type: 'REJECT', mission: m })}
                          t={t}
                          role={role || 'SYNDIC'}
                          lang={lang}
                        />

                      } />
                      <Route path="profile" element={<ProfilePage userName={userName} role={role || 'SYNDIC'} t={t} onLogout={handleLogout} onUpdateProfile={handleProfileUpdate} userData={fullUserData} />} />

                      <Route path="entretien_list" element={role !== 'SYNDIC' ? <MaintenancePage maintenancePlans={maintenancePlans} buildings={buildings} syndics={syndics} onCreateClick={(bid) => { setPreSelectedBuildingForMaintenance(bid); setShowCreateMaintenanceModal(true); }} onDeleteClick={setDeletePlanId} t={t} /> : <Navigate to="dashboard" replace />} />

                      <Route path="settings" element={<div className="flex flex-col items-center justify-center h-full text-zinc-600">Settings Module under construction</div>} />
                    </Routes>
                  </main>
                </div>
                <BottomNav role={role} stats={stats} t={t} />



                {/* Modals */}
                {selectedBuilding && (
                  <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
                    <div className="w-full max-w-5xl h-[90vh] overflow-y-auto rounded-3xl">
                      <BuildingProfile building={selectedBuilding} professionals={professionals} syndics={syndics} interventions={interventions.filter(i => i.buildingId === selectedBuildingId)} onClose={() => { setSelectedBuildingId(null); setProfileInitialTab('data'); }} lang={lang} onUpdateBuilding={() => { }} onAddIntervention={(i) => setInterventions(prev => [i, ...prev])} onUpdateIntervention={() => { }} onOpenIntervention={setSelectedInterventionId} initialTab={profileInitialTab} maintenancePlans={maintenancePlans.filter(p => p.buildingId === selectedBuildingId)} />
                    </div>
                  </div>
                )}
                {/* Intervention Slip Overlay */}
                {selectedInterventionId && selectedIntervention && (
                  <InterventionSlip
                    intervention={selectedIntervention}
                    building={buildings.find(b => b.id === selectedIntervention.buildingId)!}
                    professional={professionals.find(p => p.id === selectedIntervention.professionalId)}
                    syndic={selectedIntSyndic}
                    lang={lang}
                    onClose={() => setSelectedInterventionId(null)}
                    onUpdate={handleInterventionUpdate}
                    onOpenMaintenance={(bid) => { setPreSelectedBuildingForMaintenance(bid); setShowCreateMaintenanceModal(true); }}
                    role={role || 'SYNDIC'}
                  />
                )}
                {showCreateModal && <CreateInterventionModal isOpen={showCreateModal} onClose={() => setShowCreateModal(false)} onCreate={handleCreateIntervention} onSyndicCreate={(s) => setSyndics(prev => [...prev, s])} buildings={buildings} syndics={syndics} lang={lang} role={role || 'SYNDIC'} userName={userName} />}

                {showCreateMaintenanceModal && <CreateMaintenanceModal isOpen={showCreateMaintenanceModal} onClose={() => setShowCreateMaintenanceModal(false)} onCreate={handleCreateMaintenance} buildings={buildings} initialBuildingId={preSelectedBuildingForMaintenance} lang={lang} />}
                {listModal.isOpen && <DashboardListModal isOpen={listModal.isOpen} onClose={() => setListModal(prev => ({ ...prev, isOpen: false }))} title={listModal.title} items={listModal.items} buildings={buildings} syndics={syndics} onItemClick={(id, type) => { setListModal(prev => ({ ...prev, isOpen: false })); if (type === 'INTERVENTION') setSelectedInterventionId(id); }} lang={lang} />}
                {isTourActive && (
                  <OnboardingTour
                    isActive={isTourActive}
                    onClose={() => setIsTourActive(false)}
                    lang={lang}
                    currentTab={location.pathname.split('/').pop() || 'dashboard'}
                    onTabChange={(t) => {
                      const prefix = role === 'SYNDIC' ? 'syndic' : 'admin';
                      navigate(t === 'dashboard' ? `/${prefix}/dashboard` : `/${prefix}/${t}`);
                    }}
                  />
                )}


                {missionActionModal && (
                  <MissionActionModal type={missionActionModal.type} mission={missionActionModal.mission} missionDate={missionDate} setMissionDate={setMissionDate} onCancel={() => setMissionActionModal(null)} onConfirm={() => { if (missionActionModal.type === 'APPROVE') handleApproveMission(missionActionModal.mission, missionDate); else handleRejectMission(missionActionModal.mission.id); setMissionActionModal(null); setMissionDate(''); }} t={t} />
                )}
                {deletePlanId && (
                  <ConfirmationModal isOpen={!!deletePlanId} onClose={() => setDeletePlanId(null)} onConfirm={handleDeleteMaintenance} title={t.confirmDeleteTitle || 'Confirm Deletion'} message={t.confirmDeleteMaintMsg || 'Delete this maintenance plan?'} confirmLabel={t.btnDelete || 'Delete'} cancelLabel={t.btnCancel || 'Cancel'} />
                )}
              </div>
            )
          )
        } />


        {/* Catch all */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes >
      <ToastContainer toasts={toastMessages} onRemove={(id) => setToastMessages(prev => prev.filter(t => t.id !== id))} />
    </>
  );
};

export default App;