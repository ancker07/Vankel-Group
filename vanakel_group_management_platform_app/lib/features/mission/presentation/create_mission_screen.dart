import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/mission.dart';
import '../data/mission_repository.dart';

class CreateMissionScreen extends ConsumerStatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  ConsumerState<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends ConsumerState<CreateMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  MissionUrgency _urgency = MissionUrgency.normal;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newMission = Mission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        address: _addressController.text,
        status: MissionStatus.pending,
        urgency: _urgency,
        createdAt: DateTime.now(),
        isAiDetected: false,
      );

      ref.read(missionRepositoryProvider.notifier).addMission(newMission);
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              _buildLabel('Address'),
              TextFormField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration('Select building...'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Description'),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration('Describe the issue...'),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

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
                      ),
                      backgroundColor: AppTheme.zinc900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? AppTheme.brandGreen : AppTheme.zinc800,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Request',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
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
