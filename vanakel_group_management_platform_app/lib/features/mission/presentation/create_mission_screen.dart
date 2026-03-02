import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/mission.dart';
import 'providers/mission_provider.dart';
import 'providers/mission_list_provider.dart';

import '../../auth/presentation/providers/auth_state_provider.dart';

class CreateMissionScreen extends ConsumerStatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  ConsumerState<CreateMissionScreen> createState() =>
      _CreateMissionScreenState();
}

class _CreateMissionScreenState extends ConsumerState<CreateMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  MissionUrgency _urgency = MissionUrgency.normal;
  bool _isLoading = false;

  final List<File> _images = [];
  final List<File> _documents = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
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
          'building_id': 4, // Default building ID as seen in screenshot
          'requested_by': user?.id,
          'urgency': _urgency.name.toUpperCase(),
          'status': 'PENDING',
          'category': 'GENERAL',
          'sector': 'GENERAL',
          'on_site_contact_name': user?.name ?? 'Unknown',
          'on_site_contact_phone': user?.phone ?? '+123456789',
          'on_site_contact_email': user?.email ?? '',
          'type': 'mission',
        };

        final formData = FormData.fromMap(formDataMap);

        // Add images
        for (var i = 0; i < _images.length; i++) {
          formData.files.add(
            MapEntry(
              'images[]',
              await MultipartFile.fromFile(
                _images[i].path,
                filename: path.basename(_images[i].path),
              ),
            ),
          );
        }

        // Add documents
        for (var i = 0; i < _documents.length; i++) {
          formData.files.add(
            MapEntry(
              'documents[]',
              await MultipartFile.fromFile(
                _documents[i].path,
                filename: path.basename(_documents[i].path),
              ),
            ),
          );
        }

        await ref
            .read(missionRepositoryProvider)
            .createMissionWithFiles(formData);
        ref.invalidate(missionListProvider);

        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request sent successfully')),
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
    return Scaffold(
      backgroundColor: AppTheme.brandBlack,
      appBar: AppBar(
        title: const Text('New Request'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  _buildLabel('Subject'),
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration('e.g., Water Leak'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Address'),
                  TextFormField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration('Select building...'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Description'),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration('Describe the issue...'),
                    maxLines: 4,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Urgency'),
                  Row(
                    children: MissionUrgency.values.map((urgency) {
                      final isSelected = _urgency == urgency;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(urgency.name.toUpperCase()),
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

                  _buildAttachmentSection(),

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
                    : const Text(
                        'Submit Request',
                        style: TextStyle(
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

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Attachments'),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildAddAttachmentButton(
              icon: Icons.camera_alt_outlined,
              label: 'Camera',
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(width: 12),
            _buildAddAttachmentButton(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(width: 12),
            _buildAddAttachmentButton(
              icon: Icons.description_outlined,
              label: 'Document',
              onTap: _pickDocument,
            ),
          ],
        ),
        if (_images.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildLabel('Images (${_images.length})'),
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
          _buildLabel('Documents (${_documents.length})'),
          const SizedBox(height: 8),
          Column(
            children: _documents.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
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
                      Icons.description_outlined,
                      color: AppTheme.zinc500,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        path.basename(file.path),
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
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _removeDocument(index),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAddAttachmentButton({
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
