import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:neurolink/widgets/neomorphic_card.dart';
import 'package:neurolink/widgets/neomorphic_text_field.dart';
import 'package:neurolink/widgets/neomorphic_button.dart';
import 'package:neurolink/services/family_member_service.dart';
import 'package:neurolink/models/family_member_model.dart';
import 'package:url_launcher/url_launcher.dart';

class FamilyContactsScreen extends StatefulWidget {
  const FamilyContactsScreen({super.key});

  @override
  State<FamilyContactsScreen> createState() => _FamilyContactsScreenState();
}

class _FamilyContactsScreenState extends State<FamilyContactsScreen> {
  List<FamilyMemberModel> _familyMembers = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _relationshipCtrl = TextEditingController();
  FamilyMemberModel? _editingMember;

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    final members = await FamilyMemberService().getFamilyMembers();
    setState(() {
      _familyMembers = members;
      _isLoading = false;
    });
  }

  Future<void> _makeCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cannot make phone call'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _relationshipCtrl.dispose();
    super.dispose();
  }

  Future<void> _showMemberForm({FamilyMemberModel? member}) async {
    setState(() {
      _editingMember = member;
    });
    if (member != null) {
      _nameCtrl.text = member.name;
      _phoneCtrl.text = member.phoneNumber;
      _relationshipCtrl.text = member.relationship;
    } else {
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _relationshipCtrl.clear();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  member == null ? 'Add Family Member' : 'Edit Family Member',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      NeomorphicTextField(
                        controller: _nameCtrl,
                        labelText: 'Full Name',
                        hintText: 'e.g., Jane Doe',
                        prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 14),
                      NeomorphicTextField(
                        controller: _relationshipCtrl,
                        labelText: 'Relationship',
                        hintText: 'e.g., Daughter',
                        prefixIcon: Icon(Icons.favorite_outline, color: Theme.of(context).colorScheme.tertiary),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Relationship is required' : null,
                      ),
                      const SizedBox(height: 14),
                      NeomorphicTextField(
                        controller: _phoneCtrl,
                        labelText: 'Phone Number',
                        hintText: 'e.g., +1 555 123 4567',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icon(Icons.phone_outlined, color: Theme.of(context).colorScheme.primary),
                        validator: (v) {
                          final val = v?.trim() ?? '';
                          if (val.isEmpty) return 'Phone number is required';
                          if (val.length < 7) return 'Enter a valid phone number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: NeomorphicButton(
                              onPressed: () => Navigator.of(ctx).maybePop(),
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              child: Text(
                                'Cancel',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: NeomorphicButton(
                              onPressed: () async {
                                if (!(_formKey.currentState?.validate() ?? false)) return;
                                try {
                                  if (_editingMember == null) {
                                    final now = DateTime.now();
                                    final newMember = FamilyMemberModel(
                                      id: now.millisecondsSinceEpoch.toString(),
                                      userId: 'local-user',
                                      name: _nameCtrl.text.trim(),
                                      phoneNumber: _phoneCtrl.text.trim(),
                                      relationship: _relationshipCtrl.text.trim(),
                                      imagePath: null,
                                      createdAt: now,
                                      updatedAt: now,
                                    );
                                    await FamilyMemberService().addFamilyMember(newMember);
                                  } else {
                                    final updated = _editingMember!.copyWith(
                                      name: _nameCtrl.text.trim(),
                                      phoneNumber: _phoneCtrl.text.trim(),
                                      relationship: _relationshipCtrl.text.trim(),
                                      updatedAt: DateTime.now(),
                                    );
                                    await FamilyMemberService().updateFamilyMember(updated);
                                  }
                                  if (mounted) {
                                    Navigator.of(ctx).maybePop();
                                    await _loadFamilyMembers();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(_editingMember == null ? 'Member added' : 'Member updated'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Save member error: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Failed to save. Please try again.'),
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }
                                } finally {
                                  setState(() => _editingMember = null);
                                }
                              },
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check, color: Theme.of(context).colorScheme.onPrimary),
                                  const SizedBox(width: 8),
                                  Text(
                                    member == null ? 'Add' : 'Save',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(FamilyMemberModel member) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Remove Member',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to remove ${member.name}?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: NeomorphicButton(
                      onPressed: () => Navigator.of(ctx).maybePop(),
                      child: Text('Cancel', style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeomorphicButton(
                      onPressed: () async {
                        try {
                          await FamilyMemberService().deleteFamilyMember(member.id);
                          if (mounted) {
                            Navigator.of(ctx).maybePop();
                            await _loadFamilyMembers();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Member removed')),
                            );
                          }
                        } catch (e) {
                          debugPrint('Delete member error: $e');
                        }
                      },
                      backgroundColor: Theme.of(context).colorScheme.error,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onError),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onError,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
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
        title: Text(
          'Family Contacts',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _familyMembers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No family members added yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: NeomorphicButton(
                          onPressed: () => _showMemberForm(),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_alt_1, color: Theme.of(context).colorScheme.onPrimary),
                              const SizedBox(width: 8),
                              Text(
                                'Add Member',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Loved Ones',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to call',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _familyMembers.length,
                        itemBuilder: (context, index) {
                          final member = _familyMembers[index];
                          return NeomorphicCard(
                            onTap: () => _makeCall(member.phoneNumber),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 32,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.name,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        member.relationship,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        member.phoneNumber,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.tertiary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.phone,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () => _showMemberForm(member: member),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
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
                                          Icons.edit_outlined,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () => _confirmDelete(member),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
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
                                          Icons.delete_outline,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: NeomorphicButton(
          onPressed: () => _showMemberForm(),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_alt_1, color: Theme.of(context).colorScheme.onPrimary),
              const SizedBox(width: 8),
              Text(
                'Add Member',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
