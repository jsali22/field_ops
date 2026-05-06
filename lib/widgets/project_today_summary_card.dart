import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/labor_entry.dart';
import '../models/material_entry.dart';
import '../providers/project_providers.dart';

// This widget turns the existing labor/material streams into a simple live
// "today" snapshot without adding more Firestore queries.
class ProjectTodaySummaryCard extends ConsumerWidget {
  const ProjectTodaySummaryCard({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LaborEntry>> laborEntriesAsync = ref.watch(
      labor_entries_provider(projectId),
    );
    final AsyncValue<List<MaterialEntry>> materialEntriesAsync = ref.watch(
      material_entries_provider(projectId),
    );

    // The summary depends on two live streams, so we wait for both before
    // calculating the totals.
    return laborEntriesAsync.when(
      data: (List<LaborEntry> laborEntries) {
        return materialEntriesAsync.when(
          data: (List<MaterialEntry> materialEntries) {
            final _TodaySummary summary = _calculateTodaySummary(
              laborEntries: laborEntries,
              materialEntries: materialEntries,
            );

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.today_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Today Summary',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Live totals for entries dated today.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        _SummaryTile(
                          label: 'Labor Hours',
                          value: _formatHours(summary.totalLaborHours),
                        ),
                        _SummaryTile(
                          label: 'Labor Cost',
                          value: _formatCurrency(summary.laborCostEstimate),
                        ),
                        _SummaryTile(
                          label: 'Material Cost',
                          value: _formatCurrency(summary.materialCostEstimate),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const _SummaryLoadingCard(),
          error: (Object error, StackTrace stackTrace) {
            return const _SummaryErrorCard(
              message: 'Unable to load today\'s summary right now.',
            );
          },
        );
      },
      loading: () => const _SummaryLoadingCard(),
      error: (Object error, StackTrace stackTrace) {
        return const _SummaryErrorCard(
          message: 'Unable to load today\'s summary right now.',
        );
      },
    );
  }

  _TodaySummary _calculateTodaySummary({
    required List<LaborEntry> laborEntries,
    required List<MaterialEntry> materialEntries,
  }) {
    double totalLaborHours = 0;
    double laborCostEstimate = 0;
    double materialCostEstimate = 0;

    for (final LaborEntry entry in laborEntries) {
      if (_isToday(entry.date)) {
        totalLaborHours += entry.hours;
        laborCostEstimate += entry.hours * entry.hourlyRate;
      }
    }

    for (final MaterialEntry entry in materialEntries) {
      if (_isToday(entry.date)) {
        materialCostEstimate += entry.quantity * entry.unitCost;
      }
    }

    return _TodaySummary(
      totalLaborHours: totalLaborHours,
      laborCostEstimate: laborCostEstimate,
      materialCostEstimate: materialCostEstimate,
    );
  }

  // Matching on calendar day keeps the summary tied to the device's local
  // "today" value, which is enough for this MVP.
  bool _isToday(DateTime value) {
    final DateTime now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  static String _formatHours(double value) {
    final bool isWhole = value == value.truncateToDouble();
    return isWhole ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  static String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }
}

class _TodaySummary {
  const _TodaySummary({
    required this.totalLaborHours,
    required this.laborCostEstimate,
    required this.materialCostEstimate,
  });

  final double totalLaborHours;
  final double laborCostEstimate;
  final double materialCostEstimate;
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _SummaryLoadingCard extends StatelessWidget {
  const _SummaryLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading today\'s summary...'),
          ],
        ),
      ),
    );
  }
}

class _SummaryErrorCard extends StatelessWidget {
  const _SummaryErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
