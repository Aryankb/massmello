import 'package:flutter/material.dart';
import 'package:neurolink/widgets/neomorphic_button.dart';
import 'package:neurolink/widgets/neomorphic_text_field.dart';
import 'package:neurolink/screens/onboarding/location_screen.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationScreen(name: _nameController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Icon(
                    Icons.person_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome to NeuroLink',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Let's start by getting to know you better. What is your name?",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 40),
                NeomorphicTextField(
                  controller: _nameController,
                  labelText: 'Your Name',
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                NeomorphicButton(
                  onPressed: _continue,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
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
                      _buildStepIndicator(true),
                      const SizedBox(width: 8),
                      _buildStepIndicator(false),
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
