import '../../pkg.dart';

class PulsingHarvestButton extends StatefulWidget {
  const PulsingHarvestButton({
    super.key,
    required this.isReadyToHarvest,
    required this.child,
    this.tooltipMessage = 'Tanaman siap dipanen! Klik untuk memanen.',
  });

  final bool isReadyToHarvest;
  final Widget child;
  final String tooltipMessage;

  @override
  State<PulsingHarvestButton> createState() => _PulsingHarvestButtonState();
}

class _PulsingHarvestButtonState extends State<PulsingHarvestButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));

    _fadeAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));

    if (widget.isReadyToHarvest) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PulsingHarvestButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReadyToHarvest != oldWidget.isReadyToHarvest) {
      if (widget.isReadyToHarvest) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
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
    if (!widget.isReadyToHarvest) {
      return widget.child;
    }

    return Tooltip(
      message: widget.tooltipMessage,
      triggerMode: TooltipTriggerMode.longPress,
      preferBelow: false,
      decoration: BoxDecoration(
        color: ColorValues.green900.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
      ),
      textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scaleX: 1.15,
                  scaleY: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: ColorValues.green400,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [BoxShadow(color: ColorValues.green600.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Tombol asli berada di layer atas
          widget.child,
        ],
      ),
    );
  }
}
