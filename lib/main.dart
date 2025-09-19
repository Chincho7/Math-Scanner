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
    // Camera permission will be requested only when user navigates to camera screen
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
