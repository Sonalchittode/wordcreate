import 'package:flutter/material.dart';
import 'package:wordcreate/presentation/views/profile/account_view.dart';
import 'package:wordcreate/presentation/views/profile/subscription_view.dart';
import 'package:wordcreate/presentation/views/progress/progress_view.dart';
import 'package:wordcreate/presentation/views/settings/settings_view.dart';
import '../../data/services/auth_service.dart';
import '../../main.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header (Profile Info)
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            currentAccountPicture: CircleAvatar(
              backgroundColor: colorScheme.secondary,
              child: const Icon(Icons.person, size: 40, color: Colors.white),
            ),
            accountName: const Text('sonalsonal',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: const Text('sonal@email.com',
                style: TextStyle(color: Colors.grey)),
          ),

          // Menu Items
          ListTile(
            leading: Icon(Icons.person_outline, color:colorScheme.primary),
            title: const Text('Account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountView()),
              );
            },
          ),

          // --- UPDATED TRY PREMIUM ---
          ListTile(
            leading: Icon(Icons.workspace_premium_outlined, color: colorScheme.secondary), // Changed color to pop
            title: const Text('Try Premium', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionView()),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.bar_chart, color: colorScheme.primary),
            title: const Text('Your Progress'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProgressView()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings_outlined, color: colorScheme.primary),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsView()),
              );
            },
          ),

          const Spacer(),

          // --- UPDATED LOG OUT ---
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              await authService.signOut();
              if (context.mounted) {
                // This ensures the drawer doesn't stay "open" in memory
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const VocabApp()),
                      (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}