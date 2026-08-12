import 'dart:typed_data';

/// True if [bytes] is a PNG that has an alpha / transparency channel
/// (RGBA, gray+alpha, or palette + tRNS) — suitable for a FIFA cutout.
bool isTransparentPng(Uint8List bytes) {
  if (bytes.length < 33) return false;
  const sig = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  for (var i = 0; i < 8; i++) {
    if (bytes[i] != sig[i]) return false;
  }

  // signature(8) + len(4) + "IHDR"(4) + width(4) + height(4) + bitDepth(1) → colorType @ 25
  final colorType = bytes[25];
  if (colorType == 4 || colorType == 6) return true; // gray+alpha / RGBA
  if (colorType != 3) return false; // palette needs tRNS

  var offset = 8;
  while (offset + 12 <= bytes.length) {
    final length = (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
    if (type == 'tRNS' && length > 0) return true;
    if (type == 'IEND') break;
    offset += 12 + length;
  }
  return false;
}

class PngCutoutException implements Exception {
  PngCutoutException([this.message = 'PNG transparent uniquement (fond transparent requis)']);
  final String message;
  @override
  String toString() => message;
}
