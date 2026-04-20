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

## Prompt 13
Implement Step 3.2 — Auth Providers from REQUIREMENTS.md.

Goal:
Create Riverpod providers for the authentication layer so the UI can access AuthService and reactively listen to Firebase auth state changes.

Requirements:

1. Create /providers/auth_providers.dart

2. Add the following providers:

   a) auth_service_provider
   - Type: Provider<AuthService>
   - Provides a singleton-style instance of AuthService

   b) auth_state_provider
   - Type: StreamProvider<User?>
   - Uses AuthService.authStateChanges()
   - Exposes the live Firebase authentication state to the UI

3. Constraints:
   - Keep providers UI-free
   - Do not create screens yet
   - Do not create AuthGate yet
   - Do not modify unrelated files
   - Follow the same provider architecture style used in project_providers.dart

4. Notes:
   - The UI should later consume authentication state through auth_state_provider
   - Do not add login or registration logic in this step
   - Do not move FirebaseAuth usage directly into widgets

## Prompt 14
Implement Step 3.3 — Login Screen from REQUIREMENTS.md.

Goal:
Create a LoginScreen that allows a user to sign in with email and password using the existing AuthService and Riverpod auth providers.

Requirements:

1. Create a new file:
   - /screens/login_screen.dart

2. Build a LoginScreen UI that includes:
   - email TextFormField
   - password TextFormField
   - sign in button
   - a secondary action/button to navigate to a future RegistrationScreen
     (this can be a placeholder callback or TODO for now if RegistrationScreen does not exist yet)

3. Form behavior:
   - validate that email is not empty and looks like an email
   - validate that password is not empty
   - show loading state while sign-in is in progress
   - disable inputs/buttons while loading

4. Authentication behavior:
   - use auth_service_provider through Riverpod
   - call signInWithEmailPassword(email, password)
   - do not call FirebaseAuth directly in the widget
   - catch/auth errors in the UI layer and display a simple error message or SnackBar

5. Widget/state architecture:
   - use ConsumerStatefulWidget if needed for form controllers and loading state
   - keep logic reasonably small and readable
   - keep files focused and do not over-engineer

6. Constraints:
   - Do NOT implement RegistrationScreen yet
   - Do NOT implement AuthGate yet
   - Do NOT modify unrelated files unless a small navigation placeholder is needed
   - Do NOT replace the current app startup flow yet
   - Keep this step focused only on the login screen UI and sign-in flow

7. Desired outcome:
   - The app now has a clean LoginScreen that can sign in an existing email/password user
   - The screen is ready to be connected to RegistrationScreen and AuthGate in later steps

## Prompt 15
Implement Step 3.4 — Registration Screen from REQUIREMENTS.md.

Goal:
Create a RegistrationScreen that allows a user to create an account with email and password using the existing AuthService and Riverpod auth providers.

Requirements:

1. Create a new file:
   - /screens/registration_screen.dart

2. Build a RegistrationScreen UI that includes:
   - email TextFormField
   - password TextFormField
   - confirm password TextFormField
   - primary “Create Account” button
   - secondary action/button to return to LoginScreen later
     (this can be a placeholder callback or TODO if LoginScreen navigation is not wired yet)

3. Form behavior:
   - validate that email is not empty and looks like an email
   - validate that password is not empty
   - validate that confirm password matches password
   - show loading state while registration is in progress
   - disable inputs/buttons while loading

4. Authentication behavior:
   - use auth_service_provider through Riverpod
   - call registerWithEmailPassword(email, password)
   - do not call FirebaseAuth directly in the widget for registration
   - catch/auth errors in the UI layer and display a simple error message or SnackBar

5. Widget/state architecture:
   - use ConsumerStatefulWidget for form controllers and loading state
   - keep logic reasonably small and readable
   - keep files focused and do not over-engineer

