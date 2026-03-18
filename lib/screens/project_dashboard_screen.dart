import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';
import '../providers/project_providers.dart';

class ProjectDashboardScreen extends ConsumerWidget { // ConsumerWidget allows the screen to read and watch providers through the WidgetRef object. The dashboard screen needs to read the selected_project_provider to know which project to display, so it needs to be a ConsumerWidget.
  const ProjectDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Project? selectedProject = ref.watch(selected_project_provider); // Watch/read the selected_project_provider to get the currently selected project from the app state. This will allow the dashboard screen to display the correct project details based on which project was selected in the ProjectsScreen.

    if (selectedProject == null) { // If no project is selected, show a placeholder screen with a message indicating that no project is selected. This can happen if the user navigates to the dashboard screen without selecting a project first, or if the selected project was somehow cleared from the state.
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
          const _DashboardSectionCard(
            title: 'Labor Logs',
            placeholder: 'No entries yet',
            buttonLabel: 'Add Labor Entry',
            icon: Icons.engineering_outlined,
            onPressed: _handleAddLaborEntry,
          ),
          const SizedBox(height: 16),
          const _DashboardSectionCard(
            title: 'Material Logs',
            placeholder: 'No entries yet',
            buttonLabel: 'Add Material Entry',
            icon: Icons.inventory_2_outlined,
            onPressed: _handleAddMaterialEntry,
          ),
        ],
      ),
    );
  }

  static void _handleAddLaborEntry() {
    // TODO: Navigate to the add labor entry flow in Step 2.6.
  }

  static void _handleAddMaterialEntry() {
    // TODO: Navigate to the add material entry flow in Step 2.7.
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
