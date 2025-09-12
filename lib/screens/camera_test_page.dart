import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// A direct camera test page that focuses solely on camera permissions and initialization
/// This isolates camera functionality for easier debugging
class CameraTestPage extends StatefulWidget {
  const CameraTestPage({super.key});

  @override
  State<CameraTestPage> createState() => _CameraTestPageState();
}

class _CameraTestPageState extends State<CameraTestPage> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isPermissionRequested = false;
  String _statusMessage = "Checking camera permission...";
  PermissionStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Don't request permission immediately - let user trigger it
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app returning from Settings after permission change
    if (state == AppLifecycleState.resumed && _isPermissionRequested) {
      _checkPermissionAndInitCamera();
    }
  }

  // Separate permission check from camera initialization for better diagnostics
  Future<void> _checkPermissionAndInitCamera() async {
    setState(() {
      _statusMessage = "Checking camera permission...";
    });

    try {
      _permissionStatus = await Permission.camera.status;
      
      if (_permissionStatus == PermissionStatus.granted) {
        setState(() {
          _statusMessage = "Permission granted. Initializing camera...";
        });
        await _initializeCamera();
      } else if (_permissionStatus == PermissionStatus.denied) {
        setState(() {
          _statusMessage = "Camera permission denied. Request needed.";
        });
      } else if (_permissionStatus == PermissionStatus.permanentlyDenied) {
        setState(() {
          _statusMessage = "Camera permission permanently denied. Please open settings.";
        });
      } else {
        setState(() {
          _statusMessage = "Permission status: ${_permissionStatus?.toString()}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error checking permission: $e";
      });
    }
  }

  // Handle the request separately
  Future<void> _requestPermission() async {
    setState(() {
      _statusMessage = "Requesting camera permission...";
      _isPermissionRequested = true;
    });

    try {
      final status = await Permission.camera.request();
      _permissionStatus = status;
      
      if (status.isGranted) {
        setState(() {
          _statusMessage = "Permission granted. Initializing camera...";
        });
        await _initializeCamera();
      } else {
        setState(() {
          _statusMessage = "Permission denied: ${status.toString()}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error requesting permission: $e";
      });
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _statusMessage = "Getting available cameras...";
    });

    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _statusMessage = "No cameras found on device";
        });
        return;
      }

      // Start with back camera if available
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      setState(() {
        _statusMessage = "Creating camera controller...";
      });

      // Create controller
      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium, // Lower resolution for testing
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Initialize camera
      setState(() {
        _statusMessage = "Initializing camera controller...";
      });
      
      await _controller!.initialize();

      setState(() {
        _isCameraInitialized = true;
        _statusMessage = "Camera initialized successfully!";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Camera initialization error: $e";
      });
    }
  }

  Widget _buildPermissionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            Text(_statusMessage, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            if (_permissionStatus == null || _permissionStatus == PermissionStatus.denied)
              ElevatedButton(
                onPressed: _requestPermission,
                child: const Text("Request Camera Permission"),
              ),
            if (_permissionStatus == PermissionStatus.permanentlyDenied)
              ElevatedButton(
                onPressed: () => openAppSettings(),
                child: const Text("Open Settings"),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkPermissionAndInitCamera,
              child: const Text("Check Permission Status"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Dispose and recreate
              _controller?.dispose();
              setState(() {
                _isCameraInitialized = false;
                _controller = null;
              });
              _checkPermissionAndInitCamera();
            },
          )
        ],
      ),
      body: _isCameraInitialized
          ? Column(
              children: [
                Expanded(
                  child: _controller != null
                      ? CameraPreview(_controller!)
                      : const Center(child: Text("Camera controller is null")),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black12,
                  child: Text(_statusMessage, 
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            )
          : _buildPermissionView(),
    );
  }
}
