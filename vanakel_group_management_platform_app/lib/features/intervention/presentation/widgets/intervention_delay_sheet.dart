import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';

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

  final List<String> _delayReasonIds = [
    'missing_part',
    'no_access',
    'client_unavailable',
    'waiting_validation',
    'weather',
    'subcontractor',
    'other',
  ];

  String _getReasonLabel(String id, AppLocalizations l10n) {
    switch (id) {
      case 'missing_part':
        return l10n.delayReasonMissingPart;
      case 'no_access':
        return l10n.delayReasonNoAccess;
      case 'client_unavailable':
        return l10n.delayReasonClientUnavailable;
      case 'waiting_validation':
        return l10n.delayReasonWaitingValidation;
      case 'weather':
        return l10n.delayReasonWeather;
      case 'subcontractor':
        return l10n.delayReasonSubcontractor;
      case 'other':
      default:
        return l10n.delayReasonOther;
    }
  }

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
    final l10n = AppLocalizations.of(context)!;
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
              Text(
                l10n.delayReasonHeader,
                style: const TextStyle(
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
          Text(
            l10n.whyIsItDelayed,
            style: const TextStyle(
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
                hint: Text(
                  l10n.selectAReason,
                  style: const TextStyle(color: AppTheme.zinc500, fontSize: 14),
                ),
                isExpanded: true,
                dropdownColor: AppTheme.zinc900,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.zinc500,
                ),
                items: _delayReasonIds.map((id) {
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(
                      _getReasonLabel(id, l10n),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedReason = value),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Details
          Text(
            l10n.additionalDetails,
            style: const TextStyle(
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
              hintText: l10n.enterSpecificDetails,
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
          Text(
            l10n.newScheduledDate,
            style: const TextStyle(
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
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppTheme.brandGreen,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate != null
                        ? DateFormat('EEEE, MMM d, y').format(_selectedDate!)
                        : l10n.selectNewDate,
                    style: TextStyle(
                      color: _selectedDate != null
                          ? Colors.white
                          : AppTheme.zinc500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedDate != null)
                    IconButton(
                      icon: const Icon(
                        Icons.clear,
                        size: 16,
                        color: AppTheme.zinc500,
                      ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.confirmDelay,
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
