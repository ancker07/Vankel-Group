
import React, { useState, useEffect } from 'react';
import { Sparkles, Save, Shield, Cpu, Key, AlertCircle, CheckCircle2, Loader2, Eye, EyeOff } from 'lucide-react';
import { dataService } from '@/services/dataService';
import { Language } from '@/types';

interface AiSettingsPageProps {
    lang: Language;
    t: any;
}

const AiSettingsPage: React.FC<AiSettingsPageProps> = ({ lang, t }) => {
    const [model, setModel] = useState('gemini-3-flash-preview');
    const [apiKey, setApiKey] = useState('');
    const [isLoading, setIsLoading] = useState(true);
    const [isSaving, setIsSaving] = useState(false);
    const [message, setMessage] = useState<{ type: 'success' | 'error', text: string } | null>(null);
    const [showApiKey, setShowApiKey] = useState(false);

    useEffect(() => {
        const fetchSettings = async () => {
            try {
                const settings = await dataService.getAiSettings();
                if (settings) {
                    setModel(settings.model || 'gemini-3-flash-preview');
                    setApiKey(settings.apiKey || '');
                }
            } catch (error) {
                console.error("Error fetching AI settings:", error);
                setMessage({ type: 'error', text: 'Failed to load AI settings.' });
            } finally {
                setIsLoading(false);
            }
        };

        fetchSettings();
    }, []);

    const handleSave = async () => {
        setIsSaving(true);
        setMessage(null);
        try {
            await dataService.updateAiSettings({ model, apiKey });
            setMessage({ type: 'success', text: 'AI settings updated successfully!' });
            // Optional: clear message after 3 seconds
            setTimeout(() => setMessage(null), 3000);
        } catch (error) {
            console.error("Error saving AI settings:", error);
            setMessage({ type: 'error', text: 'Failed to update AI settings. Please try again.' });
        } finally {
            setIsSaving(false);
        }
    };

    if (isLoading) {
        return (
            <div className="flex flex-col items-center justify-center h-full space-y-4">
                <div className="w-12 h-12 border-4 border-brand-green/20 border-t-brand-green rounded-full animate-spin"></div>
                <p className="text-zinc-500 font-medium">{t?.loading_settings || 'Loading settings...'}</p>
            </div>
        );
    }

    return (
        <div className="flex flex-col h-full space-y-6 animate-in fade-in duration-500 max-w-4xl mx-auto pb-20">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center px-4 md:px-0 gap-4">
                <div>
                    <h1 className="text-2xl md:text-3xl font-black text-white flex items-center gap-3">
                        <Sparkles className="text-brand-green shrink-0" size={28} />
                        {t?.superadmin_ai_settings || 'AI Settings'}
                    </h1>
                    <p className="text-zinc-500 text-xs md:text-sm mt-1">{t?.ai_settings_subtitle || 'Configure global AI models and API keys for the system.'}</p>
                </div>
            </div>

            <div className="grid grid-cols-1 gap-6 px-4 md:px-0">
                {/* Main Settings Card */}
                <div className="bg-zinc-950 rounded-[2rem] border border-zinc-800 overflow-hidden shadow-2xl">
                    <div className="p-5 md:p-8 border-b border-zinc-900 bg-zinc-900/20">
                        <div className="flex items-center gap-3 mb-2">
                            <Shield className="text-brand-green" size={20} />
                            <h2 className="text-lg md:text-xl font-bold text-white">{t?.model_config || 'Model Configuration'}</h2>
                        </div>
                        <p className="text-zinc-500 text-xs md:text-sm">{t?.model_config_desc || 'Select the preferred AI engine and provide credentials.'}</p>
                    </div>

                    <div className="p-5 md:p-8 space-y-6 md:space-y-8">
                        {/* Model Selection */}
                        <div className="space-y-3">
                            <label className="flex items-center gap-2 text-[10px] md:text-sm font-black uppercase tracking-widest text-zinc-500">
                                <Cpu size={14} />
                                {t?.select_ai_model || 'Select AI Model'}
                            </label>
                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                <button
                                    onClick={() => setModel('gemini-3-flash-preview')}
                                    className={`p-5 rounded-2xl border transition-all text-left flex flex-col gap-2 ${model.startsWith('gemini')
                                            ? 'bg-brand-green/10 border-brand-green shadow-[0_0_20px_rgba(186,253,154,0.1)]'
                                            : 'bg-zinc-900/50 border-zinc-800 hover:border-zinc-700'
                                        }`}
                                >
                                    <div className="flex justify-between items-start">
                                        <span className={`font-bold text-sm md:text-base ${model.startsWith('gemini') ? 'text-brand-green' : 'text-zinc-300'}`}>{t?.google_gemini || 'Google Gemini'}</span>
                                        {model.startsWith('gemini') && <CheckCircle2 size={18} className="text-brand-green" />}
                                    </div>
                                    <p className="text-[10px] md:text-xs text-zinc-500 leading-relaxed font-medium">{t?.gemini_desc || 'Fast and efficient model for extraction and short rewrites.'}</p>
                                </button>

                                <button
                                    onClick={() => setModel('gpt-4o')}
                                    className={`p-5 rounded-2xl border transition-all text-left flex flex-col gap-2 ${model.startsWith('gpt')
                                            ? 'bg-purple-500/10 border-purple-500 shadow-[0_0_20px_rgba(168,85,247,0.1)]'
                                            : 'bg-zinc-900/50 border-zinc-800 hover:border-zinc-700'
                                        }`}
                                >
                                    <div className="flex justify-between items-start">
                                        <span className={`font-bold text-sm md:text-base ${model.startsWith('gpt') ? 'text-purple-400' : 'text-zinc-300'}`}>{t?.openai_chatgpt || 'OpenAI ChatGPT'}</span>
                                        {model.startsWith('gpt') && <CheckCircle2 size={18} className="text-purple-400" />}
                                    </div>
                                    <p className="text-[10px] md:text-xs text-zinc-500 leading-relaxed font-medium">{t?.chatgpt_desc || 'Powerful general purpose model for complex logic and long content.'}</p>
                                </button>
                            </div>
                        </div>

                        {/* API Key Input */}
                        <div className="space-y-3">
                            <label className="flex items-center gap-2 text-[10px] md:text-sm font-black uppercase tracking-widest text-zinc-500">
                                <Key size={14} />
                                {t?.api_key || 'API Key'}
                            </label>
                            <div className="relative">
                                <input
                                    type={showApiKey ? 'text' : 'password'}
                                    value={apiKey}
                                    onChange={(e) => setApiKey(e.target.value)}
                                    placeholder="Enter your API key here..."
                                    className="w-full bg-zinc-900 border border-zinc-800 rounded-2xl py-3.5 md:py-4 px-4 md:px-5 text-white focus:border-brand-green focus:ring-1 focus:ring-brand-green outline-none transition-all font-mono text-xs md:text-sm"
                                />
                                <div className="absolute right-4 top-1/2 -translate-y-1/2 flex items-center gap-2">
                                    <button
                                        type="button"
                                        onClick={() => setShowApiKey(!showApiKey)}
                                        className="p-1 hover:bg-zinc-800 rounded-lg text-zinc-600 hover:text-brand-green transition-all"
                                    >
                                        {showApiKey ? <EyeOff size={18} /> : <Eye size={18} />}
                                    </button>
                                    <Shield size={18} className="text-zinc-700" />
                                </div>
                            </div>
                            <p className="text-[9px] md:text-[10px] text-zinc-600 font-bold italic leading-tight">
                                {t?.api_key_secured || '* Your API key is encrypted and stored securely. It is only used for system-level AI requests.'}
                            </p>
                        </div>

                        {/* Status Message */}
                        {message && (
                            <div className={`p-4 rounded-xl border flex items-center gap-3 animate-in fade-in slide-in-from-top-2 duration-300 ${message.type === 'success' ? 'bg-brand-green/10 border-brand-green/20 text-brand-green' : 'bg-red-500/10 border-red-500/20 text-red-400'
                                }`}>
                                {message.type === 'success' ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
                                <span className="text-xs md:text-sm font-bold">{message.text}</span>
                            </div>
                        )}
                    </div>

                    <div className="p-5 md:p-8 bg-zinc-900/30 border-t border-zinc-900 flex">
                        <button
                            onClick={handleSave}
                            disabled={isSaving}
                            className="w-full sm:w-auto flex items-center justify-center gap-2 px-8 py-4 bg-brand-green text-brand-black rounded-2xl font-black uppercase tracking-widest hover:bg-white transition-all active:scale-95 disabled:opacity-50 shadow-xl shadow-brand-green/20"
                        >
                            {isSaving ? (
                                <Loader2 size={18} className="animate-spin" />
                            ) : (
                                <Save size={18} />
                            )}
                            {t?.save_changes || 'Save Changes'}
                        </button>
                    </div>
                </div>

                {/* Info Card */}
                <div className="bg-zinc-900/20 rounded-[2rem] border border-zinc-800 p-5 md:p-6 flex items-start gap-4">
                    <div className="w-10 h-10 rounded-xl bg-zinc-950 border border-zinc-800 flex items-center justify-center shrink-0">
                        <AlertCircle className="text-zinc-600" size={20} />
                    </div>
                    <div>
                        <h3 className="text-xs md:text-sm font-bold text-white mb-1">{t?.about_ai_integration || 'About AI Integration'}</h3>
                        <p className="text-[10px] md:text-xs text-zinc-500 leading-tight md:leading-relaxed font-bold uppercase tracking-tight opacity-60">
                            {t?.about_ai_desc || 'Vanakel Group uses AI to automatically classify incoming emails, improve technical reports, and generate building summaries. Gemini is recommended for its speed and native support for extraction features.'}
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
};


export default AiSettingsPage;
