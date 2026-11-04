<?php

namespace App\Support;

use App\Models\User;

/**
 * Fixed notification / email wording in the three app languages.
 *
 * Every message is rendered in the RECIPIENT's selected language (users.locale, set by the
 * mobile app and the website whenever the language is changed). No AI call is involved, so
 * a notification can never fall back to English just because a translation request failed.
 */
class MessageText
{
    public const LOCALES = ['en', 'fr', 'nl'];

    /** key => locale => [title, body]; {placeholders} are filled by make(). */
    private const MESSAGES = [
        'mission_approved' => [
            'en' => ['Mission Approved!', "Your mission '{title}' has been approved."],
            'fr' => ['Mission approuvée !', 'Votre mission « {title} » a été approuvée.'],
            'nl' => ['Missie goedgekeurd!', "Uw missie '{title}' is goedgekeurd."],
        ],
        'mission_rejected' => [
            'en' => ['Mission Rejected', "Your mission '{title}' was unfortunately rejected."],
            'fr' => ['Mission refusée', 'Votre mission « {title} » a malheureusement été refusée.'],
            'nl' => ['Missie afgewezen', "Uw missie '{title}' is helaas afgewezen."],
        ],
        'intervention_update' => [
            'en' => ['Intervention Update', "The status of '{title}' has changed to {status}."],
            'fr' => ["Mise à jour de l'intervention", 'Le statut de « {title} » est passé à {status}.'],
            'nl' => ['Update van de interventie', "De status van '{title}' is gewijzigd naar {status}."],
        ],
        'new_assignment' => [
            'en' => ['New Assignment', "You have been assigned to a new intervention: '{title}'."],
            'fr' => ['Nouvelle affectation', 'Une nouvelle intervention vous a été attribuée : « {title} ».'],
            'nl' => ['Nieuwe toewijzing', "U bent toegewezen aan een nieuwe interventie: '{title}'."],
        ],
        'intervention_submitted' => [
            'en' => ['Intervention sent for review', "{technician} sent '{title}' to the admin ({status})."],
            'fr' => ["Intervention envoyée pour validation", "{technician} a envoyé « {title} » à l'admin ({status})."],
            'nl' => ['Interventie ter controle verzonden', "{technician} heeft '{title}' naar de beheerder gestuurd ({status})."],
        ],
        'new_mission' => [
            'en' => ['New Mission: {title}', 'Urgency: {urgency}. {source}'],
            'fr' => ['Nouvelle mission : {title}', 'Urgence : {urgency}. {source}'],
            'nl' => ['Nieuwe missie: {title}', 'Urgentie: {urgency}. {source}'],
        ],
        'urgent_mission' => [
            'en' => ['🚨 Urgent mission: {title}', 'Urgency: {urgency}. {source}'],
            'fr' => ['🚨 Mission urgente : {title}', 'Urgence : {urgency}. {source}'],
            'nl' => ['🚨 Dringende missie: {title}', 'Urgentie: {urgency}. {source}'],
        ],
    ];

    private const WORDS = [
        'status' => [
            'PENDING' => ['en' => 'In progress', 'fr' => 'En cours', 'nl' => 'In uitvoering'],
            'DELAYED' => ['en' => 'Delayed', 'fr' => 'Retardée', 'nl' => 'Vertraagd'],
            'COMPLETED' => ['en' => 'Completed', 'fr' => 'Terminée', 'nl' => 'Voltooid'],
        ],
        'urgency' => [
            'LOW' => ['en' => 'Low', 'fr' => 'Faible', 'nl' => 'Laag'],
            'MEDIUM' => ['en' => 'Medium', 'fr' => 'Moyenne', 'nl' => 'Gemiddeld'],
            'NORMAL' => ['en' => 'Normal', 'fr' => 'Normale', 'nl' => 'Normaal'],
            'HIGH' => ['en' => 'High', 'fr' => 'Élevée', 'nl' => 'Hoog'],
            'URGENT' => ['en' => 'Urgent', 'fr' => 'Urgente', 'nl' => 'Dringend'],
        ],
        'source' => [
            'EMAIL' => ['en' => 'Received by email.', 'fr' => 'Reçue par e-mail.', 'nl' => 'Ontvangen per e-mail.'],
            'OTHER' => ['en' => 'Requested by a Syndic.', 'fr' => 'Demandée par un syndic.', 'nl' => 'Aangevraagd door een syndicus.'],
        ],
        'delay_reason' => [
            'missing_part' => ['en' => 'Missing part', 'fr' => 'Pièce manquante', 'nl' => 'Ontbrekend onderdeel'],
            'no_access' => ['en' => 'No access', 'fr' => 'Accès impossible', 'nl' => 'Geen toegang'],
            'client_unavailable' => ['en' => 'Client unavailable', 'fr' => 'Client indisponible', 'nl' => 'Klant niet beschikbaar'],
            'waiting_validation' => ['en' => 'Waiting validation', 'fr' => 'En attente de validation', 'nl' => 'Wacht op goedkeuring'],
            'weather' => ['en' => 'Bad weather', 'fr' => 'Mauvais temps', 'nl' => 'Slecht weer'],
            'subcontractor' => ['en' => 'Subcontractor unavailable', 'fr' => 'Sous-traitant indisponible', 'nl' => 'Onderaannemer niet beschikbaar'],
            'other' => ['en' => 'Other', 'fr' => 'Autre', 'nl' => 'Andere'],
        ],
    ];

