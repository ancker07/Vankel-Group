
import { dataService } from "./dataService";

/**
 * AI Service (OpenAI ChatGPT only).
 * Dynamically fetches model/key configuration from the backend.
 */

export interface AiConfig {
    model: string;
    apiKey: string;
}

export interface EmailExtractionResult {
    classification: "MISSION" | "NON_MISSION" | "NEEDS_REVIEW";
    confidence: number;
    reasons: string[];
    mission: {
        title: string | null;
        description: string | null;
        sector: string | null;
        urgency: string | null;
        address: {
            raw: string | null;
            street: string | null;
            number: string | null;
            postalCode: string | null;
            city: string | null;
            country: "BE" | "FR" | "NL" | null;
        } | null;
        reference: string | null;
        contactOnSite: {
            name: string | null;
            phone: string | null;
            email: string | null;
        } | null;
        syndicName: string | null;
        senderEmail: string | null;
    } | null;
    extractionWarnings: string[];
}

export const DEFAULT_AI_MODEL = 'gpt-5-mini';

let cachedConfig: AiConfig | null = null;

export const getAiConfig = async (): Promise<AiConfig> => {
    try {
        const settings = await dataService.getAiSettings();
        cachedConfig = {
            model: settings.model || DEFAULT_AI_MODEL,
            apiKey: settings.apiKey || ''
        };
        return cachedConfig;
    } catch (error) {
        console.error("Failed to load AI config from backend:", error);
        return {
            model: DEFAULT_AI_MODEL,
            apiKey: ''
        };
    }
};

