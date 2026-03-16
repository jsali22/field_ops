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

------------------------------------------------------------------------------------
