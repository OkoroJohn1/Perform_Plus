/// Copies a picked file into the app documents directory and works out its
/// page count — never relies on the original picked path, since Android
/// can revoke access to it after the picker closes.
///
/// V1 schema note: each [Note] row has exactly one `filePath` (see
/// `notes_table.dart`), so an image upload is a single-page note; a
/// student photographing several pages of the same handout uploads them as
/// separate notes for now. PDFs are the only genuinely multi-page path,
/// via their own real page count.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/engine/study_engine.dart';
import '../../../domain/models/note.dart';
import '../screens/note_reader_screen.dart';

const _uuid = Uuid();

class UnsupportedNoteFileException implements Exception {
  final String message;
  const UnsupportedNoteFileException(this.message);
}

class ImportedNoteFile {
  final String filePath;
  final NoteFileType fileType;
  final int totalPages;
  final String suggestedTitle;

  const ImportedNoteFile({
    required this.filePath,
    required this.fileType,
    required this.totalPages,
    required this.suggestedTitle,
  });
}

/// Throws [UnsupportedNoteFileException] for anything outside
/// [supportedNoteExtensions] — DOCX/PPTX need server-side conversion that
/// doesn't exist yet, and this app never fails silently on that.
Future<ImportedNoteFile> importNoteFile(String sourcePath, {PageRenderer? renderer}) async {
  final unsupported = unsupportedFileMessage(sourcePath);
  if (unsupported != null) throw UnsupportedNoteFileException(unsupported);

  final ext = p.extension(sourcePath).toLowerCase();
  final isPdf = ext == '.pdf';
  final destDir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'notes'));
  if (!await destDir.exists()) await destDir.create(recursive: true);
  final destPath = p.join(destDir.path, '${_uuid.v4()}$ext');
  await File(sourcePath).copy(destPath);

  final totalPages = isPdf ? await (renderer ?? PdfxPageRenderer()).pageCount(destPath) : 1;
  final title = p.basenameWithoutExtension(sourcePath);

  return ImportedNoteFile(
    filePath: destPath,
    fileType: isPdf ? NoteFileType.pdf : NoteFileType.image,
    totalPages: totalPages,
    suggestedTitle: title,
  );
}
