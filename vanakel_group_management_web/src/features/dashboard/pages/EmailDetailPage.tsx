
import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Mail, Calendar, ArrowLeft, Paperclip, Download, Clock, Trash2 } from 'lucide-react';
import { Email, Language } from '@/types';
import { dataService } from '@/services/dataService';
import { STORAGE_BASE_URL } from '@/lib/apiClient';
import ConfirmationModal from '@/components/common/ConfirmationModal';

interface EmailDetailPageProps {
    lang: Language;
}

const EmailDetailPage: React.FC<EmailDetailPageProps> = ({ lang }) => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const [email, setEmail] = useState<Email | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [showDeleteModal, setShowDeleteModal] = useState(false);
    const [isDeleting, setIsDeleting] = useState(false);

    useEffect(() => {
        const fetchEmail = async () => {
            if (!id) return;
            setIsLoading(true);
            try {
                const data = await dataService.getEmailById(parseInt(id));
                setEmail(data);
            } catch (error) {
                console.error("Error fetching email details:", error);
            } finally {
                setIsLoading(false);
            }
        };

        fetchEmail();
    }, [id]);

    const handleBack = () => {
        navigate(-1);
    };

    const handleDelete = async () => {
        if (!id) return;
        setIsDeleting(true);
        try {
            await dataService.deleteEmail(parseInt(id));
            const pathParts = window.location.pathname.split('/');
            const prefix = pathParts[1] || 'admin';
            navigate(`/${prefix}/emails`, { replace: true });
        } catch (error) {
            console.error("Error deleting email:", error);
            setIsDeleting(false);
        }
    };

    if (isLoading) {
        return (
            <div className="flex flex-col items-center justify-center h-full space-y-4">
                <div className="w-12 h-12 border-4 border-brand-green/20 border-t-brand-green rounded-full animate-spin"></div>
                <p className="text-zinc-500 font-medium">Loading email details...</p>
            </div>
        );
    }

    if (!email) {
        return (
            <div className="flex flex-col items-center justify-center h-full space-y-4 text-center">
                <div className="w-20 h-20 bg-zinc-900 rounded-3xl flex items-center justify-center border border-zinc-800 mb-2">
                    <Mail size={40} className="text-zinc-700" />
                </div>
                <h2 className="text-2xl font-black text-white">Email Not Found</h2>
                <p className="text-zinc-500 max-w-xs">We couldn't find the email you're looking for. It might have been deleted or the ID is incorrect.</p>
                <button
                    onClick={handleBack}
                    className="mt-4 px-6 py-2.5 bg-brand-green text-black font-bold rounded-xl hover:bg-white transition-colors flex items-center gap-2"
                >
                    <ArrowLeft size={18} />
                    Go Back
                </button>
            </div>
        );
    }

    return (
        <div className="flex flex-col h-full animate-in fade-in slide-in-from-bottom-4 duration-500 max-w-5xl mx-auto space-y-6 pb-12">
            {/* Header / Actions */}
            <div className="flex items-center justify-between">
                <button
                    onClick={handleBack}
                    className="flex items-center gap-2 text-zinc-500 hover:text-white transition-colors group"
                >
                    <div className="w-8 h-8 rounded-lg bg-zinc-900 border border-zinc-800 flex items-center justify-center group-hover:border-zinc-700 transition-all">
                        <ArrowLeft size={16} />
                    </div>
                    <span className="text-sm font-bold">Back to Inbox</span>
                </button>

                <div className="flex items-center gap-3">
                    <button
                        onClick={() => setShowDeleteModal(true)}
                        className="flex items-center gap-2 px-4 py-2 bg-red-500/10 text-red-500 border border-red-500/20 rounded-xl font-bold text-xs uppercase tracking-widest hover:bg-red-500 hover:text-white transition-all active:scale-95 shadow-lg shadow-red-500/5 group"
                    >
                        <Trash2 size={16} className="group-hover:animate-pulse" />
                        Delete Email
                    </button>
                    <div className="px-3 py-1 bg-zinc-900 border border-zinc-800 rounded-full text-[10px] font-black uppercase tracking-widest text-zinc-500">
                        {email.is_read ? 'Read' : 'New Email'}
                    </div>
                </div>
            </div>

            {/* Email Main Card */}
            <div className="bg-zinc-950 rounded-3xl border border-zinc-800 overflow-hidden shadow-2xl">
                {/* Subject Area */}
                <div className="p-8 border-b border-zinc-900 bg-zinc-900/20">
                    <h1 className="text-3xl font-black text-white leading-tight">
                        {email.subject || '(No Subject)'}
                    </h1>

                    <div className="flex flex-wrap items-center gap-6 mt-6">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-full bg-brand-green/10 border border-brand-green/20 flex items-center justify-center text-brand-green font-black shadow-inner">
                                {email.from_name ? email.from_name.charAt(0).toUpperCase() : '?'}
                            </div>
                            <div>
                                <p className="text-sm font-bold text-white">{email.from_name || 'Unknown Sender'}</p>
                                <p className="text-xs text-zinc-500 font-medium">{email.from_address}</p>
                            </div>
                        </div>

                        <div className="h-4 w-px bg-zinc-800 hidden md:block"></div>

                        <div className="flex items-center gap-2 text-zinc-500">
                            <Calendar size={14} />
                            <span className="text-xs font-medium">
                                {new Date(email.received_at).toLocaleDateString(undefined, {
                                    weekday: 'long',
                                    year: 'numeric',
                                    month: 'long',
                                    day: 'numeric'
                                })}
                            </span>
                        </div>

                        <div className="flex items-center gap-2 text-zinc-500">
                            <Clock size={14} />
                            <span className="text-xs font-medium">
                                {new Date(email.received_at).toLocaleTimeString(undefined, {
                                    hour: '2-digit',
                                    minute: '2-digit'
                                })}
                            </span>
                        </div>
                    </div>
                </div>

                {/* Content Area */}
                <div className="p-8">
                    <div className="flex flex-col space-y-8">
                        {/* Body Text / HTML */}
                        <div className="bg-zinc-900/30 rounded-2xl border border-zinc-800/50 p-6 min-h-[300px] overflow-x-auto">
                            {email.body_html ? (
                                <div
                                    className="email-content text-zinc-300 text-sm leading-relaxed"
                                    dangerouslySetInnerHTML={{ __html: email.body_html }}
                                />
                            ) : (
                                <pre className="text-zinc-300 text-sm leading-relaxed whitespace-pre-wrap font-sans">
                                    {email.body_text || 'This email has no content.'}
                                </pre>
                            )}
                        </div>

                        {/* Attachments Section */}
                        {email.attachments && email.attachments.length > 0 && (
                            <div className="space-y-4">
                                <div className="flex items-center gap-2 text-zinc-400">
                                    <Paperclip size={18} />
                                    <h3 className="text-sm font-black uppercase tracking-widest">
                                        Attachments ({email.attachments.length})
                                    </h3>
                                </div>
                                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                                    {email.attachments.map(att => (
                                        <a
                                            key={att.id}
                                            href={`${STORAGE_BASE_URL}/${att.file_path}`}
                                            target="_blank"
                                            rel="noopener noreferrer"
                                            className="flex items-center gap-4 p-4 bg-zinc-900 border border-zinc-800 rounded-2xl hover:border-brand-green/50 hover:bg-zinc-800/50 transition-all group shadow-sm hover:shadow-brand-green/5"
                                        >
                                            <div className="w-10 h-10 rounded-xl bg-zinc-950 border border-zinc-800 flex items-center justify-center text-zinc-600 group-hover:text-brand-green transition-colors">
                                                <Paperclip size={20} />
                                            </div>
                                            <div className="flex-1 overflow-hidden">
                                                <p className="text-xs font-bold text-zinc-300 truncate group-hover:text-white transition-colors">
                                                    {att.file_name}
                                                </p>
                                                <p className="text-[10px] text-zinc-500 mt-0.5">
                                                    {att.file_size ? (att.file_size / 1024).toFixed(1) + ' KB' : 'Unknown size'}
                                                </p>
                                            </div>
                                            <div className="w-8 h-8 rounded-lg bg-zinc-950/50 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all text-zinc-500 hover:text-white">
                                                <Download size={16} />
                                            </div>
                                        </a>
                                    ))}
                                </div>
                            </div>
                        )}
                    </div>
                </div>

                {/* Footer Metadata */}
                <div className="px-8 py-4 bg-zinc-950/80 border-t border-zinc-900 flex justify-between items-center">
                    <span className="text-[9px] font-black uppercase tracking-tighter text-zinc-700 font-mono">
                        MESSAGE_ID: {email.message_id}
                    </span>
                    <div className="flex items-center gap-4">
                        <span className="text-[9px] font-black uppercase text-zinc-600">
                            VANKEL GROUP MANAGEMENT SYSTEM
                        </span>
                    </div>
                </div>
            </div>

            <ConfirmationModal
                isOpen={showDeleteModal}
                onClose={() => setShowDeleteModal(false)}
                onConfirm={handleDelete}
                title="Delete Email"
                message="Are you sure you want to delete this email? This action will permanently remove it from the system and the mail server."
                confirmLabel={isDeleting ? "Deleting..." : "Yes, Delete"}
                cancelLabel="Cancel"
                isDanger={true}
            />
        </div>
    );
};

export default EmailDetailPage;
