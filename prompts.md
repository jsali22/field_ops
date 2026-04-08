**ColdStart**

# PROMPTS.md

## Prompt 1
Create a simple SplashScreen in lib/screens/splash_screen.dart.

## Prompt 2
Read REQUIREMENTS.md and implement Step 2.1 only.

Follow all AI Assistant Guardrails in REQUIREMENTS.md.

Implement the core data models for the app in the /models directory:
- Project
- LaborEntry
- MaterialEntry

Requirements:
- Create one file per model in lib/models
- Keep these as pure Dart data classes only
- Include constructors
- Include copyWith methods if appropriate
- Include Firestore-friendly serialization helpers (toMap/fromMap)
- Support optional fields where indicated in REQUIREMENTS.md
- Use DateTime in the Dart models and serialize appropriately for Firestore
- Do not implement services, providers, screens, or widgets yet
- Do not modify unrelated files
- Do not jump ahead to future steps

## Prompt 3
Read REQUIREMENTS.md and implement only the first part of Step 2.2.

Follow all AI Assistant Guardrails in REQUIREMENTS.md.

Task:
Create lib/services/database_service.dart and implement only the project-related cloud persistence methods for now.

Requirements:
- Keep the service UI-free
- Use Cloud Firestore
- Use streams for live updates
- Assume projects are stored under:
  users/{uid}/projects/{projectId}
- The service should support:
  1. createProject(Project project)
  2. streamProjectsForCurrentUser()
- Use FirebaseAuth to determine the current authenticated user
- Return typed Project objects, not raw maps
- Do not implement labor entry or material entry methods yet
- Do not implement providers or screens yet
- Do not modify unrelated files

## Prompt 4
Read REQUIREMENTS.md and implement only the project-related portion of Step 2.3.

Follow all AI Assistant Guardrails in REQUIREMENTS.md.

Task:
Create the Riverpod providers needed to expose project data from DatabaseService to the UI layer.

Implement only these providers inside the /providers directory:
1. database_service_provider
   - Provides a singleton instance of DatabaseService

2. projects_provider
   - A StreamProvider<List<Project>>
   - Uses DatabaseService.streamProjectsForCurrentUser()
   - Exposes a live list of projects for the authenticated user

3. selected_project_provider
   - A StateProvider<Project?>
   - Holds the currently selected project in app state

Constraints:
- Providers must not contain UI code
- Providers must communicate with DatabaseService instead of Firestore directly
- Use flutter_riverpod
- Maintain strict separation of concerns
- Do not implement labor_entries_provider or material_entries_provider yet
- Do not modify DatabaseService unless absolutely necessary for imports only
- Do not implement screens or widgets yet
- Do not modify unrelated files

## Prompt 5
Read REQUIREMENTS.md and implement only Step 2.4 for the project list screen and create project flow.

Follow all AI Assistant Guardrails in REQUIREMENTS.md.

Task:
Create the UI needed to display the current user’s projects and create a new project in the cloud.

Requirements:
1. Create a ProjectsScreen in /screens
   - Shows the live list of projects from projects_provider
   - Includes a button to create a new project
   - Uses Riverpod to read data
   - Handles loading and error states cleanly

2. Create a CreateProject dialog or screen
   - Allows the user to enter a project name
   - Optionally include client and address fields if easy to support now
   - Creates a Project and saves it using the existing DatabaseService flow
   - Returns to the project list after creation

3. Acceptance criteria
   - Creating a project updates the list immediately with no restart
   - UI must not communicate directly with Firestore
   - All data access must go through Riverpod providers and/or DatabaseService

Constraints:
- Keep files small and focused
- Extract reusable UI pieces if needed
- Do not implement project detail, labor entry, or material entry screens yet
- Do not jump ahead to future steps
- Keep this implementation focused only on the project list + create flow

## Prompt 6
Implement Step 2.5 — Project Dashboard (Choose Project) from REQUIREMENTS.md.

Goal:
Create a ProjectDashboardScreen that loads when a user taps a project and displays basic project information along with placeholders for Labor Logs and Material Logs.

Requirements:

1. Create a new screen:
   - File: /screens/project_dashboard_screen.dart
   - Widget: ProjectDashboardScreen (ConsumerWidget)

2. Behavior:
   - The screen must read the currently selected project from selected_project_provider.
   - If no project is selected, display a simple fallback UI (e.g., "No project selected").

3. UI Structure:
   - AppBar displaying the project name
   - Body containing:
     a) A simple header section showing:
        - Project name
        - Optional client and address if available

     b) Two sections (can be simple cards or containers):
        - "Labor Logs"
        - "Material Logs"

     Each section should:
        - Display a title
        - Include a placeholder message like "No entries yet"
        - Include a button:
            - "Add Labor Entry"
            - "Add Material Entry"

     (These buttons do NOT need to navigate yet — just leave TODO comments)

