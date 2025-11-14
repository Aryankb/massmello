import 'package:flutter/material.dart';
import 'package:massmello/widgets/neomorphic_card.dart';
import 'package:massmello/services/user_service.dart';
import 'package:massmello/services/location_service.dart';
import 'package:massmello/services/sos_service.dart';
import 'package:massmello/models/user_model.dart';
import 'package:massmello/screens/ar_navigation_screen.dart';
import 'package:massmello/screens/memory_games_screen.dart';
import 'package:massmello/screens/family_contacts_screen.dart';
import 'package:massmello/screens/settings_screen.dart';
import 'package:massmello/screens/person_identification_screen.dart';
import 'package:massmello/screens/ar_object_recognition_screen.dart';
import 'package:massmello/screens/record_object_note_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _user;
  bool _isLoading = true;
  final LocationService _locationService = LocationService();
  final SOSService _sosService = SOSService();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _startLocationMonitoring();
  }

  @override
  void dispose() {
    _locationService.stopLocationTracking();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await UserService().getUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  void _startLocationMonitoring() {
    _locationService.startLocationTracking((position) async {
      await _sosService.checkLocationAndTriggerSOS(
        position.latitude,
        position.longitude,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello,',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        _user?.name ?? 'User',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withValues(alpha: 0.5)
                                : const Color(0xFFA3B1C6),
                            offset: const Offset(4, 4),
                            blurRadius: 8,
                          ),
                          BoxShadow(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white,
                            offset: const Offset(-4, -4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                '🏠 Home Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              NeomorphicCard(
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _user?.location ?? 'Not set',
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxisCount = 2;
                  if (width < 360) {
                    crossAxisCount = 1;
                  } else if (width > 800) {
                    crossAxisCount = 3;
                  }

                  double childAspectRatio;
                  if (width < 340) {
                    childAspectRatio = 0.8; // more height for very small devices
                  } else if (width < 380) {
                    childAspectRatio = 0.9;
                  } else if (width > 900) {
                    childAspectRatio = 1.2; // more compact on wide screens
                  } else {
                    childAspectRatio = 1.05;
                  }

                  final items = <Widget>[
                    _buildActionCard(
                      context,
                      icon: Icons.person_search,
                      title: 'Identify Person',
                      subtitle: 'Remember new people',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PersonIdentificationScreen()),
                        );
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.view_in_ar_outlined,
                      title: 'Object Memory',
                      subtitle: 'Scan objects to recall memories',
                      color: const Color(0xFF6C63FF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ARObjectRecognitionScreen()),
                        );
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.add_box_outlined,
                      title: 'Record Memory',
                      subtitle: 'Save new object memories',
                      color: const Color(0xFFFF6584),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RecordObjectNoteScreen()),
                        );
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.navigation_outlined,
                      title: 'AR Navigation',
                      subtitle: 'Find your way home',
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ARNavigationScreen()),
                        );
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.games_outlined,
                      title: 'Memory Games',
                      subtitle: 'Exercise your mind',
                      color: Theme.of(context).colorScheme.secondary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MemoryGamesScreen()),
                        );
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.contacts_outlined,
                      title: 'Family Contacts',
                      subtitle: 'Call your loved ones',
                      color: Theme.of(context).colorScheme.tertiary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FamilyContactsScreen()),
                        );
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.emergency_outlined,
                      title: 'Emergency',
                      subtitle: 'Quick SOS alert',
                      color: Theme.of(context).colorScheme.error,
                      onTap: () async {
                        final position = await _locationService.getCurrentPosition();
                        if (position != null) {
                          await _sosService.checkLocationAndTriggerSOS(
                            position.latitude,
                            position.longitude,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Emergency alert sent!')),
                            );
                          }
                        }
                      },
                    ),
                  ];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => items[index],
                  );
                },
              ),
              const SizedBox(height: 32),
              NeomorphicCard(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Monitoring Active',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'We\'ll alert your family if you go too far from home',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
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
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return NeomorphicCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final iconSize = w < 150 ? 40.0 : 48.0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }
}
