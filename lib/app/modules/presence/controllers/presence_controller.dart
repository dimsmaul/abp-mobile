import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide Response;
import 'package:permission_handler/permission_handler.dart';

import '../../../data/services/api_service.dart';
import '../../home/controllers/home_controller.dart';

// GPS on consumer phones routinely drifts 10–30 meters even with a good fix.
// A polygon drawn tight around a small office building therefore flips
// "inside" and "outside" between consecutive position reads. We allow a
// short buffer around the polygon edge so the same user standing still
// gets a stable verdict.
const double _kPolygonToleranceMeters = 25.0;

// Reject obviously poor fixes — they make `outside` decisions unreliable.
const double _kMinAcceptableAccuracyMeters = 80.0;

enum PresenceState {
  initial,
  initializing,
  locationServiceOff,
  permissionLocationDenied,
  permissionCameraDenied,
  fetching,
  inZone,
  outOfZone,
  noOffices,
  alreadyComplete,
  error,
}

class PresenceController extends GetxController {
  final api = Get.find<ApiService>();

  final state = PresenceState.initial.obs;
  final errorMessage = ''.obs;

  final currentPosition = Rxn<Position>();
  final matchedOfficeName = Rxn<String>();

  // Decided each start() from today's attendance state. Drives the camera
  // arg passed when the user taps the action button.
  final attendanceType = Rxn<String>();

  /// Public entry — re-run the gate check. Called by the dashboard center
  /// nav button each time the user taps onto this tab. Intentionally NOT
  /// invoked from onInit so the app doesn't ask for location/camera
  /// permissions on launch.
  Future<void> start() async {
    state.value = PresenceState.initializing;
    errorMessage.value = '';
    matchedOfficeName.value = null;

    // 1. Decide attendance type from today's state.
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      final hasIn = home.checkInTime.value != null;
      final hasOut = home.checkOutTime.value != null;
      if (!hasIn) {
        attendanceType.value = 'check_in';
      } else if (!hasOut) {
        attendanceType.value = 'check_out';
      } else {
        state.value = PresenceState.alreadyComplete;
        return;
      }
    } else {
      attendanceType.value = 'check_in';
    }

    // 2. Permissions — camera + location.
    final cam = await Permission.camera.status;
    if (!cam.isGranted) {
      final ask = await Permission.camera.request();
      if (!ask.isGranted) {
        state.value = PresenceState.permissionCameraDenied;
        return;
      }
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      state.value = PresenceState.locationServiceOff;
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      state.value = PresenceState.permissionLocationDenied;
      return;
    }

    state.value = PresenceState.fetching;

