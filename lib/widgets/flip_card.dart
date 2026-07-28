import 'dart:math';
import 'package:flutter/material.dart';

class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool isFlipped;
  final bool isHighlighted;
  final Color? borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTripleTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onLongPressEnd;
  final Duration flipDuration;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.isFlipped = false,
    this.isHighlighted = false,
    this.borderColor,
    this.onTap,
    this.onDoubleTap,
    this.onTripleTap,
    this.onLongPress,
    this.onLongPressEnd,
    this.flipDuration = const Duration(milliseconds: 400),
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Triple-tap detection
  int _tapCount = 0;
  DateTime? _lastTapTime;
  static const _tapTimeout = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.flipDuration,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isFlipped) {
      _controller.value = 1;
    }
  }

  void _handleTap() {
    final now = DateTime.now();

    if (_lastTapTime != null && now.difference(_lastTapTime!) < _tapTimeout) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }
    _lastTapTime = now;

    if (_tapCount == 3) {
      _tapCount = 0;
      widget.onTripleTap?.call();
    } else if (_tapCount == 2) {
      // Delay to check if it becomes triple tap
      Future.delayed(_tapTimeout, () {
        if (_tapCount == 2) {
          _tapCount = 0;
          widget.onDoubleTap?.call();
        }
      });
    } else if (_tapCount == 1) {
      // Delay to check if it becomes double/triple tap
      Future.delayed(_tapTimeout, () {
        if (_tapCount == 1) {
          _tapCount = 0;
          widget.onTap?.call();
        }
      });
    }
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      onLongPressEnd: (_) => widget.onLongPressEnd?.call(),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isFrontVisible = angle < pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            child: isFrontVisible
                ? _buildSide(widget.front)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildSide(widget.back),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSide(Widget child) {
    final borderColor = widget.borderColor ?? Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: widget.isHighlighted
            ? Border.all(
                color: borderColor,
                width: 2,
              )
            : null,
        boxShadow: widget.isHighlighted
            ? [
                BoxShadow(
                  color: borderColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }
}

/// Helper widget to build the card content
class FlipCardContent extends StatelessWidget {
  final String text;
  final bool isBack;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showSuccessfulBadge;
  final bool showUnsuccessfulBadge;
  final bool showPendingBadge;
  final VoidCallback? onStatusTap;

  const FlipCardContent({
    super.key,
    required this.text,
    this.isBack = false,
    this.backgroundColor,
    this.textColor,
    this.showSuccessfulBadge = false,
    this.showUnsuccessfulBadge = false,
    this.showPendingBadge = false,
    this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = !isBack && (showSuccessfulBadge || showUnsuccessfulBadge || showPendingBadge);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? (isBack ? Colors.grey[100] : Colors.grey[200]),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isBack ? 10 : 12,
                fontWeight: isBack ? FontWeight.normal : FontWeight.w600,
                color: textColor ?? Colors.grey[800],
              ),
              maxLines: isBack ? 5 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showBadge)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onStatusTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    showSuccessfulBadge
                        ? Icons.check_circle
                        : showUnsuccessfulBadge
                            ? Icons.cancel
                            : Icons.help,
                    color: showSuccessfulBadge
                        ? Colors.green[600]
                        : showUnsuccessfulBadge
                            ? Colors.red[600]
                            : Colors.grey[600],
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
