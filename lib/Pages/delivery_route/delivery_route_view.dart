import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Constants/constants.dart';

/// A self-contained map view that shows the full delivery trip for one order:
///   driver (you)  ──►  restaurant (pickup)  ──►  customer (drop-off)
///
/// It draws the real driving route on the roads using the free OSRM routing
/// service (no API key / billing needed), and falls back to straight lines if
/// routing is unavailable. It also offers turn-by-turn navigation by handing
/// off to the Google Maps app, plus call / WhatsApp shortcuts.
///
/// This widget has NO Scaffold so it can be embedded inside a tab. For a
/// full-screen experience use [DeliveryRouteScreen] below.
class DeliveryRouteView extends StatefulWidget {
  final String orderNumber;

  final String restaurantName;
  final String restaurantPhone;
  final String restaurantAddress;
  final double? restaurantLat;
  final double? restaurantLng;

  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final double? customerLat;
  final double? customerLng;

  /// Shows a "full screen" button (only useful when embedded inside a tab).
  final bool showExpandButton;

  const DeliveryRouteView({
    Key? key,
    this.orderNumber = "",
    this.restaurantName = "",
    this.restaurantPhone = "",
    this.restaurantAddress = "",
    this.restaurantLat,
    this.restaurantLng,
    this.customerName = "",
    this.customerPhone = "",
    this.customerAddress = "",
    this.customerLat,
    this.customerLng,
    this.showExpandButton = true,
  }) : super(key: key);

  @override
  State<DeliveryRouteView> createState() => _DeliveryRouteViewState();
}

class _DeliveryRouteViewState extends State<DeliveryRouteView> {
  GoogleMapController? _map;
  LatLng? _me; // driver live location

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Per-leg distance (km) / duration (min). Null while loading / unavailable.
  double? _legToRestaurantKm;
  double? _legToRestaurantMin;
  double? _legToCustomerKm;
  double? _legToCustomerMin;

  bool _loading = true;

  static const Color _orange = Color(0xFFF57C00); // pickup leg / restaurant
  static const Color _green = Color(0xFF2E7D32); // delivery leg / customer
  static const Color _blue = Color(0xFF1565C0); // driver

  LatLng? get _restaurant => _validLatLng(widget.restaurantLat, widget.restaurantLng);
  LatLng? get _customer => _validLatLng(widget.customerLat, widget.customerLng);

  static LatLng? _validLatLng(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (lat == 0 && lng == 0) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return LatLng(lat, lng);
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _getMyLocation();
    _buildMarkers();
    await _buildRoutes();
    if (mounted) setState(() => _loading = false);
    _fitBounds();
  }

