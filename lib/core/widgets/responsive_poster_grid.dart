import 'package:flutter/material.dart';

class ResponsivePosterGrid extends StatelessWidget {
  const ResponsivePosterGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 210,
        childAspectRatio: 0.60,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
