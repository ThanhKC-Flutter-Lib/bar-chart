import 'package:flutter/material.dart';
import 'package:flutter_custom_line_chart/custom_tooltip_widget.dart';
import 'package:flutter_custom_line_chart/my_weight.dart';
import 'package:touchable/touchable.dart';

class BarChartPainter extends CustomPainter {
  final List<MyWeight> myWeightProgress;
  final double heightView;
  final double minWeight;
  final double maxWeight;
  final BuildContext context;
  final Function(MyWeight myWeight) onPointClick;

  BarChartPainter({
    required this.myWeightProgress,
    required this.heightView,
    required this.minWeight,
    required this.maxWeight,
    required this.context,
    required this.onPointClick,
  });
  // Your existing drawing logic here for background, axes, labels, etc.
  final tooltipLabelStyle = const TextStyle(color: Colors.white, fontSize: 12);

  late final tooltipPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill;
  OverlayEntry? _currentTooltipOverlayEntry;

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate bar width and spacing\
    final touchyCanvas = TouchyCanvas(context, canvas);
    final overlayPaint = Paint()..color = Colors.transparent;
    final barWidth = size.width /
        myWeightProgress.length *
        0.8; // 80% of the available space per bar
    final barSpacing =
        size.width / myWeightProgress.length * 0.2; // 20% for spacing

    // Draw bars

    final allUnfocused =
        myWeightProgress.every((element) => !element.isFocusing);
    List<Offset> points = [];

    for (int i = 0; i < myWeightProgress.length; i++) {
      final isFocusing = myWeightProgress[i].isFocusing;
      final weight = myWeightProgress[i];
      final barHeight =
          ((weight.weight - minWeight) / (maxWeight - minWeight)) * heightView;
      final barX = i * (barWidth + barSpacing);
      final barRect =
          Rect.fromLTWH(barX, heightView - barHeight, barWidth, barHeight);
      touchyCanvas.drawRect(
          barRect,
          Paint()
            ..color = allUnfocused
                ? Colors.blue
                : isFocusing
                    ? Colors.blue
                    : Colors.grey,
          onTapDown: (_) => onPointClick(weight));

      final double x = i * (barWidth + barSpacing) + barWidth / 2;
      final double y = heightView -
          ((myWeightProgress[i].weight - minWeight) / (maxWeight - minWeight)) *
              heightView;
      points.add(Offset(x, y));
    }

    //vẽ overlay để xác định vị trí tap
    touchyCanvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      overlayPaint,
      onTapDown: (details) {
        // Determine which bar is tapped based on the tap position
        final double barWidth = size.width / myWeightProgress.length * 0.8;
        final double barSpacing = size.width / myWeightProgress.length * 0.2;
        final int tappedIndex =
            (details.localPosition.dx / (barWidth + barSpacing)).floor();

        if (tappedIndex >= 0 && tappedIndex < myWeightProgress.length) {
          onPointClick(myWeightProgress[tappedIndex]);
        }
      },
    );

    // draw tooltip
    final tooltipLabels = _computeTooltipLabels(myWeightProgress);
    _drawTooltip(
      canvas: canvas,
      center: calculateCenter(points),
      labels: tooltipLabels,
      points: points,
      labelMaxWidth: 62,
      size: size,
    );

    // Your existing drawing logic here for tooltips, etc.
  }

  Offset calculateCenter(List<Offset> points) {
    double totalX = 0;
    double totalY = 0;
    for (Offset point in points) {
      totalX += point.dx;
      totalY += point.dy;
    }
    return Offset(totalX / points.length, totalY / points.length);
  }

  // Include your existing methods here (e.g., _getTextPainter, _computeYLabels, etc.)
  List<String> _computeTooltipLabels(List<MyWeight> myWeightProgress) {
    return myWeightProgress
        .map((e) => "${e.weight.toStringAsFixed(1)} kg")
        .toList();
  }

  void _drawTooltip({
    required Canvas canvas,
    required Offset center,
    required List<String> labels,
    required List<Offset> points,
    required double labelMaxWidth,
    required Size size,
  }) {
    for (var i = 0; i < labels.length; i++) {
      final myWeight = myWeightProgress[i];
      if (!myWeight.isFocusing) continue;
      final label = labels[i];
      final point = points[i];
      final textPainter =
          _getTextPainter(label, tooltipLabelStyle, labelMaxWidth);
      final double tooltipWidth = textPainter.width + 20;
      final double tooltipHeight = textPainter.height + 10;

      final bool isMaxHeight = point.dy < tooltipHeight * 2;

      // Adjust Y position for tooltip if column is at max height
      final double tooltipY;
      if (isMaxHeight) {
        // If the tooltip goes beyond the top of the view, draw it inside the view, potentially overlapping the column
        tooltipY = 0;
      } else {
        // Default case: Position tooltip above the column
        tooltipY = point.dy - (tooltipHeight + 5);
      }
      final Offset tooltipPosition =
          Offset(point.dx - tooltipWidth / 2, tooltipY);

      // Ensure tooltip stays within the canvas
      final double adjustedX =
          tooltipPosition.dx.clamp(0, size.width - tooltipWidth);
      final Offset adjustedPosition = Offset(adjustedX, tooltipPosition.dy);

      // Draw tooltip background
      final RRect tooltipBackground = RRect.fromRectAndRadius(
        Rect.fromLTWH(adjustedPosition.dx, adjustedPosition.dy, tooltipWidth,
            tooltipHeight),
        const Radius.circular(4),
      );
      // canvas.drawRRect(tooltipBackground, tooltipPaint);

      // Draw tooltip text
      final Offset textPosition =
          Offset(adjustedPosition.dx + 10, adjustedPosition.dy + 5);
      textPainter.paint(canvas, textPosition);
      showCustomTooltip(context, 'tooltipContent', adjustedPosition);

      final double barWidth = size.width / myWeightProgress.length * 0.8;
      final double barSpacing = size.width / myWeightProgress.length * 0.2;
      final double columnCenterX = i * (barWidth + barSpacing) + barWidth / 2;

      // Draw triangle
      final Path trianglePath = Path();
      const double triangleWidth = 10.0;
      const double triangleHeight = 5.0;
      final double triangleBaseY = tooltipY + tooltipHeight + 5;
      trianglePath.moveTo(columnCenterX, triangleBaseY);
      trianglePath.lineTo(
          columnCenterX - triangleWidth / 2, triangleBaseY - triangleHeight);
      trianglePath.lineTo(
          columnCenterX + triangleWidth / 2, triangleBaseY - triangleHeight);
      trianglePath.close();

      canvas.drawPath(trianglePath, tooltipPaint);
    }
  }

  TextPainter _getTextPainter(String text, TextStyle style, double maxWidth) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    textPainter.layout(minWidth: 0, maxWidth: maxWidth);
    return textPainter;
  }

  void showCustomTooltip(
      BuildContext context, String content, Offset position) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Remove existing tooltip if any
      _currentTooltipOverlayEntry?.remove();
      _currentTooltipOverlayEntry = null;

      _currentTooltipOverlayEntry = OverlayEntry(
        builder: (context) =>
            CustomTooltipWidget(content: content, position: position),
      );

      // Find the overlay and insert the tooltip
      Overlay.of(context).insert(_currentTooltipOverlayEntry!);
    });
  }

  void hideCustomTooltip() {
    _currentTooltipOverlayEntry?.remove();
    _currentTooltipOverlayEntry = null;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
