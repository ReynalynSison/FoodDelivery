import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../map/map_view.dart';
import '../map/pathfinding_service.dart';
import '../core/database/location_service.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TrackingPage — immersive fullscreen map with floating overlays
// ═════════════════════════════════════════════════════════════════════════════

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  // ── Services ──────────────────────────────────────────────────────────────
  final _locationService = LocationService();
  final _pathfinder      = PathfindingService();

  // ── Delivery pin ──────────────────────────────────────────────────────────
  LatLng? _pinnedLocation;

  // ── Route ─────────────────────────────────────────────────────────────────
  List<LatLng> _route = [];

  // ── Rider movement ────────────────────────────────────────────────────────
  LatLng _riderLocation     = DeliveryLocations.riderInitialLocation;
  int    _currentRouteIndex = 0;
  Timer? _movementTimer;
  bool   _movementStarted   = false;

  // ── ETA countdown ─────────────────────────────────────────────────────────
  /// Seconds remaining until "on the way". Counts down from 60.
  int    _etaSeconds        = 60;
  Timer? _etaTimer;

  // ── Delivered modal shown flag ─────────────────────────────────────────────
  bool _deliveredModalShown = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final order = context.read<OrderProvider>().currentOrder;
      if (order == null) return;

      if (order.status == OrderStatus.delivered) {
        _showAlreadyDeliveredDialog();
        return;
      }

      if (order.status == OrderStatus.confirmed) {
        _startEtaCountdown();
      }
    });
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _etaTimer?.cancel();
    super.dispose();
  }

  // ── ETA countdown (confirmed phase only) ──────────────────────────────────

  void _startEtaCountdown() {
    _etaTimer?.cancel();
    _etaTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_etaSeconds > 0) {
          _etaSeconds--;
        } else {
          t.cancel();
        }
      });
    });
  }

  // ── Already-delivered guard ────────────────────────────────────────────────

  void _showAlreadyDeliveredDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Order Already Delivered'),
        content: const Text(
          'This order has been delivered.\nYou can view it in your History.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // ── Delivered celebration modal ────────────────────────────────────────────

  void _showDeliveredModal() {
    if (_deliveredModalShown) return;
    _deliveredModalShown = true;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => _DeliveredModalSheet(
        onDone: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // ── Saved location ─────────────────────────────────────────────────────────

  void _loadSavedLocation() {
    if (_locationService.hasSavedLocation()) {
      final lat = _locationService.getSavedLat()!;
      final lng = _locationService.getSavedLng()!;
      debugPrint('[TrackingPage] Loaded saved location: $lat, $lng');
      setState(() => _pinnedLocation = LatLng(lat, lng));
    } else {
      debugPrint('[TrackingPage] No saved delivery location found.');
    }
  }

  // ── Re-pin ─────────────────────────────────────────────────────────────────

  void _onMapTapped(LatLng tapped) {
    if (_movementStarted) return;
    debugPrint('[TrackingPage] Re-pinned: $tapped');
    setState(() {
      _pinnedLocation  = tapped;
      _route           = [];
      _movementStarted = false;
    });
    _locationService.saveLocation(tapped.latitude, tapped.longitude);
  }

  // ── Route generation ───────────────────────────────────────────────────────

  void _generateRoute() {
    if (_pinnedLocation == null) return;
    final waypoints = _pathfinder.findRoute(
      DeliveryLocations.riderInitialLocation,
      _pinnedLocation!,
    );
    debugPrint('[TrackingPage] A* route: ${waypoints.length} waypoints');
    setState(() {
      _route               = waypoints;
      _riderLocation       = waypoints.isNotEmpty
          ? waypoints.first
          : DeliveryLocations.riderInitialLocation;
      _currentRouteIndex   = 0;
    });
  }

  // ── Rider movement ─────────────────────────────────────────────────────────

  void _startRiderMovement(OrderProvider orderProvider) {
    if (_movementStarted || _route.isEmpty) return;
    _movementStarted = true;
    debugPrint('[TrackingPage] Rider movement started');

    _movementTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final next = _currentRouteIndex + 1;
      if (next >= _route.length) {
        timer.cancel();
        _movementTimer = null;
        orderProvider.forceDelivered();
        return;
      }
      setState(() {
        _currentRouteIndex = next;
        _riderLocation     = _route[next];
      });
    });
  }

  // ── Status helpers ─────────────────────────────────────────────────────────

  String _statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed: return 'Order Confirmed';
      case OrderStatus.onTheWay: return 'Delivery is on the way';
      case OrderStatus.delivered: return 'Delivered';
    }
  }

  String _etaLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return _etaSeconds > 0
            ? 'Rider departs in ${_etaSeconds}s'
            : 'Rider departing…';
      case OrderStatus.onTheWay:
        return _movementStarted ? 'On its way to you' : 'Calculating route…';
      case OrderStatus.delivered:
        return 'Delivered 🎉';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order         = orderProvider.currentOrder;

    // Trigger route generation and rider movement reactively
    if (order != null && order.status == OrderStatus.onTheWay) {
      if (_pinnedLocation != null && _route.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _generateRoute());
      }
      if (_route.isNotEmpty && !_movementStarted) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _startRiderMovement(orderProvider),
        );
      }
    }

    // Stop ETA timer once we transition away from confirmed
    if (order != null &&
        order.status != OrderStatus.confirmed &&
        _etaTimer?.isActive == true) {
      _etaTimer?.cancel();
    }

    // Show delivered modal once when status flips
    if (order != null && order.status == OrderStatus.delivered) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDeliveredModal());
    }

    return CupertinoPageScaffold(
      // No navigation bar — the map is truly fullscreen
      child: Stack(
        children: [
          // ── 1. Fullscreen map ──────────────────────────────────────────
          Positioned.fill(
            child: order == null
                ? const _NoOrderPlaceholder()
                : MapView(
                    route: _route,
                    riderLocation: _riderLocation,
                    pinnedLocation: _pinnedLocation,
                    onMapTapped: order.status == OrderStatus.onTheWay &&
                            !_movementStarted
                        ? _onMapTapped
                        : null,
                  ),
          ),

          // ── 2. Back button (top-left) ──────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _FloatingBackButton(),
          ),

          // ── 3. Top status overlay (top-center) ────────────────────────
          if (order != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 64,
              right: 16,
              child: _StatusOverlay(
                statusText: _statusText(order.status),
                etaLabel: _etaLabel(order.status),
                status: order.status,
              ),
            ),

          // ── 4. No-location warning strip ──────────────────────────────
          if (order != null &&
              order.status == OrderStatus.onTheWay &&
              _pinnedLocation == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 72,
              left: 16,
              right: 16,
              child: const _NoLocationWarning(),
            ),

          // ── 5. Bottom DraggableScrollableSheet panel ───────────────────
          if (order != null)
            DraggableScrollableSheet(
              initialChildSize: 0.28,
              minChildSize: 0.14,
              maxChildSize: 0.6,
              snap: true,
              snapSizes: const [0.14, 0.28, 0.6],
              builder: (context, scrollController) => _BottomPanel(
                order: order,
                pinnedLocation: _pinnedLocation,
                scrollController: scrollController,
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Floating back button
// ═════════════════════════════════════════════════════════════════════════════

class _FloatingBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          CupertinoIcons.chevron_left,
          size: 18,
          color: CupertinoColors.label.resolveFrom(context),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Top status overlay — rounded pill card with AnimatedSwitcher
// ═════════════════════════════════════════════════════════════════════════════

class _StatusOverlay extends StatelessWidget {
  final String statusText;
  final String etaLabel;
  final OrderStatus status;

  const _StatusOverlay({
    required this.statusText,
    required this.etaLabel,
    required this.status,
  });

  Color _accentColor(BuildContext context) {
    switch (status) {
      case OrderStatus.confirmed:
        return CupertinoColors.systemOrange.resolveFrom(context);
      case OrderStatus.onTheWay:
        return CupertinoColors.systemBlue.resolveFrom(context);
      case OrderStatus.delivered:
        return CupertinoColors.systemGreen.resolveFrom(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground
            .resolveFrom(context)
            .withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Colored status dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status text with smooth transition
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.3),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    statusText,
                    key: ValueKey(statusText),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                // ETA countdown
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    etaLabel,
                    key: ValueKey(etaLabel),
                    style: TextStyle(
                      fontSize: 11,
                      color: accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// No-location warning strip
// ═════════════════════════════════════════════════════════════════════════════

class _NoLocationWarning extends StatelessWidget {
  const _NoLocationWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemOrange.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle_fill,
              color: CupertinoColors.white, size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'No delivery location set. Go to Settings → Delivery Location.',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Bottom DraggableScrollableSheet panel
// ═════════════════════════════════════════════════════════════════════════════

class _BottomPanel extends StatelessWidget {
  final Order order;
  final LatLng? pinnedLocation;
  final ScrollController scrollController;

  const _BottomPanel({
    required this.order,
    required this.pinnedLocation,
    required this.scrollController,
  });

  String _shortId(String id) {
    if (id.length > 16) return id.substring(6, 16);
    return id;
  }

  String _addressLabel() {
    if (pinnedLocation == null) return 'Not set — go to Settings';
    return '${pinnedLocation!.latitude.toStringAsFixed(4)}°N, '
        '${pinnedLocation!.longitude.toStringAsFixed(4)}°E';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          // ── Drag handle ──────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Step progress ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: _StepProgressIndicator(status: order.status),
          ),

          // ── Divider ───────────────────────────────────────────────────
          Container(
            height: 0.5,
            color: CupertinoColors.separator.resolveFrom(context),
          ),

          // ── Order details ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${_shortId(order.id)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    Text(
                      '\$${order.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.systemBlue.resolveFrom(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Items summary
                if (order.items.isNotEmpty)
                  _DetailRow(
                    icon: CupertinoIcons.bag_fill,
                    label: order.items.join(', '),
                  ),

                const SizedBox(height: 6),

                // Delivery address
                _DetailRow(
                  icon: CupertinoIcons.location_fill,
                  label: _addressLabel(),
                  accent: pinnedLocation == null
                      ? CupertinoColors.systemOrange
                      : null,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Horizontal step progress indicator
// ═════════════════════════════════════════════════════════════════════════════

class _StepProgressIndicator extends StatelessWidget {
  final OrderStatus status;
  const _StepProgressIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    const steps = ['Confirmed', 'On The Way', 'Delivered'];
    final currentStep = status.index; // 0, 1, 2

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        // Odd indices are connector lines
        if (i.isOdd) {
          final lineIndex = i ~/ 2; // which gap: 0 = between 0&1, 1 = between 1&2
          final filled = currentStep > lineIndex;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 2,
              color: filled
                  ? CupertinoColors.systemBlue.resolveFrom(context)
                  : CupertinoColors.systemFill.resolveFrom(context),
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isDone    = currentStep > stepIndex;
        final isCurrent = currentStep == stepIndex;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? CupertinoColors.systemBlue.resolveFrom(context)
                    : isCurrent
                        ? CupertinoColors.systemBlue
                            .resolveFrom(context)
                            .withValues(alpha: 0.15)
                        : CupertinoColors.systemFill.resolveFrom(context),
                border: isCurrent
                    ? Border.all(
                        color: CupertinoColors.systemBlue.resolveFrom(context),
                        width: 2,
                      )
                    : null,
              ),
              child: isDone
                  ? const Icon(CupertinoIcons.checkmark,
                      size: 13, color: CupertinoColors.white)
                  : isCurrent
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: CupertinoColors.systemBlue
                                  .resolveFrom(context),
                            ),
                          ),
                        )
                      : null,
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              steps[stepIndex],
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isCurrent ? FontWeight.w700 : FontWeight.w400,
                color: isCurrent
                    ? CupertinoColors.label.resolveFrom(context)
                    : CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Detail row (icon + text)
// ═════════════════════════════════════════════════════════════════════════════

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final CupertinoDynamicColor? accent;

  const _DetailRow({required this.icon, required this.label, this.accent});

  @override
  Widget build(BuildContext context) {
    final color = accent != null
        ? accent!.resolveFrom(context)
        : CupertinoColors.secondaryLabel.resolveFrom(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Delivered modal sheet (Cupertino modal popup)
// ═════════════════════════════════════════════════════════════════════════════

class _DeliveredModalSheet extends StatefulWidget {
  final VoidCallback onDone;
  const _DeliveredModalSheet({required this.onDone});

  @override
  State<_DeliveredModalSheet> createState() => _DeliveredModalSheetState();
}

class _DeliveredModalSheetState extends State<_DeliveredModalSheet> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: CupertinoColors.systemFill.resolveFrom(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Checkmark icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.checkmark_seal_fill,
              size: 40,
              color: CupertinoColors.systemGreen,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Order Delivered! 🎉',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your food has arrived. Enjoy your meal!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),

          const SizedBox(height: 24),

          // ── Star rating ────────────────────────────────────────────────
          Text(
            'Rate your order',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    filled ? CupertinoIcons.star_fill : CupertinoIcons.star,
                    size: 34,
                    color: filled
                        ? CupertinoColors.systemYellow
                        : CupertinoColors.systemFill.resolveFrom(context),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 28),

          // ── Buttons ────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: widget.onDone,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// No active order placeholder
// ═════════════════════════════════════════════════════════════════════════════

class _NoOrderPlaceholder extends StatelessWidget {
  const _NoOrderPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.map,
              size: 56,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No active order',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
