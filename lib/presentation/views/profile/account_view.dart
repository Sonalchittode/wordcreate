import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../../../data/services/auth_service.dart';
import '../../../main.dart';
import '../../../data/repositories/firebase_repository.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final AuthService authService = AuthService();
    final FirebaseRepository dbRepo = FirebaseRepository();

    return Scaffold(
      backgroundColor: Colors.white, // Arctic White
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- PROFILE HEADER ---
            CircleAvatar(
              radius: 50,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.person, size: 60, color: colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'User',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
            Text(
              user?.email ?? '',
              style: TextStyle(color: colorScheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 32),

            // --- INFO CARD (Grouped Style) ---
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.5), // Ice Blue
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  FutureBuilder<bool>(
                    future: dbRepo.checkUserPlanStatus(),
                    builder: (context, snapshot) {
                      String status = "Loading...";
                      Color statusColor = colorScheme.primary.withValues(alpha: 0.4);

                      if (snapshot.hasData) {
                        bool isPaid = snapshot.data!;
                        status = isPaid ? 'Premium Member' : 'Basic Plan';
                        statusColor = isPaid ? colorScheme.secondary : colorScheme.primary;
                      }

                      return _AccountInfoRow(
                        icon: Icons.stars_rounded,
                        label: 'Membership',
                        value: status,
                        valueColor: statusColor,
                      );
                    },
                  ),
                  _Divider(colorScheme: colorScheme),
                  _AccountInfoRow(
                    icon: Icons.alternate_email,
                    label: 'Email',
                    value: user?.email ?? 'N/A',
                  ),
                  _Divider(colorScheme: colorScheme),
                  _UserIDSection(uid: user?.uid ?? ''),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- ACCOUNT ACTIONS ---
            _ActionTile(
              title: 'Change Password',
              icon: Icons.lock_outline,
              onTap: () {
                if (user?.email != null) {
                  FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password reset link sent to your email.")),
                  );
                }
              },
            ),
            _ActionTile(
              title: 'Logout',
              icon: Icons.logout,
              iconColor: Colors.redAccent,
              onTap: () async {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const VocabApp()),
                        (route) => false,
                  );
                }
              },
            ),
            _ActionTile(
              title: 'Delete Account',
              icon: Icons.delete_forever_outlined,
              iconColor: colorScheme.primary.withValues(alpha: 0.3),
              onTap: () => _showDeleteDialog(context, colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Account?", style: TextStyle(color: colorScheme.primary)),
        content: const Text("This action is permanent and will delete all your stories and progress."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: colorScheme.primary))),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Delete", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
}

// --- HELPER WIDGETS ---

class _Divider extends StatelessWidget {
  final ColorScheme colorScheme;
  const _Divider({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 50, endIndent: 16, color: colorScheme.primary.withValues(alpha: 0.05));
  }
}

class _AccountInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _AccountInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary.withValues(alpha: 0.6), size: 22),
          const SizedBox(width: 15),
          Text(label, style: TextStyle(fontSize: 15, color: colorScheme.primary, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
              value,
              style: TextStyle(
                  fontSize: 15,
                  color: valueColor ?? colorScheme.primary.withValues(alpha: 0.4),
                  fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal
              )
          ),
        ],
      ),
    );
  }
}

class _UserIDSection extends StatelessWidget {
  final String uid;
  const _UserIDSection({required this.uid});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.fingerprint, color: colorScheme.primary.withValues(alpha: 0.6), size: 22),
          const SizedBox(width: 15),
          Text('User ID', style: TextStyle(fontSize: 15, color: colorScheme.primary, fontWeight: FontWeight.w500)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: uid));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User ID copied!')),
              );
            },
            child: Row(
              children: [
                Text(
                  uid.length > 8 ? '${uid.substring(0, 8)}...' : uid,
                  style: TextStyle(color: colorScheme.primary.withValues(alpha: 0.3)),
                ),
                const SizedBox(width: 5),
                Icon(Icons.copy, size: 14, color: colorScheme.primary.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: iconColor ?? colorScheme.primary),
      title: Text(title, style: TextStyle(color: iconColor ?? colorScheme.primary, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right, size: 20, color: colorScheme.primary.withValues(alpha: 0.2)),
      onTap: onTap,
    );
  }
}