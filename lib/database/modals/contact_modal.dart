class ContactModal {
  final String name;
  final String phone;
  String? pubContactId;

  ContactModal({required this.name, required this.phone, this.pubContactId,});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'public_id': pubContactId,
    };
  }

  factory ContactModal.fromMap(Map<String, dynamic> map) {
    return ContactModal(
      name: map['name'] as String,
      phone: map['phone'] as String,
      pubContactId: map['public_id'] as String?,
    );
  }
}
