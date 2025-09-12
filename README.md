# Math Scanner App

A Flutter application that allows users to scan, upload, or manually input math problems on both iOS and Android devices.

## Features

- **Scan with Camera**: Use OCR to recognize math problems from handwriting, textbooks, or screens
- **Upload Image**: Pick a photo from the gallery to extract math problems
- **Manual Input**: Type math problems using a math-friendly keyboard

## Getting Started

### Prerequisites

- Flutter SDK (2.19.0 or higher)
- Dart SDK (2.19.0 or higher)
- Android Studio / Xcode for building to respective platforms

### Installation

1. Clone this repository
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app on a connected device or simulator

## Building for Production

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```
Then use Xcode to archive and distribute the app.

## Dependencies

- camera: For accessing device camera
- image_picker: For picking images from gallery
- google_mlkit_text_recognition: For OCR capabilities
- math_keyboard: For math-friendly keyboard input
- flutter_math_fork: For rendering math expressions

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Google ML Kit for OCR capabilities
- Flutter team for the amazing framework
