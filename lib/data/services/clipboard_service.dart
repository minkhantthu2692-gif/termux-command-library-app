import 'package:flutter/services.dart';

class ClipboardService {
  const ClipboardService();

  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
