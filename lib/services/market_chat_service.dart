import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =====================================================
// MODÈLES
// =====================================================

class MarketConversation {
  final String id;
  final String productId;
  final String productTitle;
  final String productImage;
  final String buyerId;
  final String buyerName;
  final String buyerAvatar;
  final String sellerId;
  final String sellerName;
  final String sellerAvatar;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isActive;

  MarketConversation({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productImage,
    required this.buyerId,
    required this.buyerName,
    required this.buyerAvatar,
    required this.sellerId,
    required this.sellerName,
    required this.sellerAvatar,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isActive = true,
  });

  factory MarketConversation.fromJson(Map<String, dynamic> json) {
    return MarketConversation(
      id: json['id'].toString(),
      productId: json['product_id'],
      productTitle: json['product_title'],
      productImage: json['product_image'] ?? '',
      buyerId: json['buyer_id'],
      buyerName: json['buyer_name'],
      buyerAvatar: json['buyer_avatar'] ?? '',
      sellerId: json['seller_id'],
      sellerName: json['seller_name'],
      sellerAvatar: json['seller_avatar'] ?? '',
      lastMessage: json['last_message'] ?? '',
      lastMessageAt: DateTime.parse(json['last_message_at']),
      unreadCount: json['unread_count'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}

class MarketMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;

  MarketMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
  });

  factory MarketMessage.fromJson(Map<String, dynamic> json) {
    return MarketMessage(
      id: json['id'].toString(),
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'] ?? '',
      message: json['message'],
      timestamp: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      imageUrl: json['image_url'],
    );
  }

  bool isMine(String currentUserId) => senderId == currentUserId;
}

// =====================================================
// SERVICE
// =====================================================

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
    
    return MarketConversation.fromJson((response as List).first);
  }

  Future<MarketMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String message,
    String? imageUrl,
  }) async {
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
    
    final sentMessage = MarketMessage.fromJson((response as List).first);

    await _supabase
        .from('market_conversations')
        .update({
          'last_message': message,
          'last_message_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);

    return sentMessage;
  }

  Future<void> markAsRead(String conversationId, String userId) async {
    await _supabase
        .from('market_messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId);
  }

  Stream<List<MarketMessage>> getMessages(String conversationId) {
    return _supabase
        .from('market_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((list) => list.map((e) => MarketMessage.fromJson(e)).toList());
  }

  Future<List<MarketConversation>> getUserConversations(String userId) async {
    final response = await _supabase
        .from('market_conversations')
        .select('*')
        .eq('buyer_id', userId)
        .eq('is_active', true)
        .order('last_message_at', ascending: false);
    
    return (response as List).map((e) => MarketConversation.fromJson(e)).toList();
  }

  Future<int> getUnreadCount(String userId) async {
    final response = await _supabase.rpc('get_market_unread_count', params: {
      'p_user_id': userId,
    });
    return response ?? 0;
  }

  Future<void> deleteConversation(String conversationId) async {
    await _supabase
        .from('market_conversations')
        .update({'is_active': false})
        .eq('id', conversationId);
  }
}
