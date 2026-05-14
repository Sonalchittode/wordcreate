import 'package:flutter/material.dart';
import '../profile/subscription_view.dart';
import 'feedback_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});


  @override
  Widget build(BuildContext context) {
    // Accessing the theme's color scheme
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white, // Arctic White
      appBar: AppBar(
        title: const Text('Settings'),
        // AppBar theme is inherited from main.dart (Deep Navy)
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // PREMIUM SECTION
          const _SectionHeader(title: 'PREMIUM'),
          _GroupedSection(
            children: [
              _ActionTile(
                title: 'Try Premium',
                icon: Icons.star,
                iconColor: colorScheme.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SubscriptionView()),
                  );
                },
              ),
            ],
          ),

          // MAKE IT YOURS SECTION
          const _SectionHeader(title: 'MAKE IT YOURS'),
          const _GroupedSection(
            children: [
              _SwitchTile(title: 'Notifications', icon: Icons.notifications_none, initialValue: true),
              _SwitchTile(title: 'Dark Mode', icon: Icons.dark_mode_outlined, initialValue: false),
              _SwitchTile(title: 'Sound', icon: Icons.volume_up_outlined, initialValue: true),
            ],
          ),

          // SUPPORT SECTION
          const _SectionHeader(title: 'SUPPORT'),
          _GroupedSection(
            children: [
              const _ActionTile(title: 'Help', icon: Icons.help_outline),
              _ActionTile(
                title: 'Feedback',
                icon: Icons.chat_bubble_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FeedbackView()),
                  );
                },
              ),
              const _ActionTile(title: 'Contact Us', icon: Icons.mail_outline),
              const _ActionTile(title: 'Rate App', icon: Icons.star_outline),
            ],
          ),

          // OTHERS SECTION
          const _SectionHeader(title: 'OTHERS'),
          const _GroupedSection(
            children: [
              _ActionTile(title: 'Privacy Policy', icon: Icons.lock_outline),
              _ActionTile(title: 'Terms & Conditions', icon: Icons.description_outlined),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// --- Helper Widget for Square Grouping ---
class _GroupedSection extends StatelessWidget {
  final List<Widget> children;
  const _GroupedSection({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // We add dividers between children for a cleaner look inside the square
    List<Widget> dividedChildren = [];
    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i != children.length - 1) {
        dividedChildren.add(
          Divider(
            height: 1,
            indent: 56, // Aligns divider with the start of the title text
            endIndent: 16,
            color: colorScheme.primary.withValues(alpha: 0.05),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        // Ice Blue background for the section square
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: dividedChildren,
      ),
    );
  }
}

// --- Helper Widgets for Settings ---
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
          title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              // Using Deep Navy with lower opacity for a subtle professional look
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              letterSpacing: 1.2
          )
      ),
    );
  }
}

class _SwitchTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool initialValue;
  const _SwitchTile({required this.title, required this.icon, required this.initialValue});

  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  late bool _value;
  @override
  void initState() { super.initState(); _value = widget.initialValue; }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(widget.icon, color: colorScheme.primary),
      title: Text(widget.title, style: TextStyle(color: colorScheme.primary)),
      trailing: Switch(
        value: _value,
        activeColor: colorScheme.secondary, // Steel Blue
        onChanged: (val) => setState(() => _value = val),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor; // Added to allow specific highlighting (like Premium star)
  final VoidCallback? onTap;

  const _ActionTile({
    required this.title,
    required this.icon,
    this.iconColor,
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: iconColor ?? colorScheme.primary),
      title: Text(title, style: TextStyle(color: colorScheme.primary)),
      trailing: Icon(Icons.chevron_right, size: 22, color: colorScheme.primary.withValues(alpha: 0.3)),
      onTap: onTap ?? () {},
    );
  }
}