import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:clinic_portal/login.dart';

class setstaff extends StatelessWidget {
  const setstaff({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Update Profile'),
            subtitle: const Text('Change your name, phone, or email'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to Update Profile screen (create this screen separately)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Update Profile tapped')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            subtitle: const Text('Update your account password'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to Change Password screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Change Password tapped')),
              );
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Enable or disable notifications'),
            value: true, // You can make this dynamic later
            onChanged: (val) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Notifications: $val')));
            },
            secondary: const Icon(Icons.notifications),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
