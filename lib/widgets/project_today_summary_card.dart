import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/labor_entry.dart';
import '../models/material_entry.dart';
import '../providers/project_providers.dart';

class ProjectTodaySummaryCard extends ConsumerWidget {
  // ConsumerWidget because it needs to read providers to get the labor and material entries for the project and calculate the summary data reactively whenever those entries change in Firestore.
  const ProjectTodaySummaryCard({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LaborEntry>> laborEntriesAsync = ref.watch(
      // Watch the labor_entries_provider for the specific project ID to get a stream of labor entries for that project. This will allow the UI to reactively update whenever there are changes to the labor entries in Firestore for that project.
      labor_entries_provider(projectId),
    );
    final AsyncValue<List<MaterialEntry>> materialEntriesAsync = ref.watch(
      // Watch the material_entries_provider for the specific project ID to get a stream of material entries for that project. This will allow the UI to reactively update whenever there are changes to the material entries in Firestore for that project.
      material_entries_provider(projectId),
    );

    // Nested when: We need to wait for both the labor entries and material entries to load before we can calculate and display the summary data. By nesting the .when calls, we can handle the loading and error states for both streams independently, and only show the summary card when we have successfully loaded both sets of data. If either stream is still loading, we show a loading card, and if either stream has an error, we show an error card with the relevant message.
    return laborEntriesAsync.when(
      // Handle the async state of the labor entries stream. If it's loading, show a loading card. If there's an error, show an error card. If we have data, then we proceed to check the material entries stream.
      data: (List<LaborEntry> laborEntries) {
        return materialEntriesAsync.when(
          // Handle the async state of the material entries stream. If it's loading, show a loading card. If there's an error, show an error card. If we have data, then we can calculate the summary and show the summary card.
          data: (List<MaterialEntry> materialEntries) {
            final _TodaySummary summary = _calculateTodaySummary(
              // Calculate the summary data for today based on the labor entries and material entries. This method will iterate through the entries, filter for those that are from today, and calculate the total labor hours, labor cost estimate, and material cost estimate for today's work on the project.
              laborEntries: laborEntries,
              materialEntries: materialEntries,
            );

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Today Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        _SummaryTile(
                          label: 'Labor Hours',
                          value: _formatHours(
                            summary.totalLaborHours,
                          ), // Format the total labor hours to show a whole number if it's a whole hour, or two decimal places if it's a fractional hour. This makes the display cleaner and easier to read, especially when the total labor hours is a whole number.
                        ),
                        _SummaryTile(
                          label: 'Labor Cost',
                          value: _formatCurrency(
                            summary.laborCostEstimate,
                          ), // Format the labor cost estimate as a currency string with a dollar sign and two decimal places. This makes it clear that this value represents a monetary amount and improves readability.
                        ),
                        _SummaryTile(
                          label: 'Material Cost',
                          value: _formatCurrency(
                            summary.materialCostEstimate,
                          ), // Format the material cost estimate as a currency string with a dollar sign and two decimal places. This makes it clear that this value represents a monetary amount and improves readability.
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () =>
              const _SummaryLoadingCard(), // Show a loading card while the material entries stream is still loading. We want to show this if either stream is loading, so that the user knows that data is being loaded and the summary will appear once it's ready.
          error: (Object error, StackTrace stackTrace) {
            return _SummaryErrorCard(
              message: 'Unable to load today\'s summary right now.',
            );
          },
        );
      },
      loading: () =>
          const _SummaryLoadingCard(), // Show a loading card while the labor entries stream is still loading. We want to show this if either stream is loading, so that the user knows that data is being loaded and the summary will appear once it's ready.
      error: (Object error, StackTrace stackTrace) {
        return _SummaryErrorCard(
          message: 'Unable to load today\'s summary right now.',
        );
      },
    );
  }

  // The _calculateTodaySummary method takes the list of labor entries and material entries, filters them for entries that are from today, and calculates the total labor hours, labor cost estimate, and material cost estimate for today's work on the project. It returns a _TodaySummary object that contains these calculated values.
  _TodaySummary _calculateTodaySummary({
    required List<LaborEntry> laborEntries,
    required List<MaterialEntry> materialEntries,
  }) {
    double totalLaborHours = 0;
    double laborCostEstimate = 0;
    double materialCostEstimate = 0;

    // Iterate through the labor entries and sum up the hours and calculate the labor cost estimate for entries that are from today. We check if each entry's date is today using the _isToday helper method, and if it is, we add its hours to the total labor hours and calculate its cost by multiplying the hours by the hourly rate and adding that to the labor cost estimate.
    for (final LaborEntry entry in laborEntries) {
      if (_isToday(entry.date)) {
        totalLaborHours += entry.hours;
        laborCostEstimate += entry.hours * entry.hourlyRate;
      }
    }

    // Iterate through the material entries and calculate the material cost estimate for entries that are from today. We check if each entry's date is today using the _isToday helper method, and if it is, we calculate its cost by multiplying the quantity by the unit cost and adding that to the material cost estimate.
    for (final MaterialEntry entry in materialEntries) {
      if (_isToday(entry.date)) {
        materialCostEstimate += entry.quantity * entry.unitCost;
      }
    }

    // Return a _TodaySummary object that contains the calculated total labor hours, labor cost estimate, and material cost estimate for today's work on the project. This object will be used to display the summary data in the UI.
    return _TodaySummary(
      totalLaborHours: totalLaborHours,
      laborCostEstimate: laborCostEstimate,
      materialCostEstimate: materialCostEstimate,
    );
  }

  // The _isToday helper method checks if a given DateTime value is from the same calendar day as the current date. It compares the year, month, and day components of the value to the current date to determine if they match. This is used to filter the labor and material entries to only include those that are from today when calculating the summary data.
  bool _isToday(DateTime value) {
    final DateTime now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  // The _formatHours helper method formats a double value representing hours into a string. If the value is a whole number (e.g., 8.0), it formats it without decimal places (e.g., "8"). If the value has a fractional part (e.g., 8.5), it formats it with two decimal places (e.g., "8.50"). This makes the display of labor hours cleaner and more user-friendly, especially when the total labor hours is a whole number.
  static String _formatHours(double value) {
    final bool isWhole = value == value.truncateToDouble();
    return isWhole ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  // The _formatCurrency helper method formats a double value representing a monetary amount into a string with a dollar sign and two decimal places (e.g., 123.456 becomes "$123.46"). This makes it clear that the value represents a currency amount and improves readability in the UI when displaying the labor and material cost estimates.
  static String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }
}

// The _TodaySummary class is a simple data class that holds the calculated summary values for today's labor hours, labor cost estimate, and material cost estimate. It is used to pass this summary data from the _calculateTodaySummary method to the UI for display in the summary card.
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

// The _SummaryLoadingCard and _SummaryErrorCard are simple widgets that display a loading indicator or an error message, respectively. They are used in the ProjectTodaySummaryCard to show appropriate feedback to the user while the labor and material entries are being loaded from Firestore, or if there was an error loading that data. This helps improve the user experience by providing clear feedback on the state of the data loading process.
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
