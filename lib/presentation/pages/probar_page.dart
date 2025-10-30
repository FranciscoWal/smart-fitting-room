import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // para rootBundle.load()

class ProbarPage extends StatefulWidget {
  const ProbarPage({super.key});

  @override
  State<ProbarPage> createState() => _ProbarPageState();
}

class _ProbarPageState extends State<ProbarPage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  PoseDetector? _poseDetector;
  List<Pose>? _poses;
  bool _isProcessing = false;
  Size? _imageSize;
  bool _isFrontCamera = false;
  DateTime _lastProcessTime = DateTime.now();

  final List<String> _ropaPaths = [
    'assets/images/prenda_1.png',
    'assets/images/prenda_2.png',
    'assets/images/prenda_3.png',
  ];
  int _currentRopaIndex = 0;
  ui.Image? _ropaImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );
    _loadRopaImage(_ropaPaths[_currentRopaIndex]);
  }

  Future<void> _loadRopaImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    setState(() => _ropaImage = frame.image);
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    final cameras = await availableCameras();

    // 👉 Usamos la cámara TRASERA (y luego reflejamos la imagen)
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _isFrontCamera = false;
    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    setState(() => _isCameraInitialized = true);

    await _cameraController!.startImageStream(_processCameraImage);
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;

    // 👇 Procesar máximo 2 veces por segundo
    if (DateTime.now().difference(_lastProcessTime).inMilliseconds < 500) return;
    _lastProcessTime = DateTime.now();

    _isProcessing = true;

    try {
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final poses = await _poseDetector!.processImage(inputImage);
      if (mounted) {
        setState(() {
          _poses = poses;
        });
      }
    } catch (e) {
      debugPrint('Error al procesar la imagen: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final bytesBuilder = BytesBuilder();
      for (final plane in image.planes) {
        bytesBuilder.add(plane.bytes);
      }
      final bytes = bytesBuilder.toBytes();

      int rotationDegrees = _cameraController?.description.sensorOrientation ?? 0;
      InputImageRotation rotation = InputImageRotation.rotation0deg;
      if (rotationDegrees == 90) {
        rotation = InputImageRotation.rotation90deg;
      } else if (rotationDegrees == 180) {
        rotation = InputImageRotation.rotation180deg;
      } else if (rotationDegrees == 270) {
        rotation = InputImageRotation.rotation270deg;
      }

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes.isNotEmpty ? image.planes[0].bytesPerRow : 0,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (_) {
      return null;
    }
  }

  void _changeRopa() async {
    setState(() {
      _currentRopaIndex = (_currentRopaIndex + 1) % _ropaPaths.length;
    });
    await _loadRopaImage(_ropaPaths[_currentRopaIndex]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cambiando a prenda ${_currentRopaIndex + 1}'),
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCameraInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                // 📸 Cámara reflejada como espejo
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(3.1416),
                  child: CameraPreview(_cameraController!),
                ),
                // 👕 Dibuja la prenda sobre el cuerpo
                if (_poses != null && _imageSize != null && _ropaImage != null)
                  ..._poses!.map((pose) {
                    return CustomPaint(
                      painter: RopaPainter(
                        pose: pose,
                        imageSize: _imageSize!,
                        widgetSize: MediaQuery.of(context).size,
                        mirror: true,
                        ropaImage: _ropaImage!,
                      ),
                    );
                  }).toList(),
                // 🔘 Botón inferior
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _changeRopa,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Probar prendas',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

// 🎨 Pinta la prenda sobre el cuerpo según puntos de pose
class RopaPainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final Size widgetSize;
  final bool mirror;
  final ui.Image ropaImage;

  RopaPainter({
    required this.pose,
    required this.imageSize,
    required this.widgetSize,
    required this.mirror,
    required this.ropaImage,
  });

  Offset _mapPoint(double x, double y) {
    final scaleX = widgetSize.width / imageSize.width;
    final scaleY = widgetSize.height / imageSize.height;

    double mappedX = x * scaleX;
    if (mirror) mappedX = widgetSize.width - mappedX;
    double mappedY = y * scaleY;
    return Offset(mappedX, mappedY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) return;

    final pLeftShoulder = _mapPoint(leftShoulder.x, leftShoulder.y);
    final pRightShoulder = _mapPoint(rightShoulder.x, rightShoulder.y);
    final pLeftHip = _mapPoint(leftHip.x, leftHip.y);
    final pRightHip = _mapPoint(rightHip.x, rightHip.y);

    final top = (pLeftShoulder.dy + pRightShoulder.dy) / 2;
    final bottom = (pLeftHip.dy + pRightHip.dy) / 2;
    final left = (pLeftShoulder.dx + pLeftHip.dx) / 2;
    final right = (pRightShoulder.dx + pRightHip.dx) / 2;

    final rect = Rect.fromLTRB(left, top, right, bottom);

    // 👕 Dibuja la imagen PNG de la prenda
    paintImage(
      canvas: canvas,
      rect: rect,
      image: ropaImage,
      fit: BoxFit.fill,
      opacity: 0.9,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}