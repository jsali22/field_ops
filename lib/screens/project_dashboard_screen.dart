import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/labor_entry.dart';
import '../models/material_entry.dart';
import '../models/project.dart';
import '../providers/project_providers.dart';
import '../widgets/theme_mode_toggle_button.dart';
import '../widgets/project_today_summary_card.dart';
import 'add_labor_entry_dialog.dart';
import 'add_material_entry_dialog.dart';

class ProjectDashboardScreen extends ConsumerWidget {
  // ConsumerWidget allows the screen to read and watch providers through the WidgetRef object. The dashboard screen needs to read the selected_project_provider to know which project to display, so it needs to be a ConsumerWidget.
  const ProjectDashboardScreen({super.key});

  // The _showAddLaborEntryDialog and _showAddMaterialEntryDialog methods are responsible for showing the respective dialogs when the user presses the "Add Labor Entry" or "Add Material Entry" buttons in the dashboard. They use the showDialog function to display the dialog widgets, and they set barrierDismissible to false to prevent the user from dismissing the dialog by tapping outside of it while they are filling out the form.
  Future<void> _showLaborEntryDialog(
    BuildContext context, {
    LaborEntry? existingEntry,
  }) {
    // Opens the dialog and waits for it to be dismissed before returning. The dialog will handle the form submission and saving of the labor entry, and once the dialog is closed, the dashboard will automatically update due to the reactive nature of Riverpod and the Firestore streams.
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevents the user from dismissing the dialog by tapping outside of it while filling out the form, which can help prevent accidental dismissals and potential loss of input data.
      builder: (BuildContext context) =>
          AddLaborEntryDialog(existingEntry: existingEntry),
    );
  }

  Future<void> _showMaterialEntryDialog(
    BuildContext context, {
    MaterialEntry? existingEntry,
  }) {
    // Opens the dialog and waits for it to be dismissed before returning. The dialog will handle the form submission and saving of the material entry, and once the dialog is closed, the dashboard will automatically update due to the reactive nature of Riverpod and the Firestore streams.
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevents the user from dismissing the dialog by tapping outside of it while filling out the form, which can help prevent accidental dismissals and potential loss of input data.
      builder: (BuildContext context) =>
          AddMaterialEntryDialog(existingEntry: existingEntry),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Project? selectedProject = ref.watch(
      selected_project_provider,
    ); // Watch/read the selected_project_provider to get the currently selected project from the app state. This will allow the dashboard screen to display the correct project details based on which project was selected in the ProjectsScreen.

    if (selectedProject == null) {
      // If no project is selected, show a placeholder screen with a message indicating that no project is selected. This can happen if the user navigates to the dashboard screen without selecting a project first, or if the selected project was somehow cleared from the state.
      return Scaffold(
        appBar: AppBar(
          title: const Text('Project Dashboard'),
          actions: const <Widget>[ThemeModeToggleButton(), SizedBox(width: 8)],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'No project selected',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Return to the project list and choose a project to view its dashboard.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Back to Projects'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedProject.name),
        actions: const <Widget>[ThemeModeToggleButton(), SizedBox(width: 8)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          _ProjectHeaderCard(
            project: selectedProject,
          ), // Displays the project name, client, and address in a card at the top of the dashboard. This widget takes the selected project as input and shows its details in a nicely formatted way.
          const SizedBox(height: 20),
          ProjectTodaySummaryCard(
            projectId: selectedProject.id,
          ), // This card shows a summary of today's labor and material costs for the project. It listens to the labor and material entries for the project and calculates the totals for today, and updates reactively whenever new entries are added or existing entries are updated in Firestore.
          const SizedBox(height: 20),
          _LaborLogsSection(
            // This section of the dashboard displays the labor logs for the selected project. It listens to the labor_entries_provider for the specific project ID to get a stream of labor entries, and builds the UI based on the current state of that stream (loading, error, or data).
            projectId: selectedProject.id,
            onAddPressed: () => _showLaborEntryDialog(context),
            onEditEntry: (LaborEntry entry) =>
                _showLaborEntryDialog(context, existingEntry: entry),
          ),
          const SizedBox(height: 20),
          _MaterialLogsSection(
            projectId: selectedProject.id,
            onAddPressed: () => _showMaterialEntryDialog(context),
            onEditEntry: (MaterialEntry entry) =>
                _showMaterialEntryDialog(context, existingEntry: entry),
          ),
        ],
      ),
    );
  }
}

