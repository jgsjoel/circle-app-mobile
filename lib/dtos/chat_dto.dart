import 'package:flutter/material.dart';

class ChatDto {
  String name;
  String? publicUserId;
  String? id;
  Icon? icon;
  bool isGroup;
  String? time;
  int? messageCount;
  String? lastMessage;
  String? phone;
  String? pubChatId;

  ChatDto({
    required this.name,
    required this.isGroup,
    
    this.messageCount,
    this.lastMessage,
    this.icon,
    this.time,
    this.id,
    this.phone,
    this.pubChatId,
    this.publicUserId
  });

  ChatDto copyWith({
    String? name,
    String? publicUserId,
    String? id,
    Icon? icon,
    bool? isGroup,
    String? time,
    int? messageCount,
    String? lastMessage,
    String? phone,
    String? pubChatId,
  }) {
    return ChatDto(
      name: name ?? this.name,
      isGroup: isGroup ?? this.isGroup,
      messageCount: messageCount ?? this.messageCount,
      lastMessage: lastMessage ?? this.lastMessage,
      icon: icon ?? this.icon,
      time: time ?? this.time,
      id: id ?? this.id,
      phone: phone ?? this.phone,
      pubChatId: pubChatId ?? this.pubChatId,
      publicUserId: publicUserId ?? this.publicUserId,
    );
  }
}