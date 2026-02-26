
import React, { useState, useRef } from 'react';
import { User, Mail, Phone, Shield, Building, Lock, LogOut, Edit2, Check, X, Camera } from 'lucide-react';
import UserAvatar from '@/components/common/UserAvatar';

interface ProfilePageProps {
    userName: string;
    role: string;
    t: any;
    onLogout: () => void;
    onUpdateProfile?: (data: FormData) => Promise<void>;
    userData?: any;
}

const ProfilePage: React.FC<ProfilePageProps> = ({ userName, role, t, onLogout, onUpdateProfile, userData }) => {
    const [isEditing, setIsEditing] = useState(false);
    const [name, setName] = useState(userName);
    const [email, setEmail] = useState(() => localStorage.getItem('vanakel_userEmail') || 'contact@vanakel.be');
    const [phone, setPhone] = useState('+32 400 00 00 00');
    const [bio, setBio] = useState('Syndic professionnel gérant plusieurs résidences à Bruxelles.');
    const [imageFile, setImageFile] = useState<File | null>(null);
    const [imagePreview, setImagePreview] = useState<string | null>(null);
    const [isSaving, setIsSaving] = useState(false);

    const fileInputRef = useRef<HTMLInputElement>(null);

    // Sync state with userData props when they load dynamically
    React.useEffect(() => {
        if (userData) {
            setName(userData.name || userName);
            setEmail(userData.email || localStorage.getItem('vanakel_userEmail') || 'contact@vanakel.be');
            setPhone(userData.phone || '+32 400 00 00 00');
            setBio(userData.bio || 'Syndic professionnel gérant plusieurs résidences à Bruxelles.');
            if (userData.image_url) {
                setImagePreview(userData.image_url);
            }
        }
    }, [userData, userName]);

    const handleSave = async () => {
        if (onUpdateProfile) {
            setIsSaving(true);
            const formData = new FormData();
            formData.append('email', email);
            formData.append('name', name);
            formData.append('phone', phone);
            formData.append('bio', bio);
            if (imageFile) {
                formData.append('image', imageFile);
            }
            try {
                await onUpdateProfile(formData);
                setIsEditing(false);
            } catch (err) {
                console.error("Failed to update profile", err);
            } finally {
                setIsSaving(false);
            }
        } else {
            setIsEditing(false);
        }
    };

    const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            setImageFile(file);
            const reader = new FileReader();
            reader.onloadend = () => {
                setImagePreview(reader.result as string);
            };
            reader.readAsDataURL(file);
            console.log("File selected:", file.name);
            // Auto-trigger save mode when image changes
            setIsEditing(true);
        }
    };

    // Calculate member since from userData or use default
    const memberSince = React.useMemo(() => {
        if (userData?.created_at) {
            const date = new Date(userData.created_at);
            const monthNames = [
                "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
                "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"
            ];
            return `${monthNames[date.getMonth()]} ${date.getFullYear()}`;
        }
        return "Février 2026";
    }, [userData]);

    return (
        <div className="max-w-4xl mx-auto space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700 px-4 md:px-0 pb-20">
            {/* Header / Hero Section */}
            <div className="relative overflow-hidden rounded-3xl bg-zinc-950 border border-zinc-800 p-8 md:p-12">
                <div className="absolute top-0 right-0 w-64 h-64 bg-brand-green/5 blur-[100px] rounded-full -mr-32 -mt-32"></div>
                <div className="relative flex flex-col md:flex-row items-center gap-8">
                    <div className="relative group">
                        {imagePreview ? (
                            <div className="w-24 h-24 md:w-32 md:h-32 rounded-full overflow-hidden border-4 border-zinc-900 ring-2 ring-brand-green/20">
                                <img src={imagePreview} alt={name} className="w-full h-full object-cover" />
                            </div>
                        ) : (
                            <UserAvatar name={name} size="xl" className="border-4 border-zinc-900 ring-2 ring-brand-green/20" />
                        )}
                        <input
                            type="file"
                            ref={fileInputRef}
                            className="hidden"
                            accept="image/*"
                            onChange={handleImageChange}
                        />
                        <button
                            onClick={() => fileInputRef.current?.click()}
                            className="absolute bottom-0 right-0 p-2 bg-brand-green text-brand-black rounded-lg shadow-lg hover:scale-110 transition-transform group-hover:block"
                            title="Changer la photo"
                        >
                            <Camera size={16} />
                        </button>
                    </div>
                    <div className="text-center md:text-left space-y-2">
                        <div className="flex flex-wrap items-center justify-center md:justify-start gap-3">
                            <h1 className="text-3xl font-black text-white">{name}</h1>
                            <span className="px-3 py-1 bg-brand-green/10 text-brand-green rounded-full text-[10px] font-black uppercase tracking-widest border border-brand-green/20">
                                {role}
                            </span>
                        </div>
                        <p className="text-zinc-500 font-medium">{t.memberSince} {memberSince}</p>

                    </div>
                </div>
            </div>

            {/* Profile Content Grid */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Information Form */}
                <div className="lg:col-span-2 space-y-8">
                    <section className="bg-zinc-950 border border-zinc-800 rounded-3xl p-8 space-y-6">
                        <div className="flex justify-between items-center">
                            <h2 className="text-xl font-bold text-white flex items-center gap-2">
                                <User size={20} className="text-brand-green" />
                                {t.information}
                            </h2>
                            {!isEditing ? (
                                <button
                                    onClick={() => setIsEditing(true)}
                                    className="text-xs font-black text-brand-green uppercase tracking-widest hover:text-brand-green-light transition-colors"
                                >
                                    {t.modifier || 'Modifier'}

                                </button>
                            ) : (
                                <div className="flex gap-4">
                                    <button onClick={handleSave} className="text-brand-green hover:scale-110 transition-transform">
                                        <Check size={20} />
                                    </button>
                                    <button onClick={() => setIsEditing(false)} className="text-red-500 hover:scale-110 transition-transform">
                                        <X size={20} />
                                    </button>
                                </div>
                            )}
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                            <div className="space-y-1.5">
                                <label className="text-[10px] font-black uppercase text-zinc-600 tracking-widest flex items-center gap-1.5">
                                    <User size={12} /> {t.contact_name || 'Nom Complet'}

                                </label>
                                {isEditing ? (
                                    <input
                                        value={name}
                                        onChange={(e) => setName(e.target.value)}
                                        className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-brand-green/50 transition-colors"
                                    />
                                ) : (
                                    <p className="text-zinc-300 font-medium px-1">{name}</p>
                                )}
                            </div>
                            <div className="space-y-1.5">
                                <label className="text-[10px] font-black uppercase text-zinc-600 tracking-widest flex items-center gap-1.5">
                                    <Mail size={12} /> {t.email}

                                </label>
                                {isEditing ? (
                                    <input
                                        value={email}
                                        disabled
                                        className="w-full bg-zinc-900/50 border border-zinc-800 rounded-xl px-4 py-2.5 text-sm text-zinc-500 cursor-not-allowed focus:outline-none transition-colors"
                                        title={t.email_not_editable || "L'email ne peut pas être modifié"}
                                    />
                                ) : (
                                    <p className="text-zinc-300 font-medium px-1">{email}</p>
                                )}
                            </div>
                            <div className="space-y-1.5">
                                <label className="text-[10px] font-black uppercase text-zinc-600 tracking-widest flex items-center gap-1.5">
                                    <Phone size={12} /> {t.phone}

                                </label>
                                {isEditing ? (
                                    <input
                                        value={phone}
                                        onChange={(e) => setPhone(e.target.value)}
                                        className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-brand-green/50 transition-colors"
                                    />
                                ) : (
                                    <p className="text-zinc-300 font-medium px-1">{phone}</p>
                                )}
                            </div>
                            <div className="space-y-1.5">
                                <label className="text-[10px] font-black uppercase text-zinc-600 tracking-widest flex items-center gap-1.5">
                                    <Building size={12} /> Gérance
                                </label>
                                <p className="text-zinc-300 font-medium px-1">{userData?.company_name || 'Pro Gérance SPRL'}</p>
                            </div>
                        </div>

                        <div className="space-y-1.5 pt-2">
                            <label className="text-[10px] font-black uppercase text-zinc-600 tracking-widest">Bio</label>
                            {isEditing ? (
                                <textarea
                                    value={bio}
                                    onChange={(e) => setBio(e.target.value)}
                                    rows={3}
                                    className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-brand-green/50 transition-colors resize-none"
                                />
                            ) : (
                                <p className="text-zinc-400 text-sm leading-relaxed px-1">{bio}</p>
                            )}
                        </div>
                    </section>
                </div>

                {/* Sidebar Column */}
                <div className="space-y-8">
                    {/* Stats Card */}
                    <div className="bg-zinc-950 border border-zinc-800 rounded-3xl p-8 space-y-6">
                        <h2 className="text-lg font-bold text-white uppercase tracking-tight">{t.statistiques}</h2>

                        <div className="space-y-4">
                            <div className="bg-zinc-900/50 p-4 rounded-2xl flex justify-between items-center border border-zinc-800/50">
                                <div className="space-y-1">
                                    <p className="text-[10px] font-black text-zinc-600 uppercase">{t.properties}</p>

                                    <p className="text-2xl font-black text-white">{userData?.properties_count || '12'}</p>
                                </div>
                                <Building className="text-zinc-700" size={24} />
                            </div>
                            <div className="bg-zinc-900/50 p-4 rounded-2xl flex justify-between items-center border border-zinc-800/50">
                                <div className="space-y-1">
                                    <p className="text-[10px] font-black text-zinc-600 uppercase">{t.ongoing || 'Interventions'}</p>

                                    <p className="text-2xl font-black text-white">{userData?.interventions_count || '48'}</p>
                                </div>
                                <Check className="text-brand-green" size={24} />
                            </div>
                        </div>
                    </div>

                    {/* Actions Card */}
                    <div className="bg-zinc-950 border border-zinc-800 rounded-3xl p-6 space-y-3">
                        <button className="w-full flex items-center gap-3 p-4 rounded-2xl text-zinc-400 hover:text-white hover:bg-zinc-900 transition-all border border-transparent hover:border-zinc-800 group">
                            <div className="w-8 h-8 rounded-lg bg-zinc-900 flex items-center justify-center group-hover:bg-brand-green/10 group-hover:text-brand-green transition-colors">
                                <Lock size={16} />
                            </div>
                            <span className="text-sm font-bold">{t.security}</span>

                        </button>
                        <button className="w-full flex items-center gap-3 p-4 rounded-2xl text-zinc-400 hover:text-white hover:bg-zinc-900 transition-all border border-transparent hover:border-zinc-800 group">
                            <div className="w-8 h-8 rounded-lg bg-zinc-900 flex items-center justify-center group-hover:bg-brand-green/10 group-hover:text-brand-green transition-colors">
                                <Shield size={16} />
                            </div>
                            <span className="text-sm font-bold">{t.privacy}</span>

                        </button>
                        <div className="pt-3">
                            <button
                                onClick={onLogout}
                                className="w-full flex items-center gap-3 p-4 rounded-2xl text-red-500 hover:bg-red-500/10 transition-all group"
                            >
                                <div className="w-8 h-8 rounded-lg bg-red-500/10 flex items-center justify-center group-hover:bg-red-500 group-hover:text-white transition-colors">
                                    <LogOut size={16} />
                                </div>
                                <span className="text-sm font-black uppercase tracking-widest">{t.logout}</span>

                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ProfilePage;
