import 'dart:io';

import 'package:image/image.dart' as img;

/// Converts WebP/mislabeled logo files to valid PNG for Android resources.
void main() {
  const sourcePath = 'assets/images/grj_logo.png';
  final sourceBytes = File(sourcePath).readAsBytesSync();
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) {
    stderr.writeln('Failed to decode $sourcePath');
    exit(1);
  }

  File(sourcePath).writeAsBytesSync(img.encodePng(decoded));
  stdout.writeln('Converted $sourcePath to PNG');

  const drawablePath = 'android/app/src/main/res/drawable-nodpi/grj_logo.png';
  File(drawablePath).writeAsBytesSync(img.encodePng(decoded));
  stdout.writeln('Wrote $drawablePath');

  const launcherSizes = <String, int>{
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in launcherSizes.entries) {
    final resized = img.copyResize(
      decoded,
      width: entry.value,
      height: entry.value,
      interpolation: img.Interpolation.cubic,
    );
    final out = File('android/app/src/main/res/${entry.key}/ic_launcher.png');
    out.writeAsBytesSync(img.encodePng(resized));
    stdout.writeln('Wrote ${out.path} (${entry.value}px)');
  }
}