// This widget is responsible for displaying the project name, client, and address in a card at the top of the dashboard. It takes the selected project as input and shows its details in a nicely formatted way. If the client and address fields are both null or empty, it will show a default message indicating that no client or address has been added.
class _ProjectHeaderCard extends StatelessWidget {
  const _ProjectHeaderCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final List<_ProjectDetailRow> details = <_ProjectDetailRow>[
      if (project.client != null && project.client!.trim().isNotEmpty)
        _ProjectDetailRow(
          icon: Icons.person_outline,
          label: 'Client',
          value: project.client!.trim(),
        ),
      if (project.address != null && project.address!.trim().isNotEmpty)
        _ProjectDetailRow(
          icon: Icons.location_on_outlined,
          label: 'Address',
          value: project.address!.trim(),
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.assignment_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Project Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              project.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (details.isEmpty)
              Text(
                'No client or address added',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...details,
          ],
        ),
      ),
    );
  }
}

// This widget represents a single row of project details (client or address) in the project header card. It takes an icon, a label, and a value as input and displays them in a formatted way with some spacing. This helps keep the code organized and reusable for both the client and address fields in the project header.
class _ProjectDetailRow extends StatelessWidget {
  const _ProjectDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('$label: $value')),
        ],
      ),
    );
  }
}

// This section of the dashboard displays the labor logs for the selected project. It listens to the labor_entries_provider for the specific project ID to get a stream of labor entries, and builds the UI based on the current state of that stream (loading, error, or data).
class _LaborLogsSection extends ConsumerWidget {
  const _LaborLogsSection({
    required this.projectId,
    required this.onAddPressed,
    required this.onEditEntry, // This callback is called when the user taps on a labor entry in the list, and it will trigger the display of the AddLaborEntryDialog with the existing entry data pre-filled for editing.
  });

  final String projectId;
  final VoidCallback
  onAddPressed; // This callback is called when the user presses the "Add Labor Entry" button, and it will trigger the display of the AddLaborEntryDialog.
  final ValueChanged<LaborEntry> onEditEntry;

  // The _confirmDeleteLaborEntry method is responsible for showing a confirmation dialog when the user attempts to delete a labor entry, and if the user confirms, it will call the deleteLaborEntry method from the database service to remove the entry from Firestore. It also handles any errors that may occur during deletion and shows a SnackBar with an error message if the deletion fails.
  Future<void> _confirmDeleteLaborEntry(
    BuildContext context,
    WidgetRef ref,
    LaborEntry entry,
  ) async {
    // Show a confirmation dialog to the user before deleting the labor entry, to prevent accidental deletions. The dialog will ask the user if they are sure they want to delete the entry, and if they confirm, it will proceed with the deletion. If they cancel, it will simply close the dialog and do nothing.
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Labor Entry'),
          content: const Text(
            'Are you sure you want to delete this labor entry?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete Labor Entry'),
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

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
      context,
    ); // Get the ScaffoldMessengerState to show a SnackBar if the deletion fails. We need to get this before we call the asynchronous deleteLaborEntry method, because after that call, the context might no longer be valid if the user has navigated away from the dashboard screen

