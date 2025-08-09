import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final Map<String, String> creds;

  ApiService(this.creds);

  String _basicAuth(String user, String pass) {
    final str = '$user:$pass';
    return 'Basic ${base64Encode(utf8.encode(str))}';
  }

  Future<bool> testWooCommerce() async {
    final url = '${creds['wooUrl']}/wp-json/wc/v3/orders';
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _basicAuth(creds['wooKey']!, creds['wooSecret']!),
        },
      );
      print('[WooCommerce] Status: ${res.statusCode}, Body: ${res.body}');
      if (res.statusCode != 200) {
        print('[WooCommerce] Credential issue: Key/Secret/URL may be invalid.');
      }
      return res.statusCode == 200;
    } catch (e) {
      print('[WooCommerce] Exception: ${e.toString()}');
      return false;
    }
  }

  Future<bool> testWordPress() async {
    if ((creds['wpUser']?.isEmpty ?? true) || (creds['wpPass']?.isEmpty ?? true)) {
      print('[WordPress] Skipping test: Username or App Password not provided.');
      return true;
    }
    final url = '${creds['wooUrl']}/wp-json/wp/v2/users/me';
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _basicAuth(creds['wpUser']!, creds['wpPass']!),
        },
      );
      print('[WordPress] Status: ${res.statusCode}, Body: ${res.body}');
      if (res.statusCode != 200) {
        print('[WordPress] Credential issue: Username/App Password/URL may be invalid.');
      }
      return res.statusCode == 200;
    } catch (e) {
      print('[WordPress] Exception: ${e.toString()}');
      return false;
    }
  }

  Future<bool> testGorgias() async {
    if ((creds['gorgiasToken']?.isEmpty ?? true) || (creds['gorgiasSub']?.isEmpty ?? true)) {
      print('[Gorgias] Skipping test: Token or Subdomain not provided.');
      return true;
    }
    final url = 'https://${creds['gorgiasSub']}.gorgias.com/api/tickets';
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${creds['gorgiasToken']}',
          'Accept': 'application/json',
        },
      );
      print('[Gorgias] Status: ${res.statusCode}, Body: ${res.body}');
      if (res.statusCode != 200) {
        print('[Gorgias] Credential issue: Token/Subdomain may be invalid.');
      }
      return res.statusCode == 200;
    } catch (e) {
      print('[Gorgias] Exception: ${e.toString()}');
      return false;
    }
  }
}
