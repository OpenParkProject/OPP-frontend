import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_user_home.dart';

class ParkingSubmitTicketPage extends StatefulWidget {
  final String plate;
  final int duration; // in minuti
  final DateTime startDate;

  const ParkingSubmitTicketPage({
    Key? key,
    required this.plate,
    required this.duration,
    required this.startDate,
  }) : super(key: key);

  @override
  State<ParkingSubmitTicketPage> createState() => _ParkingSubmitTicketPageState();
}

class _ParkingSubmitTicketPageState extends State<ParkingSubmitTicketPage> {
  bool _loading = false;
  String? _message;

  Future<void> _submitTicket() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    final Dio dio = Dio(BaseOptions(baseUrl: "http://openpark.com/api/v1"));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    try {
      final response = await dio.post(
        '/cars/${widget.plate}/tickets',
        data: {
          "plate": widget.plate,
          "start_date": widget.startDate.toUtc().toIso8601String(),
          "duration": widget.duration,
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      setState(() {
        _message = "✅ Ticket created successfully!";
      });

      // Optionally redirect to home after a delay
      await Future.delayed(Duration(seconds: 2));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainUserHomePage(username: "User")),
      );
    } catch (e) {
      String errorMsg = "Unknown error";
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          errorMsg = data['error'] ?? data['detail'] ?? data.values.join(", ");
        }
      }
      setState(() {
        _message = "❌ Failed to create ticket: $errorMsg";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _submitTicket();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Submitting Ticket")),
      body: Center(
        child: _loading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_message!, textAlign: TextAlign.center),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Back"),
                  ),
                ],
              ),
      ),
    );
  }
}
