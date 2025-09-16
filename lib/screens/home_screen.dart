import 'package:flutter/material.dart';
import 'package:math_scanner/screens/camera_screen.dart';
import 'package:math_scanner/screens/manual_input_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:math_scanner/screens/result_screen.dart';
import 'package:math_scanner/services/text_recognition_service.dart';
import 'package:math_scanner/screens/camera_test_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:math_scanner/services/permission_service.dart';
import 'package:math_scanner/screens/camera_permission_guide_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _cameraPermissionDenied = false;
  final PermissionService _permissionService = PermissionService();
  
  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }
  
  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (mounted) {
      setState(() {
        _cameraPermissionDenied = status.isDenied || status.isPermanentlyDenied;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Scanner'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              openAppSettings();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
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
                  const SizedBox(height: 20),
                  _buildOptionCard(
                    context,
                    'Camera Test',
                    Icons.camera_outlined,
                    Colors.purple,
                    () => _navigateToCameraTest(context),
                  ),
                ],
              ),
            ),
          ),
          if (_cameraPermissionDenied)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.black87,
              child: Row(
                children: [
                  const Icon(
                    Icons.no_photography,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Camera permission is required to scan math problems",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CameraPermissionGuideScreen(),
                        ),
                      ).then((_) {
                        // Check permission again after returning from the guide screen
                        if (mounted) {
                          Future.delayed(const Duration(seconds: 1), () {
                            _checkCameraPermission();
                          });
                        }
                      });
                    },
                    child: const Text(
                      "Help",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await openAppSettings();
                      // Check permission again after returning from settings
                      if (mounted) {
                        Future.delayed(const Duration(seconds: 1), () {
                          _checkCameraPermission();
                        });
                      }
                    },
                    child: const Text(
                      "Settings",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
        ],
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

  void _navigateToCameraTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraTestPage(),
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
