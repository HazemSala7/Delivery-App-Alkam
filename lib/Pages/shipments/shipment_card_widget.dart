import 'dart:async';
import 'package:flutter/material.dart';
import 'package:optimus_opost/Pages/shipment_detail/shipment_detail.dart';
import 'package:optimus_opost/Pages/delivery_route/delivery_route_view.dart';
import 'package:optimus_opost/Pages/shipments/preparation_time/preparation_time.dart';
import 'package:optimus_opost/Pages/shipments/shipments.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimus_opost/l10n/app_localizations.dart';

class ShipmentCardWidget extends StatefulWidget {
  final String trackingNumber;
  final String lattitude;
  final String longitude;
  final String businessName;
  final String businessPhone;
  final String consigneeName;
  final String consigneePhone1;
  final String consigneePhone2;
  final String status;
  final String itemsDescription;
  final double codAmount;
  final String type;
  final String from;
  final String to;
  final dynamic productsArray;
  final int quantity;
  final int id;
  final int userId;
  final String createdAt;
  final String updatedAt;
  final String resturantAdress;
  final String customerAdress;
  final String customerNear;
  final bool newOrder;
  final Map<String, dynamic> shipment;
  final List<dynamic> newShipmentsQueue;
  final Map<String, bool> showDeliveryButtonForShipment;
  final Map<String, int> remainingSecondsForShipment;
  final Map<String, Timer> autoDismissTimers;
  final dynamic activeShipments;
  final Future<void> Function(String shipmentId) confirmShipment;
  final Future<void> Function(
          String tracking, String newStatus, int userId, String message)
      changeOrderStatus;
  final void Function(String shipmentId)? onAutoDismissCleanup;
  final void Function(String shipmentId, Map<String, dynamic> shipment)?
      onConfirmCompleted;
  final Color mainColor;

  const ShipmentCardWidget({
    Key? key,
    this.trackingNumber = "",
    this.lattitude = "",
    this.longitude = "",
    this.businessName = "",
    this.businessPhone = "",
    this.consigneeName = "",
    this.consigneePhone1 = "",
    this.consigneePhone2 = "",
    this.status = "",
    this.itemsDescription = "",
    this.codAmount = 0.0,
    this.type = "",
    this.from = "",
    this.to = "",
    this.productsArray,
    this.quantity = 0,
    this.id = 0,
    this.userId = 0,
    this.createdAt = "",
    this.updatedAt = "",
    this.resturantAdress = "",
    this.customerAdress = "",
    this.customerNear = "",
    this.newOrder = false,
    required this.shipment,
    required this.newShipmentsQueue,
    required this.showDeliveryButtonForShipment,
    required this.remainingSecondsForShipment,
    required this.autoDismissTimers,
    required this.activeShipments,
    required this.confirmShipment,
    required this.changeOrderStatus,
    this.onAutoDismissCleanup,
    this.onConfirmCompleted,
    required this.mainColor,
  }) : super(key: key);

  @override
  State<ShipmentCardWidget> createState() => _ShipmentCardWidgetState();
}

class _ShipmentCardWidgetState extends State<ShipmentCardWidget> {
  // Helper getters replicate the original local variables/logic
  String get _shipmentIdStr =>
      widget.shipment["id"]?.toString() ?? widget.id.toString();

  String get _localStatus =>
      widget.shipment["status"]?.toString() ?? widget.status;

  String get _localTracking =>
      widget.shipment["id"]?.toString() ?? widget.trackingNumber;

  // المجموع الكلي = مجموع المنتجات + سعر التوصيل + سعر الخدمة (من النظام).
  double get _localCod => _total + _deliveryPrice + _servicePrice;

  double get _total {
    final parsed = double.tryParse(
        widget.shipment["total"]?.toString() ?? widget.codAmount.toString())!;
    return parsed;
  }

  double get _deliveryPrice {
    final parsed = double.tryParse(
        widget.shipment["restaurant"]?["delivery_price"]?.toString() ?? "0");
    return parsed ?? 0.0;
  }

  // سعر الخدمة الموجود بالنظام (يُضاف إلى المجموع).
  double get _servicePrice {
    final parsed =
        double.tryParse(widget.shipment["service_price"]?.toString() ?? "0");
    return parsed ?? 0.0;
  }

