# Vanakel Group Management Platform - Mobile App Plan (Admin & Syndic)

## 1. Executive Summary
This mobile application extends the **Vanakel Group** platform to Android and iOS devices. Unlike the previous plan which focused on a "Technician" role, this app is designed specifically for two core roles:
1.  **Admin (Contractor):** To manage missions, approve requests, and oversee operations on the go.
2.  **Syndic (Client):** To request interventions, track progress, and view reports.

**Technology Stack:** Flutter (Cross-platform for iOS & Android).

---

## 2. User Roles & Features

### **Role A: ADMIN (Contractor / Company)**
*The "Boss" mode. Full control over incoming requests and ongoing jobs.*

#### **1. Mission Control (The Inbox)**
*   **AI Feed:** View list of missions detected from emails.
*   **Mission Cards:** See Title, Address, Urgency (Badge), and AI Summary.
*   **Actions:**
    *   **Swipe to Approve:** Converts Mission -> Intervention.
    *   **Swipe to Reject:** Deletes Mission.
    *   **Edit:** Correct AI-extracted data (e.g., wrong address).

#### **2. Intervention Management**
*   **List View:** Filter by Status (In Progress, Delayed, Completed).
*   **Detail View:** Full access to codes, keys, and tenant contact.
*   **Update Status:**
    *   **Mark Delayed:** Requires selecting a reason + adding a note.
    *   **Mark Completed:** Triggers report generation flow.

#### **3. Reporting & Completion**
*   **Report Builder:**
    *   Auto-filled fields (Address, Dates).
    *   **AI Writing Assistant:** Button to rewrite rough notes into professional text.
    *   **Photos:** Upload "Before/After" images from camera.
*   **Send:** One-tap to email PDF or send via WhatsApp to Syndic.

#### **4. Dashboard & Navigation**
*   **KPIs:** Counters for Pending, Delayed, Completed.
*   **Map:** View all active interventions on a map with route navigation (Waze/Google Maps).

---

### **Role B: SYNDIC (Property Manager / Client)**
*The "Client" mode. Read-only tracking and simple request creation.*

#### **1. Dashboard (My Portfolio)**
*   **Overview:** Simple stats (Active, Delayed, Completed).
*   **Timeline:** Recent activity feed (e.g., "Leak at Rue de la Loi fixed").

#### **2. Request Intervention (Missions)**
*   **New Request Form:**
    *   Subject & Description.
    *   Address (Select from their managed buildings).
    *   Urgency (Low/Normal/Urgent).
    *   *Note: This bypasses the email AI and goes straight to Admin's mission list.*

#### **3. Tracking (Read-Only)**
*   **Intervention List:** View status of their requests.
*   **Restrictions:** Cannot edit details or change status.
*   **Documents:** Download PDF reports and invoices for completed jobs.

---

## 3. Mobile App Architecture (Flutter)

```
lib/
├── core/
│   ├── auth/              # Role-based login (Admin vs Syndic)
│   ├── theme/             # Vanakel Branding (Green/Black)
│   └── api/               # Dio Client + Interceptors
├── features/
│   ├── dashboard/         # KPIs and Charts
│   ├── missions/          # Incoming requests (Admin: Approve/Reject, Syndic: Create)
│   ├── interventions/     # Active jobs list
│   ├── report/            # PDF Generation & AI Rewrite
│   └── profile/           # User settings
└── main.dart
```

---

## 4. Development Roadmap (10 Weeks)

### **Phase 1: Foundation (Weeks 1-2)**
*   **Setup:** Flutter project, CI/CD for iOS/Android.
*   **Auth:** Login screen with Role detection (Admin vs Syndic).
*   **Navigation:** Bottom Tab Bar (changes based on Role).

### **Phase 2: Admin Features (Weeks 3-6)**
*   **Week 3:** Mission List (AI Feed) + Approve/Reject logic.
*   **Week 4:** Intervention Details + Map Integration.
*   **Week 5:** Reporting Module (Photo upload + AI Text Improve).
*   **Week 6:** PDF Generation & Sharing (WhatsApp/Email).

### **Phase 3: Syndic Features (Weeks 7-8)**
*   **Week 7:** Dashboard & Read-only Intervention list.
*   **Week 8:** "Create Request" Form.

### **Phase 4: Polish & Deploy (Weeks 9-10)**
*   **Week 9:** Push Notifications (Status changes, New missions).
*   **Week 10:** App Store & Play Store submission.

---

## 5. Key Technical Requirements
1.  **AI Integration:** Mobile app calls the Backend API to trigger Gemini AI for text rewriting.
2.  **PDF Generation:** PDF is generated on the **Backend** (Laravel) and sent as a link to the mobile app to share.
3.  **Offline Support:** Admin needs to view intervention details (codes/keys) even without internet.
4.  **Maps:** Deep linking to Waze/Google Maps for navigation.
