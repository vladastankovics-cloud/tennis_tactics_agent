import 'package:flutter/material.dart';

/// A slider widget that shows two values for comparison:
/// - A reference value shown as a fixed marker (e.g., user's profile)
/// - An editable value shown as a draggable handle (e.g., opponent's profile)
class ComparisonSlider extends StatelessWidget {
  final String label;
  final int value;
  final int? referenceValue;
  final ValueChanged<int>? onChanged;
  final Color valueColor;
  final Color? referenceColor;
  final bool showValueOnLeft;

  const ComparisonSlider({
    super.key,
    required this.label,
    required this.value,
    this.referenceValue,
    this.onChanged,
    this.valueColor = Colors.blue,
    this.referenceColor,
    this.showValueOnLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEditable = onChanged != null;

    return Row(
      children: [
        // Label on the left
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),

        // Slider track on the right
        Expanded(
          flex: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final handleSize = 24.0;
              final halfHandle = handleSize / 2;

              return GestureDetector(
                onHorizontalDragUpdate: isEditable
                    ? (details) {
                        final rawValue = (details.localPosition.dx / trackWidth) * 100;
                        final newValue = ((rawValue / 5).round() * 5).clamp(0, 100);
                        onChanged!(newValue);
                      }
                    : null,
                onTapDown: isEditable
                    ? (details) {
                        final rawValue = (details.localPosition.dx / trackWidth) * 100;
                        final newValue = ((rawValue / 5).round() * 5).clamp(0, 100);
                        onChanged!(newValue);
                      }
                    : null,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Reference marker (fixed, non-draggable)
                      if (referenceValue != null && referenceColor != null)
                        Positioned(
                          left: (referenceValue! / 100) * trackWidth - halfHandle,
                          top: 2,
                          child: Container(
                            width: handleSize,
                            height: handleSize,
                            decoration: BoxDecoration(
                              color: referenceColor!.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: referenceColor!,
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                referenceValue.toString(),
                                style: TextStyle(
                                  color: referenceColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Editable value handle (draggable)
                      Positioned(
                        left: (value / 100) * trackWidth - halfHandle,
                        top: 2,
                        child: Container(
                          width: handleSize,
                          height: handleSize,
                          decoration: BoxDecoration(
                            color: valueColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: valueColor.withOpacity(0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              value.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Group header for comparison sliders showing averaged values
class ComparisonGroupHeader extends StatelessWidget {
  final String label;
  final int value;
  final int? referenceValue;
  final Color valueColor;
  final Color? referenceColor;

  const ComparisonGroupHeader({
    super.key,
    required this.label,
    required this.value,
    this.referenceValue,
    this.valueColor = Colors.blue,
    this.referenceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Label
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),

        // Value indicators
        Expanded(
          flex: 1,
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: valueColor, width: 2),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;
                final handleSize = 28.0;
                final halfHandle = handleSize / 2;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Reference marker
                    if (referenceValue != null && referenceColor != null)
                      Positioned(
                        left: (referenceValue! / 100) * trackWidth - halfHandle,
                        top: 0,
                        child: Container(
                          width: handleSize,
                          height: handleSize,
                          decoration: BoxDecoration(
                            color: referenceColor!.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: referenceColor!,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              referenceValue.toString(),
                              style: TextStyle(
                                color: referenceColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Main value
                    Positioned(
                      left: (value / 100) * trackWidth - halfHandle,
                      top: 0,
                      child: Container(
                        width: handleSize,
                        height: handleSize,
                        decoration: BoxDecoration(
                          color: valueColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: valueColor.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            value.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