  bool get _isNewOrder =>
      widget.newOrder &&
      widget.newShipmentsQueue.any((s) => s["id"].toString() == _shipmentIdStr);

  bool get _showDeliveryButton =>
      widget.showDeliveryButtonForShipment[_shipmentIdStr] ?? !_isNewOrder;

  int get _remainingSeconds =>
      widget.remainingSecondsForShipment[_shipmentIdStr] ?? 20;

  bool isProcessing = false;
  bool _isConfirmingNewOrder = false;
  bool get _activeShipmentsIsEmpty {
    final active = widget.activeShipments;
    if (active is Iterable) return (active as Iterable).isEmpty;
    if (active is Map) return (active as Map).isEmpty;
    return active == {};
  }

  @override
  void dispose() {
    super.dispose();
  }

  Color _statusColor() {
    switch (_localStatus) {
      case "delivered":
        return const Color(0xFF27AE60);
      case "in_delivery":
        return const Color(0xFF2980B9);
      case "in_progress":
      case "ready_for_delivery":
        return const Color(0xFFE67E22);
      case "canceled":
      case "returned":
        return const Color(0xFFC0392B);
      case "pending":
        return const Color(0xFF7F8C8D);
      default:
        return widget.mainColor;
    }
  }

  String _statusLabel() {
    switch (_localStatus) {
      case "delivered":
        return "تم التسليم";
      case "in_delivery":
        return "قيد التوصيل";
      case "in_progress":
        return "قيد التحضير";
      case "ready_for_delivery":
        return "جاهز للتوصيل";
      case "canceled":
        return "ملغي";
      case "returned":
        return "مرتجع";
      case "pending":
        return "بانتظار التأكيد";
      default:
        return _localStatus.isEmpty ? "-" : _localStatus;
    }
  }

