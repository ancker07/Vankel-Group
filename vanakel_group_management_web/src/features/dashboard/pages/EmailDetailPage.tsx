
import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Mail, Calendar, ArrowLeft, Paperclip, Download, Clock, Trash2, Send, CheckCircle2, X } from 'lucide-react';
import { Email, Language } from '@/types';
import { dataService } from '@/services/dataService';
import { STORAGE_BASE_URL } from '@/lib/apiClient';
import ConfirmationModal from '@/components/common/ConfirmationModal';
import EmailReplyForm from '../components/EmailReplyForm';

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
    const [showReplyForm, setShowReplyForm] = useState(false);
    const [successMessage, setSuccessMessage] = useState<string | null>(null);
    const [thread, setThread] = useState<Email[]>([]);

    useEffect(() => {
        const fetchEmail = async () => {
            if (!id) return;
            setIsLoading(true);
            try {
                const data = await dataService.getEmailById(parseInt(id));
                setEmail(data);

                // If it's part of a thread, fetch the whole thread
                if (data.thread_id) {
                    const threadData = await dataService.getEmailThread(data.thread_id);
                    setThread(threadData.emails || []);
                } else {
                    setThread([data]);
                }
            } catch (error) {
                console.error("Error fetching email details:", error);
            } finally {
                setIsLoading(false);
            }
        };

        fetchEmail();
    }, [id]);

    useEffect(() => {
        if (successMessage) {
            const timer = setTimeout(() => setSuccessMessage(null), 5000);
            return () => clearTimeout(timer);
        }
    }, [successMessage]);

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
        <div className="flex flex-col min-h-screen animate-in fade-in slide-in-from-bottom-4 duration-500 max-w-6xl mx-auto space-y-8 pb-20">
            {/* Success Message Banner */}
            {successMessage && (
                <div className="flex items-center gap-3 p-4 bg-brand-green/10 border border-brand-green/20 rounded-2xl text-brand-green text-sm animate-in slide-in-from-top-4 duration-300">
                    <CheckCircle2 size={18} />
                    <span className="font-bold">{successMessage}</span>
                </div>
            )}

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
                        onClick={() => setShowReplyForm(!showReplyForm)}
                        className={`flex items-center gap-2 px-4 py-2 rounded-xl font-bold text-xs uppercase tracking-widest transition-all active:scale-95 shadow-lg group ${showReplyForm
                            ? 'bg-zinc-800 text-white border border-zinc-700'
                            : 'bg-brand-green text-black border border-brand-green shadow-brand-green/10 hover:bg-white hover:border-white'
                            }`}
                    >
                        {showReplyForm ? <X size={16} /> : <Send size={16} className="group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />}
                        {showReplyForm ? 'Close Reply' : 'Reply Email'}
                    </button>

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

            {/* Reply Form Section */}
            {showReplyForm && (
                <div className="animate-in slide-in-from-top-4 duration-500 mb-4">
                    <EmailReplyForm
                        emailId={email.id}
                        onClose={() => setShowReplyForm(false)}
                        onSuccess={(msg) => setSuccessMessage(msg)}
                    />
                </div>
            )}

            {/* Conversation Thread */}
            <div className="space-y-6">
                {thread.map((msg, index) => {
                    const isLast = index === thread.length - 1;
                    return (
                        <div
                            key={msg.id}
                            id={`msg-${msg.id}`}
                            className={`bg-zinc-950 rounded-3xl border transition-all duration-500 ${isLast ? 'border-zinc-800 shadow-2xl' : 'border-zinc-900/50 opacity-70 hover:opacity-100 scale-[0.98] hover:scale-[1]'
                                } overflow-hidden`}
                        >
                            {/* Subject Area (Only for the first message or if subject changes significantly) */}
                            {index === 0 && (
                                <div className="p-8 border-b border-zinc-900 bg-zinc-900/20">
                                    <h1 className="text-3xl font-black text-white leading-tight">
                                        {msg.subject || '(No Subject)'}
                                    </h1>
                                </div>
                            )}

                            {/* Sender/Meta Area */}
                            <div className={`p-6 md:px-8 flex flex-wrap items-center justify-between gap-4 ${index !== 0 ? 'bg-zinc-900/10' : ''}`}>
                                <div className="flex items-center gap-3">
                                    <div className={`w-10 h-10 rounded-full flex items-center justify-center font-black shadow-inner border ${msg.from_address.includes('vanakelgroup.com')
                                        ? 'bg-brand-green/10 border-brand-green/20 text-brand-green'
                                        : 'bg-blue-500/10 border-blue-500/20 text-blue-400'
                                        }`}>
                                        {msg.from_name ? msg.from_name.charAt(0).toUpperCase() : '?'}
                                    </div>
                                    <div>
                                        <p className="text-sm font-bold text-white">{msg.from_name || 'Unknown Sender'}</p>
                                        <p className="text-xs text-zinc-500 font-medium">{msg.from_address}</p>
                                    </div>
                                </div>

                                <div className="flex items-center gap-6">
                                    <div className="flex items-center gap-2 text-zinc-500">
                                        <Calendar size={14} />
                                        <span className="text-xs font-medium">
                                            {new Date(msg.received_at).toLocaleDateString(undefined, {
                                                month: 'short',
                                                day: 'numeric',
                                                year: 'numeric'
                                            })}
                                        </span>
                                    </div>
                                    <div className="flex items-center gap-2 text-zinc-500">
                                        <Clock size={14} />
                                        <span className="text-xs font-medium">
                                            {new Date(msg.received_at).toLocaleTimeString(undefined, {
                                                hour: '2-digit',
                                                minute: '2-digit'
                                            })}
                                        </span>
                                    </div>
                                </div>
                            </div>

                            {/* Content Area */}
                            <div className="p-8">
                                <div className="flex flex-col space-y-6">
                                    <div className="text-zinc-300 text-sm leading-relaxed whitespace-pre-wrap font-sans">
                                        {msg.body_html ? (
                                            <div
                                                className="email-content"
                                                dangerouslySetInnerHTML={{ __html: msg.body_html }}
                                            />
                                        ) : (
                                            msg.body_text || 'This email has no content.'
                                        )}
                                    </div>

                                    {/* Attachments Section */}
                                    {msg.attachments && msg.attachments.length > 0 && (
                                        <div className="pt-4 border-t border-zinc-900/50">
                                            <div className="flex items-center gap-2 text-zinc-500 mb-3">
                                                <Paperclip size={14} />
                                                <span className="text-[10px] font-black uppercase tracking-widest">
                                                    Attachments ({msg.attachments.length})
                                                </span>
                                            </div>
                                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                                                {msg.attachments.map(att => (
                                                    <a
                                                        key={att.id}
                                                        href={`${STORAGE_BASE_URL}/${att.file_path}`}
                                                        target="_blank"
                                                        rel="noopener noreferrer"
                                                        className="flex items-center gap-3 p-3 bg-zinc-900 border border-zinc-800 rounded-xl hover:border-brand-green/30 hover:bg-zinc-800/50 transition-all group"
                                                    >
                                                        <Paperclip size={16} className="text-zinc-600 group-hover:text-brand-green" />
                                                        <div className="flex-1 overflow-hidden">
                                                            <p className="text-[10px] font-bold text-zinc-400 truncate group-hover:text-white">
                                                                {att.file_name}
                                                            </p>
                                                        </div>
                                                        <Download size={14} className="text-zinc-700 group-hover:text-white" />
                                                    </a>
                                                ))}
                                            </div>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </div>
                    );
                })}
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
