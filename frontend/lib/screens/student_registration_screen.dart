import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../models/event.dart';
import '../services/student_registration_service.dart';

class StudentRegistrationScreen extends StatefulWidget {
  final Event event;

  const StudentRegistrationScreen({
    super.key,
    required this.event,
  });

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends State<StudentRegistrationScreen> {
  static const Color backgroundColor = Color(0xFF080B1F);
  static const Color cardColor = Color(0xFF11152D);

  final StudentRegistrationService _registrationService =
      StudentRegistrationService();

  late Razorpay _razorpay;

  bool _isRegistering = false;
  String? _currentOrderId;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      _handlePaymentSuccess,
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      _handlePaymentError,
    );

    _razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _register() async {
    if (_isRegistering) return;

    setState(() {
      _isRegistering = true;
    });

    try {
      if (widget.event.paymentType == 'FREE') {
        await _registerFreeEvent();
      } else {
        await _startPayment();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRegistering = false;
      });

      _showError(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _registerFreeEvent() async {
    await _registrationService.registerForFreeEvent(
      widget.event.id,
    );

    if (!mounted) return;

    setState(() {
      _isRegistering = false;
    });

    await _showSuccess(
      'Registration Successful',
      'You have successfully registered for this event.',
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Future<void> _startPayment() async {
    final order = await _registrationService.createPaymentOrder(
      widget.event.id,
    );

    final orderId = order['razorpayOrderId']?.toString();
    final keyId = order['razorpayKeyId']?.toString();

    if (orderId == null || orderId.isEmpty) {
      throw Exception(
        'Razorpay order ID was not returned.',
      );
    }

    if (keyId == null || keyId.isEmpty) {
      throw Exception(
        'Razorpay key ID was not returned.',
      );
    }

    _currentOrderId = orderId;

    final amount = order['amount'];

    final options = {
      'key': keyId,
      'amount': _amountInPaise(amount),
      'name': 'CampusSync',
      'description': widget.event.title,
      'order_id': orderId,
      'currency': 'INR',
      'theme': {
        'color': '#080B1F',
      },
      'retry': {
        'enabled': true,
        'max_count': 2,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRegistering = false;
      });

      _showError(
        'Unable to open Razorpay checkout.',
      );
    }
  }

  int _amountInPaise(dynamic amount) {
    if (amount is num) {
      return (amount * 100).round();
    }

    final parsedAmount = double.tryParse(
      amount?.toString() ?? '',
    );

    if (parsedAmount == null) {
      throw Exception('Invalid payment amount.');
    }

    return (parsedAmount * 100).round();
  }

  Future<void> _handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) async {
    final orderId = response.orderId ?? _currentOrderId;
    final paymentId = response.paymentId;
    final signature = response.signature;

    if (orderId == null ||
        orderId.isEmpty ||
        paymentId == null ||
        paymentId.isEmpty ||
        signature == null ||
        signature.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isRegistering = false;
      });

      _showError(
        'Payment succeeded, but required payment details '
        'were missing.',
      );

      return;
    }

    try {
      final result = await _registrationService.verifyPayment(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );

      if (!mounted) return;

      setState(() {
        _isRegistering = false;
      });

      await _showSuccess(
        'Payment Successful',
        _successMessage(result),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRegistering = false;
      });

      _showError(
        'Payment was received, but verification failed.\n\n'
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  String _successMessage(
    Map<String, dynamic> result,
  ) {
    final status = result['status']?.toString();

    if (status != null && status.isNotEmpty) {
      return 'Your payment has been verified successfully.\n\n'
          'Registration status: $status';
    }

    return 'Your payment has been verified successfully.\n\n'
        'You are now registered for the event.';
  }

  void _handlePaymentError(
    PaymentFailureResponse response,
  ) {
    if (!mounted) return;

    setState(() {
      _isRegistering = false;
    });

    final message = response.message;

    _showError(
      message != null && message.isNotEmpty
          ? 'Payment failed.\n\n$message'
          : 'Payment failed or was cancelled.',
    );
  }

  void _handleExternalWallet(
    ExternalWalletResponse response,
  ) {
    if (!mounted) return;

    setState(() {
      _isRegistering = false;
    });

    _showInfo(
      'External Wallet',
      'External wallet selected: '
          '${response.walletName ?? 'Unknown wallet'}',
    );
  }

  Future<void> _showSuccess(
    String title,
    String message,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Registration Failed',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInfo(
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');

    return '$day/$month/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour =
        dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;

    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  Widget _summaryRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white60,
            size: 20,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isPaid = event.paymentType == 'PAID';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Registration',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              event.organizationName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white12,
                ),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    Icons.calendar_today_outlined,
                    'Date',
                    _formatDate(event.startDateTime),
                  ),
                  _summaryRow(
                    Icons.access_time_rounded,
                    'Time',
                    _formatTime(event.startDateTime),
                  ),
                  _summaryRow(
                    Icons.location_on_outlined,
                    'Venue',
                    event.venue,
                  ),
                  _summaryRow(
                    Icons.payments_outlined,
                    'Fee',
                    isPaid
                        ? '₹${event.registrationFee.toStringAsFixed(2)}'
                        : 'FREE',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              isPaid
                  ? 'Payment Information'
                  : 'Registration Confirmation',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              isPaid
                  ? 'You will be redirected to Razorpay to complete '
                      'your payment securely.'
                  : 'This is a free event. No payment is required.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isRegistering ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: backgroundColor,
                  disabledBackgroundColor: Colors.white38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isRegistering
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: backgroundColor,
                        ),
                      )
                    : Text(
                        isPaid
                            ? 'Proceed to Payment'
                            : 'Confirm Registration',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}