# Vanakel Group Management Platform - Project Overview

## 1. What is this Project?
**Simple Explanation:**  
The **Vanakel Group Management Platform** is a smart digital system designed to help property managers (Syndics) and maintenance teams (Vanakel Group) take care of buildings efficiently. 

Think of it as a "Control Center" where:
1.  **Residents/Syndics** report problems (like a water leak).
2.  **The System** automatically understands the email using AI.
3.  **Admins** assign the job to a technician.
4.  **Technicians** fix the issue and report back using a mobile app.

It replaces messy spreadsheets, phone calls, and manual emails with one organized system.

---

## 2. Who is it for? (The Users)
There are 4 main types of people who will use this system:

| Role | Who are they? | What do they do? | Platform |
| :--- | :--- | :--- | :--- |
| **ADMIN** | Vanakel Office Staff | They see everything. They dispatch jobs, manage users, and check finances. | **Web Dashboard** |
| **SYNDIC** | Property Managers | They manage specific buildings. They request repairs and approve quotes. | **Web Portal** |
| **PROFESSIONAL** | Technicians / Workers | The people fixing things on-site. They receive their schedule and report work done. | **Mobile App** |
| **CLIENT** | Tenants / Residents | The people living in the building. They get notified when help is coming. | **Email / SMS** |

---

## 3. How does it work? (The Technology)
We are building a modern, fast, and reliable system using three main technologies:

1.  **The Brain (Backend - Laravel):**  
    This is the central computer that stores all data (buildings, users, jobs) and handles the "thinking" (like reading emails automatically).
    
2.  **The Control Center (Web - React):**  
    A website for Admins and Syndics to manage everything on their computers.

3.  **The Field Tool (Mobile - Flutter):**  
    A phone app for technicians to use on the road. It works even if they lose internet connection in a basement!

---

## 4. Key Features
*   **Smart Email Reader:** If a tenant sends an email saying "Urgent leak in the kitchen!", the system's AI reads it, creates a job, and alerts the Admin.
*   **Planning Board:** A calendar to see where every technician is and schedule new jobs easily.
*   **Building Health:** Keeps a history of every repair for every building, so you know if a boiler keeps breaking down.
*   **Instant Reports:** Technicians take "Before" and "After" photos on their phone, and the system automatically sends a professional report to the Syndic.

---

## 5. Estimated Development Timeline
**Total Estimated Time:** 3.5 to 4 Months (approx. 14-16 weeks)

This timeline assumes a small, dedicated team (or one very experienced Full-Stack Developer).

### **Phase 1: The Foundation (Weeks 1-4)**
*   **Goal:** Build the "Brain" of the system.
*   **Tasks:** 
    *   Set up the Database (where data lives).
    *   Create the User System (Login/Logout).
    *   Build the API (how the App talks to the Brain).

### **Phase 2: The Web Platform (Weeks 5-8)**
*   **Goal:** Build the website for Admins and Syndics.
*   **Tasks:**
    *   Create the Dashboard for stats.
    *   Build the "Building Manager" and "Intervention Manager" screens.
    *   Connect the website to the "Brain".

### **Phase 3: The Mobile App (Weeks 9-12)**
*   **Goal:** Build the app for Technicians.
*   **Tasks:**
    *   Create the "My Schedule" screen.
    *   Build the reporting tool (Camera, Notes, Signature).
    *   Make it work offline (no internet).

### **Phase 4: AI & Automation (Weeks 13-14)**
*   **Goal:** Make the system smart.
*   **Tasks:**
    *   Connect the Email Inbox to the system.
    *   Teach the AI to understand repair requests.
    *   Set up automatic notifications.

### **Phase 5: Testing & Launch (Weeks 15-16)**
*   **Goal:** Make sure everything is perfect.
*   **Tasks:**
    *   Test the app on iPhone and Android.
    *   Fix any bugs.
    *   Move everything to the live server.