  Widget _buildHeader(BuildContext context) {
    final visiblePreparationContainer = _localStatus != "in_delivery";
    final statusColor = _statusColor();
    final isLoad = widget.type.toString() == "load";
    final typeColor =
        isLoad ? const Color(0xFFC0392B) : const Color(0xFF27AE60);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                        color: typeColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        isLoad
                            ? Icons.upload_rounded
                            : Icons.inventory_2_rounded,
                        color: Colors.white,
                        size: 13),
                    const SizedBox(width: 4),
                    Text(isLoad ? "تحميل" : "استلام",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status chip
              if (!_isNewOrder)
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(_statusLabel(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor)),
                        ),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              // Tracking number
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.mainColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.confirmation_number_rounded,
                        color: widget.mainColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "#$_localTracking",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: widget.mainColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (visiblePreparationContainer &&
              (_isNewOrder || _localStatus == "in_progress"))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _isNewOrder
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F0),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.3)),
                            ),
                            child: TweenAnimationBuilder<Duration>(
                              duration: Duration(seconds: _remainingSeconds),
                              tween: Tween(
                                  begin: Duration(seconds: _remainingSeconds),
                                  end: Duration.zero),
                              builder: (context, value, child) {
                                final seconds = value.inSeconds;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.timer_outlined,
                                        size: 14, color: Colors.red),
                                    const SizedBox(width: 6),
                                    Text(
                                        'سيتم الإلغاء خلال $seconds ثانية',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.red)),
                                  ],
                                );
                              },
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFE67E22)
                                      .withOpacity(0.3)),
                            ),
                            child: PreparationTimer(
                              startAt: widget
                                          .shipment["preparation_started_at"] !=
                                      null
                                  ? DateTime.parse(widget
                                      .shipment["preparation_started_at"])
                                  : DateTime.now(),
                              preparationTime:
                                  widget.shipment["preparation_time"] ?? 0,
                            ),
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressRow({required bool isFrom}) {
    // Kept for backwards compatibility; no longer used in build().
    return const SizedBox.shrink();
  }

  Widget _buildRoute() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connected dots + vertical line
            SizedBox(
              width: 18,
              child: Column(
                children: [
                  // From (hollow)
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.mainColor, width: 2),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: widget.mainColor.withOpacity(0.35),
                    ),
                  ),
                  // To (filled)
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: widget.mainColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _routeRow(
                    label: AppLocalizations.of(context)!.from,
                    value: widget.from,
                  ),
                  const SizedBox(height: 6),
                  _routeRow(
                    label: AppLocalizations.of(context)!.to,
                    value: widget.to,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeRow({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF95A5A6),
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 1),
        Text(
          value.isEmpty ? "-" : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 5.0;
          const dashSpace = 4.0;
          final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
          return Row(
            mainAxisSize: MainAxisSize.max,
            children: List.generate(
              count,
              (_) => Container(
                width: dashWidth,
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: dashSpace / 2),
                color: const Color(0xFFE4E3E3),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentRow(BuildContext context) {
    String paymentLabel;
    if (_localStatus == "delivered") {
      paymentLabel = "تم استلام المبلغ";
    } else if (_localStatus == "ready_for_delivery" ||
        _localStatus == "in_progress") {
      paymentLabel = "ادفع للمطعم";
    } else if (_localStatus == "in_delivery") {
      paymentLabel = "الزبون يجب ان يدفع";
    } else {
      paymentLabel = "";
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.payments_rounded,
                      color: Color(0xFFE67E22), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (paymentLabel.isNotEmpty)
                        Text(paymentLabel,
                            style: const TextStyle(
                                color: Color(0xff7F8C8D),
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      Text(
                          "$_localCod ${AppLocalizations.of(context)!.shekels}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF2C3E50))),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            if (!_isNewOrder) ...[
              _buildRouteButton(context),
              const SizedBox(width: 8),
            ],
            _buildConfirmOrDetailsButton(context),
          ]),
    );
  }

  Widget _buildRouteButton(BuildContext context) {
    return InkWell(
      onTap: () => _openRouteScreen(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: widget.mainColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_rounded, size: 18, color: Colors.white),
            SizedBox(width: 6),
            Text("الطريق",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _openRouteScreen(BuildContext context) {
    double? parse(dynamic v) => double.tryParse(v?.toString() ?? "");
    final restaurant = widget.shipment["restaurant"];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryRouteScreen(
          orderNumber: widget.trackingNumber,
          restaurantName: widget.businessName,
          restaurantPhone: widget.businessPhone,
          restaurantAddress: widget.resturantAdress,
          restaurantLat: parse(restaurant?["lattitude"]),
          restaurantLng: parse(restaurant?["longitude"]),
          customerName: widget.consigneeName,
          customerPhone: widget.consigneePhone1,
          customerAddress: [widget.customerAdress, widget.customerNear]
              .where((e) => e.trim().isNotEmpty)
              .join(" - "),
          customerLat: parse(widget.lattitude),
          customerLng: parse(widget.longitude),
        ),
      ),
    );
  }

  Widget _buildConfirmOrDetailsButton(BuildContext context) {
    return InkWell(
      onTap: _isConfirmingNewOrder
          ? null
          : () async {
              if (_isNewOrder) {
                setState(() => _isConfirmingNewOrder = true);
                try {
                  // Confirm new order flow
                  widget.autoDismissTimers[_shipmentIdStr]?.cancel();
                  await widget.confirmShipment(_shipmentIdStr);

                  // safety: after awaiting, widget might be gone
                  if (!mounted) return;

                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setString('activeShipmentId', _shipmentIdStr);

                  if (widget.onConfirmCompleted != null) {
                    if (mounted) setState(() => _isConfirmingNewOrder = false);
                    widget.onConfirmCompleted!(_shipmentIdStr,
                        Map<String, dynamic>.from(widget.shipment));
                    return;
                  }

                  // If parent didn't provide a handler, update the lists that were passed in (best-effort)
                  if (!mounted) return;
                  setState(() {
                    if (widget.activeShipments is List) {
                      final existingIndex = (widget.activeShipments as List)
                          .indexWhere(
                              (s) => s["id"].toString() == _shipmentIdStr);
                      if (existingIndex != -1) {
                        (widget.activeShipments as List)[existingIndex] =
                            Map<String, dynamic>.from(widget.shipment);
                      } else {
                        (widget.activeShipments as List)
                            .add(Map<String, dynamic>.from(widget.shipment));
                      }
                    }
                    widget.newShipmentsQueue.removeWhere(
                        (s) => s["id"].toString() == _shipmentIdStr);
                    widget.autoDismissTimers[_shipmentIdStr]?.cancel();
                    widget.autoDismissTimers.remove(_shipmentIdStr);
                  });
                } catch (e) {
                  Fluttertoast.showToast(
                      msg: 'حدث خطأ، يرجى المحاولة مرة أخرى',
                      backgroundColor: Colors.red,
                      textColor: Colors.white);
                } finally {
                  if (mounted) setState(() => _isConfirmingNewOrder = false);
                }
              } else {
                // open product details sheet
                if (!mounted) return;
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  builder: (context) {
                    return FractionallySizedBox(
                      heightFactor: 0.85,
                      child: ProductDetailsBottomSheet(
                        total: _localCod.toString(),
                        productsArray: widget.productsArray['items'] ?? [],
                        deliveryPrice: _deliveryPrice,
                        mealsPrice: _total,
                        servicePrice: _servicePrice,
                      ),
                    );
                  },
                );
              }
            },
      child: Container(
        decoration: BoxDecoration(
          gradient: _isNewOrder
              ? LinearGradient(
                  colors: [
                    widget.mainColor,
                    Color.lerp(widget.mainColor, Colors.black, 0.25) ??
                        widget.mainColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _isNewOrder ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: _isNewOrder
              ? null
              : Border.all(color: widget.mainColor, width: 1.4),
          boxShadow: _isNewOrder
              ? [
                  BoxShadow(
                    color: widget.mainColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isNewOrder
                  ? (_isConfirmingNewOrder
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.check_circle_outline,
                              size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text("تأكيد الطلب",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ]))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(AppLocalizations.of(context)!.shipment_details,
                          style: TextStyle(
                              color: widget.mainColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_back_ios_new_rounded,
                          size: 14, color: widget.mainColor),
                    ]),
            ]),
      ),
    );
  }

  Widget _buildDeliveryButton() {
    final hideDeliveryButton = _localStatus == "delivered" ||
        _localStatus == "canceled" ||
        _localStatus == "pending" ||
        _localStatus == "returned" ||
        _activeShipmentsIsEmpty;

    if (hideDeliveryButton) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        height: 40,
        child: Row(children: [
          Expanded(
            flex: 1,
            child: InkWell(
              onTap: _showDeliveryButton
                  ? () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext dialogContext) {
                          bool isConfirmLoading = false;
                          final isPreparationStage =
                              _localStatus == "ready_for_delivery" ||
                                  _localStatus == "in_progress";
                          return StatefulBuilder(
                            builder: (context, setDialogState) {
                              return AlertDialog(
                                content: Text(
                                    isPreparationStage
                                        ? "الرجاء التاكد من المكونات والمشروبات قبل استلام الطلب"
                                        : "هل تريد تأكيد تسليم الطلب ؟ ",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                actions: <Widget>[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      InkWell(
                                        onTap: () async {
                                          if (isConfirmLoading) return;
                                          setDialogState(
                                              () => isConfirmLoading = true);

                                          // show a blocking loading dialog on top
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (BuildContext
                                                loadingDialogContext) {
                                              return WillPopScope(
                                                onWillPop: () async => false,
                                                child: AlertDialog(
                                                  content: Row(
                                                    children: const [
                                                      SizedBox(
                                                          height: 24,
                                                          width: 24,
                                                          child:
                                                              CircularProgressIndicator()),
                                                      SizedBox(width: 16),
                                                      Expanded(
                                                          child: Text(
                                                              'جاري المعالجة...'))
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );

                                          try {
                                            if (isPreparationStage) {
                                              await widget.changeOrderStatus(
                                                  _localTracking,
                                                  "in_delivery",
                                                  widget.userId,
                                                  'طلبك الان اصبح قيد التوصيل');

                                              // close loading dialog first, then the confirmation
                                              Navigator.of(dialogContext)
                                                  .pop(); // pops loading dialog
                                              Navigator.of(dialogContext)
                                                  .pop(); // pops confirmation

                                              if (!mounted) return;
                                              Fluttertoast.showToast(
                                                  msg:
                                                      "لقد تم تأكيد استلام الطلب من المطعم",
                                                  backgroundColor: Colors.green,
                                                  textColor: Colors.white);
                                            } else {
                                              await widget.changeOrderStatus(
                                                  _localTracking,
                                                  "delivered",
                                                  widget.userId,
                                                  'تم تسليم طلبك');

                                              Navigator.of(dialogContext)
                                                  .pop(); // pops loading dialog
                                              Navigator.of(dialogContext)
                                                  .pop(); // pops confirmation

                                              if (!mounted) return;
                                              Fluttertoast.showToast(
                                                  msg: 'لقد تم اكتمال الطلب',
                                                  backgroundColor: Colors.green,
                                                  textColor: Colors.white);
                                            }
                                          } catch (e) {
                                            // close loading dialog and keep confirmation open
                                            try {
                                              Navigator.of(dialogContext).pop();
                                            } catch (_) {}

                                            Fluttertoast.showToast(
                                                msg:
                                                    'حدث خطأ، يرجى المحاولة مرة أخرى',
                                                backgroundColor: Colors.red,
                                                textColor: Colors.white);

                                            setDialogState(
                                                () => isConfirmLoading = false);
                                          }
                                        },
                                        child: Container(
                                          height: 50,
                                          width: 100,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: widget.mainColor),
                                          child: Center(
                                              child: isConfirmLoading
                                                  ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2),
                                                    )
                                                  : const Text("نعم",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                          color:
                                                              Colors.white))),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          if (!isConfirmLoading)
                                            Navigator.pop(dialogContext);
                                        },
                                        child: Container(
                                          height: 50,
                                          width: 100,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: widget.mainColor),
                                          child: const Center(
                                              child: Text("لا",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Colors.white))),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              );
                            },
                          );
                        },
                      );
                    }
                  : null,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  gradient: _showDeliveryButton
                      ? const LinearGradient(
                          colors: [Color(0xFF27AE60), Color(0xFF1E8449)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _showDeliveryButton ? null : Colors.grey.shade400,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          _showDeliveryButton
                              ? (_localStatus != "in_delivery"
                                  ? Icons.check_circle_outline
                                  : Icons.local_shipping_rounded)
                              : Icons.hourglass_bottom_rounded,
                          color: Colors.white,
                          size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _showDeliveryButton
                            ? (_localStatus != "in_delivery"
                                ? "تم استلام الطلب"
                                : "تم توصيل الطلب")
                            : "انتظر ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTypeLabel() {
    final isLoad = widget.type.toString() == "load";
    final color = isLoad ? const Color(0xFFC0392B) : const Color(0xFF27AE60);
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                isLoad
                    ? Icons.upload_rounded
                    : Icons.inventory_2_rounded,
                color: Colors.white,
                size: 13),
            const SizedBox(width: 4),
            Text(isLoad ? "تحميل" : "استلام",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (!_isNewOrder) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShipmentDetail(
                    name: widget.trackingNumber,
                    shipment_id: widget.id.toString(),
                    from: widget.from,
                    lattitude: double.tryParse(widget.lattitude) ?? 0.0,
                    longitude: double.tryParse(widget.longitude) ?? 0.0,
                    to: widget.to,
                    cod_amount: widget.codAmount,
                    total: _localCod,
                    status: widget.status,
                    quantity: widget.quantity,
                    business_name: widget.businessName,
                    business_phone: widget.businessPhone,
                    consignee_name: widget.consigneeName,
                    consignee_phone1: widget.consigneePhone1,
                    consignee_phone2: widget.consigneePhone2,
                    items_description: widget.itemsDescription,
                    createdAt: widget.createdAt,
                    updatedAt: widget.updatedAt,
                    customerAdress: widget.customerAdress,
                    customerNear: widget.customerNear,
                    resturantAdress: widget.resturantAdress,
                  ),
                ),
              );
            }
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: _isNewOrder
                  ? Border.all(
                      color: widget.mainColor.withOpacity(0.5),
                      width: 1.5)
                  : Border.all(color: const Color(0xFFECECEC)),
              boxShadow: [
                BoxShadow(
                  color: _isNewOrder
                      ? widget.mainColor.withOpacity(0.15)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context),
                  _buildRoute(),
                  _buildDivider(),
                  _buildPaymentRow(context),
                  Visibility(
                      visible: !widget.newOrder,
                      child: _buildDeliveryButton()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
