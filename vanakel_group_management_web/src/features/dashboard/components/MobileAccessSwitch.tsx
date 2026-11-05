import React, { useEffect, useState } from 'react';
import { Smartphone } from 'lucide-react';
import { dataService } from '@/services/dataService';
import { usePermissions } from '@/lib/permissions';

/**
 * Super admin master switch for the whole mobile app. While it is off every request from the phone app is
 * refused by the server (the website keeps working). Turning it off asks for a confirmation first.
 */
const MobileAccessSwitch: React.FC<{ t: any }> = ({ t }) => {
    const can = usePermissions();
    const [enabled, setEnabled] = useState<boolean | null>(null);
    const [isSaving, setIsSaving] = useState(false);
    const [confirmOff, setConfirmOff] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        if (!can('settings.mobile')) return;
        dataService.getMobileAccess()
            .then(r => setEnabled(!!r.enabled))
            .catch(() => setError(t.mobile_access_load_error || 'Could not load the mobile access setting.'));
    }, []);

    if (!can('settings.mobile')) return null;

    const save = async (next: boolean) => {
        setIsSaving(true);
        setError('');
        try {
            const r = await dataService.setMobileAccess(next);
            setEnabled(!!r.enabled);
            setConfirmOff(false);
        } catch (e: any) {
            setError(e?.response?.data?.message || t.mobile_access_save_error || 'Could not save. Please try again.');
        } finally {
            setIsSaving(false);
        }
    };

    const isOn = enabled === true;

    return (
        <div className={`rounded-2xl border p-5 flex flex-col gap-4 ${enabled === false ? 'border-red-500/40 bg-red-500/5' : 'border-zinc-900 bg-zinc-950/50'}`}>
            <div className="flex items-center justify-between gap-4">
                <div className="flex items-start gap-3 min-w-0">
                    <Smartphone size={22} className={enabled === false ? 'text-red-400' : 'text-brand-green'} />
                    <div className="min-w-0">
                        <h3 className="text-sm font-black uppercase tracking-widest text-white">{t.mobile_access_title || 'Mobile app access'}</h3>
                        <p className="text-xs text-zinc-500 mt-1">
                            {enabled === null
                                ? '…'
                                : isOn
                                    ? (t.mobile_access_on || 'The mobile app is on. Admins and technicians can use it.')
                                    : (t.mobile_access_off || 'The mobile app is switched off. Nothing works on the phones until you turn it back on. The website is not affected.')}
                        </p>
                    </div>
                </div>
                <button
                    type="button"
                    role="switch"
                    aria-checked={isOn}
                    aria-label={t.mobile_access_title || 'Mobile app access'}
                    disabled={enabled === null || isSaving}
                    onClick={() => (isOn ? setConfirmOff(true) : save(true))}
                    className={`relative shrink-0 w-14 h-8 rounded-full transition-colors disabled:opacity-50 ${isOn ? 'bg-brand-green' : 'bg-zinc-700'}`}
                >
                    <span className={`absolute top-1 left-1 w-6 h-6 rounded-full bg-white transition-transform ${isOn ? 'translate-x-6' : ''}`} />
                </button>
            </div>

            {confirmOff && (
                <div className="rounded-xl border border-red-500/30 bg-red-500/10 p-4 space-y-3">
                    <p className="text-sm text-red-300">{t.mobile_access_confirm || 'Switch the mobile app off for everyone? No one will be able to use it on their phone until you switch it on again.'}</p>
                    <div className="flex gap-3">
                        <button onClick={() => setConfirmOff(false)} disabled={isSaving} className="flex-1 py-2.5 bg-zinc-900 text-zinc-300 border border-zinc-800 rounded-xl font-bold text-xs uppercase">{t.btnCancel || 'Cancel'}</button>
                        <button onClick={() => save(false)} disabled={isSaving} className="flex-1 py-2.5 bg-red-500 text-white rounded-xl font-bold text-xs uppercase disabled:opacity-50">{t.mobile_access_turn_off || 'Switch off'}</button>
                    </div>
                </div>
            )}

            {error && <p className="text-xs text-red-400">{error}</p>}
        </div>
    );
};

export default MobileAccessSwitch;
