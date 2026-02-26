
import React from 'react';
import { ResponsiveContainer, BarChart, CartesianGrid, XAxis, YAxis, Tooltip, Bar } from 'recharts';
import { Calendar, ToggleRight, ToggleLeft } from 'lucide-react';

interface ActivityChartProps {
    data: any[];
    showCompare: boolean;
    setShowCompare: (show: boolean) => void;
    lang: string;
    t: any;
}

const ActivityChart: React.FC<ActivityChartProps> = ({ data, showCompare, setShowCompare, lang, t }) => {
    return (
        <div className="lg:col-span-2 bg-zinc-950 p-4 md:p-6 rounded-2xl border border-zinc-800">
            <div className="flex justify-between items-center mb-4 md:mb-6">
                <h3 className="text-base md:text-lg font-semibold flex items-center gap-2 text-white">
                    <Calendar size={18} className="text-brand-green shrink-0" />
                    <span>{t.interventions_received}</span>
                </h3>
                <button
                    onClick={() => setShowCompare(!showCompare)}
                    className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-[10px] font-black uppercase tracking-widest transition-all ${showCompare ? 'bg-brand-green text-brand-black' : 'bg-zinc-900 text-zinc-500 border border-zinc-800 hover:text-white'}`}
                >
                    {showCompare ? <ToggleRight size={16} /> : <ToggleLeft size={16} />}{t.compare}
                </button>
            </div>
            <div className="h-[250px] md:h-[300px] w-full">
                <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={data} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#27272a" vertical={false} />
                        <XAxis
                            dataKey="name"
                            stroke="#71717a"
                            fontSize={10}
                            tickLine={false}
                            axisLine={false}
                            dy={10}
                        />
                        <YAxis
                            stroke="#71717a"
                            fontSize={10}
                            tickLine={false}
                            axisLine={false}
                        />
                        <Tooltip
                            cursor={{ fill: '#27272a', opacity: 0.4 }}
                            contentStyle={{ backgroundColor: '#09090b', borderColor: '#27272a', borderRadius: '8px', color: '#fff' }}
                            itemStyle={{ color: '#fff', fontSize: '12px' }}
                        />
                        <Bar dataKey="value" fill="#22c55e" radius={[4, 4, 0, 0]} barSize={32} />
                        {showCompare && <Bar dataKey="comparison" fill="#3f3f46" radius={[4, 4, 0, 0]} barSize={32} />}
                    </BarChart>
                </ResponsiveContainer>
            </div>
        </div>
    );
};

export default ActivityChart;
