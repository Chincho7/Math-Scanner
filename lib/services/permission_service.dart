import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';

class PermissionService {
  // Singleton instance
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();
  
  /// Check if camera hardware is available on the device
  Future<bool> isCameraAvailable() async {
    try {
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Aggressively force iOS to recognize camera permission
  /// This uses multiple methods to ensure the permission shows up in settings
  Future<void> forceIOSCameraPermissionRegistration() async {
    if (Platform.isIOS) {
      try {
        // Method 1: Standard permission_handler approach with timeout
        await Permission.camera.request().timeout(const Duration(seconds: 5));
        
        // Method 2: Try camera plugin directly to trigger system dialog (with timeout)
        try {
          final cameras = await availableCameras().timeout(const Duration(seconds: 3));
          if (cameras.isNotEmpty) {
            final controller = CameraController(cameras[0], ResolutionPreset.low, enableAudio: false);
            await controller.initialize().timeout(const Duration(seconds: 4));
            await controller.dispose();
          }
        } catch (e) {
          // Ignore errors, we just want to trigger the system dialog
          print('Camera init attempt: $e');
        }
      } catch (e) {
        print('Force permission registration error: $e');
      }
    }
  }

  /// Request camera permission with proper user guidance
  Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      // First check if camera is available on the device
      final cameras = await availableCameras().catchError((e) {
        // If there's an error checking cameras, it might be permission-related
        return <CameraDescription>[];
      });
      
      // Force permission request first to ensure iOS registers it properly
      // This is critical - iOS needs to see the request at least once
      // to show the permission in Settings
      await Permission.camera.request();
      
      // Now check current status after the request
      final status = await Permission.camera.status;
      
      // Already granted
      if (status.isGranted) {
        return true;
      }
      
      // Check if we have physical cameras
      if (cameras.isEmpty) {
        _showToast(context, "No cameras found on device");
        return false;
      }
      
      // Permission permanently denied, need to open settings
      if (status.isPermanentlyDenied) {
        final bool shouldOpenSettings = await _showPermissionDialog(
          context,
          title: "Camera Permission Required",
          message: "Camera access has been permanently denied. Please go to your iPhone Settings > Math Scanner > Camera and enable the permission.\n\nIf you don't see Camera in the settings, please delete and reinstall the app.",
          primaryButtonText: "Open Settings",
          secondaryButtonText: "Cancel",
          isPermanent: true,
        );
        
        if (shouldOpenSettings) {
          await openAppSettings();
          // After returning from settings, check again
          await Future.delayed(const Duration(seconds: 1));
          return await Permission.camera.isGranted;
        }
        return false;
      }
      
      // First time asking or previously denied (not permanently)
      if (status.isDenied || status.isRestricted || status.isLimited) {
        // Show explanatory dialog first
        final bool shouldRequest = await _showPermissionDialog(
          context,
          title: "Camera Access Needed",
          message: "This app needs to use your camera to scan math problems. Allow camera access?",
          primaryButtonText: "Continue",
          secondaryButtonText: "Not Now",
        );
        
        if (!shouldRequest) {
          return false;
        }
        
        // Request permission again - this will show the iOS permission popup
        final result = await Permission.camera.request();
        
        // Check the result of request
        if (result.isGranted) {
          return true;
        } else {
          // Show the iOS settings instructions
          if (result.isPermanentlyDenied) {
            await _showPermissionDialog(
              context,
              title: "Camera Permission Denied",
              message: "Please open your iPhone Settings app > Math Scanner > Camera and enable the permission.\n\nIf you don't see Camera in the settings, please delete and reinstall the app.",
              primaryButtonText: "Open Settings",
              secondaryButtonText: "Cancel",
              isPermanent: true,
            ).then((openSettings) {
              if (openSettings) {
                openAppSettings();
              }
            });
          } else {
            _showToast(context, "Camera permission denied. Some features will not work.");
          }
          return false;
        }
      }
    } catch (e) {
      _showToast(context, "Error requesting camera permission: $e");
    }
    
    return false;
  }
  
  // Helper method to show toast messages
  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: "Settings",
          onPressed: openAppSettings,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<bool> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String primaryButtonText,
    required String secondaryButtonText,
    bool isPermanent = false,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(secondaryButtonText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(primaryButtonText),
          ),
        ],
      ),
    ) ?? false;
  }
}
