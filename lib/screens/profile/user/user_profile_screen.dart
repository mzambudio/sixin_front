import 'package:flutter/material.dart';
import 'package:sixin_front/screens/profile/widgets/profile_view.dart';

class UserProfileScreen extends StatelessWidget {
  final String uid;
  const UserProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ProfileView(uid: uid),
    );
  }
}
