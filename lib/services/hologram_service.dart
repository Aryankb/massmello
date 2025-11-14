import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:massmello/models/hologram_message_model.dart';
import 'package:massmello/services/location_service.dart';

class HologramService {
  static const String _hologramsKey = 'holograms';
  final LocationService _locationService = LocationService();

  Future<void> addHologram(HologramMessageModel hologram) async {
    try {
      final holograms = await getHolograms();
      holograms.add(hologram);
      await _saveAll(holograms);
    } catch (e) {
      debugPrint('Error adding hologram: $e');
      rethrow;
    }
  }

  Future<List<HologramMessageModel>> getHolograms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hologramsData = prefs.getString(_hologramsKey);
      if (hologramsData == null) return [];
      
      final List<dynamic> hologramsList = json.decode(hologramsData) as List;
      return hologramsList.map((h) => HologramMessageModel.fromJson(h as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting holograms: $e');
      return [];
    }
  }

  Future<void> deleteHologram(String id) async {
    try {
      final holograms = await getHolograms();
      holograms.removeWhere((h) => h.id == id);
      await _saveAll(holograms);
    } catch (e) {
      debugPrint('Error deleting hologram: $e');
      rethrow;
    }
  }

  Future<List<HologramMessageModel>> getHologramsNearLocation(double lat, double long, double searchRadius) async {
    try {
      final allHolograms = await getHolograms();
      final nearbyHolograms = <HologramMessageModel>[];

      for (final hologram in allHolograms) {
        final distance = _locationService.calculateDistance(
          lat, long,
          hologram.latitude, hologram.longitude
        );
        
        if (distance <= hologram.radius + searchRadius) {
          nearbyHolograms.add(hologram);
        }
      }

      return nearbyHolograms;
    } catch (e) {
      debugPrint('Error getting nearby holograms: $e');
      return [];
    }
  }

  Future<void> _saveAll(List<HologramMessageModel> holograms) async {
    final prefs = await SharedPreferences.getInstance();
    final hologramsData = holograms.map((h) => h.toJson()).toList();
    await prefs.setString(_hologramsKey, json.encode(hologramsData));
  }
}
