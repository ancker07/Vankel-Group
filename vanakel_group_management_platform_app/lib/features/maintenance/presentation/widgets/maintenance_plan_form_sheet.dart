import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/maintenance_plan.dart';
import '../providers/maintenance_list_provider.dart';
import '../../../intervention/presentation/providers/intervention_provider.dart';

class MaintenancePlanFormSheet extends ConsumerStatefulWidget {
  final MaintenancePlan? plan;

  const MaintenancePlanFormSheet({super.key, this.plan});

  @override
  ConsumerState<MaintenancePlanFormSheet> createState() => _MaintenancePlanFormSheetState();
}

class _MaintenancePlanFormSheetState extends ConsumerState<MaintenancePlanFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _frequency;
  String? _selectedBuildingId;
  late DateTime _startDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.plan?.title ?? '');
    _descriptionController = TextEditingController(text: widget.plan?.description ?? '');
    _frequency = widget.plan?.frequency ?? 'MONTHLY';
    _selectedBuildingId = widget.plan?.buildingId;
    _startDate = widget.plan?.startDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBuildingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a building')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final buildings = ref.read(buildingListProvider).value ?? [];
      final building = buildings.firstWhere(
        (b) => b['id'].toString() == _selectedBuildingId,
        orElse: () => null,
      );
      final syndicId = building?['linked_syndic_id']?.toString();

      final newPlan = MaintenancePlan(
        id: widget.plan?.id ?? '',
        buildingId: _selectedBuildingId!,
        title: _titleController.text,
        description: _descriptionController.text,
        frequency: _frequency,
        interval: 1,
        startDate: _startDate,
        endDate: _startDate.add(const Duration(days: 365)),
        status: 'ACTIVE',
        syndicId: syndicId,
        createdAt: widget.plan?.createdAt ?? DateTime.now(),
      );

      if (widget.plan == null) {
        await ref.read(maintenanceListProvider.notifier).createPlan(newPlan);
      } else {
        await ref.read(maintenanceListProvider.notifier).updatePlan(newPlan);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildingsAsync = ref.watch(buildingListProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.plan == null ? 'NEW MAINTENANCE PLAN' : 'EDIT MAINTENANCE PLAN',
                style: const TextStyle(
                  color: Color(0xFFF97316),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Building Selector
              buildingsAsync.when(
                data: (buildings) => DropdownButtonFormField<String>(
                  value: _selectedBuildingId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF18181B),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Select Building'),
                  items: buildings.map<DropdownMenuItem<String>>((b) {
                    return DropdownMenuItem<String>(
                      value: b['id'].toString(),
                      child: Text(b['address'] ?? 'No Address'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedBuildingId = val),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading buildings', style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Title'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Description'),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _frequency,
                isExpanded: true,
                dropdownColor: const Color(0xFF18181B),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Frequency'),
                items: const [
                  DropdownMenuItem(value: 'DAILY', child: Text('DAILY')),
                  DropdownMenuItem(value: 'WEEKLY', child: Text('WEEKLY')),
                  DropdownMenuItem(value: 'MONTHLY', child: Text('MONTHLY')),
                  DropdownMenuItem(value: 'QUARTERLY', child: Text('QUARTERLY')),
                  DropdownMenuItem(value: 'YEARLY', child: Text('YEARLY')),
                ],
                onChanged: (val) => setState(() => _frequency = val!),
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFFF97316),
                            onPrimary: Colors.black,
                            surface: Color(0xFF18181B),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Colors.white30),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('START DATE', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(
                            "${_startDate.day}/${_startDate.month}/${_startDate.year}",
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(widget.plan == null ? 'CREATE PLAN' : 'SAVE CHANGES', 
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white30, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF97316), width: 1),
      ),
    );
  }
}
