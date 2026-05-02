import 'dart:io';

void main() async {
  final testDir = Directory('test');
  final files = testDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    var content = await file.readAsString();
    bool changed = false;

    if (content.contains('await property(')) {
      content = content.replaceAll('await property(', 'property(');
      changed = true;
    }

    if (content.contains('(vehicles) {')) {
      content = content.replaceAll('(vehicles) {', '(List<Vehicle> vehicles) {');
      changed = true;
    }
    if (content.contains('(logs) {')) {
      content = content.replaceAll('(logs) {', '(List<dynamic> logs) {');
      changed = true;
    }
    if (content.contains('(docs) {')) {
      content = content.replaceAll('(docs) {', '(List<Document> docs) {');
      changed = true;
    }
    if (content.contains('(reminders) {')) {
      content = content.replaceAll('(reminders) {', '(List<Reminder> reminders) {');
      changed = true;
    }

    // specific to other files, but changing generic ones is okay
    
    // For single models
    if (content.contains('(log) {')) {
      content = content.replaceAll('(log) {', '(dynamic log) {');
      changed = true;
    }

    if (changed) {
      await file.writeAsString(content);
      print('Fixed \${file.path}');
    }
  }
}
