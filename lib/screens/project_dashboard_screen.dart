import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/labor_entry.dart';
import '../models/material_entry.dart';
import '../models/project.dart';
import '../providers/project_providers.dart';
import '../widgets/project_today_summary_card.dart';
import '../widgets/theme_mode_toggle_button.dart';
import 'add_labor_entry_dialog.dart';
import 'add_material_entry_dialog.dart';

class ProjectDashboardScreen extends ConsumerWidget {
  const ProjectDashboardScreen({super.key});

  // The dashboard stays lightweight by reading the selected project from
  // provider state and the logs from Firestore-backed streams.
  Future<void> _showLaborEntryDialog(
    BuildContext context, {
    LaborEntry? existingEntry,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          AddLaborEntryDialog(existingEntry: existingEntry),
    );
  }

  Future<void> _showMaterialEntryDialog(
    BuildContext context, {
    MaterialEntry? existingEntry,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          AddMaterialEntryDialog(existingEntry: existingEntry),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Project? selectedProject = ref.watch(selected_project_provider);

    if (selectedProject == null) {
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
          _ProjectHeaderCard(project: selectedProject),
          const SizedBox(height: 20),
          ProjectTodaySummaryCard(projectId: selectedProject.id),
          const SizedBox(height: 20),
          _LaborLogsSection(
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

class _LaborLogsSection extends ConsumerWidget {
  const _LaborLogsSection({
    required this.projectId,
    required this.onAddPressed,
    required this.onEditEntry,
  });

  final String projectId;
  final VoidCallback onAddPressed;
  final ValueChanged<LaborEntry> onEditEntry;

  Future<void> _confirmDeleteLaborEntry(
    BuildContext context,
    WidgetRef ref,
    LaborEntry entry,
  ) async {
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

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(database_service_provider)
          .deleteLaborEntry(projectId, entry.id);
    } catch (error) {
      if (!context.mounted) {
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
      labor_entries_provider(projectId),
    );

    return _DashboardLogSection(
      icon: Icons.engineering_outlined,
      title: 'Labor Logs',
      helperText: 'Tap an entry to edit it. Use the trash icon to remove it.',
      actionLabel: 'Add Labor Entry',
      onActionPressed: onAddPressed,
      child: laborEntriesAsync.when(
        // AsyncValue.when keeps loading, error, and live data handling explicit.
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
                    contentPadding: EdgeInsets.zero,
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
                      '${_formatDate(entry.date)} • ${entry.hours.toStringAsFixed(2)} hrs • \$${entry.hourlyRate.toStringAsFixed(2)}/hr',
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
    required this.onEditEntry,
  });

  final String projectId;
  final VoidCallback onAddPressed;
  final ValueChanged<MaterialEntry> onEditEntry;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MaterialEntry>> materialEntriesAsync = ref.watch(
      material_entries_provider(projectId),
    );

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

  String _formatDate(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    final String year = value.year.toString();
    return '$month/$day/$year';
  }
}

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
