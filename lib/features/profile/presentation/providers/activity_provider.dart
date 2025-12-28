// lib/features/profile/presentation/providers/activity_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../jobs/presentation/providers/jobs_provider.dart';
import './profile_provider.dart';

final recentActivityProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final jobs = ref.watch(jobsProvider).value ?? [];
  final profile = ref.watch(profileProvider).value;

  List<Map<String, dynamic>> activities = [];

  // 1. Add Recent Jobs (Available for the user)
  for (var job in jobs.take(2)) {
    activities.add({
      'type': 'job',
      'title': 'New Job Matching You',
      'message': '${job.title} at ${job.company.name}', // Changed from companyName to company.name      'time': job.createdAt,
      'icon': Icons.work_outline,
      'color': Colors.blue,
    });
  }

  // 2. Add Job Application Status (Simulated from Job Data)
  // In a real app, you'd pull from an 'applicationsProvider'
  final userApplications = jobs.where((j) => j.isApplied == true).toList();
  for (var app in userApplications.take(2)) {
    activities.add({
      'type': 'application',
      'title': 'Application Update',
      'message': 'Your application for ${app.title} is now "Under Review"',
      'time': DateTime.now().subtract(const Duration(hours: 5)), // Mocking recent update
      'icon': Icons.assignment_turned_in_outlined,
      'color': Colors.orange,
    });
  }

  // 3. Add Marketplace Activity
  if (profile?.marketplaceStats != null && (profile?.marketplaceStats?.activeProducts ?? 0) > 0) {
    activities.add({
      'type': 'sale',
      'title': 'Marketplace Active',
      'message': 'You have ${profile!.marketplaceStats!.activeProducts} products live for sale.',
      'time': profile.updatedAt ?? DateTime.now(),
      'icon': Icons.shopping_bag_outlined,
      'color': Colors.purple,
    });
  }

  // Sort by Newest first
  activities.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

  return activities;
});