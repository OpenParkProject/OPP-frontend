import 'package:flutter/material.dart';

class CardPaymentPage extends StatefulWidget {
  const CardPaymentPage({super.key});

  @override
  _CardPaymentPageState createState() => _CardPaymentPageState();
}

class _CardPaymentPageState extends State<CardPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final cardNumberController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();

  void saveCardInfo() async {
    if (_formKey.currentState!.validate()) {
      // 模拟支付处理逻辑
      bool paymentSuccess = await mockPaymentProcess();

      if (paymentSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PaymentSuccessPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed，please retry')),
        );
      }
    }
  }

  Future<bool> mockPaymentProcess() async {
    await Future.delayed(Duration(seconds: 2));
    // 这里模拟一个随机支付成功或失败的结果
    return DateTime.now().second % 2 == 0;
  }

  @override
  void dispose() {
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Credit Card')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: cardNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Card Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Card Number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: expiryController,
                decoration: InputDecoration(labelText: ' (MM/YY)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Expired date';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: cvvController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'CVV'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length != 3) {
                    return 'CVV';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveCardInfo,
                child: Text('Confirm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment Successfully')),
      body: Center(
        child: Text(
          'Payment Successfully！',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
