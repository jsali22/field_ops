import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/labor_entry.dart';
import '../models/project.dart';
import '../providers/project_providers.dart';

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

  bool get _isEditMode => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    final LaborEntry? existingEntry = widget.existingEntry;
    if (existingEntry == null) {
      return;
    }

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

    final double? hours = double.tryParse(_hoursController.text.trim());
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
            notes: notes.isEmpty ? null : notes,
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
        // Async saves can finish after navigation, so stop before using context.
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Keep the dialog in place while a save is running.
      canPop: !_isSaving,
      child: AlertDialog(
        title: Row(
          children: <Widget>[
            Icon(
              Icons.engineering_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Text(_isEditMode ? 'Edit Labor Entry' : 'Add Labor Entry'),
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
                  'Capture labor hours, rate, and any useful notes for this project.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
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
                : Text(_isEditMode ? 'Save Labor Entry' : 'Add Labor Entry'),
          ),
        ],
      ),
    );
  }
}