    try {
      await ref
          .read(
            database_service_provider,
          ) // Read the database service provider to get an instance of the DatabaseService, and then call the deleteLaborEntry method with the project ID and entry ID to delete the labor entry from Firestore. This will remove the document corresponding to the labor entry from the 'labor_entries' subcollection under the specified project document in Firestore.
          .deleteLaborEntry(projectId, entry.id);
    } catch (error) {
      if (!context.mounted) {
        // Check if the context is still valid before trying to show a SnackBar. If the user has navigated away from the dashboard screen while the deletion was in progress, the context will no longer be valid, and trying to show a SnackBar would cause an error. In that case, we simply return without doing anything, since we can't show the error message to the user anyway.
        return;
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to delete the labor entry. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LaborEntry>> laborEntriesAsync = ref.watch(
      // Watch the labor_entries_provider for the specific project ID to get the current list of labor entries for that project, and also listen for any updates to that list in real time. This allows the dashboard to reactively update whenever labor entries are added, updated, or removed in the Firestore database for this project.
      labor_entries_provider(projectId),
    );

    // Depending on the current async state of the labor entries stream, this will build different UI: a loading spinner, an error message, or the list of labor entries. The when method allows us to handle each state (data, loading, error) separately and return the appropriate widget for each case.
    return _DashboardLogSection(
      icon: Icons.engineering_outlined,
      title: 'Labor Logs',
      helperText: 'Tap an entry to edit it. Use the trash icon to remove it.',
      actionLabel: 'Add Labor Entry',
      onActionPressed: onAddPressed,
      child: laborEntriesAsync.when(
        data: (List<LaborEntry> entries) {
          if (entries.isEmpty) {
            return Text(
              'No entries yet',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          }

          // If there are labor entries, build a list of ListTile widgets to display each entry. Each ListTile will show the role/task, date, hours, and hourly rate for the labor entry, and will have an onTap handler to edit the entry and a delete button to remove the entry.
          return Column(
            children: entries
                .map(
                  (LaborEntry entry) => ListTile(
                    contentPadding: EdgeInsets
                        .zero, // Remove default padding from ListTile to make it align better with the card's padding.
                    onTap: () => onEditEntry(entry),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.engineering_outlined, size: 18),
                    ),
                    title: Text(
                      entry.roleTask,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${_formatDate(entry.date)} • ${entry.hours.toStringAsFixed(2)} hrs • \$${entry.hourlyRate.toStringAsFixed(2)}/hr', // Format the subtitle to show the date, hours, and hourly rate for the labor entry in a concise way. The _formatDate method is used to format the date as MM/DD/YYYY, and toStringAsFixed(2) is used to format the hours and hourly rate with 2 decimal places for better readability.
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete labor entry',
                      onPressed: () =>
                          _confirmDeleteLaborEntry(context, ref, entry),
                      color: Theme.of(context).colorScheme.error,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                )
                .toList(growable: false),
          );
        },
        loading: () => const _DashboardSectionLoadingState(
          message: 'Loading labor entries...',
        ),
        error: (Object error, StackTrace stackTrace) => Text(
          'Unable to load labor entries right now.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  // The _formatDate method takes a DateTime object and formats it as a string in the MM/DD/YYYY format. It uses the month, day, and year properties of the DateTime object, and pads the month and day with leading zeros if they are less than 10 to ensure consistent formatting.
  String _formatDate(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    final String year = value.year.toString();
    return '$month/$day/$year';
  }
}

// This section of the dashboard displays the material logs for the selected project. It listens to the material_entries_provider for the specific project ID to get a stream of material entries, and builds the UI based on the current state of that stream (loading, error, or data).
class _MaterialLogsSection extends ConsumerWidget {
  const _MaterialLogsSection({
    required this.projectId,
    required this.onAddPressed,
    required this.onEditEntry, // This callback is called when the user taps on a material entry in the list, and it will trigger the display of the AddMaterialEntryDialog with the existing entry data pre-filled for editing.
  });

  final String projectId;
  final VoidCallback
  onAddPressed; // This callback is called when the user presses the "Add Material Entry" button, and it will trigger the display of the AddMaterialEntryDialog.
  final ValueChanged<MaterialEntry> onEditEntry;

  // The _confirmDeleteMaterialEntry method is responsible for showing a confirmation dialog when the user attempts to delete a material entry, and if the user confirms, it will call the deleteMaterialEntry method from the database service to remove the entry from Firestore. It also handles any errors that may occur during deletion and shows a SnackBar with an error message if the deletion fails.
  Future<void> _confirmDeleteMaterialEntry(
    BuildContext context,
    WidgetRef ref,
    MaterialEntry entry,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Material Entry'),
          content: const Text(
            'Are you sure you want to delete this material entry?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete Material Entry'),
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
      await ref
          .read(database_service_provider)
          .deleteMaterialEntry(projectId, entry.id);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to delete the material entry. Please try again.',
          ),
        ),
      );
    }
  }

  // The build method listens to the material_entries_provider for the specific project ID to get the current list of material entries for that project, and also listen for any updates to that list in real time.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MaterialEntry>> materialEntriesAsync = ref.watch(
      material_entries_provider(projectId),
    );

    // Depending on the current async state of the material entries stream, this will build different UI: a loading spinner, an error message, or the list of material entries.
    return _DashboardLogSection(
      icon: Icons.inventory_2_outlined,
      title: 'Material Logs',
      helperText: 'Tap an entry to edit it. Use the trash icon to remove it.',
      actionLabel: 'Add Material Entry',
      onActionPressed: onAddPressed,
      child: materialEntriesAsync.when(
        data: (List<MaterialEntry> entries) {
          if (entries.isEmpty) {
            return Text(
              'No entries yet',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          }

          // If there are material entries, build a list of ListTile widgets to display each entry. Each ListTile will show the material name, date, quantity, and unit cost for the material entry, and will have an onTap handler to edit the entry and a delete button to remove the entry.
          return Column(
            children: entries
                .map(
                  (MaterialEntry entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => onEditEntry(entry),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.inventory_2_outlined, size: 18),
                    ),
                    title: Text(
                      entry.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${_formatDate(entry.date)} • ${entry.quantity.toStringAsFixed(2)} qty • \$${entry.unitCost.toStringAsFixed(2)}/unit',
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete material entry',
                      onPressed: () =>
                          _confirmDeleteMaterialEntry(context, ref, entry),
                      color: Theme.of(context).colorScheme.error,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                )
                .toList(growable: false),
          );
        },
        loading: () => const _DashboardSectionLoadingState(
          message: 'Loading material entries...',
        ),
        error: (Object error, StackTrace stackTrace) => Text(
          'Unable to load material entries right now.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  // The _formatDate method takes a DateTime object and formats it as a string in the MM/DD/YYYY format. It uses the month, day, and year properties of the DateTime object, and pads the month and day with leading zeros if they are less than 10 to ensure consistent formatting.
  String _formatDate(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    final String year = value.year.toString();
    return '$month/$day/$year';
  }
}

// This widget represents a section of the dashboard that displays either labor logs or material logs. It takes an icon, a title, a child widget to display the list of entries, and an action label and callback for the button to add new entries. This helps keep the code organized and reusable for both the labor logs and material logs sections of the dashboard.
class _DashboardLogSection extends StatelessWidget {
  const _DashboardLogSection({
    required this.icon,
    required this.title,
    required this.child,
    required this.helperText,
    required this.actionLabel,
    required this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final String helperText;
  final String actionLabel;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 6),
            Text(helperText, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            child,
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onActionPressed,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// This widget is used to display a loading state for the dashboard sections (labor logs and material logs) while the data is being fetched from Firestore. It shows a CircularProgressIndicator and a message indicating that the entries are loading. This provides feedback to the user that the app is working on fetching the data, and helps improve the user experience by preventing confusion or frustration when there is a delay in loading the entries.
class _DashboardSectionLoadingState extends StatelessWidget {
  const _DashboardSectionLoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(message),
          ],
        ),
      ),
    );
  }
}
