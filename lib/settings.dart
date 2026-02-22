import 'package:faceid/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'core/database/location_service.dart';
import 'providers/theme_provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _box             = Hive.box('database');
  final _locationService = LocationService();

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _tiles(
    dynamic trailing,
    String title,
    Color color,
    IconData icon,
    String additionalInfo,
  ) {
    return CupertinoListTile(
      title: Text(title),
      additionalInfo: Text(additionalInfo),
      trailing: trailing,
      leading: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: color,
        ),
        child: Icon(icon, size: 17),
      ),
    );
  }

  String _locationLabel() {
    final lat = _locationService.getSavedLat();
    final lng = _locationService.getSavedLng();
    if (lat == null || lng == null) return 'Not set';
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  Future<void> _openLocationPicker() async {
    final saved = await Navigator.of(context).push<LatLng?>(
      CupertinoPageRoute(
        builder: (_) => _LocationPickerPage(
          initial: _locationService.hasSavedLocation()
              ? LatLng(
                  _locationService.getSavedLat()!,
                  _locationService.getSavedLng()!,
                )
              : null,
        ),
      ),
    );

    if (saved != null) {
      await _locationService.saveLocation(saved.latitude, saved.longitude);
      if (mounted) setState(() {});
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return CupertinoPageScaffold(
      child: ListView(
        children: [
          // ── Account section ──────────────────────────────────────────────
          CupertinoListSection.insetGrouped(
            header: const Text('Account'),
            children: [
              _tiles(
                CupertinoSwitch(
                  value: _box.get('biometrics') ?? false,
                  onChanged: (value) {
                    setState(() => _box.put('biometrics', value));
                  },
                ),
                'Biometrics',
                CupertinoColors.systemGreen,
                CupertinoIcons.hand_thumbsup_fill,
                '',
              ),
              GestureDetector(
                onTap: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: const Text('Logout?'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('Yes'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pushReplacement(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: const Text('Close'),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  );
                },
                child: _tiles(
                  const Icon(CupertinoIcons.chevron_forward),
                  'Sign out',
                  CupertinoColors.systemPurple,
                  CupertinoIcons.square_arrow_right,
                  _box.get('username') ?? '',
                ),
              ),
            ],
          ),

          // ── Appearance section ───────────────────────────────────────────
          CupertinoListSection.insetGrouped(
            header: const Text('Appearance'),
            children: [
              _tiles(
                CupertinoSwitch(
                  value: themeProvider.isDark,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
                'Dark Mode',
                CupertinoColors.systemIndigo,
                CupertinoIcons.moon_fill,
                themeProvider.isDark ? 'On' : 'Off',
              ),
            ],
          ),

          // ── Delivery Location section ─────────────────────────────────────
          CupertinoListSection.insetGrouped(
            header: const Text('Delivery Location'),
            footer: const Text(
              'Tap to open the map and pin your delivery address. '
              'This location will be used as the drop-off point.',
            ),
            children: [
              GestureDetector(
                onTap: _openLocationPicker,
                child: _tiles(
                  const Icon(CupertinoIcons.chevron_forward),
                  'Set Delivery Location',
                  CupertinoColors.systemBlue,
                  CupertinoIcons.location_fill,
                  _locationLabel(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Location Picker Page — full-screen map; tap to pin, confirm to save
// ─────────────────────────────────────────────────────────────────────────────

class _LocationPickerPage extends StatefulWidget {
  /// Pre-existing saved pin (null if first time).
  final LatLng? initial;

  const _LocationPickerPage({this.initial});

  @override
  State<_LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<_LocationPickerPage> {
  LatLng? _tapped;
  late final MapController _mapController;

  /// Metro Manila default view centre
  static const LatLng _manilaCenter = LatLng(14.5995, 120.9842);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _tapped = widget.initial;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Pin Delivery Location'),
        trailing: _tapped == null
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(_tapped),
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // ── Map ──
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initial ?? _manilaCenter,
                initialZoom: 13,
                onTap: (_, latLng) => setState(() => _tapped = latLng),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.faceid',
                  maxZoom: 19,
                ),
                if (_tapped != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _tapped!,
                        width: 70,
                        height: 60,
                        child: _buildPin(),
                      ),
                    ],
                  ),
              ],
            ),

            // ── Instruction banner ──
            if (_tapped == null)
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.resolveFrom(context)
                        .withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.location_fill,
                          color: CupertinoColors.systemBlue, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap anywhere on the map to pin your delivery location.',
                          style: TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Coordinates chip ──
            if (_tapped != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.resolveFrom(context)
                        .withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.location_solid,
                          color: CupertinoColors.systemGreen, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_tapped!.latitude.toStringAsFixed(5)}, '
                          '${_tapped!.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => setState(() => _tapped = null),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.systemRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(CupertinoIcons.location_fill,
              color: CupertinoColors.white, size: 20),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGreen.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Delivery',
            style: TextStyle(
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