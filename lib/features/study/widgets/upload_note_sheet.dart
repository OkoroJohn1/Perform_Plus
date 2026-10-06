/// The Study tab's upload entry point. V1 supports PDF and images only —
/// DOCX/PPTX need server-side conversion, which needs a backend that
/// doesn't exist yet; picking one shows a concrete message rather than
/// failing silently (a common case, since lecture material is frequently
/// distributed as PowerPoint).
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/note_provider.dart';
import '../../../domain/models/note.dart';
import '../services/note_import_service.dart';

/// Test-only injection points — mirrors `add_first_results_screen.dart`'s
/// `debugPickImage` pattern. Each returns a local file path, or null if the
/// student backed out of the picker.
typedef PickPdfPath = Future<String?> Function();
typedef PickImagePath = Future<String?> Function(ImageSource source);

Future<String?> _defaultPickPdf() async {
  final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
  return result.isEmpty ? null : result.first.path;
}

Future<String?> _defaultPickImage(ImageSource source) async {
  final file = await ImagePicker().pickImage(source: source, imageQuality: 90);
  return file?.path;
}

Future<void> showUploadNoteSheet(
  BuildContext context, {
  NoteCategory category = NoteCategory.note,
  PickPdfPath? debugPickPdf,
  PickImagePath? debugPickImage,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _UploadNoteSheet(
      category: category,
      pickPdf: debugPickPdf ?? _defaultPickPdf,
      pickImage: debugPickImage ?? _defaultPickImage,
    ),
  );
}

class _UploadNoteSheet extends ConsumerStatefulWidget {
  final NoteCategory category;
  final PickPdfPath pickPdf;
  final PickImagePath pickImage;

  const _UploadNoteSheet({required this.category, required this.pickPdf, required this.pickImage});

  @override
  ConsumerState<_UploadNoteSheet> createState() => _UploadNoteSheetState();
}

class _UploadNoteSheetState extends ConsumerState<_UploadNoteSheet> {
  bool _busy = false;

  Future<void> _handle(Future<String?> Function() pick) async {
    final path = await pick();
    if (path == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final imported = await importNoteFile(path);
      await ref.read(notesProvider.notifier).uploadNote(
            title: imported.suggestedTitle,
            filePath: imported.filePath,
            fileType: imported.fileType,
            totalPages: imported.totalPages,
            category: widget.category,
          );
      if (mounted) Navigator.of(context).pop();
    } on UnsupportedNoteFileException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(e.message)),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't import that file. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _UploadOption(
            icon: Icons.picture_as_pdf,
            label: 'Choose a PDF',
            onTap: () => _handle(widget.pickPdf),
          ),
          Divider(height: 1, color: context.palette.divider),
          _UploadOption(
            icon: Icons.image_outlined,
            label: 'Choose images',
            onTap: () => _handle(() => widget.pickImage(ImageSource.gallery)),
          ),
          Divider(height: 1, color: context.palette.divider),
          _UploadOption(
            icon: Icons.photo_camera_outlined,
            label: 'Photograph pages',
            onTap: () => _handle(() => widget.pickImage(ImageSource.camera)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(icon, size: 20, color: context.palette.primary),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
