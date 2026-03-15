import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/api/api_constants.dart';
import '../domain/intervention.dart';
import '../domain/document.dart';
import 'providers/intervention_list_provider.dart';
import '../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../core/enums/user_role_enum.dart';

class InterventionDetailsScreen extends ConsumerWidget {
  final String interventionId;

  const InterventionDetailsScreen({super.key, required this.interventionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isAdmin = authState.user?.role == UserRole.admin;

    final interventionAsync = ref.watch(
      interventionDetailProvider(interventionId),
    );

    return Scaffold(
      backgroundColor: AppTheme.brandBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.zinc950,
        title: const Text(
          'INTERVENTION SLIP',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: AppTheme.brandGreen,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.zinc400),
            onPressed: () => ref.invalidate(interventionDetailProvider(interventionId)),
          ),
        ],
      ),
      body: interventionAsync.when(
        data: (intervention) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header card: Building + Syndic + Professional ---
              _buildEntityCard(intervention),
              const SizedBox(height: 16),

              // --- Status Section ---
              _buildStatusCard(intervention, isAdmin, ref),
              const SizedBox(height: 16),

              // --- On-Site Contact ---
              _buildContactCard(intervention),
              const SizedBox(height: 16),

              // --- Description ---
              _buildSection(
                icon: Icons.description_outlined,
                label: 'DESCRIPTION',
                child: Text(
                  intervention.description,
                  style: const TextStyle(
                    color: AppTheme.zinc300,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Admin Feedback ---
              if (intervention.adminFeedback != null &&
                  intervention.adminFeedback!.isNotEmpty)
                _buildSection(
                  icon: Icons.sticky_note_2_outlined,
                  label: 'ADMIN NOTE',
                  child: Text(
                    intervention.adminFeedback!,
                    style: const TextStyle(
                      color: AppTheme.zinc300,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
              if (intervention.adminFeedback != null &&
                  intervention.adminFeedback!.isNotEmpty)
                const SizedBox(height: 16),

              // --- Delay Info ---
              if (intervention.status == InterventionStatus.delayed)
                _buildDelayCard(intervention),
              if (intervention.status == InterventionStatus.delayed)
                const SizedBox(height: 16),

              // --- Documents ---
              if (intervention.documents.isNotEmpty) ...[
                _buildDocumentsSection(intervention, context),
                const SizedBox(height: 16),
              ],

              // --- Admin: Status Update Actions ---
              if (isAdmin) ...[
                _buildStatusUpdateButtons(intervention, ref),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(interventionDetailProvider(interventionId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Entity Header Card ---
  Widget _buildEntityCard(Intervention intervention) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Building
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppTheme.brandGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [intervention.address, intervention.city]
                      .where((e) => e != null && e.isNotEmpty)
                      .join(', '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Scheduled date
          Row(
            children: [
              const Icon(Icons.schedule, size: 13, color: AppTheme.zinc500),
              const SizedBox(width: 6),
              Text(
                DateFormat('EEEE, MMM d, y · HH:mm')
                    .format(intervention.scheduledDate),
                style: const TextStyle(
                    color: AppTheme.zinc500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.zinc800),
          const SizedBox(height: 12),
          // Syndic + Pro row
          Row(
            children: [
              Expanded(
                child: _buildEntityInfo(
                  label: 'SYNDIC',
                  name: intervention.syndicName ?? 'Unassigned',
                  icon: Icons.shield_outlined,
                ),
              ),
              Expanded(
                child: _buildEntityInfo(
                  label: 'PROFESSIONAL',
                  name: intervention.professionalName ?? 'Unassigned',
                  icon: Icons.engineering_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntityInfo({
    required String label,
    required String name,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.zinc500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.zinc500,
                      letterSpacing: 1)),
              Text(name,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  // --- Status Card ---
  Widget _buildStatusCard(
      Intervention intervention, bool isAdmin, WidgetRef ref) {
    final status = intervention.status;
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('STATUS',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.zinc500,
                      letterSpacing: 1)),
              Text(_getStatusLabel(status),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: color)),
            ],
          ),
          if (intervention.urgency != null) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getUrgencyColor(intervention.urgency).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _getUrgencyColor(intervention.urgency)
                        .withOpacity(0.3)),
              ),
              child: Text(
                intervention.urgency!.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _getUrgencyColor(intervention.urgency),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- On-Site Contact Card ---
  Widget _buildContactCard(Intervention intervention) {
    final hasContact = (intervention.onSiteContactName?.isNotEmpty == true) ||
        (intervention.onSiteContactPhone?.isNotEmpty == true) ||
        (intervention.onSiteContactEmail?.isNotEmpty == true);

    if (!hasContact) return const SizedBox.shrink();

    return _buildSection(
      icon: Icons.person_outline,
      label: 'ON-SITE CONTACT',
      child: Column(
        children: [
          if (intervention.onSiteContactName?.isNotEmpty == true)
            _buildContactRow(
              Icons.badge_outlined,
              intervention.onSiteContactName!,
            ),
          if (intervention.onSiteContactPhone?.isNotEmpty == true)
            _buildContactRow(
              Icons.phone_outlined,
              intervention.onSiteContactPhone!,
              onTap: () => _launchUrl('tel:${intervention.onSiteContactPhone}'),
            ),
          if (intervention.onSiteContactEmail?.isNotEmpty == true)
            _buildContactRow(
              Icons.email_outlined,
              intervention.onSiteContactEmail!,
              onTap: () =>
                  _launchUrl('mailto:${intervention.onSiteContactEmail}'),
            ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.brandGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: onTap != null ? AppTheme.brandGreen : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration:
                      onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Delay Info Card ---
  Widget _buildDelayCard(Intervention intervention) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.brandOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.brandOrange.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_outlined,
                  size: 16, color: AppTheme.brandOrange),
              SizedBox(width: 8),
              Text('DELAY INFORMATION',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.brandOrange,
                      letterSpacing: 1.5)),
            ],
          ),
          if (intervention.delayReason?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            const Text('REASON',
                style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.zinc500,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(intervention.delayReason!,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
          if (intervention.delayDetails?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            const Text('DETAILS',
                style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.zinc500,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(intervention.delayDetails!,
                style: const TextStyle(
                    color: AppTheme.zinc300, fontSize: 14, height: 1.5)),
          ],
          if (intervention.delayedRescheduleDate != null) ...[
            const SizedBox(height: 12),
            const Text('RESCHEDULED TO',
                style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.zinc500,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMM d, y')
                  .format(intervention.delayedRescheduleDate!),
              style: const TextStyle(
                  color: AppTheme.brandOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  // --- Documents Section ---
  Widget _buildDocumentsSection(Intervention intervention, BuildContext context) {
    return _buildSection(
      icon: Icons.attach_file,
      label: 'ATTACHMENTS',
      child: Column(
        children: intervention.documents
            .map((doc) => _buildDocumentItem(doc, context))
            .toList(),
      ),
    );
  }

  Widget _buildDocumentItem(Document document, BuildContext context) {
    final fullUrl = ApiConstants.getStorageUrl(document.filePath);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.zinc900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Row(
        children: [
          Icon(
            document.isImage
                ? Icons.image_outlined
                : document.isPdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.insert_drive_file_outlined,
            color: AppTheme.brandGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.fileName,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  document.fileType,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.zinc500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, color: AppTheme.brandGreen),
            onPressed: () => _launchUrl(fullUrl),
          ),
        ],
      ),
    );
  }

  // --- Admin Status Update Buttons ---
  Widget _buildStatusUpdateButtons(Intervention intervention, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'UPDATE STATUS',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppTheme.zinc500,
                letterSpacing: 1.5),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _StatusButton(
                label: 'PENDING',
                color: Colors.blueAccent,
                isActive: intervention.status == InterventionStatus.pending,
                onTap: intervention.status != InterventionStatus.pending
                    ? () => ref
                        .read(interventionListProvider.notifier)
                        .updateStatus(intervention.id, InterventionStatus.pending)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatusButton(
                label: 'DELAYED',
                color: AppTheme.brandOrange,
                isActive: intervention.status == InterventionStatus.delayed,
                onTap: intervention.status != InterventionStatus.delayed
                    ? () => ref
                        .read(interventionListProvider.notifier)
                        .updateStatus(intervention.id, InterventionStatus.delayed)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatusButton(
                label: 'DONE',
                color: AppTheme.brandGreen,
                isActive: intervention.status == InterventionStatus.completed,
                onTap: intervention.status != InterventionStatus.completed
                    ? () => ref
                        .read(interventionListProvider.notifier)
                        .updateStatus(
                            intervention.id, InterventionStatus.completed)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Reusable Section Widget ---
  Widget _buildSection({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.brandGreen),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.zinc500,
                    letterSpacing: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // --- Helpers ---
  String _getStatusLabel(InterventionStatus status) {
    switch (status) {
      case InterventionStatus.pending:
        return 'PENDING';
      case InterventionStatus.delayed:
        return 'DELAYED';
      case InterventionStatus.completed:
        return 'COMPLETED';
    }
  }

  Color _getStatusColor(InterventionStatus status) {
    switch (status) {
      case InterventionStatus.pending:
        return Colors.blueAccent;
      case InterventionStatus.delayed:
        return AppTheme.brandOrange;
      case InterventionStatus.completed:
        return AppTheme.brandGreen;
    }
  }

  Color _getUrgencyColor(String? urgency) {
    switch (urgency?.toUpperCase()) {
      case 'LOW':
        return AppTheme.zinc500;
      case 'MEDIUM':
        return Colors.blueAccent;
      case 'HIGH':
        return AppTheme.brandOrange;
      case 'CRITICAL':
        return Colors.red;
      default:
        return AppTheme.zinc500;
    }
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// --- Status Button Widget ---
class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback? onTap;

  const _StatusButton({
    required this.label,
    required this.color,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color : AppTheme.zinc800,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isActive ? color : AppTheme.zinc500,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
