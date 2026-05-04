import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/labor_entry.dart';
import '../models/project.dart';
import '../providers/project_providers.dart';

// This class defines the AddLaborEntryDialog, which is a dialog that allows the user to input details for a new labor entry (role/task, hours, hourly rate, and optional notes) and save it to the database. It uses a ConsumerStatefulWidget because it needs to manage local widget state (form input and loading state) and also read providers to create a labor entry in the database when the form is submitted.
// Collects labor entries, validates them, builds a LaborEntry model, and submits it to the database service through the database_service_provider.
class AddLaborEntryDialog extends ConsumerStatefulWidget {
  const AddLaborEntryDialog({super.key, this.existingEntry});

  final LaborEntry? existingEntry;

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

  // A helper getter to determine if the dialog is in edit mode (editing an existing entry) or add mode (creating a new entry). This is based on whether an existingEntry was passed to the dialog.
  bool get _isEditMode => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    final LaborEntry? existingEntry = widget
        .existingEntry; // We store the existing entry in a local variable for easier access. If existingEntry is null, it means we are adding a new entry, and the form fields will start empty. If existingEntry is not null, we will populate the form fields with its data so that the user can edit it.
    if (existingEntry == null) {
      return;
    }

    // If an existing entry is provided, populate the form fields with its data so that the user can edit it. This allows the same dialog to be used for both adding new entries and editing existing ones.
    _roleTaskController.text = existingEntry.roleTask;
    _hoursController.text = existingEntry.hours.toString();
    _hourlyRateController.text = existingEntry.hourlyRate.toString();
    _notesController.text = existingEntry.notes ?? '';
  }

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

    // Validate that the hours and hourly rate inputs can be parsed as valid numbers before trying to create the labor entry. If either value is invalid, show an error message and stop the submission process.
    final double? hours = double.tryParse(
      // double.tryParse attempts to convert the input text as a double, and returns null if the input is not a valid number. This allows us to validate that the user has entered a valid numeric value for hours before trying to create the labor entry.
      _hoursController.text
          .trim(), // We use .trim() to remove any leading or trailing whitespace from the input before trying to parse it as a number, which helps prevent parsing errors if the user accidentally includes extra spaces.
    ); // double.tryParse attempts to convert the input text as a double, and returns null if the input is not a valid number. This allows us to validate that the user has entered a valid numeric value for hours before trying to create the labor entry.
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

    // Build the LaborEntry model using the input from the form fields. If we are in edit mode (editing an existing entry), we create a copy of the existing entry with the updated values. If we are in add mode (creating a new entry), we create a new LaborEntry instance with a unique ID and the current timestamp for createdAt.
    final String notes = _notesController.text.trim();
    final LaborEntry? existingEntry = widget.existingEntry;
    final DateTime now = DateTime.now();
    final LaborEntry entry = existingEntry == null
        ? LaborEntry(
            id: 'labor_${now.microsecondsSinceEpoch}',
            projectId: selectedProject.id,
            date: now,
            roleTask: _roleTaskController.text.trim(),
            hours: hours,
            hourlyRate: hourlyRate,
            notes: notes.isEmpty
                ? null
                : notes, // If the notes field is empty, we set notes to null in the LaborEntry model. This way, we can distinguish between an entry that has no notes (null) and an entry that has notes that are just an empty string. This also helps to keep the database cleaner by not storing empty strings for notes when there are no notes.
            createdAt: now,
          )
        : existingEntry.copyWith(
            projectId: selectedProject.id,
            roleTask: _roleTaskController.text.trim(),
            hours: hours,
            hourlyRate: hourlyRate,
            notes: notes.isEmpty ? null : notes,
            clearNotes: notes.isEmpty,
          );

    // Try to save the labor entry to the database using the database service provider. If we are in edit mode, we call updateLaborEntry to update the existing entry. If we are in add mode, we call createLaborEntry to create a new entry. We wrap this in a try-catch block to handle any errors that may occur during the database operation, and show an appropriate error message if something goes wrong.
    try {
      if (_isEditMode) {
        await ref.read(database_service_provider).updateLaborEntry(entry);
      } else {
        await ref.read(database_service_provider).createLaborEntry(entry);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode ? 'Labor entry updated.' : 'Labor entry added.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        // If this widget is no longer on screen, stop before trying to use its context to show a snackbar, since that would cause an error. This can happen if the user submits the form and then quickly dismisses the dialog before the async operation completes.
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Unable to update the labor entry. Please try again.'
                : 'Unable to add the labor entry. Please try again.',
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

  // The build method constructs the UI for the dialog, which includes a form with input fields for the labor entry details and buttons to cancel or submit the form. The submit button will show a loading spinner when the form is being submitted to provide feedback to the user.
  @override
  Widget build(BuildContext context) {
    return PopScope(
      // PopScope is used to prevent the user from accidentally dismissing the dialog while a save operation is in progress. When _isSaving is true, canPop is set to false, which disables the ability to pop the dialog (e.g., by tapping outside of it or pressing the back button) until the save operation is complete.
      canPop: !_isSaving,
      child: AlertDialog(
        title: Text(_isEditMode ? 'Edit Labor Entry' : 'Add Labor Entry'),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
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
                      // Validate that the role/task field is not empty. If it is empty, return an error message that will be displayed below the input field. If it is valid, return null to indicate no validation error.
                      return 'Role/Task is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
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
                const SizedBox(height: 14),
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
                const SizedBox(height: 14),
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
                : Text(_isEditMode ? 'Save Changes' : 'Add Entry'),
          ),
        ],
      ),
    );
  }
}
