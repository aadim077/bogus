import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../services/firestore_service.dart';
import '../../utils/constants.dart';

// Color palette from other screens
const Color primaryColor = Color(0xFF283B54);
const Color accentColor = Color(0xFF0096A6);
const Color textColor = Colors.white;
const Color cardColor = Color(0xFF3B4E66);

class UploadScreen extends StatefulWidget {
  final String userId;
  const UploadScreen({required this.userId, super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _videoFile;
  final _picker = ImagePicker();
  final _titleC = TextEditingController();
  final _captionC = TextEditingController();
  bool _loading = false;

  /// Pick video from gallery
  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _videoFile = File(picked.path));
    }
  }

  /// Upload video to Cloudinary + Firestore
  Future<void> _uploadVideo() async {
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please pick a video first", style: TextStyle(color: primaryColor)),
          backgroundColor: accentColor,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // 🔥 Upload to Cloudinary
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$kCloudName/video/upload");

      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = kUnsignedPreset
        ..files.add(await http.MultipartFile.fromPath("file", _videoFile!.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      print("Cloudinary response: $resBody"); //

      final data = json.decode(resBody);

      if (response.statusCode != 200 || data["secure_url"] == null) {
        throw "Cloudinary upload failed: $resBody";
      }

      final videoUrl = data["secure_url"];
      final publicId = data["public_id"];

      // 🔥 Save metadata to Firestore
      await FirestoreService().uploadVideoMetadata({
        'title': _titleC.text.trim(),
        'caption': _captionC.text.trim(),
        'url': videoUrl,
        'public_id': publicId,
        'userId': widget.userId,
        'likes': [],
        'saves': [],
        'createdAt': FieldValue.serverTimestamp(),
      }, widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Video uploaded ", style: TextStyle(color: primaryColor)),
            backgroundColor: accentColor,
          ),
        );
        setState(() {
          _videoFile = null;
          _titleC.clear();
          _captionC.clear();
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text("Upload Video", style: TextStyle(color: textColor)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: kPad,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _titleC,
                label: 'Title (optional)',
                icon: Icons.title,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _captionC,
                label: 'Caption',
                icon: Icons.description,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _videoFile != null
                        ? " Selected: ${_videoFile!.path.split('/').last}"
                        : "No video selected",
                    style: TextStyle(color: textColor.withOpacity(0.8), fontWeight: FontWeight.bold),
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.video_library, color: primaryColor),
                    label: const Text("Pick Video", style: TextStyle(color: primaryColor)),
                    onPressed: _pickVideo,
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _uploadVideo,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                  )
                      : const Icon(Icons.upload, color: primaryColor),
                  label: _loading
                      ? const Text("Uploading...", style: TextStyle(color: primaryColor))
                      : const Text("Upload", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper method to build a consistent text field
Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool obscureText = false,
  String? Function(String?)? validator,
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