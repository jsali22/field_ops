import 'package:flutter_riverpod/flutter_riverpod.dart'; // gives access to Provider, StreamProvider, and StateProvider, which are used to create the providers in this file.

import '../models/labor_entry.dart';
import '../models/material_entry.dart';
import '../models/project.dart'; // supplies the Project type/model, which is used in the providers to represent project data.
import '../services/database_service.dart'; // supplies the DatabaseService class, which is used in the providers to interact with the Firestore database and retrieve project data for the current user.

// This file defines the Riverpod providers for the project-related data and services. It connects the DatabaseService to Riverpod state and then the UI.
// It exposes project-related app state to the UI in a reactive way, without letting wiidgets talk directly to the database service (Firestore)

// This provider creates an instance of the DatabaseService class, which is responsible for interacting with the Firestore database to perform operations related to projects.
// By using a provider, we can easily access the DatabaseService instance from anywhere in the app, and it also allows for better testability and separation of concerns.
final database_service_provider = Provider<DatabaseService>((ref) {
  // Provides a value but its not reactive on its own, it's mainly for dependency injection of the DatabaseService instance.
  return DatabaseService();
});

// This provider listens to the stream of projects for the current user from the DatabaseService and exposes it to the UI as a StreamProvider so that the UI can reactively update whenever the list of projects changes in the database (e.g., when a project is added, updated, or removed).
final projects_provider = StreamProvider<List<Project>>((ref) {
  // Use StreamProvider because we want to listen to a stream of data (the list of projects for the current user) that can change over time, and we want the UI to automatically update whenever there are changes to the projects in the Firestore database.
  final DatabaseService databaseService = ref.watch(
    database_service_provider,
  ); // ref.watch: "get the database service instance from the provider, so we can call methods on it to get the project data stream.""
  return databaseService
      .streamProjectsForCurrentUser(); // calls the streamProjectsForCurrentUser method of the DatabaseService to get a stream of lists of Project instances that belong to the currently authenticated user. This stream will emit new values whenever there are changes to the projects in the Firestore database, allowing the UI to reactively update with the latest project data.
});

// This provider stores the currently selected project in the app state, allowing different parts of the UI to access and modify the selected project without needing to pass it down through widget constructors.
class SelectedProjectNotifier extends Notifier<Project?> {
  @override
  Project? build() { // The build method is called when the notifier is first created and can be used to initialize the state. In this case, we return null to indicate that no project is selected by default when the app starts.
    return null; // Initial state is null, meaning no project is selected when the app starts. The state can be updated later by calling the selectProject method to set a specific project as the selected one.
  }

  void selectProject(Project? project) { // This method allows us to update the selected project by calling selectProject with a new Project instance (or null to deselect). It updates the state of the notifier, which will notify any listeners that the selected project has changed, allowing the UI to reactively update based on the new selection.
    state = project; // Update the state with the new selected project. This will trigger any UI that listens to this provider to rebuild and reflect the new selected project.
  }
}

final selected_project_provider =
    NotifierProvider<SelectedProjectNotifier, Project?>( // Instead of directly mutating .state from outside the notifier, we define a method selectProject within the SelectedProjectNotifier class that updates the state. This encapsulates the logic for updating the selected project and allows for better control over how the state is modified.
      SelectedProjectNotifier.new,
    );

// This provider listens to the stream of labor entries for a specific project from the DatabaseService and exposes it to the UI as a StreamProvider.family so that the UI can reactively update whenever the list of labor entries changes in the database for that project.
final labor_entries_provider = StreamProvider.family<List<LaborEntry>, String>((
  // The .family modifier allows this provider to take a parameter (the project ID) so that it can provide labor entries specific to each project.
  ref,
  projectId,
) {
  final DatabaseService databaseService = ref.watch(database_service_provider);
  return databaseService.streamLaborEntriesForProject(projectId);
});

final material_entries_provider =
    StreamProvider.family<List<MaterialEntry>, String>((ref, projectId) {
      final DatabaseService databaseService = ref.watch(
        database_service_provider,
      );
      return databaseService.streamMaterialEntriesForProject(projectId);
    });
