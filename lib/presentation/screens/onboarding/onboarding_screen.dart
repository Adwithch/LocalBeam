// lib/presentation/screens/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/beam_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.wifi_tethering_rounded,
      title: 'Transfer Without Internet',
      body: 'LocalBeam works entirely on your local network.\nNo cloud. No middlemen. Just fast.',
      accentColor: AppColors.primary,
    ),
    _OnboardingPage(
      icon: Icons.lock_outline_rounded,
      title: 'End-to-End Encrypted',
      body: 'Optional AES-256-GCM encryption keeps your files private — even on shared networks.',
      accentColor: AppColors.secondary,
    ),
    _OnboardingPage(
      icon: Icons.speed_rounded,
      title: 'Blazing Fast',
      body: 'Optimized for LAN speeds. Transfer a 10 GB file in under a minute on gigabit networks.',
      accentColor: AppColors.success,
    ),
    _OnboardingPage(
      icon: Icons.devices_rounded,
      title: 'Works Everywhere',
      body: 'Android, iOS, macOS, Windows, Linux — send files between any combination of devices.',
      accentColor: AppColors.warning,
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.animationNormal,
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final box = Hive.box(AppConstants.settingsBox);
    await box.put(AppConstants.keyOnboardingDone, true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ).animate().fadeIn(delay: 500.ms),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i],
              ),
            ),

            // Indicators + button
            Padding(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: AppConstants.animationFast,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? _pages[_currentPage].accentColor
                              : AppColors.outline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // CTA button
                  BeamButton(
                    onPressed: _next,
                    label: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    icon: _currentPage == _pages.length - 1
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color accentColor;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withOpacity(0.12),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, size: 56, color: accentColor),
          )
              .animate(key: ValueKey(title))
              .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 700.ms)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 48),

          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('title_$title'))
              .slideY(begin: 0.3, curve: Curves.easeOutCubic, duration: 500.ms, delay: 100.ms)
              .fadeIn(delay: 100.ms, duration: 400.ms),

          const SizedBox(height: 16),

          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceDim,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('body_$title'))
              .slideY(begin: 0.3, curve: Curves.easeOutCubic, duration: 500.ms, delay: 200.ms)
              .fadeIn(delay: 200.ms, duration: 400.ms),
        ],
      ),
    );
  }
}
