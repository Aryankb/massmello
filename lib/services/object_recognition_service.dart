import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:massmello/models/object_note_model.dart';

class ObjectRecognitionService {
  final ImageLabeler _imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.5),
  );
  
  static const String _apiBaseUrl = 'https://your-backend-api.com/api';
  static const String _storageKey = 'object_notes';

  // Detect objects in camera image
  Future<List<ImageLabel>> detectObjects(CameraImage image) async {
    try {
      // Validate image data
      if (image.planes.isEmpty) {
        debugPrint('Camera image has no planes');
        return [];
      }
      
      if (image.width == 0 || image.height == 0) {
        debugPrint('Camera image has invalid dimensions');
        return [];
      }

      // Convert CameraImage to InputImage
      final inputImage = _convertCameraImage(image);
      
      if (inputImage == null) {
        debugPrint('Failed to convert camera image to InputImage');
        return [];
      }

      final labels = await _imageLabeler.processImage(inputImage);
      return labels;
    } catch (e) {
      debugPrint('Error detecting objects: $e');
      return [];
    }
  }

  // Convert CameraImage to InputImage with proper format handling
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // Determine the input image format based on the platform
      final format = _getInputImageFormat(image.format.group);
      
      if (format == null) {
        debugPrint('Unsupported image format: ${image.format.group}');
        return null;
      }

      final plane = image.planes.first;
      
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  // Get the appropriate InputImageFormat for the platform
  InputImageFormat? _getInputImageFormat(ImageFormatGroup formatGroup) {
    switch (formatGroup) {
      case ImageFormatGroup.yuv420:
        return InputImageFormat.yuv420;
      case ImageFormatGroup.bgra8888:
        return InputImageFormat.bgra8888;
      case ImageFormatGroup.nv21:
        return InputImageFormat.nv21;
      default:
        return null;
    }
  }

  // Detect objects from file
  Future<List<ImageLabel>> detectObjectsFromFile(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final labels = await _imageLabeler.processImage(inputImage);
      return labels;
    } catch (e) {
      print('Error detecting objects from file: $e');
      return [];
    }
  }

  // Check if object exists in backend database
  Future<ObjectNoteModel?> checkObjectInDatabase(String objectLabel) async {
    // Skip backend check if using placeholder URL
    if (_apiBaseUrl.contains('your-backend-api.com')) {
      debugPrint('Backend API not configured, skipping remote check');
      return null;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/check_object'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'objectLabel': objectLabel}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Validate that response is JSON
        final contentType = response.headers['content-type'];
        if (contentType == null || !contentType.contains('application/json')) {
          debugPrint('Backend returned non-JSON response');
          return null;
        }
        
        final data = json.decode(response.body);
        if (data['found'] == true) {
          return ObjectNoteModel.fromJson(data['object']);
        }
      }
      return null;
    } catch (e) {
      // Silently fail for backend errors - app works offline
      debugPrint('Backend check skipped: $e');
      return null;
    }
  }

  // Save object note locally
  Future<bool> saveObjectNoteLocally(ObjectNoteModel objectNote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notes = await getLocalObjectNotes();
      notes.add(objectNote);
      
      final jsonList = notes.map((note) => note.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
      return true;
    } catch (e) {
      print('Error saving object note locally: $e');
      return false;
    }
  }

  // Get all local object notes
  Future<List<ObjectNoteModel>> getLocalObjectNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ObjectNoteModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting local object notes: $e');
      return [];
    }
  }

  // Find matching object note locally
  Future<ObjectNoteModel?> findMatchingObjectNote(String detectedLabel) async {
    try {
      final notes = await getLocalObjectNotes();
      
      // Try exact match first
      var match = notes.where((note) => 
        note.objectLabel.toLowerCase() == detectedLabel.toLowerCase()
      ).firstOrNull;
      
      if (match != null) return match;
      
      // Try partial match
      match = notes.where((note) => 
        note.objectLabel.toLowerCase().contains(detectedLabel.toLowerCase()) ||
        detectedLabel.toLowerCase().contains(note.objectLabel.toLowerCase())
      ).firstOrNull;
      
      return match;
    } catch (e) {
      print('Error finding matching object note: $e');
      return null;
    }
  }

  // Save object note to backend
  Future<bool> saveObjectNoteToBackend(ObjectNoteModel objectNote) async {
    // Skip backend save if using placeholder URL
    if (_apiBaseUrl.contains('your-backend-api.com')) {
      debugPrint('Backend API not configured, skipping remote save');
      return false;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/save_object_note'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(objectNote.toJson()),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Backend save skipped: $e');
      return false;
    }
  }

  // Delete object note
  Future<bool> deleteObjectNote(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notes = await getLocalObjectNotes();
      notes.removeWhere((note) => note.id == id);
      
      final jsonList = notes.map((note) => note.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
      return true;
    } catch (e) {
      print('Error deleting object note: $e');
      return false;
    }
  }

  void dispose() {
    _imageLabeler.close();
  }
}
