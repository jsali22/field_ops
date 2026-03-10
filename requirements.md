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


Optional MVP Stretch (Only if ahead)
- Step 2.9 — Edit/Delete Entries
    - Allow editing and deleting labor/material entries

- Step 2.10 — Basic “Today” Summary
    - Show totals for today: total hours, labor cost estimate, material cost estimate

-------------------------------------------------------------------------------------- Phase 3: Full CRUD + user ownership + security rules + deeper integration + auth-gating

- Phase 2 uses basic cloud persistence; Phase 3 hardens it with authentication-based ownership, security rules, and full CRUD.

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