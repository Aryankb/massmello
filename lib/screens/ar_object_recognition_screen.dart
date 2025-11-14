import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:massmello/services/object_recognition_service.dart';
import 'package:massmello/models/object_note_model.dart';
import 'package:massmello/widgets/neomorphic_container.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ARObjectRecognitionScreen extends StatefulWidget {
  const ARObjectRecognitionScreen({super.key});

  @override
  State<ARObjectRecognitionScreen> createState() => _ARObjectRecognitionScreenState();
}

class _ARObjectRecognitionScreenState extends State<ARObjectRecognitionScreen> {
  CameraController? _cameraController;
  ARKitController? _arkitController;
  final ObjectRecognitionService _recognitionService = ObjectRecognitionService();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isProcessing = false;
  bool _isARActive = false;
  String? _detectedObject;
  ObjectNoteModel? _matchedNote;
  List<CameraDescription>? _cameras;
  ARKitNode? _noteNode;
  int _frameCount = 0;
  static const int _frameSkip = 30; // Process every 30th frame
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeTTS();
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream().then((_) {
      _cameraController?.dispose();
    }).catchError((e) {
      _cameraController?.dispose();
    });
    _arkitController?.dispose();
    _recognitionService.dispose();
    _flutterTts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {});
          _startObjectDetection();
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _initializeTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _startObjectDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream((CameraImage image) async {
      // Skip frames to reduce processing load
      _frameCount++;
      if (_frameCount % _frameSkip != 0) {
        return;
      }
      
      if (_isProcessing) return;
      
      _isProcessing = true;
      
      try {
        // Validate image before processing
        if (image.planes.isEmpty || image.width == 0 || image.height == 0) {
          _isProcessing = false;
          return;
        }
        
        final labels = await _recognitionService.detectObjects(image);
        
        if (labels.isNotEmpty && labels.first.confidence > 0.7) {
          final topLabel = labels.first.label;
          
          if (_detectedObject != topLabel) {
            if (mounted) {
              setState(() {
                _detectedObject = topLabel;
              });
            }
            await _checkForMatchingNote(topLabel);
          }
        }
      } catch (e) {
        debugPrint('Error in object detection: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _checkForMatchingNote(String objectLabel) async {
    // Check locally first
    final localMatch = await _recognitionService.findMatchingObjectNote(objectLabel);
    
    if (localMatch != null) {
      setState(() {
        _matchedNote = localMatch;
        _isARActive = true;
      });
      await _playNoteInAR(localMatch);
      return;
    }

    // Check backend
    final backendMatch = await _recognitionService.checkObjectInDatabase(objectLabel);
    
    if (backendMatch != null) {
      setState(() {
        _matchedNote = backendMatch;
        _isARActive = true;
      });
      await _playNoteInAR(backendMatch);
    } else {
      setState(() {
        _matchedNote = null;
        _isARActive = false;
      });
    }
  }

  Future<void> _playNoteInAR(ObjectNoteModel note) async {
    // Play audio if available
    if (note.audioPath != null) {
      await _audioPlayer.play(DeviceFileSource(note.audioPath!));
    } else {
      // Use TTS to speak the note
      await _flutterTts.speak(note.note);
    }

    // Show AR visual note
    _showARNote(note);
  }

  void _showARNote(ObjectNoteModel note) {
    if (_arkitController == null) return;
    
    if (_noteNode != null) {
      _arkitController?.remove(_noteNode!.name);
    }

    // Create text node in AR
    _noteNode = ARKitNode(
      geometry: ARKitText(
        text: note.note,
        extrusionDepth: 1,
        materials: [
          ARKitMaterial(
            diffuse: ARKitMaterialProperty.color(Colors.white),
          ),
        ],
      ),
      position: vector.Vector3(0, 0, -1.5),
      scale: vector.Vector3(0.02, 0.02, 0.02),
    );

    _arkitController?.add(_noteNode!);

    // Remove after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (_noteNode != null && _arkitController != null) {
        _arkitController?.remove(_noteNode!.name);
        _noteNode = null;
      }
    });
  }

  void onARKitViewCreated(ARKitController controller) {
    _arkitController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_cameraController != null && _cameraController!.value.isInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),
          
          // AR overlay when note is detected
          if (_isARActive && _matchedNote != null)
            Positioned.fill(
              child: ARKitSceneView(
                onARKitViewCreated: onARKitViewCreated,
                showStatistics: false,
              ),
            ),

          // UI Overlay
          SafeArea(
            child: SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                child: Column(
                  children: [
                    // Header
                    NeomorphicContainer(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Object Memory Scanner',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Detection status
                    if (_detectedObject != null)
                      NeomorphicContainer(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _matchedNote != null ? Icons.check_circle : Icons.search,
                                  color: _matchedNote != null ? Colors.green : Colors.orange,
                                  size: 32,
                                ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _matchedNote != null ? 'Memory Found!' : 'Scanning...',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Detected: $_detectedObject',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_matchedNote != null) ...[
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 12),
                          Text(
                            _matchedNote!.note,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Instructions
                NeomorphicContainer(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white70, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Point camera at objects to find memories',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/record_object_note');
        },
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add),
        label: const Text('Add Memory'),
      ),
    );
  }
}
