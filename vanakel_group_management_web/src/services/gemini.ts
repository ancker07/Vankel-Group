
import { GoogleGenAI, Type } from "@google/genai";
import { Language } from "./types";

// Always use named parameter for apiKey and directly access process.env.API_KEY
const getAI = () => new GoogleGenAI({ apiKey: process.env.API_KEY });

/**
 * GLOBAL AI REWRITE RULE:
 * Acts ONLY as a light professional rewrite and grammar assistant.
 * - Detect language automatically and keep it.
 * - Correct grammar, spelling, and basic sentence structure.
 * - Preserve original meaning EXACTLY.
 * - Keep same technical intent and terminology.
 * - Minimal, subtle, and conservative rewrite intensity.
 * - DO NOT add new info or interpreted content.
 */

export const improveNote = async (text: string): Promise<string> => {
  try {
    const ai = getAI();
    const response = await ai.models.generateContent({
      model: 'gemini-3-flash-preview',
      contents: `You are a careful grammar and clarity assistant. 
      Rewrite the following text ONLY to improve clarity and correct grammar/spelling.
      
      STRICT RULES:
      1. Correct grammar, spelling, and minor sentence structure.
      2. Keep the EXACT same technical meaning and terminology.
      3. AUTO-DETECT the language and rewrite in that SAME language. No translation.
      4. DO NOT add new information or decorative/marketing language.
      5. Keep the rewrite minimal, subtle, and conservative.
      
      Original text: "${text}"`,
      config: {
        thinkingConfig: { thinkingBudget: 0 }
      }
    });
    return response.text?.trim() || text;
  } catch (error) {
    console.error("AI Improvement failed:", error);
    return text;
  }
};

export const optimizeIntervention = async (title: string, description: string): Promise<{ title: string, description: string }> => {
  try {
    const ai = getAI();
    const response = await ai.models.generateContent({
      model: 'gemini-3-flash-preview',
      contents: `You are a careful grammar and clarity assistant for building management technical notes. 
      Rewrite the provided intervention title and description ONLY to improve clarity and correct grammar/spelling.
      
      STRICT RULES:
      1. Correct grammar, spelling, and minor sentence structure.
      2. Keep the EXACT same technical meaning and terminology.
      3. AUTO-DETECT the language and rewrite in that SAME language. No translation.
      4. DO NOT add new information, decorative, or "over-professionalized" language.
      5. Keep the rewrite minimal and subtle.
      
      Output the result ONLY as a JSON object with keys "title" and "description".

      Original Title: "${title}"
      Original Description: "${description}"`,
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            title: { type: Type.STRING },
            description: { type: Type.STRING }
          },
          required: ["title", "description"]
        },
        thinkingConfig: { thinkingBudget: 0 }
      }
    });
    return JSON.parse(response.text || '{}');
  } catch (error) {
    console.error("AI Optimization failed:", error);
    throw error;
  }
};

export const generateAnnualSummary = async (buildingData: any, interventions: any[]): Promise<string> => {
  try {
    const ai = getAI();
    const prompt = `
      As a technical expert for Vanakel Group, generate a professional annual summary for this building.
      Building: ${JSON.stringify(buildingData)}
      Interventions this year: ${JSON.stringify(interventions)}
      
      Include:
      1. Technical overview of the property's health.
      2. Recurring maintenance patterns or issues.
      3. Predictive maintenance recommendations based on equipment age and recent interventions.
      4. General budget and long-term outlook.
      Keep it professional and well-structured for an official annual report.
    `;
    const response = await ai.models.generateContent({
      model: 'gemini-3-flash-preview',
      contents: prompt,
    });
    return response.text || "Summary generation failed.";
  } catch (error) {
    console.error("Annual summary generation failed:", error);
    return "Error generating summary.";
  }
};

