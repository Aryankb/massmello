import 'package:flutter/material.dart';
import 'package:neurolink/widgets/neomorphic_button.dart';
import 'package:neurolink/widgets/neomorphic_text_field.dart';
import 'package:neurolink/screens/onboarding/photos_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class LocationScreen extends StatefulWidget {
  final String name;

  const LocationScreen({super.key, required this.name});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _geocodeAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // final locations = await locationFromAddress(_locationController.text);
      if (true) {
        setState(() {
          // _latitude = locations.first.latitude;
          // _longitude = locations.first.longitude;
          _latitude = 21.133;
          _longitude = 81.758;

          _isLoading = false;
        });
        _continue();
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not find location. Please try a different address.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _continue() {
    if (_latitude != null && _longitude != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhotosScreen(
            name: widget.name,
            location: _locationController.text,
            latitude: _latitude!,
            longitude: _longitude!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Icon(
                    Icons.home_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Where is home?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tell us your home address so we can help you navigate back safely.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 40),
                NeomorphicTextField(
                  controller: _locationController,
                  labelText: 'Home Address',
                  hintText: 'Enter your full address',
                  prefixIcon: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your home address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                NeomorphicButton(
                  onPressed: _isLoading ? () {} : _geocodeAddress,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Continue',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepIndicator(false),
                      const SizedBox(width: 8),
                      _buildStepIndicator(true),
                      const SizedBox(width: 8),
                      _buildStepIndicator(false),
                      const SizedBox(width: 8),
                      _buildStepIndicator(false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isActive) {
    return Container(
      width: isActive ? 32 : 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
