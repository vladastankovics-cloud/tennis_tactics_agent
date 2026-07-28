import 'dart:math';
import 'package:flutter/material.dart';

/// Data model for a tactic bubble
class TacticBubbleData {
  final String shortName;
  final String description;
  final int count;
  final int? latestAt;
  final bool isStrength; // true = worked (strength), false = didn't work (weakness)
  final bool isHidden; // true = hidden by user

  TacticBubbleData({
    required this.shortName,
    required this.description,
    required this.count,
    this.latestAt,
    this.isStrength = true,
    this.isHidden = false,
  });

  factory TacticBubbleData.fromMap(Map<String, dynamic> map, {bool isStrength = true, bool isHidden = false}) {
    return TacticBubbleData(
      shortName: map['short_name'] as String,
      description: map['description'] as String,
      count: map['count'] as int,
      latestAt: map['latest_at'] as int?,
      isStrength: isStrength,
      isHidden: isHidden,
    );
  }

  TacticBubbleData copyWith({
    String? shortName,
    String? description,
    int? count,
    int? latestAt,
    bool? isStrength,
    bool? isHidden,
  }) {
    return TacticBubbleData(
      shortName: shortName ?? this.shortName,
      description: description ?? this.description,
      count: count ?? this.count,
      latestAt: latestAt ?? this.latestAt,
      isStrength: isStrength ?? this.isStrength,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}

/// Internal bubble state for physics simulation
class _BubbleState {
  TacticBubbleData data;
  Offset position;
  Offset velocity;
  double radius;
  double dragOffsetX; // Track horizontal drag for swipe-to-dismiss
  bool isDismissing; // Animation state for cross-out
  bool isUnhiding; // Animation state for unhide (immediately show as recovered)

  _BubbleState({
    required this.data,
    required this.position,
    required this.radius,
  }) : velocity = Offset.zero,
       dragOffsetX = 0,
       isDismissing = false,
       isUnhiding = false;
}

/// A unified bubble chart with physics-based positioning
/// Strengths are blue, weaknesses are green (hard court colors)
class TacticBubbleChart extends StatefulWidget {
  final List<TacticBubbleData> bubbles;
  final Function(TacticBubbleData)? onTap;
  final Function(TacticBubbleData)? onDismiss;
  final Function(TacticBubbleData)? onUnhide; // Called when swiping right on hidden bubble
  final String emptyMessage;

  // Hard court colors
  static const Color strengthColor = Color(0xFF3B82C4); // Court blue
  static const Color weaknessColor = Color(0xFF6B8F55); // Surround green

  const TacticBubbleChart({
    super.key,
    required this.bubbles,
    this.onTap,
    this.onDismiss,
    this.onUnhide,
    this.emptyMessage = 'No tactics yet',
  });

  @override
  State<TacticBubbleChart> createState() => _TacticBubbleChartState();
}

class _TacticBubbleChartState extends State<TacticBubbleChart> with SingleTickerProviderStateMixin {
  List<_BubbleState> _bubbleStates = [];
  int? _draggedIndex;
  late AnimationController _controller;
  Size _containerSize = Size.zero;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_physicsStep);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TacticBubbleChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bubbles != widget.bubbles) {
      // Check if only isHidden changed (same bubbles, just visibility update)
      final oldNames = oldWidget.bubbles.map((b) => b.shortName).toSet();
      final newNames = widget.bubbles.map((b) => b.shortName).toSet();

      if (oldNames.length == newNames.length && oldNames.containsAll(newNames)) {
        // Same bubbles, just update data in place (smooth transition)
        for (var state in _bubbleStates) {
          final newData = widget.bubbles.firstWhere(
            (b) => b.shortName == state.data.shortName,
            orElse: () => state.data,
          );
          state.data = newData;
          // Reset animation states when data is updated
          state.isDismissing = false;
          state.isUnhiding = false;
          state.dragOffsetX = 0;
        }
        // Schedule a rebuild to reflect updated data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      } else {
        // Different bubbles, reinitialize
        _initialized = false;
      }
    }
  }

  void _initializeBubbles(Size size) {
    if (_initialized && _containerSize == size) return;

    _containerSize = size;
    _initialized = true;

    final random = Random(42); // Fixed seed for consistent layout
    final bubbles = widget.bubbles;

    if (bubbles.isEmpty) {
      _bubbleStates = [];
      return;
    }

    // Calculate sizes based on count - maximize bubble sizes
    final totalCount = bubbles.fold<int>(0, (sum, b) => sum + b.count);
    final minDimension = min(size.width, size.height);
    final maxDimension = max(size.width, size.height);

    // Use more of the available space
    final baseSize = minDimension * 0.12;
    final maxSize = minDimension * 0.35;

    _bubbleStates = bubbles.map((bubble) {
      final sizeRatio = bubble.count / totalCount;
      // Larger size range for bigger bubbles
      var radius = baseSize + maxDimension * sizeRatio * 0.15;
      radius = radius.clamp(35.0, maxSize);

      // Random initial position within bounds
      final x = radius + random.nextDouble() * (size.width - 2 * radius);
      final y = radius + random.nextDouble() * (size.height - 2 * radius);

      return _BubbleState(
        data: bubble,
        position: Offset(x, y),
        radius: radius,
      );
    }).toList();

    // Run physics simulation to settle bubbles
    _settleBubbles();
  }

  void _settleBubbles() {
    // Run several iterations to settle bubbles
    for (int i = 0; i < 100; i++) {
      _applyForces();
      _updatePositions(0.3);
    }
    // Clear velocities after settling
    for (var bubble in _bubbleStates) {
      bubble.velocity = Offset.zero;
    }
  }

  void _physicsStep() {
    if (_bubbleStates.isEmpty) return;

    _applyForces();
    _updatePositions(0.5);

    // Check if settled
    bool settled = true;
    for (var bubble in _bubbleStates) {
      if (bubble.velocity.distance > 0.1) {
        settled = false;
        break;
      }
    }

    if (settled && _draggedIndex == null) {
      _controller.stop();
    }

    setState(() {});
  }

  void _applyForces() {
    final center = Offset(_containerSize.width / 2, _containerSize.height / 2);

    for (int i = 0; i < _bubbleStates.length; i++) {
      if (i == _draggedIndex) continue;

      var bubble = _bubbleStates[i];
      var force = Offset.zero;

      // Repulsion from other bubbles (prevent overlap)
      for (int j = 0; j < _bubbleStates.length; j++) {
        if (i == j) continue;

        final other = _bubbleStates[j];
        final diff = bubble.position - other.position;
        final distance = diff.distance;
        final minDistance = bubble.radius + other.radius;

        if (distance < minDistance && distance > 0) {
          // Strong repulsion when overlapping
          final overlap = minDistance - distance;
          final direction = diff / distance;
          force += direction * overlap * 2.0;
        } else if (distance < minDistance * 1.5 && distance > 0) {
          // Gentle attraction to make bubbles touch
          final gap = distance - minDistance;
          final direction = diff / distance;
          force -= direction * gap * 0.3;
        }
      }

      // Gentle attraction to center
      final toCenter = center - bubble.position;
      force += toCenter * 0.01;

      // Wall repulsion
      if (bubble.position.dx < bubble.radius) {
        force += Offset((bubble.radius - bubble.position.dx) * 0.5, 0);
      }
      if (bubble.position.dx > _containerSize.width - bubble.radius) {
        force += Offset((_containerSize.width - bubble.radius - bubble.position.dx) * 0.5, 0);
      }
      if (bubble.position.dy < bubble.radius) {
        force += Offset(0, (bubble.radius - bubble.position.dy) * 0.5);
      }
      if (bubble.position.dy > _containerSize.height - bubble.radius) {
        force += Offset(0, (_containerSize.height - bubble.radius - bubble.position.dy) * 0.5);
      }

      bubble.velocity += force;
      bubble.velocity *= 0.8; // Damping
    }
  }

  void _updatePositions(double dt) {
    for (int i = 0; i < _bubbleStates.length; i++) {
      if (i == _draggedIndex) continue;

      var bubble = _bubbleStates[i];
      bubble.position += bubble.velocity * dt;

      // Clamp to bounds
      bubble.position = Offset(
        bubble.position.dx.clamp(bubble.radius, _containerSize.width - bubble.radius),
        bubble.position.dy.clamp(bubble.radius, _containerSize.height - bubble.radius),
      );
    }
  }

  // Find which bubble was hit at the given position
  // Check in reverse z-order (top to bottom) - blue first, then green
  int? _findBubbleAtPosition(Offset position, List<int> sortedIndices) {
    // Check from top of z-order (end of sorted list) to bottom
    for (int i = sortedIndices.length - 1; i >= 0; i--) {
      final index = sortedIndices[i];
      final state = _bubbleStates[index];
      final distance = (position - state.position).distance;
      if (distance <= state.radius) {
        return index;
      }
    }
    return null;
  }

  void _handleTapUp(TapUpDetails details, List<int> sortedIndices) {
    final index = _findBubbleAtPosition(details.localPosition, sortedIndices);
    if (index != null && widget.onTap != null && !_bubbleStates[index].isDismissing) {
      widget.onTap!(_bubbleStates[index].data);
    }
  }

  void _handlePanStart(DragStartDetails details, List<int> sortedIndices) {
    final index = _findBubbleAtPosition(details.localPosition, sortedIndices);
    if (index != null) {
      _draggedIndex = index;
      _bubbleStates[index].dragOffsetX = 0;
      _controller.repeat();
      setState(() {}); // Trigger rebuild to update z-order
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_draggedIndex == null) return;

    final bubble = _bubbleStates[_draggedIndex!];

    // Track horizontal offset for swipe-to-dismiss
    bubble.dragOffsetX += details.delta.dx;

    // Move bubble
    bubble.position += details.delta;

    // Clamp to bounds
    bubble.position = Offset(
      bubble.position.dx.clamp(bubble.radius, _containerSize.width - bubble.radius),
      bubble.position.dy.clamp(bubble.radius, _containerSize.height - bubble.radius),
    );

    setState(() {});
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_draggedIndex == null) return;
    _onPanEndForIndex(_draggedIndex!, details);
  }

  void _onPanEndForIndex(int index, DragEndDetails details) {
    final bubble = _bubbleStates[index];

    // Check if bubble is at the left edge of screen to dismiss (within 10px margin)
    final distanceFromLeft = bubble.position.dx - bubble.radius;
    final atLeftEdge = distanceFromLeft <= 10;

    // Check if bubble is at the right edge of screen to unhide (within 10px margin)
    final distanceFromRight = _containerSize.width - bubble.position.dx - bubble.radius;
    final atRightEdge = distanceFromRight <= 10;

    if (atLeftEdge && widget.onDismiss != null && !bubble.data.isHidden) {
      // Trigger dismiss animation
      bubble.isDismissing = true;
      setState(() {});

      // Delay to show cross-out animation, then dismiss
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          widget.onDismiss!(bubble.data);
        }
      });
    }
    else if (atRightEdge && widget.onUnhide != null && bubble.data.isHidden) {
      // Immediately show as unhidden (colorful, no strikethrough)
      bubble.isUnhiding = true;
      setState(() {});
      // Trigger unhide callback
      widget.onUnhide!(bubble.data);
    }
    else if (bubble.data.isHidden && !atRightEdge) {
      // Debug: why didn't unhide trigger?
      debugPrint('⚠️ Unhide not triggered: distanceFromRight=$distanceFromRight, containerWidth=${_containerSize.width}, bubbleX=${bubble.position.dx}, radius=${bubble.radius}');
    }

    bubble.dragOffsetX = 0;
    _draggedIndex = null;
    // Physics will continue to settle
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bubbles.isEmpty) {
      return Center(
        child: Text(
          widget.emptyMessage,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _initializeBubbles(size);

        // Sort indices: blue (strength) always on top of green (weakness)
        // EXCEPT: the currently dragged bubble is always on very top (so user can see it)
        final sortedIndices = List.generate(_bubbleStates.length, (i) => i)
          ..sort((a, b) {
            // Dragged bubble always on very top (for visibility while dragging)
            if (_draggedIndex == a) return 1;
            if (_draggedIndex == b) return -1;

            // Blue (strength) bubbles on top of green (weakness)
            final aStrength = _bubbleStates[a].data.isStrength;
            final bStrength = _bubbleStates[b].data.isStrength;
            if (aStrength && !bStrength) return 1;
            if (!aStrength && bStrength) return -1;

            return 0;
          });

        // Use stack-level gesture detection to allow hitting bubbles under others
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) => _handleTapUp(details, sortedIndices),
          onPanStart: (details) => _handlePanStart(details, sortedIndices),
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: Stack(
          children: sortedIndices.map((index) {
            final state = _bubbleStates[index];
            final bubble = state.data;
            // Safety: reset isDismissing for already-hidden bubbles
            if (bubble.isHidden && state.isDismissing) {
              state.isDismissing = false;
            }
            final color = bubble.isStrength
                ? TacticBubbleChart.strengthColor
                : TacticBubbleChart.weaknessColor;

            // Calculate swipe progress for visual feedback - only for the bubble being dragged
            final isDragging = _draggedIndex == index;
            final distanceFromLeft = state.position.dx - state.radius;
            final distanceFromRight = size.width - state.radius - state.position.dx;
            // Show cross-out when within 50 pixels of left edge (only when dragging non-hidden bubbles)
            final swipeProgress = (isDragging && !bubble.isHidden && !state.isDismissing)
                ? (1.0 - (distanceFromLeft / 50)).clamp(0.0, 1.0)
                : 0.0;
            // Show unhide progress when within 50 pixels of right edge (only when dragging)
            final unhideProgress = (isDragging && bubble.isHidden)
                ? (1.0 - (distanceFromRight / 50)).clamp(0.0, 1.0)
                : 0.0;
            // isUnhiding means we've triggered unhide - show as recovered immediately
            // isDismissing means we're hiding - show as hidden immediately (strikethrough, not cross)
            final isHidden = (bubble.isHidden || state.isDismissing) && !state.isUnhiding;
            // Hidden bubbles have paler color
            final opacity = isHidden ? 0.6 : 1.0;

            return Positioned(
              left: state.position.dx - state.radius,
              top: state.position.dy - state.radius,
              child: IgnorePointer(
                // Gestures are handled at Stack level
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: opacity,
                  child: Stack(
                    children: [
                      Container(
                        width: state.radius * 2,
                        height: state.radius * 2,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    bubble.shortName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: state.radius * 0.28,
                                      fontWeight: FontWeight.bold,
                                      decoration: (isHidden && unhideProgress == 0)
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: Colors.white,
                                      decorationThickness: 2,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (bubble.count > 1) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'x${bubble.count}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: state.radius * 0.2,
                                      decoration: (isHidden && unhideProgress == 0)
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Cross-out overlay only when actively swiping left to hide (not when already dismissing or hidden)
                      if (swipeProgress > 0 && !bubble.isHidden && !state.isDismissing)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CrossOutPainter(
                              progress: state.isDismissing ? 1.0 : swipeProgress,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      // Plus overlay when swiping right to unhide
                      if (unhideProgress > 0)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PlusSignPainter(
                              progress: unhideProgress,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        );
      },
    );
  }
}

/// Custom painter for cross-out effect
class _CrossOutPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CrossOutPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color.withOpacity(0.8 * progress)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Draw X
    final offset = radius * 0.5;

    // First line of X (top-left to bottom-right)
    final line1Start = center + Offset(-offset, -offset);
    final line1End = center + Offset(offset * progress, offset * progress);
    canvas.drawLine(line1Start, line1End, paint);

    // Second line of X (top-right to bottom-left)
    if (progress > 0.5) {
      final secondProgress = (progress - 0.5) * 2;
      final line2Start = center + Offset(offset, -offset);
      final line2End = center + Offset(-offset * secondProgress, offset * secondProgress);
      canvas.drawLine(line2Start, line2End, paint);
    }
  }

  @override
  bool shouldRepaint(_CrossOutPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Custom painter for plus sign effect (when restoring hidden bubble)
class _PlusSignPainter extends CustomPainter {
  final double progress;
  final Color color;

  _PlusSignPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color.withOpacity(0.8 * progress)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final offset = radius * 0.5;

    // Draw vertical line of +
    final vertStart = center + Offset(0, -offset);
    final vertEnd = center + Offset(0, offset * progress);
    canvas.drawLine(vertStart, vertEnd, paint);

    // Draw horizontal line of + (after vertical is half done)
    if (progress > 0.5) {
      final horizProgress = (progress - 0.5) * 2;
      final horizStart = center + Offset(-offset * horizProgress, 0);
      final horizEnd = center + Offset(offset * horizProgress, 0);
      canvas.drawLine(horizStart, horizEnd, paint);
    }
  }

  @override
  bool shouldRepaint(_PlusSignPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// Keep old widget for backwards compatibility but mark deprecated
@Deprecated('Use TacticBubbleChart instead')
class TacticBubbleContainer extends StatelessWidget {
  final List<TacticBubbleData> bubbles;
  final Color color;
  final Function(TacticBubbleData)? onTap;
  final Function(TacticBubbleData)? onDismiss;
  final String emptyMessage;

  const TacticBubbleContainer({
    super.key,
    required this.bubbles,
    required this.color,
    this.onTap,
    this.onDismiss,
    this.emptyMessage = 'No tactics yet',
  });

  @override
  Widget build(BuildContext context) {
    // Convert to new format - assume all are strengths since color was passed
    final isStrength = color == TacticBubbleChart.strengthColor;
    final convertedBubbles = bubbles.map((b) => TacticBubbleData(
      shortName: b.shortName,
      description: b.description,
      count: b.count,
      latestAt: b.latestAt,
      isStrength: isStrength,
    )).toList();

    return TacticBubbleChart(
      bubbles: convertedBubbles,
      onTap: onTap,
      onDismiss: onDismiss,
      emptyMessage: emptyMessage,
    );
  }
}
