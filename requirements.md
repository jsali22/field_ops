Project Requirements: FieldOps
Developer: Jack Salinas
Description: FieldOps is a mobile-first project operations dashboard designed specifically for small and mid-sized contractors. 

------------------------------------------------------------------------------------
Phase 1: Project Setup & Core Infrastructure

- Step 1.1:
    - Dependencies added to pubspec.yaml (Riverpod, Firebase Core, Firebase Auth, and Shared Preferences)
    - Firebase initialized
    - Theme created in lib/theme.dart

- Step 1.2:
    - Folder structure created (models, screens, widgets, services, providers).
    - ProviderScope added
    - Splash screen placeholder created

------------------------------------------------------------------------------------
Phase 2: Project Setup & Core Infrastructure

Goal: Users can create and manage multiple projects, select an active project, and record daily labor/material logs that persist in the cloud and sync across devices.

- Step 2.1 — Core Data Models
    - Define model classes in /models:
        - Project (id, name, client?, address?, createdAt, updatedAt)
        - LaborEntry (id, projectId, date, role/task, hours, hourlyRate, notes?, createdAt)
        - MaterialEntry (id, projectId, date, name, quantity, unitCost, vendor?, notes?, createdAt)
    - Include serialization helpers (toMap/fromMap) for database storage.
    - Notes:
        - This should establish the “data contract” for the entire app.

- Step 2.2 — Database Service (Cloud Persistence Layer)
    - Create /services/database_service.dart that can:
        - Create a project
        - Stream all projects for the current user
        - Create labor entry (under a project)
        - Stream labor entries for a project
        - Create material entry (under a project)
        - Stream material entries for a project
        - Data stored in cloud so it syncs across devices.
    - Notes:
        - Keep the service UI-free.
        - Use streams for “live updates”.

- Step 2.3 — Riverpod Providers (Business Logic Layer)
    - providers contains:
        - database_service_provider
        - projects_provider (stream of projects)
        - selected_project_provider (active project state)
        - labor_entries_provider(projectId)
        - material_entries_provider(projectId)
    - UI reads data only through providers.

- Step 2.4 — Project List Screen + Create Project Flow
    - Screen: ProjectsScreen
        - Shows list of projects (from provider)
        - Button to create a new project
    - Screen/modal: CreateProjectScreen (or dialog)
        - Creates a project in the cloud
        - Returns to project list
    - Acceptance criteria
        - Creating a project updates the list immediately (no restart).

- Step 2.5 — Project Dashboard (Choose Project)
    - Screen: ProjectDashboardScreen
        - Loads when user taps a project
        - Sets selected project state
        - Shows two sections/tabs:
            - Labor Logs
            - Material Logs
    - Shows basic summary counts (e.g., entries today / this week).

- Step 2.6 — Add Labor Log (Daily Log Entry)
    - Screen/modal: AddLaborEntryScreen
        - Create labor entry for selected project
    - Labor list widget:
        - Displays entries by date
        - Live updates via provider stream
    - Acceptance criteria
        - Add entry → appears immediately on dashboard.

- Step 2.7 — Add Material Log (Daily Log Entry)
    - Screen/modal: AddMaterialEntryScreen
        - Create material entry for selected project
    - Material list widget:
        - Displays entries by date
        - Live updates via provider stream
    - Acceptance criteria
        - Add entry → appears immediately on dashboard.

- Step 2.8 — Minimal Navigation Shell
    - Define navigation routes / flow:
        - Projects list → dashboard → add entry screens
    - Ensure “back” behavior is intuitive.

*Optional MVP Stretch (Only if ahead)*

- Step 2.9 — Edit/Delete Entries (Moved to Step 3.8)
    - Allow editing and deleting labor/material entries

- Step 2.10 — Basic “Today” Summary (Implemented up to this point)
    - Show totals for today: total hours, labor cost estimate, material cost estimate

-------------------------------------------------------------------------------------- 
Phase 3: Milestone 2 — Full Integration & Polish

Goal: Replace the temporary anonymous-auth bootstrap with a proper authentication flow, secure project ownership around authenticated users, and complete the cloud-backed architecture with polished UI/state handling.

- Step 3.1 — Auth Service Foundation
	- Create /services/auth_service.dart
	- Add methods for:
	•	authStateChanges()
	•	signInAnonymously() (can remain as fallback if desired)
	•	signInWithEmailPassword(...)
	•	registerWithEmailPassword(...)
	•	signOut()
	- Keep the service UI-free.
	- Notes:
	•	This establishes the authentication layer before building screens.

- Step 3.2 — Auth Providers
	- Create /providers/auth_providers.dart
	- Add Riverpod providers for:
	•	auth_service_provider
	•	auth_state_provider (stream of current auth state)
	- Notes:
	•	UI should consume auth state through providers, not Firebase directly.

- Step 3.3 — Login Screen
	- Create LoginScreen
	- Allow user to:
	•	enter email
	•	enter password
	•	sign in
	•	navigate to registration
	- Handle loading and error states cleanly.
	- Notes:
	•	Keep styling simple at first.

- Step 3.4 — Registration Screen
	- Create RegistrationScreen
	- Allow user to:
	•	enter email
	•	enter password
	•	create account
	- Validate input and handle auth errors cleanly.
	- Notes:
	•	Reuse styling patterns from LoginScreen where possible.

