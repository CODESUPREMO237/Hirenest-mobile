// ignore_for_file: avoid_print
import 'dart:io';

/// Checks if a file is empty or only contains comments/whitespace
bool isEffectivelyEmpty(File file) {
  final lines = file.readAsLinesSync();

  // Remove empty lines and lines with only comments
  final contentLines = lines.where((line) {
    final trimmed = line.trim();
    return trimmed.isNotEmpty && !trimmed.startsWith('//') && !trimmed.startsWith('/*') && !trimmed.startsWith('*');
  }).toList();

  return contentLines.isEmpty;
}

void main() {
  final projectDir = Directory('lib'); // Change if you want another root
  final emptyFiles = <String>[];

  void scanDirectory(Directory dir) {
    for (var entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        if (isEffectivelyEmpty(entity)) {
          emptyFiles.add(entity.path);
        }
      }
    }
  }

  scanDirectory(projectDir);

  if (emptyFiles.isEmpty) {
    print('✅ All Dart files have code.');
  } else {
    print('⚠️ The following Dart files are empty or only have comments:\n');
    for (var filePath in emptyFiles) {
      print(filePath);
    }
  }
}
