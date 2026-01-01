// lib/features/applications/presentation/pages/applicant_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../data/models/application_model.dart';
import '../../data/repositories/applications_repository.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/data/models/user_model.dart';

class ApplicantDetailsPage extends ConsumerStatefulWidget {
  final ApplicationModel application;
  final String jobId;

  const ApplicantDetailsPage({
    super.key,
    required this.application,
    required this.jobId,
  });

  @override
  ConsumerState<ApplicantDetailsPage> createState() => _ApplicantDetailsPageState();
}

class _ApplicantDetailsPageState extends ConsumerState<ApplicantDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final applicantDetails = widget.application.applicantDetails;
    final profile = applicantDetails?.profile;
    final jobSeekerProfile = applicantDetails?.jobSeekerProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicant Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Card with Photo and Basic Info
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: profile?.avatar != null
                        ? NetworkImage(profile!.avatar!)
                        : null,
                    child: profile?.avatar == null
                        ? Text(
                      profile?.firstName?.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${profile?.firstName ?? ""} ${profile?.lastName ?? ""}'.trim().isEmpty
                        ? 'Applicant'
                        : '${profile?.firstName ?? ""} ${profile?.lastName ?? ""}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (profile?.headline != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      profile!.headline!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (profile?.location?.city != null) ...[
                        const Icon(Icons.location_on, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          profile!.location!.city!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 2. Contact Actions (Email & Call)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendEmail(applicantDetails?.email),
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Email'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callPhone(profile?.phone),
                      icon: const Icon(Icons.phone_outlined),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Application Info
            _buildSection(
              context,
              title: 'Application Details',
              children: [
                _buildInfoRow(
                  icon: Icons.schedule,
                  label: 'Applied',
                  value: _formatDate(widget.application.createdAt ?? DateTime.now()),
                ),
                _buildInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Status',
                  value: _getStatusLabel(widget.application.status),
                  valueColor: _getStatusColor(widget.application.status),
                ),
                if (widget.application.coverLetter != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Cover Letter',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.application.coverLetter!,
                    style: TextStyle(color: Colors.grey[700], height: 1.5),
                  ),
                ],
              ],
            ),

            // 4. Screening Questions & Answers (NEW SECTION)
            if (widget.application.screeningAnswers != null &&
                widget.application.screeningAnswers!.isNotEmpty)
              _buildSection(
                context,
                title: 'Screening Questions',
                children: widget.application.screeningAnswers!
                    .asMap()
                    .entries
                    .map((entry) => _buildScreeningAnswerCard(entry.key + 1, entry.value))
                    .toList(),
              ),

            // 5. Resume Section (DOWNLOADABLE/VIEWABLE)
            if (widget.application.resume != null ||
                jobSeekerProfile?.resume?.url != null)
              _buildSection(
                context,
                title: 'Resume',
                children: [
                  ListTile(
                    tileColor: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    leading: const Icon(Icons.description,
                        color: Colors.blue, size: 30),
                    title: Text(
                      widget.application.resume?.filename ?? 'Resume.pdf',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Tap to view or download'),
                    trailing: const Icon(Icons.open_in_new, size: 20),
                    onTap: () => _openResume(
                        widget.application.resume?.url ??
                            jobSeekerProfile?.resume?.url ??
                            ''),
                  ),
                ],
              ),

            // 6. Experience Section
            if (jobSeekerProfile?.experience != null &&
                jobSeekerProfile!.experience!.isNotEmpty)
              _buildSection(
                context,
                title: 'Experience',
                children: jobSeekerProfile.experience!
                    .map((exp) => _buildExperienceCard(exp))
                    .toList(),
              ),

            // 7. Education Section
            if (jobSeekerProfile?.education != null &&
                jobSeekerProfile!.education!.isNotEmpty)
              _buildSection(
                context,
                title: 'Education',
                children: jobSeekerProfile.education!
                    .map((edu) => _buildEducationCard(edu))
                    .toList(),
              ),

            // 8. Skills Section
            if (jobSeekerProfile?.skills != null &&
                jobSeekerProfile!.skills!.isNotEmpty)
              _buildSection(
                context,
                title: 'Skills',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: jobSeekerProfile.skills!.map((skill) {
                      return Chip(
                        label: Text(skill.name ?? 'Skill'),
                        backgroundColor: Colors.blue.shade50,
                        side: BorderSide.none,
                        labelStyle: const TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.w500),
                      );
                    }).toList(),
                  ),
                ],
              ),

            const SizedBox(height: 140), // Extra space for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: _buildActionBar(context),
    );
  }

  // --- UI BUILDING HELPER METHODS ---

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      {required IconData icon,
        required String label,
        required String value,
        Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label:',
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: valueColor ?? Colors.black),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Screening Answer Card
  Widget _buildScreeningAnswerCard(int index, ScreeningAnswer answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answer.question,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        answer.answer,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(ExperienceData exp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blueGrey,
              child: Icon(Icons.business, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exp.position ?? 'Position',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(exp.company ?? 'Company',
                    style: TextStyle(color: Colors.grey[700])),
                Text(
                  '${exp.startDate?.year ?? ""} - ${exp.current == true ? 'Present' : exp.endDate?.year ?? ""}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard(EducationData edu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.orangeAccent,
              child: Icon(Icons.school, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(edu.degree ?? 'Degree',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(edu.institution ?? 'Institution',
                    style: TextStyle(color: Colors.grey[700])),
                Text(
                  '${edu.startYear ?? ""} - ${edu.endYear ?? "Present"}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED ACTION BAR WITH IMPROVED FLOW ---
  Widget _buildActionBar(BuildContext context) {
    final status = widget.application.status;

    // Hide action bar for final states
    if (status == 'accepted' || status == 'rejected') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shortlist button (only show if not already shortlisted)
            if (status != 'shortlisted') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addToShortlist(),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Shortlist Candidate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(color: Colors.purple, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Status indicator for shortlisted candidates
            if (status == 'shortlisted') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.purple.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Shortlisted · Ready for interview or final decision',
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Accept/Reject row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectApplicant(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _acceptApplicant(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: const Text('Accept Candidate',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC METHODS (Url Launcher & API Calls) ---

  Future<void> _openResume(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open resume')));
      }
    }
  }

  Future<void> _sendEmail(String? email) async {
    if (email == null) return;
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _callPhone(String? phone) async {
    if (phone == null) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String _formatDate(DateTime date) => DateFormat('MMM dd, yyyy').format(date);

  // Updated status label with better descriptions
  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Under Review';
      case 'shortlisted':
        return 'Shortlisted ⭐';
      case 'accepted':
        return 'Accepted ✓';
      case 'rejected':
        return 'Rejected';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'shortlisted':
        return Colors.purple;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event, color: Colors.blue),
              title: const Text('Schedule Interview'),
              onTap: () {
                Navigator.pop(context);
                _scheduleInterview();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.grey),
              title: const Text('View Application History'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon')));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptApplicant() async {
    final confirmed = await _showConfirmDialog(
      'Accept Candidate',
      'The candidate will be notified of their acceptance. Continue?',
    );
    if (confirmed == true) {
      try {
        await ref.read(applicationsRepositoryProvider).updateApplicationStatus(
          id: widget.application.id,
          status: 'accepted',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Candidate accepted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        _showError(e);
      }
    }
  }

  Future<void> _rejectApplicant() async {
    final confirmed = await _showConfirmDialog(
      'Reject Candidate',
      'Are you sure you want to reject this application? This action cannot be undone.',
      isRed: true,
    );
    if (confirmed == true) {
      try {
        await ref
            .read(applicationsRepositoryProvider)
            .rejectApplication(id: widget.application.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application rejected'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        _showError(e);
      }
    }
  }

  Future<void> _addToShortlist() async {
    try {
      await ref
          .read(applicationsRepositoryProvider)
          .shortlistApplication(widget.application.id);
      if (mounted) {
        setState(() {
          // Force rebuild to update UI
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⭐ Added to Shortlist'),
            backgroundColor: Colors.purple,
            action: SnackBarAction(
              label: 'Schedule Interview',
              textColor: Colors.white,
              onPressed: () => _scheduleInterview(),
            ),
          ),
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _scheduleInterview() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final fullDateTime = DateTime(
            date.year, date.month, date.day, time.hour, time.minute);
        try {
          await ref.read(applicationsRepositoryProvider).scheduleInterview(
            id: widget.application.id,
            scheduledAt: fullDateTime,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Interview scheduled for ${DateFormat('MMM dd, yyyy at h:mm a').format(fullDateTime)}'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        } catch (e) {
          _showError(e);
        }
      }
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content,
      {bool isRed = false}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRed ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showError(dynamic e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Provider for Repository
final applicationsRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return ApplicationsRepository(dio);
});
