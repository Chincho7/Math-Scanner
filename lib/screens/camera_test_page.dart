import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// A robust camera test page with comprehensive error reporting
class CameraTestPage extends StatefulWidget {
  const CameraTestPage({Key? key}) : super(key: key);

  @override
  State<CameraTestPage> createState() => _CameraTestPageState();
}

class _CameraTestPageState extends State<CameraTestPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  String _status = "Starting camera test...";
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initTest();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initTest() async {
    _updateStatus("Requesting camera permission...");
    
    // Request permission
    final status = await Permission.camera.request();
    
    if (status.isGranted) {
      _updateStatus("Permission granted. Getting available cameras...");
      
      try {
        // Get cameras
        _cameras = await availableCameras();
        _updateStatus("Found ${_cameras!.length} cameras");
        
        if (_cameras!.isEmpty) {
          _updateStatus("Error: No cameras found");
          return;
        }
        
        // Find back camera
        final backCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );
        
        _updateStatus("Selected camera: ${backCamera.name}");
        
        // Create controller with low resolution
        _controller = CameraController(
          backCamera,
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.jpeg,
        );
        
        _updateStatus("Created controller. Initializing...");
        
        // Initialize with longer timeout for iOS
        await _controller!.initialize().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            _updateStatus("ERROR: Camera initialization timed out");
            return;
          },
        );
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _status = "Camera initialized successfully!";
          });
        }
      } catch (e) {
        _updateStatus("Error: $e");
      }
    } else {
      _updateStatus("Permission denied: $status");
    }
  }
  
  void _updateStatus(String message) {
    print("CAMERA TEST: $message");
    if (mounted) {
      setState(() {
        _status = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Camera Test"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller?.dispose();
              _controller = null;
              setState(() {
                _isInitialized = false;
              });
              _initTest();
            },
            tooltip: "Restart Test",
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: openAppSettings,
            tooltip: "Open Settings",
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Camera Status:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_status),
                if (Platform.isIOS) ...[
                  const SizedBox(height: 8),
                  const Text(
                    "iOS camera initialization can take several seconds",
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          
          // Camera preview or loading state
          Expanded(
            child: _isInitialized && _controller != null && _controller!.value.isInitialized
                ? _buildCameraPreview()
                : _buildLoadingState(),
          ),
          
          // iOS-specific help
          if (Platform.isIOS)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.05),
              child: Column(
                children: [
                  const Text(
                    "iPhone Camera Permission Guide:",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Settings > Math Scanner > Camera > Enable",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCameraPreview() {
    try {
      return CameraPreview(_controller!);
    } catch (e) {
      _updateStatus("Preview error: $e");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              "Error displaying camera preview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(e.toString()),
          ],
        ),
      );
    }
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(_status),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _initTest,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
