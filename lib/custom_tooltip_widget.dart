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
    final screenPosition = MediaQuery.of(context).size.width * position.dx;

    return Positioned(
      left: screenPosition,
      top: position.dy,
      child: Material(
        elevation: 5.0,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(content),
        ),
      ),
    );
  }
}
