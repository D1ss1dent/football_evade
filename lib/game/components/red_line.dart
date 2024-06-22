import 'package:flutter/material.dart';

class RedLine extends StatelessWidget {
  final double yPos;

  RedLine(this.yPos);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: yPos,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 1,
        color: Colors.red,
      ),
    );
  }
}