- Step 3.5 — Second Authentication Provider
	- Add a second auth method beyond email/password
	- Preferred option:
	•	Google Sign-In
	- Alternative if needed:
	•	keep Anonymous Auth as a supported option if acceptable for the course
	- Notes:
	•	This satisfies the “more than basic Email/Password” requirement.

- Step 3.6 — Auth Gate
	- Create AuthGate widget
	- Behavior:
	•	if user is null → show LoginScreen
	•	else → show ProjectsScreen
	- Replace the temporary startup auth bootstrap with this flow.
	- Notes:
	•	This becomes the top-level routing logic for the app.

- Step 3.7 — User Ownership Hardening
	- Ensure all project/labor/material records remain scoped to authenticated user ownership
	- Verify ownerUid / user-scoped collection structure is applied consistently
	- Remove any temporary assumptions from MVP that are no longer needed
	- Notes:
	•	This hardens the architecture around real user accounts.

- Step 3.8 — CRUD Completion for Core Models
	- Add edit/delete support for:
	•	projects
	•	labor entries
	•	material entries
	- Keep flows simple and safe
	- Notes:
	•	This completes the CRUD requirement for milestone 2.

------------------------------------------------------------------------------------
Phase 4: Polish, Persistence, and Presentation

Goal: Refine the MVP into a cohesive, polished application ready for final presentation. Focus on visual design, user experience, stability, and code cleanup.

- Step 4.1: App Theming & Visual Identity
	- Define a consistent color palette (primary, secondary, background)
	- Apply theme across:
	- AppBar
	- Buttons (Elevated, Outlined, Text)
	- Input fields
	- Cards and lists
	- Improve spacing, typography, and visual hierarchy
	- Ensure UI feels cohesive and intentional

Notes:
• High-visibility improvement for presentation  
• Should not require major layout redesign  

- Step 4.2: Local Persistence (Shared Preferences)
	- Implement a small persistent feature, such as:
	- Dark mode toggle OR
	- “Remember user preference” setting
	- Store preference locally using SharedPreferences
	- Load preference at app startup and apply automatically

Notes:
• Demonstrates local state persistence 
• Should integrate cleanly with app theme  

- Step 4.3: Async Loading & Error State Cleanup
	- Review all async flows in the app
	- Ensure consistent use of:
	- AsyncValue.when() for providers
	- Loading indicators
	- User-friendly error messages
	- Verify dialogs and screens handle loading states properly
	- Remove any inconsistent or missing states

Notes:
• Focus on stability and UX consistency  
• No new features required  

- Step 4.4: Comment & Code Cleanup
	- Remove excessive or redundant inline comments
	- Keep only meaningful, high-level explanations
	- Ensure consistent naming conventions
	- Improve readability and organization

Notes:
• Code should feel clean and professional  
• Prepare for final review and presentation  

- Step 4.5: Widget Refactoring & File Organization
	- Identify large files (>200–300 lines)
	- Extract reusable widgets where appropriate
	- Separate UI sections into smaller components
	- Maintain clear separation between UI, providers, and services

Notes:
• Improves maintainability and clarity  
• Helps during final walkthrough  

- Step 4.6: UI & UX Polish
	- Improve layout consistency across screens:
	- Projects list
	- Dashboard
	- Dialogs
	- Add subtle visual improvements:
	- Icons where appropriate
	- Better spacing and grouping
	- Ensure navigation flow feels smooth and intuitive:
	Login → Projects → Dashboard → CRUD actions

Notes:
• Focus on making the app feel like a real product  
• Avoid overcomplicating UI  

- Step 4.7: Final Presentation Readiness
	- Remove debug/test scaffolding
	- Ensure all flows work end-to-end:
	- Authentication
	- Project CRUD
	- Labor/material CRUD
	- Fix minor UI inconsistencies
	- Prepare demo-ready state of the app

Notes:
• Final sanity pass before presentation  
• Prioritize stability over new features  

--------------------------------------------------------------------------------------

- Implementation Notes (Guardrails)
    - No complex analytics until Phase 3.
    - Keep screens thin; extract widgets (lists/cards/forms) into /widgets.
    - Use Riverpod providers for all data flow.
    - Use AsyncValue.when() on data streams.

------------------------------------------------------------------------------------

AI Assistant Guardrails
Codex: When reading this file to implement a step, you MUST adhere to the following architectural rules:
1. State Management: Use flutter_riverpod exclusively. Do not use setState for complex logic.
2. Architecture: Maintain strict separation of concerns:
● /models: Pure Dart data classes (use json_serializable or freezed if helpful).
● /services: Backend/API communication only. No UI code.
● /providers: Riverpod providers linking services to the UI.
● /screens & /widgets: UI only. Keep files small. Extract complex widgets into their own files.
3. Local Storage: Use shared_preferences for local app state (e.g., theme toggles, onboarding
status).
4. Database: Use [Firebase Firestore OR PostgreSQL] for persistent cloud data.
5. Stepwise Execution: Only implement the specific step requested in the prompt. Do not jump ahead.
6. File Size Limit: Avoid creating very large files. If a file grows beyond ~200 lines,
extract reusable widgets or logic into separate files.
7. Do not modify REQUIREMENTS.md or PROMPTS.md unless explicitly asked.

------------------------------------------------------------------------------------