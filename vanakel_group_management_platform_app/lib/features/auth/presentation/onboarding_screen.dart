import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/enums/user_role_enum.dart';
import 'providers/auth_state_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  List<OnboardingContent> _getContents(AppLocalizations l10n) => [
    OnboardingContent(
      image: 'assets/images/onboarding_1.png',
      title: l10n.onboardingTitle,
      description: l10n.onboardingDesc,
    ),
    OnboardingContent(
      image: 'assets/images/onboarding_2.png',
      title: l10n.onboardingTitle2,
      description: l10n.onboardingDesc2,
    ),
    OnboardingContent(
      image: 'assets/images/onboarding_3.png',
      title: l10n.onboardingTitle3,
      description: l10n.onboardingDesc3,
    ),
  ];

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.zinc950,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
              Text(
                l10n.selectLanguage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildLanguageOption(
                context,
                l10n.english,
                const Locale('en'),
                '🇺🇸',
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                context,
                l10n.french,
                const Locale('fr'),
                '🇫🇷',
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                context,
                l10n.dutch,
                const Locale('nl'),
                '🇳🇱',
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String label,
    Locale locale,
    String flag,
  ) {
    final currentLocale = ref.watch(localeProvider);
    final isSelected = currentLocale.languageCode == locale.languageCode;

    return InkWell(
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(locale);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandGreen.withValues(alpha: 0.1)
              : AppTheme.zinc900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.brandGreen : AppTheme.zinc800,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.zinc400,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.brandGreen),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contents = _getContents(l10n);
    final currentLocale = ref.watch(localeProvider);

    String getLanguageName(String code) {
      switch (code) {
        case 'en':
          return l10n.english;
        case 'fr':
          return l10n.french;
        case 'nl':
          return l10n.dutch;
        default:
          return l10n.english;
      }
    }

    String getFlag(String code) {
      switch (code) {
        case 'en':
          return '🇺🇸';
        case 'fr':
          return '🇫🇷';
        case 'nl':
          return '🇳🇱';
        default:
          return '🇺🇸';
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.zinc950,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _showLanguageSelector(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.zinc900,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.zinc800),
                      ),
                      child: Row(
                        children: [
                          Text(
                            getFlag(currentLocale.languageCode),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            getLanguageName(currentLocale.languageCode),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppTheme.zinc400,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      l10n.skip,
                      style: const TextStyle(
                        color: AppTheme.zinc400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: contents.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              contents[index].image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppTheme.zinc900,
                                    child: const Icon(
                                      Icons.image_outlined,
                                      size: 100,
                                      color: AppTheme.zinc800,
                                    ),
                                  ),
                            ),
                          ).animate().fadeIn(duration: 600.ms).scale(),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          contents[index].title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                        const SizedBox(height: 16),
                        Text(
                          contents[index].description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.zinc400),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: contents.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: AppTheme.brandGreen,
                      dotColor: AppTheme.zinc800,
                      dotHeight: 8,
                      dotWidth: 8,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentIndex == contents.length - 1) {
                        context.go('/login');
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _currentIndex == contents.length - 1
                          ? l10n.getStarted
                          : l10n.next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingContent {
  final String image;
  final String title;
  final String description;

  OnboardingContent({
    required this.image,
    required this.title,
    required this.description,
  });
}
