import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/material_entry.dart';
import '../models/project.dart';
import '../providers/project_providers.dart';

class AddMaterialEntryDialog extends ConsumerStatefulWidget {
  const AddMaterialEntryDialog({super.key, this.existingEntry});

  final MaterialEntry? existingEntry;

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

  bool get _isEditMode => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    final MaterialEntry? existingEntry = widget.existingEntry;
    if (existingEntry == null) {
      return;
    }

    _nameController.text = existingEntry.name;
    _quantityController.text = existingEntry.quantity.toString();
    _unitCostController.text = existingEntry.unitCost.toString();
    _vendorController.text = existingEntry.vendor ?? '';
    _notesController.text = existingEntry.notes ?? '';
  }

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Keep the dialog in place while a save is running.
      canPop: !_isSaving,
      child: AlertDialog(
        title: Row(
          children: <Widget>[
            Icon(
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
