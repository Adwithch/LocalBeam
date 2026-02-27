// lib/presentation/screens/file_picker/file_picker_screen.dart

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/beam_button.dart';

class FilePickerScreen extends StatefulWidget {
  const FilePickerScreen({super.key});

  @override
  State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  final List<PlatformFile> _selectedFiles = [];
  bool _picking = false;

  int get _totalSize => _selectedFiles.fold(0, (sum, f) => sum + (f.size));

  String _fmt(int b) {
    if (b < 1024) return '${b}B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)}KB';
    if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(2)}MB';
    return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
  }

  Future<void> _pickFiles() async {
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withReadStream: false,
        withData: false,
      );
      if (result != null) {
        setState(() {
          final newFiles = result.files.where(
            (f) => !_selectedFiles.any((e) => e.path == f.path),
          );
          _selectedFiles.addAll(newFiles);
        });
      }
    } finally {
      setState(() => _picking = false);
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  void _proceed() {
    final paths = _selectedFiles
        .map((f) => f.path)
        .whereType<String>()
        .toList();
    Navigator.pop(context, paths);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Files'),
        actions: [
          if (_selectedFiles.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _selectedFiles.clear()),
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Drop zone / pick area
          Expanded(
            child: _selectedFiles.isEmpty
                ? _EmptyDropZone(onPick: _pickFiles, picking: _picking)
                : _FileList(
                    files: _selectedFiles,
                    onRemove: _removeFile,
                    onAddMore: _pickFiles,
                    picking: _picking,
                  ),
          ),

          // Footer
          if (_selectedFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.outline)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '${_selectedFiles.length} file${_selectedFiles.length > 1 ? 's' : ''}',
                        style: theme.textTheme.titleSmall,
                      ),
                      const Spacer(),
                      Text(
                        _fmt(_totalSize),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BeamButton(
                    onPressed: _proceed,
                    label: 'Continue to Send',
                    icon: Icons.arrow_forward_rounded,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyDropZone extends StatelessWidget {
  final VoidCallback onPick;
  final bool picking;

  const _EmptyDropZone({required this.onPick, required this.picking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.upload_file_rounded, size: 56, color: AppColors.primary),
          )
              .animate()
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 700.ms),
          const SizedBox(height: 24),
          Text('No files selected', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to pick files',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceDim),
          ),
          const SizedBox(height: 32),
          BeamButton(
            onPressed: picking ? null : onPick,
            label: 'Browse Files',
            icon: Icons.folder_open_rounded,
            loading: picking,
          ),
          const SizedBox(height: 12),
          Text(
            'Any file type supported',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}

class _FileList extends StatelessWidget {
  final List<PlatformFile> files;
  final void Function(int) onRemove;
  final VoidCallback onAddMore;
  final bool picking;

  const _FileList({
    required this.files,
    required this.onRemove,
    required this.onAddMore,
    required this.picking,
  });

  String _fmt(int b) {
    if (b < 1024) return '${b}B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)}KB';
    if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(2)}MB';
    return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
  }

  IconData _fileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg': case 'jpeg': case 'png': case 'gif': case 'webp': case 'heic':
        return Icons.image_rounded;
      case 'mp4': case 'mov': case 'avi': case 'mkv': case 'webm':
        return Icons.video_file_rounded;
      case 'mp3': case 'wav': case 'aac': case 'flac': case 'm4a':
        return Icons.audio_file_rounded;
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'zip': case 'rar': case '7z': case 'tar': case 'gz':
        return Icons.folder_zip_rounded;
      case 'apk': return Icons.android_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...files.asMap().entries.map((entry) {
          final i = entry.key;
          final f = entry.value;
          final ext = p.extension(f.name).replaceFirst('.', '');

          return Dismissible(
            key: Key(f.path ?? f.name),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_rounded, color: AppColors.error),
            ),
            onDismissed: (_) => onRemove(i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_fileIcon(ext), size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _fmt(f.size),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.onSurfaceMuted,
                    onPressed: () => onRemove(i),
                  ),
                ],
              ),
            ).animate(delay: Duration(milliseconds: i * 30)).slideX(begin: 0.1).fadeIn(),
          );
        }),

        // Add more button
        TextButton.icon(
          onPressed: picking ? null : onAddMore,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add More Files'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}
