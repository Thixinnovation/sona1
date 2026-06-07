import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/market_chat.dart';

class MarketChatService {
  final SupabaseClient _supabase;

  MarketChatService(this._supabase);

  Future<MarketConversation> getOrCreateConversation({
    required String productId,
    required String productTitle,
    required String productImage,
    required String sellerId,
    required String sellerName,
    required String sellerAvatar,
    required String buyerId,
    required String buyerName,
    required String buyerAvatar,
  }) async {
    try {
      final existing = await _supabase
          .from('market_conversations')
          .select('*')
          .eq('product_id', productId)
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId)
          .maybeSingle();

      if (existing != null) {
        return MarketConversation.fromJson(existing);
      }

      final newConversation = {
        'product_id': productId,
        'product_title': productTitle,
        'product_image': productImage,
        'buyer_id': buyerId,
        'buyer_name': buyerName,
        'buyer_avatar': buyerAvatar,
        'seller_id': sellerId,
        'seller_name': sellerName,
        'seller_avatar': sellerAvatar,
        'last_message': 'Début de la conversation',
        'last_message_at': DateTime.now().toIso8601String(),
        'is_active': true,
      };

      final response = await _supabase
          .from('market_conversations')
          .insert(newConversation)
          .select();
      
      return MarketConversation.fromJson((response as List).first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      rethrow;
    }
  }

  Future<MarketMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String message,
    String? imageUrl,
  }) async {
    try {
      final newMessage = {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_avatar': senderAvatar,
        'message': message,
        'image_url': imageUrl,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('market_messages')
          .insert(newMessage)
          .select();
      
      final sentMessage = MarketMessage.fromJson((response as List).first as Map<String, dynamic>);

      await _supabase
          .from('market_conversations')
          .update({
            'last_message': message,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);

      return sentMessage;
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      await _supabase
          .from('market_messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId);
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Stream<List<MarketMessage>> getMessages(String conversationId) {
    return _supabase
        .from('market_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((list) => list
            .map((e) => MarketMessage.fromJson(e as Map<String, dynamic>))
            .toList());
  }

  Future<List<MarketConversation>> getUserConversations(String userId) async {
    try {
      final response = await _supabase
          .from('market_conversations')
          .select('*')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .eq('is_active', true)
          .order('last_message_at', ascending: false);
      
      return (response as List)
          .map((e) => MarketConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      return [];
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final conversations = await _supabase
          .from('market_conversations')
          .select('id')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId');
      
      int totalUnread = 0;
      for (final conv in conversations as List) {
        final convMap = conv as Map<String, dynamic>;
        final unread = await _supabase
            .from('market_messages')
            .select('id', count: CountOption.exact)
            .eq('conversation_id', convMap['id'])
            .eq('is_read', false)
            .neq('sender_id', userId);
        totalUnread += unread.count ?? 0;
      }
      return totalUnread;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _supabase
          .from('market_conversations')
          .update({'is_active': false})
          .eq('id', conversationId);
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
    }
  }
}
