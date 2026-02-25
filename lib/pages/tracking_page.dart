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
  const TrackingPage({super.key, this.isEmbedded = false, this.orderId});
  final bool    isEmbedded;
  final String? orderId; // null = auto-pick or show list

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final _locationService = LocationService();
  final _pathfinder      = PathfindingService();

  // ── Per-instance tracking state (for the selected order) ─────────────────
  String?   _trackedOrderId;
  LatLng?   _pinnedLocation;
  List<LatLng> _route = [];
  LatLng _riderLocation  = DeliveryLocations.riderInitialLocation;
  int    _currentRouteIndex = 0;
  Timer? _movementTimer;
  bool   _movementStarted = false;
  int    _etaSeconds      = 60;
  Timer? _etaTimer;
  bool   _deliveredModalShown = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
    if (widget.orderId != null) {
      _trackedOrderId = widget.orderId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _initForOrder());
    }
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _etaTimer?.cancel();
    super.dispose();
  }

  void _loadSavedLocation() {
    if (_locationService.hasSavedLocation()) {
      setState(() => _pinnedLocation = LatLng(
        _locationService.getSavedLat()!,
        _locationService.getSavedLng()!,
      ));
    }
  }

  void _initForOrder() {
    final orders = context.read<OrderProvider>().activeOrders;
    final order = _trackedOrderId != null
        ? orders.firstWhere((o) => o.id == _trackedOrderId,
            orElse: () => orders.first)
        : orders.first;

    if (order.status == OrderStatus.delivered) {
      _showAlreadyDeliveredDialog();
      return;
    }
    if (order.status == OrderStatus.confirmed) {
      // Calculate how many seconds have already elapsed since the order was placed.
      final elapsed   = DateTime.now().difference(order.createdAt).inSeconds;
      final remaining = (60 - elapsed).clamp(0, 60);
      setState(() => _etaSeconds = remaining);
      _startEtaCountdown();
    }
  }

  void _selectOrder(String orderId) {
    final orders = context.read<OrderProvider>().activeOrders;
    final order  = orders.firstWhere((o) => o.id == orderId,
        orElse: () => orders.first);

    // Calculate correct remaining ETA before resetting state
    final elapsed   = DateTime.now().difference(order.createdAt).inSeconds;
    final remaining = (60 - elapsed).clamp(0, 60);

    _etaTimer?.cancel();
    _movementTimer?.cancel();
    setState(() {
      _trackedOrderId      = orderId;
      _route               = [];
      _movementStarted     = false;
      _deliveredModalShown = false;
      _etaSeconds          = order.status == OrderStatus.confirmed ? remaining : 60;
      _riderLocation       = DeliveryLocations.riderInitialLocation;
      _currentRouteIndex   = 0;
    });
    _initForOrder();
  }

  void _startEtaCountdown() {
    _etaTimer?.cancel();
    _etaTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { if (_etaSeconds > 0) _etaSeconds--; else t.cancel(); });
    });
  }

  void _showAlreadyDeliveredDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Order Already Delivered'),
        content: const Text('This order has been delivered.\nYou can view it in your History.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted && !widget.isEmbedded) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _generateRoute() {
    if (_pinnedLocation == null) {
      debugPrint('[TrackingPage] Cannot generate route: no delivery location set');
      return;
    }
    final waypoints = _pathfinder.findRoute(
      DeliveryLocations.riderInitialLocation, _pinnedLocation!);
    setState(() {
      _route             = waypoints;
      _riderLocation     = waypoints.isNotEmpty ? waypoints.first : DeliveryLocations.riderInitialLocation;
      _currentRouteIndex = 0;
    });
  }

  void _startRiderMovement(OrderProvider orderProvider) {
    if (_movementStarted || _route.isEmpty || _trackedOrderId == null) {
      debugPrint('[TrackingPage] Cannot start rider: movementStarted=$_movementStarted, route=${_route.length}, orderId=$_trackedOrderId');
      return;
    }
    _movementStarted = true;
    _movementTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      final next = _currentRouteIndex + 1;
      if (next >= _route.length) {
        timer.cancel();
        _movementTimer = null;
        await orderProvider.forceDelivered(_trackedOrderId!);
        return;
      }
      setState(() {
        _currentRouteIndex = next;
        _riderLocation     = _route[next];
      });
    });
  }

  void _onMapTapped(LatLng tapped) {
    if (_movementStarted) return;
    setState(() { _pinnedLocation = tapped; _route = []; _movementStarted = false; });
    _locationService.saveLocation(tapped.latitude, tapped.longitude);
  }

  String _statusText(OrderStatus s) {
    switch (s) {
      case OrderStatus.confirmed: return 'Order Confirmed';
      case OrderStatus.onTheWay: return 'Delivery is on the way';
      case OrderStatus.delivered: return 'Delivered';
    }
  }

  String _etaLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.confirmed:
        return _etaSeconds > 0 ? 'Rider departs in ${_etaSeconds}s' : 'Rider departing…';
      case OrderStatus.onTheWay:
        return _movementStarted ? 'On its way to you' : 'Calculating route…';
      case OrderStatus.delivered:
        return 'Delivered 🎉';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final activeOrders  = orderProvider.activeOrders;

    // ── No active orders ───────────────────────────────────────────────────
    if (activeOrders.isEmpty) {
      return CupertinoPageScaffold(
        child: Stack(
          children: [
            const Positioned.fill(child: _NoOrderPlaceholder()),
            if (!widget.isEmbedded)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: _FloatingBackButton(),
              ),
          ],
        ),
      );
    }

    // ── Multiple orders & none selected yet → show picker ─────────────────
    if (_trackedOrderId == null && activeOrders.length > 1) {
      return _OrderPickerPage(
        orders: activeOrders,
        isEmbedded: widget.isEmbedded,
        onSelect: (orderId) => _selectOrder(orderId),
      );
    }

    // ── Auto-select when only one order ────────────────────────────────────
    if (_trackedOrderId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _selectOrder(activeOrders.first.id));
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    // ── Find the tracked order ─────────────────────────────────────────────
    final orderIdx = activeOrders.indexWhere((o) => o.id == _trackedOrderId);
    if (orderIdx == -1) {
      // Order was completed/removed — go back to picker or placeholder
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() { _trackedOrderId = null; _deliveredModalShown = false; });
      });
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    final order = activeOrders[orderIdx];

    // ── Reactive triggers ─────────────────────────────────────────────────
    if (order.status == OrderStatus.onTheWay) {
      if (_pinnedLocation == null && _locationService.hasSavedLocation()) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedLocation());
      }
      if (_pinnedLocation != null && _route.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _generateRoute());
      }
      if (_route.isNotEmpty && !_movementStarted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startRiderMovement(orderProvider));
      }
    }
    if (order.status != OrderStatus.confirmed && _etaTimer?.isActive == true) {
      _etaTimer?.cancel();
    }
    if (order.status == OrderStatus.delivered && !_deliveredModalShown) {
      _deliveredModalShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showCupertinoModalPopup<void>(
          context: context,
          builder: (ctx) => _DeliveredModalSheet(
            onDone: () {
              Navigator.of(ctx).pop();
              orderProvider.clearPendingRating(_trackedOrderId!);
              if (!widget.isEmbedded && mounted) Navigator.of(context).pop();
            },
          ),
        );
      });
    }

    // ── Map view ──────────────────────────────────────────────────────────
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // 1. Fullscreen map
          Positioned.fill(
            child: MapView(
              route: _route,
              riderLocation: _riderLocation,
              pinnedLocation: _pinnedLocation,
              onMapTapped: order.status == OrderStatus.onTheWay && !_movementStarted
                  ? _onMapTapped : null,
            ),
          ),

          // 2. Back / picker button (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: widget.isEmbedded && activeOrders.length > 1
                ? _FloatingPickerButton(
                    onTap: () => setState(() {
                      _trackedOrderId = null;
                      _movementTimer?.cancel();
                      _etaTimer?.cancel();
                    }),
                  )
                : (!widget.isEmbedded ? _FloatingBackButton() : const SizedBox.shrink()),
          ),

          // 3. Status overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: (widget.isEmbedded && activeOrders.length <= 1) ? 16 : 64,
            right: 16,
            child: _StatusOverlay(
              statusText: _statusText(order.status),
              etaLabel: _etaLabel(order.status),
              status: order.status,
              deliveryAddress: _locationService.getSavedAddress() ??
                  (_pinnedLocation != null
                      ? '${_pinnedLocation!.latitude.toStringAsFixed(4)}°N, ${_pinnedLocation!.longitude.toStringAsFixed(4)}°E'
                      : null),
            ),
          ),

          // 4. No-location warning
          if (order.status == OrderStatus.onTheWay && _pinnedLocation == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 72,
              left: 16, right: 16,
              child: const _NoLocationWarning(),
            ),

          // 5. Bottom panel
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.14,
            maxChildSize: 0.6,
            snap: true,
            snapSizes: const [0.14, 0.28, 0.6],
            builder: (context, sc) => _BottomPanel(
              order: order,
              pinnedLocation: _pinnedLocation,
              addressLabel: _locationService.getSavedAddress(),
              scrollController: sc,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Order Picker — shown when multiple orders are active
// ═════════════════════════════════════════════════════════════════════════════

class _OrderPickerPage extends StatelessWidget {
  final List<Order> orders;
  final bool isEmbedded;
  final void Function(String orderId) onSelect;

  const _OrderPickerPage({
    required this.orders,
    required this.isEmbedded,
    required this.onSelect,
  });

  String _shortId(String id) =>
      id.length > 16 ? id.substring(6, 16) : id;

  String _statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.confirmed: return 'Order Confirmed';
      case OrderStatus.onTheWay:  return 'On the Way';
      case OrderStatus.delivered: return 'Delivered';
    }
  }

  Color _statusColor(OrderStatus s, BuildContext ctx) {
    switch (s) {
      case OrderStatus.confirmed: return CupertinoColors.systemOrange.resolveFrom(ctx);
      case OrderStatus.onTheWay:  return CupertinoColors.systemBlue.resolveFrom(ctx);
      case OrderStatus.delivered: return CupertinoColors.systemGreen.resolveFrom(ctx);
    }
  }

  @override
  Widget build(BuildContext context) {

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Track Order'),
            border: null,
            leading: isEmbedded
                ? null
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(CupertinoIcons.chevron_left),
                  ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'You have ${orders.length} active orders. Select one to track.',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final order = orders[index];
                final accent = _statusColor(order.status, context);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => onSelect(order.id),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground.resolveFrom(context),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Status circle
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              order.status == OrderStatus.delivered
                                  ? CupertinoIcons.checkmark_seal_fill
                                  : CupertinoIcons.clock_fill,
                              color: accent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                      '₱${order.totalAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.systemBlue.resolveFrom(context),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _statusLabel(order.status),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Items
                                if (order.items.isNotEmpty)
                                  Text(
                                    order.items.join(', '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: orders.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Floating picker button — shown on map when multiple orders are active
// ═════════════════════════════════════════════════════════════════════════════

class _FloatingPickerButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FloatingPickerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
          CupertinoIcons.list_bullet,
          size: 18,
          color: CupertinoColors.label.resolveFrom(context),
        ),
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
  final String? deliveryAddress;

  const _StatusOverlay({
    required this.statusText,
    required this.etaLabel,
    required this.status,
    this.deliveryAddress,
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
                // Delivery address
                if (deliveryAddress != null && deliveryAddress!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(CupertinoIcons.location_fill,
                          size: 10,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          deliveryAddress!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemOrange.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(CupertinoIcons.location_slash_fill,
              color: CupertinoColors.white, size: 16),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No delivery address set!\nGo to Settings → Delivery Location to pin your drop-off point.',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
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
  final String? addressLabel;
  final ScrollController scrollController;

  const _BottomPanel({
    required this.order,
    required this.pinnedLocation,
    required this.scrollController,
    this.addressLabel,
  });

  String _shortId(String id) {
    if (id.length > 16) return id.substring(6, 16);
    return id;
  }

  String _displayAddress() {
    if (pinnedLocation == null) return 'Not set — go to Settings';
    if (addressLabel != null && addressLabel!.isNotEmpty) return addressLabel!;
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

          // ── Food Tiger branding header ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40FF6B35),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🐯', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Food Tiger',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF6B35),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Your order is on the way',
                      style: TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
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
                      '₱${order.totalAmount.toStringAsFixed(0)}',
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
                  label: _displayAddress(),
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
    final isDelivered = status == OrderStatus.delivered;

    // Accent colour: green when delivered, blue otherwise
    final activeColor = isDelivered
        ? CupertinoColors.systemGreen.resolveFrom(context)
        : CupertinoColors.systemBlue.resolveFrom(context);

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        // Odd indices are connector lines
        if (i.isOdd) {
          final lineIndex = i ~/ 2;
          // Fill the line if the step ahead of it is reached
          final filled = currentStep > lineIndex;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 2,
              color: filled
                  ? activeColor
                  : CupertinoColors.systemFill.resolveFrom(context),
            ),
          );
        }

        final stepIndex = i ~/ 2;
        // A step is "done" (filled circle + checkmark) when:
        //   • currentStep has passed it (currentStep > stepIndex), OR
        //   • it IS the current step AND status is delivered (last step reached)
        final isDone    = currentStep > stepIndex ||
                          (isDelivered && stepIndex == currentStep);
        final isCurrent = !isDone && currentStep == stepIndex;

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
                    ? activeColor
                    : isCurrent
                        ? activeColor.withValues(alpha: 0.15)
                        : CupertinoColors.systemFill.resolveFrom(context),
                border: isCurrent
                    ? Border.all(color: activeColor, width: 2)
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
                              color: activeColor,
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
                fontWeight: (isDone || isCurrent)
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: (isDone || isCurrent)
                    ? (isDone
                        ? activeColor
                        : CupertinoColors.label.resolveFrom(context))
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
  int _step   = 0; // 0 = delivered screen, 1 = rating screen

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
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        child: _step == 0
            ? _buildDeliveredStep(context)
            : _buildRatingStep(context),
      ),
    );
  }

  // ── Step 0: Order Delivered ─────────────────────────────────────────────

  Widget _buildDeliveredStep(BuildContext context) {
    return Column(
      key: const ValueKey('delivered'),
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

        // Big checkmark
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGreen.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.checkmark_seal_fill,
            size: 50,
            color: CupertinoColors.systemGreen,
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Order Delivered! 🎉',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your food has arrived.\nEnjoy your meal!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),

        const SizedBox(height: 32),

        // Continue → go to rating step
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            borderRadius: BorderRadius.circular(14),
            onPressed: () => setState(() => _step = 1),
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 1: Rate your order ─────────────────────────────────────────────

  Widget _buildRatingStep(BuildContext context) {
    return Column(
      key: const ValueKey('rating'),
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

        Text(
          'How was your order?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Rate your delivery experience',
          style: TextStyle(
            fontSize: 14,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),

        const SizedBox(height: 28),

        // Star rating
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
                  size: 38,
                  color: filled
                      ? CupertinoColors.systemYellow
                      : CupertinoColors.systemFill.resolveFrom(context),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 32),

        // Done button
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            borderRadius: BorderRadius.circular(14),
            onPressed: widget.onDone,
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ),
      ],
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