export interface EmailExtractionResult {
  classification: "MISSION" | "NON_MISSION" | "NEEDS_REVIEW";
  confidence: number;
  reasons: string[];
  mission: {
    title: string | null;
    description: string | null;
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

export const extractEmailData = async (emailContent: string): Promise<EmailExtractionResult> => {
  const ai = getAI();
  const systemPrompt = `
SYSTEM:
You are an information extraction engine for property management intervention emails. 
Return ONLY valid JSON matching the schema provided. No prose. No markdown.

USER:
Extract and classify the email into one of:
- "MISSION": an actionable intervention/mission request
- "NON_MISSION": marketing/newsletter/spam/general conversation
- "NEEDS_REVIEW": looks like a mission but essential info is missing or ambiguous

Return JSON with this exact schema:
{
  "classification": "MISSION" | "NON_MISSION" | "NEEDS_REVIEW",
  "confidence": 0.0 to 1.0,
  "reasons": [string],
  "mission": {
    "title": string | null,
    "description": string | null,
    "address": {
      "raw": string | null,
      "street": string | null,
      "number": string | null,
      "postalCode": string | null,
      "city": string | null,
      "country": "BE" | "FR" | "NL" | null
    },
    "reference": string | null,
    "contactOnSite": {
      "name": string | null,
      "phone": string | null,
      "email": string | null
    },
    "syndicName": string | null,
    "senderEmail": string | null
  },
  "extractionWarnings": [string]
}

Extraction rules:
- If you see "Adresse:" / "Address:" / "Adres:" prefer that as address.
- Belgian address patterns are common: street + number + postal code + city.
- Phone can appear as 0470 12 34 56, +32 470 12 34 56, etc.
- Do not guess missing values. Use null if unknown.
- If this is marketing/newsletter, classification MUST be "NON_MISSION" and mission fields should be null.
- If it is a mission but address is missing/ambiguous, classification MUST be "NEEDS_REVIEW" (not ERROR).
`;

  // Schema Definition
  const schema = {
    type: Type.OBJECT,
    properties: {
      classification: { type: Type.STRING, enum: ["MISSION", "NON_MISSION", "NEEDS_REVIEW"] },
      confidence: { type: Type.NUMBER },
      reasons: { type: Type.ARRAY, items: { type: Type.STRING } },
      mission: {
        type: Type.OBJECT,
        properties: {
          title: { type: Type.STRING, nullable: true },
          description: { type: Type.STRING, nullable: true },
          address: {
            type: Type.OBJECT,
            properties: {
              raw: { type: Type.STRING, nullable: true },
              street: { type: Type.STRING, nullable: true },
              number: { type: Type.STRING, nullable: true },
              postalCode: { type: Type.STRING, nullable: true },
              city: { type: Type.STRING, nullable: true },
              country: { type: Type.STRING, enum: ["BE", "FR", "NL"], nullable: true },
            },
            nullable: true
          },
          reference: { type: Type.STRING, nullable: true },
          contactOnSite: {
            type: Type.OBJECT,
            properties: {
              name: { type: Type.STRING, nullable: true },
              phone: { type: Type.STRING, nullable: true },
              email: { type: Type.STRING, nullable: true },
            },
            nullable: true
          },
          syndicName: { type: Type.STRING, nullable: true },
          senderEmail: { type: Type.STRING, nullable: true },
        },
        nullable: true
      },
      extractionWarnings: { type: Type.ARRAY, items: { type: Type.STRING } },
    },
    required: ["classification", "confidence", "reasons"]
  };

  // Retry Logic with Timeout (Max 2 attempts, 15s timeout each)
  for (let i = 0; i < 2; i++) {
    try {
      const apiCall = ai.models.generateContent({
        model: 'gemini-3-flash-preview',
        contents: systemPrompt + `\n\nEmail Content:\n${emailContent}`,
        config: {
          responseMimeType: "application/json",
          responseSchema: schema,
          thinkingConfig: { thinkingBudget: 0 }
        }
      });

      // 15 Second Timeout to prevent infinite loading
      const timeout = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error("AI Processing Timeout")), 15000)
      );

      const response = await Promise.race([apiCall, timeout]);
      return JSON.parse(response.text || '{}');
    } catch (e) {
      console.warn(`AI extraction attempt ${i + 1} failed:`, e);
      if (i === 1) throw e;
      await new Promise(r => setTimeout(r, 1000));
    }
  }
  throw new Error("AI Service failed after retries");
};
