import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:massmello/services/object_recognition_service.dart';
import 'package:massmello/models/object_note_model.dart';
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
          // Camera preview as background
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

          // Object detection border highlight (centered)
          if (_detectedObject != null)
            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _matchedNote != null 
                        ? const Color(0xFF6C63FF)
                        : Colors.orange,
                    width: 4,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (_matchedNote != null 
                          ? const Color(0xFF6C63FF)
                          : Colors.orange).withOpacity(0.6),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _matchedNote != null ? Icons.check_circle : Icons.search,
                    color: _matchedNote != null 
                        ? const Color(0xFF6C63FF)
                        : Colors.orange,
                    size: 48,
                  ),
                ),
              ),
            ),

          // UI Overlay (inspired by AR Navigation)
          SafeArea(
            child: Column(
              children: [
                // Top header with info
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
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
                      if (_detectedObject != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoItem(
                              icon: Icons.camera_alt,
                              label: 'Object',
                              value: _detectedObject!.length > 12 
                                  ? '${_detectedObject!.substring(0, 12)}...'
                                  : _detectedObject!,
                            ),
                            _buildInfoItem(
                              icon: _matchedNote != null ? Icons.check_circle : Icons.search,
                              label: 'Status',
                              value: _matchedNote != null ? 'Found' : 'Searching',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                const Spacer(),

                // Memory display when found
                if (_matchedNote != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _matchedNote!.audioPath != null 
                                  ? Icons.volume_up 
                                  : Icons.text_fields,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Memory: ${_matchedNote!.objectName}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white30),
                        const SizedBox(height: 12),
                        Text(
                          _matchedNote!.note,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Auto-playing message',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else if (_detectedObject != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Searching for saved memories...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.white70, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Point camera at objects to find memories',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
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

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
