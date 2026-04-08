import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';
import '../providers/project_providers.dart';
import 'create_project_dialog.dart';
import 'project_dashboard_screen.dart';

class ProjectsScreen extends ConsumerWidget {
  // ConsumerWidget is a Riverpod widget that allows the screen to read and watch providers through the WidgetRef object.
  const ProjectsScreen({super.key});

 // This screen displays the list of projects for the current user, and allows the user to create a new project or tap on an existing project to view its dashboard. It uses the projects_provider to listen to the stream of projects from Firestore and reactively update the UI whenever the list of projects changes in the database. It also uses the selected_project_provider to keep track of which project is currently selected when navigating to the dashboard screen.
  Future<void> _showCreateProjectDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevents the user from dismissing the dialog by tapping outside of it while filling out the form, which can help prevent accidental dismissals and potential loss of input data.
      builder: (BuildContext context) => const CreateProjectDialog(),
    );
  }
  // The _openProjectDashboard method is responsible for navigating to the ProjectDashboardScreen when a project is tapped. It first updates the selected_project_provider with the project that was tapped, then it pushes the ProjectDashboardScreen onto the navigation stack. When the user navigates back from the dashboard, it resets the selected_project_provider to null to clear the selection.
  Future<void> _openProjectDashboard(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    ref.read(selected_project_provider.notifier).selectProject(project); // Update the selected project in the provider so that the dashboard screen knows which project to display when it builds. This allows us to pass the selected project data to the dashboard screen without needing to pass it through the constructor or navigation arguments.

   // Wait for the dashboard screen to be popped before clearing the selected project, so that the dashboard can still access the selected project data while it's open. Once the user navigates back from the dashboard, we clear the selected project to reset the state for the next time a project is selected.
    await Navigator.of(context).push( // Push the ProjectDashboardScreen onto the navigation stack to navigate to it. The dashboard screen will read the selected project from the provider and display the relevant data. When the user navigates back from the dashboard, we will clear the selected project in the provider to reset the state.
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const ProjectDashboardScreen(), // We can use a constant constructor here because the ProjectDashboardScreen reads the selected project from the provider, so it doesn't need to receive any data through its constructor. This allows us to keep the navigation simple and rely on the provider for passing data to the dashboard screen.
      ),
    );

    ref.read(selected_project_provider.notifier).selectProject(null); // Clear the selected project in the provider after returning from the dashboard to reset the state for the next time a project is selected. This ensures that if the user goes back to the projects list and selects a different project, the dashboard will show the correct data for the newly selected project.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // projects_provider is a StreamProvider<List<Project>>, so ref.watch(projects_provider) returns an AsyncValue<List<Project>>.
    // AsyncValue can be in one of 3 states: loading, error, or data. The UI will reactively update based on the current state of the projects stream from Firestore.
    final AsyncValue<List<Project>> projectsAsync = ref.watch(
      projects_provider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: projectsAsync.when(
        // Depending on the current async state of the projects stream, this will build different UI: a loading spinner, an error message with retry button, or the list of projects.
        data: (List<Project> projects) {
          if (projects.isEmpty) {
            return _ProjectsEmptyState(
              // Keeps all the UI for the empty state in a separate widget to keep the code organized and easier to read. This widget will show a message and a button to create a new project when there are no projects in the database for the current user.
              onCreatePressed: () => _showCreateProjectDialog(context),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: projects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final Project project = projects[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(project.name),
                  subtitle: _ProjectSubtitle(
                    project: project,
                  ), // This widget is responsible for formatting the optional client and address fields of the project into a single subtitle string, and handling the case where both fields are null or empty by showing a default message.
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openProjectDashboard(context, ref, project),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) {
          return _ProjectsErrorState(
            // Keeps all the UI for the error state in a separate widget to keep the code organized and easier to read. This widget will show an error message and a retry button when there is an error loading the projects from the database.
            message: error.toString(),
            onRetryPressed: () => ref.invalidate(projects_provider),
          );
        },
      ),
    );
  }
}

class _ProjectsEmptyState extends StatelessWidget {
  const _ProjectsEmptyState({required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.folder_open, size: 56),
            const SizedBox(height: 16),
            Text(
              'No projects yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first project to start tracking labor and materials.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreatePressed,
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectsErrorState extends StatelessWidget {
  const _ProjectsErrorState({
    required this.message,
    required this.onRetryPressed,
  });

  final String message;
  final VoidCallback onRetryPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              'Unable to load projects',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetryPressed,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectSubtitle extends StatelessWidget {
  const _ProjectSubtitle({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final List<String> details = <String>[
      if (project.client != null && project.client!.trim().isNotEmpty)
        project.client!.trim(),
      if (project.address != null && project.address!.trim().isNotEmpty)
        project.address!.trim(),
    ];

    if (details.isEmpty) {
      return const Text('No client or address added');
    }

    return Text(details.join(' • '));
  }
}
