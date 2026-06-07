import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_item.dart';

// ============================================================================
// Model EventRegistration (intégré dans le même fichier)
// ============================================================================
class EventRegistration {
  final String id;
  final String userId;
  final String eventId;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  
  // Propriétés supplémentaires pour le billet
  final String ticketCode;
  final String attendeeThixId;
  final int tickets;

  // Constructeur nommé
  EventRegistration({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    required this.createdAt,
    this.metadata,
    this.ticketCode = '',
    this.attendeeThixId = '',
    this.tickets = 1,
  });

  // Constructeur positionnel pour compatibilité
  EventRegistration.positional(
    this.id,
    this.userId,
    this.eventId,
    this.status,
    this.createdAt,
    this.metadata,
    this.ticketCode,
    this.attendeeThixId,
    this.tickets,
  );

  factory EventRegistration.fromJson(Map<String, dynamic> json) {
    final String id = json['id'].toString();
    final String userId = json['user_id'].toString();
    
    String ticketCode = json['ticket_code'] ?? '';
    if (ticketCode.isEmpty) {
      ticketCode = 'THIX-${id.substring(0, id.length > 8 ? 8 : id.length).toUpperCase()}';
    }
    
    String attendeeThixId = json['attendee_thix_id'] ?? '';
    if (attendeeThixId.isEmpty) {
      attendeeThixId = userId.substring(0, userId.length > 8 ? 8 : userId.length);
    }
    
    int tickets = 1;
    if (json['tickets'] != null) {
      if (json['tickets'] is int) {
        tickets = json['tickets'] as int;
      } else if (json['tickets'] is String) {
        tickets = int.tryParse(json['tickets'] as String) ?? 1;
      }
    } else if (json['metadata'] != null && json['metadata']['tickets'] != null) {
      final metaTickets = json['metadata']['tickets'];
      if (metaTickets is int) {
        tickets = metaTickets;
      } else if (metaTickets is String) {
        tickets = int.tryParse(metaTickets) ?? 1;
      }
    }
    
    return EventRegistration(
      id: id,
      userId: userId,
      eventId: json['event_id'].toString(),
      status: json['status'] ?? 'confirmed',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : null,
      ticketCode: ticketCode,
      attendeeThixId: attendeeThixId,
      tickets: tickets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
      'ticket_code': ticketCode,
      'attendee_thix_id': attendeeThixId,
      'tickets': tickets,
    };
  }
  
  String get note => metadata?['note'] ?? '';
  int get ticketsFromMetadata => metadata?['tickets'] ?? tickets;
}

// ============================================================================
// EventService
// ============================================================================
class EventService {
  final SupabaseClient _supabase;
  static const String eventsTable = 'events';
  static const String registrationsTable = 'event_registrations';

  // Constructeur qui accepte les deux types d'appel
  EventService([SupabaseClient? client])
      : _supabase = client ?? Supabase.instance.client;

  // -------------------- EVENTS --------------------
  Future<EventItem?> getEventById(String eventId) async {
    try {
      final data = await _supabase.from(eventsTable).select().eq('id', eventId).single();
      return EventItem.fromJson(data);
    } catch (e) {
      debugPrint('getEventById error: $e');
      return null;
    }
  }

