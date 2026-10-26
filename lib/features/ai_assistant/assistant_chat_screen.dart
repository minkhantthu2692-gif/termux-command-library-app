import 'package:flutter/material.dart';

import 'ai_chat_page.dart';

/// Route wrapper for `/assistant/chat`. Query parameters are parsed once by the
/// router and passed as immutable values so the page never depends on URL state
/// after it is opened.
class AssistantChatScreen extends StatelessWidget {
  const AssistantChatScreen({
    super.key,
    this.conversationId,
    this.commandId,
    this.initialPrompt,
  });

  final String? conversationId;
  final String? commandId;
  final String? initialPrompt;

  @override
  Widget build(BuildContext context) {
    return AiChatPage(
      conversationId: conversationId,
      commandId: commandId,
      initialPrompt: initialPrompt,
    );
  }
}
