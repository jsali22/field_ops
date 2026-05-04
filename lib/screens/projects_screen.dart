import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';
import '../providers/project_providers.dart';
import '../widgets/theme_mode_toggle_button.dart';
import 'create_project_dialog.dart';
import 'project_dashboard_screen.dart';

class ProjectsScreen extends ConsumerWidget {
  // ConsumerWidget is a Riverpod widget that allows the screen to read and watch providers through the WidgetRef object.
  const ProjectsScreen({super.key});

  // This screen displays the list of projects for the current user, and allows the user to create a new project or tap on an existing project to view its dashboard. It uses the projects_provider to listen to the stream of projects from Firestore and reactively update the UI whenever the list of projects changes in the database. It also uses the selected_project_provider to keep track of which project is currently selected when navigating to the dashboard screen.
  Future<void> _showProjectDialog(
    BuildContext context, {
    Project? existingProject,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevents the user from dismissing the dialog by tapping outside of it while filling out the form, which can help prevent accidental dismissals and potential loss of input data.
      builder: (BuildContext context) =>
          CreateProjectDialog(existingProject: existingProject),
    );
  }

  // The _confirmDeleteProject method is responsible for showing a confirmation dialog when the user selects the "Delete" action from the project options menu. If the user confirms the deletion, it calls the deleteProject method of the database service provider to remove the project from Firestore.
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
      // Try to delete the project from the database using the database service provider. We wrap this in a try-catch block to handle any errors that may occur during the database operation, and show an appropriate error message if something goes wrong.
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

  // The _openProjectDashboard method is responsible for navigating to the ProjectDashboardScreen when a project is tapped. It first updates the selected_project_provider with the project that was tapped, then it pushes the ProjectDashboardScreen onto the navigation stack. When the user navigates back from the dashboard, it resets the selected_project_provider to null to clear the selection.
  Future<void> _openProjectDashboard(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    ref
        .read(selected_project_provider.notifier)
        .selectProject(
          project,
        ); // Update the selected project in the provider so that the dashboard screen knows which project to display when it builds. This allows us to pass the selected project data to the dashboard screen without needing to pass it through the constructor or navigation arguments.

    // Wait for the dashboard screen to be popped before clearing the selected project, so that the dashboard can still access the selected project data while it's open. Once the user navigates back from the dashboard, we clear the selected project to reset the state for the next time a project is selected.
    await Navigator.of(context).push(
      // Push the ProjectDashboardScreen onto the navigation stack to navigate to it. The dashboard screen will read the selected project from the provider and display the relevant data. When the user navigates back from the dashboard, we will clear the selected project in the provider to reset the state.
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            const ProjectDashboardScreen(), // We can use a constant constructor here because the ProjectDashboardScreen reads the selected project from the provider, so it doesn't need to receive any data through its constructor. This allows us to keep the navigation simple and rely on the provider for passing data to the dashboard screen.
      ),
    );

    ref
        .read(selected_project_provider.notifier)
        .selectProject(
          null,
        ); // Clear the selected project in the provider after returning from the dashboard to reset the state for the next time a project is selected. This ensures that if the user goes back to the projects list and selects a different project, the dashboard will show the correct data for the newly selected project.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // projects_provider is a StreamProvider<List<Project>>, so ref.watch(projects_provider) returns an AsyncValue<List<Project>>.
    // AsyncValue can be in one of 3 states: loading, error, or data. The UI will reactively update based on the current state of the projects stream from Firestore.
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
        // Depending on the current async state of the projects stream, this will build different UI: a loading spinner, an error message with retry button, or the list of projects.
        data: (List<Project> projects) {
          if (projects.isEmpty) {
            return _ProjectsEmptyState(
              // Keeps all the UI for the empty state in a separate widget to keep the code organized and easier to read. This widget will show a message and a button to create a new project when there are no projects in the database for the current user.
              onCreatePressed: () => _showProjectDialog(context),
            );
          }

          // If there are projects in the database, show the list of projects using the _ProjectsList widget, which takes care of displaying each project and handling the user interactions for opening, editing, and deleting projects.
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
            // Keeps all the UI for the error state in a separate widget to keep the code organized and easier to read. This widget will show an error message and a retry button when there is an error loading the projects from the database.
            message: 'We couldn\'t load your projects right now.',
            onRetryPressed: () => ref.invalidate(projects_provider),
          );
        },
      ),
    );
  }
}

// An enum to represent the possible actions in the project options menu. This makes the code more readable and type-safe when handling the user's selection from the menu.
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

// This widget represents the introductory content at the top of the projects list, which provides instructions to the user on how to use the projects screen. It is displayed as a card with an icon and some text explaining how to open, edit, and create projects.
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

// This widget represents a single project item in the list of projects. It displays the project name, client, and address (if available), and provides a popup menu with options to edit or delete the project. Tapping on the project will open the project dashboard.
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
        subtitle: _ProjectSubtitle(
          project: project,
        ), // This widget is responsible for formatting the optional client and address fields of the project into a single subtitle string, and handling the case where both fields are null or empty by showing a default message.
        trailing: PopupMenuButton<_ProjectAction>(
          onSelected: (_ProjectAction action) {
            switch (action) {
              case _ProjectAction.edit:
                onEdit(); // When the user selects "Edit" from the options menu, we open the CreateProjectDialog with the existing project data passed in, which allows the user to edit the project details. The same dialog is used for both creating new projects and editing existing ones
                return;
              case _ProjectAction.delete:
                onDelete(); // When the user selects "Delete" from the options menu, we show a confirmation dialog, and if the user confirms, we delete the project from the database.
                return;
            }
          },
          itemBuilder:
              (
                BuildContext context,
              ) => // The options menu for each project item, which allows the user to select actions like "Edit" or "Delete". We use a PopupMenuButton with an enum to represent the possible actions, which makes the code more readable and easier to maintain.
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

// These are separate widgets for the different states of the projects screen (loading, empty, error) to keep the code organized and easier to read. Each widget is responsible for displaying the appropriate UI for its respective state, such as a loading spinner for the loading state, a message and button for the empty state, and an error message with retry button for the error state.
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

// This widget represents the empty state of the projects screen, which is shown when there are no projects in the database for the current user. It displays a message and a button to create a new project, encouraging the user to get started with the app.
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

// This widget represents the error state of the projects screen, which is shown when there is an error loading the projects from the database. It displays an error message and a retry button that allows the user to attempt to load the projects again by invalidating the projects_provider, which will trigger it to fetch the data from Firestore again.
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

// This widget is responsible for formatting the optional client and address fields of the project into a single subtitle string, and handling the case where both fields are null or empty by showing a default message. 
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
