import 'package:flutter/material.dart';
import 'package:math_scanner/screens/camera_screen.dart';
import 'package:math_scanner/screens/manual_input_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:math_scanner/screens/result_screen.dart';
import 'package:math_scanner/services/text_recognition_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Scanner'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose Input Method',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildOptionCard(
              context,
              'Scan with Camera',
              Icons.camera_alt,
              Colors.blue,
              () => _navigateToCameraScreen(context),
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              context,
              'Upload Image',
              Icons.photo_library,
              Colors.green,
              () => _pickImageFromGallery(context),
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              context,
              'Manual Input',
              Icons.keyboard,
              Colors.orange,
              () => _navigateToManualInputScreen(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 50,
                color: color,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCameraScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );
  }

  void _navigateToManualInputScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManualInputScreen(),
      ),
    );
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null && context.mounted) {
      final TextRecognitionService recognitionService = TextRecognitionService();
      final String recognizedText = await recognitionService.recognizeTextFromPath(image.path);
      
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              mathProblem: recognizedText,
              imageSource: image.path,
            ),
          ),
        );
      }
    }
  }
}