4. Navigation:
   - Modify ProjectsScreen:
     - When a project is tapped:
        a) Update selected_project_provider
        b) Navigate to ProjectDashboardScreen using Navigator.push

5. Constraints:
   - Do NOT implement labor/material data fetching yet
   - Do NOT implement forms yet
   - Keep UI simple and clean
   - Maintain separation of concerns (no direct Firebase usage here)

## Prompt 7
Implement Step 2.6 — Add Labor Log (Daily Log Entry) from REQUIREMENTS.md.

Goal:
Allow users to create labor entries for the selected project and display them live on the ProjectDashboardScreen using Riverpod and Firestore streams.

Requirements:

1. Database Service Updates:
   - Extend /services/database_service.dart with:
     a) createLaborEntry(LaborEntry entry)
     b) streamLaborEntriesForProject(String projectId)

   - Store labor entries under:
     users/{uid}/projects/{projectId}/labor_entries/{entryId}

   - streamLaborEntriesForProject should return Stream<List<LaborEntry>> ordered by date (descending)

2. Providers:
   - Create labor_entries_provider inside /providers (or extend existing file)
   - Type: StreamProvider.family<List<LaborEntry>, String>
   - It should call DatabaseService.streamLaborEntriesForProject(projectId)

3. Add Labor Entry UI:
   - Create a simple dialog:
     File: /screens/add_labor_entry_dialog.dart

   - Fields:
     - Role/Task (String, required)
     - Hours (double, required)
     - Hourly Rate (double, required)
     - Optional notes

   - On submit:
     - Get selected project from selected_project_provider
     - Create LaborEntry object
     - Call createLaborEntry via database_service_provider
     - Close dialog

4. Dashboard Integration:
   - In ProjectDashboardScreen:
     a) Replace "Labor Logs" placeholder with:
        - A list of labor entries from labor_entries_provider(projectId)
     b) Use AsyncValue.when() for loading/error/data
     c) Show entries (simple ListTile is fine)

   - Wire "Add Labor Entry" button:
     - Open AddLaborEntryDialog

5. Constraints:
   - Do NOT implement edit/delete
   - Keep UI simple
   - Do NOT add unnecessary complexity
   - Maintain separation of concerns (no direct Firebase calls in UI)

6. Acceptance Criteria:
   - Add labor entry → appears immediately in dashboard
   - Data persists in Firestore
   - UI updates via stream (no refresh needed)

## Prompt 8
Implement Step 2.7 — Add Material Log (Daily Log Entry) from REQUIREMENTS.md.

Goal:
Allow users to create material entries for the selected project and display them live on the ProjectDashboardScreen using Riverpod and Firestore streams.

Requirements:

1. Database Service Updates:
   - Extend /services/database_service.dart with:
     a) createMaterialEntry(MaterialEntry entry)
     b) streamMaterialEntriesForProject(String projectId)

   - Store material entries under:
     users/{uid}/projects/{projectId}/material_entries/{entryId}

   - streamMaterialEntriesForProject should return Stream<List<MaterialEntry>> ordered by date (descending)

2. Providers:
   - Add material_entries_provider inside /providers
   - Type: StreamProvider.family<List<MaterialEntry>, String>
   - It should call DatabaseService.streamMaterialEntriesForProject(projectId)

3. Add Material Entry UI:
   - Create a simple dialog:
     File: /screens/add_material_entry_dialog.dart

   - Fields:
     - Name (String, required)
     - Quantity (double, required)
     - Unit Cost (double, required)
     - Optional vendor
     - Optional notes

   - On submit:
     - Get selected project from selected_project_provider
     - Create MaterialEntry object
     - Call createMaterialEntry via database_service_provider
     - Close dialog

4. Dashboard Integration:
   - In ProjectDashboardScreen:
     a) Replace the "Material Logs" placeholder with:
        - A list of material entries from material_entries_provider(projectId)
     b) Use AsyncValue.when() for loading/error/data
     c) Show entries with simple ListTile UI

   - Wire "Add Material Entry" button:
     - Open AddMaterialEntryDialog

5. Constraints:
   - Do NOT implement edit/delete
   - Keep UI simple
   - Do NOT add unnecessary complexity
   - Maintain separation of concerns (no direct Firebase calls in UI)

6. Acceptance Criteria:
   - Add material entry → appears immediately on dashboard
   - Data persists in Firestore
   - UI updates via stream (no refresh needed)

## Prompt 9
Fix the Riverpod build error in project_providers.dart.

