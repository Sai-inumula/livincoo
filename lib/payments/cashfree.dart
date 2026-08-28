import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:http/http.dart' as http;

class CashfreeApiPage extends StatefulWidget {
  final double price;

  const CashfreeApiPage({
    super.key,
    required this.price,
  });

  @override
  State<CashfreeApiPage> createState() => _CashfreeApiPageState();
}

class _CashfreeApiPageState extends State<CashfreeApiPage> {
  final CFPaymentGatewayService _cfPaymentGatewayService =
  CFPaymentGatewayService();

  // ============================================================================
  // CASHFREE CREDENTIALS & API CONFIGURATION
  // ============================================================================
  // For Live Production: https://api.cashfree.com/pg
  // For Testing:         https://sandbox.cashfree.com/pg
  static const String baseUrl = 'https://api.cashfree.com/pg';
  static const String clientId = 'xxxxxxxxxx';       // from sandbox dashboard
  static const String clientSecret = 'xxxxxxxxxxxxxxxxx';   // cfsk_ma_test_...
  final CFEnvironment environment = CFEnvironment.PRODUCTION;


  bool loading = true;
  bool paymentStarted = false;

  String? orderId;
  String? paymentSessionId;

  @override
  void initState() {
    super.initState();

    // Set callback listeners for SDK finish/error events
    _cfPaymentGatewayService.setCallback(
      verifyPayment,
      onError,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      startPayment();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !paymentStarted || !loading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showSnackBar('Payment in progress. Please do not close.');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          automaticallyImplyLeading: !loading,
        ),
        body: Center(
          child: loading
              ? const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Initiating Cashfree Payment...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          )
              : const Text(
            'Verifying transaction status...',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 1. START PAYMENT
  // ============================================================================

  Future<void> startPayment() async {
    if (paymentStarted) return;

    setState(() {
      paymentStarted = true;
      loading = true;
    });

    try {
      // Step A: Create order via Direct Cashfree HTTP API
      final result = await createOrderDirectlyFromApi();

      if (result == null) {
        _paymentFailed(
          orderId: '',
          paymentId: '',
          message: 'Unable to create payment order',
        );
        return;
      }

      orderId = result['order_id'];
      paymentSessionId = result['payment_session_id'];

      if (orderId == null || paymentSessionId == null) {
        _paymentFailed(
          orderId: orderId ?? '',
          paymentId: '',
          message: 'Invalid session tokens received from API',
        );
        return;
      }

      // Step B: Launch Cashfree SDK Web Checkout
      await openCashfreeCheckout();
    } catch (e) {
     // debugPrint('Payment start exception: $e');

      _paymentFailed(
        orderId: orderId ?? '',
        paymentId: '',
        message: e is Exception
            ? e.toString().replaceAll('Exception: ', '')
            : 'Unable to start payment',
      );
    }
  }

  // ============================================================================
  // 2. DIRECT HTTP POST: CASHFREE CREATE ORDER API
  // ============================================================================

  Future<Map<String, String>?> createOrderDirectlyFromApi() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    String phone = user.phoneNumber ?? '';
    phone = phone.replaceAll(RegExp(r'\D'), '');

    if (phone.length > 10) {
      phone = phone.substring(phone.length - 10);
    }

    if (phone.length != 10) {
      phone = '9999999999'; // Fallback dummy phone for testing
    }

    final generatedOrderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';

    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'x-client-id': clientId,
        'x-client-secret': clientSecret,
        'x-api-version': "2025-01-01",
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'order_id': generatedOrderId,
        'order_amount': widget.price,
        'order_currency': 'INR',
        'customer_details': {
          'customer_id': user.uid,
          'customer_email': user.email ?? 'customer@example.com',
          'customer_phone': phone,
        },
      }),
    );

   // debugPrint('Create Order HTTP Status: ${response.statusCode}');
    //debugPrint('Create Order HTTP Body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cashfree Order API failed: ${response.body}');
    }

    final data = jsonDecode(response.body);

    if (data['order_id'] == null || data['payment_session_id'] == null) {
      throw Exception('Cashfree API did not return payment_session_id');
    }

    return {
      'order_id': data['order_id'].toString(),
      'payment_session_id': data['payment_session_id'].toString(),
    };
  }

  // ============================================================================
  // 3. OPEN CASHFREE CHECKOUT VIEW
  // ============================================================================

  Future<void> openCashfreeCheckout() async {
    if (orderId == null || paymentSessionId == null) {
      _paymentFailed(
        orderId: orderId ?? '',
        paymentId: '',
        message: 'Payment session missing',
      );
      return;
    }

    try {
      final session = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(orderId!)
          .setPaymentSessionId(paymentSessionId!)
          .build();

      final cfWebCheckout = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      _cfPaymentGatewayService.doPayment(cfWebCheckout);
    } on CFException catch (e) {
     // debugPrint('Cashfree SDK Exception: ${e.message}');
      _paymentFailed(
        orderId: orderId ?? '',
        paymentId: '',
        message: e.message ?? 'Cashfree SDK error',
      );
    } catch (e) {
     // debugPrint('Cashfree Checkout Exception: $e');
      _paymentFailed(
        orderId: orderId ?? '',
        paymentId: '',
        message: 'Unable to open checkout view',
      );
    }
  }

  // ============================================================================
  // 4. CASHFREE SDK CALLBACKS
  // ============================================================================

  void verifyPayment(String returnedOrderId) {
    //debugPrint('SDK Success Callback Triggered for Order: $returnedOrderId');
    verifyOrderDirectlyFromApi(returnedOrderId);
  }

  void onError(CFErrorResponse errorResponse, String returnedOrderId) {
    //debugPrint('SDK Error Callback: ${errorResponse.getMessage()}');

    _paymentFailed(
      orderId: returnedOrderId.isNotEmpty ? returnedOrderId : (orderId ?? ''),
      paymentId: '',
      message: errorResponse.getMessage() ?? 'Payment cancelled or failed',
    );
  }

  // ============================================================================
  // 5. DIRECT HTTP GET: CASHFREE VERIFY ORDER API
  // ============================================================================

  Future<void> verifyOrderDirectlyFromApi(String returnedOrderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$returnedOrderId'),
        headers: {
          'x-client-id': clientId,
          'x-client-secret': clientSecret,
          'x-api-version': "2025-01-01",
          'Accept': 'application/json',
        },
      );

     // debugPrint('Verify Order HTTP Status: ${response.statusCode}');
     // debugPrint('Verify Order HTTP Body: ${response.body}');

      if (response.statusCode != 200) {
        _paymentFailed(
          orderId: returnedOrderId,
          paymentId: '',
          message: 'Failed to fetch status from Cashfree',
        );
        return;
      }

      final data = jsonDecode(response.body);

      final String status = data['order_status']?.toString().toUpperCase() ?? '';
      final String paymentId = data['cf_order_id']?.toString() ?? '';

      if (!mounted) return;

      if (status == 'PAID') {
        _showSnackBar('Payment Successful!');

        Navigator.pop(
          context,
          {
            'Success': true,
            'PaymentId': paymentId,
            'OrderId': returnedOrderId,
          },
        );
      } else {
        _paymentFailed(
          orderId: returnedOrderId,
          paymentId: paymentId,
          message: 'Payment status: $status',
        );
      }
    } catch (e) {
     // debugPrint('Verification HTTP Exception: $e');
      _paymentFailed(
        orderId: returnedOrderId,
        paymentId: '',
        message: 'Error verifying order status',
      );
    }
  }

  // ============================================================================
  // UTILS
  // ============================================================================

  void _paymentFailed({
    required String orderId,
    required String paymentId,
    required String message,
  }) {
    _showSnackBar(message);

    if (!mounted) return;

    Navigator.pop(
      context,
      {
        'Success': false,
        'PaymentId': paymentId,
        'OrderId': orderId,
        'Message': message,
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}