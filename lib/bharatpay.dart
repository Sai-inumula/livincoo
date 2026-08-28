import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BharatPeIntegrationPage(),
    );
  }
}

class BharatPeIntegrationPage extends StatefulWidget {
  const BharatPeIntegrationPage({super.key});

  @override
  State<BharatPeIntegrationPage> createState() =>
      _BharatPeIntegrationPageState();
}

class _BharatPeIntegrationPageState extends State<BharatPeIntegrationPage> {
  bool _isLoading = false;

  // IMPORTANT: For security, never store API secret keys directly inside Dart code.
  // Always hit your own backend API server, which acts as a bridge to BharatPe APIs.
  Future<void> initiateBharatPePayment() async {
    setState(() {
      _isLoading = true;
    });

    final String backendApiUrl =
        "https://yourbackend.com/api/v1/create-bharatpe-order";

    try {
      // 1. Create order payload
      final response = await http.post(
        Uri.parse(backendApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": "100.00", // Amount in INR
          "orderId": "ORD_${DateTime.now().millisecondsSinceEpoch}",
          "customerName": "John Doe",
          "merchantVpa":
              "merchantname@bharatpe", // Your registered business VPA
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Extract the generated UPI deep-link string provided by BharatPe's system
        // Format looks like: upi://pay?pa=merchant@bharatpe&pn=Name&am=100.00...
        final String upiIntentUrl = data['upiString'] ?? '';

        if (upiIntentUrl.isNotEmpty) {
          _launchUPIIntent(upiIntentUrl);
        } else {
          _showSnackBar("Failed to generate payment intent string.");
        }
      } else {
        _showSnackBar("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("An error occurred: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 2. Launch the Deep link into installed UPI apps (including BharatPe)
  Future<void> _launchUPIIntent(String urlStr) async {
    final Uri url = Uri.parse(urlStr);

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode:
            LaunchMode
                .externalApplication, // Crucial for opening external banking apps
      );

      // 3. After returning to the app, verify the transaction status
      _checkPaymentStatus();
    } else {
      _showSnackBar("No compatible UPI app or BharatPe found on this device.");
    }
  }

  // 4. Poll your server or use webhooks to verify if the payment went through
  Future<void> _checkPaymentStatus() async {
    _showSnackBar("Checking payment status with server...");
    // Implement an API call here to your backend to confirm BharatPe webhook status
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BharatPe UPI Integration"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child:
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Amount to Pay: ₹100.00",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.green,
                      ),
                      onPressed: initiateBharatPePayment,
                      icon: const Icon(Icons.payment, color: Colors.white),
                      label: const Text(
                        "Pay via UPI / BharatPe",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
