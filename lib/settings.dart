import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:faceid/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'core/database/location_service.dart';
import 'map/map_view.dart';
import 'providers/theme_provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _box             = Hive.box('database');
  final _locationService = LocationService();

  // â”€â”€ Local state for instant toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late bool _biometricsEnabled;

  @override
  void initState() {
    super.initState();
    _biometricsEnabled = _box.get('biometrics') ?? false;
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _tiles(
      dynamic trailing,
      String title,
      Color color,
      IconData icon,
      String additionalInfo, {
      Widget? iconWidget,
      VoidCallback? onTap,
  }) {
    return CupertinoListTile.notched(
      onTap: onTap,
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      ),
      additionalInfo: additionalInfo.isNotEmpty
          ? ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                additionalInfo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            )
          : null,
      trailing: trailing,
      leading: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Center(
          child: iconWidget ??
              Icon(icon, size: 17, color: CupertinoColors.white),
        ),
      ),
    );
  }

  String _locationLabel() {
    final address = _locationService.getSavedAddress();
    if (address != null && address.isNotEmpty) return address;
    final lat = _locationService.getSavedLat();
    final lng = _locationService.getSavedLng();
    if (lat == null || lng == null) return 'Not set';
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<({LatLng latLng, String address})?>(
      CupertinoPageRoute(
        builder: (_) => _LocationPickerPage(
          initial: _locationService.hasSavedLocation()
              ? LatLng(
            _locationService.getSavedLat()!,
            _locationService.getSavedLng()!,
          )
              : null,
          initialAddress: _locationService.getSavedAddress(),
        ),
      ),
    );

    if (result != null) {
      await _locationService.saveLocation(
        result.latLng.latitude,
        result.latLng.longitude,
        address: result.address,
      );
      if (mounted) setState(() {});
    }
  }

    // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    @override
    Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: CustomScrollView(
        slivers: [
          // ── Large title nav bar ─────────────────────────────────────────
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Settings'),
            border: null,
          ),

          SliverList(
            delegate: SliverChildListDelegate([

              // ── ACCOUNT ─────────────────────────────────────────────────
              CupertinoListSection.insetGrouped(
                header: const Text('ACCOUNT'),
                children: [
                  // Profile tile
                  CupertinoListTile.notched(
                    onTap: () {
                      showCupertinoDialog<void>(
                        context: context,
                        builder: (ctx) => CupertinoAlertDialog(
                          title: const Text('Profile'),
                          content: Text(
                            'Signed in as: ${_box.get('username') ?? 'Guest'}',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('OK'),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      );
                    },
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A7BD5), // formal steel-blue
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Center(
                        child: Icon(CupertinoIcons.person_fill,
                            size: 17, color: CupertinoColors.white),
                      ),
                    ),
                    title: Text(
                      _box.get('username') ?? 'Guest',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    additionalInfo: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        _box.get('email') ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey),
                      ),
                    ),
                    trailing: const CupertinoListTileChevron(),
                  ),

                  // Face ID tile
                  _tiles(
                    CupertinoSwitch(
                      value: _biometricsEnabled,
                      onChanged: (value) {
                        setState(() => _biometricsEnabled = value);
                        _box.put('biometrics', value);
                      },
                    ),
                    'Face ID',
                    const Color(0xFF2DB87D), // formal teal-green
                    CupertinoIcons.person_fill,
                    '',
                    iconWidget: const _FaceIdIcon(
                        size: 17, color: CupertinoColors.white),
                  ),
                ],
              ),

              // ── APPEARANCE ──────────────────────────────────────────────
              CupertinoListSection.insetGrouped(
                header: const Text('APPEARANCE'),
                children: [
                  _tiles(
                    CupertinoSwitch(
                      value: themeProvider.isDark,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    ),
                    'Dark Mode',
                    const Color(0xFF5856D6), // formal indigo
                    CupertinoIcons.moon_fill,
                    themeProvider.isDark ? 'On' : 'Off',
                  ),
                ],
              ),

              // ── DELIVERY ────────────────────────────────────────────────
              CupertinoListSection.insetGrouped(
                header: const Text('DELIVERY'),
                footer: const Padding(
                  padding: EdgeInsets.only(top: 6),
                ),
                children: [
                  _tiles(
                    const CupertinoListTileChevron(),
                    'Delivery Location',
                    const Color(0xFF007AFF), // iOS system blue
                    CupertinoIcons.location_fill,
                    _locationLabel(),
                    onTap: _openLocationPicker,
                  ),
                ],
              ),

              // ── SIGN OUT ────────────────────────────────────────────────
              CupertinoListSection.insetGrouped(
                children: [
                  _tiles(
                    const SizedBox.shrink(),
                    'Sign Out',
                    const Color(0xFFFF3B30), // iOS system red
                    CupertinoIcons.square_arrow_right,
                    '',
                    onTap: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (ctx) => CupertinoAlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text(
                              'Are you sure you want to sign out?'),
                          actions: [
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: const Text('Sign Out'),
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                            CupertinoDialogAction(
                              isDefaultAction: true,
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── App version footer ───────────────────────────────────────
              Center(
                child: Text(
                  'Food Tiger v1.0.0',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
    );
  }
}


class _NominatimResult {
  final String displayName;
  final double lat;
  final double lng;

  const _NominatimResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  factory _NominatimResult.fromJson(Map<String, dynamic> json) {
    return _NominatimResult(
      displayName: json['display_name'] as String,
      lat: double.parse(json['lat'] as String),
      lng: double.parse(json['lon'] as String),
    );
  }

  /// Short label â€” first two comma-separated parts of display_name.
  String get shortName {
    final parts = displayName.split(',');
    if (parts.length >= 2) return '${parts[0].trim()}, ${parts[1].trim()}';
    return parts[0].trim();
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Location Picker Page â€” search-driven; Nominatim forward geocoding
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LocationPickerPage extends StatefulWidget {
  /// Pre-existing saved pin (null if first time).
  final LatLng? initial;
  final String? initialAddress;

  const _LocationPickerPage({this.initial, this.initialAddress});

  @override
  State<_LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<_LocationPickerPage> {
  // â”€â”€ Controllers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // â”€â”€ State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  LatLng? _pinned;
  String? _pinnedAddress;
  List<_NominatimResult> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;

  // â”€â”€ Debounce â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Timer? _debounce;

  /// Metro Manila default view centre
  static const LatLng _manilaCenter = LatLng(14.5995, 120.9842);

  // â”€â”€ Lifecycle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initial != null) {
      _pinned = widget.initial;
      // Prefer saved address label; fall back to coordinates only if not stored
      _pinnedAddress = (widget.initialAddress != null && widget.initialAddress!.isNotEmpty)
          ? widget.initialAddress
          : '${widget.initial!.latitude.toStringAsFixed(5)}, '
          '${widget.initial!.longitude.toStringAsFixed(5)}';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // â”€â”€ Nominatim search â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _fetchSuggestions(query.trim());
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(query)}'
            '&format=json&limit=6&addressdetails=0',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'faceid-flutter-app/1.0'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _suggestions = data
              .map((e) => _NominatimResult.fromJson(e as Map<String, dynamic>))
              .toList();
          _showSuggestions = _suggestions.isNotEmpty;
          _isSearching = false;
        });
      } else {
        setState(() => _isSearching = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // â”€â”€ Suggestion selected â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _selectSuggestion(_NominatimResult result) {
    final latLng = LatLng(result.lat, result.lng);
    _searchController.text = result.shortName;
    _searchFocus.unfocus();
    setState(() {
      _pinned = latLng;
      _pinnedAddress = result.displayName;
      _suggestions = [];
      _showSuggestions = false;
    });
    // Animate map camera to the chosen location
    _mapController.move(latLng, 15);
  }

  // â”€â”€ Clear pin â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _clearPin() {
    _searchController.clear();
    setState(() {
      _pinned = null;
      _pinnedAddress = null;
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final bg = CupertinoColors.systemBackground.resolveFrom(context);
    final secondaryBg =
    CupertinoColors.secondarySystemBackground.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel =
    CupertinoColors.secondaryLabel.resolveFrom(context);
    final separatorColor =
    CupertinoColors.separator.resolveFrom(context);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Set Delivery Location'),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // â”€â”€ Full-screen map (no tap-to-pin) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _pinned ?? _manilaCenter,
                initialZoom: _pinned != null ? 15 : 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.faceid',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    // Store marker — Holy Cross College, Candaba, Pampanga
                    Marker(
                      point: DeliveryLocations.storeLocation,
                      width: 90,
                      height: 70,
                      child: _buildStoreMarker(),
                    ),
                    if (_pinned != null)
                      Marker(
                        point: _pinned!,
                        width: 70,
                        height: 62,
                        child: _buildPin(),
                      ),
                  ],
                ),
              ],
            ),

            // â”€â”€ Top search panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search field card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: bg.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withValues(alpha: 0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.search,
                            size: 18, color: secondaryLabel),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CupertinoTextField.borderless(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            autocorrect: false,
                            enableSuggestions: false,
                            placeholder: 'Search address or place…',
                            placeholderStyle: TextStyle(
                              color: secondaryLabel,
                              fontSize: 15,
                            ),
                            style: TextStyle(
                              color: labelColor,
                              fontSize: 15,
                            ),
                            onChanged: _onSearchChanged,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) {
                              if (_searchController.text.trim().length >= 3) {
                                _fetchSuggestions(
                                    _searchController.text.trim());
                              }
                            },
                          ),
                        ),
                        if (_isSearching)
                          const CupertinoActivityIndicator(radius: 9)
                        else if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: _clearPin,
                            child: Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 18,
                              color: secondaryLabel,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // â”€â”€ Suggestions list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  if (_showSuggestions && _suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: bg.withValues(alpha: 0.97),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                            CupertinoColors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          children: List.generate(_suggestions.length, (i) {
                            final item = _suggestions[i];
                            final isLast = i == _suggestions.length - 1;
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _selectSuggestion(item),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 11),
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.location,
                                          size: 16,
                                          color: CupertinoColors.systemBlue
                                              .resolveFrom(context),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.shortName,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: labelColor,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.displayName,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: secondaryLabel,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isLast)
                                    Container(
                                      height: 0.5,
                                      margin: const EdgeInsets.only(left: 40),
                                      color: separatorColor,
                                    ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // â”€â”€ Bottom confirmation panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_pinned != null && !_showSuggestions)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag indicator
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: separatorColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Address row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: secondaryBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              CupertinoIcons.location_fill,
                              size: 18,
                              color: CupertinoColors.systemBlue
                                  .resolveFrom(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery location',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: secondaryLabel,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _pinnedAddress ??
                                      '${_pinned!.latitude.toStringAsFixed(5)}, '
                                          '${_pinned!.longitude.toStringAsFixed(5)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: labelColor,
                                    height: 1.35,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Save button
                      CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () => Navigator.of(context).pop((
                        latLng: _pinned!,
                        address: _pinnedAddress ?? '',
                        )),
                        child: const Text(
                          'Save Location',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Change / clear link
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _clearPin,
                        child: Text(
                          'Change location',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFFFF6B35), // Food Tiger orange
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

  // â”€â”€ Pin widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35), // Food Tiger orange
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(CupertinoIcons.location_fill,
              color: CupertinoColors.white, size: 20),
        ),
        // Pin stem
        Container(
          width: 3,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFFF6B35), // Food Tiger orange
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreMarker() {
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
} // end _LocationPickerPageState

// ─────────────────────────────────────────────────────────────────────────────
// Face ID icon — CustomPainter (corner brackets + eyes + nose + smile)
// ─────────────────────────────────────────────────────────────────────────────

class _FaceIdIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _FaceIdIcon({this.size = 24, this.color = CupertinoColors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FaceIdPainter(color: color),
      ),
    );
  }
}

