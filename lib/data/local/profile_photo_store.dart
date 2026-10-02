/// Local-first profile photo handling: pick -> square-crop -> downscale ->
/// JPEG-encode -> save to the app documents directory. A raw phone photo
/// is several MB for something displayed at 128dp, so nothing this large
/// is ever kept or (eventually) uploaded as-is.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const profilePhotoMaxDimension = 512;
const profilePhotoJpegQuality = 85;

Future<Uint8List?> pickProfilePhotoBytes(ImageSource source) async {
  final file = await ImagePicker().pickImage(source: source, imageQuality: 90);
  if (file == null) return null;
  return file.readAsBytes();
}

/// A low-memory Android device can kill this app's whole process while the
/// system camera is in the foreground -- the pending `pickImage()` future
/// above never resolves, and the picked photo would otherwise just be lost
/// once the student returns to a freshly-restarted app. `image_picker`
/// keeps that result on the platform side for exactly this case; this must
/// be called once, early (see `profile_setup_screen.dart`'s `initState`),
/// before any other picker call this session. Returns `null` on a normal
/// launch (nothing was lost) or if retrieval itself fails.
Future<Uint8List?> retrieveLostProfilePhotoBytes() async {
  try {
    final response = await ImagePicker().retrieveLostData();
    if (response.isEmpty || response.file == null) return null;
    return response.file!.readAsBytes();
  } catch (_) {
    return null;
  }
}

/// Centre-crops to a square, downscales to at most 512x512, and re-encodes
/// as JPEG. Throws [FormatException] if [bytes] isn't a decodable image.
Uint8List processProfilePhoto(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Could not decode the selected image.');
  }

  final side = decoded.width < decoded.height ? decoded.width : decoded.height;
  final x = ((decoded.width - side) / 2).round();
  final y = ((decoded.height - side) / 2).round();
  final square = img.copyCrop(decoded, x: x, y: y, width: side, height: side);

  final resized = side > profilePhotoMaxDimension
      ? img.copyResize(
          square,
          width: profilePhotoMaxDimension,
          height: profilePhotoMaxDimension,
          interpolation: img.Interpolation.average,
        )
      : square;

  return Uint8List.fromList(
    img.encodeJpg(resized, quality: profilePhotoJpegQuality),
  );
}

/// Overwrites any previous photo at a fixed filename — there is only ever
/// one profile photo locally. Returns the path stored on the profile row.
Future<String> saveProfilePhoto(Uint8List processedBytes) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'profile_photo.jpg'));
  await file.writeAsBytes(processedBytes, flush: true);
  return file.path;
}

Future<void> deleteProfilePhotoFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {
    // Best-effort — a stray file left on disk isn't worth surfacing.
  }
}
