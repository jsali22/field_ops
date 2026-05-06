import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';
import '../providers/project_providers.dart';
import '../widgets/theme_mode_toggle_button.dart';
import 'create_project_dialog.dart';
import 'project_dashboard_screen.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  // This is the signed-in landing screen for the current user's projects.
  Future<void> _showProjectDialog(
    BuildContext context, {
    Project? existingProject,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          CreateProjectDialog(existingProject: existingProject),
    );
  }

  Future<void> _confirmDeleteProject(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Project'),
          content: const Text('Are you sure you want to delete this project?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      final Project? selectedProject = ref.read(selected_project_provider);
      if (selectedProject?.id == project.id) {
        ref.read(selected_project_provider.notifier).selectProject(null);
      }

      await ref.read(database_service_provider).deleteProject(project.id);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to delete the project. Please try again.'),
        ),
      );
    }
  }

  Future<void> _openProjectDashboard(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    // Keep selection in provider state while the dashboard route is active.
    ref.read(selected_project_provider.notifier).selectProject(project);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const ProjectDashboardScreen(),
      ),
    );

    ref.read(selected_project_provider.notifier).selectProject(null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Project>> projectsAsync = ref.watch(
      projects_provider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: const <Widget>[ThemeModeToggleButton(), SizedBox(width: 8)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: projectsAsync.when(
        // AsyncValue.when keeps loading, error, and data handling explicit.
        data: (List<Project> projects) {
          if (projects.isEmpty) {
            return _ProjectsEmptyState(
              onCreatePressed: () => _showProjectDialog(context),
            );
          }

          return _ProjectsList(
            projects: projects,
            topContent: const _ProjectsListIntro(),
            onOpenProject: (Project project) =>
                _openProjectDashboard(context, ref, project),
            onEditProject: (Project project) =>
                _showProjectDialog(context, existingProject: project),
            onDeleteProject: (Project project) =>
                _confirmDeleteProject(context, ref, project),
          );
        },
        loading: () => const _ProjectsLoadingState(),
        error: (Object error, StackTrace stackTrace) {
          return _ProjectsErrorState(
            message: 'We couldn\'t load your projects right now.',
            onRetryPressed: () => ref.invalidate(projects_provider),
          );
        },
      ),
    );
  }
}

enum _ProjectAction { edit, delete }

class _ProjectsList extends StatelessWidget {
  const _ProjectsList({
    required this.projects,
    required this.topContent,
    required this.onOpenProject,
    required this.onEditProject,
    required this.onDeleteProject,
  });

  final List<Project> projects;
  final Widget topContent;
  final ValueChanged<Project> onOpenProject;
  final ValueChanged<Project> onEditProject;
  final ValueChanged<Project> onDeleteProject;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
      itemCount: projects.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return topContent;
        }

        final Project project = projects[index - 1];
        return _ProjectListItem(
          project: project,
          onOpen: () => onOpenProject(project),
          onEdit: () => onEditProject(project),
          onDelete: () => onDeleteProject(project),
        );
      },
    );
  }
}

class _ProjectsListIntro extends StatelessWidget {
  const _ProjectsListIntro();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.folder_copy_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'How to use projects',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap a project to open its dashboard. Use the project menu to edit or delete a project. Use the New Project button to create another project.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectListItem extends StatelessWidget {
  const _ProjectListItem({
    required this.project,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Project project;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        title: Text(
          project.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: _ProjectSubtitle(project: project),
        trailing: PopupMenuButton<_ProjectAction>(
          onSelected: (_ProjectAction action) {
            switch (action) {
              case _ProjectAction.edit:
                onEdit();
                return;
              case _ProjectAction.delete:
                onDelete();
                return;
            }
          },
          itemBuilder: (BuildContext context) =>
              const <PopupMenuEntry<_ProjectAction>>[
                PopupMenuItem<_ProjectAction>(
                  value: _ProjectAction.edit,
                  child: Text('Edit'),
                ),
                PopupMenuItem<_ProjectAction>(
                  value: _ProjectAction.delete,
                  child: Text('Delete'),
                ),
              ],
        ),
        onTap: onOpen,
      ),
    );
  }
}

class _ProjectsLoadingState extends StatelessWidget {
  const _ProjectsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading projects...'),
          ],
        ),
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
            const SizedBox(height: 20),
            Text(
              'No projects yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Create your first project to start tracking labor and materials.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
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
            const SizedBox(height: 20),
            Text(
              'Unable to load projects',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
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
