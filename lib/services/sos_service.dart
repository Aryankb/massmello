import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:massmello/models/sos_settings_model.dart';
import 'package:massmello/services/location_service.dart';

class SOSService {
  static const String _sosSettingsKey = 'sos_settings';
  final LocationService _locationService = LocationService();

  Future<void> saveSOSSettings(SOSSettingsModel settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sosSettingsKey, json.encode(settings.toJson()));
    } catch (e) {
      debugPrint('Error saving SOS settings: $e');
      rethrow;
    }
  }

  Future<SOSSettingsModel?> getSOSSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsData = prefs.getString(_sosSettingsKey);
      if (settingsData == null) return null;
      return SOSSettingsModel.fromJson(json.decode(settingsData) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting SOS settings: $e');
      return null;
    }
  }

  Future<void> updateSOSSettings(SOSSettingsModel settings) async {
    await saveSOSSettings(settings);
  }

  Future<bool> checkLocationAndTriggerSOS(double currentLat, double currentLong) async {
    try {
      final settings = await getSOSSettings();
      if (settings == null || !settings.isEnabled) return false;

      final distance = _locationService.calculateDistance(
        currentLat, currentLong,
        settings.homeLatitude, settings.homeLongitude
      );

      if (distance > settings.radius) {
        await sendSOSRequest(settings.backendUrl, settings.userId, currentLat, currentLong);
        await updateSOSSettings(settings.copyWith(lastTriggered: DateTime.now()));
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking location for SOS: $e');
      return false;
    }
  }

  Future<void> sendSOSRequest(String backendUrl, String userId, double currentLat, double currentLong) async {
    try {
      final url = '$backendUrl/location_crossed';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'latitude': currentLat,
          'longitude': currentLong,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('SOS request sent successfully');
      } else {
        debugPrint('SOS request failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending SOS request: $e');
    }
  }
}
