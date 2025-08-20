import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../services/firestore_service.dart';

class ReelItem extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String currentUserId;
  final String videoId;
  final String videoUrl;
  final String username;
  final String caption;
  final bool isActive;

  const ReelItem({
    required this.doc,
    required this.currentUserId,
    required this.videoId,
    required this.videoUrl,
    required this.username,
    required this.caption,
    required this.isActive,
    super.key,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        if (widget.isActive) _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void didUpdateWidget(covariant ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive && _initialized) {
      widget.isActive ? _controller.play() : _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.videoId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final videoData = snap.data!.data() ?? {};
        final likes = List<String>.from(videoData['likes'] ?? []);
        final isLiked = likes.contains(widget.currentUserId);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserId)
              .snapshots(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = userSnap.data!.data() ?? {};
            final savedVideos = List<String>.from(userData['savedVideos'] ?? []);
            final isSaved = savedVideos.contains(widget.videoId);

            return Stack(
              fit: StackFit.expand,
              children: [
                //  Fullscreen video
                if (_initialized)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                else
                  const Center(child: CircularProgressIndicator()),

                //  Overlay (caption + like + save buttons)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent
                        ],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "@${widget.username}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.caption,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            //  Like button
                            IconButton(
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.white,
                                size: 30,
                              ),
                              onPressed: () {
                                FirestoreService().toggleLike(
                                  widget.videoId,
                                  widget.currentUserId,
                                );
                              },
                            ),
                            Text(
                              likes.length.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),

                            const SizedBox(height: 10),

                            //  Save button
                            IconButton(
                              icon: Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: isSaved ? Colors.yellow : Colors.white,
                                size: 30,
                              ),
                              onPressed: () {
                                FirestoreService().toggleSave(
                                  widget.currentUserId,
                                  widget.videoId,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
