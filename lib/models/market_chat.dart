import 'package:supabase_flutter/supabase_flutter.dart';

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
      lastMessageAt: DateTime.parse(json['last_message_at'].toString()),
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
      timestamp: DateTime.parse(json['created_at'].toString()),
      isRead: json['is_read'] ?? false,
      imageUrl: json['image_url'],
    );
  }

  bool isMine(String currentUserId) => senderId == currentUserId;
}
