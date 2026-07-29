// lib/features/applications/presentation/pages/applicant_details_page.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../data/models/application_model.dart';
import '../providers/applications_provider.dart';
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
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.application.status;
  }

  @override
  Widget build(BuildContext context) {
    final applicantDetails = widget.application.applicantDetails;
    final profile = applicantDetails?.profile;
    final jobSeekerProfile = applicantDetails?.jobSeekerProfile;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Applicant Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
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
            // Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: AppSpacing.roundedXl, // Changed to roundedXl below
                boxShadow: AppSpacing.cardShadow,
              ),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderLight, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: profile?.avatar != null ? NetworkImage(profile!.avatar!) : null,
                      child: profile?.avatar == null
                          ? Text(
                              profile?.firstName?.substring(0, 1).toUpperCase() ?? 'A',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${profile?.firstName ?? ""} ${profile?.lastName ?? ""}'.trim().isEmpty
                        ? 'Applicant'
                        : '${profile?.firstName ?? ""} ${profile?.lastName ?? ""}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                  ),
                  if (profile?.headline != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      profile!.headline!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (profile?.location?.city != null) ...[
                        const Icon(Icons.location_on, size: 16, color: AppColors.textMutedLight),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          profile!.location!.city!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMutedLight,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _sendEmail(applicantDetails?.email),
                          icon: const Icon(Icons.email_outlined, size: 18),
                          label: const Text('Email'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _callPhone(profile?.phone),
                          icon: const Icon(Icons.phone_outlined, size: 18),
                          label: const Text('Call'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Application Info
            _buildSection(
              context,
              title: 'Application Details',
              children: [
                _buildInfoRow(context, icon: Icons.schedule, label: 'Applied', value: _formatDate(widget.application.createdAt ?? DateTime.now())),
                _buildInfoRow(context, icon: Icons.badge_outlined, label: 'Status', value: _getStatusLabel(_currentStatus), valueColor: _getStatusColor(_currentStatus)),
                if (widget.application.coverLetter != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Cover Letter',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.application.coverLetter!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight, height: 1.6),
                  ),
                ],
              ],
            ),

            // Screening Questions
            if (widget.application.screeningAnswers != null && widget.application.screeningAnswers!.isNotEmpty)
              _buildSection(
                context,
                title: 'Screening Questions',
                children: widget.application.screeningAnswers!
                    .asMap()
                    .entries
                    .map((entry) => _buildScreeningAnswerCard(context, entry.key + 1, entry.value))
                    .toList(),
              ),

            // Resume Section
            if (widget.application.resume != null || jobSeekerProfile?.resume?.url != null)
              _buildSection(
                context,
                title: 'Resume',
                children: [
                  InkWell(
                    onTap: () => _openResume(widget.application.resume?.url ?? jobSeekerProfile?.resume?.url ?? ''),
                    borderRadius: AppSpacing.roundedMd,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: AppSpacing.roundedMd,
                        color: AppColors.backgroundLight,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: AppSpacing.roundedSm,
                            ),
                            child: const Icon(Icons.description, color: AppColors.primary),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.application.resume?.filename ?? 'Resume.pdf',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tap to view document',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMutedLight),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            // Experience Section
            if (jobSeekerProfile?.experience != null && jobSeekerProfile!.experience!.isNotEmpty)
              _buildSection(
                context,
                title: 'Experience',
                children: jobSeekerProfile.experience!.map((exp) => _buildExperienceCard(context, exp)).toList(),
              ),

            // Education Section
            if (jobSeekerProfile?.education != null && jobSeekerProfile!.education!.isNotEmpty)
              _buildSection(
                context,
                title: 'Education',
                children: jobSeekerProfile.education!.map((edu) => _buildEducationCard(context, edu)).toList(),
              ),

            // Skills Section
            if (jobSeekerProfile?.skills != null && jobSeekerProfile!.skills!.isNotEmpty)
              _buildSection(
                context,
                title: 'Skills',
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: jobSeekerProfile.skills!.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: AppSpacing.roundedFull,
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Text(
                          skill.name ?? 'Skill',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

            const SizedBox(height: 140),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionBar(context),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedXl,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String label, required String value, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMutedLight),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimaryLight,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreeningAnswerCard(BuildContext context, int index, ScreeningAnswer answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.borderLight),
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
                  color: AppColors.primary,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answer.question,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      answer.answer,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                            height: 1.5,
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

  Widget _buildExperienceCard(BuildContext context, ExperienceData exp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(Icons.business, color: AppColors.textSecondaryLight, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.position ?? 'Position',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  exp.company ?? 'Company',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exp.startDate?.year ?? ""} - ${exp.current == true ? 'Present' : exp.endDate?.year ?? ""}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard(BuildContext context, EducationData edu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(Icons.school, color: AppColors.textSecondaryLight, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.degree ?? 'Degree',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  edu.institution ?? 'Institution',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 2),
                Text(
                  '${edu.startYear ?? ""} - ${edu.endYear ?? "Present"}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    final status = _currentStatus;

    if (status == 'accepted' || status == 'rejected') {
      final isAccepted = status == 'accepted';
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isAccepted ? AppColors.success.withValues(alpha: 0.05) : AppColors.error.withValues(alpha: 0.05),
          border: Border(top: BorderSide(color: isAccepted ? AppColors.success : AppColors.error, width: 2)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Icon(isAccepted ? Icons.check_circle : Icons.cancel, color: isAccepted ? AppColors.success : AppColors.error, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  isAccepted ? 'Candidate Accepted ✓' : 'Application Rejected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isAccepted ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: AppSpacing.bottomNavShadow,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status != 'shortlisted') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addToShortlist(),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Shortlist Candidate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.borderLight, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (status == 'shortlisted') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.05),
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.accent, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Shortlisted · Ready for decision',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectApplicant(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => _acceptApplicant(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                    ),
                    child: const Text('Accept Candidate', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openResume(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open resume')));
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'Under Review';
      case 'shortlisted': return 'Shortlisted';
      case 'accepted': return 'Accepted';
      case 'rejected': return 'Rejected';
      default: return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'shortlisted': return AppColors.accent;
      case 'accepted': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.textMutedLight;
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event, color: AppColors.primary),
              title: const Text('Schedule Interview'),
              onTap: () {
                Navigator.pop(context);
                _scheduleInterview();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.textMutedLight),
              title: const Text('View Application History'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleInterview() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule Interview coming soon')));
  }

  void _addToShortlist() async {
    try {
      setState(() { _currentStatus = 'shortlisted'; });
      await ref.read(applicationsRepositoryProvider).updateApplicationStatus(id: widget.application.id, status: 'shortlisted');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidate shortlisted')));
    } catch (e) {
      setState(() { _currentStatus = widget.application.status; });
      _showError(e);
    }
  }

  Future<void> _acceptApplicant() async {
    final confirmed = await _showConfirmDialog('Accept Candidate', 'The candidate will be notified of their acceptance. Continue?');
    if (confirmed == true) {
      try {
        setState(() { _currentStatus = 'accepted'; });
        await ref.read(applicationsRepositoryProvider).updateApplicationStatus(id: widget.application.id, status: 'accepted');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Candidate accepted successfully'), backgroundColor: AppColors.success));
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() { _currentStatus = widget.application.status; });
        _showError(e);
      }
    }
  }

  Future<void> _rejectApplicant() async {
    final confirmed = await _showConfirmDialog('Reject Candidate', 'Are you sure you want to reject this application? This action cannot be undone.', isRed: true);
    if (confirmed == true) {
      try {
        setState(() { _currentStatus = 'rejected'; });
        await ref.read(applicationsRepositoryProvider).rejectApplication(id: widget.application.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application rejected'), backgroundColor: AppColors.warning));
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() { _currentStatus = widget.application.status; });
        _showError(e);
      }
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content, {bool isRed = false}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirm', style: TextStyle(color: isRed ? AppColors.error : AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showError(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }
}