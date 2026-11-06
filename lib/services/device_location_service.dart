import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/delivery_location.dart';

enum LocationAccessIssue { denied, permanentlyDenied, servicesDisabled }

class LocationAccessFailure implements Exception {
  const LocationAccessFailure(this.issue);

  final LocationAccessIssue issue;
}

abstract interface class DeviceLocationService {
  Future<DeliveryLocation> getCurrentLocation();

  Future<bool> openAppSettings();
}

class GeolocatorDeviceLocationService implements DeviceLocationService {
  @override
  Future<DeliveryLocation> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationAccessFailure(
        LocationAccessIssue.servicesDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationAccessFailure(
        LocationAccessIssue.permanentlyDenied,
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationAccessFailure(LocationAccessIssue.denied);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return DeliveryLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on TimeoutException {
      rethrow;
    } on LocationServiceDisabledException {
      throw const LocationAccessFailure(
        LocationAccessIssue.servicesDisabled,
      );
    } on PermissionDeniedException {
      throw const LocationAccessFailure(LocationAccessIssue.denied);
    }
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
