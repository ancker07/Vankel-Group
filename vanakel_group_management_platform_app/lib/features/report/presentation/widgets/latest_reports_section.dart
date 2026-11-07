import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_format.dart';
import '../../../../core/utils/app_labels.dart';
import '../../../../core/utils/translation_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/admin_badge.dart';
import '../../../intervention/domain/intervention.dart';
import '../report_actions.dart';

/// Dashboard: the five latest reports. A tap opens the PDF, "View all" opens the Reports page.
class LatestReportsSection extends ConsumerWidget {
  final List<Intervention> interventions;
  const LatestReportsSection({super.key, required this.interventions});

  static const _shown = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reports = latestReports(interventions).take(_shown).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.latestReports,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/admin/dashboard/reports'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.brandGreen),
              child: Text(l10n.viewAll, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (reports.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.zinc950,
              border: Border.all(color: AppTheme.zinc800),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              l10n.noReportsYet,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.zinc500, fontSize: 13),
            ),
          )
        else
          for (final report in reports)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ReportRow(
                report: report,
                onTap: () => openInterventionReport(context, ref, report),
              ),
            ),
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  final Intervention report;
  final VoidCallback onTap;
  const _ReportRow({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = report.status == InterventionStatus.delayed ? AppTheme.brandOrange : AppTheme.brandGreen;

    return Material(
      color: AppTheme.zinc950,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.zinc800),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationHelper.getLocalizedField(
                        context: context,
                        enValue: report.titleEn,
                        frValue: report.titleFr,
                        nlValue: report.titleNl,
                        fallback: report.title,
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      TranslationHelper.address(context, report.address),
                      style: const TextStyle(color: AppTheme.zinc500, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.interventionStatusLabel(report.status).toUpperCase(),
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                        Text(
                          AppFormat.date(context, report.completedAt ?? report.updatedAt ?? report.scheduledDate),
                          style: const TextStyle(color: AppTheme.zinc500, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        if (report.assignedToAdmin) const AdminBadge(show: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
