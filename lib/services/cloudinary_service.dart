import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../utils/constants.dart';

class CloudinaryService {
  final String cloudName = kCloudName;           // replace in constants.dart
  final String unsignedPreset = kUnsignedPreset; // replace in constants.dart

  Future<Map<String, dynamic>?> uploadVideo(File file) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = unsignedPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path,
          filename: p.basename(file.path)));
    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      // You can log resp.body for debugging
      return null;
    }
  }
}
