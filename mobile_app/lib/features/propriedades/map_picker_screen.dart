import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_colors.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key, this.initial, this.readOnly = false});

  final LatLng? initial;

  final bool readOnly;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _NominatimSuggestion {
  const _NominatimSuggestion({
    required this.mainText,
    required this.secondaryText,
    required this.lat,
    required this.lon,
  });

  final String mainText;
  final String secondaryText;
  final double lat;
  final double lon;
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const _defaultCenter = LatLng(-29.6914, -53.8008);
  static const _nominatimUrl = 'https://nominatim.openstreetmap.org/search';

  final _dio = Dio();
  final _mapController = MapController();
  late LatLng _center;

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  List<_NominatimSuggestion> _suggestions = [];
  bool _loadingSuggestions = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? _defaultCenter;
    _dio.options.headers['User-Agent'] = 'PoliVisitas/1.0 (com.ufsm.polivisitas)';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _dio.close();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _fetchSuggestions(query.trim()),
    );
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _loadingSuggestions = true);
    try {
      final response = await _dio.get(
        _nominatimUrl,
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 5,
          'countrycodes': 'br',
          'addressdetails': 1,
        },
      );

      if (!mounted) return;

      final results = response.data as List? ?? [];
      setState(() {
        _suggestions = results.map((r) {
          final displayName = r['display_name'] as String? ?? '';
          final parts = displayName.split(', ');
          final mainText = parts.isNotEmpty ? parts[0] : displayName;
          final secondaryText =
              parts.length > 1 ? parts.sublist(1).join(', ') : '';
          return _NominatimSuggestion(
            mainText: mainText,
            secondaryText: secondaryText,
            lat: double.tryParse(r['lat'] as String? ?? '') ?? 0,
            lon: double.tryParse(r['lon'] as String? ?? '') ?? 0,
          );
        }).toList();
      });
    } catch (_) {
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  void _selectSuggestion(_NominatimSuggestion suggestion) {
    _searchCtrl.text = suggestion.mainText;
    _searchFocus.unfocus();
    final target = LatLng(suggestion.lat, suggestion.lon);
    setState(() {
      _suggestions = [];
      _center = target;
    });
    _mapController.move(target, 15);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _suggestions = []);
    _searchFocus.requestFocus();
  }

  String _formatLat(double v) {
    final dir = v >= 0 ? 'N' : 'S';
    return '${v.abs().toStringAsFixed(6)}° $dir';
  }

  String _formatLng(double v) {
    final dir = v >= 0 ? 'L' : 'O';
    return '${v.abs().toStringAsFixed(6)}° $dir';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 14,
                    onMapEvent: widget.readOnly
                        ? null
                        : (event) =>
                            setState(() => _center = event.camera.center),
                    onTap: widget.readOnly
                        ? null
                        : (tapPosition, latLng) {
                            _searchFocus.unfocus();
                            setState(() => _suggestions = []);
                          },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.ufsm.polivisitas',
                    ),
                    if (widget.readOnly)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _center,
                            width: 52,
                            height: 56,
                            alignment: Alignment.bottomCenter,
                            child: const Icon(
                              Icons.location_pin,
                              color: AppColors.primary,
                              size: 52,
                              shadows: [
                                Shadow(
                                  color: Color(0x55000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (!widget.readOnly)
                  IgnorePointer(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_pin,
                            color: AppColors.primary,
                            size: 52,
                            shadows: [
                              Shadow(
                                color: Color(0x55000000),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          Container(
                            width: 10,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!widget.readOnly && _suggestions.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 16,
                    right: 16,
                    child: _buildSuggestionsList(),
                  ),
                Positioned(
                  right: 12,
                  bottom: 20,
                  child: Column(
                    children: [
                      _zoomButton(
                        icon: Icons.add,
                        onTap: () {
                          final zoom = _mapController.camera.zoom;
                          _mapController.move(
                              _center, (zoom + 1).clamp(3.0, 20.0));
                        },
                      ),
                      const SizedBox(height: 8),
                      _zoomButton(
                        icon: Icons.remove,
                        onTap: () {
                          final zoom = _mapController.camera.zoom;
                          _mapController.move(
                              _center, (zoom - 1).clamp(3.0, 20.0));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.readOnly
                            ? 'Localização da Propriedade'
                            : 'Escolher Localização',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.readOnly
                            ? 'Arraste ou dê zoom para explorar o mapa'
                            : 'Busque ou mova o mapa para posicionar o pin',
                        style: const TextStyle(
                          color: Color(0xFFCCF2D9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!widget.readOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildSearchBar(),
              ),
            if (widget.readOnly) const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final hasText = _searchCtrl.text.isNotEmpty;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Buscar cidade, bairro ou endereço...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (_loadingSuggestions)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else if (hasText)
            GestureDetector(
              onTap: _clearSearch,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.close, size: 18, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_suggestions.length, (i) {
            final s = _suggestions[i];
            final isLast = i == _suggestions.length - 1;
            return InkWell(
              onTap: () => _selectSuggestion(s),
              borderRadius: isLast
                  ? const BorderRadius.vertical(bottom: Radius.circular(12))
                  : BorderRadius.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i > 0) const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.mainText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (s.secondaryText.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  s.secondaryText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPad + 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.gps_fixed, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${_formatLat(_center.latitude)},  ${_formatLng(_center.longitude)}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF444444)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => widget.readOnly
                  ? Navigator.of(context).pop()
                  : Navigator.of(context).pop(_center),
              icon: Icon(
                widget.readOnly ? Icons.close : Icons.check,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                widget.readOnly ? 'Fechar' : 'Confirmar localização',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}
