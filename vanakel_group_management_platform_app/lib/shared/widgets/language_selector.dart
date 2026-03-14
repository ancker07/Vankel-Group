import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_theme.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  String _getFlag(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return '🇫🇷';
      case 'nl':
        return '🇳🇱';
      case 'en':
      default:
        return '🇺🇸';
    }
  }

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'nl':
        return 'Nederlands';
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return GestureDetector(
      onTap: () => _showLanguageBottomSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.zinc900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.zinc800),
        ),
        child: Text(
          _getFlag(currentLocale.languageCode),
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.zinc950,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.zinc800,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SELECT LANGUAGE',
                style: TextStyle(
                  color: AppTheme.zinc500,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              _buildLanguageItem(context, ref, 'en', currentLocale.languageCode == 'en'),
              _buildLanguageItem(context, ref, 'fr', currentLocale.languageCode == 'fr'),
              _buildLanguageItem(context, ref, 'nl', currentLocale.languageCode == 'nl'),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageItem(
    BuildContext context,
    WidgetRef ref,
    String code,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(Locale(code));
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Text(
              _getFlag(code),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            Text(
              _getLanguageName(code),
              style: TextStyle(
                color: isSelected ? AppTheme.brandGreen : Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.brandGreen,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
