import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/app_colors.dart';
import '../../core/env.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key, this.initial});

  final LatLng? initial;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _PlaceSuggestion {
  const _PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });

  final String placeId;
  final String mainText;
  final String secondaryText;
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const _defaultCenter = LatLng(-29.6914, -53.8008);
  static const _placesBaseUrl = 'https://maps.googleapis.com/maps/api/place';

  final _dio = Dio();
  GoogleMapController? _mapController;
  late LatLng _center;

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  List<_PlaceSuggestion> _suggestions = [];
  bool _loadingSuggestions = false;
  bool _loadingDetails = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? _defaultCenter;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
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
      const Duration(milliseconds: 350),
      () => _fetchSuggestions(query.trim()),
    );
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _loadingSuggestions = true);
    try {
      final response = await _dio.get(
        '$_placesBaseUrl/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': Env.mapsApiKey,
          'language': 'pt-BR',
          'components': 'country:br',
        },
      );

      if (!mounted) return;

      final predictions = response.data['predictions'] as List? ?? [];
      setState(() {
        _suggestions = predictions.map((p) {
          final fmt = p['structured_formatting'] as Map<String, dynamic>? ?? {};
          return _PlaceSuggestion(
            placeId: p['place_id'] as String,
            mainText: fmt['main_text'] as String? ?? p['description'] as String,
            secondaryText: fmt['secondary_text'] as String? ?? '',
          );
        }).toList();
      });
    } catch (_) {
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  Future<void> _selectSuggestion(_PlaceSuggestion suggestion) async {
    _searchCtrl.text = suggestion.mainText;
    _searchFocus.unfocus();
    setState(() {
      _suggestions = [];
      _loadingDetails = true;
    });

    try {
      final response = await _dio.get(
        '$_placesBaseUrl/details/json',
        queryParameters: {
          'place_id': suggestion.placeId,
          'fields': 'geometry',
          'key': Env.mapsApiKey,
        },
      );

      if (!mounted) return;

      final loc =
          response.data['result']['geometry']['location']
              as Map<String, dynamic>;
      final target = LatLng(
        (loc['lat'] as num).toDouble(),
        (loc['lng'] as num).toDouble(),
      );

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 15),
        ),
      );
      setState(() => _center = target);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingDetails = false);
    }
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
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _center,
                        zoom: 14,
                      ),
                      onMapCreated: (c) => setState(() => _mapController = c),
                      onCameraMove: (pos) =>
                          setState(() => _center = pos.target),
                      onTap: (_) {
                        _searchFocus.unfocus();
                        setState(() => _suggestions = []);
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                    ),
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
                    if (_suggestions.isNotEmpty)
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
                            onTap: () async {
                              final zoom =
                                  await _mapController?.getZoomLevel() ?? 14;
                              _mapController?.animateCamera(
                                CameraUpdate.zoomTo((zoom + 1).clamp(3, 20)),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _zoomButton(
                            icon: Icons.remove,
                            onTap: () async {
                              final zoom =
                                  await _mapController?.getZoomLevel() ?? 14;
                              _mapController?.animateCamera(
                                CameraUpdate.zoomTo((zoom - 1).clamp(3, 20)),
                              );
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
          if (_loadingDetails)
            const ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Escolher Localização',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Busque ou mova o mapa para posicionar o pin',
                        style: TextStyle(
                          color: Color(0xFFCCF2D9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildSearchBar(),
            ),
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
              onPressed: () => Navigator.of(context).pop(_center),
              icon: const Icon(Icons.check, color: Colors.white, size: 18),
              label: const Text(
                'Confirmar localização',
                style: TextStyle(
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
