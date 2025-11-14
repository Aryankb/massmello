import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:massmello/services/object_recognition_service.dart';
import 'package:massmello/models/object_note_model.dart';
import 'package:massmello/widgets/neomorphic_container.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class RecordObjectNoteScreen extends StatefulWidget {
  const RecordObjectNoteScreen({super.key});

  @override
  State<RecordObjectNoteScreen> createState() => _RecordObjectNoteScreenState();
}

class _RecordObjectNoteScreenState extends State<RecordObjectNoteScreen> {
  CameraController? _cameraController;
  ARKitController? _arkitController;
  final ObjectRecognitionService _recognitionService = ObjectRecognitionService();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _objectNameController = TextEditingController();
  
  List<CameraDescription>? _cameras;
  String? _detectedObject;
  File? _capturedImage;
  String? _recordedAudioPath;
  bool _isRecordingAudio = false;
  bool _isProcessing = false;
  bool _showARPreview = false;
  ARKitNode? _previewNode;
  
  RecordingMode _recordingMode = RecordingMode.text;
  List<ObjectNoteModel> _savedNotes = [];
  final int _maxLocalNotes = 5;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadSavedNotes();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _arkitController?.dispose();
    _recognitionService.dispose();
    _flutterTts.stop();
    _audioPlayer.dispose();
    _noteController.dispose();
    _objectNameController.dispose();
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
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _loadSavedNotes() async {
    final notes = await _recognitionService.getLocalObjectNotes();
    setState(() {
      _savedNotes = notes.take(_maxLocalNotes).toList();
    });
  }

  Future<void> _detectObject() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showSnackBar('Camera not ready');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final image = await _cameraController!.takePicture();
      _capturedImage = File(image.path);
      
      final labels = await _recognitionService.detectObjectsFromFile(_capturedImage!);
      
