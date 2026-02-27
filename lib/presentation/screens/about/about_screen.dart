// lib/presentation/screens/about/about_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryContainer],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
              ),
              child: const Icon(Icons.wifi_tethering_rounded, size: 52, color: Colors.white),
            ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 800.ms),
            const SizedBox(height: 20),
            Text(AppConstants.appName, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800))
                .animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 6),
            Text('v${AppConstants.appVersion}', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceDim))
                .animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 8),
            Text('Fast. Private. Local.', style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))
                .animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
              children: ['No Internet', 'AES-256-GCM', 'Cross-Platform', 'Open Source', '10GB+ Files']
                  .map((l) => Chip(label: Text(l, style: const TextStyle(fontSize: 12)))).toList(),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 32),
            Text(
              'LocalBeam transfers files directly between devices on your local network — no cloud, no middlemen, no size limits. Files never leave your network.',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceDim, height: 1.6),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 450.ms),
            const SizedBox(height: 32),
            _InfoCard(title: 'Built with', items: [
              '🐦 Flutter 3.16+ / Dart 3+',
              '⚡ Riverpod state management',
              '🔒 AES-256-GCM encryption',
              '🌐 Shelf HTTP server',
              '📡 mDNS peer discovery',
              '📦 Hive local storage',
              '🔗 WebRTC data channels',
            ]).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 20),
            // Author card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primaryContainer, AppColors.surfaceVariant], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                  child: const Center(child: Text('A', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Made with 💙 by', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceDim)),
                  Text(AppConstants.authorName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: () => _launchUrl(AppConstants.authorInstagram),
                    child: const Text('@a.dwith', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ])),
                IconButton(icon: const Icon(Icons.open_in_new_rounded, color: AppColors.primary), onPressed: () => _launchUrl(AppConstants.authorInstagram)),
              ]),
            ).animate().fadeIn(delay: 550.ms),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _launchUrl(AppConstants.repoUrl),
              icon: const Icon(Icons.code_rounded),
              label: const Text('View Source Code'),
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 32),
            Text('${AppConstants.licenseType} · ${AppConstants.appName} v${AppConstants.appVersion}',
                style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 11)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> items;
  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...items.map((i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(i, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceDim)),
        )),
      ]),
    );
  }
}
