# Vanakel Group Management Platform - Mobile App Plan

## 1. Executive Summary
The **Vanakel Mobile App** is the primary tool for **Professionals (Technicians)** in the field. Unlike the Web Dashboard (Admin/Syndic), the Mobile App focuses on **execution**, **reporting**, and **offline reliability**.

**Core Objective:** Empower technicians to view their schedule, navigate to buildings, and complete interventions (with photos & signatures) even without internet access.

---

## 2. Technology Stack (Flutter)

| Component | Technology / Package | Reason |
| :--- | :--- | :--- |
| **Framework** | **Flutter** (Dart) | Single codebase for iOS & Android. |
| **State Management** | **Flutter Riverpod** | Modern, safe, and testable state management. |
| **Navigation** | **GoRouter** | Deep linking support and easy routing logic. |
| **Networking** | **Dio** | Powerful HTTP client with interceptors (good for auth). |
| **Local Database** | **Isar** or **Hive** | Fast NoSQL database for **Offline Mode** caching. |
| **Maps** | **google_maps_flutter** | For viewing intervention locations. |
| **Camera** | **image_picker** | Taking "Before/After" photos. |
| **Signature** | **signature** | Capturing client approval on-screen. |
| **Connectivity** | **connectivity_plus** | Detecting online/offline status. |

---

## 3. App Architecture
We will use a **Clean Architecture** approach to ensure the app is maintainable and scalable.

```
lib/
├── core/                  # Shared utilities (Constants, Theme, Dio Client)
├── data/                  # Data Layer (API calls, Local DB)
│   ├── models/            # JSON serialization (fromJson/toJson)
│   ├── repositories/      # Implementation of data fetching
│   └── sources/           # RemoteDataSource (API), LocalDataSource (DB)
├── domain/                # Business Logic (Entities, UseCases)
│   ├── entities/          # Pure Dart classes (no JSON logic)
│   └── repositories/      # Abstract interfaces
├── presentation/          # UI Layer (Widgets, Screens, Providers)
│   ├── auth/              # Login Screen
│   ├── dashboard/         # Job List, Map View
│   ├── intervention/      # Job Details, Reporting, Camera
│   └── profile/           # User settings
└── main.dart              # Entry point
```

---

## 4. Key Features & Implementation Plan

### **Phase 1: Foundation & Authentication (Week 1)**
*   **Goal:** App can launch, user can log in, and token is stored securely.
*   **Tasks:**
    *   Setup Flutter project structure (Clean Arch folders).
    *   Configure `Dio` client with Interceptors (auto-attach JWT token).
    *   Implement `LoginScreen` with email/password.
    *   Secure storage for Tokens (using `flutter_secure_storage`).

### **Phase 2: The Dashboard & Schedule (Week 2)**
*   **Goal:** Technician can see their assigned jobs for the day.
*   **Tasks:**
    *   Create `InterventionListScreen` (Tabs: Today, Upcoming, History).
    *   Fetch interventions from API (`GET /api/my-interventions`).
    *   Implement "Pull to Refresh".
    *   Add basic Google Maps view showing markers for today's jobs.

### **Phase 3: Job Execution & Reporting (Week 3)**
*   **Goal:** Complete the full workflow of a job.
*   **Tasks:**
    *   **Job Detail Screen:** Show address, access codes (hidden by default), and tenant contact.
    *   **Status Workflow:** Buttons for "Start Travel", "Start Work", "Complete".
    *   **Photo Upload:** Use camera to take pictures -> Upload to S3/Server.
    *   **Signature Pad:** Capture client signature and save as image.

### **Phase 4: Offline-First Mode (Week 4)**
*   **Goal:** App works in basements with no signal.
*   **Tasks:**
    *   **Caching:** When online, save all today's jobs to `Isar`/`Hive`.
    *   **Queue System:** If offline, save "Job Completed" actions to a local queue.
    *   **Background Sync:** When internet returns, flush the queue (upload photos/data).

### **Phase 5: Polish & Testing (Week 5)**
*   **Goal:** Production ready.
*   **Tasks:**
    *   Push Notifications (Firebase FCM) for new job assignments.
    *   Error handling (User friendly toasts).
    *   Unit Tests for logic (Repositories/Providers).
    *   Build & Release (APK / TestFlight).

---

## 5. Development Roadmap

| Sprint | Focus | Deliverable |
| :--- | :--- | :--- |
| **Sprint 1** | **Setup & Auth** | Login works, Token saved, App Structure ready. |
| **Sprint 2** | **Jobs List** | See list of jobs, Filter by date, Map view. |
| **Sprint 3** | **Job Details** | View full info, Click-to-call, Navigate button. |
| **Sprint 4** | **Reporting** | Take Photos, Sign, Submit Report. |
| **Sprint 5** | **Offline Mode** | Caching & Sync logic. |

---

## 6. Next Steps for You
Since you have the Flutter project open:
1.  **Add Dependencies:** Open `pubspec.yaml` and add the packages listed in Section 2.
2.  **Create Folders:** Create the `core`, `data`, `domain`, `presentation` folder structure in `lib/`.
3.  **Start Coding:** Begin with `presentation/auth/login_screen.dart`.
