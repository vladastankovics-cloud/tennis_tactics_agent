import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Represents a player position on the court
class CourtPosition {
  final double x; // 0.0 = left, 1.0 = right
  final double y; // 0.0 = far baseline (opponent), 1.0 = near baseline (player)
  final String label; // "P", "O", "P1", "P2", "O1", "O2"

  const CourtPosition({
    required this.x,
    required this.y,
    required this.label,
  });

  factory CourtPosition.fromMap(Map<String, dynamic> map) {
    return CourtPosition(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      label: map['label'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'x': x, 'y': y, 'label': label};
  }
}

/// Represents a movement on the tennis court (player, opponent, or ball)
class CourtMovement {
  final double fromX;
  final double fromY;
  final double toX;
  final double toY;
  final String type; // "player", "opponent", "ball"
  final String? shotLabel; // e.g., "FHTS" (forehand topspin), "BHSL" (backhand slice)

  const CourtMovement({
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    this.type = 'player',
    this.shotLabel,
  });

  factory CourtMovement.fromMap(Map<String, dynamic> map) {
    final from = map['from'] as Map<String, dynamic>;
    final to = map['to'] as Map<String, dynamic>;
    return CourtMovement(
      fromX: (from['x'] as num).toDouble(),
      fromY: (from['y'] as num).toDouble(),
      toX: (to['x'] as num).toDouble(),
      toY: (to['y'] as num).toDouble(),
      type: map['type'] as String? ?? 'player',
      shotLabel: map['shot'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'from': {'x': fromX, 'y': fromY},
      'to': {'x': toX, 'y': toY},
      'type': type,
      if (shotLabel != null) 'shot': shotLabel,
    };
  }
}

/// An animated widget that displays a tennis court diagram with sequential playback
class TennisCourtDiagram extends StatefulWidget {
  final List<CourtMovement> movements;
  final List<CourtPosition> positions;

  const TennisCourtDiagram({
    super.key,
    this.movements = const [],
    this.positions = const [],
  });

  @override
  State<TennisCourtDiagram> createState() => _TennisCourtDiagramState();
}

class _TennisCourtDiagramState extends State<TennisCourtDiagram>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPlaying = true; // Auto-play by default

  // Duration per movement in milliseconds (slower for better visibility)
  static const int _msPerMovement = 2200;

