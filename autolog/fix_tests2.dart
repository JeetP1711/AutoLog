import 'dart:io';

void main() async {
  final testDir = Directory('test');
  final files = testDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    var content = await file.readAsString();
    bool changed = false;

    // We have lines like:
    //      property(
    //        forAll(_whitespaceString),
    //        (String ws) {
    
    // We want to remove `property(` and extract the inside of `forAll(...)` and the function block.
    // Actually, simple string replacement works if we just replace `property(\n        forAll(` with `forAll(\n        `
    // Wait, the formatting might be slightly different.
    
    // Let's replace `property(\n        forAll(` with `forAll(`
    if (content.contains('property(\n        forAll(')) {
      content = content.replaceAll('property(\n        forAll(', 'forAll(');
      changed = true;
    } else if (content.contains('property(\n      forAll(')) {
      content = content.replaceAll('property(\n      forAll(', 'forAll(');
      changed = true;
    } else if (content.contains('property(forAll(')) {
      content = content.replaceAll('property(forAll(', 'forAll(');
      changed = true;
    } else if (content.contains('property(\n    forAll(')) {
      content = content.replaceAll('property(\n    forAll(', 'forAll(');
      changed = true;
    }
    
    // In `kiri_check`, `forAll` takes (arbitrary, function)
    // Example: `forAll(_whitespaceString, (ws) { ... })`
    // Before it was `forAll(_whitespaceString), \n (ws) {`
    // So we need to replace `),\n        (ws) {` with `, (ws) {`
    
    // Let's use regex for replacing `), \n (args) {` with `, (args) {`
    // Specifically looking for `),\n` followed by whitespace and `(`
    var regex = RegExp(r'\),\n\s*\(');
    if (regex.hasMatch(content) && changed) {
       content = content.replaceAllMapped(regex, (match) {
         // but wait, there could be other matches. 
         // Let's just fix it manually for the files if regex is too risky, or use a better regex:
         return match.group(0)!.replaceFirst('),\n', ',\n');
       });
    }
    
    // also we need to remove the closing `)` from the end of the property call
    // The previous code had:
    //        },
    //      );
    // Which was closing `property(`. We need to remove it or change it.
    // If it was:
    //        },
    //      );
    // We can just leave it? No, if we removed `property(`, we removed one `(`.
    // Wait, `forAll` still takes the closure, so it still needs a closing `)`.
    // Wait!
    // Original: `property( forAll(arb), (val) { ... } );`
    // New: `forAll( arb, (val) { ... } );`
    // Both end with `);`! So we don't need to change the end at all!!!
    
    if (changed) {
      await file.writeAsString(content);
      print('Fixed \${file.path}');
    }
  }
}
