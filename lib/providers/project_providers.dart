import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/labor_entry.dart';
import '../models/material_entry.dart';
import '../models/project.dart';
import '../services/database_service.dart';

// Providers keep screens reactive while routing all project data through the
// service layer instead of letting widgets talk to Firestore directly.
final database_service_provider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Backed by a Firestore stream, so project lists stay live in the UI.
final projects_provider = StreamProvider<List<Project>>((ref) {
  final DatabaseService databaseService = ref.watch(database_service_provider);
  return databaseService.streamProjectsForCurrentUser();
});

class SelectedProjectNotifier extends Notifier<Project?> {
  @override
  Project? build() {
    return null;
  }

  // The dashboard reads this shared selection instead of passing a whole
  // Project object through every route constructor.
  void selectProject(Project? project) {
    state = project;
  }
}

final selected_project_provider =
    NotifierProvider<SelectedProjectNotifier, Project?>(
      SelectedProjectNotifier.new,
    );

// `.family` lets the same provider pattern serve entries for whichever project
// is currently open.
final labor_entries_provider = StreamProvider.family<List<LaborEntry>, String>((
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
