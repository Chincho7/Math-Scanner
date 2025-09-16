import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPermissionGuideScreen extends StatelessWidget {
  const CameraPermissionGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Permission Guide'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Camera Access Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Math Scanner needs camera access to scan and solve math problems from textbooks and handwritten notes.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildGuideSection(
                '1. Enable Camera Access',
                'When prompted, tap "Allow" to give Math Scanner access to your camera.',
                Icons.check_circle_outline,
              ),
              _buildGuideSection(
                '2. If Previously Denied',
                'You\'ll need to enable camera access in your iPhone settings:',
                Icons.settings,
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                        _buildStep('1', 'Open iPhone Settings'),
                    _buildStep('2', 'Scroll down to "Math Scanner"'),
                    _buildStep('3', 'Tap on "Math Scanner"'),
                    _buildStep('4', 'Tap on "Camera"'),
                    _buildStep('5', 'Select "Allow"'),
                    const Divider(height: 24, thickness: 1),
                    _buildNote('If Camera option is missing:'),
                    _buildStep('1', 'Delete the Math Scanner app'),
                    _buildStep('2', 'Restart your iPhone'),
                    _buildStep('3', 'Reinstall Math Scanner'),
                    _buildStep('4', 'Open app and allow when prompted'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => openAppSettings(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Open iPhone Settings',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection(String title, String description, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            instruction,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNote(String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Text(
            note,
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: Colors.orange[700]
            ),
          ),
        ],
      ),
    );
  }
}
