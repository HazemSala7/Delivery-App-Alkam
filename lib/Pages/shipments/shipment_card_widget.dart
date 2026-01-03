import 'dart:async';
import 'package:flutter/material.dart';
import 'package:optimus_opost/Pages/shipment_detail/shipment_detail.dart';
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

  double get _localCod {
    final parsed = double.tryParse(widget.shipment["total"]?.toString() ??
            widget.codAmount.toString())! +
        double.tryParse(
            widget.shipment["restaurant"]["delivery_price"]?.toString() ??
                widget.codAmount.toString())!;
    return parsed;
  }

  double get _total {
    final parsed = double.tryParse(
        widget.shipment["total"]?.toString() ?? widget.codAmount.toString())!;
    return parsed;
  }

  double get _deliveryPrice {
    final parsed = double.tryParse(
        widget.shipment["restaurant"]["delivery_price"]?.toString() ??
            widget.codAmount.toString())!;
    return parsed;
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

  Widget _buildHeader(BuildContext context) {
    final visiblePreparationContainer = _localStatus != "in_delivery";
    return Padding(
      padding: const EdgeInsets.only(right: 15, left: 15, top: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_localTracking,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Visibility(
            visible: visiblePreparationContainer,
            child: Container(
              width: _isNewOrder ? 180 : 120,
              height: 30,
              decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 241, 241, 241),
                  border: Border.all(color: const Color(0xffDDDDDD))),
              child: _isNewOrder
                  ? Center(
                      child: TweenAnimationBuilder<Duration>(
                        duration: Duration(seconds: _remainingSeconds),
                        tween: Tween(
                            begin: Duration(seconds: _remainingSeconds),
                            end: Duration.zero),
                        builder: (context, value, child) {
                          final seconds = value.inSeconds;
                          return Text('سيتم الإلغاء خلال: $seconds ثانية',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.red));
                        },
                      ),
                    )
                  : Visibility(
                      visible: _localStatus == "in_progress",
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          PreparationTimer(
                            startAt: widget
                                        .shipment["preparation_started_at"] !=
                                    null
                                ? DateTime.parse(
                                    widget.shipment["preparation_started_at"])
                                : DateTime.now(),
                            preparationTime:
                                widget.shipment["preparation_time"] ?? 0,
                          ),
                        ],
                      ),
                    ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAddressRow({required bool isFrom}) {
    return Padding(
      padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
      child: Row(
        children: [
          Container(
            height: 12,
            width: 12,
            decoration: BoxDecoration(
                color: isFrom ? null : widget.mainColor,
                shape: BoxShape.circle,
                border: isFrom
                    ? Border.all(color: widget.mainColor, width: 2)
                    : null),
          ),
          const SizedBox(width: 10),
          Text(
              isFrom
                  ? AppLocalizations.of(context)!.from
                  : AppLocalizations.of(context)!.to,
              style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          if (isFrom)
            Text(widget.from,
                style: const TextStyle(fontWeight: FontWeight.bold))
          else
            SizedBox(
                height: 20,
                child: Text(
                    widget.to.length > 25
                        ? '${widget.to.substring(0, 25)}...'
                        : widget.to,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
        padding: const EdgeInsets.only(right: 15, left: 15, top: 15),
        child: Container(
            width: double.infinity, height: 1, color: const Color(0xFFE4E3E3)));
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
      padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Image.asset("assets/money.png", fit: BoxFit.cover),
          const SizedBox(width: 10),
          Column(children: [
            Text(paymentLabel,
                style: const TextStyle(color: Color(0xff3C3C3C), fontSize: 12)),
            Text("$_localCod ${AppLocalizations.of(context)!.shekels}")
          ]),
        ]),
        _buildConfirmOrDetailsButton(context),
      ]),
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
                      ),
                    );
                  },
                );
              }
            },
      child: Container(
        decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: widget.mainColor)),
        width: 150,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _isNewOrder
                ? (_isConfirmingNewOrder
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text("تأكيد الطلب",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)))
                : Text(AppLocalizations.of(context)!.shipment_details,
                    style: TextStyle(color: widget.mainColor)),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios, size: 20, color: widget.mainColor),
          ]),
        ),
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
                height: 40,
                decoration: BoxDecoration(
                    color: _showDeliveryButton ? Colors.green : Colors.grey),
                child: Center(
                  child: Text(
                    _showDeliveryButton
                        ? (_localStatus != "in_delivery"
                            ? "تم استلام الطلب"
                            : "تم توصيل الطلب")
                        : "انتظر ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text(widget.type.toString() == "load" ? "تحميل" : "استلام",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 15),
        Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(
                color: widget.type.toString() == "receive"
                    ? Colors.green
                    : Colors.red,
                borderRadius: BorderRadius.circular(10))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final containerHeight = (["delivered", "canceled", "pending", "returned"]
                .contains(_localStatus) ||
            _activeShipmentsIsEmpty)
        ? 180.0
        : 240.0;
    return Padding(
      padding: const EdgeInsets.only(right: 15, left: 15, top: 15),
      child: InkWell(
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
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: containerHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 1))
                  ],
                  border: Border(
                      bottom: BorderSide(color: widget.mainColor, width: 3.0)),
                  color: Colors.white),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeader(context),
                    _buildAddressRow(isFrom: true),
                    _buildAddressRow(isFrom: false),
                    _buildDivider(),
                    _buildPaymentRow(context),
                    Visibility(
                        visible: !widget.newOrder,
                        child: _buildDeliveryButton()),
                  ]),
            ),
            _buildTypeLabel(),
          ],
        ),
      ),
    );
  }
}
