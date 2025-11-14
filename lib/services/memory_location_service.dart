import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:massmello/models/memory_location_model.dart';
import 'package:massmello/services/location_service.dart';

class MemoryLocationService {
  static const String _memoryLocationsKey = 'memory_locations';
  final LocationService _locationService = LocationService();

  Future<void> addMemoryLocation(MemoryLocationModel location) async {
    try {
      final locations = await getMemoryLocations();
      locations.add(location);
      await _saveAll(locations);
    } catch (e) {
      debugPrint('Error adding memory location: $e');
      rethrow;
    }
  }

  Future<List<MemoryLocationModel>> getMemoryLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsData = prefs.getString(_memoryLocationsKey);
      if (locationsData == null) return [];
      
      final List<dynamic> locationsList = json.decode(locationsData) as List;
      return locationsList.map((l) => MemoryLocationModel.fromJson(l as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting memory locations: $e');
      return [];
    }
  }

  Future<void> deleteMemoryLocation(String id) async {
    try {
      final locations = await getMemoryLocations();
      locations.removeWhere((l) => l.id == id);
      await _saveAll(locations);
    } catch (e) {
      debugPrint('Error deleting memory location: $e');
      rethrow;
    }
  }

  Future<MemoryLocationModel?> getMemoryLocationNearby(double lat, double long) async {
    try {
      final allLocations = await getMemoryLocations();

      for (final location in allLocations) {
        final distance = _locationService.calculateDistance(
          lat, long,
          location.latitude, location.longitude
        );
        
        if (distance <= location.radius) {
          return location;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting nearby memory location: $e');
      return null;
    }
  }

  Future<void> _saveAll(List<MemoryLocationModel> locations) async {
    final prefs = await SharedPreferences.getInstance();
    final locationsData = locations.map((l) => l.toJson()).toList();
    await prefs.setString(_memoryLocationsKey, json.encode(locationsData));
  }
}
