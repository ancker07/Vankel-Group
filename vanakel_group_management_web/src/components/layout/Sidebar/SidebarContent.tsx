import React from 'react';
import { Building2, LayoutDashboard, ShieldCheck, Clock, ClipboardList, RotateCcw, FileText, Mail, Settings, User, Sparkles, MessageSquare } from 'lucide-react';
import SidebarItem from './SidebarItem';
import { Role } from '@/types';

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
    return (
        <nav className="flex-1 px-4 space-y-2 overflow-y-auto">
            {/* Navigation Items */}
            {role === 'SUPERADMIN' ? (
                <>
                    <div id="nav-super-admin">
                        <SidebarItem
                            icon={<ShieldCheck size={20} className="text-brand-green" />}
                            label={t.superAdmin}
                            active={activeTab === 'super_admin'}
                            onClick={() => handleTabClick('super_admin')}
                        />
                    </div>

                    <div className="pt-6 mt-6 border-t border-zinc-800">
                        <p className="px-4 mb-2 text-[10px] font-black uppercase text-zinc-600 tracking-widest">System Tools</p>
                        <SidebarItem
                            icon={<Mail size={20} className={isIngesting ? "animate-pulse text-brand-green" : ""} />}
                            label="Email Ingestion"
                            active={activeTab === 'email_ingestion'}
                            onClick={() => handleTabClick('email_ingestion')}
                        />
                        <SidebarItem
                            icon={<Building2 size={20} className="text-cyan-400" />}
                            label={t.management || 'Management'}
                            active={activeTab === 'management'}
                            onClick={() => handleTabClick('management')}
                        />
                        <SidebarItem
                            icon={<Clock size={20} className="text-brand-green" />}
                            label={t.ongoing || 'Interventions'}
                            active={activeTab === 'ongoing'}
                            onClick={() => handleTabClick('ongoing')}
                        />
                        <SidebarItem
                            icon={<ClipboardList size={20} className="text-orange-400" />}
                            label={t.missions || 'Missions'}
                            active={activeTab === 'missions'}
                            onClick={() => handleTabClick('missions')}
                        />
                        <SidebarItem
                            icon={<RotateCcw size={20} className="text-orange-500" />}
                            label={t.maintenance || 'Maintenance'}
                            active={activeTab === 'entretien_list'}
                            onClick={() => handleTabClick('entretien_list')}
                        />
                        <SidebarItem
                            icon={<FileText size={20} className="text-yellow-400" />}
                            label={t.reports || 'Reports'}
                            active={activeTab === 'reports'}
                            onClick={() => handleTabClick('reports')}
                        />
                        <SidebarItem
                            icon={<Mail size={20} className="text-blue-400" />}
                            label="Inbox"
                            active={activeTab === 'emails'}
                            onClick={() => handleTabClick('emails')}
                        />
                        <SidebarItem
                            icon={<Sparkles size={20} className="text-purple-400" />}
                            label="AI Settings"
                            active={activeTab === 'ai-settings'}
                            onClick={() => handleTabClick('ai-settings')}
                        />
                         <SidebarItem
                            icon={<MessageSquare size={20} className="text-pink-400" />}
                            label={t.contacts || "Contacts"}
                            active={activeTab === 'contacts'}
                            onClick={() => handleTabClick('contacts')}
                        />
                        <div id="header-settings">
                            <SidebarItem icon={<Settings size={20} />} label={t.settings} active={activeTab === 'settings'} onClick={() => handleTabClick('settings')} />
                        </div>
                    </div>
                </>
            ) : (
                <>
                    <div id="nav-dashboard">
                        <SidebarItem icon={<LayoutDashboard size={20} />} label={t.dashboard} active={activeTab === 'dashboard'} onClick={() => handleTabClick('dashboard')} />
                    </div>

                    {role === 'SYNDIC' ? (
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
                    ) : (
                        <>
                            <div id="nav-management">
                                <SidebarItem icon={<Building2 size={20} />} label={t.management} active={activeTab === 'management'} onClick={() => handleTabClick('management')} />
                            </div>
                            <div id="nav-ongoing">
                                <SidebarItem icon={<Clock size={20} />} label={t.ongoing} active={activeTab === 'ongoing'} onClick={() => handleTabClick('ongoing')} badge={stats.ongoing} />
                            </div>
                            <div id="nav-missions">
                                <SidebarItem icon={<ClipboardList size={20} />} label={t.missions} active={activeTab === 'missions'} onClick={() => handleTabClick('missions')} badge={stats.missions} />
                            </div>
                            <SidebarItem
                                icon={<RotateCcw size={20} className="text-orange-500" />}
                                label={t.maintenance || 'Entretien'}
                                active={activeTab === 'entretien_list'}
                                onClick={() => handleTabClick('entretien_list')}
                            />
                            <div id="nav-reports">
                                <SidebarItem icon={<FileText size={20} />} label={t.reports} active={activeTab === 'reports'} onClick={() => handleTabClick('reports')} />
                            </div>
                            <SidebarItem
                                icon={<MessageSquare size={20} className="text-pink-400" />}
                                label={t.contacts || "Contacts"}
                                active={activeTab === 'contacts'}
                                onClick={() => handleTabClick('contacts')}
                            />
                        </>
                    )}
                </>
            )}
        </nav>
    );
};

export default SidebarContent;
