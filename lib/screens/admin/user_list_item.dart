import 'package:flutter/material.dart';

class UserListItem extends StatelessWidget {
  final String uid;
  final String email;
  final VoidCallback onDelete;
  const UserListItem({super.key, required this.uid, required this.email, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(uid),
      subtitle: Text(email),
      trailing: IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
    );
  }
}
