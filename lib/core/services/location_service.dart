import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final GeolocatorPlatform _geolocator = GeolocatorPlatform.instance;

  Future<LocationPermissionStatus> checkPermissionStatus() async {
    try {
      final permission = await Permission.location.status;
      
      if (permission.isGranted) {
        return LocationPermissionStatus.granted;
      } else if (permission.isDenied) {
        return LocationPermissionStatus.denied;
      } else if (permission.isPermanentlyDenied) {
        return LocationPermissionStatus.permanentlyDenied;
      } else if (permission.isRestricted) {
        return LocationPermissionStatus.restricted;
      }
      
      return LocationPermissionStatus.unknown;
    } catch (e) {
      print('خطأ في التحقق من صلاحيات الموقع: $e');
      return LocationPermissionStatus.unknown;
    }
  }

  Future<LocationPermissionStatus> requestPermission() async {
    try {
      final permission = await Permission.location.request();
      
      if (permission.isGranted) {
        return LocationPermissionStatus.granted;
      } else if (permission.isDenied) {
        return LocationPermissionStatus.denied;
      } else if (permission.isPermanentlyDenied) {
        return LocationPermissionStatus.permanentlyDenied;
      } else if (permission.isRestricted) {
        return LocationPermissionStatus.restricted;
      }
      
      return LocationPermissionStatus.unknown;
    } catch (e) {
      print('خطأ في طلب صلاحيات الموقع: $e');
      return LocationPermissionStatus.unknown;
    }
  }

  Future<LocationData?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) async {
    try {
      final permissionStatus = await checkPermissionStatus();
      if (permissionStatus != LocationPermissionStatus.granted) {
        return null;
      }

      final serviceEnabled = await _geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      final position = await _geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: accuracy),
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (e) {
      print('خطأ في الحصول على الموقع: $e');
      return null;
    }
  }

  Future<void> openLocationSettings() async {
    await openAppSettings();
  }
}

enum LocationPermissionStatus {
  granted, denied, permanentlyDenied, restricted, unknown
}

class LocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime? timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp?.millisecondsSinceEpoch,
    };
  }
}