import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:massmello/models/person_model.dart';
import 'package:http/http.dart' as http;

class PersonService {
  static const String _personsKey = 'remembered_persons';
  static const String _backendUrl = 'https://b715c7f06e54.ngrok-free.app'; // Replace with your backend URL

  // Get all remembered persons
  Future<List<PersonModel>> getAllPersons() async {
    final prefs = await SharedPreferences.getInstance();
    final personsJson = prefs.getStringList(_personsKey) ?? [];
    
    return personsJson
        .map((json) => PersonModel.fromJson(jsonDecode(json)))
        .toList();
  }

  // Get a specific person by ID
  Future<PersonModel?> getPerson(String id) async {
    final persons = await getAllPersons();
    try {
      return persons.firstWhere((person) => person.id == id);
    } catch (e) {
      return null;
    }
  }

  // Save a new person
  Future<void> savePerson(PersonModel person) async {
    final prefs = await SharedPreferences.getInstance();
    final persons = await getAllPersons();
    
    // Check if person already exists
    final existingIndex = persons.indexWhere((p) => p.id == person.id);
    
    if (existingIndex >= 0) {
      persons[existingIndex] = person;
    } else {
      persons.add(person);
    }
    
    final personsJson = persons.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_personsKey, personsJson);
  }

  // Update person with new identification
  Future<void> markPersonIdentified(String personId) async {
    final person = await getPerson(personId);
    if (person != null) {
      final updatedPerson = person.copyWith(
        identifiedDates: [
          ...person.identifiedDates,
          DateTime.now().toIso8601String(),
        ],
      );
      await savePerson(updatedPerson);
    }
  }

  // Delete a person
  Future<void> deletePerson(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final persons = await getAllPersons();
    persons.removeWhere((person) => person.id == id);
    
    final personsJson = persons.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_personsKey, personsJson);
  }

  // Check person via backend API with image
  Future<Map<String, dynamic>?> checkPersonWithBackend(File imageFile) async {
    try {
      final uri = Uri.parse('$_backendUrl/check_person');
      final request = http.MultipartRequest('POST', uri);
      
      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Backend error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error checking person with backend: $e');
      return null;
    }
  }

  // Analyze person using Gemini AI (placeholder for AI analysis)
  Future<Map<String, dynamic>?> analyzePersonWithAI(File imageFile, String? additionalContext) async {
    try {
      // This is a placeholder - integrate with actual Gemini API
      // You'll need to add google_generative_ai package to pubspec.yaml
      
      // For now, return mock analysis
      return {
        'confidence': 0.95,
        'suggested_name': 'Unknown Person',
        'estimated_age': 'Adult',
        'analysis': 'Person detected in image',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error analyzing with AI: $e');
      return null;
    }
  }

  // Search persons by name
  Future<List<PersonModel>> searchPersons(String query) async {
    final allPersons = await getAllPersons();
    final lowerQuery = query.toLowerCase();
    
    return allPersons.where((person) {
      return person.name.toLowerCase().contains(lowerQuery) ||
             (person.relationship?.toLowerCase().contains(lowerQuery) ?? false) ||
             (person.notes?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Get recently identified persons
  Future<List<PersonModel>> getRecentlyIdentified({int limit = 5}) async {
    final allPersons = await getAllPersons();
    
    // Sort by most recent identification
    allPersons.sort((a, b) {
      if (a.identifiedDates.isEmpty && b.identifiedDates.isEmpty) return 0;
      if (a.identifiedDates.isEmpty) return 1;
      if (b.identifiedDates.isEmpty) return -1;
      
      return b.identifiedDates.last.compareTo(a.identifiedDates.last);
    });
    
    return allPersons.take(limit).toList();
  }
}