  Future<List<EventItem>> getAllEvents() async {
    try {
      final data = await _supabase.from(eventsTable).select().order('starts_at');
      return (data as List).map((e) => EventItem.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getAllEvents error: $e');
      return [];
    }
  }

  // -------------------- REGISTRATIONS --------------------
  Future<bool> hasUserTicket(String userId, String eventId) async {
    try {
      final res = await _supabase
          .from(registrationsTable)
          .select('id')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .eq('status', 'confirmed')
          .limit(1);
      return res.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> registerForEvent({
    required String userId,
    required String eventId,
    int tickets = 1,
    String? note,
  }) async {
    try {
      final ticketCode = _generateTicketCode();
      final attendeeThixId = _generateAttendeeId(userId);
      
      await _supabase.from(registrationsTable).insert({
        'user_id': userId,
        'event_id': eventId,
        'status': 'confirmed',
        'ticket_code': ticketCode,
        'attendee_thix_id': attendeeThixId,
        'tickets': tickets,
        'metadata': {
          'tickets': tickets,
          'note': note ?? '',
        },
      });
      return true;
    } catch (e) {
      debugPrint('registerForEvent error: $e');
      return false;
    }
  }

  Future<EventRegistration?> createRegistration({
    required String userId,
    required String eventId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final tickets = metadata?['tickets'] ?? 1;
      final note = metadata?['note'] ?? '';
      final ticketCode = _generateTicketCode();
      final attendeeThixId = _generateAttendeeId(userId);
      
      final res = await _supabase.from(registrationsTable).insert({
        'user_id': userId,
        'event_id': eventId,
        'status': 'confirmed',
        'ticket_code': ticketCode,
        'attendee_thix_id': attendeeThixId,
        'tickets': tickets,
        'metadata': {
          'tickets': tickets,
          'note': note,
          ...?metadata,
        },
      }).select().single();
      return EventRegistration.fromJson(res);
    } catch (e) {
      debugPrint('createRegistration error: $e');
      return null;
    }
  }

  Future<EventRegistration?> getRegistrationById(String registrationId) async {
    try {
      final data = await _supabase
          .from(registrationsTable)
          .select()
          .eq('id', registrationId)
          .single();
      return EventRegistration.fromJson(data);
    } catch (e) {
      debugPrint('getRegistrationById error: $e');
      return null;
    }
  }

  Future<bool> cancelRegistration(String registrationId) async {
    try {
      await _supabase
          .from(registrationsTable)
          .update({'status': 'cancelled'})
          .eq('id', registrationId);
      return true;
    } catch (e) {
      debugPrint('cancelRegistration error: $e');
      return false;
    }
  }

  Future<List<EventRegistration>> getUserRegistrations(String userId) async {
    try {
      final data = await _supabase
          .from(registrationsTable)
          .select()
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .order('created_at', ascending: false);
      return (data as List).map((e) => EventRegistration.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getUserRegistrations error: $e');
      return [];
    }
  }
  
  Future<List<EventRegistration>> getAllUserRegistrations(String userId) async {
    try {
      final data = await _supabase
          .from(registrationsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => EventRegistration.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getAllUserRegistrations error: $e');
      return [];
    }
  }

  Future<bool> updateRegistrationStatus(String registrationId, String status) async {
    try {
      await _supabase
          .from(registrationsTable)
          .update({'status': status})
          .eq('id', registrationId);
      return true;
    } catch (e) {
      debugPrint('updateRegistrationStatus error: $e');
      return false;
    }
  }

  // Méthode validatePromoCode pour event_checkout_page.dart
  Future<bool> validatePromoCode(String code, String eventId) async {
    try {
      final result = await _supabase
          .from('promo_codes')
          .select()
          .eq('code', code.toUpperCase())
          .eq('event_id', eventId)
          .eq('is_active', true)
          .maybeSingle();
      
      if (result == null) return false;
      
      final expiresAt = result['expires_at'];
      if (expiresAt != null) {
        final expiryDate = DateTime.tryParse(expiresAt.toString());
        if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
          return false;
        }
      }
      
      final maxUses = result['max_uses'] as int?;
      final currentUses = result['current_uses'] as int? ?? 0;
      
      if (maxUses != null && currentUses >= maxUses) {
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('validatePromoCode error: $e');
      return false;
    }
  }
  
  // Méthodes utilitaires privées
  String _generateTicketCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    String code = 'THIX-';
    for (int i = 0; i < 8; i++) {
      final index = (random.hashCode + i * 31) % chars.length;
      code += chars[index.abs()];
    }
    return code;
  }
  
  String _generateAttendeeId(String userId) {
    if (userId.length >= 8) {
      return userId.substring(0, 8).toUpperCase();
    }
    return userId.padRight(8, '0').toUpperCase();
  }
}