6. Constraints:
   - Do NOT implement AuthGate yet
   - Do NOT replace the current app startup flow yet
   - Do NOT modify unrelated files unless a small placeholder action is needed
   - Keep this step focused only on the registration screen UI and create-account flow

7. Desired outcome:
   - The app now has a clean RegistrationScreen that can create a new email/password user
   - The screen is ready to be connected to LoginScreen and AuthGate in later steps

## Prompt 16
Implement Step 3.5 — Second Authentication Provider from REQUIREMENTS.md.

Goal:
Add anonymous sign-in as a second supported authentication method by exposing it through the existing LoginScreen and AuthService architecture.

Requirements:

1. Update LoginScreen so it offers two authentication actions:
   - Sign in with email/password
   - Continue as Guest (anonymous sign-in)

2. Anonymous sign-in behavior:
   - Use auth_service_provider through Riverpod
   - Call AuthService.signInAnonymously()
   - Do not call FirebaseAuth directly in the widget
   - Reuse the existing loading/error handling pattern as much as possible

3. UI behavior:
   - Keep the current email/password login form intact
   - Add a clearly labeled secondary action/button for guest access
   - Disable actions appropriately while loading

4. Architecture constraints:
   - Do not implement AuthGate yet
   - Do not replace the current app startup flow yet
   - Do not modify unrelated files unless needed for this specific auth option
   - Keep the step focused on adding a second auth method cleanly to the existing login flow

5. Desired outcome:
   - The app now supports more than one authentication method
   - LoginScreen demonstrates both email/password sign-in and anonymous sign-in
   - The implementation remains consistent with the existing service/provider architecture

## Prompt 17
Implement Step 3.6 — AuthGate from REQUIREMENTS.md.

Goal:
Add an AuthGate that listens to authentication state through Riverpod and controls the app’s startup flow:
- if user == null → show LoginScreen
- else → show ProjectsScreen

Requirements:

1. Create a new file:
   - /screens/auth_gate.dart

2. AuthGate behavior:
   - AuthGate must be a ConsumerWidget
   - It must read auth_state_provider
   - It must use AsyncValue.when() to handle:
     - loading
     - error
     - data

3. Routing behavior:
   - if auth_state_provider resolves to null → show LoginScreen
   - if auth_state_provider resolves to a User → show ProjectsScreen

4. Startup integration:
   - Update app startup flow so the app shows AuthGate instead of directly launching ProjectsScreen
   - Remove the temporary anonymous-auth bootstrap from main.dart
   - Do not leave both systems active at the same time

5. Login / Registration connection:
   - Replace the placeholder navigation between LoginScreen and RegistrationScreen with real navigation
   - LoginScreen should be able to navigate to RegistrationScreen
   - RegistrationScreen should be able to navigate back to LoginScreen
   - Keep navigation simple and intuitive

6. Constraints:
   - Do NOT implement new auth methods
   - Do NOT modify AuthService unless absolutely necessary
   - Do NOT implement CRUD in this step
   - Keep this focused on auth flow and startup routing only
   - Maintain separation of concerns

7. Desired outcome:
   - App startup is now controlled by auth state
   - Signed-out users see LoginScreen
   - Signed-in users see ProjectsScreen
   - Login and Registration screens can navigate between each other
   - Temporary startup anonymous-auth logic is removed

## Prompt 18
Implement Step 3.7 — User Ownership Hardening from REQUIREMENTS.md.

Goal:
Harden the data layer so project and entry ownership consistently aligns with the authenticated user now that AuthGate and the auth flow are in place.

Requirements:

1. Review the current ownership assumptions across:
   - project creation flow
   - labor entry creation flow
   - material entry creation flow
   - DatabaseService Firestore paths
   - Project model ownership fields

2. Ensure user ownership is applied consistently:
   - Firestore reads/writes must remain scoped under users/{uid}/...
   - Project ownership should reliably reflect the authenticated user
   - Labor and material entries should remain tied to the currently selected project under the authenticated user’s project collection

