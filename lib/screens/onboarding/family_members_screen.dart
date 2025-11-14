import 'package:flutter/material.dart';
import 'package:neurolink/widgets/neomorphic_button.dart';
import 'package:neurolink/widgets/neomorphic_text_field.dart';
import 'package:neurolink/widgets/neomorphic_card.dart';
import 'package:neurolink/models/user_model.dart';
import 'package:neurolink/models/family_member_model.dart';
import 'package:neurolink/models/sos_settings_model.dart';
import 'package:neurolink/services/user_service.dart';
import 'package:neurolink/services/family_member_service.dart';
import 'package:neurolink/services/sos_service.dart';
import 'package:neurolink/screens/home_screen.dart';

class FamilyMembersScreen extends StatefulWidget {
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final List<String> imagePaths;

  const FamilyMembersScreen({
    super.key,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.imagePaths,
  });

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final List<Map<String, String>> _familyMembers = [];
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  void _addMember() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _familyMembers.add({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'relation': _relationController.text,
        });
        _nameController.clear();
        _phoneController.clear();
        _relationController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Family member added'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
    }
  }

  void _removeMember(int index) {
    setState(() => _familyMembers.removeAt(index));
  }

  Future<void> _complete() async {
    if (_familyMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add at least one family member'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final user = UserModel(
        id: userId,
        name: widget.name,
        location: widget.location,
        homeLatitude: widget.latitude,
        homeLongitude: widget.longitude,
        profileImages: widget.imagePaths,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await UserService().saveUser(user);

      final familyService = FamilyMemberService();
      for (final member in _familyMembers) {
        final familyMember = FamilyMemberModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          name: member['name']!,
          phoneNumber: member['phone']!,
          relationship: member['relation']!,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await familyService.addFamilyMember(familyMember);
      }

      final sosSettings = SOSSettingsModel(
        userId: userId,
        homeLatitude: widget.latitude,
        homeLongitude: widget.longitude,
        radius: 500,
        isEnabled: true,
        backendUrl: 'http://localhost:8000',
      );
      await SOSService().saveSOSSettings(sosSettings);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
        child: Column(
          children: [
            Expanded(
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
                          Icons.people_outline,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Add Family Members',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Add at least one family member for emergency contacts.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 32),
                      NeomorphicTextField(
                        controller: _nameController,
                        labelText: 'Name',
                        hintText: 'Enter name',
                        prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                        validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      NeomorphicTextField(
                        controller: _phoneController,
                        labelText: 'Phone Number',
                        hintText: 'Enter phone number',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                        validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      NeomorphicTextField(
                        controller: _relationController,
                        labelText: 'Relationship',
                        hintText: 'e.g., Son, Daughter, Spouse',
                        prefixIcon: Icon(Icons.favorite, color: Theme.of(context).colorScheme.primary),
                        validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      NeomorphicButton(
                        onPressed: _addMember,
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Add Member',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_familyMembers.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Text(
                          'Added Members (${_familyMembers.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _familyMembers.length,
                          itemBuilder: (context, index) {
                            final member = _familyMembers[index];
                            return NeomorphicCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member['name']!,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          member['relation']!,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          member['phone']!,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                                    onPressed: () => _removeMember(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  NeomorphicButton(
                    onPressed: _isLoading ? () {} : _complete,
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
                            'Complete Setup',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStepIndicator(false),
                        const SizedBox(width: 8),
                        _buildStepIndicator(false),
                        const SizedBox(width: 8),
                        _buildStepIndicator(false),
                        const SizedBox(width: 8),
                        _buildStepIndicator(true),
                      ],
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
