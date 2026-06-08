import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

class UserService {
  final SupabaseClient _supabase;

  UserService(this._supabase);

  // ==================== LECTURE PROFIL ====================

  Future<AppUser?> getUserById(String uid) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', uid)
          .maybeSingle();

      if (response == null) return null;
      return _appUserFromProfileRow(response);
    } catch (e) {
      debugPrint('Error getUserById: $e');
      return null;
    }
  }

  Future<AppUser?> getUserByThixId(String thixId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('thix_id', thixId)
          .maybeSingle();

      if (response == null) return null;
      return _appUserFromProfileRow(response);
    } catch (e) {
      debugPrint('Error getUserByThixId: $e');
      return null;
    }
  }

  AppUser _appUserFromProfileRow(Map<String, dynamic> row) {
    DateTime dt(Object? v) {
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    List<String> strList(Object? v) => (v is List) 
        ? v.whereType<String>().toList(growable: false) 
        : const <String>[];
        
    List<Map<String, dynamic>> mapList(Object? v) => (v is List) 
        ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(growable: false) 
        : const <Map<String, dynamic>>[];

    final accountTypeRaw = (row['account_type'] ?? row['accountType'] ?? 'personal').toString();
    final accountType = AccountType.values.firstWhere(
      (e) => e.name == accountTypeRaw,
      orElse: () => AccountType.personal,
    );

    return AppUser(
      id: (row['user_id'] ?? row['id'] ?? '').toString(),
      thixId: (row['thix_id'] ?? 'THIX-PENDING').toString(),
      thixChat: (row['thix_chat'] ?? '').toString(),
      thixScore: (row['thix_score'] as num?)?.toInt(),
      email: row['email']?.toString() ?? '',
      phone: row['phone']?.toString(),
      displayName: (row['display_name'] ?? 'Utilisateur THIX').toString(),
      accountType: accountType,
      photoUrl: (row['photo_url'] ?? row['avatar_url'])?.toString(),
      bio: row['bio']?.toString(),
      countryOrOrigin: row['country_or_origin']?.toString(),
      contactPhone: row['contact_phone']?.toString(),
      maritalStatus: row['marital_status']?.toString(),
      gender: row['gender']?.toString(),
      occupation: (row['occupation'] ?? row['occupation_title'])?.toString(),
      profession: (row['profession'] ?? row['job_title'])?.toString(),
      dateOfBirth: row['date_of_birth']?.toString(),
      placeOfBirth: row['place_of_birth']?.toString(),
      nationality: row['nationality']?.toString(),
      address: row['address']?.toString(),
      fatherName: row['father_name']?.toString(),
      motherName: row['mother_name']?.toString(),
      emergencyContactName: row['emergency_contact_name']?.toString(),
      emergencyContactPhone: row['emergency_contact_phone']?.toString(),
      emergencyContactRelation: row['emergency_contact_relation']?.toString(),
      registrationStatus: row['registration_status']?.toString(),
      education: mapList(row['education']),
      experience: mapList(row['experience']),
      skills: mapList(row['skills']),
      enrollments: mapList(row['enrollments']),
      languages: strList(row['languages']),
      biometricsEnabled: (row['biometrics_enabled'] as bool?) ?? true,
      twoFaEnabled: (row['two_fa_enabled'] as bool?) ?? false,
      createdAt: dt(row['created_at']),
      updatedAt: dt(row['updated_at']),
    );
  }

  // ==================== MISE À JOUR PROFIL ====================

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? fullName,
    String? competence,
    String? bio,
    String? countryOrOrigin,
    String? contactPhone,
    String? maritalStatus,
    String? gender,
    String? profession,
    String? occupation,
    String? dateOfBirth,
    String? placeOfBirth,
    String? nationality,
    String? address,
    String? fatherName,
    String? motherName,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
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
    String? idDocumentFrontDocId,
    String? idDocumentBackDocId,
    String? idDocumentSelfieDocId,
    String? idVerificationStatus,
    String? thixChat,
    List<String>? languages,
    List<Map<String, dynamic>>? languagesDetailed,
    String? photoUrl,
    String? registrationStatus,
    bool? biometricsEnabled,
    bool? twoFaEnabled,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? experience,
    List<Map<String, dynamic>>? skills,
    List<Map<String, dynamic>>? emergencyContacts,
  }) async {
    final Map<String, dynamic> updates = {};

    // Informations personnelles
    if (displayName != null) updates['display_name'] = displayName;
    if (fullName != null) updates['full_name'] = fullName;
    if (competence != null) updates['competence'] = competence;
    if (bio != null) updates['bio'] = bio;
    if (countryOrOrigin != null) updates['country_or_origin'] = countryOrOrigin;
    if (contactPhone != null) updates['contact_phone'] = contactPhone;
    if (maritalStatus != null) updates['marital_status'] = maritalStatus;
    if (gender != null) updates['gender'] = gender;
    if (profession != null) updates['profession'] = profession;
    if (occupation != null) updates['occupation'] = occupation;
    if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth;
    if (placeOfBirth != null) updates['place_of_birth'] = placeOfBirth;
    if (nationality != null) updates['nationality'] = nationality;
    if (address != null) updates['address'] = address;
    if (fatherName != null) updates['father_name'] = fatherName;
    if (motherName != null) updates['mother_name'] = motherName;

    // Contacts d'urgence
    if (emergencyContactName != null) updates['emergency_contact_name'] = emergencyContactName;
    if (emergencyContactPhone != null) updates['emergency_contact_phone'] = emergencyContactPhone;
    if (emergencyContactRelation != null) updates['emergency_contact_relation'] = emergencyContactRelation;
    if (emergencyContacts != null) updates['emergency_contacts'] = emergencyContacts;

    // Origine et résidence
    if (originProvince != null) updates['origin_province'] = originProvince;
    if (originTerritory != null) updates['origin_territory'] = originTerritory;
    if (originSector != null) updates['origin_sector'] = originSector;
    if (residenceCountry != null) updates['residence_country'] = residenceCountry;
    if (residenceProvince != null) updates['residence_province'] = residenceProvince;
    if (residenceTerritory != null) updates['residence_territory'] = residenceTerritory;
    if (residenceCity != null) updates['residence_city'] = residenceCity;
    if (residenceCommune != null) updates['residence_commune'] = residenceCommune;
    if (residenceQuarter != null) updates['residence_quarter'] = residenceQuarter;
    if (residenceAvenue != null) updates['residence_avenue'] = residenceAvenue;
    if (residenceNumber != null) updates['residence_number'] = residenceNumber;

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
    if (idDocumentFrontDocId != null) updates['id_document_front_doc_id'] = idDocumentFrontDocId;
    if (idDocumentBackDocId != null) updates['id_document_back_doc_id'] = idDocumentBackDocId;
    if (idDocumentSelfieDocId != null) updates['id_document_selfie_doc_id'] = idDocumentSelfieDocId;
    if (idVerificationStatus != null) updates['id_verification_status'] = idVerificationStatus;

    // Parcours
    if (education != null) updates['education'] = education;
    if (experience != null) updates['experience'] = experience;
    if (skills != null) updates['skills'] = skills;

    // Langues
    if (languages != null) updates['languages'] = languages;
    if (languagesDetailed != null) updates['languages_detailed'] = languagesDetailed;

    // Statut
    if (registrationStatus != null) updates['registration_status'] = registrationStatus;
    if (photoUrl != null) updates['photo_url'] = photoUrl;
    if (thixChat != null) updates['thix_chat'] = thixChat;

    // Sécurité
    if (biometricsEnabled != null) updates['biometrics_enabled'] = biometricsEnabled;
    if (twoFaEnabled != null) updates['two_fa_enabled'] = twoFaEnabled;

    if (updates.isNotEmpty) {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _supabase.from('profiles').update(updates).eq('id', uid);
    }
  }

  // ==================== THIX ID ====================

  Future<String> ensureThixId({required String uid}) async {
    try {
      final row = await _supabase
          .from('profiles')
          .select('thix_id')
          .eq('id', uid)
          .maybeSingle();

      final existing = (row?['thix_id'] ?? '').toString().trim();

      if (existing.isNotEmpty && existing != 'THIX-PENDING') {
        return existing;
      }

      final candidate = 'THIX-${DateTime.now().millisecondsSinceEpoch}';
      await _supabase
          .from('profiles')
          .update({'thix_id': candidate})
          .eq('id', uid);
      return candidate;
    } catch (e) {
      debugPrint('Error ensureThixId: $e');
      rethrow;
    }
  }

  // ==================== THIX CHAT ====================

  Future<String> ensureThixChat({
    required String uid,
    required String desired,
  }) async {
    try {
      // Vérifier si déjà assigné
      final row = await _supabase
          .from('profiles')
          .select('thix_chat')
          .eq('id', uid)
          .maybeSingle();

      final existing = (row?['thix_chat'] ?? '').toString().trim();
      if (existing.isNotEmpty) return existing;

      // Valider le format
      final sanitized = desired.trim();
      if (sanitized.isEmpty) {
        throw Exception('THIX CHAT ne peut pas être vide.');
      }

      // Format: @nom (3-20 caractères alphanumériques, point ou underscore)
      if (!RegExp(r'^@[a-zA-Z0-9._]{3,20}$').hasMatch(sanitized)) {
        throw Exception('THIX CHAT invalide. Format: @suivi de 3 à 20 caractères (lettres, chiffres, . ou _)');
      }

      // Convertir en minuscules pour l'unicité
      final normalized = sanitized.toLowerCase();

      // Vérifier l'unicité
      final existingChat = await _supabase
          .from('profiles')
          .select('id')
          .eq('thix_chat', normalized)
          .maybeSingle();

      if (existingChat != null) {
        throw Exception('THIX CHAT déjà utilisé. Choisissez un autre identifiant.');
      }

      // Assigner le THIX CHAT
      await _supabase
          .from('profiles')
          .update({'thix_chat': normalized})
          .eq('id', uid);

      return normalized;
    } catch (e) {
      debugPrint('Error ensureThixChat: $e');
      rethrow;
    }
  }

  // ==================== ÉVÉNEMENTS DE SÉCURITÉ ====================

  Future<void> logSecurityEvent({
    required String uid,
    required String type,
    required String label,
  }) async {
    try {
      await _supabase.from('security_events').insert({
        'user_id': uid,
        'type': type,
        'label': label,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logSecurityEvent: $e');
    }
  }

  Future<List<Map<String, dynamic>>> streamSecurityEvents(String uid) async {
    try {
      final response = await _supabase
          .from('security_events')
          .select('*')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(50);
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      debugPrint('Error streamSecurityEvents: $e');
      return [];
    }
  }

  // ==================== PAIEMENTS ====================

  Future<void> addPaymentTransaction({
    required String uid,
    required String title,
    required double amount,
    required String currency,
    required String method,
    required String status,
  }) async {
    try {
      final txRef = 'TX_${DateTime.now().millisecondsSinceEpoch}';
      await _supabase.from('payments').insert({
        'user_id': uid,
        'tx_ref': txRef,
        'title': title,
        'amount': amount,
        'currency': currency,
        'method': method,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error addPaymentTransaction: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> streamPayments(String uid) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('*')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(50);
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      debugPrint('Error streamPayments: $e');
      return [];
    }
  }
}
