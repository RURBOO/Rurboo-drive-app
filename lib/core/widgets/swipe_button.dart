import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A premium, advanced-level swipe-to-act button.
/// Features: animated shimmer, glowing thumb, spring-back, haptic feedback.
class SwipeButton extends StatefulWidget {
  final String text;
  final Future<void> Function() onSwipe;
  final Color color;
  final IconData icon;
  final bool isLoading;

  const SwipeButton({
    super.key,
    required this.text,
    required this.onSwipe,
    this.color = Colors.green,
    this.icon = Icons.chevron_right,
    this.isLoading = false,
  });

  @override
  State<SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<SwipeButton>
    with TickerProviderStateMixin {
  // Drag state
  double _dragOffset = 0.0;
  bool _isCompleted = false;
  bool _isExecuting = false;

  // For width calculation
  double _trackWidth = 0.0;
  static const double _thumbSize = 56.0;
  static const double _padding = 6.0;

  double get _dragLimit => math.max(0, _trackWidth - _thumbSize - _padding * 2);

  // Shimmer animation controller
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  // Success "check" animation
  late final AnimationController _successCtrl;
  late final Animation<double> _successAnim;

  // Spring-back animation
  late final AnimationController _springCtrl;
  late final Animation<double> _springAnim;

  bool _isSpringBack = false;

  @override
  void initState() {
    super.initState();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successAnim = CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);

    _springCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _springAnim = Tween<double>(begin: 0.0, end: 0.0).animate(_springCtrl);
    _springCtrl.addListener(() {
      if (_isSpringBack) {
        setState(() {
          _dragOffset = _springAnim.value;
        });
      }
    });
    _springCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isSpringBack) {
        _isSpringBack = false;
      }
    });
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _successCtrl.dispose();
    _springCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isCompleted || _isExecuting) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, _dragLimit);
    });
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_isCompleted || _isExecuting) return;

    // Success threshold at 85%
    if (_dragOffset >= _dragLimit * 0.85) {
      setState(() {
        _dragOffset = _dragLimit;
        _isCompleted = true;
        _isExecuting = true;
      });

      HapticFeedback.heavyImpact();
      _successCtrl.forward();

      try {
        await widget.onSwipe();
      } catch (_) {
        if (!mounted) return;
        // Reset on failure
        _successCtrl.reset();
        setState(() {
          _isCompleted = false;
          _isExecuting = false;
          _isSpringBack = true;
        });
        _springAnim = Tween<double>(begin: _dragOffset, end: 0.0).animate(
          CurvedAnimation(parent: _springCtrl, curve: Curves.elasticOut),
        );
        _springCtrl
          ..reset()
          ..forward();
      } finally {
        if (mounted && _isCompleted) {
          setState(() {
            _isExecuting = false;
          });
        }
      }
    } else {
      // Snap back with spring
      HapticFeedback.lightImpact();
      _isSpringBack = true;
      _springAnim = Tween<double>(begin: _dragOffset, end: 0.0).animate(
        CurvedAnimation(parent: _springCtrl, curve: Curves.elasticOut),
      );
      _springCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _trackWidth = constraints.maxWidth;

          return AnimatedBuilder(
            animation: Listenable.merge([_shimmerAnim, _successAnim]),
            builder: (context, _) {
              return Container(
                height: 68,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: widget.color.withValues(alpha: _isCompleted ? 0.6 : 0.25),
                    width: 1.5,
                  ),
                  boxShadow: _isCompleted
                      ? [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // === Filled progress track ===
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: _dragOffset + _thumbSize + _padding * 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.color.withValues(alpha: 0.25),
                                widget.color.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // === Shimmer overlay ===
                      if (!_isCompleted)
                        Positioned.fill(
                          child: ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (rect) {
                              return LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.transparent,
                                  widget.color.withValues(alpha: 0.12),
                                  Colors.transparent,
                                ],
                                stops: [
                                  (_shimmerAnim.value - 0.4).clamp(0.0, 1.0),
                                  _shimmerAnim.value.clamp(0.0, 1.0),
                                  (_shimmerAnim.value + 0.4).clamp(0.0, 1.0),
                                ],
                              ).createShader(rect);
                            },
                            child: Container(color: Colors.white),
                          ),
                        ),

                      // === Center label ===
                      Center(
                        child: widget.isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: widget.color,
                                ),
                              )
                            : AnimatedOpacity(
                                opacity: _isCompleted ? 0.0 : (1.0 - (_dragOffset / (_dragLimit == 0 ? 1 : _dragLimit)) * 0.8),
                                duration: const Duration(milliseconds: 150),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chevron_right,
                                      color: widget.color.withValues(alpha: 0.5),
                                      size: 20,
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: widget.color.withValues(alpha: 0.3),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.text,
                                      style: TextStyle(
                                        color: widget.color,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      // === Draggable Thumb ===
                      if (!widget.isLoading)
                        Transform.translate(
                          offset: Offset(_padding + _dragOffset, 0),
                          child: GestureDetector(
                            onHorizontalDragUpdate: _onDragUpdate,
                            onHorizontalDragEnd: _onDragEnd,
                            child: _buildThumb(),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildThumb() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _thumbSize,
      height: _thumbSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isCompleted
              ? [Colors.green.shade300, Colors.green.shade700]
              : [
                  widget.color.withValues(alpha: 0.9),
                  widget.color,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: _isCompleted ? 0.6 : 0.4),
            blurRadius: _isCompleted ? 20 : 12,
            spreadRadius: _isCompleted ? 3 : 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _isExecuting
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      key: ValueKey('check'),
                      color: Colors.white,
                      size: 28,
                    )
                  : Icon(
                      widget.icon,
                      key: const ValueKey('arrow'),
                      color: Colors.white,
                      size: 30,
                    ),
            ),
    );
  }
}
