import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Ensure this is added to pubspec.yaml
import 'create_official_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Soft professional grey
      appBar: AppBar(
        title: const Text("ADMIN PORTAL",
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("System Overview"),
            const SizedBox(height: 16),
            _buildQuickStats(),

            const SizedBox(height: 32),
            _buildSectionHeader("Official Distribution"),
            const SizedBox(height: 16),
            _buildOfficialPieChart(),

            const SizedBox(height: 40),
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.indigo.shade900,
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        int totalDocs = snapshot.data!.docs.length;
        int officials = snapshot.data!.docs.where((d) =>
        (d.data() as Map<String, dynamic>)['role'] == 'OFFICIAL').length;
        int citizens = totalDocs - officials-1;

        return Row(
          children: [
            _statCard("Citizens", citizens.toString(), Icons.people_alt_rounded, Colors.blue),
            const SizedBox(width: 16),
            _statCard("Officials", officials.toString(), Icons.admin_panel_settings, Colors.orange.shade700),
          ],
        );
      },
    );
  }

  Widget _buildOfficialPieChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: 'OFFICIAL')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs;
        int aeCount = docs.where((d) => (d.data() as Map)['officialRole'] == 'AE').length;
        int aeeCount = docs.where((d) => (d.data() as Map)['officialRole'] == 'AEE').length;
        int eeCount = docs.where((d) => (d.data() as Map)['officialRole'] == 'EE').length;
        int total = docs.length;

        if (total == 0) {
          return _emptyStateCard("No Officials Registered Yet");
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 5,
                    centerSpaceRadius: 60,
                    sections: [
                      _sectionData(aeCount.toDouble(), Colors.tealAccent.shade700, "AE"),
                      _sectionData(aeeCount.toDouble(), Colors.orangeAccent.shade700, "AEE"),
                      _sectionData(eeCount.toDouble(), Colors.indigoAccent, "EE"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _legendItem("AE", aeCount, Colors.tealAccent.shade700),
                  _legendItem("AEE", aeeCount, Colors.orangeAccent.shade700),
                  _legendItem("EE", eeCount, Colors.indigoAccent),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CreateOfficialScreen())),
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text("REGISTER NEW OFFICER",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 60),
            backgroundColor: Colors.indigo.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }

  // --- HELPER METHODS ---

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _sectionData(double value, Color color, String title) {
    return PieChartSectionData(
      color: color,
      value: value,
      title: value > 0 ? '${value.toInt()}' : '',
      radius: 30,
      titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _legendItem(String name, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(name, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text("$count Staff", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _emptyStateCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 50, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}