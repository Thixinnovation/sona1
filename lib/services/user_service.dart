import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

class UserService {
  final SupabaseClient _supabase;

  UserService(this._supabase);

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? fullName,
    String? photoUrl,
    String? registrationStatus,
    String? thixChat,
    String? bio,
    String? competence,
    String? countryOrOrigin,
    String? contactPhone,
    String? dateOfBirth,
    String? placeOfBirth,
    String? nationality,
    String? maritalStatus,
    String? gender,
    String? occupation,
    String? address,
    String? fatherName,
    String? motherName,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? experience,
    // ===== NOUVEAUX PARAMÈTRES =====
    String? originProvince,
    String? originTerritory,
    String? originSector,
    String? residenceCountry,
    String? residenceProvince,
    String? residenceTerritory,
    String? residenceCity,
    String? residenceCommune,
    String? residenceQuarter,
    String? residenceAvenue,
    String? residenceNumber,
    List<Map<String, dynamic>>? emergencyContacts,
    String? height,
    String? weight,
    String? bloodGroup,
    bool? hasPhysicalDisability,
    String? physicalDisabilityDescription,
    String? nationalIdNumber,
    String? idDocumentType,
    String? idDocumentIssueDate,
    String? idDocumentExpiryDate,
    String? idDocumentIssuePlace,
  }) async {
    final Map<String, dynamic> updates = {};
    
    // Informations personnelles
    if (displayName != null) updates['display_name'] = displayName;
    if (fullName != null) updates['full_name'] = fullName;
    if (photoUrl != null) updates['photo_url'] = photoUrl;
    if (registrationStatus != null) updates['registration_status'] = registrationStatus;
    if (thixChat != null) updates['thix_chat'] = thixChat;
    if (bio != null) updates['bio'] = bio;
    if (competence != null) updates['competence'] = competence;
    if (countryOrOrigin != null) updates['country_or_origin'] = countryOrOrigin;
    if (contactPhone != null) updates['contact_phone'] = contactPhone;
    if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth;
    if (placeOfBirth != null) updates['place_of_birth'] = placeOfBirth;
    if (nationality != null) updates['nationality'] = nationality;
    if (maritalStatus != null) updates['marital_status'] = maritalStatus;
    if (gender != null) updates['gender'] = gender;
    if (occupation != null) updates['occupation'] = occupation;
    if (address != null) updates['address'] = address;
    if (fatherName != null) updates['father_name'] = fatherName;
    if (motherName != null) updates['mother_name'] = motherName;
    if (emergencyContactName != null) updates['emergency_contact_name'] = emergencyContactName;
    if (emergencyContactPhone != null) updates['emergency_contact_phone'] = emergencyContactPhone;
    if (emergencyContactRelation != null) updates['emergency_contact_relation'] = emergencyContactRelation;
    if (education != null) updates['education'] = education;
    if (experience != null) updates['experience'] = experience;
    
    // Origine
    if (originProvince != null) updates['origin_province'] = originProvince;
    if (originTerritory != null) updates['origin_territory'] = originTerritory;
    if (originSector != null) updates['origin_sector'] = originSector;
    
    // Résidence
    if (residenceCountry != null) updates['residence_country'] = residenceCountry;
    if (residenceProvince != null) updates['residence_province'] = residenceProvince;
    if (residenceTerritory != null) updates['residence_territory'] = residenceTerritory;
    if (residenceCity != null) updates['residence_city'] = residenceCity;
    if (residenceCommune != null) updates['residence_commune'] = residenceCommune;
    if (residenceQuarter != null) updates['residence_quarter'] = residenceQuarter;
    if (residenceAvenue != null) updates['residence_avenue'] = residenceAvenue;
    if (residenceNumber != null) updates['residence_number'] = residenceNumber;
    
    // Contacts d'urgence
    if (emergencyContacts != null) updates['emergency_contacts'] = emergencyContacts;
    
    // Informations physiques
    if (height != null) updates['height'] = height;
    if (weight != null) updates['weight'] = weight;
    if (bloodGroup != null) updates['blood_group'] = bloodGroup;
    if (hasPhysicalDisability != null) updates['has_physical_disability'] = hasPhysicalDisability;
    if (physicalDisabilityDescription != null) updates['physical_disability_description'] = physicalDisabilityDescription;
    
    // Documents d'identité
    if (nationalIdNumber != null) updates['national_id_number'] = nationalIdNumber;
    if (idDocumentType != null) updates['id_document_type'] = idDocumentType;
    if (idDocumentIssueDate != null) updates['id_document_issue_date'] = idDocumentIssueDate;
    if (idDocumentExpiryDate != null) updates['id_document_expiry_date'] = idDocumentExpiryDate;
    if (idDocumentIssuePlace != null) updates['id_document_issue_place'] = idDocumentIssuePlace;

    if (updates.isNotEmpty) {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _supabase.from('profiles').update(updates).eq('id', uid);
    }
  }

  Future<String> ensureThixId({required String uid}) async {
    final row = await _supabase.from('profiles').select('thix_id').eq('id', uid).maybeSingle();
    final existing = (row?['thix_id'] ?? '').toString().trim();
    if (existing.isNotEmpty && existing != 'THIX-PENDING') return existing;
    final candidate = 'THIX-${DateTime.now().millisecondsSinceEpoch}';
    await _supabase.from('profiles').update({'thix_id': candidate}).eq('id', uid);
    return candidate;
  }

  Future<String> ensureThixChat({required String uid, required String desired}) async {
    final normalized = desired.trim().toLowerCase();
    await _supabase.from('profiles').update({'thix_chat': normalized}).eq('id', uid);
    return normalized;
  }
}
