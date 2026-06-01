import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final packages = ['phosphor_flutter', 'lucide_icons', 'lucide_icons_flutter'];
  final client = HttpClient();
  for (final pkg in packages) {
    try {
      final req = await client.getUrl(Uri.parse('https://pub.dev/api/packages/$pkg'));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body);
      print('$pkg latest version: ${json['latest']['version']}');
      if (json['versions'] != null) {
        final versions = (json['versions'] as List).map((v) => v['version']).toList();
        print('$pkg all versions: $versions');
      }
    } catch (e) {
      print('Failed to fetch $pkg: $e');
    }
  }
  client.close();
}
