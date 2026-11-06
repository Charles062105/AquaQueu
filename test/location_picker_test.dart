import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:aquaqueu/features/customer/presentation/screens/location_picker_screen.dart';
import 'package:aquaqueu/models/delivery_location.dart';
import 'package:aquaqueu/services/device_location_service.dart';

class _FakeDeviceLocationService implements DeviceLocationService {
  _FakeDeviceLocationService({this.failure});

  final LocationAccessFailure? failure;
  bool settingsOpened = false;

  @override
  Future<DeliveryLocation> getCurrentLocation() async {
    final error = failure;
    if (error != null) throw error;
    return const DeliveryLocation(latitude: 6.9, longitude: 122.1);
  }

  @override
  Future<bool> openAppSettings() async {
    settingsOpened = true;
    return true;
  }
}

Widget _testMap({
  required LatLng initialCenter,
  required LatLng? selectedPoint,
  required ValueChanged<LatLng> onSelect,
  required ValueChanged<DragUpdateDetails> onDragPin,
}) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Map center: ${initialCenter.latitude},${initialCenter.longitude}'),
        if (selectedPoint != null)
          Text('Selected pin: ${selectedPoint.latitude},${selectedPoint.longitude}'),
        TextButton(
          onPressed: () => onSelect(const LatLng(6.9, 122.1)),
          child: const Text('Choose sample pin'),
        ),
      ],
    ),
  );
}

void main() {
  test('delivery pin validates latitude and longitude bounds', () {
    expect(
      const DeliveryLocation(latitude: 6.9, longitude: 122.1).isValid,
      isTrue,
    );
    expect(
      const DeliveryLocation(latitude: 90.1, longitude: 122.1).isValid,
      isFalse,
    );
    expect(
      const DeliveryLocation(latitude: 6.9, longitude: 180.1).isValid,
      isFalse,
    );
  });

  testWidgets('customer can choose and return a map pin', (tester) async {
    DeliveryLocation? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selected = await Navigator.of(context).push<DeliveryLocation>(
                  MaterialPageRoute(
                    builder: (_) => LocationPickerScreen(mapBuilder: _testMap),
                  ),
                );
              },
              child: const Text('Open location picker'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open location picker'));
    await tester.pumpAndSettle();
    expect(find.textContaining('6.9214,122.079'), findsOneWidget);

    await tester.tap(find.text('Choose sample pin'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Selected pin: 6.9,122.1'), findsOneWidget);
    await tester.tap(find.text('Confirm delivery location'));
    await tester.pumpAndSettle();

    expect(selected?.latitude, 6.9);
    expect(selected?.longitude, 122.1);
  });

  testWidgets('denied location permission gives a manual pin fallback', (
    tester,
  ) async {
    final locationService = _FakeDeviceLocationService(
      failure: const LocationAccessFailure(LocationAccessIssue.denied),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LocationPickerScreen(
          locationService: locationService,
          mapBuilder: _testMap,
        ),
      ),
    );

    await tester.tap(find.text('Use current location'));
    await tester.pumpAndSettle();
    expect(find.text('Use your current location?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Location permission was denied.'),
      findsOneWidget,
    );
    expect(find.text('Choose sample pin'), findsOneWidget);
    expect(find.text('Open location settings'), findsNothing);
  });

  testWidgets('permanently denied permission can open app settings', (
    tester,
  ) async {
    final locationService = _FakeDeviceLocationService(
      failure: const LocationAccessFailure(
        LocationAccessIssue.permanentlyDenied,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LocationPickerScreen(
          locationService: locationService,
          mapBuilder: _testMap,
        ),
      ),
    );

    await tester.tap(find.text('Use current location'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Open location settings'), findsOneWidget);
    await tester.tap(find.text('Open location settings'));
    await tester.pumpAndSettle();
    expect(locationService.settingsOpened, isTrue);
  });
}
