import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented whenever Ctrl+F is pressed so the Search screen can request
/// focus on its text field.
class SearchFocusSignal extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() => state++;
}

final searchFocusSignalProvider =
    NotifierProvider<SearchFocusSignal, int>(SearchFocusSignal.new);

final searchFocusNodeProvider = Provider.autoDispose<FocusNode>((ref) {
  final node = FocusNode(debugLabel: 'search_input');
  ref.onDispose(node.dispose);
  return node;
});
