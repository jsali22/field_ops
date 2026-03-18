import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';
import '../providers/project_providers.dart';

class CreateProjectDialog extends ConsumerStatefulWidget { // consumer stateful widget because we need to manage local widget state and also read providers to create a project in the database when the form is submitted.
  const CreateProjectDialog({super.key});

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
    // Right now the create dialog builds the Project object because the current service API expects a complete model instance.
    // I’d likely move ID generation and authenticated ownership assignment further into the service layer to keep the UI thinner.
    final User? user = FirebaseAuth.instance.currentUser; // So the dialog had to depend on FirebaseAuth directly to get the current user, build the Project, and generate the ID.
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to create a project.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final DateTime now = DateTime.now();
    final String name = _nameController.text.trim();
    final String client = _clientController.text.trim();
    final String address = _addressController.text.trim();
    final Project project = Project(
      // the create dialog builds the Project object because the current service API expects a complete model instance. As the architecture matures, I’d likely move ID generation and authenticated ownership assignment further into the service layer to keep the UI thinner.
      id: 'project_${now.microsecondsSinceEpoch}', // Generate a unique ID for the project using the current timestamp in microseconds. This is a simple way to create a unique identifier for the project without needing to rely on Firestore's auto-generated IDs.
      name: name,
      ownerUid: user.uid,
      client: client.isEmpty ? null : client,
      address: address.isEmpty ? null : address,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ref.read(database_service_provider).createProject(project);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Project "$name" created.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Failed to create project: $error')),
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
    return AlertDialog(
      title: const Text('Create Project'),
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
              : const Text('Create'),
        ),
      ],
    );
  }
}
