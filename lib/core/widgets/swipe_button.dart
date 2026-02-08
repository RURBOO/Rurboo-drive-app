import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _SwipeButtonState extends State<SwipeButton> with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  double _maxWidth = 0.0;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _maxWidth = constraints.maxWidth;
        final handleSize = 50.0;
        final dragLimit = _maxWidth - handleSize - 8; // 8 is padding

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: widget.color.withValues(alpha: 0.2)),
          ),
          child: Stack(
            children: [
              // Background Text (Shimmer effect could be added here)
              Center(
                child: widget.isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        widget.text,
                        style: TextStyle(
                          color: widget.color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              // Swipe Handle
              if (!widget.isLoading)
                Positioned(
                  left: 4 + _dragValue,
                  top: 4,
                  bottom: 4,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      if (_isCompleted) return;
                      setState(() {
                        _dragValue += details.delta.dx;
                        _dragValue = _dragValue.clamp(0.0, dragLimit);
                      });
                    },
                    onHorizontalDragEnd: (details) async {
                      if (_isCompleted) return;
                      
                      if (_dragValue >= dragLimit * 0.9) {
                        setState(() {
                          _dragValue = dragLimit;
                          _isCompleted = true;
                        });
                        HapticFeedback.lightImpact();
                        try {
                          await widget.onSwipe();
                        } catch (e) {
                          // Reset if failed
                          setState(() {
                            _isCompleted = false;
                            _dragValue = 0;
                          });
                        }
                      } else {
                        // Reset
                        setState(() {
                          _dragValue = 0;
                        });
                      }
                    },
                    child: Container(
                      width: handleSize,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
