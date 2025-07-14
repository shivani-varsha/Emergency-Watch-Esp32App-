import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  Location location = Location();

  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  LocationData? _locationData;

  Future<bool> checkService() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
    }
    return _serviceEnabled;
  }

  Future<bool> requestPermission() async {
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
    }
    return _permissionGranted == PermissionStatus.granted;
  }

  Future<LocationData?> getLocation() async {
    _locationData = await location.getLocation();
    return _locationData;
  }

  Future<LatLng?> getCurrentLocation() async {
    if (await checkService() && await requestPermission()) {
      _locationData = await getLocation();
      if (_locationData != null) {
        return LatLng(_locationData!.latitude!, _locationData!.longitude!);
      }
    }
    return null;
  }
}