import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'models/order.dart';
import 'settings.dart';
import 'food/food_list_page.dart';
import 'pages/history_page.dart';
import 'pages/tracking_page.dart';
import 'providers/order_provider.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house_fill),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.clock_fill),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings_solid),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const _DiscoverTab();
          case 1:
            return HistoryPage();
          default:
            return const Settings();
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Discover tab wrapper — injects the Track Order banner above FoodListPage
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab();

  @override
  Widget build(BuildContext context) {
    final activeOrder = context.watch<OrderProvider>().activeOrder;

    // No active order → show food list alone
    if (activeOrder == null) return const FoodListPage();

    // Active order → stack the banner on top of the food list
    return Stack(
      children: [
        const FoodListPage(),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _TrackOrderBanner(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Persistent "Track Order" sticky banner
// ─────────────────────────────────────────────────────────────────────────────

class _TrackOrderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().activeOrder!;

    String statusLabel;
    switch (order.status) {
      case OrderStatus.confirmed:
        statusLabel = 'Order Confirmed';
        break;
      case OrderStatus.onTheWay:
        statusLabel = 'Delivery is on the way';
        break;
      default:
        statusLabel = 'Order Confirmed';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemBlue
                .resolveFrom(context)
                .withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onPressed: () => Navigator.of(context).push(
          CupertinoPageRoute(builder: (_) => const TrackingPage()),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.location_fill,
              color: CupertinoColors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Track Your Order',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    statusLabel,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
