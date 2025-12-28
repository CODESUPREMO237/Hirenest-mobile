// Settings Tile
// =====================================================
// lib/features/profile/presentation/widgets/settings_tile.dart
// =====================================================
import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
final IconData icon;
final String title;
final String? subtitle;
final VoidCallback? onTap;
final Widget? trailing;

const SettingsTile({
super.key,
required this.icon,
required this.title,
this.subtitle,
this.onTap,
this.trailing,
});

@override
Widget build(BuildContext context) {
return ListTile(
leading: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: Theme.of(context).primaryColor.withOpacity(0.1),
borderRadius: BorderRadius.circular(8),
),
child: Icon(icon, color: Theme.of(context).primaryColor),
),
title: Text(title),
subtitle: subtitle != null ? Text(subtitle!) : null,
trailing: trailing ?? const Icon(Icons.chevron_right),
onTap: onTap,
);
}
}