import 'package:flutter/material.dart';

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
            const Text(
              "Screening Questions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add),
              label: const Text("Add Question"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_questions.isEmpty)
          const Center(
            child: Text(
              "No questions added. Applicants will apply directly.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          )
        else
          ..._questions.asMap().entries.map((entry) {
            int idx = entry.key;
            var q = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: q['question'],
                            decoration: const InputDecoration(
                              hintText: "Enter your question...",
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              _questions[idx]['question'] = val;
                              widget.onChanged(_questions);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeQuestion(idx),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          value: q['type'],
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
                        Row(
                          children: [
                            const Text("Required"),
                            Switch(
                              value: q['required'],
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
      children: [
        const Divider(),
        ...(_questions[qIdx]['options'] as List).asMap().entries.map((optEntry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(optEntry.value)),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
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
        TextButton(
          onPressed: () => _showAddOptionDialog(qIdx),
          child: const Text("+ Add Option"),
        )
      ],
    );
  }

  void _showAddOptionDialog(int qIdx) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Choice"),
        content: TextField(
          controller: ctrl,
          autofocus: true, // ✅ Changed from autoFocus to autofocus
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                setState(() {
                  (_questions[qIdx]['options'] as List).add(ctrl.text);
                });
                widget.onChanged(_questions);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}