import '../../../core/services/pdf_service.dart';
import '../../../shared/widgets/mission_map.dart';
import '../../../core/utils/launcher.dart';
import '../../../core/services/map_service.dart';
import '../../../core/error/error_text.dart';
import '../../../core/utils/app_format.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart' as dio;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/utils/file_opener.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/intervention.dart';
import 'providers/intervention_list_provider.dart';
import 'providers/intervention_provider.dart';
import 'widgets/intervention_delay_sheet.dart';
import '../../../../core/utils/translation_helper.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../shared/widgets/dictation_button.dart';
import '../../../shared/widgets/team_member_tracker.dart';
import '../../auth/presentation/providers/auth_state_provider.dart';

class InterventionDetailsScreen extends ConsumerStatefulWidget {
  final String interventionId;

  const InterventionDetailsScreen({super.key, required this.interventionId});

  @override
  ConsumerState<InterventionDetailsScreen> createState() =>
      _InterventionDetailsScreenState();
}

class _InterventionDetailsScreenState
    extends ConsumerState<InterventionDetailsScreen> {
  bool _isSaving = false;
  bool _isInitialized = false;
  late TextEditingController _adminNoteController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _contactEmailController;

  // Local state for 'REGISTER' workflow
  InterventionStatus? _localStatus;
  String? _localSyndicId;
  String? _localProId;
  String? _localDelayReason;
  String? _localDelayDetails;
  DateTime? _localDelayedRescheduleDate;
  final List<XFile> _selectedImages = [];
  final List<File> _selectedDocs = [];
  final ImagePicker _picker = ImagePicker();
  bool _isImproving = false;

  @override
  void initState() {
    super.initState();
    _adminNoteController = TextEditingController();
    _contactNameController = TextEditingController();
    _contactPhoneController = TextEditingController();
    _contactEmailController = TextEditingController();
  }

  @override
  void dispose() {
    _adminNoteController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  void _initializeControllers(Intervention intervention) {
    if (_isInitialized) return;

    if (_adminNoteController.text.isEmpty) {
      _adminNoteController.text = intervention.adminFeedback ?? '';
    }
    _contactNameController.text = intervention.onSiteContactName ?? '';
    _contactPhoneController.text = intervention.onSiteContactPhone ?? '';
    _contactEmailController.text = intervention.onSiteContactEmail ?? '';

    // Auto-fill logic from description if contact fields are empty after loading
    if (_contactNameController.text.isEmpty &&
        _contactPhoneController.text.isEmpty) {
      final pattern = RegExp(
        r'(?:contact|sur place|contact sur place)\s*[:]\s*([^\d\n(]+)(?:\(([^)]+)\))?',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(intervention.description);
      if (match != null) {
        String name = match.group(1)?.trim() ?? '';
        name = name.replaceAll(
          RegExp(r'^(M\.|Mr\.|Mme\.|Mle\.)\s*', caseSensitive: false),
          '',
        );
        final phone =
            match.group(2)?.trim().replaceAll(RegExp(r'[^\d+]'), '') ?? '';

        if (name.isNotEmpty) _contactNameController.text = name;
        if (phone.isNotEmpty) _contactPhoneController.text = phone;
      }
    }

    _localStatus ??= intervention.status;
    _localSyndicId ??= (intervention.syndicId ?? intervention.buildingSyndicId);
    _localProId ??= intervention.proId;
    _localDelayReason ??= intervention.delayReason;
    _localDelayDetails ??= intervention.delayDetails;
    _localDelayedRescheduleDate ??= intervention.delayedRescheduleDate;

    _isInitialized = true;
  }

  /// Photos: camera or gallery. Photos are resized: full-size phone pictures are 5-12 MB.
  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.zinc900,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.camera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.gallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      if (source == ImageSource.camera) {
        final image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        if (image != null && mounted) setState(() => _selectedImages.add(image));
      } else {
        final images = await _picker.pickMultiImage(imageQuality: 70, maxWidth: 1920, maxHeight: 1920);
        if (images.isNotEmpty && mounted) setState(() => _selectedImages.addAll(images));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pdfError(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Documents (same types and 10 MB limit as the server accepts).
  Future<void> _pickDocuments() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
        allowMultiple: true,
      );
      if (result == null) return;

      const maxBytes = 10 * 1024 * 1024;
      final accepted = <File>[];
      for (final f in result.files) {
        final filePath = f.path;
        if (filePath == null) continue;
        final file = File(filePath);
        if (await file.length() > maxBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.fileTooLarge(f.name)), backgroundColor: Colors.red),
            );
          }
          continue;
        }
        accepted.add(file);
      }
      if (accepted.isNotEmpty && mounted) setState(() => _selectedDocs.addAll(accepted));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pdfError(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// "Send to Admin": the technician picked Completed or Delayed (a delay needs its reason) and hands
  /// the work over for review. The server checks the same rules; this just answers without a round trip.
  void _submitToAdmin(Intervention i, AppLocalizations l10n) {
    final messenger = ScaffoldMessenger.of(context);
    void refuse(String message) =>
        messenger.showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));

    final status = _localStatus ?? i.status;
    if (status == InterventionStatus.pending) return refuse(l10n.submitNeedsStatus);
    final reason = _localDelayReason ?? i.delayReason;
    if (status == InterventionStatus.delayed && (reason == null || reason.trim().isEmpty)) {
      return refuse(l10n.submitNeedsDelayReason);
    }
    _executeRegister(i.id, mode: 'SUBMIT');
  }

  Future<void> _executeRegister(String id, {String mode = 'NONE'}) async {
    setState(() => _isSaving = true);
    try {
      final formData = dio.FormData();
      formData.fields.addAll([
        MapEntry('admin_feedback', _adminNoteController.text),
        MapEntry('on_site_contact_name', _contactNameController.text),
        MapEntry('on_site_contact_phone', _contactPhoneController.text),
        MapEntry('on_site_contact_email', _contactEmailController.text),
        MapEntry('save_mode', mode),
      ]);

      if (_localStatus != null) {
        formData.fields.add(
          MapEntry('status', _localStatus!.name.toUpperCase()),
        );
      }
      if (_localSyndicId != null) {
        formData.fields.add(MapEntry('syndic_id', _localSyndicId!));
      }
      if (_localProId != null) {
        formData.fields.add(MapEntry('pro_id', _localProId!));
      }

      if (_localStatus == InterventionStatus.delayed) {
        if (_localDelayReason != null)
          formData.fields.add(MapEntry('delay_reason', _localDelayReason!));
        if (_localDelayDetails != null)
          formData.fields.add(MapEntry('delay_details', _localDelayDetails!));
        if (_localDelayedRescheduleDate != null) {
          formData.fields.add(
            MapEntry(
              'delayed_reschedule_date',
              _localDelayedRescheduleDate!.toIso8601String(),
            ),
          );
        }
      }

      for (final image in _selectedImages) {
        formData.files.add(
          MapEntry(
            'photos[]',
            await dio.MultipartFile.fromFile(image.path, filename: image.name),
          ),
        );
      }

      for (final doc in _selectedDocs) {
        formData.files.add(
          MapEntry(
            'files[]',
            await dio.MultipartFile.fromFile(doc.path, filename: doc.path.split(Platform.pathSeparator).last),
          ),
        );
      }

      // "Save & send e-mail": the PDF report goes along (same as on the website)
      if (mode == 'EMAIL') await _attachReportPdf(formData, id);

      final result = await ref
          .read(interventionListProvider.notifier)
          .registerIntervention(id, formData);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        // Say what really happened: who got the report (the e-mail is sent by the server right after the save)
        var message = l10n.interventionRegisteredSuccess;
        var color = AppTheme.brandGreen;
        if (mode == 'SUBMIT') {
          message = l10n.sentToAdminSuccess;
        } else if (mode == 'EMAIL') {
          final report = result.report;
          if (report == null || !report.delivered) {
            message = l10n.reportNotSent;
            color = Colors.red;
          } else if (report.complete) {
            message = l10n.reportSentTo(report.sent.length);
          } else {
            message = l10n.reportPartial(report.sent.length, report.failed.length);
            color = AppTheme.brandOrange;
          }
        }
        setState(() {
          _isSaving = false;
          _selectedImages.clear();
          _selectedDocs.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 6)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorWithMessage(context, e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Builds the PDF report (with what the user just typed) and adds it to the save, so the e-mail
  /// carries it. A PDF problem must never block the save / the e-mail.
  Future<void> _attachReportPdf(dio.FormData formData, String id) async {
    try {
      final current = ref.read(interventionDetailProvider(id)).value;
      if (current == null) return;
      final report = current.copyWith(
        adminFeedback: _adminNoteController.text,
        status: _localStatus ?? current.status,
        delayReason: _localDelayReason ?? current.delayReason,
        delayDetails: _localDelayDetails ?? current.delayDetails,
      );
      final bytes = await PdfService.buildInterventionReport(
        intervention: report,
        building: null,
        professional: null,
        syndic: null,
        lang: Localizations.localeOf(context).languageCode,
      );
      formData.files.add(MapEntry('files[]', dio.MultipartFile.fromBytes(bytes, filename: PdfService.fileNameFor(id))));
    } catch (e) {
      debugPrint('Report PDF not attached: $e');
    }
  }

  Future<void> _handleDelay(String id, Intervention intervention) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InterventionDelaySheet(
        initialReason: _localDelayReason ?? intervention.delayReason,
        initialDetails: _localDelayDetails ?? intervention.delayDetails,
        initialDate:
            _localDelayedRescheduleDate ?? intervention.delayedRescheduleDate,
      ),
    );

    if (result != null) {
      setState(() {
        _localStatus = InterventionStatus.delayed;
        _localDelayReason = result['reason'];
        _localDelayDetails = result['details'];
        _localDelayedRescheduleDate = result['date'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final interventionAsync = ref.watch(
      interventionDetailProvider(widget.interventionId),
    );

    return Scaffold(
      backgroundColor: AppTheme.brandBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.zinc950,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: interventionAsync.when(
          data: (i) => Text(
            TranslationHelper.getLocalizedField(
              context: context,
              enValue: i.titleEn,
              frValue: i.titleFr,
              nlValue: i.titleNl,
              fallback: i.title,
            ).toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          loading: () => Text(l10n.loading),
          error: (_, __) => Text(l10n.error),
        ),
        actions: [
          interventionAsync.when(
            data: (i) => IconButton(
              icon: const Icon(Icons.rotate_left, color: AppTheme.brandOrange),
              tooltip: l10n.maintenance,
              onPressed: () => _showMaintenanceModal(context, i, l10n),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.zinc400),
            onPressed: () => ref.invalidate(
              interventionDetailProvider(widget.interventionId),
            ),
          ),
        ],
      ),
      body: interventionAsync.when(
        data: (intervention) {
          _initializeControllers(intervention);
          // A completed mission is read-only unless the role may reopen it (admin)
          final locked = intervention.status == InterventionStatus.completed &&
              !(ref.watch(authStateProvider).user?.can('interventions.reopen') ?? false);
          Widget editable(Widget child) => locked
              ? IgnorePointer(child: Opacity(opacity: 0.6, child: child))
              : child;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (locked) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.brandGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.brandGreen.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline, color: AppTheme.brandGreen, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(l10n.missionLocked,
                                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (intervention.submittedAt != null) ...[
                        _buildReviewBanner(intervention, l10n),
                        const SizedBox(height: 16),
                      ],
                      _buildSummaryCard(intervention, l10n),
                      const SizedBox(height: 24),
                      // Status control up top so admins / super admins can find it
                      editable(_buildStatusSection(intervention, l10n)),
                      const SizedBox(height: 24),
                      if (_canManageAssignments)
                        editable(_buildContactSection(intervention, l10n))
                      else
                        _buildTechnicianContactCard(l10n),
                      const SizedBox(height: 24),
                      _buildDescriptionSection(intervention, l10n),
                      const SizedBox(height: 24),
                      _buildMapSection(intervention, l10n),
                      const SizedBox(height: 24),
                      if (ref.watch(authStateProvider).user?.can('team.view') ?? false) ...[
                        TeamMemberTracker(interventionId: widget.interventionId),
                        const SizedBox(height: 24),
                      ],
                      editable(_buildFeedbackSection(intervention, l10n)),
                      const SizedBox(height: 24),
                      editable(_buildMediaAuditSection(intervention, l10n)),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              if (!locked) _buildFooter(intervention, l10n),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.brandGreen),
        ),
        error: (e, __) => Center(
          child: Text(errorWithMessage(context, e), style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  /// Who / where at a glance: reference, address, syndic and the assigned professional.
  /// Shown to everyone while the work waits for an admin's review.
  Widget _buildReviewBanner(Intervention i, AppLocalizations l10n) {
    final who = i.submittedByName;
    final when = AppFormat.dateTime(context, i.submittedAt!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.brandOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.brandOrange.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        const Icon(Icons.hourglass_top_outlined, color: AppTheme.brandOrange, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.awaitingAdminReview, style: const TextStyle(fontWeight: FontWeight.w800)),
            if (who != null && who.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(l10n.submittedByOn(who, when), style: const TextStyle(fontSize: 12, color: AppTheme.zinc400)),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSummaryCard(Intervention i, AppLocalizations l10n) {
    Widget row(IconData icon, String label, String? value) {
      if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppTheme.zinc500),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.zinc500, letterSpacing: 1.2)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final location = [TranslationHelper.address(context, i.address), i.city].where((e) => e != null && e.trim().isNotEmpty).join(', ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (i.interventionNumber != null && i.interventionNumber!.isNotEmpty)
            Text('#${i.interventionNumber}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.brandGreen)),
          Text(i.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          row(Icons.place_outlined, l10n.propertyAddress, location),
          row(Icons.business_outlined, l10n.syndicManager, i.syndicName ?? i.extractedSyndicName),
          row(Icons.engineering_outlined, l10n.assignedProfessional, i.professionalName),
        ],
      ),
    );
  }

  /// Admins / super admins manage syndic, contact and assignment; technicians don't.
  bool get _canManageAssignments {
    final user = ref.read(authStateProvider).user;
    return user != null && (user.isSuperAdmin || user.can('missions.approve') || user.can('team.view'));
  }

  Future<void> _launch(String scheme, String value) async {
    final uri = Uri(scheme: scheme, path: value.trim());
    await openLink(context, uri);
  }

  /// Read-only on-site contact for technicians: who to ask for, and how to reach them.
  Widget _buildTechnicianContactCard(AppLocalizations l10n) {
    final name = _contactNameController.text.trim();
    final phone = _contactPhoneController.text.trim();
    final email = _contactEmailController.text.trim();

    Widget line(IconData icon, String label, String value, {String? scheme, Color? color}) {
      final has = value.isNotEmpty;
      return InkWell(
        onTap: has && scheme != null ? () => _launch(scheme, value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: has && scheme != null ? AppTheme.brandGreen : AppTheme.zinc500),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.zinc500, letterSpacing: 1.2)),
                    const SizedBox(height: 2),
                    Text(has ? value : '—',
                        style: TextStyle(
                            color: has ? (color ?? Colors.white) : AppTheme.zinc500,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (has && scheme != null)
                Icon(scheme == 'tel' ? Icons.call : Icons.mail_outline, size: 18, color: AppTheme.brandGreen),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppTheme.zinc500),
              const SizedBox(width: 8),
              Text(l10n.onSiteContact,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.zinc500, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 8),
          line(Icons.badge_outlined, l10n.name, name),
          line(Icons.phone_outlined, l10n.phoneTitle, phone, scheme: 'tel'),
          if (email.isNotEmpty) line(Icons.alternate_email, 'EMAIL', email, scheme: 'mailto'),
        ],
      ),
    );
  }

  Widget _buildContactSection(Intervention i, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 16,
                color: AppTheme.zinc500,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.onSiteContact,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.zinc500,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTextField(l10n.name, _contactNameController)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  l10n.phoneTitle,
                  _contactPhoneController,
                  hint: '+32 ...',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            l10n.emailOptional,
            _contactEmailController,
            hint: 'email@example.com',
          ),
          const SizedBox(height: 24),
          Text(
            l10n.syndicCustomerInfo,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppTheme.zinc500,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildSyndicDropdown(l10n),
          _buildExtractedSyndicInfo(i, l10n),
          _buildSyndicInfoCard(l10n),
        ],
      ),
    );
  }

  Widget _buildExtractedSyndicInfo(Intervention i, AppLocalizations l10n) {
    if (_localSyndicId != null || i.extractedSyndicName == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.brandOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.brandOrange.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.brandOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.brandOrange.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 20,
              color: AppTheme.brandOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.extractedSyndicUnmatched,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.brandOrange,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  i.extractedSyndicName!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  l10n.notMatchedToDatabase,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.zinc500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyndicInfoCard(AppLocalizations l10n) {
    if (_localSyndicId == null) return const SizedBox.shrink();

    final syndicsAsync = ref.watch(syndicListProvider);
    return syndicsAsync.when(
      data: (syndics) {
        final syndic = syndics.firstWhere(
          (s) => s['id'].toString() == _localSyndicId,
          orElse: () => null,
        );
        if (syndic == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.brandGreen.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.brandGreen.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.brandGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.brandGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 20,
                      color: AppTheme.brandGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.syndicManager,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.zinc500,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          syndic['company_name'] ?? syndic['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        if (syndic['contact_person'] != null)
                          Text(
                            syndic['contact_person'].toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.zinc500,
                              letterSpacing: 0.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (syndic['phone'] != null)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.smartphone_outlined,
                            size: 14,
                            color: AppTheme.brandGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            syndic['phone'],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.zinc300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (syndic['email'] != null)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(
                            Icons.mail_outline,
                            size: 14,
                            color: AppTheme.zinc500,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              syndic['email'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.zinc500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: AppTheme.zinc500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.zinc900,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.zinc800),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.zinc500, fontSize: 13),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyndicDropdown(AppLocalizations l10n) {
    final syndicsAsync = ref.watch(syndicListProvider);
    return syndicsAsync.when(
      data: (syndics) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.zinc900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.zinc800),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _localSyndicId,
            hint: Text(
              l10n.selectCustomer,
              style: const TextStyle(color: AppTheme.zinc500, fontSize: 13),
            ),
            isExpanded: true,
            dropdownColor: AppTheme.zinc950,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            items: syndics
                .map(
                  (s) => DropdownMenuItem(
                    value: s['id'].toString(),
                    child: Text(s['company_name'] ?? s['name'] ?? ''),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _localSyndicId = v),
          ),
        ),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => Text(l10n.errorLoadingSyndics),
    );
  }

  Widget _buildDescriptionSection(Intervention i, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.interventionDescription,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppTheme.brandGreen,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.zinc950,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.zinc800),
          ),
          child: Text(
            TranslationHelper.getLocalizedField(
              context: context,
              enValue: i.descriptionEn,
              frValue: i.descriptionFr,
              nlValue: i.descriptionNl,
              fallback: i.description,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(Intervention i, AppLocalizations l10n) {
    final user = ref.watch(authStateProvider).user;
    final canChangeStatus = user != null &&
        user.can('interventions.update') &&
        (i.status != InterventionStatus.completed || user.can('interventions.reopen'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.brandGreen,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            l10n.updateStatus,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatusBtn(
                label: l10n.inProgress,
                isActive: _localStatus == InterventionStatus.pending,
                color: AppTheme.zinc500,
                isEnabled: canChangeStatus,
                onTap: () =>
                    setState(() => _localStatus = InterventionStatus.pending),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatusBtn(
                label: l10n.delayed,
                isActive: _localStatus == InterventionStatus.delayed,
                color: AppTheme.brandOrange,
                isEnabled: canChangeStatus,
                onTap: () => _handleDelay(i.id, i),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatusBtn(
                label: l10n.completed,
                isActive: _localStatus == InterventionStatus.completed,
                color: AppTheme.brandGreen,
                isEnabled: canChangeStatus,
                onTap: () =>
                    setState(() => _localStatus = InterventionStatus.completed),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(Intervention i, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.technicalObservations,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppTheme.zinc500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        // all the note tools are visible at once (they used to hide in a sideways-scrolling row)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DictationButton(controller: _adminNoteController),
            _buildSmallBtn(Icons.camera_alt_outlined, l10n.photos, _pickImage),
            _buildSmallBtn(Icons.upload_file_outlined, l10n.documents, _pickDocuments),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 250,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.zinc950,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _adminNoteController.text.isNotEmpty
                  ? AppTheme.brandGreen.withValues(alpha: 0.3)
                  : AppTheme.zinc800,
              width: _adminNoteController.text.isNotEmpty ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _adminNoteController,
            maxLines: null,
            minLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: l10n.technicalFeedbackHint,
              hintStyle: const TextStyle(color: AppTheme.zinc500, fontSize: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              _buildAIBtn(l10n),
              const SizedBox(height: 8),
              Text(
                l10n.improveWithAi,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.brandGreen,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.zinc900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.zinc800),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppTheme.zinc500),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppTheme.zinc500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIBtn(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _isImproving
          ? null
          : () async {
              if (_adminNoteController.text.isEmpty) return;

              setState(() => _isImproving = true);
              try {
                final improved = await ref
                    .read(interventionListProvider.notifier)
                    .improveNote(_adminNoteController.text);
                if (mounted) {
                  _adminNoteController.text = improved;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.noteImprovedWithAi),
                      backgroundColor: AppTheme.brandGreen,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.aiErrorWithMessage(errorText(context, e))),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isImproving = false);
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isImproving
              ? AppTheme.brandGreen.withValues(alpha: 0.1)
              : AppTheme.zinc900,
          shape: BoxShape.circle,
          border: Border.all(
            color: _isImproving ? AppTheme.brandGreen : AppTheme.zinc800,
            width: 2,
          ),
          boxShadow: [
            if (_isImproving)
              BoxShadow(
                color: AppTheme.brandGreen.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
          ],
        ),
        child: _isImproving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.brandGreen,
                ),
              )
            : const Icon(
                Icons.auto_awesome_outlined,
                size: 24,
                color: AppTheme.brandGreen,
              ),
      ),
    );
  }

  Widget _buildMediaAuditSection(Intervention i, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.mediaAudit,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppTheme.zinc500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMediaBox(
                Icons.camera_alt_outlined,
                l10n.photos,
                count: _selectedImages.length.toString(),
                onTap: _pickImage,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMediaBox(
                Icons.upload_file_outlined,
                l10n.documents,
                count: (i.documents.length + _selectedDocs.length).toString(),
                onTap: _pickDocuments,
              ),
            ),
          ],
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_selectedImages[index].path),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImages.removeAt(index)),
                      child: const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        for (var n = 0; n < _selectedDocs.length; n++)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.attach_file, size: 18, color: AppTheme.brandGreen),
            title: Text(
              _selectedDocs[n].path.split(Platform.pathSeparator).last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _selectedDocs.removeAt(n)),
            ),
          ),
        // files already uploaded to this intervention (tap to open)
        for (final d in i.documents)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              d.isImage ? Icons.image_outlined : (d.isPdf ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined),
              size: 18,
              color: AppTheme.zinc400,
            ),
            title: Text(d.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.open_in_new, size: 16, color: AppTheme.brandGreen),
            onTap: () => openUploadedDocument(context, d),
          ),
        const SizedBox(height: 24),
        _buildAuditCard(l10n),
      ],
    );
  }

  Widget _buildMediaBox(
    IconData icon,
    String label, {
    String? count,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.zinc950,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.zinc800),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppTheme.zinc500),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppTheme.zinc500,
              ),
            ),
            if (count != null && count != '0') ...[
              const SizedBox(height: 4),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.brandGreen,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuditCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.auditTraceability,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: AppTheme.brandGreen,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.brandGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: AppTheme.brandGreen,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.interventionInitializedOn,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormat.dateTime(context, DateTime.now()),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.zinc500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Intervention i, AppLocalizations l10n) {
    // A user who cannot review work (a technician) hands it to the admin; admins keep "Register".
    final user = ref.watch(authStateProvider).user;
    final sendsToAdmin = user != null && !user.can('interventions.reopen');
    final lockedForTechnician = sendsToAdmin && i.status == InterventionStatus.completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.brandBlack,
        border: Border(top: BorderSide(color: AppTheme.zinc800)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (_isSaving || _isImproving || lockedForTechnician)
                ? null
                : () => sendsToAdmin ? _submitToAdmin(i, l10n) : _showRegisterOptionsModal(context, i, l10n),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: (_isSaving || _isImproving)
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(sendsToAdmin ? Icons.send_outlined : Icons.description_outlined, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        sendsToAdmin ? l10n.sendToAdmin : l10n.registerInterventionTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Where the work is: a map preview and a big GPS button (same card as on a mission).
  Widget _buildMapSection(Intervention i, AppLocalizations l10n) {
    final hasAddress = i.address.trim().isNotEmpty && i.address.trim() != 'No Address';
    final address = hasAddress ? [i.address, if ((i.city ?? '').trim().isNotEmpty) i.city!].join(', ') : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.locationAccess,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppTheme.brandGreen,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.zinc950,
              border: Border.all(color: AppTheme.zinc800),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (hasAddress) MissionMap(address: address),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationHelper.address(context, i.address),
                        style: const TextStyle(color: AppTheme.zinc300, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          // MapService shows a message when the phone has no maps app / no address
                          onPressed: () => _openMap(address.isEmpty ? i.address : address),
                          icon: const Icon(Icons.navigation),
                          label: Text(l10n.openGps),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Reject bottom sheet — overflow-safe
  // ---------------------------------------------------------------------------

  Future<void> _showMaintenanceModal(
    BuildContext context,
    Intervention i,
    AppLocalizations l10n,
  ) async {
    final titleController = TextEditingController(
      text: TranslationHelper.getLocalizedField(
        context: context,
        enValue: i.titleEn,
        frValue: i.titleFr,
        nlValue: i.titleNl,
        fallback: i.title,
      ),
    );
    final descController = TextEditingController(
      text: TranslationHelper.getLocalizedField(
        context: context,
        enValue: i.descriptionEn,
        frValue: i.descriptionFr,
        nlValue: i.descriptionNl,
        fallback: i.description,
      ),
    );
    DateTime startDate = DateTime.now();
    String frequency = 'YEARLY';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppTheme.zinc950,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.zinc800)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.createMaintenancePlan,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.brandOrange,
                        letterSpacing: 1.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.zinc500),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModalField(l10n.maintenanceTitle, titleController),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.startDate,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.zinc500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: startDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null) {
                                      setModalState(() => startDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.zinc900,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.zinc800,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: AppTheme.brandOrange,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppFormat.dateMedium(context, startDate),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.frequency,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.zinc500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.zinc900,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.zinc800),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: frequency,
                                      isExpanded: true,
                                      dropdownColor: AppTheme.zinc900,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'YEARLY',
                                          child: Text(l10n.yearly),
                                        ),
                                        DropdownMenuItem(
                                          value: 'QUARTERLY',
                                          child: Text(l10n.quarterly),
                                        ),
                                        DropdownMenuItem(
                                          value: 'MONTHLY',
                                          child: Text(l10n.monthly),
                                        ),
                                      ],
                                      onChanged: (v) =>
                                          setModalState(() => frequency = v!),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      _buildModalField(
                        l10n.description,
                        descController,
                        maxLines: 4,
                      ),

                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.brandOrange.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.brandOrange.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.brandOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.maintenancePlanAutoInfo,
                                style: const TextStyle(
                                  color: AppTheme.zinc400,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.zinc800)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (titleController.text.isEmpty) return;

                            setModalState(() => isSubmitting = true);
                            try {
                              final endDate = DateTime(
                                startDate.year + 5,
                                startDate.month,
                                startDate.day,
                              );

                              await ref
                                  .read(interventionListProvider.notifier)
                                  .createMaintenancePlan({
                                    'building_id': i.buildingId,
                                    'title': titleController.text,
                                    'description': descController.text,
                                    'syndic_id':
                                        i.syndicId ?? i.buildingSyndicId,
                                    'recurrence': {
                                      'frequency': frequency,
                                      'interval': 1,
                                      'start_date': startDate.toIso8601String(),
                                      'end_date': endDate.toIso8601String(),
                                    },
                                  });
                              if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.maintenancePlanCreatedSuccess,
                                      ),
                                      backgroundColor: AppTheme.brandGreen,
                                    ),
                                  );
                                }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorWithMessage(context, e)),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.confirmPlan,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRegisterOptionsModal(BuildContext context, Intervention i, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.zinc950,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.zinc800,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              l10n.saveRecord,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.chooseSaveMode,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.zinc500,
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionBtn(
              icon: Icons.save_outlined,
              label: l10n.saveOnly,
              onTap: () {
                Navigator.pop(context);
                _executeRegister(i.id, mode: 'NONE');
              },
            ),
            const SizedBox(height: 12),
            _buildOptionBtn(
              icon: Icons.mail_outline,
              label: l10n.saveSendEmail,
              onTap: () {
                Navigator.pop(context);
                _executeRegister(i.id, mode: 'EMAIL');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppTheme.zinc800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppTheme.zinc900.withValues(alpha: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white70),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppTheme.zinc500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.zinc900,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.zinc800),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Navigation to the address (see MapService.openDirections: several fallbacks + a visible message).
  Future<void> _openMap(String address) => MapService.openDirections(context, address);
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;

  const _StatusBtn({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? color : AppTheme.zinc800),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isActive ? color : AppTheme.zinc500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
