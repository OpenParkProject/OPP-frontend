import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:openpark/API/client.dart';

class SuperuserStatisticsPage extends StatefulWidget {
  const SuperuserStatisticsPage({super.key});

  @override
  State<SuperuserStatisticsPage> createState() => _SuperuserStatisticsPageState();
}

class _SuperuserStatisticsPageState extends State<SuperuserStatisticsPage> {
  bool loading = true;
  String? error;

  int totalUsers = 0;
  Map<String, int> usersByRole = {};

  int totalTickets = 0;
  double totalRevenue = 0;
  double averageTicketPerUser = 0;
  double averageTicketPrice = 0;

  int totalFines = 0;
  double totalFinesAmount = 0;
  double percentFinesPaid = 0;

  final Map<String, Color> roleColors = {
    "superuser": Colors.deepPurple,
    "admin": Colors.indigo,
    "controller": Colors.teal,
    "driver": Colors.orange,
  };

  final Map<String, int> durationBins = {
    '0–30 min': 0,
    '31–60 min': 0,
    '1–2 h': 0,
    '2–4 h': 0,
    '4–8 h': 0,
    '8+ h': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await DioClient().setAuthToken();
      final usersRes = await DioClient().dio.get("/users");
      final ticketsRes = await DioClient().dio.get("/tickets");
      final finesRes = await DioClient().dio.get("/fines");

      final users = List<Map<String, dynamic>>.from(usersRes.data);
      final tickets = List<Map<String, dynamic>>.from(ticketsRes.data);
      final fines = List<Map<String, dynamic>>.from(finesRes.data);

      final roleCount = <String, int>{};
      for (var u in users) {
        final role = u['role'] ?? 'unknown';
        roleCount[role] = (roleCount[role] ?? 0) + 1;
      }

      final revenue = tickets.fold(0.0, (sum, t) => sum + (t['price'] ?? 0.0));
      final double avgPerUser = users.isEmpty ? 0 : tickets.length / users.length;
      final double avgPrice = tickets.isEmpty ? 0 : revenue / tickets.length;

      final finesAmount = fines.fold(0.0, (sum, f) => sum + (f['amount'] ?? 0.0));
      final finesPaid = fines.where((f) => f['paid'] == true).length;
      final double percentPaid = fines.isEmpty ? 0 : (finesPaid / fines.length) * 100;

      // Clear previous bin data
      durationBins.updateAll((key, value) => 0);

      for (var t in tickets) {
        try {
          final start = DateTime.parse(t['start_date']);
          final end = DateTime.parse(t['end_date']);
          final minutes = end.difference(start).inMinutes;
          if (minutes <= 30) durationBins['0–30 min'] = durationBins['0–30 min']! + 1;
          else if (minutes <= 60) durationBins['31–60 min'] = durationBins['31–60 min']! + 1;
          else if (minutes <= 120) durationBins['1–2 h'] = durationBins['1–2 h']! + 1;
          else if (minutes <= 240) durationBins['2–4 h'] = durationBins['2–4 h']! + 1;
          else if (minutes <= 480) durationBins['4–8 h'] = durationBins['4–8 h']! + 1;
          else durationBins['8+ h'] = durationBins['8+ h']! + 1;
        } catch (_) {}
      }

      setState(() {
        totalUsers = users.length;
        usersByRole = roleCount;
        totalTickets = tickets.length;
        totalRevenue = revenue;
        averageTicketPerUser = avgPerUser;
        averageTicketPrice = avgPrice;
        totalFines = fines.length;
        totalFinesAmount = finesAmount;
        percentFinesPaid = percentPaid;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = "Failed to fetch statistics: $e";
        loading = false;
      });
    }
  }

  List<PieChartSectionData> _buildPieSections() {
    final total = usersByRole.values.fold(0, (sum, val) => sum + val);
    return usersByRole.entries.map((e) {
      final percent = total == 0 ? 0.0 : (e.value / total) * 100;
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: roleColors[e.key] ?? Colors.grey,
        title: "${e.key[0].toUpperCase()}${e.key.substring(1)}\n${percent.toStringAsFixed(1)}%",
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  List<BarChartGroupData> _buildDurationHistogram() {
    int x = 0;
    return durationBins.entries.map((e) {
      return BarChartGroupData(
        x: x++,
        barRods: [
          BarChartRodData(
            toY: e.value.toDouble(),
            color: Colors.blue,
            width: 20,
          )
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text(error!));

    final binLabels = durationBins.keys.toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text("📊 System Statistics", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          _buildSectionDivider("📋 Overview"),
          _buildCard([
            _buildStatRow("👥 Total Users", "$totalUsers"),
            _buildStatRow("🎫 Total Tickets", "$totalTickets"),
            _buildStatRow("💶 Total Revenue", "${totalRevenue.toStringAsFixed(2)} €"),
            _buildStatRow("📈 Avg Tickets/User", averageTicketPerUser.toStringAsFixed(2)),
            _buildStatRow("🧾 Avg Ticket Price", "${averageTicketPrice.toStringAsFixed(2)} €"),
          ]),

          _buildSectionDivider("🧩 Users by Role"),
          SizedBox(
            height: 250,
            child: PieChart(PieChartData(
              sections: _buildPieSections(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            )),
          ),
          const SizedBox(height: 12),
          _buildCard(usersByRole.entries.map((e) {
            final percent = (e.value / totalUsers) * 100;
            return _buildStatRow("${e.key[0].toUpperCase()}${e.key.substring(1)}", "${e.value} (${percent.toStringAsFixed(1)}%)");
          }).toList()),

          _buildSectionDivider("⏱ Ticket Duration Distribution"),
          SizedBox(
            height: 250,
            child: BarChart(BarChartData(
              barGroups: _buildDurationHistogram(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < binLabels.length) {
                        return Transform.translate(
                          offset: const Offset(-10, 5),
                          child: Text(binLabels[value.toInt()], style: const TextStyle(fontSize: 10)),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
            )),
          ),

          _buildSectionDivider("🚨 Fines"),
          _buildCard([
            _buildStatRow("📄 Total Fines", "$totalFines"),
            _buildStatRow("💰 Total Fines Amount", "${totalFinesAmount.toStringAsFixed(2)} €"),
            _buildStatRow("✅ % Fines Paid", "${percentFinesPaid.toStringAsFixed(1)}%"),
          ]),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        const Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const Expanded(child: Divider(thickness: 1)),
      ]),
    );
  }
}
