/// Drop-in `Scaffold` replacement that paints the app's dark blue-to-black
/// gradient behind everything — `ThemeData.scaffoldBackgroundColor` can
/// only express a flat color, so the gradient backdrop has to live here
/// instead. Every screen's bare `Scaffold(...)` should use this.
library;

import 'package:flutter/material.dart';

class GradientScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const GradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B1740), Color(0xFF0B0A18)],
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        body: body,
      ),
    );
  }
}
