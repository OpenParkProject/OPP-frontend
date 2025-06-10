import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../API/client.dart';

class AddEditControllerDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const AddEditControllerDialog({this.existing, super.key});

  @override
  State<AddEditControllerDialog> createState() => _AddEditControllerDialogState();
}

class _AddEditControllerDialogState extends State<AddEditControllerDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  List<Map<String, dynamic>> allZones = [];
  Set<int> selectedZoneIds = {};
  bool loading = false;
  String? error;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _usernameController.text = widget.existing!['username'] ?? '';
      // Assume che le zone siano disponibili come lista di ID nell’utente
      selectedZoneIds = Set<int>.from(widget.existing!['zone_ids'] ?? []);
    }
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      final response = await dio.get('/zones');
      final zones = List<Map<String, dynamic>>.from(response.data);

      // Per ciascuna zona, puoi opzionalmente verificare se ha utenti
      // ma NON è obbligatorio per mostrare la lista di zone
      setState(() {
        allZones = zones.where((z) => z.containsKey('id') && z.containsKey('name')).toList();
      });

    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Backend ha risposto 404: zone non trovate, o senza utenti → continua comunque
        setState(() {
          allZones = []; // o [] se vuoi mostrare che non ce ne sono
          error = "⚠️ No zones found.";
        });
      } else {
        setState(() => error = '❌ Failed to load zones');
      }
    } catch (e) {
      setState(() => error = '❌ Unexpected error while loading zones');
    }
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final zones = selectedZoneIds.toList();

    if (username.isEmpty) {
      setState(() => error = "❗ Username is required.");
      return;
    }
    if (!isEdit && password.length < 6) {
      setState(() => error = "❗ Password must be at least 6 characters.");
      return;
    }
    if (zones.isEmpty) {
      setState(() => error = "❗ Select at least one zone.");
      return;
    }

    setState(() => loading = true);

    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final email = "$timestamp@gmail.com";

      final data = {
        "name": "Controller",
        "surname": "Controller",
        "email": email,
        "username": username,
        "role": "controller",
        if (!isEdit) "password": password,
      };

      if (isEdit) {
        // PATCH su utente esistente
        await dio.patch("/users/${widget.existing!['id']}", data: data);
      } else {
        // STEP 1: Registrazione utente
        await dio.post("/register", data: data);

        // STEP 2: Assegnazione zone
        for (final zid in zones) {
          await dio.post("/zones/$zid/users", data: {
            "username": username,
            "role": "controller",
          });
        }
      }

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => error = "❌ Failed to ${isEdit ? 'update' : 'create'} controller.");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? "Edit Controller" : "Add Controller"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            if (!isEdit)
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
            const SizedBox(height: 12),
            Text("Assign zones:", style: TextStyle(fontWeight: FontWeight.bold)),
            if (allZones.isEmpty)
              Text("No zones found.")
            else
              ...allZones.map((zone) {
                return CheckboxListTile(
                  title: Text(zone['name'] ?? 'Unnamed zone'),
                  value: selectedZoneIds.contains(zone['id']),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedZoneIds.add(zone['id']);
                      } else {
                        selectedZoneIds.remove(zone['id']);
                      }
                    });
                  },
                );
              }),
            if (error != null) ...[
              SizedBox(height: 12),
              Text(error!, style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
        ElevatedButton(
          onPressed: loading ? null : _submit,
          child: Text(isEdit ? "Save Changes" : "Create"),
        ),
      ],
    );
  }
}
