import 'dart:io';

void main() {
  final directory = Directory('lib');
  final libFiles = directory.listSync(recursive: true)
      .where((file) => file.path.endsWith('.dart') && file is File)
      .map((file) => file as File);

  for (final file in libFiles) {
    var content = file.readAsStringSync();
    bool changed = false;

    // A simple regex to remove "const " specifically from lines containing AppColors.
    // This isn't perfect for all ASTs but it resolves 99% of invalid `const` prepends in flutter UI code.
    final regex = RegExp(r'const\s+([A-Za-z0-9_]+\([^;]*?AppColors\.[a-zA-Z_0-9]+[^;]*?\))');
    
    // We will apply the regex iteratively since it might miss nested ones.
    var newContent = content;
    for(int i=0; i<5; i++) {
      newContent = newContent.replaceAllMapped(regex, (match) {
        return match.group(1)!;
      });
    }

    if (newContent != content) {
      file.writeAsStringSync(newContent);
    }
  }
}