class _FaceIdPainter extends CustomPainter {
  final Color color;
  const _FaceIdPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = w * 0.18;
    final arm = w * 0.28;

    // Top-left bracket
    canvas.drawPath(
      ui.Path()
        ..moveTo(0, arm)
        ..lineTo(0, r)
        ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
        ..lineTo(arm, 0),
      paint,
    );
    // Top-right bracket
    canvas.drawPath(
      ui.Path()
        ..moveTo(w - arm, 0)
        ..lineTo(w - r, 0)
        ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
        ..lineTo(w, arm),
      paint,
    );
    // Bottom-left bracket
    canvas.drawPath(
      ui.Path()
        ..moveTo(0, h - arm)
        ..lineTo(0, h - r)
        ..arcToPoint(Offset(r, h),
            radius: Radius.circular(r), clockwise: false)
        ..lineTo(arm, h),
      paint,
    );
    // Bottom-right bracket
    canvas.drawPath(
      ui.Path()
        ..moveTo(w - arm, h)
        ..lineTo(w - r, h)
        ..arcToPoint(Offset(w, h - r),
            radius: Radius.circular(r), clockwise: false)
        ..lineTo(w, h - arm),
      paint,
    );

    final cx = w / 2;
    // Left eye
    canvas.drawLine(
      Offset(cx - w * 0.22, h * 0.33),
      Offset(cx - w * 0.22, h * 0.45),
      paint,
    );
    // Right eye
    canvas.drawLine(
      Offset(cx + w * 0.22, h * 0.33),
      Offset(cx + w * 0.22, h * 0.45),
      paint,
    );
    // Nose
    canvas.drawPath(
      ui.Path()
        ..moveTo(cx, h * 0.40)
        ..lineTo(cx, h * 0.58)
        ..lineTo(cx - w * 0.08, h * 0.62),
      paint,
    );
    // Smile
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, h * 0.62),
        width: w * 0.44,
        height: h * 0.22,
      ),
      0.3,
      2.54,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_FaceIdPainter old) => old.color != color;
}
