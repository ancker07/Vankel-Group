import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/enums/user_role_enum.dart';
import '../../auth/presentation/providers/auth_state_provider.dart';
import 'package:go_router/go_router.dart';
import '../../intervention/domain/document.dart';
import '../domain/mission.dart';
import './providers/mission_list_provider.dart';
import '../../../core/utils/translation_helper.dart';

class MissionDetailsScreen extends ConsumerWidget {
  final String missionId;

  const MissionDetailsScreen({super.key, required this.missionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionAsync = ref.watch(missionDetailProvider(missionId));
    final authState = ref.watch(authStateProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.missionDetails),
        actions: [
          if (authState.user?.role == UserRole.admin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/create-mission');
              },
            ),
        ],
      ),
      body: missionAsync.when(
        data: (mission) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusSection(context, ref, mission),
              const SizedBox(height: 24),
              _buildInfoCard(context, mission),
              const SizedBox(height: 24),
              _buildDescriptionCard(context, mission),
              // Syndic contact info
              if (mission.syndicName != null ||
                  mission.extractedSyndicName != null) ...[
                const SizedBox(height: 24),
                _buildSyndicContactCard(context, mission),
              ],
              if (mission.documents.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildDocumentsSection(mission, context),
              ],
              const SizedBox(height: 32),
              // Action Buttons for Admin
              if (authState.user?.role == UserRole.admin &&
                  (mission.status == MissionStatus.pending || mission.status == MissionStatus.needsReview)) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApprove(context, ref, mission, l10n),
                    icon: const Icon(Icons.check),
                    label: Text(l10n.approveMission),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReject(context, ref, mission, l10n),
                    icon: const Icon(Icons.close),
                    label: Text(l10n.rejectMission),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
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
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(missionDetailProvider(missionId)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(MissionStatus status, AppLocalizations l10n) {
    switch (status) {
      case MissionStatus.pending:
        return l10n.pendingRequest;
      case MissionStatus.approved:
        return l10n.accepted;
      case MissionStatus.rejected:
        return l10n.rejected;
      case MissionStatus.completed:
        return l10n.completed;
      case MissionStatus.needsReview:
        return l10n.needsReview;
    }
  }

  Widget _buildStatusSection(
    BuildContext context,
    WidgetRef ref,
    Mission mission,
  ) {
    Color statusColor;
    IconData statusIcon;

    switch (mission.status) {
      case MissionStatus.approved:
        statusColor = AppTheme.brandGreen;
        statusIcon = Icons.check_circle;
        break;
      case MissionStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case MissionStatus.completed:
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      case MissionStatus.needsReview:
        statusColor = Colors.orange;
        statusIcon = Icons.report_problem_outlined;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusLabel(mission.status, AppLocalizations.of(context)!),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.createdOn(
                    DateFormat('MMM d, y - HH:mm').format(mission.createdAt),
                  ),
                  style: const TextStyle(fontSize: 14, color: AppTheme.zinc500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Mission mission) {
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
          Row(
            children: [
              if (mission.isAiDetected) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: Colors.purple[200],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.aiDetected,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple[200],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              _buildUrgencyBadge(mission.urgency, AppLocalizations.of(context)!),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            TranslationHelper.getLocalizedField(
              context: context,
              enValue: mission.titleEn,
              frValue: mission.titleFr,
              nlValue: mission.titleNl,
              fallback: mission.title,
            ),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.location_on, color: AppTheme.brandGreen, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mission.address,
                  style: const TextStyle(fontSize: 16, color: AppTheme.zinc300),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context, Mission mission) {
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
          Text(
            AppLocalizations.of(context)!.description,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            TranslationHelper.getLocalizedField(
              context: context,
              enValue: mission.descriptionEn,
              frValue: mission.descriptionFr,
              nlValue: mission.descriptionNl,
              fallback: mission.description,
            ),
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.zinc300,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge(MissionUrgency urgency, AppLocalizations l10n) {
    Color color;
    String label;

    switch (urgency) {
      case MissionUrgency.urgent:
        color = Colors.red;
        label = l10n.urgent;
        break;
      case MissionUrgency.normal:
        color = Colors.orange;
        label = l10n.normal;
        break;
      case MissionUrgency.low:
        color = Colors.blue;
        label = l10n.low;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDocumentsSection(Mission mission, BuildContext context) {
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
          Text(
            AppLocalizations.of(context)!.attachments,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...mission.documents.map(
            (document) => _buildDocumentItem(document, context),
          ),
        ],
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Row(
        children: [
          Icon(
            document.isImage
                ? Icons.image
                : document.isPdf
                ? Icons.picture_as_pdf
                : Icons.insert_drive_file,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  document.fileType,
                  style: const TextStyle(fontSize: 12, color: AppTheme.zinc500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, color: AppTheme.brandGreen),
            onPressed: () async {
              final uri = Uri.parse(fullUrl);
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.couldNotOpen(document.fileName),
                        ),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
          ),
        ],
      ),
    );
  }
  Future<void> _handleApprove(BuildContext context, WidgetRef ref, Mission mission, AppLocalizations l10n) async {
    final result = await _showConfirmDialog(
      context: context,
      title: l10n.approveMission,
      content: l10n.approveMissionConfirm,
      mission: mission,
      isApprove: true,
      l10n: l10n,
    );

    if (result != null && result['confirmed'] == true) {
      try {
        await ref.read(missionListProvider.notifier).approveMission(
          mission.id,
          scheduledDate: result['date'],
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.missionApprovedSuccess), backgroundColor: Colors.green),
          );
          // Go back to the list
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref, Mission mission, AppLocalizations l10n) async {
    final result = await _showConfirmDialog(
      context: context,
      title: l10n.rejectMission,
      content: l10n.rejectMissionConfirm,
      mission: mission,
      isApprove: false,
      l10n: l10n,
    );

    if (result != null && result['confirmed'] == true) {
      try {
        await ref.read(missionListProvider.notifier).rejectMission(mission.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.missionRejected), backgroundColor: Colors.red),
          );
          // Go back to the list
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    required Mission mission,
    required bool isApprove,
    required AppLocalizations l10n,
  }) {
    DateTime? selectedDate;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.zinc950,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppTheme.zinc800),
          ),
          title: Row(
            children: [
              Icon(
                isApprove ? Icons.check_circle_outline : Icons.error_outline,
                color: isApprove ? AppTheme.brandGreen : Colors.red,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: const TextStyle(color: AppTheme.zinc300, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.zinc900.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.zinc800),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.missionHeader,
                        style: const TextStyle(
                          color: AppTheme.zinc500,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        TranslationHelper.getLocalizedField(
                          context: context,
                          enValue: mission.titleEn,
                          frValue: mission.titleFr,
                          nlValue: mission.titleNl,
                          fallback: mission.title,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isApprove) ...[
                  const SizedBox(height: 20),
                  Text(
                    l10n.interventionDateOptional,
                    style: const TextStyle(
                      color: AppTheme.zinc500,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppTheme.brandGreen,
                                onPrimary: Colors.black,
                                surface: AppTheme.zinc950,
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.zinc900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.zinc800),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: selectedDate != null ? AppTheme.brandGreen : AppTheme.zinc500,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedDate != null
                                ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                                : l10n.chooseADate,
                            style: TextStyle(
                              color: selectedDate != null ? Colors.white : AppTheme.zinc500,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (selectedDate != null) ...[
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => setState(() => selectedDate = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel.toUpperCase(), style: const TextStyle(color: AppTheme.zinc500, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'confirmed': true,
                'date': selectedDate?.toIso8601String(),
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: isApprove ? AppTheme.brandGreen : Colors.red,
                foregroundColor: isApprove ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                isApprove ? l10n.approve : l10n.reject,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyndicContactCard(BuildContext context, Mission mission) {
    final l10n = AppLocalizations.of(context)!;
    final name = mission.syndicName ?? mission.extractedSyndicName ?? 'Unknown';
    final email = mission.syndicEmail;
    final phone = mission.syndicPhone;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business_center_outlined,
                  color: AppTheme.brandGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.syndicCustomerInfo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.zinc800, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.business, size: 16, color: AppTheme.zinc500),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (email != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final uri = Uri(scheme: 'mailto', path: email);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, size: 16, color: AppTheme.zinc500),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.brandGreen,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.brandGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (phone != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final uri = Uri(scheme: 'tel', path: phone);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: AppTheme.zinc500),
                  const SizedBox(width: 10),
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.brandGreen,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.brandGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
