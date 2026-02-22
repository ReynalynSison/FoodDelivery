import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  static const String _baseUrl = 'https://api.xendit.co/v2/invoices';

  Future<Map<String, dynamic>> createInvoice({
    required double amount,
    required String description,
  }) async {
    final secretKey = dotenv.env['XENDIT_SECRET_KEY'];

    if (secretKey == null || secretKey.isEmpty) {
      throw Exception('XENDIT_SECRET_KEY not found in .env');
    }

    final auth = base64Encode(utf8.encode('$secretKey:'));

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'external_id': 'invoice_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'description': description,
        'currency': 'PHP',
        'invoice_duration': 3600,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'invoice_url': data['invoice_url'],
        'invoice_id': data['id'],
      };
    } else {
      throw Exception('Failed to create invoice: ${response.body}');
    }
  }

  Future<String> checkInvoiceStatus(String invoiceId) async {
    final secretKey = dotenv.env['XENDIT_SECRET_KEY'];

    if (secretKey == null || secretKey.isEmpty) {
      throw Exception('XENDIT_SECRET_KEY not found in .env');
    }

    final auth = base64Encode(utf8.encode('$secretKey:'));

    final response = await http.get(
      Uri.parse('$_baseUrl/$invoiceId'),
      headers: {
        'Authorization': 'Basic $auth',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'];
    } else {
      throw Exception('Failed to check invoice status: ${response.body}');
    }
  }
}

