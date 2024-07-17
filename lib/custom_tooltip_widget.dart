import 'package:flutter/material.dart';

class CustomTooltipWidget extends StatelessWidget {
  final String content;
  final Offset position;

  const CustomTooltipWidget({
    Key? key,
    required this.content,
    required this.position,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate screen position based on the given Offset
    final screenPosition = position.dx + 20;

    return Positioned(
        left: screenPosition,
        top: position.dy,
        width: 50,
        child: Container(
          width: 50,
          height: 50,
          color: Colors.red,
        ));
  }
}
