import 'package:flutter/material.dart';

import 'card_payment.dart';


class PaymentSelectionPage extends StatefulWidget {
  const PaymentSelectionPage({super.key});

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
          builder: (context) => GenericPaymentPage(method: selectedMethod),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}

class GenericPaymentPage extends StatelessWidget {
  final String method;

  GenericPaymentPage({required this.method});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$method pay')),
      body: Center(
        child: Text(
          'This is $method payment',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
