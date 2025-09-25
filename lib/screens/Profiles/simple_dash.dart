import 'package:flutter/material.dart';
import 'package:event_manager_local/services/organiser_service.dart';

class SimpleDash extends StatefulWidget {
  const SimpleDash({super.key});

  @override
  State<SimpleDash> createState() => _SimpleDashState();
}

class _SimpleDashState extends State<SimpleDash> {
  final OrganiserService _service = OrganiserService();
  bool _loading = true;

  int _totalEvents = 0;
  int _totalRegistrations = 0;
  int _totalCheckIns = 0;
  double _totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _loading = true);

    final events = await _service.getOrganiserEvents();
    final registrations = await _service.getTotalRegistrations();
    final checkIns = await _service.getTotalCheckins();
    final revenue = await _service.getTotalRevenue();

    setState(() {
      _totalEvents = events.length;
      _totalRegistrations = registrations;
      _totalCheckIns = checkIns;
      _totalRevenue = revenue;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // First Row
          Row(
            children: [
              _buildDashCard("Total Events", "$_totalEvents", Colors.blue),
              const SizedBox(width: 16),
              _buildDashCard(
                "Total Registrations",
                "$_totalRegistrations",
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Second Row
          Row(
            children: [
              _buildDashCard(
                "Total Revenue",
                "\$${_totalRevenue.toStringAsFixed(2)}",
                Colors.orange,
              ),
              const SizedBox(width: 16),
              _buildDashCard(
                "Total CheckIns",
                "$_totalCheckIns",
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Reusable card widget for dashboard items
  Widget _buildDashCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
