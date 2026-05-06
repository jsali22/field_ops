import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';
import '../providers/project_providers.dart';

class CreateProjectDialog extends ConsumerStatefulWidget {
  const CreateProjectDialog({super.key, this.existingProject});

  final Project? existingProject;

  @override
  ConsumerState<CreateProjectDialog> createState() =>
      _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<CreateProjectDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isSaving = false;

  bool get _isEditMode => widget.existingProject != null;

  @override
  void initState() {
    super.initState();
    final Project? existingProject = widget.existingProject;
    if (existingProject == null) {
      return;
    }

    _nameController.text = existingProject.name;
    _clientController.text = existingProject.client ?? '';
    _addressController.text = existingProject.address ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isSaving = true;
    });

    final DateTime now = DateTime.now();
    final String name = _nameController.text.trim();
    final String client = _clientController.text.trim();
    final String address = _addressController.text.trim();
    final Project? existingProject = widget.existingProject;
    final Project project = existingProject == null
        ? Project(
            id: 'project_${now.microsecondsSinceEpoch}',
            name: name,
            ownerUid: '',
            client: client.isEmpty ? null : client,
            address: address.isEmpty ? null : address,
            createdAt: now,
            updatedAt: now,
          )
        : existingProject.copyWith(
            name: name,
            client: client.isEmpty ? null : client,
            address: address.isEmpty ? null : address,
            updatedAt: now,
            clearClient: client.isEmpty,
            clearAddress: address.isEmpty,
          );

    try {
      if (_isEditMode) {
        await ref.read(database_service_provider).updateProject(project);
      } else {
        await ref.read(database_service_provider).createProject(project);
      }

      final Project? selectedProject = ref.read(selected_project_provider);
      if (selectedProject?.id == project.id) {
        ref.read(selected_project_provider.notifier).selectProject(project);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Project "$name" updated.'
                : 'Project "$name" created.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Unable to update the project. Please try again.'
                : 'Unable to create the project. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Keep the dialog in place while a save is running.
      canPop: !_isSaving,
      child: AlertDialog(
        title: Row(
          children: <Widget>[
            Icon(
              _isEditMode
                  ? Icons.edit_outlined
                  : Icons.create_new_folder_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Text(_isEditMode ? 'Edit Project' : 'Create Project'),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _isEditMode
                      ? 'Update the project details below.'
                      : 'Add a project name now. Client and address can be added now or later.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(labelText: 'Project Name'),
                  textInputAction: TextInputAction.next,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Project name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _clientController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(labelText: 'Client'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(labelText: 'Address'),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditMode ? 'Save Project' : 'Create Project'),
          ),
        ],
      ),
    );
  }
}
