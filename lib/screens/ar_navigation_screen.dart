import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' show sin, cos, pi;
import 'package:massmello/services/user_service.dart';
import 'package:massmello/services/location_service.dart';

class ARNavigationScreen extends StatefulWidget {
  const ARNavigationScreen({super.key});

  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen> {
  late ARKitController arkitController;

  double? _homeLatitude;
  double? _homeLongitude;
  double? _compassHeading;
  double _distanceToHome = 0;
  double _bearingToHome = 0;
  
  Timer? _updateTimer;
  final LocationService _locationService = LocationService();
  StreamSubscription<CompassEvent>? _compassSubscription;
  ARKitNode? _arrowNode;

  @override
  void initState() {
    super.initState();
    _loadHomeLocation();
    _startCompass();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _compassSubscription?.cancel();
    arkitController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeLocation() async {
    final user = await UserService().getUser();
    if (user != null) {
      setState(() {
        _homeLatitude = user.homeLatitude;
        _homeLongitude = user.homeLongitude;
      });
      _startLocationUpdates();
    }
  }

  void _startCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      setState(() {
        _compassHeading = event.heading;
      });
    });
  }

  void _startLocationUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _updatePosition();
    });
  }

  Future<void> _updatePosition() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null && _homeLatitude != null && _homeLongitude != null) {
      setState(() {
        _distanceToHome = _locationService.calculateDistance(
          position.latitude,
          position.longitude,
          _homeLatitude!,
          _homeLongitude!,
        );
        _bearingToHome = _locationService.calculateBearing(
          position.latitude,
          position.longitude,
          _homeLatitude!,
          _homeLongitude!,
        );
      });
      _updateARArrow();
    }
  }

  void _updateARArrow() {
    if (_compassHeading == null) return;

    final adjustedBearing = (_bearingToHome - _compassHeading!) % 360;
    final radians = adjustedBearing * (pi / 180);

    if (_arrowNode != null) {
      arkitController.remove(_arrowNode!.name);
    }

    final distance = 2.0;
    final x = distance * sin(radians);
    final z = -distance * cos(radians);

    _arrowNode = ARKitReferenceNode(
      url: 'assets/models/arrow.obj',
      position: vector.Vector3(x, -0.5, z),
      scale: vector.Vector3(0.2, 0.2, 0.2),
      eulerAngles: vector.Vector3(pi / 2, radians, 0),
    );

    arkitController.add(_arrowNode!);
  }

  void onARKitViewCreated(ARKitController controller) {
    arkitController = controller;
    _updateARArrow();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ARKitSceneView(
            onARKitViewCreated: onARKitViewCreated,
            showStatistics: false,
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
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
                              'AR Navigation to Home',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem(
                            icon: Icons.straighten,
                            label: 'Distance',
                            value: '${(_distanceToHome).toStringAsFixed(0)}m',
                          ),
                          _buildInfoItem(
                            icon: Icons.explore,
                            label: 'Direction',
                            value: '${_bearingToHome.toStringAsFixed(0)}°',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Follow the arrow to reach home',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
