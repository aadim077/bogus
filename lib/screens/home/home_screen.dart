import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/flag_secure.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/notification_icon.dart';
import '../upload/upload_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_dashboard.dart';
import 'reel_item.dart';



// Color palette for the application
const Color primaryColor = Color(0xFF283B54);
const Color accentColor = Color(0xFF0096A6);
const Color textColor = Colors.white;
const Color cardColor = Color(0xFF3B4E66);



// A themed Bottom Navigation Bar widget to replace the placeholder

class ThemedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const ThemedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,

  });



  @override

  Widget build(BuildContext context) {

    return Container(
      decoration: const BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),

          ),

        ],

      ),

      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: accentColor,
        unselectedItemColor: textColor.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',

          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_rounded),
            label: 'Upload',

          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',

          ),

        ],

      ),

    );

  }

}



class HomeScreen extends StatefulWidget {
  final UserState userState;
  const HomeScreen({required this.userState, super.key});



  @override

  State<HomeScreen> createState() => _HomeScreenState();

}



class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final PageController _pageController = PageController();



  @override

  void initState() {
    super.initState();
    ScreenSecurity.enable(); // FLAG_SECURE

  }



  @override

  void dispose() {
    _pageController.dispose();
    super.dispose();

  }



  @override

  Widget build(BuildContext context) {
    if (widget.userState.isAdmin) return const AdminDashboard();
    final pages = [

//  Reels Feed

      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService().videosStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: accentColor));

          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No videos yet",
                style: TextStyle(color: textColor),

              ),

            );

          }
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data();

              return ReelItem(
                doc: docs[i],
                currentUserId: widget.userState.uid,
                videoId: docs[i].id,
                videoUrl: data['url'] ?? '',
                username: data['username'] ?? 'User',
                caption: data['caption'] ?? '',
                isActive: _pageController.hasClients
                    ? (_pageController.page?.round() ?? -1) == i
                    : i == 0,
              );

            },

            onPageChanged: (_) {

              setState(() {}); // triggers ReelItem rebuild -> play/pause

            },

          );

        },

      ),



// Upload

      UploadScreen(userId: widget.userState.uid),



// Profile

      ProfileScreen(userId: widget.userState.uid),

    ];



    return Scaffold(
      backgroundColor: primaryColor, // Apply the background color
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,



      ),
      body: pages[_index],
      bottomNavigationBar: ThemedBottomNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),

      ),

    );

  }

}