Current issue:
The build fails with:
"Method not found: 'StateProvider'"

Goal:
Replace selected_project_provider with a Riverpod provider implementation that works with the current flutter_riverpod version in this project.

Requirements:
1. Modify only the provider code needed for selected_project_provider.
2. Keep database_service_provider and projects_provider unchanged unless imports need adjustment.
3. Replace StateProvider<Project?> with a small Notifier-based provider that:
   - stores the currently selected Project?
   - has an initial value of null
   - allows the UI to update the selected project through the notifier
4. Update any existing usages only if necessary to match the new notifier API.
5. Do not modify unrelated architecture or UI behavior.

## Prompt 10
Implement Step 2.8 — Minimal Navigation Shell from REQUIREMENTS.md.

Goal:
Make the current MVP navigation flow feel intentional and intuitive, without adding major new features.

Requirements:

1. Review the current navigation flow:
   - Projects list screen
   - Project dashboard screen
   - Create project dialog
   - Add labor entry dialog
   - Add material entry dialog

2. Improve the navigation shell so that:
   - ProjectsScreen is the clear entry point of the app
   - Tapping a project navigates cleanly to ProjectDashboardScreen
   - Back navigation from ProjectDashboardScreen returns to ProjectsScreen naturally
   - Opening and closing dialogs feels consistent
   - There are no unnecessary navigation layers or duplicate flows

3. ProjectDashboardScreen should feel like a proper second-level screen:
   - Keep the AppBar and back behavior intuitive
   - Ensure selected_project_provider is still used correctly

4. Dialog behavior:
   - Keep CreateProjectDialog, AddLaborEntryDialog, and AddMaterialEntryDialog as dialogs
   - Do not convert them to full screens unless absolutely necessary
   - If there are obvious navigation or dismissal improvements, make them

5. Constraints:
   - Do NOT implement new major features
   - Do NOT add authentication
   - Do NOT implement edit/delete
   - Do NOT refactor unrelated architecture
   - Keep this focused on navigation flow and usability polish only

6. Desired outcome:
   - The app should feel like:
     Projects list → Project dashboard → add entry dialogs
   - Back behavior should be intuitive and consistent
   - The existing MVP should feel more cohesive

## Prompt 11
Implement Step 2.10 — Basic “Today” Summary from REQUIREMENTS.md.

Goal:
Add a simple summary section to ProjectDashboardScreen that shows today's totals for the selected project:
- total labor hours today
- labor cost estimate today
- material cost estimate today

Requirements:

1. Add a new summary section to ProjectDashboardScreen near the top of the dashboard, below the project header.

2. The summary should use the existing live data sources already available in the app:
   - labor_entries_provider(projectId)
   - material_entries_provider(projectId)

3. Compute only today’s totals:
   - total labor hours today = sum of LaborEntry.hours where entry.date is today
   - labor cost estimate today = sum of (hours * hourlyRate) for today’s labor entries
   - material cost estimate today = sum of (quantity * unitCost) for today’s material entries

4. UI requirements:
   - Keep the summary UI simple and clean
   - A card or small set of summary tiles is fine
   - Clearly label each metric
   - Format currency reasonably (simple string formatting is fine; no need for intl package)

5. State handling:
   - Use Riverpod and AsyncValue.when()
   - Handle loading and error states cleanly
   - Do not duplicate Firestore logic in the UI

6. Constraints:
   - Do NOT add new database methods if existing providers already expose the needed data
   - Do NOT implement weekly/monthly analytics
   - Do NOT over-engineer the summary
   - Keep the implementation focused only on “today” totals
   - Maintain separation of concerns

7. Desired outcome:
   - The dashboard looks more complete and informative
   - Summary updates automatically when labor/material entries are added

## Prompt 12
Implement Step 3.1 — Auth Service Foundation from REQUIREMENTS.md.

Goal:
Create the authentication service layer for the app so future login/register/auth-gate flows can be built on top of it.

Requirements:

1. Create /services/auth_service.dart

2. Implement an AuthService class that uses FirebaseAuth and provides:
   - authStateChanges()
   - signInAnonymously()
   - signInWithEmailPassword(String email, String password)
   - registerWithEmailPassword(String email, String password)
   - signOut()

3. Keep the service UI-free:
   - no widgets
   - no navigation
   - no snackbar/dialog code

4. Return Firebase user/auth results in a clean, simple way appropriate for later provider usage.
   - Throw meaningful exceptions or surface FirebaseAuthException clearly enough for the UI layer to handle later.

5. Constraints:
   - Do NOT create screens yet
   - Do NOT create AuthGate yet
   - Do NOT modify unrelated files
   - Keep this step focused only on the service layer
------------------------------------------------------------------------------------
