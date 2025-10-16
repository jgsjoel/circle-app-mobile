class MediaDto {
  final String url;
  final String publicId;

  MediaDto({
    required this.url,
    required this.publicId,
  });

  factory MediaDto.fromJson(Map<String, dynamic> json) {
    return MediaDto(
      url: json['url'] ?? '',
      publicId: json['public_id'] ?? '',
    );
  }
}