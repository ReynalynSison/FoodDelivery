import 'dart:async';
import 'dart:convert';

import 'package:faceid/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
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
      additionalInfo: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 140),
        child: Text(
          additionalInfo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
      ),
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
// _NominatimResult — lightweight model for a single Nominatim suggestion
// ─────────────────────────────────────────────────────────────────────────────

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

  /// Short label — first two comma-separated parts of display_name.
  String get shortName {
    final parts = displayName.split(',');
    if (parts.length >= 2) return '${parts[0].trim()}, ${parts[1].trim()}';
    return parts[0].trim();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Location Picker Page — search-driven; Nominatim forward geocoding
// ─────────────────────────────────────────────────────────────────────────────

class _LocationPickerPage extends StatefulWidget {
  /// Pre-existing saved pin (null if first time).
  final LatLng? initial;
  final String? initialAddress;

  const _LocationPickerPage({this.initial, this.initialAddress});

  @override
  State<_LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<_LocationPickerPage> {
  // ── Controllers ────────────────────────────────────────────────────────────
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // ── State ──────────────────────────────────────────────────────────────────
  LatLng? _pinned;
  String? _pinnedAddress;
  List<_NominatimResult> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;

  // ── Debounce ───────────────────────────────────────────────────────────────
  Timer? _debounce;

  /// Metro Manila default view centre
  static const LatLng _manilaCenter = LatLng(14.5995, 120.9842);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

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

  // ── Nominatim search ───────────────────────────────────────────────────────

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

  // ── Suggestion selected ────────────────────────────────────────────────────

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

  // ── Clear pin ──────────────────────────────────────────────────────────────

  void _clearPin() {
    _searchController.clear();
    setState(() {
      _pinned = null;
      _pinnedAddress = null;
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
            // ── Full-screen map (no tap-to-pin) ─────────────────────────────
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
                if (_pinned != null)
                  MarkerLayer(
                    markers: [
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

            // ── Top search panel ─────────────────────────────────────────────
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

                  // ── Suggestions list ────────────────────────────────────
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

            // ── Bottom confirmation panel ────────────────────────────────────
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
                            color: CupertinoColors.systemBlue
                                .resolveFrom(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Empty state hint (no pin yet, suggestions closed) ────────────
            if (_pinned == null && !_showSuggestions)
              Positioned(
                bottom: 28,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: bg.withValues(alpha: 0.93),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.search,
                          size: 16, color: secondaryLabel),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search for your delivery address above.',
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryLabel,
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

  // ── Pin widget ─────────────────────────────────────────────────────────────

  Widget _buildPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBlue,
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
            color: CupertinoColors.systemBlue,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

