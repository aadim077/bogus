import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

// Color palette from your other code
const Color primaryColor = Color(0xFF283B54);
const Color accentColor = Color(0xFF0096A6);
const Color textColor = Colors.white;
const Color cardColor = Color(0xFF3B4E66);

class ProfileScreen extends StatelessWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final doc = await FirebaseFirestore.instance.collection("users").doc(userId).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: primaryColor, // Set the background color
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: textColor)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserProfile(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentColor));
          }
          final userData = snap.data ?? {};
          final username = userData['username'] ?? 'user';
          final bio = userData['bio'] ?? 'No bio yet';
          final photoUrl = userData['photoUrl'];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Profile Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: accentColor,
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null ? const Icon(Icons.person, size: 40, color: primaryColor) : null,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "@$username",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          Text(bio, style: TextStyle(color: textColor.withOpacity(0.7))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => auth.signOut(),
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Sign out', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(
                                userId: userId,
                                currentData: userData,
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: cardColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Edit Profile", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 🔹 Uploaded Videos
                Text("My Uploads", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection("videos")
                      .where("userId", isEqualTo: userId)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const LinearProgressIndicator(color: accentColor);
                    final videos = snap.data!.docs;
                    if (videos.isEmpty) return Text("No uploads yet.", style: TextStyle(color: textColor.withOpacity(0.7)));
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: videos.length,
                      itemBuilder: (context, i) {
                        final data = videos[i].data();
                        return _buildVideoListTile(
                          icon: Icons.play_circle_fill,
                          title: data['caption'] ?? '',
                          subtitle: "Uploaded by @$username",
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 🔹 Liked Videos
                Text("Liked Videos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection("videos")
                      .where("likes", arrayContains: userId)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const LinearProgressIndicator(color: accentColor);
                    final liked = snap.data!.docs;
                    if (liked.isEmpty) return Text("No liked videos yet.", style: TextStyle(color: textColor.withOpacity(0.7)));
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: liked.length,
                      itemBuilder: (context, i) {
                        final data = liked[i].data();
                        return _buildVideoListTile(
                          icon: Icons.favorite,
                          iconColor: Colors.red,
                          title: data['caption'] ?? '',
                          subtitle: "By @${data['username'] ?? 'user'}",
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 🔹 Saved Videos
                Text("Saved Videos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance.collection("users").doc(userId).get(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const LinearProgressIndicator(color: accentColor);
                    final saved = List<String>.from(snap.data?.data()?['savedVideos'] ?? []);
                    if (saved.isEmpty) return Text("No saved videos yet.", style: TextStyle(color: textColor.withOpacity(0.7)));
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: saved.map((id) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text("• $id", style: const TextStyle(color: textColor)),
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = textColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.7))),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> currentData;

  const EditProfileScreen({super.key, required this.userId, required this.currentData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameC = TextEditingController();
  final _bioC = TextEditingController(); // Added bio controller
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _usernameC.text = widget.currentData['username'] ?? '';
    _bioC.text = widget.currentData['bio'] ?? '';
  }

  Future<void> _saveChanges() async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection("users").doc(widget.userId).update({
        'username': _usernameC.text.trim(),
        'bio': _bioC.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated ", style: TextStyle(color: primaryColor)), backgroundColor: accentColor),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _changePassword() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password reset email sent ", style: TextStyle(color: primaryColor)), backgroundColor: accentColor),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: textColor)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            _buildTextField(
              controller: _usernameC,
              label: "Username",
              icon: Icons.person,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _bioC,
              label: "Bio",
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _saveChanges,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)) : const Icon(Icons.save, color: primaryColor),
                label: const Text("Save Changes", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _changePassword,
                style: FilledButton.styleFrom(
                  backgroundColor: cardColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.lock_reset, color: textColor),
                label: const Text("Change Password", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper method to build a consistent text field (copied from LoginScreen)
Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool obscureText = false,
  String? Function(String?)? validator,
  int? maxLines = 1,
}) {
  return Container(
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: TextFormField(
      controller: controller,
      style: const TextStyle(color: textColor),
      obscureText: obscureText,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: Icon(icon, color: textColor.withOpacity(0.7)),
      ),
    ),
  );
}