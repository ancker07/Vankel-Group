import React, { useState, useEffect } from 'react';
import { Mail, User, Calendar, MessageSquare, Trash2, Search, CheckCircle2, Clock, Briefcase } from 'lucide-react';
import { dataService } from '@/services/dataService';
import { TRANSLATIONS } from '@/utils/constants';
import { Language } from '@/types';

interface ContactSubmission {
    id: string;
    name: string;
    email: string;
    subject: string | null;
    message: string;
    status: 'PENDING' | 'PROCESSED' | 'ARCHIVED';
    created_at: string;
    mission_id?: string;
    mission?: any;
}

const ContactsPage: React.FC<{ lang: Language }> = ({ lang }) => {
    const t = TRANSLATIONS[lang];
    const [contacts, setContacts] = useState<ContactSubmission[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        const fetchContacts = async () => {
            try {
                setIsLoading(true);
                const data = await dataService.getContacts();
                setContacts(data);
            } catch (error) {
                console.error('Failed to fetch contacts:', error);
            } finally {
                setIsLoading(false);
            }
        };
        fetchContacts();
    }, []);

    const handleDelete = async (id: string) => {
        if (!window.confirm(t.confirm_delete_contact || 'Are you sure you want to delete this contact?')) return;
        try {
            await dataService.deleteContact(id);
            setContacts(prev => prev.filter(c => c.id !== id));
        } catch (error) {
            console.error('Failed to delete contact:', error);
        }
    };

    const filteredContacts = contacts.filter(c => 
        c.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        c.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (c.subject && c.subject.toLowerCase().includes(searchTerm.toLowerCase()))
    );

    return (
        <div className="space-y-6 animate-in fade-in duration-500 max-w-6xl mx-auto pb-12 px-4 md:px-0">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                <div>
                    <h2 className="text-2xl font-black text-white uppercase tracking-tight flex items-center gap-2">
                        <MessageSquare className="text-brand-green" /> {t.web_form_contacts_title || 'Web Form Contacts'}
                    </h2>
                    <p className="text-zinc-500 text-sm font-medium">{t.web_form_contacts_subtitle || 'Manage submissions from the public website'}</p>
                </div>

                <div className="relative w-full md:w-64">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-600" size={18} />
                    <input
                        type="text"
                        placeholder={t.search_contacts || 'Search contacts...'}
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="w-full bg-zinc-950 border border-zinc-800 rounded-xl pl-10 pr-4 py-2.5 text-sm text-white focus:border-brand-green outline-none transition-all"
                    />
                </div>
            </div>

            {isLoading ? (
                <div className="flex items-center justify-center p-20">
                    <div className="w-8 h-8 border-4 border-brand-green border-t-transparent rounded-full animate-spin"></div>
                </div>
            ) : filteredContacts.length === 0 ? (
                <div className="flex flex-col items-center justify-center p-20 bg-zinc-950 border border-zinc-900 rounded-3xl">
                    <MessageSquare size={48} className="text-zinc-800 mb-4" />
                    <p className="text-zinc-500 font-bold">{t.no_contacts_found || 'No contact submissions found.'}</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 gap-4">
                    {filteredContacts.map((contact) => (
                        <div key={contact.id} className="bg-zinc-950 border border-zinc-900 p-6 rounded-3xl hover:border-brand-green/30 transition-all group">
                            <div className="flex flex-col md:flex-row justify-between gap-6">
                                <div className="flex-1 space-y-4">
                                    <div className="flex items-center justify-between">
                                        <div className="flex items-center gap-3">
                                            <div className="w-10 h-10 bg-brand-green/10 rounded-xl flex items-center justify-center text-brand-green font-black">
                                                {contact.name[0]}
                                            </div>
                                            <div>
                                                <h4 className="font-bold text-white flex items-center gap-2">
                                                    {contact.name}
                                                    {contact.status === 'PENDING' && <span className="w-2 h-2 rounded-full bg-brand-green animate-pulse"></span>}
                                                </h4>
                                                <p className="text-xs text-zinc-500">{contact.email}</p>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-2 text-[10px] font-black uppercase text-zinc-600 tracking-widest bg-zinc-900 px-3 py-1 rounded-full">
                                            <Calendar size={12} /> {new Date(contact.created_at).toLocaleDateString()}
                                        </div>
                                    </div>

                                    <div>
                                        <p className="text-xs font-black uppercase text-brand-green mb-1 tracking-widest">{contact.subject}</p>
                                        <p className="text-sm text-zinc-400 leading-relaxed bg-zinc-900/50 p-4 rounded-2xl border border-zinc-900">
                                            {contact.message}
                                        </p>
                                    </div>
                                </div>

                                <div className="flex md:flex-col gap-2 shrink-0 md:border-l border-zinc-900 md:pl-6">
                                    {contact.mission_id ? (
                                        <a 
                                            href={`/superadmin/missions?id=${contact.mission_id}`}
                                            className="flex-1 md:flex-none py-3 px-6 bg-brand-green/20 text-brand-green rounded-xl font-bold text-xs uppercase tracking-widest hover:bg-brand-green hover:text-brand-black transition-all flex items-center justify-center gap-2 border border-brand-green/20"
                                        >
                                            <Briefcase size={16} /> {t.view_mission_btn || 'View Mission'}
                                        </a>
                                    ) : (
                                        <button className="flex-1 md:flex-none py-3 px-6 bg-zinc-900 text-zinc-400 rounded-xl font-bold text-xs uppercase tracking-widest hover:bg-brand-green/10 hover:text-brand-green transition-all flex items-center justify-center gap-2 border border-zinc-800">
                                            <CheckCircle2 size={16} /> {t.process_btn || 'Process'}
                                        </button>
                                    )}
                                    <button 
                                        onClick={() => handleDelete(contact.id)}
                                        className="flex-1 md:flex-none py-3 px-6 bg-zinc-900 text-zinc-400 rounded-xl font-bold text-xs uppercase tracking-widest hover:bg-red-500/10 hover:text-red-500 transition-all flex items-center justify-center gap-2 border border-zinc-800"
                                    >
                                        <Trash2 size={16} /> {t.btnDelete || 'Delete'}
                                    </button>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

export default ContactsPage;
