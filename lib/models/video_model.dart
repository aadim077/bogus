class VideoItem {
  final String id;
  final String title;
  final String url;
  final String publicId;
  final String userId;
  final List<String> likes;

  VideoItem({
    required this.id,
    required this.title,
    required this.url,
    required this.publicId,
    required this.userId,
    required this.likes,
  });

  factory VideoItem.fromMap(String id, Map<String, dynamic> d) => VideoItem(
    id: id,
    title: d['title'] ?? '',
    url: d['url'] ?? '',
    publicId: d['public_id'] ?? '',
    userId: d['userId'] ?? '',
    likes: List<String>.from(d['likes'] ?? []),
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'url': url,
    'public_id': publicId,
    'userId': userId,
    'likes': likes,
  };
}
