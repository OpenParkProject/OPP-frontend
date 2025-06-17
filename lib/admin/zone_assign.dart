import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/client.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class ZoneEditDialog extends StatefulWidget {
  final String username;
  final String role;
  final List<int> currentZoneIds;

  const ZoneEditDialog({
    super.key,
    required this.username,
    required this.role,
    required this.currentZoneIds,
  });

  @override
  State<ZoneEditDialog> createState() => _ZoneEditDialogState();
}

class _ZoneEditDialogState extends State<ZoneEditDialog> {
  List<String> allZoneIds = [];
  List<String> allZoneNames = [];
  Set<String> selectedIds = {};
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    final prefs = await SharedPreferences.getInstance();
    allZoneIds = prefs.getStringList('zone_ids') ?? [];
    allZoneNames = prefs.getStringList('zone_names') ?? [];
    selectedIds = widget.currentZoneIds.map((id) => id.toString()).toSet();
    setState(() {
      loading = false;
    });
  }

  Future<void> _submit() async {
    if (selectedIds.isEmpty) {
      setState(() {
        error = "❗ At least one zone must be assigned.\nConsider deleting this user instead.";
      });
      return;
    }

    await DioClient().setAuthToken();
    final dio = DioClient().dio;

    final current = widget.currentZoneIds.map((e) => e.toString()).toSet();
    final added = selectedIds.difference(current);
    final removed = current.difference(selectedIds);

    for (final id in added) {
      await dio.post("/zones/$id/users", data: {
        "username": widget.username,
        "role": widget.role,
      });
    }

    for (final id in removed) {
      await dio.delete("/zones/$id/users/${widget.username}");
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit ${widget.role.capitalize()}"),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      content: loading
          ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Assign zones:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (allZoneIds.isEmpty)
                    Text("No zones found.")
                  else
                    ...List.generate(allZoneIds.length, (index) {
                      final id = allZoneIds[index];
                      final name = allZoneNames.length > index ? allZoneNames[index] : "Unnamed";
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text("Zone $id - $name"),
                        value: selectedIds.contains(id),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              selectedIds.add(id);
                            } else {
                              selectedIds.remove(id);
                            }
                          });
                        },
                      );
                    }),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: loading ? null : _submit,
          child: const Text("Save"),
        ),
      ],
    );
  }
}
