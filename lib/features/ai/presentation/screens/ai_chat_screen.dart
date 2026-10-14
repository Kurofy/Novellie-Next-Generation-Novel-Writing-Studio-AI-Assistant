import 'package:flutter/material.dart';
import '../widgets/ai_chat_panel.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: AiChatPanel(),
      ),
    );
  }
}