  @override
  void initState() {
    super.initState();
    final totalDuration = widget.movements.isEmpty
        ? 1000
        : widget.movements.length * _msPerMovement;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalDuration),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Loop immediately - no pause between rallies
        if (mounted && _isPlaying) {
          _controller.reset();
          _controller.forward();
        }
      }
    });
    // Auto-start animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.movements.isNotEmpty) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        if (_controller.isCompleted) {
          _controller.reset();
        }
        _controller.forward();
      } else {
        _controller.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const aspectRatio = 0.55;

    return GestureDetector(
      onTap: _togglePlayPause,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _AnimatedTennisCourtPainter(
                      movements: widget.movements,
                      positions: widget.positions,
                      animationProgress: _controller.value,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
              // Play/pause indicator
              if (!_isPlaying && widget.movements.isNotEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedTennisCourtPainter extends CustomPainter {
  final List<CourtMovement> movements;
  final List<CourtPosition> positions;
  final double animationProgress; // 0.0 to 1.0

  // Court colors - using app theme secondary green
  static const Color surroundGreen = Color(0xFF6B8F55);
  static const Color courtBlue = Color(0xFF3B82C4);
  static const Color lineWhite = Colors.white;
  static const Color playerColor = Colors.white;
  static const Color opponentColor = Colors.black;
  static const Color ballColor = Color(0xFFFFD700);

  _AnimatedTennisCourtPainter({
    required this.movements,
    required this.positions,
    required this.animationProgress,
  });

  static const double surroundRatio = 0.12;

  @override
  void paint(Canvas canvas, Size size) {
    _drawSurround(canvas, size);
    _drawCourtSurface(canvas, size);
    _drawCourtLines(canvas, size);

    // Find initial positions from positions list or use defaults
    double playerX = 0.5, playerY = 0.82;
    double opponentX = 0.5, opponentY = 0.18;

    for (final pos in positions) {
      if (pos.label == 'P') {
        playerX = pos.x;
        playerY = pos.y;
      } else if (pos.label == 'O') {
        opponentX = pos.x;
        opponentY = pos.y;
      }
    }

    if (movements.isEmpty) {
      // Static mode - just draw positions
      _drawPosition(canvas, size, CourtPosition(x: playerX, y: playerY, label: 'P'));
      _drawPosition(canvas, size, CourtPosition(x: opponentX, y: opponentY, label: 'O'));
      return;
    }

    // Calculate which movement we're on and progress within that movement
    final totalMovements = movements.length;
    final progressPerMovement = 1.0 / totalMovements;
    final currentMovementIndex = (animationProgress / progressPerMovement).floor();
    final clampedIndex = currentMovementIndex.clamp(0, totalMovements - 1);
    final movementLocalProgress =
        ((animationProgress - (clampedIndex * progressPerMovement)) / progressPerMovement)
            .clamp(0.0, 1.0);

    // Track animated positions (start from initial positions)
    double animPlayerX = playerX, animPlayerY = playerY;
    double animOpponentX = opponentX, animOpponentY = opponentY;

    // Track target positions for smooth movement
    double targetPlayerX = playerX, targetPlayerY = playerY;
    double targetOpponentX = opponentX, targetOpponentY = opponentY;

    // Find current ball movement index for fading logic
    int currentBallIndex = 0;
    for (int i = 0; i <= clampedIndex && i < totalMovements; i++) {
      if (movements[i].type == 'ball') currentBallIndex++;
    }

    // First pass: calculate final positions up to current movement
    for (int i = 0; i <= clampedIndex && i < totalMovements; i++) {
      final movement = movements[i];

      if (movement.type == 'player') {
        targetPlayerX = movement.toX;
        targetPlayerY = movement.toY;
      } else if (movement.type == 'opponent') {
        targetOpponentX = movement.toX;
        targetOpponentY = movement.toY;
      } else if (movement.type == 'ball') {
        // Ball going to player side (y > 0.5) = player moves to intercept
        // Ball going to opponent side (y < 0.5) = opponent moves to intercept
        if (movement.toY > 0.5) {
          // Ball going to player's side - player moves to ball landing
          targetPlayerX = movement.toX;
          targetPlayerY = math.max(movement.toY, 0.55); // Can move into green for deep balls
        } else {
          // Ball going to opponent's side - opponent moves to ball landing
          targetOpponentX = movement.toX;
          targetOpponentY = math.min(movement.toY, 0.45); // Can move into green for deep balls
        }
      }
    }

    // Draw completed movements and update positions
    int ballIndex = 0;
    double prevPlayerX = playerX, prevPlayerY = playerY;
    double prevOpponentX = opponentX, prevOpponentY = opponentY;

    // Track the current ball movement for spinning ball display
    CourtMovement? currentBallMovement;
    double currentBallProgress = 0.0;

    // First pass: find the previous ball movement index for fading
    int previousBallMovementIndex = -1;
    int currentBallMovementIndex = -1;
    for (int i = 0; i < totalMovements; i++) {
      if (movements[i].type == 'ball') {
        if (i < clampedIndex) {
          previousBallMovementIndex = i;
        } else if (i == clampedIndex) {
          currentBallMovementIndex = i;
        }
      }
    }

    for (int i = 0; i < totalMovements; i++) {
      final movement = movements[i];
      final isBall = movement.type == 'ball';

      if (isBall) ballIndex++;

      if (i < clampedIndex) {
        // Completed movement - only draw the previous ball trajectory with fading
        if (isBall && i == previousBallMovementIndex) {
          // Fade out the previous shot as the current one progresses
          final fadeOpacity = currentBallMovementIndex >= 0
              ? (1.0 - movementLocalProgress * 0.8).clamp(0.2, 1.0)
              : 1.0;
          _drawBallTrajectoryWithOpacity(canvas, size, movement, 1.0, fadeOpacity);
        }

        // Update positions after movement completes
        if (movement.type == 'player') {
          prevPlayerX = movement.toX;
          prevPlayerY = movement.toY;
        } else if (movement.type == 'opponent') {
          prevOpponentX = movement.toX;
          prevOpponentY = movement.toY;
        } else if (isBall) {
          // Determine who hit and who receives
          final playerHit = movement.fromY > 0.5;
          final isVolley = movement.shotLabel?.toUpperCase().contains('VOL') ?? false;
          final isApproach = movement.fromY > 0.4 && movement.fromY < 0.6;
          final isLob = movement.shotLabel?.toUpperCase().contains('LOB') ?? false;

          if (playerHit) {
            // Player hit, opponent receives - opponent moves behind ball to hit in front
            prevOpponentX = movement.toX;
            if (isLob && movement.toY < 0.15) {
              // Lob going deep - opponent runs back
              prevOpponentY = movement.toY + 0.05;
            } else {
              prevOpponentY = math.min(movement.toY - 0.08, 0.40);
            }
            // Player recovers to center or approaches net
            if (isVolley || isApproach) {
              prevPlayerX = _lerp(prevPlayerX, 0.5, 0.5);
              prevPlayerY = math.min(prevPlayerY, 0.6); // Move toward net
            } else {
              prevPlayerX = _lerp(prevPlayerX, 0.5, 0.6); // Recover toward center
              prevPlayerY = 0.82; // Back to baseline
            }
          } else {
            // Opponent hit, player receives - player moves behind ball to hit in front
            prevPlayerX = movement.toX;
            if (isLob && movement.toY > 0.85) {
              // Lob going deep - player runs back
              prevPlayerY = movement.toY - 0.05;
            } else {
              prevPlayerY = math.max(movement.toY + 0.08, 0.60);
            }
            // Opponent recovers to center or approaches net
            if (isVolley || isApproach) {
              prevOpponentX = _lerp(prevOpponentX, 0.5, 0.5);
              prevOpponentY = math.max(prevOpponentY, 0.4); // Move toward net
            } else {
              prevOpponentX = _lerp(prevOpponentX, 0.5, 0.6); // Recover toward center
              prevOpponentY = 0.18; // Back to baseline
            }
          }
        }
      } else if (i == clampedIndex) {
        // Currently animating movement - only draw ball trajectories
        if (isBall) {
          _drawBallTrajectory(canvas, size, movement, movementLocalProgress);
          currentBallMovement = movement;
          currentBallProgress = movementLocalProgress;
        }

        // Animate positions with easing
        final easedProgress = _easeInOut(movementLocalProgress);

        if (movement.type == 'player') {
          animPlayerX = _lerp(prevPlayerX, movement.toX, easedProgress);
          animPlayerY = _lerp(prevPlayerY, movement.toY, easedProgress);
          animOpponentX = prevOpponentX;
          animOpponentY = prevOpponentY;
        } else if (movement.type == 'opponent') {
          animOpponentX = _lerp(prevOpponentX, movement.toX, easedProgress);
          animOpponentY = _lerp(prevOpponentY, movement.toY, easedProgress);
          animPlayerX = prevPlayerX;
          animPlayerY = prevPlayerY;
        } else if (isBall) {
          // Determine who hit and who receives
          final playerHit = movement.fromY > 0.5;
          final isLob = movement.shotLabel?.toUpperCase().contains('LOB') ?? false;

          if (playerHit) {
            // Player hit the ball - opponent moves to intercept
            // Position opponent BEHIND the ball (closer to their baseline) so they hit in front
            final ballLandY = movement.toY;
            double targetOpponentY;
            if (isLob && ballLandY < 0.15) {
              // Lob going deep behind opponent - they run back and hit from behind
              targetOpponentY = ballLandY + 0.05;
            } else {
              // Normal shot - opponent positions behind ball to hit in front
              targetOpponentY = math.min(ballLandY - 0.08, 0.40);
            }
            animOpponentX = _lerp(prevOpponentX, movement.toX, easedProgress);
            animOpponentY = _lerp(prevOpponentY, targetOpponentY, easedProgress);

            // Player stays at their current position (where they hit from)
            animPlayerX = prevPlayerX;
            animPlayerY = prevPlayerY;
          } else {
            // Opponent hit the ball - player moves to intercept
            // Position player BEHIND the ball (closer to their baseline) so they hit in front
            final ballLandY = movement.toY;
            double targetPlayerY;
            if (isLob && ballLandY > 0.85) {
              // Lob going deep behind player - they run back and hit from behind
              targetPlayerY = ballLandY - 0.05;
            } else {
              // Normal shot - player positions behind ball to hit in front
              targetPlayerY = math.max(ballLandY + 0.08, 0.60);
            }
            animPlayerX = _lerp(prevPlayerX, movement.toX, easedProgress);
            animPlayerY = _lerp(prevPlayerY, targetPlayerY, easedProgress);

            // Opponent stays at their current position (where they hit from)
            animOpponentX = prevOpponentX;
            animOpponentY = prevOpponentY;
          }
        }
      }
    }

    // Always draw the ball (find current or last ball position)
    if (currentBallMovement != null) {
      _drawSpinningBall(canvas, size, currentBallMovement!, currentBallProgress, animationProgress);
    } else if (movements.isNotEmpty) {
      // Find last ball movement and draw ball at its end position
      for (int i = movements.length - 1; i >= 0; i--) {
        if (movements[i].type == 'ball' && i < clampedIndex) {
          _drawSpinningBall(canvas, size, movements[i], 1.0, animationProgress);
          break;
        }
      }
    }

    // Draw player and opponent at their current animated positions
    _drawPosition(canvas, size, CourtPosition(x: animPlayerX, y: animPlayerY, label: 'P'));
    _drawPosition(canvas, size, CourtPosition(x: animOpponentX, y: animOpponentY, label: 'O'));
  }

  double _easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : (1 - math.pow(-2 * t + 2, 2) / 2).toDouble();
  }

  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  // Draw ball trajectory (yellow dashed line) without labels
  void _drawBallTrajectory(Canvas canvas, Size size, CourtMovement movement, double progress) {
    _drawBallTrajectoryWithOpacity(canvas, size, movement, progress, 1.0);
  }

  // Draw ball trajectory with opacity for fading effect
  void _drawBallTrajectoryWithOpacity(Canvas canvas, Size size, CourtMovement movement, double progress, double opacity) {
    if (progress <= 0 || opacity <= 0) return;

    final from = _courtToCanvas(size, movement.fromX, movement.fromY);
    final fullTo = _courtToCanvas(size, movement.toX, movement.toY);

    final to = Offset(
      _lerp(from.dx, fullTo.dx, progress),
      _lerp(from.dy, fullTo.dy, progress),
    );

    final color = ballColor.withOpacity(opacity);
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    _drawDashedLine(canvas, from, to, arrowPaint);

    // Always show arrowhead at the current ball position
    if (progress > 0.05) {
      _drawArrowhead(canvas, from, to, color);
    }
  }

  // Draw spinning tennis ball with seam lines showing spin type
  // Rotation is based on travel direction and spin type
  void _drawSpinningBall(Canvas canvas, Size size, CourtMovement movement, double progress, double totalProgress) {
    final fromPos = _courtToCanvas(size, movement.fromX, movement.fromY);
    final toPos = _courtToCanvas(size, movement.toX, movement.toY);

    // Ease-out curve for more realistic ball motion
    final easedProgress = (1 - math.pow(1 - progress, 2)).toDouble();

    final currentX = _lerp(fromPos.dx, toPos.dx, easedProgress);
    final currentY = _lerp(fromPos.dy, toPos.dy, easedProgress);

    final ballRadius = 10.0;

    // Calculate travel direction angle (from source to destination)
    final dx = toPos.dx - fromPos.dx;
    final dy = toPos.dy - fromPos.dy;
    final travelAngle = math.atan2(dy, dx);

    // Determine spin type from shot label
    final shotLabel = movement.shotLabel?.toUpperCase() ?? '';
    final isServe = shotLabel.contains('SV') || shotLabel.contains('SERVE');
    final hasTopspin = shotLabel.contains('TS') || shotLabel.contains('TOP') || shotLabel.contains('KICK') || shotLabel.contains('HEAVY');
    final hasSlice = shotLabel.contains('SL') || shotLabel.contains('SLICE');
    final hasFlat = shotLabel.contains('FL') || shotLabel.contains('FLAT');
    final isDropShot = shotLabel.contains('DROP');
    final isLeftHanded = shotLabel.contains('LEFT') || shotLabel.contains('LH');

    // Determine who hit the ball (player is y > 0.5, opponent is y < 0.5)
    final playerHit = movement.fromY > 0.5;

    // Only spin if topspin, slice, or drop shot is mentioned (not flat or unspecified)
    final shouldSpin = hasTopspin || hasSlice || isDropShot;

    // Draw ball shadow
    final shadowPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(currentX + 2, currentY + 2), ballRadius, shadowPaint);

    // Draw tennis ball - yellow
    final ballPaint = Paint()
      ..color = const Color(0xFFFFD700) // Tennis ball yellow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(currentX, currentY), ballRadius, ballPaint);

    canvas.save();
    canvas.translate(currentX, currentY);

    // Calculate spin rotation angle
    double spinAngle = 0.0;
    // Base rotation to orient the seams for the spin axis
    double baseRotation = 0.0;

    if (shouldSpin) {
      // Number of full rotations during ball flight
      final rotations = progress * 6;  // 6 full rotations during flight

      if (isServe) {
        // Serve spins - ball rotates around vertical axis (sidespin)
        // Seams oriented horizontally, rotate around Z-axis
        baseRotation = 0;  // Seams horizontal
        if (hasSlice) {
          spinAngle = isLeftHanded
              ? rotations * 2 * math.pi    // clockwise
              : -rotations * 2 * math.pi;  // counter-clockwise
        } else if (hasTopspin) {
          spinAngle = isLeftHanded
              ? -rotations * 2 * math.pi   // counter-clockwise
              : rotations * 2 * math.pi;   // clockwise
        }
      } else {
        // Ground strokes - ball rotates around horizontal axis (topspin/backspin)
        // Orient seams vertically first, then rotate
        baseRotation = math.pi / 2;  // Seams vertical for top/back spin effect
        if (hasTopspin) {
          // Topspin: ball rolls forward
          spinAngle = playerHit
              ? rotations * 2 * math.pi    // forward roll
              : -rotations * 2 * math.pi;  // appears opposite from other side
        } else if (hasSlice || isDropShot) {
          // Slice: ball spins backward
          spinAngle = playerHit
              ? -rotations * 2 * math.pi   // backward spin
              : rotations * 2 * math.pi;   // appears opposite from other side
        }
      }
    }

    // Draw tennis ball seam pattern with rotation
    final seamPaint = Paint()
      ..color = const Color(0xFFF7F7F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final r = ballRadius;

    // Clip seams to ball circle
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.clipPath(clipPath);

    // Apply base rotation to orient seams for spin type, then spin rotation
    canvas.rotate(baseRotation + spinAngle);

    // Tennis ball seam pattern - figure-8 / infinity pattern that wraps around
    // Draw two curved seams that create the characteristic tennis ball look

    // First seam curve (one half of the figure-8)
    final seam1 = Path();
    seam1.moveTo(0, -r);
    seam1.cubicTo(
      r * 0.8, -r * 0.8,   // control point 1
      r * 0.8, r * 0.8,    // control point 2
      0, r,                 // end point
    );
    canvas.drawPath(seam1, seamPaint);

    // Second seam curve (other half of the figure-8, opposite side)
    final seam2 = Path();
    seam2.moveTo(0, -r);
    seam2.cubicTo(
      -r * 0.8, -r * 0.8,  // control point 1
      -r * 0.8, r * 0.8,   // control point 2
      0, r,                 // end point
    );
    canvas.drawPath(seam2, seamPaint);

    canvas.restore();

    canvas.restore();

    // Draw thin outline for definition
    final outlinePaint = Paint()
      ..color = const Color(0xFFAED581)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(Offset(currentX, currentY), ballRadius, outlinePaint);
  }

  Rect _getCourtRect(Size size) {
    final surroundX = size.width * surroundRatio;
    final surroundY = size.height * surroundRatio;
    return Rect.fromLTRB(
      surroundX,
      surroundY,
      size.width - surroundX,
      size.height - surroundY,
    );
  }

  void _drawSurround(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = surroundGreen
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawCourtSurface(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = courtBlue
      ..style = PaintingStyle.fill;
    canvas.drawRect(_getCourtRect(size), paint);
  }

  void _drawCourtLines(Canvas canvas, Size size) {
    final courtRect = _getCourtRect(size);
    final courtWidth = courtRect.width;
    final courtHeight = courtRect.height;
    final courtLeft = courtRect.left;
    final courtTop = courtRect.top;

    final linePaint = Paint()
      ..color = lineWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final netY = courtTop + courtHeight * 0.5;
    final doublesLeft = courtLeft;
    final doublesRight = courtLeft + courtWidth;
    final alleyWidth = courtWidth * 0.125;
    final singlesLeft = courtLeft + alleyWidth;
    final singlesRight = courtLeft + courtWidth - alleyWidth;
    final farBaseline = courtTop;
    final nearBaseline = courtTop + courtHeight;
    final serviceLineOffset = courtHeight * 0.5 * (21.0 / 39.0);
    final nearServiceY = netY + serviceLineOffset;
    final farServiceY = netY - serviceLineOffset;
    final centerX = courtLeft + courtWidth * 0.5;

    canvas.drawRect(courtRect, linePaint);
    canvas.drawLine(Offset(singlesLeft, farBaseline), Offset(singlesLeft, nearBaseline), linePaint);
    canvas.drawLine(Offset(singlesRight, farBaseline), Offset(singlesRight, nearBaseline), linePaint);

    final netPaint = Paint()
      ..color = lineWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(doublesLeft, netY), Offset(doublesRight, netY), netPaint);

    canvas.drawLine(Offset(singlesLeft, nearServiceY), Offset(singlesRight, nearServiceY), linePaint);
    canvas.drawLine(Offset(singlesLeft, farServiceY), Offset(singlesRight, farServiceY), linePaint);
    canvas.drawLine(Offset(centerX, netY), Offset(centerX, nearServiceY), linePaint);
    canvas.drawLine(Offset(centerX, netY), Offset(centerX, farServiceY), linePaint);

    final centerMarkLength = courtHeight * 0.015;
    canvas.drawLine(Offset(centerX, nearBaseline), Offset(centerX, nearBaseline - centerMarkLength), linePaint);
    canvas.drawLine(Offset(centerX, farBaseline), Offset(centerX, farBaseline + centerMarkLength), linePaint);
  }

  Offset _courtToCanvas(Size size, double x, double y) {
    return Offset(x * size.width, y * size.height);
  }

  void _drawMovement(Canvas canvas, Size size, CourtMovement movement, int? shotNumber, double progress, {double opacity = 1.0}) {
    if (progress <= 0 || opacity <= 0) return;

    final from = _courtToCanvas(size, movement.fromX, movement.fromY);
    final fullTo = _courtToCanvas(size, movement.toX, movement.toY);

    // Partial drawing based on progress
    final to = Offset(
      _lerp(from.dx, fullTo.dx, progress),
      _lerp(from.dy, fullTo.dy, progress),
    );

    final isBall = movement.type == 'ball';
    final isOpponent = movement.type == 'opponent';

    Color color;
    if (isBall) {
      color = ballColor.withOpacity(opacity);
    } else if (isOpponent) {
      color = opponentColor.withOpacity(opacity);
    } else {
      color = playerColor.withOpacity(opacity);
    }

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    if (isBall) {
      _drawDashedLine(canvas, from, to, arrowPaint);
    } else {
      canvas.drawLine(from, to, arrowPaint);
    }

    // Only draw arrowhead when mostly complete
    if (progress > 0.8) {
      _drawArrowhead(canvas, from, to, color);
    }

    // Draw shot label when complete
    if (isBall && shotNumber != null && progress >= 1.0) {
      _drawShotLabel(canvas, from, fullTo, movement.shotLabel, shotNumber, opacity: opacity);
    }
  }

  void _drawShotLabel(Canvas canvas, Offset from, Offset to, String? shotLabel, int shotNumber, {double opacity = 1.0}) {
    if (opacity <= 0) return;

    final midX = (from.dx + to.dx) / 2;
    final midY = (from.dy + to.dy) / 2;

    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final angle = math.atan2(dy, dx);

    final perpOffset = 14.0;
    final offsetX = -math.sin(angle) * perpOffset;
    final offsetY = math.cos(angle) * perpOffset;

    final labelText = shotLabel != null ? '$shotNumber.$shotLabel' : '$shotNumber';

    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: ballColor.withOpacity(opacity),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    canvas.save();
    canvas.translate(midX + offsetX, midY + offsetY);

    if (angle.abs() > math.pi / 2) {
      canvas.translate(textPainter.width, textPainter.height);
      canvas.rotate(angle + math.pi);
    } else {
      canvas.rotate(angle);
    }

    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  void _drawPosition(Canvas canvas, Size size, CourtPosition position) {
    final pos = _courtToCanvas(size, position.x, position.y);
    final isPlayer = position.label.startsWith('P');
    final color = isPlayer ? playerColor : opponentColor;
    final textColor = isPlayer ? Colors.black : Colors.white;

    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final radius = math.min(size.width, size.height) * 0.05;
    canvas.drawCircle(pos, radius, circlePaint);

    final borderPaint = Paint()
      ..color = isPlayer ? Colors.black : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(pos, radius, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: position.label,
        style: TextStyle(
          color: textColor,
          fontSize: radius * 0.9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
    );
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dashLength = 6.0;
    const gapLength = 3.0;

    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final unitDx = dx / distance;
    final unitDy = dy / distance;

    var currentDistance = 0.0;
    var drawing = true;

    while (currentDistance < distance) {
      final segmentLength = drawing ? dashLength : gapLength;
      final endDistance = math.min(currentDistance + segmentLength, distance);

      if (drawing) {
        canvas.drawLine(
          Offset(from.dx + unitDx * currentDistance, from.dy + unitDy * currentDistance),
          Offset(from.dx + unitDx * endDistance, from.dy + unitDy * endDistance),
          paint,
        );
      }

      currentDistance = endDistance;
      drawing = !drawing;
    }
  }

  void _drawArrowhead(Canvas canvas, Offset from, Offset to, Color color) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final angle = math.atan2(dy, dx);
    final arrowLength = math.min(14.0, distance * 0.3); // Bigger arrowhead
    const arrowAngle = math.pi / 5; // Wider angle for smoother look

    // Create a smooth curved arrowhead using bezier
    final path = Path();
    final tipX = to.dx;
    final tipY = to.dy;

    final leftX = to.dx - arrowLength * math.cos(angle - arrowAngle);
    final leftY = to.dy - arrowLength * math.sin(angle - arrowAngle);
    final rightX = to.dx - arrowLength * math.cos(angle + arrowAngle);
    final rightY = to.dy - arrowLength * math.sin(angle + arrowAngle);

    // Back center point for curved base
    final backX = to.dx - arrowLength * 0.5 * math.cos(angle);
    final backY = to.dy - arrowLength * 0.5 * math.sin(angle);

    path.moveTo(tipX, tipY);
    path.quadraticBezierTo(
      (tipX + leftX) / 2 - 2 * math.sin(angle),
      (tipY + leftY) / 2 + 2 * math.cos(angle),
      leftX, leftY,
    );
    path.quadraticBezierTo(backX, backY, rightX, rightY);
    path.quadraticBezierTo(
      (tipX + rightX) / 2 + 2 * math.sin(angle),
      (tipY + rightY) / 2 - 2 * math.cos(angle),
      tipX, tipY,
    );
    path.close();

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(_AnimatedTennisCourtPainter oldDelegate) {
    return oldDelegate.movements != movements ||
           oldDelegate.positions != positions ||
           oldDelegate.animationProgress != animationProgress;
  }
}
