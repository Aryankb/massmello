import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' show sin, cos;
import 'package:neurolink/services/user_service.dart';
import 'package:neurolink/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class ARNavigationScreen extends StatefulWidget {
  const ARNavigationScreen({super.key});

  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  double? _homeLatitude;
  double? _homeLongitude;
  Position? _currentPosition;
  double? _compassHeading;
  double _distanceToHome = 0;
  double _bearingToHome = 0;
  
  Timer? _updateTimer;
  final LocationService _locationService = LocationService();
  StreamSubscription<CompassEvent>? _compassSubscription;
  ARNode? _arrowNode;

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
    arSessionManager?.dispose();
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
        _currentPosition = position;
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
    if (arObjectManager == null || _compassHeading == null) return;

    final adjustedBearing = (_bearingToHome - _compassHeading!) % 360;
    final radians = adjustedBearing * (3.14159 / 180);

    if (_arrowNode != null) {
      arObjectManager?.removeNode(_arrowNode!);
    }

    final distance = 2.0;
    final x = distance * sin(radians);
    final z = -distance * cos(radians);

    _arrowNode = ARNode(
      type: NodeType.webGLB,
      uri: "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Triangle/glTF/Triangle.gltf",
      scale: vector.Vector3(0.3, 0.3, 0.3),
      position: vector.Vector3(x, -0.5, z),
      rotation: vector.Vector4(0, 1, 0, radians),
    );

    arObjectManager?.addNode(_arrowNode!).catchError((error) {
      debugPrint('Error adding AR node: $error');
    });
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: false,
      showWorldOrigin: false,
      handlePans: false,
      handleRotation: false,
    );
    
    this.arObjectManager!.onInitialize();
    _updateARArrow();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.none,
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
