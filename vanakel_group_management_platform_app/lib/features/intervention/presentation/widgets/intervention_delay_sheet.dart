import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class InterventionDelaySheet extends StatefulWidget {
  final String? initialReason;
  final String? initialDetails;
  final DateTime? initialDate;

  const InterventionDelaySheet({
    super.key,
    this.initialReason,
    this.initialDetails,
    this.initialDate,
  });

  @override
  State<InterventionDelaySheet> createState() => _InterventionDelaySheetState();
}

class _InterventionDelaySheetState extends State<InterventionDelaySheet> {
  String? _selectedReason;
  late TextEditingController _detailsController;
  DateTime? _selectedDate;

  final List<Map<String, String>> _delayReasons = [
    {'id': 'missing_part', 'label': 'Pièce manquante / Missing part'},
    {'id': 'no_access', 'label': 'Accès impossible / No access'},
    {'id': 'client_unavailable', 'label': 'Client indisponible / Client unavailable'},
    {'id': 'waiting_validation', 'label': 'En attente de validation / Waiting validation'},
    {'id': 'weather', 'label': 'Intempéries / Bad weather'},
    {'id': 'subcontractor', 'label': 'Sous-traitant indisponible / Subcontractor unavailable'},
    {'id': 'other', 'label': 'Autre / Other'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedReason = widget.initialReason;
    _detailsController = TextEditingController(text: widget.initialDetails);
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.brandGreen,
              onPrimary: Colors.black,
              surface: AppTheme.zinc900,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DELAY REASON',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.brandOrange,
                  letterSpacing: 2,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppTheme.zinc500),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Reason selector
          const Text(
            'WHY IS IT DELAYED?',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppTheme.zinc500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.zinc900,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.zinc800),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedReason,
                hint: const Text('Select a reason', style: TextStyle(color: AppTheme.zinc500, fontSize: 14)),
                isExpanded: true,
                dropdownColor: AppTheme.zinc900,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.zinc500),
                items: _delayReasons.map((reason) {
                  return DropdownMenuItem<String>(
                    value: reason['id'],
                    child: Text(
                      reason['label']!,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedReason = value),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Details
          const Text(
            'ADDITIONAL DETAILS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppTheme.zinc500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter specific details about the delay...',
              fillColor: AppTheme.zinc900,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.zinc800),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.zinc800),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Reschedule date
          const Text(
            'NEW SCHEDULED DATE (OPTIONAL)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppTheme.zinc500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.zinc900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.zinc800),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: AppTheme.brandGreen),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate != null
                        ? DateFormat('EEEE, MMM d, y').format(_selectedDate!)
                        : 'Select new date',
                    style: TextStyle(
                      color: _selectedDate != null ? Colors.white : AppTheme.zinc500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: AppTheme.zinc500),
                      onPressed: () => setState(() => _selectedDate = null),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedReason == null
                  ? null
                  : () {
                      Navigator.pop(context, {
                        'reason': _selectedReason,
                        'details': _detailsController.text,
                        'date': _selectedDate,
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('CONFIRM DELAY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}