3. Clean up ownership-related logic where appropriate:
   - If ownership assignment is currently happening in the UI in a way that should live in the service layer, improve that
   - Avoid unnecessary duplication of user ownership logic across widgets
   - Keep the architecture consistent with:
     models → services → providers → UI

4. Constraints:
   - Do NOT implement CRUD UI yet
   - Do NOT add new auth methods
   - Do NOT implement Firestore security rules in this step
   - Do NOT over-refactor unrelated code
   - Keep this step focused on ownership consistency and authenticated-user data flow

5. Desired outcome:
   - The app’s data layer is clearly tied to the signed-in user
   - Ownership-related assumptions are cleaner and more consistent
   - The architecture is better prepared for CRUD and final polish

## Prompt 19
Implement Step 3.8 (CRUD) — Delete Labor Entry.

Goal:
Allow users to delete a labor entry from the project dashboard, updating both Firestore and the UI in real time.

Requirements:

1. DatabaseService:
   - Add a new method:
     deleteLaborEntry(String projectId, String entryId)
   - It should:
     - retrieve the current authenticated user UID
     - delete the document at:
       users/{uid}/projects/{projectId}/labor_entries/{entryId}

2. Providers:
   - Do NOT create new providers
   - Continue using labor_entries_provider(projectId)
   - The existing stream should automatically update after deletion

3. UI (Project Dashboard):
   - Update the labor entries list UI
   - Each labor entry should include a delete action (choose one):
     - trailing delete icon (IconButton), OR
     - long press → delete

4. Delete behavior:
   - When delete is triggered:
     - show a confirmation dialog:
       “Are you sure you want to delete this labor entry?”
     - If confirmed:
       - call deleteLaborEntry(...) through database_service_provider
     - If canceled:
       - do nothing

5. UX constraints:
   - Keep UI simple (no animations or advanced gestures)
   - Do not redesign the layout
   - Keep consistency with existing Material components

6. Architecture constraints:
   - UI must call DatabaseService via Riverpod
   - Do NOT call Firestore directly in widgets
   - Do NOT modify unrelated files
   - Do NOT implement edit/update yet

7. Desired outcome:
   - User can delete a labor entry from the dashboard
   - Entry disappears immediately due to stream update
   - Ownership remains enforced through DatabaseService

## Prompt 20
Implement Step 3.8 (CRUD) — Delete Material Entry.

Goal:
Allow users to delete a material entry from the project dashboard, updating both Firestore and the UI in real time.

Requirements:

1. DatabaseService:
   - Add a new method:
     deleteMaterialEntry(String projectId, String entryId)
   - It should:
     - retrieve the current authenticated user UID
     - delete the document at:
       users/{uid}/projects/{projectId}/material_entries/{entryId}

2. Providers:
   - Do NOT create new providers
   - Continue using material_entries_provider(projectId)
   - The existing stream should automatically update after deletion

3. UI (Project Dashboard):
   - Update the material entries list UI
   - Each material entry should include a delete action (choose one):
     - trailing delete icon (IconButton), OR
     - long press → delete

4. Delete behavior:
   - When delete is triggered:
     - show a confirmation dialog:
       “Are you sure you want to delete this material entry?”
     - If confirmed:
       - call deleteMaterialEntry(...) through database_service_provider
     - If canceled:
       - do nothing

5. UX constraints:
   - Keep UI simple
   - Do not redesign the layout
   - Keep consistency with the labor entry delete flow

6. Architecture constraints:
   - UI must call DatabaseService via Riverpod
   - Do NOT call Firestore directly in widgets
   - Do NOT modify unrelated files
   - Do NOT implement edit/update yet

7. Desired outcome:
   - User can delete a material entry from the dashboard
   - Entry disappears immediately due to stream update
   - Ownership remains enforced through DatabaseService

## Prompt 21
Implement Step 3.8 (CRUD) — Edit Labor and Material Entries.

Goal:
Allow users to edit existing labor and material entries from the project dashboard, updating Firestore and the UI in real time.

