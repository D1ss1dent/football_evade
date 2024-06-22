import 'package:flutter/material.dart';

class TransparentDialog extends StatelessWidget {
  final Widget child;

  TransparentDialog({required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: child,
    );
  }
}
