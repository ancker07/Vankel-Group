import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/intervention.dart';
import '../data/intervention_repository.dart';

class InterventionDetailsScreen extends ConsumerWidget {
  final String interventionId;

  const InterventionDetailsScreen({super.key, required this.interventionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interventions = ref.watch(interventionRepositoryProvider);
    final intervention = interventions.firstWhere(
      (i) => i.id == interventionId,
      orElse: () => throw Exception('Intervention not found'),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intervention Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Edit Intervention
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusSection(context, ref, intervention),
            const SizedBox(height: 24),
            _buildInfoCard(intervention),
            const SizedBox(height: 24),
            _buildCodesCard(intervention),
            const SizedBox(height: 24),
            _buildContactCard(intervention),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Generate Report
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generate Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, WidgetRef ref, Intervention intervention) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status',
            style: TextStyle(color: AppTheme.zinc500, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<InterventionStatus>(
                  value: intervention.status,
                  dropdownColor: AppTheme.zinc900,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.zinc800)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.brandGreen)),
                  ),
                  items: InterventionStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status.name.toUpperCase().replaceAll('_', ' '),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      ref.read(interventionRepositoryProvider.notifier).updateStatus(intervention.id, newStatus);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Intervention intervention) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          intervention.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, color: AppTheme.brandGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              intervention.address,
              style: const TextStyle(fontSize: 16, color: AppTheme.zinc300),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.calendar_today, color: AppTheme.zinc500, size: 20),
            const SizedBox(width: 8),
            Text(
              DateFormat('EEEE, MMM d, y - HH:mm').format(intervention.scheduledDate),
              style: const TextStyle(fontSize: 14, color: AppTheme.zinc500),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Description',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          intervention.description,
          style: const TextStyle(fontSize: 16, color: AppTheme.zinc300, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildCodesCard(Intervention intervention) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_open, color: Colors.red),
              const SizedBox(width: 8),
              const Text(
                'Access Codes & Keys',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (intervention.codes.isEmpty)
            const Text('No codes available', style: TextStyle(color: AppTheme.zinc500))
          else
            ...intervention.codes.map((code) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.key, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        code,
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildContactCard(Intervention intervention) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Info',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.zinc900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone, color: AppTheme.brandGreen),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    intervention.tenantContact ?? 'N/A',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const Text(
                    'Tap to call',
                    style: TextStyle(fontSize: 12, color: AppTheme.zinc500),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
