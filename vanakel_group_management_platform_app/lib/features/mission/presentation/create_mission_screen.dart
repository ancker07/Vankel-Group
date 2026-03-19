import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/user_role_enum.dart';
import '../../../../core/utils/translation_helper.dart';
import '../domain/mission.dart';
import 'providers/mission_provider.dart';
import 'providers/mission_list_provider.dart';
import '../../intervention/presentation/providers/intervention_provider.dart';

import '../../auth/presentation/providers/auth_state_provider.dart';

class CreateMissionScreen extends ConsumerStatefulWidget {
  final Mission? mission;
  const CreateMissionScreen({super.key, this.mission});

  @override
  ConsumerState<CreateMissionScreen> createState() =>
      _CreateMissionScreenState();
}

class _CreateMissionScreenState extends ConsumerState<CreateMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _contactEmailController;
  late MissionUrgency _urgency;
  bool _isTitleDirty = false;
  bool _isDescriptionDirty = false;
  Locale? _previousLocale;
  String _sector = 'GENERAL';
  bool _isLoading = false;
  List<dynamic> _syndics = [];
  String? _selectedSyndicId;

  final List<File> _images = [];
  final List<File> _documents = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.mission?.title);
    _descriptionController = TextEditingController(text: widget.mission?.description);
    _addressController = TextEditingController(text: widget.mission?.address);
    _contactNameController = TextEditingController(text: widget.mission?.onSiteContactName);
    _contactPhoneController = TextEditingController(text: widget.mission?.onSiteContactPhone);
    _contactEmailController = TextEditingController(text: widget.mission?.onSiteContactEmail);
    
    // Add listeners to track if user has manually edited the fields
    _titleController.addListener(() {
      if (_titleController.text != widget.mission?.title && 
          _titleController.text != widget.mission?.titleEn &&
          _titleController.text != widget.mission?.titleFr &&
          _titleController.text != widget.mission?.titleNl) {
        _isTitleDirty = true;
      }
    });
    
    _descriptionController.addListener(() {
      if (_descriptionController.text != widget.mission?.description &&
          _descriptionController.text != widget.mission?.descriptionEn &&
          _descriptionController.text != widget.mission?.descriptionFr &&
          _descriptionController.text != widget.mission?.descriptionNl) {
        _isDescriptionDirty = true;
      }
    });

    _urgency = widget.mission?.urgency ?? MissionUrgency.normal;
    _sector = widget.mission?.sector?.toUpperCase() ?? 'GENERAL';
    _selectedSyndicId = widget.mission?.syndicId;
    
    _fetchSyndics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.localeOf(context);
    
    if (_previousLocale == null) {
      // First time initialization with localized strings
      if (widget.mission != null) {
        _titleController.text = TranslationHelper.getLocalizedField(
          context: context,
          enValue: widget.mission!.titleEn,
          frValue: widget.mission!.titleFr,
          nlValue: widget.mission!.titleNl,
          fallback: widget.mission!.title,
        );
        _descriptionController.text = TranslationHelper.getLocalizedField(
          context: context,
          enValue: widget.mission!.descriptionEn,
          frValue: widget.mission!.descriptionFr,
          nlValue: widget.mission!.descriptionNl,
          fallback: widget.mission!.description,
        );
      }
      _previousLocale = currentLocale;
    } else if (_previousLocale != currentLocale) {
      // Locale changed, update controllers if not dirty
      if (widget.mission != null) {
        if (!_isTitleDirty) {
          _titleController.text = TranslationHelper.getLocalizedField(
            context: context,
            enValue: widget.mission!.titleEn,
            frValue: widget.mission!.titleFr,
            nlValue: widget.mission!.titleNl,
            fallback: widget.mission!.title,
          );
        }
        if (!_isDescriptionDirty) {
          _descriptionController.text = TranslationHelper.getLocalizedField(
            context: context,
            enValue: widget.mission!.descriptionEn,
            frValue: widget.mission!.descriptionFr,
            nlValue: widget.mission!.descriptionNl,
            fallback: widget.mission!.description,
          );
        }
      }
      _previousLocale = currentLocale;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  Future<void> _fetchSyndics() async {
    try {
      final syndics = await ref
          .read(interventionRepositoryProvider)
          .getSyndics();
      setState(() {
        _syndics = syndics;
        // Pre-select first syndic if user is syndic and syndics are available
        final authState = ref.read(authStateProvider);
        if (_selectedSyndicId == null && authState.user?.role == UserRole.syndic && syndics.isNotEmpty) {
          _selectedSyndicId = syndics[0]['id'].toString();
        }
      });
    } catch (e) {
      debugPrint('Error fetching syndics: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _images.add(File(image.path));
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        setState(() {
          _documents.add(File(result.files.single.path!));
        });
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _removeDocument(int index) {
    setState(() {
      _documents.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authState = ref.read(authStateProvider);
        final user = authState.user;

        // Create multipart request
        final formDataMap = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'addressFull': _addressController.text,
          'urgency': _urgency.name.toUpperCase(),
          'role': user?.role.name.toUpperCase() ?? 'SYNDIC',
          'syndicId': _selectedSyndicId,
          'status': widget.mission?.status.name.toUpperCase() ?? 'PENDING',
          'category': _sector,
          'sector': _sector,
          'onSiteContactName': _contactNameController.text.isNotEmpty ? _contactNameController.text : (user?.name ?? 'Unknown'),
          'onSiteContactPhone': _contactPhoneController.text.isNotEmpty ? _contactPhoneController.text : (user?.phone ?? '+123456789'),
          'onSiteContactEmail': _contactEmailController.text.isNotEmpty ? _contactEmailController.text : (user?.email ?? ''),
          'type': 'mission',
          if (widget.mission != null) '_method': 'PUT',
        };

        final formData = FormData.fromMap(formDataMap);

        // Add images as files[]
        for (var i = 0; i < _images.length; i++) {
          formData.files.add(
            MapEntry(
              'files[]',
              await MultipartFile.fromFile(
                _images[i].path,
                filename: path.basename(_images[i].path),
              ),
            ),
          );
        }

        // Add documents as files[]
        for (var i = 0; i < _documents.length; i++) {
          formData.files.add(
            MapEntry(
              'files[]',
              await MultipartFile.fromFile(
                _documents[i].path,
                filename: path.basename(_documents[i].path),
              ),
            ),
          );
        }

        if (widget.mission != null) {
          // Update existing mission
          await ref
              .read(missionRepositoryProvider)
              .updateMissionWithFiles(widget.mission!.id, formData);
        } else {
          // Create new mission
          await ref
              .read(missionRepositoryProvider)
              .createMissionWithFiles(formData);
        }
        
        ref.invalidate(missionListProvider);
        if (widget.mission != null) {
          ref.invalidate(missionDetailProvider(widget.mission!.id));
        }

        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.mission != null ? 'Mission updated successfully' : 'Request sent successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.zinc950,
      appBar: AppBar(
        title: Text(widget.mission != null ? l10n.updateRequest : l10n.newRequest),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          LanguageSelector(),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(l10n.subject),
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration(l10n.enterSubject),
                    validator: (value) =>
                        value == null || value.isEmpty ? l10n.required : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel(l10n.building),
                  TextFormField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration(l10n.selectBuildingHint),
                    validator: (value) =>
                        value == null || value.isEmpty ? l10n.required : null,
                  ),
                  const SizedBox(height: 20),

                  // Syndic selection (only show if user is not a syndic)
                  Consumer(
                    builder: (context, ref, child) {
                      final authState = ref.watch(authStateProvider);
                      if (authState.user?.role != UserRole.syndic &&
                          _syndics.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(l10n.syndic),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSyndicId,
                              dropdownColor: AppTheme.zinc900,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                l10n.selectSyndicHint,
                              ),
                              items: _syndics.map((syndic) {
                                return DropdownMenuItem<String>(
                                  value: syndic['id'].toString(),
                                  child: Text(
                                    syndic['company_name'] ?? l10n.noSyndic,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSyndicId = value;
                                });
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? l10n.required
                                  : null,
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  _buildLabel(l10n.description),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration(l10n.description),
                    maxLines: 4,
                    validator: (value) =>
                        value == null || value.isEmpty ? l10n.required : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel(l10n.sector),
                  DropdownButtonFormField<String>(
                    value: [
                      'GENERAL',
                      'ELECTRICITY',
                      'TILING',
                      'SANITARY',
                      'HEATING',
                      'PLUMBING',
                      'PAINTING',
                      'WOODWORK',
                      'OTHER',
                      'ÉLECTRICITÉ',
                      'CARRELAGE',
                      'SANITAIRE',
                      'CHAUFFAGE',
                      'PLOMBERIE',
                      'PEINTURE',
                      'MENUISERIE',
                      'GÉNÉRAL',
                      'AUTRE',
                    ].contains(_sector.toUpperCase()) ? _sector.toUpperCase() : 'GENERAL',
                    dropdownColor: AppTheme.zinc900,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration(l10n.selectSector),
                    items: [
                      'GENERAL',
                      'ELECTRICITY',
                      'TILING',
                      'SANITARY',
                      'HEATING',
                      'PLUMBING',
                      'PAINTING',
                      'WOODWORK',
                      'OTHER',
                      'ÉLECTRICITÉ',
                      'CARRELAGE',
                      'SANITAIRE',
                      'CHAUFFAGE',
                      'PLOMBERIE',
                      'PEINTURE',
                      'MENUISERIE',
                      'GÉNÉRAL',
                      'AUTRE',
                    ].map((sector) {
                      String label = sector;
                      if (sector == 'GENERAL') label = l10n.general;
                      if (sector == 'ELECTRICITY' || sector == 'ÉLECTRICITÉ') label = l10n.electricity;
                      if (sector == 'TILING' || sector == 'CARRELAGE') label = l10n.tiling;
                      if (sector == 'SANITARY' || sector == 'SANITAIRE') label = l10n.sanitary;
                      if (sector == 'HEATING' || sector == 'CHAUFFAGE') label = l10n.heating;
                      if (sector == 'PLUMBING' || sector == 'PLOMBERIE') label = l10n.plumbing;
                      if (sector == 'PAINTING' || sector == 'PEINTURE') label = l10n.painting;
                      if (sector == 'WOODWORK' || sector == 'MENUISERIE') label = l10n.woodwork;
                      if (sector == 'OTHER' || sector == 'AUTRE') label = l10n.other;
                      
                      return DropdownMenuItem<String>(
                        value: sector,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _sector = value);
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildLabel(l10n.onSiteContactName),
                  TextFormField(
                    controller: _contactNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration(l10n.name),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel(l10n.onSiteContactPhone),
                  TextFormField(
                    controller: _contactPhoneController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration(l10n.phoneTitle),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel(l10n.onSiteContactEmail),
                  TextFormField(
                    controller: _contactEmailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration(l10n.emailOptional),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel(l10n.urgency),
                  Row(
                    children: MissionUrgency.values.map((urgency) {
                      final isSelected = _urgency == urgency;
                      String label = urgency.name.toUpperCase();
                      if (urgency == MissionUrgency.low) label = l10n.low;
                      if (urgency == MissionUrgency.normal) label = l10n.normal;
                      if (urgency == MissionUrgency.urgent) label = l10n.urgent;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _urgency = urgency);
                          },
                          selectedColor: AppTheme.brandGreen,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : AppTheme.zinc500,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          backgroundColor: AppTheme.zinc900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.brandGreen
                                  : AppTheme.zinc800,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  _buildLabel(l10n.attachments),
                  Row(
                    children: [
                      _buildFileButton(
                        icon: Icons.camera_alt_outlined,
                        label: l10n.camera,
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                      const SizedBox(width: 12),
                      _buildFileButton(
                        icon: Icons.photo_library_outlined,
                        label: l10n.gallery,
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                      const SizedBox(width: 12),
                      _buildFileButton(
                        icon: Icons.description_outlined,
                        label: l10n.document,
                        onTap: () => _pickDocument(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_images.isNotEmpty) ...[
                    _buildLabel(l10n.images),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.zinc800),
                                    image: DecorationImage(
                                      image: FileImage(_images[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (_documents.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildLabel(l10n.documents),
                    const SizedBox(height: 8),
                    Column(
                      children: List.generate(_documents.length, (index) {
                        final doc = _documents[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.zinc900,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.zinc800),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.description,
                                color: AppTheme.brandGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  path.basename(doc.path),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                onPressed: () => _removeDocument(index),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],

                  const SizedBox(height: 100), // Space for submit button
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: AppTheme.brandGreen.withValues(alpha: 0.3),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        widget.mission != null
                            ? 'Update Request'
                            : 'Submit Request',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.zinc900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.zinc800),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppTheme.brandGreen, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.zinc400, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.zinc500),
      filled: true,
      fillColor: AppTheme.zinc900,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.zinc800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.brandGreen),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.zinc300,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
