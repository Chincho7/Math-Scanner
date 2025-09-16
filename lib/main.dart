import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:math_scanner/screens/camera_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Optional .env; ignore missing file.
  }

  runApp(const MathScannerApp());
}

class MathScannerApp extends StatefulWidget {
  const MathScannerApp({super.key});

  @override
  State<MathScannerApp> createState() => _MathScannerAppState();
}

class _MathScannerAppState extends State<MathScannerApp> {
  @override
  void initState() {
    super.initState();
    // Warm-up permission non-blocking after first frame to avoid white screen hang.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warmUpIOSCameraPermission();
    });
  }

  Future<void> _warmUpIOSCameraPermission() async {
    if (!Platform.isIOS) return;
    try {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        // Fire request but don't await potential secondary operations.
        await Permission.camera.request();
      }
      // Light camera probe (timeout) to register permission in Settings without blocking UI.
      unawaited(_lightCameraProbe());
    } catch (e) {
      // Swallow errors; this is best-effort.
    }
  }

  Future<void> _lightCameraProbe() async {
    try {
      final cameras = await availableCameras().timeout(const Duration(seconds: 3));
      if (cameras.isEmpty) return;
      final controller = CameraController(cameras.first, ResolutionPreset.low, enableAudio: false);
      await controller.initialize().timeout(const Duration(seconds: 4));
      await controller.dispose();
    } catch (_) {
      // Ignore; diagnostic only.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const CameraScreen(),
      },
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
    );
  }
}
