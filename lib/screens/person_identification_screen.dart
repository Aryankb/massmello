import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:massmello/models/person_model.dart';
import 'package:massmello/services/person_service.dart';
import 'package:massmello/widgets/neomorphic_card.dart';
import 'package:massmello/widgets/neomorphic_button.dart';
import 'package:massmello/widgets/neomorphic_text_field.dart';

class PersonIdentificationScreen extends StatefulWidget {
  const PersonIdentificationScreen({super.key});

  @override
  State<PersonIdentificationScreen> createState() => _PersonIdentificationScreenState();
}

class _PersonIdentificationScreenState extends State<PersonIdentificationScreen> {
  final PersonService _personService = PersonService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  File? _selectedImage;
  bool _isProcessing = false;
  bool _isIdentified = false;
  PersonModel? _identifiedPerson;
  Map<String, dynamic>? _aiAnalysis;
  List<PersonModel> _savedPersons = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPersons();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPersons() async {
    final persons = await _personService.getAllPersons();
    setState(() {
      _savedPersons = persons;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isIdentified = false;
          _identifiedPerson = null;
          _aiAnalysis = null;
        });
        await _processImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Call backend API to check if person exists
      final backendResult = await _personService.checkPersonWithBackend(_selectedImage!);
      
      // Analyze with AI
      final aiResult = await _personService.analyzePersonWithAI(
        _selectedImage!,
        'Identify this person for memory assistance',
      );

      setState(() {
        _aiAnalysis = aiResult;
        _isProcessing = false;
      });

      // Check if person is already in database
      if (backendResult != null && backendResult['person_id'] != null) {
        final person = await _personService.getPerson(backendResult['person_id']);
        if (person != null) {
          setState(() {
            _isIdentified = true;
            _identifiedPerson = person;
            _nameController.text = person.name;
            _relationshipController.text = person.relationship ?? '';
            _notesController.text = person.notes ?? '';
          });
          
          // Mark as identified
          await _personService.markPersonIdentified(person.id);
          
          if (mounted) {
            _showPersonIdentifiedDialog(person);
          }
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    }
  }

  void _showPersonIdentifiedDialog(PersonModel person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text('Person Identified!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              person.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (person.relationship != null) ...[
              const SizedBox(height: 8),
              Text(
                person.relationship!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
            if (person.notes != null) ...[
              const SizedBox(height: 12),
              Text(person.notes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePerson() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final person = PersonModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        relationship: _relationshipController.text.trim().isEmpty
            ? null
            : _relationshipController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        addedDate: DateTime.now(),
        aiAnalysis: _aiAnalysis,
        identifiedDates: [DateTime.now().toIso8601String()],
      );

      await _personService.savePerson(person);
      await _loadSavedPersons();

      setState(() {
        _isProcessing = false;
        _isIdentified = true;
        _identifiedPerson = person;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Person saved successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving person: $e')),
        );
      }
    }
  }

  void _reset() {
    setState(() {
      _selectedImage = null;
      _isIdentified = false;
      _identifiedPerson = null;
      _aiAnalysis = null;
      _nameController.clear();
      _relationshipController.clear();
      _notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Identify Person'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Selection Section
              NeomorphicCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (_selectedImage == null) ...[
                      Icon(
                        Icons.person_add,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Take or select a photo',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Help remember this person',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _selectedImage!,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (_isProcessing) ...[
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        const Text('Analyzing...'),
                      ],
                      if (_aiAnalysis != null && !_isIdentified) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.psychology, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _aiAnalysis!['analysis'] ?? 'Person detected',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              if (_selectedImage == null) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: NeomorphicButton(
                        onPressed: () => _pickImage(ImageSource.camera),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            const Text('Camera'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: NeomorphicButton(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            const Text('Gallery'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Person Details Form
              if (_selectedImage != null && !_isIdentified) ...[
                const SizedBox(height: 24),
                Text(
                  'Person Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                NeomorphicTextField(
                  controller: _nameController,
                  hintText: 'Name*',
                  prefixIcon: const Icon(Icons.person),
                ),
                const SizedBox(height: 16),
                NeomorphicTextField(
                  controller: _relationshipController,
                  hintText: 'Relationship (e.g., Friend, Family)',
                  prefixIcon: const Icon(Icons.people),
                ),
                const SizedBox(height: 16),
                NeomorphicTextField(
                  controller: _notesController,
                  hintText: 'Notes (e.g., Met at park, likes gardening)',
                  prefixIcon: const Icon(Icons.notes),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                NeomorphicButton(
                  onPressed: _isProcessing ? () {} : _savePerson,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Person'),
                ),
              ],

              // Success Message
              if (_isIdentified && _identifiedPerson != null) ...[
                const SizedBox(height: 24),
                NeomorphicCard(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Person Remembered!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _identifiedPerson!.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (_identifiedPerson!.relationship != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _identifiedPerson!.relationship!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Saved Persons List
              if (_savedPersons.isNotEmpty) ...[
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remembered Persons',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_savedPersons.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _savedPersons.length > 5 ? 5 : _savedPersons.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final person = _savedPersons[index];
                    return NeomorphicCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              person.name[0].toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  person.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (person.relationship != null)
                                  Text(
                                    person.relationship!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${person.identifiedDates.length}x',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
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
    );
  }
}
