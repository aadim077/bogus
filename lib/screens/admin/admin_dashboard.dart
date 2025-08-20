import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import '../../../services/firestore_service.dart';

// Color palette from other screens
const Color primaryColor = Color(0xFF283B54);
const Color accentColor = Color(0xFF0096A6);
const Color textColor = Colors.white;
const Color cardColor = Color(0xFF3B4E66);

// A simple widget to simulate a pie chart
class CustomPieChart extends StatelessWidget {
  const CustomPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [

                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),

                CustomPaint(
                  size: const Size(150, 150),
                  painter: _PieChartPainter(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(color: Colors.lightGreenAccent, label: "Users"),
              _buildLegendItem(color: Colors.redAccent, label: "Videos"),
              _buildLegendItem(color: Colors.yellowAccent, label: "Likes"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: textColor, fontSize: 12),
        ),
      ],
    );
  }
}

// Custom painter for pei chart
class _PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Data
    const double usersAngle = 2.5 * pi / 2;
    const double videosAngle = pi / 2;
    const double likesAngle = pi / 2;

    // Draw Users slice
    final usersPaint = Paint()..color = Colors.lightGreenAccent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      usersAngle,
      true,
      usersPaint,
    );

    // Draw Videos slice
    final videosPaint = Paint()..color = Colors.redAccent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      usersAngle,
      videosAngle,
      true,
      videosPaint,
    );

    // Draw Likes slice
    final likesPaint = Paint()..color = Colors.yellowAccent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      usersAngle + videosAngle,
      likesAngle,
      true,
      likesPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(color: textColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: textColor),
            tooltip: "Sign Out",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed("/login");
              }
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([_fs.allUsers(), _fs.allVideos()]),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentColor));
          }
          if (snap.hasError) {
            return Center(
              child: Text("Error: ${snap.error}", style: const TextStyle(color: Colors.red)),
            );
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return const Center(
              child: Text("No data found", style: TextStyle(color: textColor)),
            );
          }

          final usersSnap = (snap.data as List)[0];
          final videosSnap = (snap.data as List)[1];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // PIE CHART
                const CustomPieChart(),
                const SizedBox(height: 16),

                // USERS SECTION
                _buildExpansionCard(
                  title: "Users (${usersSnap.docs.length})",
                  icon: Icons.people,
                  children: usersSnap.docs.map<Widget>((d) {
                    final data = d.data();
                    return ListTile(
                      leading: const Icon(Icons.person, color: accentColor),
                      title: Text(data["email"] ?? "No email", style: const TextStyle(color: textColor)),
                      subtitle: Text("ID: ${d.id}", style: TextStyle(color: textColor.withOpacity(0.7))),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _fs.deleteUserDoc(d.id);
                          setState(() {});
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // VIDEOS SECTION
                _buildExpansionCard(
                  title: "Videos (${videosSnap.docs.length})",
                  icon: Icons.video_library,
                  children: videosSnap.docs.map<Widget>((d) {
                    final data = d.data();
                    return ListTile(
                      leading: const Icon(Icons.play_circle_fill, color: accentColor),
                      title: Text(data["title"] ?? "Untitled", style: const TextStyle(color: textColor)),
                      subtitle: Text("Uploader: ${data["userId"] ?? ''}", style: TextStyle(color: textColor.withOpacity(0.7))),
                      // Removed the delete button as requested
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to create consistent expansion tiles
  Widget _buildExpansionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: ExpansionTile(
        leading: Icon(icon, color: accentColor),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor,
          ),
        ),
        collapsedIconColor: textColor,
        iconColor: accentColor,
        children: children,
      ),
    );
  }
}