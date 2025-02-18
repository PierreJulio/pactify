import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageService {
  static const String apiKey = 'afbf9a190f8bae413989d9841c02d7b8';
  static const String apiUrl = 'https://api.imgbb.com/1/upload';
  final ImagePicker _picker = ImagePicker();

  Future<String?> uploadImage() async {
    try {
      // Utilisez XFile au lieu de File pour la compatibilité web
      final XFile? image = await _picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 70,
      );

      if (image == null) return null;

      // Lire les bytes de l'image
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Upload vers ImgBB
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        body: {
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['url'] as String;
        } else {
          throw 'Failed to upload image: ${data['error']['message']}';
        }
      } else {
        throw 'Failed to upload image: ${response.statusCode}';
      }
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }
}
