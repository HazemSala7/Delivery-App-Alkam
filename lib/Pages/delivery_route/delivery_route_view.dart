// NOTE: google_maps_flutter and location are disabled in this build (see the
// commented-out deps in pubspec.yaml) to keep the iOS build working. These are
// placeholder widgets that preserve the original public API (constructors) so
// call sites keep compiling. Restore the real map-based implementation (see git
// history of commit a852849 "fix some issues") when bringing the map back.
import 'package:flutter/material.dart';

class DeliveryRouteView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return const _RouteDisabledPlaceholder();
  }
}

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
          title: const Text("الطريق إلى المطعم والزبون"),
          centerTitle: true,
        ),
        body: const _RouteDisabledPlaceholder(),
      ),
    );
  }
}

class _RouteDisabledPlaceholder extends StatelessWidget {
  const _RouteDisabledPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              "الخريطة غير متاحة حالياً",
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
