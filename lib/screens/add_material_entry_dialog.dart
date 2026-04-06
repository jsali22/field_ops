import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/material_entry.dart';
import '../models/project.dart';
import '../providers/project_providers.dart';

class AddMaterialEntryDialog extends ConsumerStatefulWidget {
  const AddMaterialEntryDialog({super.key});

  @override
  ConsumerState<AddMaterialEntryDialog> createState() =>
      _AddMaterialEntryDialogState();
}

class _AddMaterialEntryDialogState
    extends ConsumerState<AddMaterialEntryDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitCostController = TextEditingController();
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitCostController.dispose();
    _vendorController.dispose();
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

    setState(() {
      _isSaving = true;
    });

    final DateTime now = DateTime.now();
    final String vendor = _vendorController.text.trim();
    final String notes = _notesController.text.trim();
    final MaterialEntry entry = MaterialEntry(
      id: 'material_${now.microsecondsSinceEpoch}',
      projectId: selectedProject.id,
      date: now,
      name: _nameController.text.trim(),
      quantity: quantity,
      unitCost: unitCost,
      vendor: vendor.isEmpty ? null : vendor,
      notes: notes.isEmpty ? null : notes,
      createdAt: now,
    );

    try {
      await ref.read(database_service_provider).createMaterialEntry(entry);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Material entry added.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Failed to add material entry: $error')),
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
    return PopScope( // PopScope is used to prevent the user from accidentally dismissing the dialog while a save operation is in progress. When _isSaving is true, canPop is set to false, which disables the ability to pop the dialog (e.g., by tapping outside of it or pressing the back button) until the save operation is complete.
      canPop: !_isSaving,
      child: AlertDialog(
        title: const Text('Add Material Entry'),
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
                  decoration: const InputDecoration(labelText: 'Name'),
                  textInputAction: TextInputAction.next,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vendorController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Vendor (Optional)',
                  ),
                  textInputAction: TextInputAction.next,
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
      ),
    );
  }
}
