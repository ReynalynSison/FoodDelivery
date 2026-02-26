import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'settings.dart';
import 'food/food_list_page.dart';
import 'pages/history_page.dart';
import 'pages/tracking_page.dart';
import 'pages/wishlist_page.dart';
import 'providers/order_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/wishlist_provider.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final _tabController = CupertinoTabController(initialIndex: 0);
  final _browseKey = GlobalKey<FoodListPageState>();
  bool _ratingShown = false;
  int _currentIndex = 0;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRatingModal(BuildContext context, OrderProvider orderProvider, String orderId) {
    if (_ratingShown) return;
    _ratingShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showCupertinoModalPopup<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _DeliveredRatingSheet(
          onDone: () {
            Navigator.of(ctx).pop();
            orderProvider.clearPendingRating(orderId);
            if (mounted) setState(() => _ratingShown = false);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final hasActive     = orderProvider.activeOrders.isNotEmpty;
    final isDark        = context.watch<ThemeProvider>().isDark;

    // Show the rating modal for the first pending-rating order
    if (orderProvider.pendingRating && !_ratingShown) {
      final pendingOrder = orderProvider.activeOrders
          .where((o) => orderProvider.isPendingRating(o.id))
          .firstOrNull;
      if (pendingOrder != null) {
        _showRatingModal(context, orderProvider, pendingOrder.id);
      }
    } else if (!orderProvider.pendingRating && _ratingShown) {
      // Reset flag when no more pending ratings
      _ratingShown = false;
    }

    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        backgroundColor: isDark
            ? const Color(0xFF1C1C1E)  // Dark mode - match app background
            : const Color(0xFFF5EFE6), // Light mode - cream/beige
        activeColor: const Color(0xFFFF6B35), // Food Tiger orange accent
        inactiveColor: isDark
            ? const Color(0xFF8E8E93)  // Dark mode inactive icons
            : const Color(0xFF8E8E93), // Light mode inactive icons
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF38383A) // Dark mode separator
                : const Color(0xFFE5DED4), // Light mode separator
            width: 0.5,
          ),
        ),
        onTap: (index) {
          if (index == 0 && _currentIndex == 0) {
            // Re-tapped Browse while already on Browse → scroll to top
            _browseKey.currentState?.scrollToTop();
          }
          _currentIndex = index;
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house_fill),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(CupertinoIcons.location_fill),
                if (hasActive)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B35),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Track',
          ),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.clock_fill),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(CupertinoIcons.heart_fill),
                if (context.watch<WishlistProvider>().ids.isNotEmpty)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B35),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Wishlist',
          ),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings_solid),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return FoodListPage(key: _browseKey);
          case 1:
            return _TrackTab(isDark: isDark);
          case 2:
            return HistoryPage(
              onBrowseMenu: () => _tabController.index = 0,
            );
          case 3:
            return const WishlistPage();
          default:
            return const Settings();
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Track tab
// ─────────────────────────────────────────────────────────────────────────────

class _TrackTab extends StatelessWidget {
  final bool isDark;
  const _TrackTab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final activeOrders = context.watch<OrderProvider>().activeOrders;

    if (activeOrders.isNotEmpty) {
      return const TrackingPage(isEmbedded: true);
    }

    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5EFE6),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0EBE3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.location,
                  size: 40,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Active Order',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF2F2F7) : const Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your delivery will appear here\nonce you place an order.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delivered rating sheet — shown as a global modal over any tab
// ─────────────────────────────────────────────────────────────────────────────

class _DeliveredRatingSheet extends StatefulWidget {
  final VoidCallback onDone;
  const _DeliveredRatingSheet({required this.onDone});

  @override
  State<_DeliveredRatingSheet> createState() => _DeliveredRatingSheetState();
}

class _DeliveredRatingSheetState extends State<_DeliveredRatingSheet> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
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
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: CupertinoColors.systemFill.resolveFrom(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Check icon
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.checkmark_seal_fill,
                size: 40, color: CupertinoColors.systemGreen),
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

