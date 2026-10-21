import React, { useState, useEffect } from 'react';
import { Users, MapPin, Phone, Mail, Clock, RotateCcw, ExternalLink } from 'lucide-react';
import { dataService } from '@/services/dataService';
import { TRANSLATIONS } from '@/utils/constants';
import { Language } from '@/types';

interface TeamMember {
    id: number;
    name: string;
    email: string;
    phone: string | null;
    role: string;
    latitude: number | null;
    longitude: number | null;
    location_updated_at: string | null;
}

const REFRESH_INTERVAL_MS = 60_000;

const TeamPage: React.FC<{ lang: Language }> = ({ lang }) => {
    const t = TRANSLATIONS[lang];
    const [members, setMembers] = useState<TeamMember[]>([]);
    const [isLoading, setIsLoading] = useState(true);

    const fetchTeam = async () => {
        try {
            const data = await dataService.getTeam();
            setMembers(data);
        } catch (error) {
            console.error('Failed to fetch team:', error);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        fetchTeam();
        // Keep positions fresh while the page is open
        const timer = setInterval(fetchTeam, REFRESH_INTERVAL_MS);
        return () => clearInterval(timer);
    }, []);

    const openInGoogleMaps = (m: TeamMember) => {
        window.open(`https://www.google.com/maps/search/?api=1&query=${m.latitude},${m.longitude}`, '_blank');
    };

    return (
        <div className="space-y-6 animate-in fade-in duration-500 max-w-6xl mx-auto pb-12 px-4 md:px-0">
            <div className="flex justify-between items-start md:items-center gap-4">
                <div>
                    <h2 className="text-2xl font-black text-white uppercase tracking-tight flex items-center gap-2">
                        <Users className="text-brand-green" /> {t.team_menu || 'Team'}
                    </h2>
                    <p className="text-zinc-500 text-sm font-medium">{t.team_subtitle || 'Last known location of each team member'}</p>
                </div>
                <button
                    onClick={() => { setIsLoading(true); fetchTeam(); }}
                    className="p-2.5 bg-zinc-900 border border-zinc-800 rounded-xl text-zinc-400 hover:text-brand-green hover:border-brand-green/50 transition-all"
                >
                    <RotateCcw size={18} className={isLoading ? 'animate-spin' : ''} />
                </button>
            </div>

            {isLoading && members.length === 0 ? (
                <div className="flex items-center justify-center p-20">
                    <div className="w-8 h-8 border-4 border-brand-green border-t-transparent rounded-full animate-spin"></div>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {members.map(m => {
                        const hasLocation = m.latitude !== null && m.longitude !== null;
                        return (
                            <div key={m.id} className="bg-zinc-950 border border-zinc-800 rounded-2xl overflow-hidden flex flex-col hover:border-brand-green/30 transition-all">
                                <div className="p-5 space-y-2">
                                    <div className="flex items-center justify-between gap-2">
                                        <h4 className="font-bold text-white truncate text-lg">{m.name}</h4>
                                        <span className="px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider bg-brand-green/10 text-brand-green border border-brand-green/20 shrink-0">{m.role}</span>
                                    </div>
                                    {m.phone && (
                                        <a href={`tel:${m.phone}`} className="flex items-center gap-1.5 text-xs text-zinc-400 hover:text-brand-green"><Phone size={12} /> {m.phone}</a>
                                    )}
                                    <div className="flex items-center gap-1.5 text-xs text-zinc-500 truncate"><Mail size={12} /> {m.email}</div>
                                </div>

                                {hasLocation ? (
                                    <button
                                        onClick={() => openInGoogleMaps(m)}
                                        className="relative h-44 w-full block group"
                                        title="Google Maps"
                                    >
                                        <iframe
                                            width="100%"
                                            height="100%"
                                            frameBorder="0"
                                            style={{ border: 0 }}
                                            className="pointer-events-none"
                                            src={`https://maps.google.com/maps?q=${m.latitude},${m.longitude}&t=&z=15&ie=UTF8&iwloc=&output=embed`}
                                        ></iframe>
                                        <span className="absolute bottom-3 right-3 px-2.5 py-1.5 bg-zinc-950/80 border border-zinc-800 rounded-lg text-zinc-300 group-hover:text-brand-green group-hover:border-brand-green/50 text-[10px] font-black uppercase tracking-widest flex items-center gap-1.5 backdrop-blur-md">
                                            <ExternalLink size={12} /> Google Maps
                                        </span>
                                    </button>
                                ) : (
                                    <div className="h-44 flex flex-col items-center justify-center gap-2 bg-zinc-900/50 text-zinc-600 text-xs font-bold">
                                        <MapPin size={20} />
                                        {t.team_no_location || 'No location shared yet'}
                                    </div>
                                )}

                                {m.location_updated_at && (
                                    <div className="px-5 py-3 border-t border-zinc-900 flex items-center gap-1.5 text-[11px] text-zinc-500">
                                        <Clock size={12} /> {t.team_last_seen || 'Last seen'}: {new Date(m.location_updated_at).toLocaleString()}
                                    </div>
                                )}
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
};

export default TeamPage;
