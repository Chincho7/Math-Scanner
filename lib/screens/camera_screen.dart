import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:math_scanner/screens/modern_result_screen.dart';
import 'package:math_scanner/screens/chatgpt_calculator_screen.dart';
import 'package:math_scanner/services/text_recognition_service.dart';
import 'package:math_scanner/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessingImage = false;
  String _status = 'Requesting permission';
  Timer? _watchdogTimer;
  bool _didAttemptFallback = false;
  FlashMode _flashMode = FlashMode.off; // Flash mode state
  final TextRecognitionService _textRecognitionService = TextRecognitionService();
  final PermissionService _permissionService = PermissionService();

  @override
  void initState() {
    super.initState();
    // Defer camera permission request to avoid blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestCameraPermission();
      _startWatchdog();
    });
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !_isCameraInitialized) {
        debugPrint('[CAMERA] Watchdog fired – attempting fallback');
        _emergencyFallbackInit();
      }
    });
  }

  Future<void> _emergencyFallbackInit() async {
    try {
      if (!_didAttemptFallback) {
        _didAttemptFallback = true;
        if (mounted) setState(() { _status = 'Attempting emergency fallback'; });
        
        _cameras = await availableCameras();
        if (_cameras.isEmpty) {
          throw Exception('No cameras available');
        }
        
        final camera = _cameras.first;
        await _cameraController?.dispose();

        // Emergency fallback with minimal settings
        _cameraController = CameraController(
          camera,
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _status = 'Ready (Fallback)';
          });
          print('[CAMERA] Fallback succeeded');
        }
      }
    } catch (e) {
      print('[CAMERA] Emergency fallback failed: $e');
      if (mounted) {
        setState(() {
          _status = 'Fallback failed: $e';
        });
      }
    }
  }

  Future<void> _requestCameraPermission() async {
    print('[CAMERA] Starting permission request');
    
    try {
      if (Platform.isIOS) {
        print('[CAMERA] iOS detected, forcing permission registration');
        await _permissionService.forceIOSCameraPermissionRegistration();
      }

      final permissionStatus = await Permission.camera.request();
      print('[CAMERA] Permission status: $permissionStatus');

      if (permissionStatus == PermissionStatus.granted) {
        print('[CAMERA] Permission granted, initializing camera');
        _initializeCamera();
      } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
        if (mounted) {
          _showPermissionDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to scan math problems'),
              duration: Duration(seconds: 3),
            ),
          );
          if (mounted) Navigator.pop(context);
        }
      }
    } catch (e) {
      print('[CAMERA] Permission request failed: $e');
      if (mounted) {
        setState(() {
          _status = 'Permission failed: $e';
        });
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
            'This app needs camera access to scan math problems. Please enable camera permission in Settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Exit camera screen
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _initializeCamera() async {
    print('[CAMERA] Starting camera initialization');
    
    try {
      setState(() { _status = 'Initializing camera'; });
      
      _cameras = await availableCameras();
      print('[CAMERA] Found ${_cameras.length} cameras');
      
      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Find the back camera, or use the first available
      CameraDescription? backCamera;
      try {
        backCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
        );
      } catch (e) {
        backCamera = _cameras.first;
      }

      await _cameraController?.dispose();

      // Try with optimized settings first
      try {
        await _initializeCameraWithFallbacks(backCamera);
      } catch (e) {
        print('[CAMERA] Optimized initialization failed, using simple approach: $e');
        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() { _isCameraInitialized = true; _status = 'Ready'; });
        }
      }

      _watchdogTimer?.cancel();
      print('[CAMERA] Initialization completed successfully');

    } catch (e) {
      print('[CAMERA] Camera initialization failed: $e');
      if (mounted) {
        setState(() { _status = 'Initialization failed: $e'; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera initialization failed: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _initializeCameraWithFallbacks(CameraDescription camera) async {
    // Optimize camera settings specifically for OCR and text recognition
    final configs = [
      {'resolution': ResolutionPreset.ultraHigh, 'format': ImageFormatGroup.jpeg}, // Ultra high for best OCR
      {'resolution': ResolutionPreset.veryHigh, 'format': ImageFormatGroup.jpeg}, // Very high quality
      {'resolution': ResolutionPreset.high, 'format': ImageFormatGroup.jpeg}, // High quality
      {'resolution': ResolutionPreset.medium, 'format': ImageFormatGroup.jpeg}, // Good balance
      {'resolution': ResolutionPreset.medium, 'format': ImageFormatGroup.yuv420},
      {'resolution': ResolutionPreset.medium, 'format': ImageFormatGroup.bgra8888},
      {'resolution': ResolutionPreset.low, 'format': ImageFormatGroup.jpeg}, // Last resort
    ];

    for (int i = 0; i < configs.length; i++) {
      final config = configs[i];
      final attemptIndex = i + 1;
      
      try {
        if (_cameraController != null) {
          await _cameraController!.dispose();
        }

        if (mounted) setState(() { _status = 'Optimizing Camera $attemptIndex'; });
        
        _cameraController = CameraController(
          camera,
          config['resolution'] as ResolutionPreset,
          enableAudio: false,
          imageFormatGroup: config['format'] as ImageFormatGroup,
        );

        _cameraController!.addListener(() {
          if (_cameraController!.value.hasError && mounted) {
            print('[CAMERA] Error: ${_cameraController!.value.errorDescription}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Camera error: ${_cameraController!.value.errorDescription}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });

        await _cameraController!.initialize().timeout(
          const Duration(seconds: 10), // Increased timeout for higher quality
          onTimeout: () {
            throw TimeoutException('Camera initialization timeout', const Duration(seconds: 10));
          },
        );

        // Set additional camera parameters for better OCR
        try {
          if (_cameraController!.value.isInitialized) {
            // Set autofocus mode for better text recognition
            await _cameraController!.setFocusMode(FocusMode.auto);
            
            // Set exposure mode for consistent lighting
            await _cameraController!.setExposureMode(ExposureMode.auto);
            
            print('[CAMERA] Camera optimized with ${config['resolution']} resolution and ${config['format']} format');
          }
        } catch (optimizeError) {
          print('[CAMERA] Warning: Could not optimize camera settings: $optimizeError');
          // Continue anyway, basic camera works
        }

        if (mounted) {
          setState(() { _isCameraInitialized = true; _status = 'Camera Ready (Optimized)'; });
        }
        print('[CAMERA] Success with optimized config $attemptIndex');
        return;

      } catch (e) {
        print('[CAMERA] Config $attemptIndex failed: $e');
        if (i == configs.length - 1) {
          rethrow;
        }
      }
    }
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
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
      // Optimize camera settings before capture for better OCR
      try {
        await _cameraController!.setFlashMode(_flashMode);
        await _cameraController!.setFocusMode(FocusMode.auto);
        await _cameraController!.setExposureMode(ExposureMode.auto);
        
        // Additional optimization for text recognition
        if (Platform.isIOS) {
          // iOS-specific optimizations for better text capture
          await _cameraController!.setExposurePoint(null); // Reset exposure point
          await _cameraController!.setFocusPoint(null); // Reset focus point for center focus
        }
        
        // Longer pause to let autofocus and exposure stabilize for text
        await Future.delayed(const Duration(milliseconds: 800));
        
        print('[CAMERA] Pre-capture optimization completed with flash: $_flashMode');
      } catch (e) {
        print('[CAMERA] Warning: Could not optimize pre-capture settings: $e');
      }

      final XFile photo = await _cameraController!.takePicture();
      print('[CAMERA] Image captured: ${photo.path}');
      
      // Process the text recognition
      final String recognizedText = await _textRecognitionService.recognizeTextFromPath(photo.path);
      print('[CAMERA] Text recognized: "$recognizedText"');

      if (mounted) {
        if (recognizedText.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No math expression detected. Try again with better lighting.'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModernResultScreen(
                mathProblem: recognizedText,
                imageSource: photo.path,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('[CAMERA] Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image. Please try again.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.flashlight_on;
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // Cycle through flash modes: off -> auto -> always -> torch -> off
      FlashMode newFlashMode;
      switch (_flashMode) {
        case FlashMode.off:
          newFlashMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          newFlashMode = FlashMode.always;
          break;
        case FlashMode.always:
          newFlashMode = FlashMode.torch;
          break;
        case FlashMode.torch:
          newFlashMode = FlashMode.off;
          break;
      }

      await _cameraController!.setFlashMode(newFlashMode);
      
      if (mounted) {
        setState(() {
          _flashMode = newFlashMode;
        });
      }
      
      print('[CAMERA] Flash mode changed to: $newFlashMode');
      
      // Show flash mode change notification
      if (mounted) {
        String flashModeText;
        switch (newFlashMode) {
          case FlashMode.off:
            flashModeText = 'Flash Off';
            break;
          case FlashMode.auto:
            flashModeText = 'Flash Auto';
            break;
          case FlashMode.always:
            flashModeText = 'Flash On';
            break;
          case FlashMode.torch:
            flashModeText = 'Flash Torch';
            break;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(flashModeText),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      print('[CAMERA] Error toggling flash: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing flash mode'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview or loading state
          if (_isCameraInitialized && 
              _cameraController != null && 
              _cameraController!.value.isInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),

          // OCR guidance overlay
          if (_isCameraInitialized && 
              _cameraController != null && 
              _cameraController!.value.isInitialized)
            Positioned.fill(
              child: CustomPaint(
                painter: OCRGuidePainter(),
              ),
            ),

          // OCR tips overlay
          if (_isCameraInitialized)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Math Recognition Tips:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Position math clearly in the frame\n• Ensure good lighting\n• Keep numbers and operators distinct\n• Example: 2+9+8 or 15-7',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading state
          if (!_isCameraInitialized)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Top controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  ),
                  const Text(
                    'Math Scanner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: _isCameraInitialized ? _toggleFlash : null,
                    icon: Icon(
                      _getFlashIcon(),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                top: 30,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery button
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),

                  // Capture button
                  GestureDetector(
                    onTap: (_isProcessingImage || !_isCameraInitialized) ? null : _takePicture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isProcessingImage ? Colors.grey : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: _isProcessingImage
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 35,
                            ),
                    ),
                  ),

                  // Calculator button
                  GestureDetector(
                    onTap: () => _showCalculatorModal(context),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.calculate,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null && mounted) {
        setState(() {
          _isProcessingImage = true;
        });

        try {
          final String recognizedText = await _textRecognitionService.recognizeTextFromPath(image.path);

          if (mounted) {
            setState(() {
              _isProcessingImage = false;
            });

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModernResultScreen(
                  mathProblem: recognizedText,
                  imageSource: image.path,
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isProcessingImage = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error processing image: $e'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showCalculatorModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatGPTCalculatorScreen(),
      ),
    );
  }
}

// Custom painter for OCR guidance overlay
class OCRGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashedPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Define the optimal OCR zone (center rectangle)
    final centerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.height * 0.3,
    );

    // Draw main guide rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, const Radius.circular(12)),
      paint,
    );

    // Draw corner indicators
    final cornerLength = 20.0;
    final corners = [
      centerRect.topLeft,
      centerRect.topRight,
      centerRect.bottomLeft,
      centerRect.bottomRight,
    ];

    for (int i = 0; i < corners.length; i++) {
      final corner = corners[i];
      if (i == 0) { // Top-left
        canvas.drawLine(corner, corner + Offset(cornerLength, 0), paint);
        canvas.drawLine(corner, corner + Offset(0, cornerLength), paint);
      } else if (i == 1) { // Top-right
        canvas.drawLine(corner, corner + Offset(-cornerLength, 0), paint);
        canvas.drawLine(corner, corner + Offset(0, cornerLength), paint);
      } else if (i == 2) { // Bottom-left
        canvas.drawLine(corner, corner + Offset(cornerLength, 0), paint);
        canvas.drawLine(corner, corner + Offset(0, -cornerLength), paint);
      } else { // Bottom-right
        canvas.drawLine(corner, corner + Offset(-cornerLength, 0), paint);
        canvas.drawLine(corner, corner + Offset(0, -cornerLength), paint);
      }
    }

    // Draw center crosshair for precise alignment
    final center = Offset(size.width / 2, size.height / 2);
    final crossSize = 15.0;
    canvas.drawLine(
      center + Offset(-crossSize, 0),
      center + Offset(crossSize, 0),
      dashedPaint,
    );
    canvas.drawLine(
      center + Offset(0, -crossSize),
      center + Offset(0, crossSize),
      dashedPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for focus corners
class FocusCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final cornerLength = 30.0;
    final margin = size.width * 0.15;
    
    // Top-left corner
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin + cornerLength, margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin, margin + cornerLength),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin - cornerLength, margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + cornerLength, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin, size.height - margin - cornerLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin - cornerLength, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin, size.height - margin - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
