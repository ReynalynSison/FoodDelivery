import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'payment_service.dart';

class PaymentPage extends StatefulWidget {
  final double totalAmount;

  const PaymentPage({super.key, required this.totalAmount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final PaymentService _paymentService = PaymentService();

  bool _isLoading = true;
  bool _isPolling = false;
  String _statusMessage = 'Creating invoice...';
  String? _invoiceId;
  Timer? _pollingTimer;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _createInvoice();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _createInvoice() async {
    try {
      final result = await _paymentService.createInvoice(
        amount: widget.totalAmount,
        description: 'Food Order',
      );

      final invoiceUrl = result['invoice_url'] as String?;
      _invoiceId = result['invoice_id'] as String?;
      debugPrint('Invoice created: id=$_invoiceId, url=$invoiceUrl');

      if (invoiceUrl == null || invoiceUrl.isEmpty) {
        throw Exception('Invoice URL is empty');
      }

      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(invoiceUrl));

      setState(() {
        _isLoading = false;
      });

      debugPrint('WebView controller created, starting polling');
      _startPolling();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      if (mounted) {
        _showErrorDialog('Failed to create invoice: $e');
      }
    }
  }

  void _startPolling() {
    if (_invoiceId == null || _isPolling) return;

    setState(() {
      _isPolling = true;
      _statusMessage = 'Checking payment status...';
    });

    debugPrint('Polling started for invoice: $_invoiceId');

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final status = await _paymentService.checkInvoiceStatus(_invoiceId!);
        debugPrint('Invoice status: $status');

        setState(() {
          _statusMessage = 'Status: $status';
        });

        if (status == 'PAID') {
          timer.cancel();
          if (mounted) {
            debugPrint('Closing WebView after payment success');
            Navigator.of(context).pop(true);
          }
        } else if (status == 'EXPIRED' || status == 'FAILED') {
          timer.cancel();
          if (mounted) {
            _showErrorDialog('Payment $status. Please try again.');
          }
        }
      } catch (e) {
        setState(() {
          _statusMessage = 'Error checking status: $e';
        });
      }
    });
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Payment Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Payment'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CupertinoActivityIndicator(radius: 20),
                    const SizedBox(height: 16),
                    Text(_statusMessage),
                  ],
                ),
              )
            : _webViewController != null
                ? WebViewWidget(controller: _webViewController!)
                : Center(
                    child: Text(_statusMessage),
                  ),
      ),
    );
  }
}
