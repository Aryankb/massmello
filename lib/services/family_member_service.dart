import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neurolink/models/family_member_model.dart';

class FamilyMemberService {
  static const String _familyMembersKey = 'family_members';

  Future<void> addFamilyMember(FamilyMemberModel member) async {
    try {
      final members = await getFamilyMembers();
      members.add(member);
      await _saveAll(members);
    } catch (e) {
      debugPrint('Error adding family member: $e');
      rethrow;
    }
  }

  Future<List<FamilyMemberModel>> getFamilyMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final membersData = prefs.getString(_familyMembersKey);
      if (membersData == null) return [];
      
      final List<dynamic> membersList = json.decode(membersData) as List;
      return membersList.map((m) => FamilyMemberModel.fromJson(m as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting family members: $e');
      return [];
    }
  }

  Future<void> updateFamilyMember(FamilyMemberModel member) async {
    try {
      final members = await getFamilyMembers();
      final index = members.indexWhere((m) => m.id == member.id);
      if (index != -1) {
        members[index] = member.copyWith(updatedAt: DateTime.now());
        await _saveAll(members);
      }
    } catch (e) {
      debugPrint('Error updating family member: $e');
      rethrow;
    }
  }

  Future<void> deleteFamilyMember(String id) async {
    try {
      final members = await getFamilyMembers();
      members.removeWhere((m) => m.id == id);
      await _saveAll(members);
    } catch (e) {
      debugPrint('Error deleting family member: $e');
      rethrow;
    }
  }

  Future<void> _saveAll(List<FamilyMemberModel> members) async {
    final prefs = await SharedPreferences.getInstance();
    final membersData = members.map((m) => m.toJson()).toList();
    await prefs.setString(_familyMembersKey, json.encode(membersData));
  }
}