Requirements:

1. DatabaseService:
   - Add methods:
     updateLaborEntry(LaborEntry entry)
     updateMaterialEntry(MaterialEntry entry)

   - Each method should:
     - retrieve the current authenticated user UID
     - update the document at:
       users/{uid}/projects/{projectId}/labor_entries/{entryId}
       users/{uid}/projects/{projectId}/material_entries/{entryId}
     - use .set(...) or .update(...) appropriately

2. Dialog reuse (IMPORTANT):
   - Do NOT create new edit dialog classes
   - Reuse:
     AddLaborEntryDialog
     AddMaterialEntryDialog

   - Modify them to support edit mode:
     - Accept an optional existing entry parameter
     - If provided:
       - pre-fill all TextEditingControllers
       - change button label from "Add Entry" → "Save Changes"

3. UI (Project Dashboard):
   - Add an edit action for each entry (choose one):
     - tap entry → edit
     - OR trailing edit icon

   - When triggered:
     - open the same dialog in edit mode
     - pass the existing entry

4. Edit behavior:
   - When user submits:
     - validate inputs (same as create)
     - call updateLaborEntry(...) or updateMaterialEntry(...)
   - No confirmation dialog needed for edit

5. Data flow:
   - Do NOT manually refresh UI
   - Rely on existing stream providers:
     labor_entries_provider
     material_entries_provider

6. Constraints:
   - Do NOT redesign the UI
   - Do NOT create new providers
   - Do NOT call Firestore directly from widgets
   - Keep logic consistent with create/delete patterns

7. Desired outcome:
   - User can edit existing entries
   - Dialog opens pre-filled with current values
   - Changes save to Firestore
   - UI updates automatically via stream

## Prompt 22
Implement Step 3.8 (CRUD) — Edit and Delete Projects.

Goal:
Allow users to edit and delete projects from the project list while keeping ownership and Firestore path rules consistent.

Requirements:

1. DatabaseService:
   - Add methods:
     updateProject(Project project)
     deleteProject(String projectId)

   - Behavior:
     - Both methods must use the current authenticated user UID
     - updateProject(Project project) should write to:
       users/{uid}/projects/{projectId}
     - deleteProject(String projectId) should delete:
       users/{uid}/projects/{projectId}

   - Keep ownership hardening consistent:
     - ownerUid should remain aligned with the authenticated user
     - project writes should still be normalized in the service layer

2. Dialog reuse (IMPORTANT):
   - Do NOT create a new edit-project dialog
   - Reuse CreateProjectDialog for edit mode
   - Add optional existing Project parameter
   - If provided:
     - pre-fill name, client, address
     - switch title/button text into edit mode
     - call updateProject(...) instead of createProject(...)

3. UI (ProjectsScreen):
   - Add edit and delete actions for each project
   - Keep the UI simple and consistent with the rest of the app
   - A popup menu, trailing action buttons, or another simple Material pattern is acceptable

4. Delete behavior:
   - Show a confirmation dialog before deleting a project:
     “Are you sure you want to delete this project?”
   - If confirmed:
     - call deleteProject(...) through database_service_provider
   - If canceled:
     - do nothing

5. Navigation/state behavior:
   - Keep selected_project_provider behavior safe and consistent
   - If project deletion affects the currently selected project, avoid leaving stale selection state behind
   - Do NOT redesign the overall navigation shell

6. Constraints:
   - Do NOT implement advanced cascading delete logic for nested subcollections unless absolutely necessary
   - Do NOT add new providers
   - Do NOT call Firestore directly from widgets
   - Keep this step focused on project CRUD only
   - Maintain separation of concerns

7. Desired outcome:
   - User can edit project name/client/address from ProjectsScreen
   - User can delete a project from ProjectsScreen with confirmation
   - UI updates automatically through the existing projects_provider stream
   - Ownership remains enforced through DatabaseService

------------------------------------------------------------------------------------
