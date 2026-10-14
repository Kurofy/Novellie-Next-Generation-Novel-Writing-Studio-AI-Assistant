import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../core/theme/theme.dart';
import '../utils/ai_markdown_to_quill.dart';

class AiQuillMessageView extends StatefulWidget {
  final String text;

  const AiQuillMessageView({
    super.key,
    required this.text,
  });

  @override
  State<AiQuillMessageView> createState() => _AiQuillMessageViewState();
}

class _AiQuillMessageViewState extends State<AiQuillMessageView> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode(canRequestFocus: false);

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    final doc = AiMarkdownToQuill.parse(widget.text);
    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void didUpdateWidget(AiQuillMessageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.dispose();
      _initController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: c.textPrimary,
              displayColor: c.textPrimary,
            ),
      ),
      child: QuillEditor.basic(
        controller: _controller,
        focusNode: _focusNode,
        config: const QuillEditorConfig(
          scrollable: false,
          expands: false,
          autoFocus: false,
          showCursor: false,
          checkBoxReadOnly: true,
          enableInteractiveSelection: true,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
