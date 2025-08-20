class AppUser {
  final String uid;
  final String email;
  final bool isAdmin;
  final List<String> savedVideos;
  AppUser({
    required this.uid,
    required this.email,
    required this.isAdmin,
    required this.savedVideos,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> d) => AppUser(
    uid: uid,
    email: d['email'] ?? '',
    isAdmin: d['isAdmin'] == true,
    savedVideos: List<String>.from(d['savedVideos'] ?? []),
  );

  Map<String, dynamic> toMap() => {
    'email': email,
    'isAdmin': isAdmin,
    'savedVideos': savedVideos,
  };
}
