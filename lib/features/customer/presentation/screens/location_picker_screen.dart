import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../models/delivery_location.dart';
import '../../../../services/device_location_service.dart';

const _zamboangaCity = LatLng(6.9214, 122.0790);

typedef LocationPickerMapBuilder =
    Widget Function({
      required LatLng initialCenter,
      required LatLng? selectedPoint,
      required ValueChanged<LatLng> onSelect,
      required ValueChanged<DragUpdateDetails> onDragPin,
    });

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    this.initialLocation,
    this.locationService,
    this.mapBuilder,
    super.key,
  });

  final DeliveryLocation? initialLocation;
  final DeviceLocationService? locationService;
  final LocationPickerMapBuilder? mapBuilder;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapKey = GlobalKey();
  final _mapController = MapController();
  late final DeviceLocationService _locationService;
  LatLng? _selectedPoint;
  bool _isLocating = false;
  bool _showSettingsAction = false;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    _locationService =
        widget.locationService ?? GeolocatorDeviceLocationService();
    final location = widget.initialLocation;
    if (location != null && location.isValid) {
      _selectedPoint = LatLng(location.latitude, location.longitude);
    }
  }

  void _selectPoint(LatLng point) {
    if (!point.latitude.isFinite ||
        !point.longitude.isFinite ||
        point.latitude < -90 ||
        point.latitude > 90 ||
        point.longitude < -180 ||
        point.longitude > 180) {
      return;
    }
    setState(() {
      _selectedPoint = point;
      _locationMessage = null;
    });
  }

  void _dragPin(DragUpdateDetails details) {
    final renderObject = _mapKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final localOffset = renderObject.globalToLocal(details.globalPosition);
    _selectPoint(_mapController.camera.screenOffsetToLatLng(localOffset));
  }

  Future<void> _useCurrentLocation() async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use your current location?'),
        content: const Text(
          'AquaQueue uses your device location only to place a delivery pin. '
          'Your typed address remains required and you can still move the pin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (shouldContinue != true || !mounted) return;

    setState(() {
      _isLocating = true;
      _locationMessage = null;
      _showSettingsAction = false;
    });
    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;
      final point = LatLng(location.latitude, location.longitude);
      setState(() {
        _selectedPoint = point;
        _isLocating = false;
      });
      _mapController.move(point, 16);
    } on LocationAccessFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _showSettingsAction =
            failure.issue == LocationAccessIssue.permanentlyDenied ||
            failure.issue == LocationAccessIssue.servicesDisabled;
        _locationMessage = switch (failure.issue) {
          LocationAccessIssue.denied =>
            'Location permission was denied. You can still tap or drag the map pin.',
          LocationAccessIssue.permanentlyDenied =>
            'Location permission is disabled for AquaQueue. Enable it in app settings, or choose a pin on the map.',
          LocationAccessIssue.servicesDisabled =>
            'Device location services are off. Enable them or choose a pin on the map.',
        };
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _locationMessage =
            'Current location is unavailable. You can still choose a pin on the map.';
      });
    }
  }

  Future<void> _openSettings() async {
    final opened = await _locationService.openAppSettings();
    if (!opened && mounted) {
      setState(() {
        _locationMessage =
            'App settings could not be opened. You can still choose a pin on the map.';
        _showSettingsAction = false;
      });
    }
  }

  void _confirmSelection() {
    final selected = _selectedPoint;
    if (selected == null) return;
    Navigator.of(context).pop(
      DeliveryLocation(
        latitude: selected.latitude,
        longitude: selected.longitude,
      ),
    );
  }

  Widget _buildMap() {
    final mapBuilder = widget.mapBuilder;
    if (mapBuilder != null) {
      return mapBuilder(
        initialCenter: _selectedPoint ?? _zamboangaCity,
        selectedPoint: _selectedPoint,
        onSelect: _selectPoint,
        onDragPin: _dragPin,
      );
    }

    return FlutterMap(
      key: _mapKey,
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _selectedPoint ?? _zamboangaCity,
        initialZoom: _selectedPoint == null ? 13 : 16,
        onTap: (_, point) => _selectPoint(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.aquaqueue.app',
        ),
        if (_selectedPoint case final point?)
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 56,
                height: 64,
                child: GestureDetector(
                  onPanUpdate: _dragPin,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 54,
                  ),
                ),
              ),
            ],
          ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              '© OpenStreetMap contributors',
              onTap: () => launchUrl(
                Uri.parse('https://www.openstreetmap.org/copyright'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pin delivery location'),
        actions: [
          TextButton(
            onPressed: _selectedPoint == null ? null : _confirmSelection,
            child: const Text('Use pin'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              children: [
                const Text(
                  'Tap the map or drag the pin to mark your delivery location. '
                  'The typed address is still required.',
                ),
                const SizedBox(height: AppSpacing.small),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLocating ? null : _useCurrentLocation,
                    icon: _isLocating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      _isLocating ? 'Finding location...' : 'Use current location',
                    ),
                  ),
                ),
                if (_locationMessage != null) ...[
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    _locationMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_showSettingsAction)
                  TextButton(
                    onPressed: _openSettings,
                    child: const Text('Open location settings'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _buildMap(),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedPoint == null ? null : _confirmSelection,
                  child: Text(
                    _selectedPoint == null
                        ? 'Tap map to place a pin'
                        : 'Confirm delivery location',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
