import 'package:flutter/material.dart';
import 'package:neurolink/widgets/neomorphic_card.dart';
import 'package:neurolink/widgets/neomorphic_text_field.dart';
import 'package:neurolink/widgets/neomorphic_button.dart';
import 'package:neurolink/services/sos_service.dart';
import 'package:neurolink/models/sos_settings_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _radiusController = TextEditingController();
  final _backendUrlController = TextEditingController();
  bool _isEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _backendUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await SOSService().getSOSSettings();
    if (settings != null) {
      setState(() {
        _radiusController.text = settings.radius.toString();
        _backendUrlController.text = settings.backendUrl;
        _isEnabled = settings.isEnabled;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final settings = await SOSService().getSOSSettings();
    if (settings != null) {
      final updatedSettings = settings.copyWith(
        radius: double.tryParse(_radiusController.text) ?? 500,
        backendUrl: _backendUrlController.text,
        isEnabled: _isEnabled,
      );
      await SOSService().updateSOSSettings(updatedSettings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Settings saved successfully'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    }
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SOS Settings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure emergency alert settings',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            NeomorphicCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable SOS Monitoring',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Monitor location and send alerts',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isEnabled,
                    onChanged: (value) => setState(() => _isEnabled = value),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Alert Radius (meters)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            NeomorphicTextField(
              controller: _radiusController,
              keyboardType: TextInputType.number,
              hintText: 'e.g., 500',
              prefixIcon: Icon(Icons.radio_button_checked, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Backend URL',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            NeomorphicTextField(
              controller: _backendUrlController,
              hintText: 'http://localhost:8000',
              prefixIcon: Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 32),
            NeomorphicButton(
              onPressed: _saveSettings,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Save Settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
