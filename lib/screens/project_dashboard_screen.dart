import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/labor_entry.dart';
import '../models/material_entry.dart';
import '../models/project.dart';
import '../providers/project_providers.dart';
import 'add_labor_entry_dialog.dart';
import 'add_material_entry_dialog.dart';

class ProjectDashboardScreen extends ConsumerWidget {
  // ConsumerWidget allows the screen to read and watch providers through the WidgetRef object. The dashboard screen needs to read the selected_project_provider to know which project to display, so it needs to be a ConsumerWidget.
  const ProjectDashboardScreen({super.key});

  // The _showAddLaborEntryDialog and _showAddMaterialEntryDialog methods are responsible for showing the respective dialogs when the user presses the "Add Labor Entry" or "Add Material Entry" buttons in the dashboard. They use the showDialog function to display the dialog widgets, and they set barrierDismissible to false to prevent the user from dismissing the dialog by tapping outside of it while they are filling out the form.
  Future<void> _showAddLaborEntryDialog(BuildContext context) { // Opens the dialog and waits for it to be dismissed before returning. The dialog will handle the form submission and saving of the labor entry, and once the dialog is closed, the dashboard will automatically update due to the reactive nature of Riverpod and the Firestore streams.
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevents the user from dismissing the dialog by tapping outside of it while filling out the form, which can help prevent accidental dismissals and potential loss of input data.
      builder: (BuildContext context) => const AddLaborEntryDialog(),
    );
  }

  Future<void> _showAddMaterialEntryDialog(BuildContext context) { // Opens the dialog and waits for it to be dismissed before returning. The dialog will handle the form submission and saving of the material entry, and once the dialog is closed, the dashboard will automatically update due to the reactive nature of Riverpod and the Firestore streams.
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevents the user from dismissing the dialog by tapping outside of it while filling out the form, which can help prevent accidental dismissals and potential loss of input data.
      builder: (BuildContext context) => const AddMaterialEntryDialog(),
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
        appBar: AppBar(title: const Text('Project Dashboard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('No project selected'),
                const SizedBox(height: 12),
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
      appBar: AppBar(title: Text(selectedProject.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _ProjectHeaderCard(project: selectedProject),
          const SizedBox(height: 16),
          _LaborLogsSection(
            projectId: selectedProject.id,
            onAddPressed: () => _showAddLaborEntryDialog(context),
          ),
          const SizedBox(height: 16),
          _MaterialLogsSection(
            projectId: selectedProject.id,
            onAddPressed: () => _showAddMaterialEntryDialog(context),
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

// This section of the dashboard displays the labor logs for the selected project. It listens to the labor_entries_provider for the specific project ID to get a stream of labor entries, and builds the UI based on the current state of that stream (loading, error, or data).
class _LaborLogsSection extends ConsumerWidget {
  const _LaborLogsSection({
    required this.projectId,
    required this.onAddPressed,
  });

  final String projectId;
  final VoidCallback onAddPressed; // This callback is called when the user presses the "Add Labor Entry" button, and it will trigger the display of the AddLaborEntryDialog.

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LaborEntry>> laborEntriesAsync = ref.watch(
      // Watch the labor_entries_provider for the specific project ID to get the current list of labor entries for that project, and also listen for any updates to that list in real time. This allows the dashboard to reactively update whenever labor entries are added, updated, or removed in the Firestore database for this project.
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
            laborEntriesAsync.when(
              // Depending on the current async state of the labor entries stream, this will build different UI: a loading spinner, an error message, or the list of labor entries.
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
                          contentPadding: EdgeInsets
                              .zero, // Remove default padding from ListTile to make it align better with the card's padding.
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
                onPressed: onAddPressed,
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

class _MaterialLogsSection extends ConsumerWidget {
  const _MaterialLogsSection({
    required this.projectId,
    required this.onAddPressed,
  });

  final String projectId;
  final VoidCallback onAddPressed; // This callback is called when the user presses the "Add Material Entry" button, and it will trigger the display of the AddMaterialEntryDialog.

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MaterialEntry>> materialEntriesAsync = ref.watch(
      material_entries_provider(projectId),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.inventory_2_outlined),
                const SizedBox(width: 10),
                Text(
                  'Material Logs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            materialEntriesAsync.when(
              data: (List<MaterialEntry> entries) {
                if (entries.isEmpty) {
                  return Text(
                    'No entries yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }

                return Column(
                  children: entries
                      .map(
                        (MaterialEntry entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(entry.name),
                          subtitle: Text(
                            '${_formatDate(entry.date)} • ${entry.quantity.toStringAsFixed(2)} qty • \$${entry.unitCost.toStringAsFixed(2)}/unit',
                          ),
                          trailing:
                              entry.vendor != null && entry.vendor!.isNotEmpty
                              ? const Icon(Icons.storefront_outlined, size: 18)
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
                'Unable to load material entries: $error',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onAddPressed,
                child: const Text('Add Material Entry'),
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
