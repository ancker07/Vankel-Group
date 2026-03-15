
import React from 'react';
import {
  Wrench,
  Flame,
  Umbrella,
  Zap,
  Trees,
  Hammer,
  Droplets,
  ShieldCheck,
  Paintbrush,
  Grid,
  Box
} from 'lucide-react';
import { Sector } from '@/types';

// Used for visual categorization in UI
export const CATEGORIES = [
  { id: 'plumbing', label: { EN: 'Plumbing', FR: 'Plomberie', NL: 'Loodgieterij' }, icon: <Droplets className="w-4 h-4" /> },
  { id: 'heating', label: { EN: 'Heating', FR: 'Chauffage', NL: 'Verwarming' }, icon: <Flame className="w-4 h-4" /> },
  { id: 'roofing', label: { EN: 'Roofing', FR: 'Toiture', NL: 'Dakbedekking' }, icon: <Umbrella className="w-4 h-4" /> },
  { id: 'electricity', label: { EN: 'Electricity', FR: 'Électricité', NL: 'Elektriciteit' }, icon: <Zap className="w-4 h-4" /> },
  { id: 'carpentry', label: { EN: 'Carpentry', FR: 'Menuiserie', NL: 'Timmerwerk' }, icon: <Trees className="w-4 h-4" /> },
  { id: 'masonry', label: { EN: 'Masonry', FR: 'Maçonnerie', NL: 'Metselwerk' }, icon: <Hammer className="w-4 h-4" /> },
  { id: 'waterproofing', label: { EN: 'Waterproofing', FR: 'Étanchéité', NL: 'Waterdichtheid' }, icon: <ShieldCheck className="w-4 h-4" /> },
  { id: 'other', label: { EN: 'Other', FR: 'Autre', NL: 'Ander' }, icon: <Wrench className="w-4 h-4" /> },
];

export const SECTORS: { id: Sector, label: { EN: string, FR: string, NL: string }, icon: React.ReactNode }[] = [
  { id: 'ELECTRICITE', label: { EN: 'Electricity', FR: 'Électricité', NL: 'Elektriciteit' }, icon: <Zap size={14} /> },
  { id: 'CARRELAGE', label: { EN: 'Tiling', FR: 'Carrelage', NL: 'Tegelwerk' }, icon: <Grid size={14} /> },
  { id: 'SANITAIRE', label: { EN: 'Sanitary', FR: 'Sanitaire', NL: 'Sanitair' }, icon: <Droplets size={14} /> },
  { id: 'CHAUFFAGE', label: { EN: 'Heating', FR: 'Chauffage', NL: 'Verwarming' }, icon: <Flame size={14} /> },
  { id: 'PLOMBERIE', label: { EN: 'Plumbing', FR: 'Plomberie', NL: 'Loodgieterij' }, icon: <Wrench size={14} /> },
  { id: 'PEINTURE', label: { EN: 'Painting', FR: 'Peinture', NL: 'Schilderwerk' }, icon: <Paintbrush size={14} /> },
  { id: 'MENUISERIE', label: { EN: 'Carpentry', FR: 'Menuiserie', NL: 'Timmerwerk' }, icon: <Trees size={14} /> },
  { id: 'GENERAL', label: { EN: 'General', FR: 'Général', NL: 'Algemeen' }, icon: <Box size={14} /> },
  { id: 'AUTRE', label: { EN: 'Other', FR: 'Autre', NL: 'Andere' }, icon: <Wrench size={14} /> },
];

export const URGENCY = [
  { id: 'LOW', label: { EN: 'Low', FR: 'Faible', NL: 'Laag' }, color: 'text-zinc-400' },
  { id: 'MEDIUM', label: { EN: 'Medium', FR: 'Moyenne', NL: 'Gemiddeld' }, color: 'text-blue-400' },
  { id: 'HIGH', label: { EN: 'High', FR: 'Haute', NL: 'Hoog' }, color: 'text-orange-400' },
  { id: 'CRITICAL', label: { EN: 'Critical', FR: 'Critique', NL: 'Kritiek' }, color: 'text-red-500' },
];


export const DELAY_REASONS = [
  { id: 'missing_part', EN: 'Missing part', FR: 'Pièce manquante', NL: 'Ontbrekend onderdeel' },
  { id: 'no_access', EN: 'No access', FR: 'Accès impossible', NL: 'Geen toegang' },
  { id: 'client_unavailable', EN: 'Client unavailable', FR: 'Client indisponible', NL: 'Klant niet beschikbaar' },
  { id: 'waiting_validation', EN: 'Waiting syndic validation', FR: 'En attente de validation du syndic', NL: 'Wachten op validatie syndicus' },
  { id: 'weather', EN: 'Bad weather', FR: 'Intempéries / météo', NL: 'Slecht weer' },
  { id: 'subcontractor', EN: 'Subcontractor unavailable', FR: 'Sous-traitant indisponible', NL: 'Onderaannemer niet beschikbaar' },
  { id: 'other', EN: 'Other', FR: 'Autre', NL: 'Andere' },
];

export { TRANSLATIONS } from '../locales';
