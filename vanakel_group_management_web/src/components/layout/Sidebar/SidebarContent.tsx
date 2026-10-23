import React from 'react';
import { Building2, LayoutDashboard, ShieldCheck, Clock, ClipboardList, RotateCcw, FileText, Mail, Settings, User, Sparkles, MessageSquare, Bell, Users, KeyRound } from 'lucide-react';
import SidebarItem from './SidebarItem';
import { Role } from '@/types';
import { usePermissions } from '@/lib/permissions';

interface SidebarContentProps {
    role: Role | null;
    stats: {
        ongoing: number;
        delayed: number;
        missions: number;
    };
    t: any;
    isIngesting: boolean;
    activeTab: string;
    handleTabClick: (tab: string) => void;
}

const SidebarContent: React.FC<SidebarContentProps> = ({
    role,
    stats,
    t,
    isIngesting,
    activeTab,
    handleTabClick
}) => {
    const can = usePermissions();
    return (
        <nav className="flex-1 px-4 space-y-2 overflow-y-auto">
            {/* Navigation Items */}
            {role === 'SYNDIC' ? (
                <>
                    <div id="nav-dashboard">
                        <SidebarItem icon={<LayoutDashboard size={20} />} label={t.dashboard} active={activeTab === 'dashboard'} onClick={() => handleTabClick('dashboard')} />
                    </div>
                        <>
                            <div id="nav-missions">
                                <SidebarItem icon={<ClipboardList size={20} />} label={t.missions} active={activeTab === 'missions'} onClick={() => handleTabClick('missions')} badge={stats.missions} />
                            </div>
                            <div id="nav-ongoing">
                                <SidebarItem icon={<Clock size={20} />} label={t.interventions || 'Interventions'} active={activeTab === 'ongoing'} onClick={() => handleTabClick('ongoing')} badge={stats.ongoing} />
                            </div>
                            <div id="nav-management">
                                <SidebarItem icon={<FileText size={20} />} label={t.management || 'History & Documents'} active={activeTab === 'management'} onClick={() => handleTabClick('management')} />
                            </div>
                            <SidebarItem
                                icon={<MessageSquare size={20} className="text-pink-400" />}
                                label={t.contact_us || "Contact Us"}
                                active={activeTab === 'contact_us'}
                                onClick={() => handleTabClick('contact_us')}
                            />
                            <div id="nav-notifications">
                                <SidebarItem icon={<Settings size={20} />} label={t.notifications || 'Notifications'} active={activeTab === 'notifications'} onClick={() => handleTabClick('notifications')} />
                            </div>
                            <div id="nav-profile">
                                <SidebarItem icon={<User size={20} />} label={t.profile || 'Profil'} active={activeTab === 'profile'} onClick={() => handleTabClick('profile')} />
                            </div>
                        </>
                </>
            ) : (
                // Staff menu: built from the role's permissions, so custom roles see exactly what they may use
                <>
                    {role === 'SUPERADMIN' ? (
                        <div id="nav-super-admin">
                            <SidebarItem icon={<ShieldCheck size={20} className="text-brand-green" />} label={t.superAdmin} active={activeTab === 'super_admin'} onClick={() => handleTabClick('super_admin')} />
                        </div>
                    ) : (
                        <div id="nav-dashboard">
                            <SidebarItem icon={<LayoutDashboard size={20} />} label={t.dashboard} active={activeTab === 'dashboard'} onClick={() => handleTabClick('dashboard')} />
                        </div>
                    )}

                    <div className={role === 'SUPERADMIN' ? 'pt-6 mt-6 border-t border-zinc-800 space-y-2' : 'space-y-2'}>
                        {role === 'SUPERADMIN' && (
                            <p className="px-4 mb-2 text-[10px] font-black uppercase text-zinc-600 tracking-widest">{t.sidebar_system_tools}</p>
                        )}
                        {can('emails.manage') && (
                            <SidebarItem icon={<Mail size={20} className={isIngesting ? "animate-pulse text-brand-green" : ""} />} label={t.ingestion_menu} active={activeTab === 'email_ingestion'} onClick={() => handleTabClick('email_ingestion')} />
                        )}
                        {can('buildings.view') && (
                            <div id="nav-management">
                                <SidebarItem icon={<Building2 size={20} className="text-cyan-400" />} label={t.management || 'Management'} active={activeTab === 'management'} onClick={() => handleTabClick('management')} />
                            </div>
                        )}
                        {can('interventions.view') && (
                            <div id="nav-ongoing">
                                <SidebarItem icon={<Clock size={20} className="text-brand-green" />} label={t.ongoing || 'Interventions'} active={activeTab === 'ongoing'} onClick={() => handleTabClick('ongoing')} badge={stats.ongoing} />
                            </div>
                        )}
                        {can('missions.view') && (
                            <div id="nav-missions">
                                <SidebarItem icon={<ClipboardList size={20} className="text-orange-400" />} label={t.missions || 'Missions'} active={activeTab === 'missions'} onClick={() => handleTabClick('missions')} badge={stats.missions} />
                            </div>
                        )}
                        {can('maintenance.view') && (
                            <SidebarItem icon={<RotateCcw size={20} className="text-orange-500" />} label={t.maintenance || 'Maintenance'} active={activeTab === 'entretien_list'} onClick={() => handleTabClick('entretien_list')} />
                        )}
                        {can('reports.view') && (
                            <div id="nav-reports">
                                <SidebarItem icon={<FileText size={20} className="text-yellow-400" />} label={t.reports || 'Reports'} active={activeTab === 'reports'} onClick={() => handleTabClick('reports')} />
                            </div>
                        )}
                        {can('emails.view') && (
                            <SidebarItem icon={<Mail size={20} className="text-blue-400" />} label={t.inbox_title} active={activeTab === 'emails'} onClick={() => handleTabClick('emails')} />
                        )}
                        {can('settings.ai') && (
                            <SidebarItem icon={<Sparkles size={20} className="text-purple-400" />} label={t.superadmin_ai_settings} active={activeTab === 'ai-settings'} onClick={() => handleTabClick('ai-settings')} />
                        )}
                        {can('notifications.broadcast') && (
                            <SidebarItem icon={<Bell size={20} className="text-brand-green" />} label={t.push_notifications_title} active={activeTab === 'push-notifications'} onClick={() => handleTabClick('push-notifications')} />
                        )}
                        {can('contacts.view') && (
                            <SidebarItem icon={<MessageSquare size={20} className="text-pink-400" />} label={t.contacts || "Contacts"} active={activeTab === 'contacts'} onClick={() => handleTabClick('contacts')} />
                        )}
                        {can('team.view') && (
                            <SidebarItem icon={<Users size={20} className="text-emerald-400" />} label={t.team_menu || 'Team'} active={activeTab === 'team'} onClick={() => handleTabClick('team')} />
                        )}
                        {can('users.view', 'roles.manage') && (
                            <SidebarItem icon={<KeyRound size={20} className="text-amber-400" />} label={t.access_title || 'Users & roles'} active={activeTab === 'access'} onClick={() => handleTabClick('access')} />
                        )}
                        {role === 'SUPERADMIN' && (
                            <div id="header-settings">
                                <SidebarItem icon={<Settings size={20} />} label={t.settings} active={activeTab === 'settings'} onClick={() => handleTabClick('settings')} />
                            </div>
                        )}
                    </div>
                </>
            )}
        </nav>
    );
};

export default SidebarContent;
