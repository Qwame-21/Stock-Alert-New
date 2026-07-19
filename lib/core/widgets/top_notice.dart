import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum TopNoticeType { success, info, warning, error }

OverlayEntry? _activeTopNotice;

void showTopNotice(
  BuildContext context, {
  required String title,
  required String message,
  TopNoticeType type = TopNoticeType.info,
  Duration duration = const Duration(seconds: 4),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  _activeTopNotice?.remove();
  _activeTopNotice = null;
  late OverlayEntry entry;
  var removed = false;

  void remove() {
    if (removed) return;
    removed = true;
    entry.remove();
    if (identical(_activeTopNotice, entry)) _activeTopNotice = null;
  }

  entry = OverlayEntry(
    builder: (_) => _TopNoticeOverlay(
      title: title,
      message: message,
      type: type,
      duration: duration,
      onDismissed: remove,
    ),
  );
  _activeTopNotice = entry;
  overlay.insert(entry);
}

String friendlyNoticeMessage(Object error) {
  final message =
      error.toString().replaceFirst(RegExp(r'^\w+Exception:\s*'), '');
  final lower = message.toLowerCase();
  if (lower.contains('databaseexception') || lower.contains('sqlite')) {
    return 'The app could not update its local copy. Restart the app and try again.';
  }
  if (lower.contains('booking_conflict') || lower.contains('time conflict')) {
    return 'That time was just booked. Choose another available time.';
  }
  if (lower.contains('socket') ||
      lower.contains('connection') ||
      lower.contains('timed out')) {
    return 'Check your connection and try again.';
  }
  return message.length > 180
      ? 'Something went wrong. Please try again.'
      : message;
}

class _TopNoticeOverlay extends StatefulWidget {
  const _TopNoticeOverlay({
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  final String title;
  final String message;
  final TopNoticeType type;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_TopNoticeOverlay> createState() => _TopNoticeOverlayState();
}

class _TopNoticeOverlayState extends State<_TopNoticeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 190),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide =
        Tween(begin: const Offset(0, -1.15), end: Offset.zero).animate(curve);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  (Color, Color, IconData) get _style => switch (widget.type) {
        TopNoticeType.success => (
            const Color(0xFFEAF6ED),
            AppColors.statusGood,
            Icons.check_circle_outline,
          ),
        TopNoticeType.warning => (
            const Color(0xFFFFF7E0),
            AppColors.statusWarning,
            Icons.warning_amber_rounded,
          ),
        TopNoticeType.error => (
            const Color(0xFFFCEDEA),
            AppColors.statusBad,
            Icons.error_outline,
          ),
        TopNoticeType.info => (
            const Color(0xFFEAF2F1),
            AppColors.accent,
            Icons.notifications_none_rounded,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (background, accent, icon) = _style;
    return Positioned(
      left: 12,
      right: 12,
      top: MediaQuery.viewPaddingOf(context).top + 10,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Semantics(
                container: true,
                liveRegion: true,
                label: '${widget.title}. ${widget.message}',
                child: Material(
                  color: background,
                  elevation: 10,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: accent.withValues(alpha: .25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: .12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: accent, size: 22),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: AppTextStyles.subheading.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(widget.message, style: AppTextStyles.body),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Dismiss notification',
                          onPressed: _dismiss,
                          icon: const Icon(Icons.close, size: 19),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
