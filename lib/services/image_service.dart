import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class ImageService {
  static const String apiKey = 'afbf9a190f8bae413989d9841c02d7b8';
  static const String apiUrl = 'https://api.imgbb.com/1/upload';
  final ImagePicker _picker = ImagePicker();

  Future<String?> uploadImage(BuildContext context) async {
    try {
      // Afficher le bottom sheet pour la sélection
      final ImageSource? source = await showModalBottomSheet<ImageSource?>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ajouter une preuve',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildOptionTile(
                  context,
                  'Prendre une photo',
                  Icons.camera_alt_outlined,
                  () => Navigator.pop(context, ImageSource.camera),
                ),
                _buildOptionTile(
                  context,
                  'Choisir depuis la galerie',
                  Icons.photo_library_outlined,
                  () => Navigator.pop(context, ImageSource.gallery),
                ),
                _buildSkipOptionTile(
                  context,
                  'Ne pas ajouter de preuve',
                  Icons.not_interested,
                  () => Navigator.pop(context, null),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );

      if (source == null) {
        // L'utilisateur a choisi de ne pas ajouter de preuve
        return 'no_proof';
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image == null) return null;

      // Afficher un indicateur de chargement
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        body: {
          'image': base64Image,
        },
      );

      // Fermer l'indicateur de chargement
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['url'] as String;
        }
      }
      throw 'Failed to upload image';
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Widget _buildOptionTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(title),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }

  Widget _buildSkipOptionTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        const Divider(),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        ),
      ],
    );
  }
}
