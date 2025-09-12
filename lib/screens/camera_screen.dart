import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:math_scanner/screens/result_screen.dart';
import 'package:math_scanner/services/text_recognition_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessingImage = false;
  final TextRecognitionService _textRecognitionService = TextRecognitionService();

  @override
  void initState() {
    super.initState();
    // Delay permission request to avoid context issues
    Future.delayed(Duration.zero, () {
      _requestCameraPermission();
    });
  }

  Future<void> _requestCameraPermission() async {
    // First check current status
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      // Already has permission, initialize camera
      _initializeCamera();
    } else if (status.isDenied) {
      // Request permission if denied
      final result = await Permission.camera.request();
      if (result.isGranted) {
        _initializeCamera();
      } else {
        _showPermissionDeniedMessage();
      }
    } else if (status.isPermanentlyDenied) {
      // Show dialog to open settings
      if (mounted) {
        _showOpenSettingsDialog();
      }
    } else {
      // Handle other states
      _initializeCamera();
    }
  }
  
  void _showPermissionDeniedMessage() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera permission is required to scan math problems'),
        duration: Duration(seconds: 3),
      ),
    );
    Navigator.pop(context);
  }
  
  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
            'Camera permission is needed to scan math problems. Please open settings and enable camera access.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras[0],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No cameras found on your device'),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing camera: $e'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessingImage) {
      return;
    }

    setState(() {
      _isProcessingImage = true;
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      final String recognizedText = await _textRecognitionService.recognizeTextFromPath(photo.path);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              mathProblem: recognizedText,
              imageSource: photo.path,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Math Problem'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isCameraInitialized
                ? CameraPreview(_cameraController!)
                : const Center(child: CircularProgressIndicator()),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(15),
                  ),
                  child: const Icon(Icons.arrow_back, size: 30),
                ),
                ElevatedButton(
                  onPressed: _isProcessingImage ? null : _takePicture,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.white,
                  ),
                  child: _isProcessingImage
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.camera_alt, size: 40, color: Colors.black),
                ),
                const SizedBox(width: 60), // Placeholder for symmetry
              ],
            ),
          ),
        ],
      ),
    );
  }
}
