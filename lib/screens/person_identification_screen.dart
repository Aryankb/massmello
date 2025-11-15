import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:massmello/models/person_model.dart';
import 'package:massmello/services/person_service.dart';
import 'package:massmello/widgets/neomorphic_card.dart';
import 'package:massmello/widgets/neomorphic_button.dart';
import 'package:massmello/widgets/neomorphic_text_field.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PersonIdentificationScreen extends StatefulWidget {
  const PersonIdentificationScreen({super.key});

  @override
  State<PersonIdentificationScreen> createState() => _PersonIdentificationScreenState();
}

class _PersonIdentificationScreenState extends State<PersonIdentificationScreen> {
  final PersonService _personService = PersonService();
  final ImagePicker _picker = ImagePicker();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  File? _selectedImage;
  bool _isProcessing = false;
  bool _isIdentified = false;
  PersonModel? _identifiedPerson;
  Map<String, dynamic>? _aiAnalysis;
  List<PersonModel> _savedPersons = [];
  String? _recognizedPersonName; // Name from backend API
  bool _isRecordingVoice = false;
  File? _recordedAudioFile;

  @override
  void initState() {
    super.initState();
    _loadSavedPersons();
    _initAudioRecorder();
  }

  Future<void> _initAudioRecorder() async {
    await _audioRecorder.openRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
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

      // Check if person is found in backend
      if (backendResult != null && 
          backendResult['status'] == 'success' && 
          backendResult['person_name'] != null) {
        
        final personName = backendResult['person_name'] as String;
        
        // Store the recognized person name
        setState(() {
          _recognizedPersonName = personName;
        });
        
        // Check if person exists in local storage
        final localPersons = await _personService.getAllPersons();
        PersonModel? matchedPerson;
        
        // Try to find person by matching the name
        for (var person in localPersons) {
          if (person.name.toLowerCase() == personName.toLowerCase() ||
              person.id == personName) {
            matchedPerson = person;
            break;
          }
        }
        
        if (matchedPerson != null) {
          // Person found in local storage
          setState(() {
            _isIdentified = true;
            _identifiedPerson = matchedPerson;
            _nameController.text = matchedPerson!.name;
            _relationshipController.text = matchedPerson.relationship ?? '';
            _notesController.text = matchedPerson.notes ?? '';
          });
          
          // Mark as identified
          await _personService.markPersonIdentified(matchedPerson.id);
          
          if (mounted) {
            _showPersonIdentifiedDialog(matchedPerson);
          }
        } else {
          // Person found in backend but not in local storage - pre-fill name
          setState(() {
            _nameController.text = personName;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Person recognized: $personName. Please add details to save locally.'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else if (backendResult != null && backendResult['person_id'] != null) {
        // Legacy support for old API format
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
        photoUrl: _selectedImage?.path, // Include the selected image path
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
      _recognizedPersonName = null;
      _isRecordingVoice = false;
      _recordedAudioFile = null;
      _nameController.clear();
      _relationshipController.clear();
      _notesController.clear();
    });
  }

  // Record voice for a person
  Future<void> _recordVoiceNote(String personName) async {
    // Check and request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Microphone Permission Required'),
            content: const Text(
              'This app needs microphone access to record voice notes. Please grant permission in Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (_isRecordingVoice) {
      // Stop recording
      await _stopRecording(personName);
    } else {
      // Start recording
      await _startRecording(personName);
    }
  }

  Future<void> _startRecording(String personName) async {
    try {
      // Ensure recorder is open
      if (!_audioRecorder.isRecording) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.aac';
        
        await _audioRecorder.startRecorder(
          toFile: filePath,
          codec: Codec.aacADTS,
        );
        
        setState(() {
          _isRecordingVoice = true;
          _recordedAudioFile = File(filePath);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Recording voice note for $personName...'),
                  ),
                ],
              ),
              duration: const Duration(days: 1), // Keep until stopped
              action: SnackBarAction(
                label: 'Stop',
                onPressed: () => _stopRecording(personName),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording(String personName) async {
    try {
      await _audioRecorder.stopRecorder();
      
      setState(() {
        _isRecordingVoice = false;
      });
      
      // Hide the recording snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (_recordedAudioFile != null && await _recordedAudioFile!.exists()) {
        await _uploadVoiceNote(personName, _recordedAudioFile!);
      }
    } catch (e) {
      setState(() {
        _isRecordingVoice = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    }
  }

  Future<void> _uploadVoiceNote(String personName, File audioFile) async {
    setState(() => _isProcessing = true);
    
    try {
      final result = await _personService.savePersonTranscript(
        personName: personName,
        audioFile: audioFile,
      );
      
      setState(() => _isProcessing = false);
      
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice note saved for $personName!'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => _showMemories(personName),
            ),
          ),
        );
        
        // Clean up the temp file
        try {
          await audioFile.delete();
        } catch (e) {
          debugPrint('Error deleting temp file: $e');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save voice note')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading voice note: $e')),
        );
      }
    }
  }

  // Simulate voice recording (for testing) - REMOVED, using real recording now

  // Show memories/transcripts for a person
  Future<void> _showMemories(String personName) async {
    setState(() => _isProcessing = true);
    
    try {
      final transcripts = await _personService.fetchPersonTranscripts(
        personName: personName,
      );
      
      setState(() => _isProcessing = false);
      
      if (!mounted) return;
      
      if (transcripts != null && transcripts['transcripts'] != null) {
        _showMemoriesDialog(personName, transcripts['transcripts']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No memories found for $personName')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching memories: $e')),
        );
      }
    }
  }

  // Show memories dialog
  void _showMemoriesDialog(String personName, List<dynamic> transcripts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.history, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Memories: $personName',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: transcripts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No memories recorded yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: transcripts.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final transcript = transcripts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        transcript['text'] ?? transcript['transcript'] ?? 'No text',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: transcript['timestamp'] != null
                          ? Text(
                              transcript['timestamp'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            )
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _recordVoiceNote(personName);
            },
            child: const Text('Add Memory'),
          ),
        ],
      ),
    );
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
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
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
                      // Show Memories button when person is recognized
                      if (_recognizedPersonName != null) ...[
                        const SizedBox(height: 16),
                        NeomorphicButton(
                          onPressed: _isProcessing 
                              ? () {} 
                              : () => _showMemories(_recognizedPersonName!),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Show Memories for: $_recognizedPersonName',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
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
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${person.identifiedDates.length}x',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              IconButton(
                                icon: Icon(
                                  Icons.mic,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                onPressed: () => _recordVoiceNote(person.name),
                                tooltip: 'Record Voice Note',
                              ),
                            ],
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
