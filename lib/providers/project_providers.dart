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
final selected_project_provider = StateProvider<Project?>((ref) {
  // Use StateProvider because we want to store a single piece of state (the currently selected project) that can be updated and accessed from different parts of the app. The UI can read this state to know which project is currently selected, and it can also update this state when the user selects a different project.
  return null; // The initial value of the selected project is set to null, indicating that no project is selected when the app starts. The UI can update this state to set the currently selected project based on user interactions (e.g., when a user taps on a project in a list).
});

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
