// lib/presentation/screens/settings/settings_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/beam_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _nameController = TextEditingController(text: settings.deviceName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Device ────────────────────────────────────────────────────
          _Section(
            title: 'Device',
            children: [
              _SettingsItem(
                icon: Icons.badge_rounded,
                title: 'Device Name',
                subtitle: settings.deviceName,
                onTap: () => _editDeviceName(context, notifier),
              ),
              _SettingsItem(
                icon: Icons.folder_rounded,
                title: 'Download Location',
                subtitle: settings.downloadPath.isEmpty
                    ? 'Default (Downloads)'
                    : settings.downloadPath,
                onTap: () => _editDownloadPath(context, notifier),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ─── Transfer ──────────────────────────────────────────────────
          _Section(
            title: 'Transfer',
            children: [
              _ToggleItem(
                icon: Icons.auto_mode_rounded,
                title: 'Auto Accept',
                subtitle: 'Automatically accept incoming transfers',
                value: settings.autoAccept,
                onChanged: notifier.setAutoAccept,
              ),
              _ToggleItem(
                icon: Icons.lock_rounded,
                title: 'Encrypt by Default',
                subtitle: 'Encrypt all transfers with a password',
                value: settings.passwordEnabled,
                onChanged: notifier.setPasswordEnabled,
              ),
              if (settings.passwordEnabled)
                _SettingsItem(
                  icon: Icons.vpn_key_rounded,
                  title: 'Default Password',
                  subtitle: settings.defaultPassword != null ? '••••••••' : 'Not set',
                  onTap: () => _editPassword(context, notifier),
                ),
              _SliderItem(
                icon: Icons.timer_rounded,
                title: 'Session Timeout',
                subtitle: '${settings.sessionTimeout ~/ 60} minutes',
                value: settings.sessionTimeout.toDouble(),
                min: 60,
                max: 3600,
                divisions: 59,
                label: '${settings.sessionTimeout ~/ 60}m',
                onChanged: (v) => notifier.setSessionTimeout(v.toInt()),
              ),
              _SliderItem(
                icon: Icons.sync_alt_rounded,
                title: 'Max Concurrent Transfers',
                subtitle: '${settings.maxConcurrent} at a time',
                value: settings.maxConcurrent.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '${settings.maxConcurrent}',
                onChanged: (v) => notifier.setMaxConcurrent(v.toInt()),
              ),
              _PickerItem(
                icon: Icons.tune_rounded,
                title: 'Chunk Size',
                subtitle: _formatChunkSize(settings.chunkSize),
                items: ChunkSizeOption.options.map((o) => o.label).toList(),
                selectedIndex: ChunkSizeOption.options
                    .indexWhere((o) => o.bytes == settings.chunkSize)
                    .clamp(0, ChunkSizeOption.options.length - 1),
                onChanged: (i) => notifier.setChunkSize(ChunkSizeOption.options[i].bytes),
              ),
              _ToggleItem(
                icon: Icons.speed_rounded,
                title: 'Bandwidth Limit',
                subtitle: 'Limit transfer speed',
                value: settings.bandwidthLimitEnabled,
                onChanged: notifier.setBandwidthLimitEnabled,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ─── Appearance ────────────────────────────────────────────────
          _Section(
            title: 'Appearance',
            children: [
              _PickerItem(
                icon: Icons.palette_rounded,
                title: 'Theme',
                subtitle: _themeLabel(settings.themeMode),
                items: const ['System', 'Dark', 'Light'],
                selectedIndex: ['system', 'dark', 'light'].indexOf(settings.themeMode).clamp(0, 2),
                onChanged: (i) => notifier.setThemeMode(['system', 'dark', 'light'][i]),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ─── Data ──────────────────────────────────────────────────────
          _Section(
            title: 'Data',
            children: [
              _SettingsItem(
                icon: Icons.delete_sweep_rounded,
                title: 'Clear Transfer History',
                subtitle: 'Remove all transfer records',
                onTap: () => _confirmClearHistory(context),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
              ),
              _SettingsItem(
                icon: Icons.ios_share_rounded,
                title: 'Export Logs',
                subtitle: 'Save transfer logs for debugging',
                onTap: () => _exportLogs(context),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ─── About ─────────────────────────────────────────────────────
          _Section(
            title: 'About',
            children: [
              _SettingsItem(
                icon: Icons.info_outline_rounded,
                title: 'About LocalBeam',
                onTap: () => Navigator.pushNamed(context, '/about'),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Footer
          const _Footer(),
        ],
      ),
    );
  }

  String _formatChunkSize(int bytes) {
    return ChunkSizeOption.options
        .firstWhere((o) => o.bytes == bytes,
            orElse: () => ChunkSizeOption.options[2])
        .label;
  }

  String _themeLabel(String mode) {
    switch (mode) {
      case 'dark': return 'Dark';
      case 'light': return 'Light';
      default: return 'System Default';
    }
  }

  void _editDeviceName(BuildContext context, SettingsNotifier notifier) {
    final ctrl = TextEditingController(text: _nameController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Device Name'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Name shown to other devices',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              notifier.setDeviceName(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editDownloadPath(BuildContext context, SettingsNotifier notifier) async {
    // On mobile use default Downloads; on desktop allow picker
    try {
      Directory? dir;
      if (Platform.isAndroid || Platform.isIOS) {
        dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      } else {
        dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }
      await notifier.setDownloadPath(dir.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download path: ${dir.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not set path: $e')),
        );
      }
    }
  }

  void _editPassword(BuildContext context, SettingsNotifier notifier) {
    final ctrl = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Default Password'),
          content: TextField(
            controller: ctrl,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                onPressed: () => setInner(() => obscure = !obscure),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                notifier.setDefaultPassword(null);
                Navigator.pop(ctx);
              },
              child: const Text('Clear Password', style: TextStyle(color: AppColors.error)),
            ),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.length >= 6) {
                  notifier.setDefaultPassword(ctrl.text);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text('All transfer records will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(historyProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _exportLogs(BuildContext context) async {
    try {
      final logs = await ref.read(historyProvider.notifier).exportLogs();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/localbeam_logs.txt');
      await file.writeAsString(logs);
      // Share via system share sheet
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Log saved to ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

// ─── Settings building blocks ─────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceDim,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final widget = e.value;
              final isLast = e.key == children.length - 1;
              return Column(
                children: [
                  widget,
                  if (!isLast) const Divider(indent: 56, endIndent: 0, height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceDim))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.onSurfaceMuted),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceDim))
          : null,
      value: value,
      onChanged: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _SliderItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  const _SliderItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Row(
        children: [
          Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary)),
        ],
      ),
      subtitle: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}

class _PickerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _PickerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceDim)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.onSurfaceMuted),
      onTap: () => _showPicker(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ...items.asMap().entries.map((e) => ListTile(
                title: Text(e.value),
                trailing: e.key == selectedIndex
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  onChanged(e.key);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Made with 💙 by ${AppConstants.authorName}',
          style: const TextStyle(
            color: AppColors.onSurfaceDim,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            // url_launcher to open instagram
          },
          child: Text(
            AppConstants.authorInstagram,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${AppConstants.appName} v${AppConstants.appVersion} · ${AppConstants.licenseType}',
          style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 11),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