    /** The language to use for a recipient: their saved choice, else the app default. */
    public static function localeFor(?User $user): string
    {
        return self::normalize($user?->locale);
    }

    public static function normalize(?string $locale): string
    {
        $code = strtolower(substr((string) $locale, 0, 2));
        if (in_array($code, self::LOCALES, true)) {
            return $code;
        }

        $default = strtolower(substr((string) config('app.locale', 'en'), 0, 2));

        return in_array($default, self::LOCALES, true) ? $default : 'en';
    }

    /** A word (status, urgency, delay reason...) in the given language; the raw value if unknown. */
    public static function word(string $group, ?string $value, string $locale): string
    {
        $value = (string) $value;
        $row = self::WORDS[$group][strtoupper($value)] ?? self::WORDS[$group][strtolower($value)] ?? null;

        return $row[self::normalize($locale)] ?? $value;
    }

    /** Value of a translatable column (title / description) in the given language. */
    public static function field($model, string $field, string $locale): string
    {
        $locale = self::normalize($locale);

        return (string) ($model->{"{$field}_{$locale}"} ?: $model->{$field});
    }

    /**
     * @param  array|callable  $params  values for the placeholders, or fn(string $locale): array
     * @return array{title: string, body: string}
     */
    public static function make(string $key, string $locale, array|callable $params = []): array
    {
        $locale = self::normalize($locale);
        [$title, $body] = self::MESSAGES[$key][$locale];
        $values = is_callable($params) ? $params($locale) : $params;

        $replace = [];
        foreach ($values as $name => $value) {
            $replace['{' . $name . '}'] = (string) $value;
        }

        return ['title' => strtr($title, $replace), 'body' => strtr($body, $replace)];
    }

    /** The message in all three languages (stored with the in-app notification). */
    public static function all(string $key, array|callable $params = []): array
    {
        $out = [];
        foreach (self::LOCALES as $locale) {
            $out[$locale] = self::make($key, $locale, $params);
        }

        return $out;
    }

    /** Intervention report email: key => [en, fr, nl]. */
    private const REPORT = [
        'subject' => ["Intervention report: {title} - {address}", "Rapport d'intervention : {title} - {address}", 'Interventieverslag: {title} - {address}'],
        'header' => ['Vanakel Group - Intervention report', "Vanakel Group - Rapport d'intervention", 'Vanakel Group - Interventieverslag'],
        'done_on' => ['Intervention carried out on {date}', 'Intervention effectuée le {date}', 'Interventie uitgevoerd op {date}'],
        'building' => ['Building information', "Informations de l'immeuble", 'Gebouwinformatie'],
        'address' => ['Address:', 'Adresse :', 'Adres:'],
        'city' => ['City:', 'Ville :', 'Stad:'],
        'syndic' => ['Syndic:', 'Syndic :', 'Syndicus:'],
        'technical' => ['Technical details', 'Détails techniques', 'Technische details'],
        'category' => ['Category:', 'Catégorie :', 'Categorie:'],
        'status' => ['Status:', 'Statut :', 'Status:'],
        'completed' => ['Completed', 'Terminé', 'Voltooid'],
        'delayed' => ['Delayed', 'Retardé', 'Vertraagd'],
        'admin_note' => ['Technical observations', 'Observations techniques', 'Technische opmerkingen'],
        'delay_details' => ['Delay details', 'Détails du retard', 'Details van de vertraging'],
        'reason' => ['Reason:', 'Motif :', 'Reden:'],
        'new_date' => ['New date:', 'Nouvelle date :', 'Nieuwe datum:'],
        'description' => ['Original description', "Description d'origine", 'Oorspronkelijke beschrijving'],
        'rights' => ['All rights reserved.', 'Tous droits réservés.', 'Alle rechten voorbehouden.'],
        'automatic' => ['This is an automatic report generated by Vanakel Management.', 'Ceci est un rapport automatique généré par Vanakel Management.', 'Dit is een automatisch verslag van Vanakel Management.'],
    ];

    /** All report-email strings for one language. */
    public static function report(string $locale): array
    {
        $i = array_search(self::normalize($locale), self::LOCALES, true);

        return array_map(fn (array $row) => $row[$i], self::REPORT);
    }

    /** Date in the numeric d/m/Y form every language here uses. */
    public static function date($value): string
    {
        return \Carbon\Carbon::parse($value ?: now())->format('d/m/Y');
    }
}
