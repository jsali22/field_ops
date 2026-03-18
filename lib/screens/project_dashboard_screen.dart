import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/labor_entry.dart';
import '../models/project.dart';
import '../providers/project_providers.dart';
import 'add_labor_entry_dialog.dart';

class ProjectDashboardScreen extends ConsumerWidget {
  // ConsumerWidget allows the screen to read and watch providers through the WidgetRef object. The dashboard screen needs to read the selected_project_provider to know which project to display, so it needs to be a ConsumerWidget.
  const ProjectDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Project? selectedProject = ref.watch(
      selected_project_provider,
    ); // Watch/read the selected_project_provider to get the currently selected project from the app state. This will allow the dashboard screen to display the correct project details based on which project was selected in the ProjectsScreen.

    if (selectedProject == null) {
      // If no project is selected, show a placeholder screen with a message indicating that no project is selected. This can happen if the user navigates to the dashboard screen without selecting a project first, or if the selected project was somehow cleared from the state.
      return Scaffold(
        appBar: AppBar(title: const Text('Project Dashboard')),
        body: const Center(child: Text('No project selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(selectedProject.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _ProjectHeaderCard(project: selectedProject),
          const SizedBox(height: 16),
          _LaborLogsSection(projectId: selectedProject.id),
          const SizedBox(height: 16),
          _DashboardSectionCard(
            title: 'Material Logs',
            placeholder: 'No entries yet',
            buttonLabel: 'Add Material Entry',
            icon: Icons.inventory_2_outlined,
            onPressed: () {
              // TODO: Navigate to the add material entry flow in Step 2.7.
            },
          ),
        ],
      ),
    );
  }
}

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              project.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
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
      padding: const EdgeInsets.only(top: 8),
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

class _DashboardSectionCard extends StatelessWidget {
  const _DashboardSectionCard({
    required this.title,
    required this.placeholder,
    required this.buttonLabel,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String placeholder;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 12),
            Text(placeholder, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// This section of the dashboard displays the labor logs for the selected project. It listens to the labor_entries_provider for the specific project ID to get a stream of labor entries, and builds the UI based on the current state of that stream (loading, error, or data).
class _LaborLogsSection extends ConsumerWidget {
  const _LaborLogsSection({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LaborEntry>> laborEntriesAsync = ref.watch( // Watch the labor_entries_provider for the specific project ID to get the current list of labor entries for that project, and also listen for any updates to that list in real time. This allows the dashboard to reactively update whenever labor entries are added, updated, or removed in the Firestore database for this project.
      labor_entries_provider(projectId),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.engineering_outlined),
                const SizedBox(width: 10),
                Text(
                  'Labor Logs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            laborEntriesAsync.when( // Depending on the current async state of the labor entries stream, this will build different UI: a loading spinner, an error message, or the list of labor entries.
              data: (List<LaborEntry> entries) {
                if (entries.isEmpty) {
                  return Text(
                    'No entries yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }

                return Column(
                  children: entries
                      .map(
                        (LaborEntry entry) => ListTile(
                          contentPadding: EdgeInsets.zero, // Remove default padding from ListTile to make it align better with the card's padding.
                          title: Text(entry.roleTask),
                          subtitle: Text(
                            '${_formatDate(entry.date)} • ${entry.hours.toStringAsFixed(2)} hrs • \$${entry.hourlyRate.toStringAsFixed(2)}/hr', // Format the subtitle to show the date, hours, and hourly rate for the labor entry in a concise way. The _formatDate method is used to format the date as MM/DD/YYYY, and toStringAsFixed(2) is used to format the hours and hourly rate with 2 decimal places for better readability.
                          ),
                          trailing:
                              entry.notes != null && entry.notes!.isNotEmpty
                              ? const Icon(Icons.notes, size: 18)
                              : null,
                        ),
                      )
                      .toList(growable: false),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object error, StackTrace stackTrace) => Text(
                'Unable to load labor entries: $error',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => showDialog<void>( // When the "Add Labor Entry" button is pressed, show the AddLaborEntryDialog, which allows the user to input details for a new labor entry and save it to the database. The dialog will read the selected project ID from the provider to know which project to associate the new labor entry with when saving to the database.
                  context: context,
                  builder: (BuildContext context) => // Build the AddLaborEntryDialog widget when the button is pressed. This dialog will handle collecting the labor entry details from the user, validating the input, and then creating a new labor entry in the database through the database_service_provider when the form is submitted.
                      const AddLaborEntryDialog(),
                ),
                child: const Text('Add Labor Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    final String year = value.year.toString();
    return '$month/$day/$year';
  }
}
