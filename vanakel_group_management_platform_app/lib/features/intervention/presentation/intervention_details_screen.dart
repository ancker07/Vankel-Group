import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart' as dio;
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/intervention.dart';
import 'providers/intervention_list_provider.dart';
import 'providers/intervention_provider.dart';
import 'widgets/intervention_delay_sheet.dart';

class InterventionDetailsScreen extends ConsumerStatefulWidget {
  final String interventionId;

  const InterventionDetailsScreen({super.key, required this.interventionId});

  @override
  ConsumerState<InterventionDetailsScreen> createState() => _InterventionDetailsScreenState();
}

class _InterventionDetailsScreenState extends ConsumerState<InterventionDetailsScreen> {
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
    if (_contactNameController.text.isEmpty && _contactPhoneController.text.isEmpty) {
      final pattern = RegExp(r'(?:contact|sur place|contact sur place)\s*[:]\s*([^\d\n(]+)(?:\(([^)]+)\))?', caseSensitive: false);
      final match = pattern.firstMatch(intervention.description);
      if (match != null) {
        String name = match.group(1)?.trim() ?? '';
        name = name.replaceAll(RegExp(r'^(M\.|Mr\.|Mme\.|Mle\.)\s*', caseSensitive: false), '');
        final phone = match.group(2)?.trim().replaceAll(RegExp(r'[^\d+]'), '') ?? '';
        
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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _selectedImages.add(image));
    }
  }

  Future<void> _executeRegister(String id) async {
    setState(() => _isSaving = true);
    try {
      final formData = dio.FormData();
      formData.fields.addAll([
        MapEntry('admin_feedback', _adminNoteController.text),
        MapEntry('on_site_contact_name', _contactNameController.text),
        MapEntry('on_site_contact_phone', _contactPhoneController.text),
        MapEntry('on_site_contact_email', _contactEmailController.text),
      ]);

      if (_localStatus != null) {
        formData.fields.add(MapEntry('status', _localStatus!.name.toUpperCase()));
      }
      if (_localSyndicId != null) {
        formData.fields.add(MapEntry('syndic_id', _localSyndicId!));
      }
      if (_localProId != null) {
        formData.fields.add(MapEntry('pro_id', _localProId!));
      }

      if (_localStatus == InterventionStatus.delayed) {
        if (_localDelayReason != null) formData.fields.add(MapEntry('delay_reason', _localDelayReason!));
        if (_localDelayDetails != null) formData.fields.add(MapEntry('delay_details', _localDelayDetails!));
        if (_localDelayedRescheduleDate != null) {
          formData.fields.add(MapEntry('delayed_reschedule_date', _localDelayedRescheduleDate!.toIso8601String()));
        }
      }

      for (final image in _selectedImages) {
        formData.files.add(MapEntry(
          'photos[]',
          await dio.MultipartFile.fromFile(image.path, filename: image.name),
        ));
      }

      await ref.read(interventionListProvider.notifier).registerIntervention(id, formData);
      
      if (mounted) {
        setState(() {
          _isSaving = false;
          _selectedImages.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intervention registered successfully')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
        initialDate: _localDelayedRescheduleDate ?? intervention.delayedRescheduleDate,
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
    final interventionAsync = ref.watch(interventionDetailProvider(widget.interventionId));

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
          data: (i) => Text(i.title.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          loading: () => const Text('LOADING...'),
          error: (_, __) => const Text('ERROR'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.zinc400),
            onPressed: () => ref.invalidate(interventionDetailProvider(widget.interventionId)),
          ),
        ],
      ),
      body: interventionAsync.when(
        data: (intervention) {
          _initializeControllers(intervention);
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContactSection(intervention),
                      const SizedBox(height: 24),
                      _buildDescriptionSection(intervention),
                      const SizedBox(height: 24),
                      _buildMapSection(intervention),
                      const SizedBox(height: 24),
                      _buildStatusSection(intervention),
                      const SizedBox(height: 24),
                      _buildFeedbackSection(intervention),
                      const SizedBox(height: 24),
                      _buildMediaAuditSection(intervention),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              _buildFooter(intervention),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen)),
        error: (e, __) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildContactSection(Intervention i) {
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
              const Icon(Icons.person_outline, size: 16, color: AppTheme.zinc500),
              const SizedBox(width: 8),
              Text('ON-SITE CONTACT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.zinc500, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTextField('NAME', _contactNameController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('GSM / TEL', _contactPhoneController, hint: '+32 ...')),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          _buildTextField('EMAIL (OPTIONAL)', _contactEmailController, hint: 'email@example.com'),
          const SizedBox(height: 24),
          const Text('SYNDIC / CUSTOMER INFO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.zinc500, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _buildSyndicDropdown(),
          _buildSyndicInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSyndicInfoCard() {
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
            border: Border.all(color: AppTheme.brandGreen.withValues(alpha: 0.2)),
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
                      border: Border.all(color: AppTheme.brandGreen.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.person_outline, size: 20, color: AppTheme.brandGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SYNDIC / MANAGER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.zinc500, letterSpacing: 1.2)),
                        const SizedBox(height: 2),
                        Text(syndic['company_name'] ?? syndic['name'] ?? 'Unknown', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                        if (syndic['contact_person'] != null)
                          Text(syndic['contact_person'].toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc500, letterSpacing: 0.5)),
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
                          const Icon(Icons.smartphone_outlined, size: 14, color: AppTheme.brandGreen),
                          const SizedBox(width: 8),
                          Text(syndic['phone'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.zinc300)),
                        ],
                      ),
                    ),
                  if (syndic['email'] != null)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.mail_outline, size: 14, color: AppTheme.zinc500),
                          const SizedBox(width: 8),
                          Flexible(child: Text(syndic['email'], style: const TextStyle(fontSize: 11, color: AppTheme.zinc500), overflow: TextOverflow.ellipsis)),
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

  Widget _buildTextField(String label, TextEditingController controller, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.zinc500)),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: AppTheme.zinc900, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.zinc800)),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppTheme.zinc500, fontSize: 13), border: InputBorder.none, contentPadding: EdgeInsets.zero),
          ),
        ),
      ],
    );
  }

  Widget _buildSyndicDropdown() {
    final syndicsAsync = ref.watch(syndicListProvider);
    return syndicsAsync.when(
      data: (syndics) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: AppTheme.zinc900, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.zinc800)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _localSyndicId,
            hint: const Text('Select Customer...', style: TextStyle(color: AppTheme.zinc500, fontSize: 13)),
            isExpanded: true,
            dropdownColor: AppTheme.zinc950,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            items: syndics.map((s) => DropdownMenuItem(value: s['id'].toString(), child: Text(s['company_name'] ?? s['name'] ?? ''))).toList(),
            onChanged: (v) => setState(() => _localSyndicId = v),
          ),
        ),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Error loading syndics'),
    );
  }

  Widget _buildDescriptionSection(Intervention i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('INTERVENTION DESCRIPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.brandGreen, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.zinc950, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.zinc800)),
          child: Text(i.description, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildStatusSection(Intervention i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.brandGreen, borderRadius: BorderRadius.circular(6)),
          child: const Text('UPDATE STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _StatusBtn(label: 'IN PROGRESS', isActive: _localStatus == InterventionStatus.pending, color: AppTheme.zinc500, onTap: () => setState(() => _localStatus = InterventionStatus.pending))),
            const SizedBox(width: 8),
            Expanded(child: _StatusBtn(label: 'DELAYED', isActive: _localStatus == InterventionStatus.delayed, color: AppTheme.brandOrange, onTap: () => _handleDelay(i.id, i))),
            const SizedBox(width: 8),
            Expanded(child: _StatusBtn(label: 'COMPLETED', isActive: _localStatus == InterventionStatus.completed, color: AppTheme.brandGreen, onTap: () => setState(() => _localStatus = InterventionStatus.completed))),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(Intervention i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text('TECHNICAL OBSERVATIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.zinc500, letterSpacing: 1.2)),
              const SizedBox(width: 16),
              _buildSmallBtn(Icons.camera_alt_outlined, 'PHOTOS', _pickImage),
              const SizedBox(width: 8),
              _buildSmallBtn(Icons.upload_file_outlined, 'DOCUMENTS', () {}),
              const SizedBox(width: 8),
              _buildAIBtn(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 250,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.zinc950, 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(
              color: _adminNoteController.text.isNotEmpty ? AppTheme.brandGreen.withValues(alpha: 0.3) : AppTheme.zinc800,
              width: _adminNoteController.text.isNotEmpty ? 2 : 1,
            )
          ),
          child: TextField(
            controller: _adminNoteController,
            maxLines: null,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(hintText: 'Technical feedback or observations...', hintStyle: TextStyle(color: AppTheme.zinc500, fontSize: 16), border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: AppTheme.zinc900, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppTheme.zinc800)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.zinc500),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.zinc500)),
          ],
        ),
      ),
    );
  }

  Widget _buildAIBtn() {
    return GestureDetector(
      onTap: _isImproving ? null : () async {
        if (_adminNoteController.text.isEmpty) return;
        
        setState(() => _isImproving = true);
        try {
          final improved = await ref.read(interventionListProvider.notifier).improveNote(_adminNoteController.text);
          if (mounted) {
            _adminNoteController.text = improved;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Note improved with AI'),
                backgroundColor: AppTheme.brandGreen,
                duration: Duration(seconds: 1),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('AI Error: $e'), backgroundColor: Colors.red),
            );
          }
        } finally {
          if (mounted) setState(() => _isImproving = false);
        }
      },
      child: Row(
        children: [
          _isImproving 
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandGreen))
            : const Icon(Icons.auto_awesome_outlined, size: 14, color: AppTheme.brandGreen),
          const SizedBox(width: 4),
          Text(_isImproving ? 'WORKING...' : 'IMPROVE WITH AI', 
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.brandGreen)
          ),
        ],
      ),
    );
  }

  Widget _buildMediaAuditSection(Intervention i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MEDIA & AUDIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.zinc500, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMediaBox(Icons.camera_alt_outlined, 'PHOTOS', count: _selectedImages.length.toString(), onTap: _pickImage)),
            const SizedBox(width: 12),
            Expanded(child: _buildMediaBox(Icons.upload_file_outlined, 'DOCUMENTS', count: i.documents.length.toString())),
          ],
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_selectedImages[index].path), width: 60, height: 60, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildAuditCard(),
      ],
    );
  }

  Widget _buildMediaBox(IconData icon, String label, {String? count, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(color: AppTheme.zinc950, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.zinc800)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppTheme.zinc500),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.zinc500)),
            if (count != null && count != '0') ...[
              const SizedBox(height: 4),
              Text(count, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.brandGreen)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuditCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.zinc950, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.zinc800)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AUDIT TRACEABILITY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.brandGreen, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.brandGreen.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.brandGreen)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('INTERVENTION INITIALIZED ON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(DateFormat('M/d/yyyy, h:mm:ss a').format(DateTime.now()), style: const TextStyle(fontSize: 10, color: AppTheme.zinc500)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Intervention i) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.brandBlack, border: Border(top: BorderSide(color: AppTheme.zinc800))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (_isSaving || _isImproving) ? null : () => _executeRegister(i.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandGreen, 
              foregroundColor: Colors.black, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), 
              elevation: 0
            ),
            child: (_isSaving || _isImproving)
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.description_outlined, size: 18), SizedBox(width: 10), Text('REGISTER INTERVENTION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14))]),
          ),
        ),
      ),
    );
  }
  Widget _buildMapSection(Intervention i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('LOCATION & ACCESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.brandGreen, letterSpacing: 1.2)),
            GestureDetector(
              onTap: () => _openMap(i.address),
              child: const Icon(Icons.near_me_outlined, size: 18, color: AppTheme.brandGreen),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _openMap(i.address),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.zinc950,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.zinc800),
            ),
            child: Stack(
              children: [
                Opacity(
                  opacity: 0.1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
                    itemBuilder: (context, index) => Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.zinc500, width: 0.5),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.brandGreen, size: 32),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          i.address == 'No Address' ? 'Address not specified' : "${i.address}\n${i.city ?? ''}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.brandGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.directions, size: 14, color: Colors.black),
                        SizedBox(width: 6),
                        Text('NAVIGATE', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openMap(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$encodedAddress";
    final appleMapsUrl = "https://maps.apple.com/?q=$encodedAddress";

    if (Platform.isAndroid) {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      }
    } else {
      if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
        await launchUrl(Uri.parse(appleMapsUrl), mode: LaunchMode.externalApplication);
      }
    }
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _StatusBtn({required this.label, required this.isActive, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}