const generateResponse = async (prompt: string, options: {
    systemPrompt?: string,
    jsonMode?: boolean,
} = {}): Promise<string> => {
    const config = await getAiConfig();

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${config.apiKey}`
        },
        body: JSON.stringify({
            model: config.model,
            messages: [
                ...(options.systemPrompt ? [{ role: 'system', content: options.systemPrompt }] : []),
                { role: 'user', content: prompt }
            ],
            response_format: options.jsonMode ? { type: "json_object" } : undefined
        })
    });

    if (!response.ok) {
        const error = await response.json();
        throw new Error(`OpenAI Error: ${error.error?.message || response.statusText}`);
    }

    const data = await response.json();
    return data.choices[0].message.content;
};

// --- Exported Feature Functions ---

export const improveNote = async (text: string): Promise<string> => {
    try {
        const systemPrompt = `You are a careful grammar and clarity assistant.
        Rewrite the following text ONLY to improve clarity and correct grammar/spelling.
        STRICT RULES:
        1. Correct grammar, spelling, and minor sentence structure.
        2. Keep the EXACT same technical meaning and terminology.
        3. AUTO-DETECT the language and rewrite in that SAME language. No translation.
        4. DO NOT add new information or decorative/marketing language.
        5. Keep the rewrite minimal, subtle, and conservative.`;

        return await generateResponse(`Original text: "${text}"`, { systemPrompt });
    } catch (error) {
        console.error("AI Improvement failed:", error);
        return text;
    }
};

export const optimizeIntervention = async (title: string, description: string): Promise<{ title: string, description: string }> => {
    try {
        const systemPrompt = `You are a careful grammar and clarity assistant for building management technical notes.
        Rewrite the provided intervention title and description ONLY to improve clarity and correct grammar/spelling.
        STRICT RULES:
        1. Correct grammar, spelling, and minor sentence structure.
        2. Keep the EXACT same technical meaning and terminology.
        3. AUTO-DETECT the language and rewrite in that SAME language. No translation.
        4. Output the result ONLY as a JSON object with keys "title" and "description".`;

        const result = await generateResponse(`Original Title: "${title}"\nOriginal Description: "${description}"`, {
            systemPrompt,
            jsonMode: true,
        });

        return JSON.parse(result || '{}');
    } catch (error) {
        console.error("AI Optimization failed:", error);
        throw error;
    }
};

export const generateAnnualSummary = async (buildingData: any, interventions: any[]): Promise<string> => {
    try {
        const prompt = `
        As a technical expert for Vanakel Group, generate a professional annual summary for this building.
        Building: ${JSON.stringify(buildingData)}
        Interventions this year: ${JSON.stringify(interventions)}

        Include:
        1. Technical overview of the property's health.
        2. Recurring maintenance patterns or issues.
        3. Predictive maintenance recommendations.
        Keep it professional and well-structured.
        `;
        return await generateResponse(prompt);
    } catch (error) {
        console.error("Annual summary generation failed:", error);
        return "Error generating summary.";
    }
};

export const extractEmailData = async (emailContent: string): Promise<EmailExtractionResult> => {
    const systemPrompt = `
    SYSTEM:
    You are an expert AI extraction engine for Vanakel Group, a Belgian building management company.
    Your task is to extract ALL mission-critical details from the email content AND any attached documents.

    ### ⚠️ CRITICAL: ATTACHMENT READING RULES
    - If attachment content is provided, it is the PRIMARY DATA SOURCE.
    - Attachments often contain formal intervention request forms with structured tables.
    - Read EVERY piece of text: titles, headers, table rows, footers.
    - If the email body is vague but attachment contains a formal request, classify as "MISSION".
    - If there is a conflict between email body and attachment, TRUST THE ATTACHMENT.

    ### DATA EXTRACTION PRIORITIES:
    1. Syndic/Manager Name: Look for "Syndic:", "Expéditeur:", "Gestionnaire:" in both email body and attachments.
    2. Address: Look for "Adresse d'intervention:", address tables, Belgian format addresses.
    3. Contact Person: Look for "Personne de contact:", "Contact sur place:", names near phone numbers.
    4. Phone/GSM: Look for "Numéro de GSM:", "GSM:", phone numbers starting with 04xx or +32.
    5. Problem Description: Merge information from email body AND attachment.
    6. Urgency: "urgente", "dans les plus brefs délais", "dringend" = HIGH or CRITICAL.

    ### Classification Rules:
    - "MISSION": A genuine request for repair, maintenance, intervention.
    - "NON_MISSION": Spam, newsletters, test messages ("test", "fff", "abc"), marketing emails.
    - "NEEDS_REVIEW": Likely a real mission but missing key information.

    ### Sector Mapping:
    - Leak, fuite, water damage → PLOMBERIE or SANITAIRE
    - Clogged sewer, égout bouché → PLOMBERIE
    - Heating, chauffage, boiler → CHAUFFAGE
    - Electrical, électricité → ELECTRICITE
    - Painting, peinture → PEINTURE
    - Carpentry, menuiserie, door, window → MENUISERIE
    - Tiles, carrelage → CARRELAGE
    - If unclear → GENERAL

    ### Critical Instructions:
    - "MISSION" REQUIRES a specific, actionable building issue.
    - Very short emails (just "fff", "hello", "test") are NEVER a "MISSION".
    - The syndicName field is CRITICAL — always try to extract it from any mention of "Syndic" in the content.

    Return ONLY valid JSON matching this schema:
    {
      "classification": "MISSION" | "NON_MISSION" | "NEEDS_REVIEW",
      "confidence": 0.0 to 1.0,
      "reasons": [string],
      "mission": {
        "title": string | null,
        "description": string | null,
        "sector": string | null,
        "urgency": string | null,
        "address": { "raw": string | null, "street": string | null, "number": string | null, "postalCode": string | null, "city": string | null, "country": "BE" | "FR" | "NL" | null } | null,
        "reference": string | null,
        "contactOnSite": { "name": string | null, "phone": string | null, "email": string | null } | null,
        "syndicName": string | null,
        "senderEmail": string | null
      } | null,
      "extractionWarnings": [string]
    }
    `;

    try {
        const result = await generateResponse(`Email Content:\n${emailContent}`, {
            systemPrompt,
            jsonMode: true,
        });
        return JSON.parse(result || '{}');
    } catch (e) {
        console.error("AI extraction failed:", e);
        throw e;
    }
};
