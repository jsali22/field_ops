import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/material_entry.dart';
import '../models/project.dart';
import '../providers/project_providers.dart';

// This widget is a dialog that allows users to add or edit a material entry for a project. It includes form fields for the material name, quantity, unit cost, vendor, and notes. The dialog handles form validation, submission, and shows appropriate success or error messages using SnackBar.
class AddMaterialEntryDialog extends ConsumerStatefulWidget {
  const AddMaterialEntryDialog({super.key, this.existingEntry});

  final MaterialEntry? existingEntry;

  @override
  ConsumerState<AddMaterialEntryDialog> createState() =>
      _AddMaterialEntryDialogState();
}

// The state class for the AddMaterialEntryDialog manages the form state, including the text controllers for each form field, the loading state while saving, and the logic for submitting the form to create or update a material entry in the database. It also handles populating the form fields with existing data when editing an entry, and provides user feedback through SnackBar messages.
class _AddMaterialEntryDialogState
    extends ConsumerState<AddMaterialEntryDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitCostController = TextEditingController();
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;

  // A helper getter to determine if the dialog is in edit mode (editing an existing entry) or add mode (creating a new entry). This is based on whether an existingEntry was passed to the dialog.
  bool get _isEditMode => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    final MaterialEntry? existingEntry = widget
        .existingEntry; // We store the existing entry in a local variable for easier access. If existingEntry is null, it means we are adding a new entry, and the form fields will start empty. If existingEntry is not null, we will populate the form fields with its data so that the user can edit it.
    if (existingEntry == null) {
      return;
    }

    // If an existing entry is provided, populate the form fields with its data so that the user can edit it. This allows the same dialog to be used for both adding new entries and editing existing ones.
    _nameController.text = existingEntry.name;
    _quantityController.text = existingEntry.quantity.toString();
    _unitCostController.text = existingEntry.unitCost.toString();
    _vendorController.text = existingEntry.vendor ?? '';
    _notesController.text = existingEntry.notes ?? '';
  }

  // The dispose method is overridden to clean up the text controllers when the widget is removed from the widget tree. This is important to free up resources and prevent memory leaks, especially since we are using multiple controllers for the form fields.
  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitCostController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // The _submit method is responsible for validating the form, creating a new MaterialEntry instance with the input data, and calling the appropriate method on the database service to save the entry to Firestore. It also handles showing success and error messages using SnackBar, and manages the loading state while the async operation is in progress.
  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    // Get the ScaffoldMessengerState to show SnackBars for user feedback (e.g., success or error messages when saving the material entry).
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Project? selectedProject = ref.read(selected_project_provider);
    if (selectedProject == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No project selected.')),
      );
      return;
    }

    // Validate that the quantity and unit cost fields contain valid numeric values. If they are not valid numbers, show an error message and return early to prevent trying to save invalid data to the database.
    final double? quantity = double.tryParse(_quantityController.text.trim());
    final double? unitCost = double.tryParse(_unitCostController.text.trim());
    if (quantity == null || unitCost == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Enter valid numeric values for quantity and unit cost.',
          ),
        ),
      );
      return;
    }

    // Set the loading state to true to disable the form inputs and show a loading indicator while the save operation is in progress. This prevents multiple submissions and provides feedback to the user that their action is being processed.
    setState(() {
      _isSaving = true;
    });

    final String vendor = _vendorController.text.trim();
    final String notes = _notesController.text.trim();
    final MaterialEntry? existingEntry = widget.existingEntry;
    final DateTime now = DateTime.now();
    final MaterialEntry entry = existingEntry == null
        ? MaterialEntry(
            id: 'material_${now.microsecondsSinceEpoch}',
            projectId: selectedProject.id,
            date: now,
            name: _nameController.text.trim(),
            quantity: quantity,
            unitCost: unitCost,
            vendor: vendor.isEmpty ? null : vendor,
            notes: notes.isEmpty ? null : notes,
            createdAt: now,
          )
        : existingEntry.copyWith(
            projectId: selectedProject.id,
            name: _nameController.text.trim(),
            quantity: quantity,
            unitCost: unitCost,
            vendor: vendor.isEmpty ? null : vendor,
            notes: notes.isEmpty ? null : notes,
            clearVendor: vendor.isEmpty,
            clearNotes: notes.isEmpty,
          );

    try {
      if (_isEditMode) {
        await ref.read(database_service_provider).updateMaterialEntry(entry);
      } else {
        await ref.read(database_service_provider).createMaterialEntry(entry);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode ? 'Material entry updated.' : 'Material entry added.',
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
                ? 'Unable to update the material entry. Please try again.'
                : 'Unable to add the material entry. Please try again.',
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

  // The _submit method is called when the user presses the "Add Entry" button. It first checks if a save operation is already in progress or if the form validation fails, and if so, it returns early to prevent multiple submissions. It then retrieves the currently selected project from the provider, validates that numeric inputs for quantity and unit cost are valid numbers, and if everything is valid, it creates a new MaterialEntry object with the input data and calls the createMaterialEntry method on the database service to save it to Firestore. It also handles showing success or error messages using SnackBar and manages the loading state while the async operation is in progress.
  @override
  Widget build(BuildContext context) {
    return PopScope(
      // PopScope is used to prevent the user from accidentally dismissing the dialog while a save operation is in progress. When _isSaving is true, canPop is set to false, which disables the ability to pop the dialog (e.g., by tapping outside of it or pressing the back button) until the save operation is complete.
      canPop: !_isSaving,
      child: AlertDialog(
        title: Row(
          children: <Widget>[
            Icon(
              // An icon to visually represent the material entry, which adds some visual interest to the dialog and helps the user quickly identify the purpose of the form.
              Icons.inventory_2_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Text(_isEditMode ? 'Edit Material Entry' : 'Add Material Entry'),
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
                // A brief description at the top of the form to guide the user on what information they should enter for the material entry. This helps set expectations and provides context for the form fields below.
                Text(
                  'Track material quantity, cost, and supplier details for this project.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(labelText: 'Name'),
                  textInputAction: TextInputAction.next,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _quantityController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (String? value) {
                    final double? parsed = double.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter valid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _unitCostController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(labelText: 'Unit Cost'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (String? value) {
                    final double? parsed = double.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed < 0) {
                      return 'Enter valid unit cost';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _vendorController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Vendor (Optional)',
                  ),
                  textInputAction: TextInputAction.next,
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
                : Text(
                    _isEditMode ? 'Save Material Entry' : 'Add Material Entry',
                  ),
          ),
        ],
      ),
    );
  }
}
