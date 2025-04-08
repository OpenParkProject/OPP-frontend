import 'package:flutter/material.dart';

import 'card_payment.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Choose your payment method',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PaymentSelectionPage(),
    );
  }
}

class PaymentSelectionPage extends StatefulWidget {
  @override
  _PaymentSelectionPageState createState() => _PaymentSelectionPageState();
}

class _PaymentSelectionPageState extends State<PaymentSelectionPage> {
  final List<String> paymentMethods = [
    'PayPal',
    'Google Pay',
    'Apple Pay',
    'Credit Card'
  ];

  String selectedMethod = 'PayPal';

  void navigateToPayment() {
    if (selectedMethod == 'Credit Card') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CardPaymentPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProcessingPaymentPage(method: selectedMethod),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Choose your payment method')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedMethod,
              isExpanded: true,
              items: paymentMethods.map((String method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedMethod = value!;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: navigateToPayment,
              child: Text('Pay'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProcessingPaymentPage extends StatefulWidget {
  final String method;
  ProcessingPaymentPage({required this.method});

  @override
  _ProcessingPaymentPageState createState() => _ProcessingPaymentPageState();
}

class _ProcessingPaymentPageState extends State<ProcessingPaymentPage> {
  @override
  void initState() {
    super.initState();
    processPayment();
  }

  void processPayment() async {
    bool success = await mockPaymentAPI(widget.method);
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PaymentSuccessPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PaymentFailurePage()),
      );
    }
  }

  Future<bool> mockPaymentAPI(String method) async {
    await Future.delayed(Duration(seconds: 2));
    return DateTime.now().second % 2 == 0; // 模拟随机成功或失败
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.method} loading')),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class PaymentSuccessPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment Success')),
      body: Center(
        child: Text(
          'Payment Success！',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

class PaymentFailurePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment Failure')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Payment failure, please retry.',
              style: TextStyle(fontSize: 20, color: Colors.red),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text('Go back to choose payment method'),
            ),
          ],
        ),
      ),
    );
  }
}



