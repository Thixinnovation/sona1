// lib/models/banner.dart
class BannerAd {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String buttonText;
  final String? buttonLink;
  final Color backgroundColor;
  final Color textColor;

  BannerAd({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.buttonText,
    this.buttonLink,
    required this.backgroundColor,
    required this.textColor,
  });

  factory BannerAd.fromJson(Map<String, dynamic> json) => BannerAd(
    id: json['id'].toString(),
    title: json['title'],
    subtitle: json['subtitle'],
    imageUrl: json['image_url'],
    buttonText: json['button_text'],
    buttonLink: json['button_link'],
    backgroundColor: Color(json['background_color']),
    textColor: Color(json['text_color']),
  );
}
