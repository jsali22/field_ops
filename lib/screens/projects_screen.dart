import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';
import '../providers/project_providers.dart';
import 'create_project_dialog.dart';

class ProjectsScreen extends ConsumerWidget { // ConsumerWidget is a Riverpod widget that allows the screen to read and watch providers through the WidgetRef object.
  const ProjectsScreen({super.key});

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
        onPressed: () => showDialog<void>(
          context: context,
          builder: (BuildContext context) => const CreateProjectDialog(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: projectsAsync.when( // Depending on the current async state of the projects stream, this will build different UI: a loading spinner, an error message with retry button, or the list of projects.
        data: (List<Project> projects) {
          if (projects.isEmpty) {
            return _ProjectsEmptyState( // Keeps all the UI for the empty state in a separate widget to keep the code organized and easier to read. This widget will show a message and a button to create a new project when there are no projects in the database for the current user.
              onCreatePressed: () => showDialog<void>(
                context: context,
                builder: (BuildContext context) => const CreateProjectDialog(),
              ),
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
                  subtitle: _ProjectSubtitle(project: project), // This widget is responsible for formatting the optional client and address fields of the project into a single subtitle string, and handling the case where both fields are null or empty by showing a default message.
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ref.read(selected_project_provider.notifier).state =
                        project;
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) {
          return _ProjectsErrorState( // Keeps all the UI for the error state in a separate widget to keep the code organized and easier to read. This widget will show an error message and a retry button when there is an error loading the projects from the database.
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
