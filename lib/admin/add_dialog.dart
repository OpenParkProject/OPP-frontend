import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../API/client.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class AddEditDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final String role;
  final bool noZoneAssignment;
  final void Function(String username, String password)? onCredentialsSaved;

  const AddEditDialog({
    this.existing,
    required this.role,
    this.noZoneAssignment = false,
    this.onCredentialsSaved,
    super.key,
  });

  @override
  State<AddEditDialog> createState() => _AddEditDialogState();
}

class _AddEditDialogState extends State<AddEditDialog> {
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
      selectedZoneIds = Set<int>.from(widget.existing!['zone_ids'] ?? []);
    }
    if (!widget.noZoneAssignment) {
      _loadZones();
    }
  }

  Future<void> _loadZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final zoneIds = prefs.getStringList("zone_ids") ?? [];
      final zoneNames = prefs.getStringList("zone_names") ?? [];

      if (zoneIds.length != zoneNames.length) {
        setState(() => error = "⚠️ Zone data mismatch.");
        return;
      }

      setState(() {
        allZones = List.generate(zoneIds.length, (i) {
          return {
            'id': int.tryParse(zoneIds[i]),
            'name': zoneNames[i],
          };
        });
      });
    } catch (e) {
      setState(() => error = '❌ Failed to load assigned zones from storage');
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
    if (!widget.noZoneAssignment && zones.isEmpty) {
      setState(() => error = "❗ Select at least one zone.");
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      Map<String, dynamic>? existingUser;
      bool userExists = false;

      // Check se l'utente esiste già
      try {
        final res = await dio.get("/users/$username");
        existingUser = Map<String, dynamic>.from(res.data);
        userExists = true;

        if (existingUser['role'] != widget.role) {
          setState(() {
            error = "❌ User '$username' already exists with role '${existingUser!['role']}' "
                    "and cannot be assigned as '${widget.role}'.";
          });
          await Future.delayed(Duration(seconds: 2));
          setState(() => loading = false);
          return;
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          userExists = false; // utente non trovato: ok, va creato
        } else {
          setState(() => error = "❌ Failed to check existing user.");
          await Future.delayed(Duration(seconds: 2));
          setState(() => loading = false);
          return;
        }
      }

      // Se non esiste, lo creiamo
      if (!userExists) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final email = "$timestamp@gmail.com";
        final data = {
          "name": widget.role.capitalize(),
          "surname": widget.role.capitalize(),
          "email": email,
          "username": username,
          "role": widget.role,
          "password": password,
        };

        try {
          await dio.post("/register", data: data);
          widget.onCredentialsSaved?.call(username, password);
        } on DioException catch (e) {
          setState(() => error = "❌ Failed to create user.");
          await Future.delayed(Duration(seconds: 2));
          setState(() => loading = false);
          return;
        }
      }

      // Assegna le zone solo se non già assegnate
      if (!widget.noZoneAssignment) {
        for (final zid in zones) {
          try {
            final res = await dio.get("/zones/$zid/users");
            final existingUsers = List<Map<String, dynamic>>.from(res.data);
            final alreadyAssigned = existingUsers.any(
              (u) => u['username'].toString().toLowerCase() == username.toLowerCase(),
            );

            if (!alreadyAssigned) {
              await dio.post("/zones/$zid/users", data: {
                "username": username,
                "role": widget.role,
              });
            }
          } catch (e) {
            setState(() => error = "❌ Failed to assign zone ID $zid.");
            await Future.delayed(Duration(seconds: 2));
            setState(() => loading = false);
            return;
          }
        }
      }

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => error = "❌ Unexpected error.");
      await Future.delayed(Duration(seconds: 2));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit
          ? "Edit ${widget.role.capitalize()}"
          : "Add ${widget.role.capitalize()}"),
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

            if (!widget.noZoneAssignment) ...[
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
            ],

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
