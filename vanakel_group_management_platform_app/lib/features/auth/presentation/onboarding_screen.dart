import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';

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
              Text(
                l10n.selectLanguage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(
                context,
                l10n.english,
                const Locale('en'),
                '🇺🇸',
              ),
              _buildLanguageOption(
                context,
                l10n.french,
                const Locale('fr'),
                '🇫🇷',
              ),
              _buildLanguageOption(
                context,
                l10n.dutch,
                const Locale('nl'),
                '🇳🇱',
              ),
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

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.brandGreen : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.brandGreen)
          : null,
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(locale);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contents = _getContents(l10n);

    return Scaffold(
      backgroundColor: AppTheme.zinc950,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.language, color: AppTheme.zinc400),
                    onPressed: () => _showLanguageSelector(context),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      l10n.skip,
                      style: const TextStyle(color: AppTheme.zinc400),
                    ),
                  ),
                ],
              ),
            ),
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
