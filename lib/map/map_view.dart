import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Default delivery scenario locations — Metro Manila, Philippines.
class DeliveryLocations {
  /// Restaurant pin — Rizal Park area, Manila
  static const LatLng restaurantLocation   = LatLng(15.093534690707086, 120.76943059939434);

  /// Fallback customer location — BGC, Taguig (used only when no pin saved)
  static const LatLng customerLocation     = LatLng(14.5547, 121.0514);

  /// Rider always departs from the restaurant
  static const LatLng riderInitialLocation = LatLng(15.093534690707086, 120.76943059939434);
}

class MapView extends StatefulWidget {
  /// Optional rider position — updated each timer tick.
  final LatLng? riderLocation;

  /// Route waypoints produced by [PathfindingService].
  final List<LatLng> route;

  /// User-pinned delivery destination. Shown as a distinct marker.
  final LatLng? pinnedLocation;

  /// If non-null, map taps are forwarded to this callback (pin phase only).
  final void Function(LatLng)? onMapTapped;

  const MapView({
    super.key,
    this.riderLocation,
    this.route = const [],
    this.pinnedLocation,
    this.onMapTapped,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Calculate the center point between two locations
  LatLng _calculateCenter(LatLng loc1, LatLng loc2) {
    return LatLng(
      (loc1.latitude + loc2.latitude) / 2,
      (loc1.longitude + loc2.longitude) / 2,
    );
  }

  /// Calculate appropriate zoom level based on distance
  double _calculateZoom(LatLng loc1, LatLng loc2) {
    // Calculate distance in degrees (approximate)
    final latDiff = (loc1.latitude - loc2.latitude).abs();
    final lonDiff = (loc1.longitude - loc2.longitude).abs();
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;

    // Adjust zoom based on approximate distance
    if (maxDiff < 0.005) return 15.0;
    if (maxDiff < 0.01) return 14.0;
    if (maxDiff < 0.02) return 13.0;
    return 12.0;
  }

  @override
  Widget build(BuildContext context) {
    final riderLoc = widget.riderLocation ?? DeliveryLocations.riderInitialLocation;

    // Center between rider start and pinned destination (if set),
    // otherwise fall back to restaurant↔customer midpoint.
    final LatLng refEnd =
        widget.pinnedLocation ?? DeliveryLocations.customerLocation;
    final center = _calculateCenter(DeliveryLocations.riderInitialLocation, refEnd);
    final zoom   = _calculateZoom(DeliveryLocations.riderInitialLocation, refEnd);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: 1,
        maxZoom: 18,
        onTap: widget.onMapTapped != null
            ? (_, latLng) => widget.onMapTapped!(latLng)
            : null,
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.faceid',
          maxZoom: 19,
        ),

        // A* route polyline — only drawn when waypoints are available
        if (widget.route.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.route,
                strokeWidth: 4.0,
                color: CupertinoColors.systemBlue.withValues(alpha: 0.85),
              ),
            ],
          ),

        // Markers layer
        MarkerLayer(
          markers: [
            // Restaurant marker — Food Tiger branding
            Marker(
              point: DeliveryLocations.restaurantLocation,
              width: 90,
              height: 70,
              child: _buildRestaurantMarker(),
            ),

            // Rider marker — position updated each timer tick
            Marker(
              point: riderLoc,
              width: 70,
              height: 60,
              child: _buildMarker(
                icon: CupertinoIcons.car_fill,
                color: CupertinoColors.systemOrange,
                label: 'Rider',
              ),
            ),

            // Pinned delivery destination marker (shown after user taps map)
            if (widget.pinnedLocation != null)
              Marker(
                point: widget.pinnedLocation!,
                width: 70,
                height: 60,
                child: _buildMarker(
                  icon: CupertinoIcons.location_fill,
                  color: CupertinoColors.systemGreen,
                  label: 'Delivery',
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRestaurantMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF6B35),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: const Text('🐯', style: TextStyle(fontSize: 20)),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Food Tiger',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarker({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: CupertinoColors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}