    // 3. Location — take the best of up to 3 reads to dampen the very
    // first noisy fix some devices report.
    Position? pos;
    try {
      for (var i = 0; i < 3; i++) {
        final fix = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 15),
          ),
        );
        if (pos == null || fix.accuracy < pos.accuracy) {
          pos = fix;
        }
        // Once we have a fix tighter than the tolerance we don't need to
        // keep waiting.
        if (pos.accuracy <= _kPolygonToleranceMeters) break;
      }
    } catch (e) {
      errorMessage.value = 'Could not read location: $e';
      state.value = PresenceState.error;
      return;
    }
    if (pos == null) {
      errorMessage.value = 'Could not read location.';
      state.value = PresenceState.error;
      return;
    }
    currentPosition.value = pos;

    // 4. Fetch ALL offices (no city / regency filter — cross-border users
    // can still be inside a polygon defined in a different administrative
    // area than where they live).
    List<dynamic> offices;
    try {
      final res = await api.fetchOffices(limit: 200);
      final data = res.data;
      final raw = data is Map ? data['data'] : null;
      final items = raw is Map ? raw['items'] : (raw is List ? raw : null);
      offices = items is List ? items : <dynamic>[];
    } on DioException catch (e) {
      errorMessage.value = dioErrorMessage(e, 'Failed to fetch office list');
      state.value = PresenceState.error;
      return;
    }

    if (offices.isEmpty) {
      state.value = PresenceState.noOffices;
      return;
    }

    // 5. Polygon hit-test with a GPS-noise tolerance band. If the point is
    // outside the polygon but within `_kPolygonToleranceMeters` of its
    // edge, we still call it inside — otherwise a stationary user keeps
    // flipping between inZone / outOfZone as the fix drifts.
    Map<String, dynamic>? matched;
    Map<String, dynamic>? nearest;
    double nearestDist = double.infinity;

    for (final raw in offices) {
      if (raw is! Map) continue;
      final office = Map<String, dynamic>.from(raw);
      final polygon = _readPolygon(office['polygon']);
      if (polygon == null || polygon.length < 3) continue;

      if (_isPointInPolygon(pos.latitude, pos.longitude, polygon)) {
        matched = office;
        break;
      }
      final d = _distanceToPolygon(pos.latitude, pos.longitude, polygon);
      if (d < nearestDist) {
        nearestDist = d;
        nearest = office;
      }
    }

    // Soft inclusion via the tolerance band — but only when the current
    // GPS fix is reasonably accurate. A 200-meter accuracy fix near the
    // edge would otherwise leak users in from across the street.
    if (matched == null &&
        nearest != null &&
        nearestDist <= _kPolygonToleranceMeters &&
        pos.accuracy <= _kMinAcceptableAccuracyMeters) {
      matched = nearest;
    }

    if (matched != null) {
      matchedOfficeName.value = matched['name']?.toString() ?? 'Office';
      state.value = PresenceState.inZone;
    } else {
      state.value = PresenceState.outOfZone;
    }
  }

  Future<void> openSettings() => openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  void openCamera() {
    if (state.value != PresenceState.inZone) return;
    final type = attendanceType.value;
    if (type == null) return;
    Get.toNamed('/camera', arguments: {
      'requireFace': true,
      'attendanceType': type,
    });
  }

  // --- Geometry helpers ----------------------------------------------------

  List<List<double>>? _readPolygon(dynamic raw) {
    if (raw == null) return null;
    dynamic parsed = raw;
    if (raw is String) {
      try {
        parsed = jsonDecode(raw);
      } catch (_) {
        return null;
      }
    }
    if (parsed is! List) return null;
    final out = <List<double>>[];
    for (final p in parsed) {
      if (p is! List || p.length < 2) return null;
      // Backend stores polygons GeoJSON-style: [lng, lat]. See
      // backend/src/lib/geofence.ts:34. Swap to our internal [lat, lng]
      // shape so the downstream hit-test treats poly[i][0] as latitude.
      final lng = (p[0] as num?)?.toDouble();
      final lat = (p[1] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      out.add([lat, lng]);
    }
    return out;
  }

  /// Ray-casting point-in-polygon. Polygon is a list of [lat, lng] pairs.
  bool _isPointInPolygon(double lat, double lng, List<List<double>> poly) {
    var inside = false;
    final n = poly.length;
    for (var i = 0, j = n - 1; i < n; j = i++) {
      final yi = poly[i][0], xi = poly[i][1];
      final yj = poly[j][0], xj = poly[j][1];
      final denom = (yj - yi) == 0 ? 1e-12 : (yj - yi);
      final intersect = ((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / denom + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  /// Min great-circle distance from the point to any polygon vertex.
  /// Approximation good enough as a "how far am I from the office?" hint
  /// when deciding whether to soft-include via the tolerance band.
  double _distanceToPolygon(
    double lat,
    double lng,
    List<List<double>> poly,
  ) {
    var min = double.infinity;
    for (final v in poly) {
      final d = _haversineMeters(lat, lng, v[0], v[1]);
      if (d < min) min = d;
    }
    return min;
  }

  double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * math.pi / 180.0;
}
