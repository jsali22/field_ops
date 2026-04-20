import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';
import '../providers/project_providers.dart';

class CreateProjectDialog extends ConsumerStatefulWidget {
  // consumer stateful widget because we need to manage local widget state and also read providers to create a project in the database when the form is submitted.
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

  bool get _isEditMode => widget.existingProject != null; // A helper getter to determine if we are editing an existing project or creating a new one based on whether an existingProject was passed to the dialog.

  @override
  void initState() {
    super.initState();
    final Project? existingProject = widget.existingProject; // We store the existing project in a local variable for easier access. If existingProject is null, it means we are creating a new project, and the form fields will start empty. If existingProject is not null, we will populate the form fields with its data so that the user can edit it.
    if (existingProject == null) {
      return;
    }

    // If an existing project is provided, populate the form fields with its data so that the user can edit it. This allows the same dialog to be used for both creating new projects and editing existing ones.
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

  // The _submit method is responsible for validating the form, creating a new Project instance with the input data, and calling the createProject method of the DatabaseService to save the project to Firestore. It also handles showing success and error messages using SnackBar, and manages the loading state while the project is being created.
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
            id: 'project_${now.microsecondsSinceEpoch}', // Generate a unique ID for the project using the current timestamp in microseconds. This is a simple way to create a unique identifier for the project without needing to rely on Firestore's auto-generated IDs.
            name: name,
            ownerUid:
                '', // The ownerUid will be set in the DatabaseService when we create the project, so we can leave it empty here.
            client: client.isEmpty ? null : client,
            address: address.isEmpty ? null : address,
            createdAt: now,
            updatedAt: now,
          )
        : existingProject.copyWith( // If we are editing an existing project, we create a copy of it with the updated values from the form fields. The copyWith method allows us to create a new instance of Project with some fields changed while keeping the others the same.
            name: name,
            client: client.isEmpty ? null : client,
            address: address.isEmpty ? null : address,
            updatedAt: now,
            clearClient: client.isEmpty,
            clearAddress: address.isEmpty,
          );

    try { // Try to save the project to the database using the database service provider. If we are in edit mode, we call updateProject to update the existing project. If we are in create mode, we call createProject to create a new project. We wrap this in a try-catch block to handle any errors that may occur during the database operation, and show an appropriate error message if something goes wrong.
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
                ? 'Failed to update project: $error'
                : 'Failed to create project: $error',
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
      // PopScope is used to prevent the user from accidentally dismissing the dialog while a save operation is in progress. When _isSaving is true, canPop is set to false, which disables the ability to pop the dialog (e.g., by tapping outside of it or pressing the back button) until the save operation is complete.
      canPop: !_isSaving,
      child: AlertDialog(
        title: Text(_isEditMode ? 'Edit Project' : 'Create Project'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _clientController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(labelText: 'Client'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
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
                : Text(_isEditMode ? 'Save Changes' : 'Create'),
          ),
        ],
      ),
    );
  }
}
