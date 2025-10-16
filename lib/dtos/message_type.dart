enum MessageType {
  MESSAGE,
  STATUS_UPDATE,
  READ,
  UNKNOWN;

  static MessageType fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'MESSAGE':
        return MessageType.MESSAGE;
      case 'STATUS_UPDATE':
        return MessageType.STATUS_UPDATE;
      case 'READ':
        return MessageType.READ;
      default:
        return MessageType.UNKNOWN;
    }
  }

  String toShortString() => name.toUpperCase();
}