      if (labels.isNotEmpty) {
        final topLabel = labels.first.label;
        setState(() {
          _detectedObject = topLabel;
          _objectNameController.text = topLabel;
        });
        _showSnackBar('Detected: $topLabel');
      } else {
        _showSnackBar('No object detected. Please enter manually.');
      }
    } catch (e) {
      debugPrint('Error detecting object: $e');
      _showSnackBar('Detection failed');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _recordAudio() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showSnackBar('Microphone permission required');
      return;
    }

    // Note: You'll need to add a proper audio recording package like 'record' or 'flutter_sound'
    // For now, this is a placeholder
    setState(() => _isRecordingAudio = !_isRecordingAudio);
    
    if (_isRecordingAudio) {
      _showSnackBar('Recording audio...');
      // TODO: Start actual audio recording
    } else {
      _showSnackBar('Audio recording stopped');
      // TODO: Save audio file and set _recordedAudioPath
    }
  }

  Future<void> _saveObjectNote() async {
    if (_objectNameController.text.isEmpty) {
      _showSnackBar('Please enter an object name');
      return;
    }

    if (_noteController.text.isEmpty && _recordedAudioPath == null) {
      _showSnackBar('Please add a text note or record audio');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final objectNote = ObjectNoteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        objectName: _objectNameController.text,
        objectLabel: _detectedObject ?? _objectNameController.text,
        note: _noteController.text,
        audioPath: _recordedAudioPath,
        imagePath: _capturedImage?.path,
        createdAt: DateTime.now(),
        metadata: {
          'recordingMode': _recordingMode.toString(),
        },
      );

      // Save locally first
      await _recognitionService.saveObjectNoteLocally(objectNote);
      
      // Keep only last 5 notes
      await _enforceLocalLimit();

      // Try to save to backend
      await _saveToBackend(objectNote);

      _showSnackBar('Object note saved successfully!');
      _resetForm();
      await _loadSavedNotes();
    } catch (e) {
      debugPrint('Error saving object note: $e');
      _showSnackBar('Failed to save note');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveToBackend(ObjectNoteModel objectNote) async {
    try {
      const apiUrl = 'https://your-backend-api.com/api/object-save';
      
      // Skip if placeholder URL
      if (apiUrl.contains('your-backend-api.com')) {
        debugPrint('Backend not configured, saving locally only');
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(objectNote.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('Successfully saved to backend');
      } else {
        debugPrint('Backend save failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Backend save error: $e');
    }
  }

  Future<void> _enforceLocalLimit() async {
    final notes = await _recognitionService.getLocalObjectNotes();
    if (notes.length > _maxLocalNotes) {
      // Keep only the most recent 5 by deleting older ones
      for (var i = _maxLocalNotes; i < notes.length; i++) {
        await _recognitionService.deleteObjectNote(notes[i].id);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _noteController.clear();
      _objectNameController.clear();
      _detectedObject = null;
      _capturedImage = null;
      _recordedAudioPath = null;
      _isRecordingAudio = false;
      _showARPreview = false;
    });
  }

  void _toggleARPreview() {
    if (!_showARPreview && _noteController.text.isEmpty) {
      _showSnackBar('Enter a note to preview in AR');
      return;
    }

    setState(() => _showARPreview = !_showARPreview);
  }

  void onARKitViewCreated(ARKitController controller) {
    _arkitController = controller;
    _addARPreviewNode();
  }

  void _addARPreviewNode() {
    if (_arkitController == null) return;

    _previewNode = ARKitNode(
      geometry: ARKitText(
        text: _noteController.text,
        extrusionDepth: 1,
        materials: [
          ARKitMaterial(
            diffuse: ARKitMaterialProperty.color(const Color(0xFF6C63FF)),
          ),
        ],
      ),
      position: vector.Vector3(0, 0, -1.5),
      scale: vector.Vector3(0.02, 0.02, 0.02),
    );

    _arkitController?.add(_previewNode!);
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview in background (full screen)
          if (_cameraController != null && _cameraController!.value.isInitialized && !_showARPreview)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),

          // AR preview overlay
          if (_showARPreview)
            Positioned.fill(
              child: ARKitSceneView(
                onARKitViewCreated: onARKitViewCreated,
                showStatistics: false,
              ),
            ),

          // Object detection border highlight
          if (_detectedObject != null)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF6C63FF),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),

          // Top header with back button and info
          SafeArea(
            child: Column(
              children: [
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
                              'Record Object Memory',
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
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Detected: $_detectedObject',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom controls
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Scan instruction or object name input
                      if (_detectedObject == null)
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.white70, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Tap detect to scan an object',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _objectNameController,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: const InputDecoration(
                              labelText: 'Object Name',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: 'e.g., Coffee Mug, Keys',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Recording mode and note input
                      if (_detectedObject != null) ...[
                        // Mode selector
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactModeButton(
                                'Text',
                                Icons.text_fields,
                                RecordingMode.text,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildCompactModeButton(
                                'Audio',
                                Icons.mic,
                                RecordingMode.audio,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Text input or audio recording
                        if (_recordingMode == RecordingMode.text)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _noteController,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Memory Note',
                                labelStyle: TextStyle(color: Colors.white70),
                                hintText: 'What do you want to remember?',
                                hintStyle: TextStyle(color: Colors.white38),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          )
                        else
                          // Audio recording button
                          GestureDetector(
                            onTap: _recordAudio,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: _isRecordingAudio 
                                    ? Colors.red.withOpacity(0.8)
                                    : const Color(0xFF6C63FF).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isRecordingAudio ? Icons.stop_circle : Icons.mic,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isRecordingAudio ? 'Stop Recording' : 'Record Audio Note',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Action buttons row
                        Row(
                          children: [
                            // AR Preview button
                            Expanded(
                              child: GestureDetector(
                                onTap: _toggleARPreview,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: _showARPreview 
                                        ? Colors.orange.withOpacity(0.8)
                                        : Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _showARPreview ? Icons.visibility_off : Icons.view_in_ar,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _showARPreview ? 'Hide AR' : 'AR Preview',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Save button
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (!_isProcessing) _saveObjectNote();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C63FF).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isProcessing)
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      else
                                        const Icon(Icons.save, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isProcessing ? 'Saving...' : 'Save',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Detect button (always visible)
                      GestureDetector(
                        onTap: () {
                          if (!_isProcessing) _detectObject();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isProcessing)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                _isProcessing ? 'Detecting Object...' : 'Detect Object',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Saved notes count
                      if (_savedNotes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _showSavedNotes,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.list_alt, color: Colors.white70, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '${_savedNotes.length} saved ${_savedNotes.length == 1 ? 'memory' : 'memories'}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactModeButton(String label, IconData icon, RecordingMode mode) {
    final isSelected = _recordingMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _recordingMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF6C63FF).withOpacity(0.9)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSavedNotes() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Saved Memories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _savedNotes.length,
                itemBuilder: (context, index) => _buildSavedNoteCard(_savedNotes[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedNoteCard(ObjectNoteModel note) {
    return NeomorphicContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (note.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(note.imagePath!),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, color: Color(0xFF6C63FF)),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.objectName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Color(0xFF6C63FF)),
            onPressed: () async {
              if (note.audioPath != null) {
                await _audioPlayer.play(DeviceFileSource(note.audioPath!));
              } else {
                await _flutterTts.speak(note.note);
              }
            },
          ),
        ],
      ),
    );
  }
}

enum RecordingMode { text, audio }
