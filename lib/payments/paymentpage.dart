import 'package:flutter/cupertino.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayPage extends StatefulWidget {
  final num price;
  const RazorpayPage({required this.price, super.key});

  @override
  State<RazorpayPage> createState() => _RazorpayPageState();
}

class _RazorpayPageState extends State<RazorpayPage> {
  late final Razorpay _razorpay;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      openCheckout();
    });
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    Navigator.pop(context, {
      "Success": true,
      "PaymentId": response.paymentId ?? '',
    });
  }

  void _handleError(PaymentFailureResponse response) {
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      Navigator.pop(context, {"Success": false, "Cancelled": true});
    } else {
      Navigator.pop(context, {"Success": false});
    }
  }

  void openCheckout() {
    final int amountInPaise = (widget.price * 100).toInt();

    final Map<String, dynamic> options = {
      'key': 'rzp_live_SvyXO868ISC6wo',
      'amount': amountInPaise,
      'currency': 'INR',
      'name': 'Arka stay',
    };

    _razorpay.open(options);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: Center(child: CupertinoActivityIndicator()),
    );
  }
}
