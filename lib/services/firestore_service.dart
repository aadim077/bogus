import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create a user
  Future<void> createUser(
      String uid,
      String email, {
        String role = "user",
        String? username,
      }) async {
    await _db.collection("users").doc(uid).set({
      "email": email,
      "role": role,
      "username": username,
      "savedVideos": [],
      "likedVideos": [],
      "profilePic": null,
      "createdAt": FieldValue.serverTimestamp(),
      "isAdmin": role == "admin",
    });
  }

  ///  Get user
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  ///  Update user
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection("users").doc(uid).update(data);
  }

  ///  Update user role
  Future<void> updateUserRole(String uid, String role) async {
    await _db.collection("users").doc(uid).update({
      "role": role,
      "isAdmin": role == "admin",
    });
  }

  ///  Upload video metadata
  Future<void> uploadVideoMetadata(
      Map<String, dynamic> meta,
      String userId,
      ) async {
    final userDoc = await _db.collection("users").doc(userId).get();
    final username = userDoc.data()?["username"] ?? "Unknown";

    await _db.collection("videos").add({
      ...meta,
      "title": meta["title"] ?? "",
      "caption": meta["caption"] ?? "",
      "url": meta["url"],
      "public_id": meta["public_id"] ?? "",
      "userId": userId,
      "username": username,
      "likes": [],
      "uploadedAt": FieldValue.serverTimestamp(),
    });
  }

  ///  All videos (feed)
  Stream<QuerySnapshot<Map<String, dynamic>>> videosStream() => _db
      .collection("videos")
      .orderBy("uploadedAt", descending: true)
      .snapshots();

  /// Only videos from a specific user
  Stream<QuerySnapshot<Map<String, dynamic>>> userVideosStream(String uid) =>
      _db
          .collection("videos")
          .where("userId", isEqualTo: uid)
          .orderBy("uploadedAt", descending: true)
          .snapshots();

  ///  Toggle Like
  ///  Toggle Like
  Future<void> toggleLike(String videoId, String uid) async {
    final videoRef = _db.collection("videos").doc(videoId);
    final userRef = _db.collection("users").doc(uid);

    final videoSnap = await videoRef.get();
    if (!videoSnap.exists) return;

    final data = videoSnap.data() as Map<String, dynamic>;
    final likes = List<String>.from(data["likes"] ?? []);

    if (likes.contains(uid)) {
      // Unlike
      await videoRef.update({
        "likes": FieldValue.arrayRemove([uid]),
      });
      await userRef.update({
        "likedVideos": FieldValue.arrayRemove([videoId]),
      });
    } else {
      // Like
      await videoRef.update({
        "likes": FieldValue.arrayUnion([uid]),
      });
      await userRef.update({
        "likedVideos": FieldValue.arrayUnion([videoId]),
      });
    }
  }


  ///  Toggle Save
  Future<void> toggleSave(String uid, String videoId) async {
    final userRef = _db.collection("users").doc(uid);

    await _db.runTransaction((txn) async {
      final snap = await txn.get(userRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final saved = List<String>.from(data["savedVideos"] ?? []);

      if (saved.contains(videoId)) {
        txn.update(userRef, {
          "savedVideos": FieldValue.arrayRemove([videoId]),
        });
      } else {
        txn.update(userRef, {
          "savedVideos": FieldValue.arrayUnion([videoId]),
        });
      }
    });
  }

  ///  Admin helpers
  Future<QuerySnapshot<Map<String, dynamic>>> allUsers() =>
      _db.collection("users").get();

  Future<QuerySnapshot<Map<String, dynamic>>> allVideos() =>
      _db.collection("videos").get();

  Future<void> deleteVideoDoc(String id) =>
      _db.collection("videos").doc(id).delete();

  Future<void> deleteUserDoc(String uid) =>
      _db.collection("users").doc(uid).delete();
}
