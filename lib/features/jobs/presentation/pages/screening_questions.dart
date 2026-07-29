import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class ScreeningQuestionsBuilder extends StatefulWidget {
  final List<Map<String, dynamic>> initialQuestions;
  final Function(List<Map<String, dynamic>>) onChanged;

  const ScreeningQuestionsBuilder({
    super.key,
    required this.initialQuestions,
    required this.onChanged,
  });

  @override
  State<ScreeningQuestionsBuilder> createState() => _ScreeningQuestionsBuilderState();
}

class _ScreeningQuestionsBuilderState extends State<ScreeningQuestionsBuilder> {
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.initialQuestions);
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'question': '',
        'type': 'text',
        'required': true,
        'options': [],
      });
    });
    widget.onChanged(_questions);
  }

  void _removeQuestion(int index) {
    setState(() => _questions.removeAt(index));
    widget.onChanged(_questions);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Screening Questions",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            TextButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add, color: AppColors.primary),
              label: const Text("Add Question", style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_questions.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: AppColors.borderLight, style: BorderStyle.none),
            ),
            child: const Center(
              child: Text(
                "No questions added. Applicants will apply directly.",
                style: TextStyle(color: AppColors.textMutedLight, fontSize: 14),
              ),
            ),
          )
        else
          ..._questions.asMap().entries.map((entry) {
            int idx = entry.key;
            var q = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: AppSpacing.roundedLg,
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppSpacing.elevatedShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: q['question'],
                            decoration: InputDecoration(
                              hintText: "Enter your question...",
                              border: OutlineInputBorder(
                                borderRadius: AppSpacing.roundedSm,
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.backgroundLight,
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            onChanged: (val) {
                              _questions[idx]['question'] = val;
                              widget.onChanged(_questions);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () => _removeQuestion(idx),
                          tooltip: 'Remove Question',
                        ),
                      ],
                    ),
                    const Divider(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: q['type'],
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              border: OutlineInputBorder(
                                borderRadius: AppSpacing.roundedSm,
                                borderSide: const BorderSide(color: AppColors.borderLight),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'text', child: Text("Text Answer")),
                              DropdownMenuItem(value: 'yes_no', child: Text("Yes/No")),
                              DropdownMenuItem(value: 'multiple_choice', child: Text("Multiple Choice")),
                            ],
                            onChanged: (val) {
                              setState(() => _questions[idx]['type'] = val);
                              widget.onChanged(_questions);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Row(
                          children: [
                            const Text("Required", style: TextStyle(color: AppColors.textSecondaryLight)),
                            Switch(
                              value: q['required'],
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() => _questions[idx]['required'] = val);
                                widget.onChanged(_questions);
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                    if (q['type'] == 'multiple_choice')
                      _buildOptionsEditor(idx),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildOptionsEditor(int qIdx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        const Text("Options", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
        const SizedBox(height: AppSpacing.sm),
        ...(_questions[qIdx]['options'] as List).asMap().entries.map((optEntry) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.drag_indicator, size: 16, color: AppColors.textMutedLight),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(optEntry.value)),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: AppColors.textMutedLight),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      (_questions[qIdx]['options'] as List).removeAt(optEntry.key);
                    });
                    widget.onChanged(_questions);
                  },
                )
              ],
            ),
          );
        }),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () => _showAddOptionDialog(qIdx),
          icon: const Icon(Icons.add, size: 18),
          label: const Text("Add Option"),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
          ),
        )
      ],
    );
  }

  void _showAddOptionDialog(int qIdx) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        title: const Text("Add Choice"),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter option text',
            border: OutlineInputBorder(borderRadius: AppSpacing.roundedSm),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondaryLight)),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                setState(() {
                  (_questions[qIdx]['options'] as List).add(ctrl.text);
                });
                widget.onChanged(_questions);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
            ),
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}