import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/labor_entry.dart';
import '../models/project.dart';
import '../providers/project_providers.dart';

// This class defines the AddLaborEntryDialog, which is a dialog that allows the user to input details for a new labor entry (role/task, hours, hourly rate, and optional notes) and save it to the database. It uses a ConsumerStatefulWidget because it needs to manage local widget state (form input and loading state) and also read providers to create a labor entry in the database when the form is submitted.
// Collects labor entries, validates them, builds a LaborEntry model, and submits it to the database service through the database_service_provider. 
class AddLaborEntryDialog extends ConsumerStatefulWidget {
  const AddLaborEntryDialog({super.key});

  @override
  ConsumerState<AddLaborEntryDialog> createState() =>
      _AddLaborEntryDialogState();
}

class _AddLaborEntryDialogState extends ConsumerState<AddLaborEntryDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _roleTaskController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _roleTaskController.dispose();
    _hoursController.dispose();
    _hourlyRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Project? selectedProject = ref.read(selected_project_provider);
    if (selectedProject == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No project selected.')),
      );
      return;
    }

    final double? hours = double.tryParse(_hoursController.text.trim()); // double.tryParse attempts to convert the input text as a double, and returns null if the input is not a valid number. This allows us to validate that the user has entered a valid numeric value for hours before trying to create the labor entry.
    final double? hourlyRate = double.tryParse(
      _hourlyRateController.text.trim(),
    );
    if (hours == null || hourlyRate == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Enter valid numeric values for hours and hourly rate.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final DateTime now = DateTime.now();
    final String notes = _notesController.text.trim();
    final LaborEntry entry = LaborEntry(
      id: 'labor_${now.microsecondsSinceEpoch}',
      projectId: selectedProject.id,
      date: now,
      roleTask: _roleTaskController.text.trim(),
      hours: hours,
      hourlyRate: hourlyRate,
      notes: notes.isEmpty ? null : notes,
      createdAt: now,
    );

    try {
      await ref.read(database_service_provider).createLaborEntry(entry);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Labor entry added.')),
      );
    } catch (error) {
      if (!mounted) { // If this widget is no longer on screen, stop before trying to use its context to show a snackbar, since that would cause an error. This can happen if the user submits the form and then quickly dismisses the dialog before the async operation completes.
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Failed to add labor entry: $error')),
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
      title: const Text('Add Labor Entry'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _roleTaskController,
                autofocus: true,
                enabled: !_isSaving,
                decoration: const InputDecoration(labelText: 'Role/Task'),
                textInputAction: TextInputAction.next,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Role/Task is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hoursController,
                enabled: !_isSaving,
                decoration: const InputDecoration(labelText: 'Hours'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                validator: (String? value) {
                  final double? parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter valid hours';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hourlyRateController,
                enabled: !_isSaving,
                decoration: const InputDecoration(labelText: 'Hourly Rate'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                validator: (String? value) {
                  final double? parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed < 0) {
                    return 'Enter valid hourly rate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                ),
                maxLines: 3,
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
              : const Text('Add Entry'),
        ),
      ],
    );
  }
}