  Future<void> _getMyLocation() async {
    try {
      final location = Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
      }
      PermissionStatus permission = await location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
      }
      if (permission == PermissionStatus.granted ||
          permission == PermissionStatus.grantedLimited) {
        final loc = await location.getLocation();
        if (loc.latitude != null && loc.longitude != null) {
          _me = LatLng(loc.latitude!, loc.longitude!);
        }
      }
    } catch (_) {
      _me = null;
    }
  }

  void _buildMarkers() {
    _markers.clear();
    if (_me != null) {
      _markers.add(Marker(
        markerId: const MarkerId("me"),
        position: _me!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: "موقعك الحالي"),
      ));
    }
    if (_restaurant != null) {
      _markers.add(Marker(
        markerId: const MarkerId("restaurant"),
        position: _restaurant!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: "المطعم: ${widget.restaurantName}",
          snippet: widget.restaurantAddress,
        ),
      ));
    }
    if (_customer != null) {
      _markers.add(Marker(
        markerId: const MarkerId("customer"),
        position: _customer!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: "الزبون: ${widget.customerName}",
          snippet: widget.customerAddress,
        ),
      ));
    }
  }

  Future<void> _buildRoutes() async {
    _polylines.clear();

    // Leg 1: driver -> restaurant (pickup)
    if (_me != null && _restaurant != null) {
      final r = await _fetchRoute(_me!, _restaurant!);
      _polylines.add(Polyline(
        polylineId: const PolylineId("toRestaurant"),
        color: _orange,
        width: 6,
        points: r?.points ?? [_me!, _restaurant!],
        patterns: r == null
            ? [PatternItem.dash(20), PatternItem.gap(10)]
            : const [],
      ));
      _legToRestaurantKm = r?.km;
      _legToRestaurantMin = r?.min;
    }

    // Leg 2: restaurant -> customer (delivery)
    if (_restaurant != null && _customer != null) {
      final r = await _fetchRoute(_restaurant!, _customer!);
      _polylines.add(Polyline(
        polylineId: const PolylineId("toCustomer"),
        color: _green,
        width: 6,
        points: r?.points ?? [_restaurant!, _customer!],
        patterns: r == null
            ? [PatternItem.dash(20), PatternItem.gap(10)]
            : const [],
      ));
      _legToCustomerKm = r?.km;
      _legToCustomerMin = r?.min;
    } else if (_me != null && _customer != null && _restaurant == null) {
      // No restaurant coords -> at least show the route to the customer.
      final r = await _fetchRoute(_me!, _customer!);
      _polylines.add(Polyline(
        polylineId: const PolylineId("toCustomer"),
        color: _green,
        width: 6,
        points: r?.points ?? [_me!, _customer!],
        patterns: r == null
            ? [PatternItem.dash(20), PatternItem.gap(10)]
            : const [],
      ));
      _legToCustomerKm = r?.km;
      _legToCustomerMin = r?.min;
    }
  }

  /// Calls the free OSRM demo server for a driving route. Returns null on any
  /// failure so the caller can fall back to a straight dashed line.
  Future<_RouteResult?> _fetchRoute(LatLng from, LatLng to) async {
    try {
      final url = Uri.parse(
          "https://router.project-osrm.org/route/v1/driving/"
          "${from.longitude},${from.latitude};${to.longitude},${to.latitude}"
          "?overview=full&geometries=polyline");
      final res = await http
          .get(url)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data["code"] != "Ok" ||
          data["routes"] == null ||
          (data["routes"] as List).isEmpty) {
        return null;
      }
      final route = data["routes"][0];
      final points = _decodePolyline(route["geometry"] as String);
      final meters = (route["distance"] as num).toDouble();
      final seconds = (route["duration"] as num).toDouble();
      return _RouteResult(
        points: points,
        km: meters / 1000.0,
        min: seconds / 60.0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Standard Google/OSRM encoded-polyline decoder (precision 5).
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  Future<void> _fitBounds() async {
    if (_map == null) return;
    final pts = <LatLng>[
      if (_me != null) _me!,
      if (_restaurant != null) _restaurant!,
      if (_customer != null) _customer!,
    ];
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      await _map!.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 15));
      return;
    }
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    // Give the map a moment to be ready before animating.
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      await _map!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
    } catch (_) {}
  }

  // ── Actions ────────────────────────────────────────────────────────────

  void _openFullScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DeliveryRouteScreen(
        orderNumber: widget.orderNumber,
        restaurantName: widget.restaurantName,
        restaurantPhone: widget.restaurantPhone,
        restaurantAddress: widget.restaurantAddress,
        restaurantLat: widget.restaurantLat,
        restaurantLng: widget.restaurantLng,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        customerAddress: widget.customerAddress,
        customerLat: widget.customerLat,
        customerLng: widget.customerLng,
      ),
    ));
  }

  Future<void> _navigateTo(LatLng dest, String label) async {
    final url = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=${dest.latitude},${dest.longitude}&travelmode=driving");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      Fluttertoast.showToast(msg: "تعذّر فتح خرائط جوجل");
    }
  }

  Future<void> _call(String phone) async {
    if (phone.trim().isEmpty) {
      Fluttertoast.showToast(msg: "لا يوجد رقم هاتف");
      return;
    }
    try {
      await launchUrl(Uri.parse("tel:$phone"));
    } catch (_) {
      Fluttertoast.showToast(msg: "تعذّر إجراء المكالمة");
    }
  }

  Future<void> _whatsapp(String phone) async {
    if (phone.trim().isEmpty) {
      Fluttertoast.showToast(msg: "لا يوجد رقم هاتف");
      return;
    }
    final contact = phone.startsWith("0") ? "+972${phone.substring(1)}" : phone;
    final url = Uri.parse("https://wa.me/${contact.replaceAll('+', '')}");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      Fluttertoast.showToast(msg: "تعذّر فتح واتساب");
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final LatLng initialTarget =
        _restaurant ?? _customer ?? _me ?? const LatLng(31.9522, 35.2332);
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: initialTarget, zoom: 12),
          onMapCreated: (c) {
            _map = c;
            _fitBounds();
          },
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
        if (_loading)
          const Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(child: _LoadingChip()),
          ),
        // Re-center + full-screen buttons
        Positioned(
          right: 12,
          top: 12,
          child: Column(
            children: [
              _RoundBtn(
                icon: Icons.center_focus_strong,
                onTap: _fitBounds,
              ),
              if (widget.showExpandButton) ...[
                const SizedBox(height: 10),
                _RoundBtn(
                  icon: Icons.fullscreen,
                  onTap: _openFullScreen,
                ),
              ],
            ],
          ),
        ),
        _buildBottomPanel(),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return DraggableScrollableSheet(
      initialChildSize: 0.34,
      minChildSize: 0.16,
      maxChildSize: 0.85,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
            ],
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              _tripHeader(),
              const SizedBox(height: 14),
              _timeline(),
              const SizedBox(height: 16),
              _stepCard(
                step: "١",
                accent: _orange,
                icon: Icons.storefront,
                title: "استلام الطلب من المطعم",
                name: widget.restaurantName,
                address: widget.restaurantAddress,
                km: _legToRestaurantKm,
                min: _legToRestaurantMin,
                dest: _restaurant,
                phone: widget.restaurantPhone,
              ),
              const SizedBox(height: 12),
              _stepCard(
                step: "٢",
                accent: _green,
                icon: Icons.home_rounded,
                title: "توصيل الطلب للزبون",
                name: widget.customerName,
                address: widget.customerAddress,
                km: _legToCustomerKm,
                min: _legToCustomerMin,
                dest: _customer,
                phone: widget.customerPhone,
              ),
              const SizedBox(height: 16),
              _howToUse(),
            ],
          ),
        );
      },
    );
  }

  Widget _tripHeader() {
    final totalKm = (_legToRestaurantKm ?? 0) + (_legToCustomerKm ?? 0);
    final totalMin = (_legToRestaurantMin ?? 0) + (_legToCustomerMin ?? 0);
    final hasTotals = totalKm > 0;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: MAINCOLOR.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delivery_dining, color: MAINCOLOR, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.orderNumber.isEmpty
                    ? "رحلة التوصيل"
                    : "رحلة التوصيل • طلب #${widget.orderNumber}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                hasTotals
                    ? "إجمالي المسافة ${totalKm.toStringAsFixed(1)} كم • حوالي ${totalMin.round()} دقيقة"
                    : "اسحب للأعلى لرؤية تفاصيل الرحلة",
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Simple, smooth visual explanation of the trip order:
  /// you → restaurant → customer.
  Widget _timeline() {
    Widget dot(Color c, IconData ic, String label) => Column(
          children: [
            CircleAvatar(radius: 16, backgroundColor: c, child: Icon(ic, size: 18, color: Colors.white)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
        );
    Widget line(Color c) => Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.only(bottom: 18),
            color: c,
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          dot(_blue, Icons.my_location, "أنت"),
          line(_orange),
          dot(_orange, Icons.storefront, "المطعم"),
          line(_green),
          dot(_green, Icons.home_rounded, "الزبون"),
        ],
      ),
    );
  }

  Widget _stepCard({
    required String step,
    required Color accent,
    required IconData icon,
    required String title,
    required String name,
    required String address,
    required double? km,
    required double? min,
    required LatLng? dest,
    required String phone,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: accent,
                child: Text(step,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.bold)),
              ),
              if (km != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${km.toStringAsFixed(1)} كم • ${(min ?? 0).round()} د",
                    style: TextStyle(
                        color: accent, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (name.trim().isNotEmpty)
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(child: Text(name, style: const TextStyle(fontSize: 13.5))),
              ],
            ),
          if (address.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(address,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _actionBtn(
                  label: "الملاحة",
                  icon: Icons.navigation,
                  color: accent,
                  filled: true,
                  onTap: dest == null
                      ? null
                      : () => _navigateTo(dest, title),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionBtn(
                  label: "اتصال",
                  icon: Icons.call,
                  color: const Color(0xFF1565C0),
                  onTap: () => _call(phone),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionBtn(
                  label: "واتساب",
                  icon: Icons.chat,
                  color: const Color(0xFF25D366),
                  onTap: () => _whatsapp(phone),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    bool filled = false,
    VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: filled ? color : color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: filled ? null : Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: filled ? Colors.white : color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: filled ? Colors.white : color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _howToUse() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: Icon(Icons.help_outline, color: MAINCOLOR),
        title: const Text("كيف أستخدم الخريطة؟",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        children: const [
          _Bullet(color: _orange, text: "الخط البرتقالي = طريقك من موقعك إلى المطعم لاستلام الطلب."),
          _Bullet(color: _green, text: "الخط الأخضر = طريقك من المطعم إلى الزبون لتسليم الطلب."),
          _Bullet(color: _blue, text: "النقطة الزرقاء = موقعك الحالي ويتحرك معك."),
          _Bullet(color: Colors.black54, text: "اضغط زر «الملاحة» لفتح خرائط جوجل والتوجيه صوتياً خطوة بخطوة."),
          _Bullet(color: Colors.black54, text: "أزرار «اتصال» و«واتساب» للتواصل مع المطعم أو الزبون مباشرة."),
        ],
      ),
    );
  }
}

class _RouteResult {
  final List<LatLng> points;
  final double km;
  final double min;
  _RouteResult({required this.points, required this.km, required this.min});
}

class _Bullet extends StatelessWidget {
  final Color color;
  final String text;
  const _Bullet({Key? key, required this.color, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12.8, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _LoadingChip extends StatelessWidget {
  const _LoadingChip({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: MAINCOLOR),
          ),
          const SizedBox(width: 10),
          const Text("جاري تجهيز الطريق...", style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({Key? key, required this.icon, required this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: MAINCOLOR, size: 22),
        ),
      ),
    );
  }
}

/// Full-screen version of the delivery route map (with an app bar).
class DeliveryRouteScreen extends StatelessWidget {
  final String orderNumber;
  final String restaurantName;
  final String restaurantPhone;
  final String restaurantAddress;
  final double? restaurantLat;
  final double? restaurantLng;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final double? customerLat;
  final double? customerLng;

  const DeliveryRouteScreen({
    Key? key,
    this.orderNumber = "",
    this.restaurantName = "",
    this.restaurantPhone = "",
    this.restaurantAddress = "",
    this.restaurantLat,
    this.restaurantLng,
    this.customerName = "",
    this.customerPhone = "",
    this.customerAddress = "",
    this.customerLat,
    this.customerLng,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: MAINCOLOR,
          foregroundColor: Colors.white,
          title: const Text("الطريق إلى المطعم والزبون"),
          centerTitle: true,
        ),
        body: DeliveryRouteView(
          orderNumber: orderNumber,
          restaurantName: restaurantName,
          restaurantPhone: restaurantPhone,
          restaurantAddress: restaurantAddress,
          restaurantLat: restaurantLat,
          restaurantLng: restaurantLng,
          customerName: customerName,
          customerPhone: customerPhone,
          customerAddress: customerAddress,
          customerLat: customerLat,
          customerLng: customerLng,
          showExpandButton: false,
        ),
      ),
    );
  }
}
