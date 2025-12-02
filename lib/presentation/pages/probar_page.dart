import 'dart:io'; // Para Platform.isAndroid / isIOS
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // rootBundle.load()

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

  // Tabla de orientación recomendada por google_mlkit_commons
  final Map<DeviceOrientation, int> _orientations = const {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

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
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final frame = await codec.getNextFrame();
      setState(() => _ropaImage = frame.image);
    } catch (e) {
      debugPrint('Error cargando prenda: $e');
    }
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
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de cámara denegado')),
        );
      }
      return;
    }

    final cameras = await availableCameras();

    // Usamos la cámara TRASERA
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _isFrontCamera = false;
    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      // Formato correcto para ML Kit:
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    setState(() => _isCameraInitialized = true);

    await _cameraController!.startImageStream(_processCameraImage);
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;

    // Procesar máximo 2 veces por segundo
    if (DateTime.now().difference(_lastProcessTime).inMilliseconds < 500) {
      return;
    }
    _lastProcessTime = DateTime.now();
    _isProcessing = true;

    try {
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final inputImage = _inputImageFromCameraImage(image);
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

  // Versión oficial adaptada de google_mlkit_commons
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;

      if (camera.lensDirection == CameraLensDirection.front) {
        // cámara frontal
        rotationCompensation =
            (sensorOrientation + rotationCompensation) % 360;
      } else {
        // cámara trasera
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.length != 1) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
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
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: _isCameraInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Fondo degradado a juego con el resto de la app
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF020617),
                        Color(0xFF020617),
                        Color(0xFF0f172a),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // 📸 Cámara a pantalla completa
                CameraPreview(_cameraController!),

                // 🧍‍♂️ Esqueleto (puntos + líneas)
                if (_poses != null && _imageSize != null)
                  CustomPaint(
                    size: screenSize,
                    painter: PoseSkeletonPainter(
                      poses: _poses!,
                      imageSize: _imageSize!,
                      widgetSize: screenSize,
                      mirror: false, // 👈 sin espejo
                    ),
                  ),

                // 👕 Prenda sobre el cuerpo (solo primera pose)
                if (_poses != null &&
                    _poses!.isNotEmpty &&
                    _imageSize != null &&
                    _ropaImage != null)
                  CustomPaint(
                    size: screenSize,
                    painter: RopaPainter(
                      pose: _poses!.first,
                      imageSize: _imageSize!,
                      widgetSize: screenSize,
                      mirror: false, // 👈 sin espejo
                      ropaImage: _ropaImage!,
                    ),
                  ),

                // 🖼 Marco / visor estético sobre la cámara
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(24, 90, 24, 90),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.45),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 🔹 Header interno con icono en círculo + título
                Positioned(
                  top: 24,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38bdf8), Color(0xFF6366f1)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.vrpano_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Probar en AR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Ajusta tu postura y prueba distintas prendas.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 🔘 Botón flotante sutil para cambiar prenda (misma funcionalidad)
                Positioned(
                  bottom: 32,
                  right: 24,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Material(
                        color: Colors.black.withOpacity(0.55),
                        child: InkWell(
                          onTap: _changeRopa,
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.autorenew_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Cambiar prenda',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF020617),
                    Color(0xFF020617),
                    Color(0xFF0f172a),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
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

// 🎯 Pinta puntos + líneas (esqueleto)
class PoseSkeletonPainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final Size widgetSize;
  final bool mirror;

  PoseSkeletonPainter({
    required this.poses,
    required this.imageSize,
    required this.widgetSize,
    required this.mirror,
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
    final pointPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    for (final pose in poses) {
      // 1) Dibuja TODOS los puntos
      for (final landmark in pose.landmarks.values) {
        final p = _mapPoint(landmark.x, landmark.y);
        canvas.drawCircle(p, 6, pointPaint);
      }

      // 2) Conexiones para simular esqueleto
      Offset? getPoint(PoseLandmarkType type) {
        final lm = pose.landmarks[type];
        if (lm == null) return null;
        return _mapPoint(lm.x, lm.y);
      }

      final pairs = <List<PoseLandmarkType>>[
        // torso
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
        [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],

        // brazo derecho
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
        [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],

        // brazo izquierdo
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
        [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],

        // pierna derecha
        [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
        [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],

        // pierna izquierda
        [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
        [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],

        // cuello / cabeza aproximados
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftEar],
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightEar],
      ];

      for (final pair in pairs) {
        final p1 = getPoint(pair[0]);
        final p2 = getPoint(pair[1]);
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1, p2, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
