import 'dart:async';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:optimus_opost/Pages/shipment_detail/add_note_diaog/add_note_dialog.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:optimus_opost/Pages/shipment_detail/detect_location/detect_location.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Constants/constants.dart';
import 'package:optimus_opost/l10n/app_localizations.dart';

class ShipmentDetail extends StatefulWidget {
  final name,
      shipment_id,
      from,
      to,
      business_name,
      business_phone,
      consignee_name,
      consignee_phone1,
      consignee_phone2,
      quantity,
      status,
      cod_amount,
      total,
      lattitude,
      longitude,
      items_description,
      createdAt,
      updatedAt,
      resturantAdress,
      customerAdress,
      customerNear;
  const ShipmentDetail(
      {super.key,
      this.name,
      this.shipment_id,
      this.from,
      this.to,
      this.total,
      this.business_name,
      this.business_phone,
      this.consignee_name,
      this.consignee_phone1,
      this.lattitude,
      this.longitude,
      this.status,
      this.cod_amount,
      this.quantity,
      this.consignee_phone2,
      this.items_description,
      this.createdAt,
      this.updatedAt,
      this.resturantAdress,
      this.customerAdress,
      this.customerNear});

  @override
  State<ShipmentDetail> createState() => _ShipmentDetailState();
}

class _ShipmentDetailState extends State<ShipmentDetail> {
  @override
  bool details = true;
  bool con = false;
  bool status = false;
  late GoogleMapController mapController;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void showContactOptions(BuildContext context, String phone) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('اختر وسيلة المكالمة'),
          // content: Text('What would you like to do?'),
          actions: <Widget>[
            MaterialButton(
              color: Colors.blue,
              child: const Text(
                'مكالمة',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _makePhoneCall(phone);
              },
            ),
            MaterialButton(
              color: Colors.green,
              child:
                  const Text('واتس اب', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _sendWhatsAppMessage(phone);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    launch("tel://$phoneNumber");
  }

  Future<void> _sendWhatsAppMessage(String phoneNumber) async {
    final contact = "+972${phoneNumber.substring(1)}";
    print(contact);
    final androidUrl =
        "whatsapp://send?phone=$contact&text=Hi, I need some help";
    final iosUrl =
        "https://wa.me/$contact?text=${Uri.parse('Hi, I need some help')}";

    try {
      if (Platform.isIOS) {
        await launchUrl(Uri.parse(iosUrl));
      } else {
        await launchUrl(Uri.parse(androidUrl));
      }
    } on Exception {
      Fluttertoast.showToast(msg: "لم يتم تنزيل الواتساب");
    }
  }

  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Container(
          color: MAINCOLOR,
          child: SafeArea(
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: MAINCOLOR,
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(25),
                              bottomRight: Radius.circular(25))),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            right: 15, left: 15, top: 20, bottom: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(
                                  width: 25,
                                  height: 25,
                                ),
                                Text(
                                  widget.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      color: Colors.white),
                                ),
                                IconButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(
                                      Icons.arrow_forward_outlined,
                                      size: 25,
                                      color: Colors.white,
                                    ))
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 15,
                                left: 15,
                              ),
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(98, 123, 128, 125),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            details = true;
                                            con = false;
                                            status = false;
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: details
                                                    ? Colors.white
                                                    : null,
                                                borderRadius: details
                                                    ? BorderRadius.circular(10)
                                                    : BorderRadius.circular(0)),
                                            height: 45,
                                            child: Center(
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .details,
                                                style: TextStyle(
                                                    color: details
                                                        ? MAINCOLOR
                                                        : Colors.white,
                                                    fontSize: 16),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            details = false;
                                            con = true;
                                            status = false;
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color:
                                                    con ? Colors.white : null,
                                                borderRadius: con
                                                    ? BorderRadius.circular(10)
                                                    : BorderRadius.circular(0)),
                                            height: 45,
                                            child: Center(
                                              child: Text(
                                                "موقع العميل",
                                                style: TextStyle(
                                                    color: con
                                                        ? MAINCOLOR
                                                        : Colors.white,
                                                    fontSize: 16),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            details = false;
                                            con = false;
                                            status = true;
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: status
                                                    ? Colors.white
                                                    : null,
                                                borderRadius: status
                                                    ? BorderRadius.circular(10)
                                                    : BorderRadius.circular(0)),
                                            height: 45,
                                            child: Center(
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .status,
                                                style: TextStyle(
                                                    color: status
                                                        ? MAINCOLOR
                                                        : Colors.white,
                                                    fontSize: 16),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    details
                        ? DetailsScreen(
                            tracking_number: widget.shipment_id.toString(),
                            quantity: widget.quantity,
                            from: widget.from,
                            to: widget.to,
                            status: widget.status,
                            business_name: widget.business_name,
                            business_phone: widget.business_phone,
                            consignee_name: widget.consignee_name,
                            consignee_phone1: widget.consignee_phone1,
                            consignee_phone2: widget.consignee_phone2,
                            items_description: widget.items_description,
                            cod_amount: widget.cod_amount,
                            total: widget.total,
                            resturantAdress: widget.resturantAdress,
                            customerAdress: widget.customerAdress,
                            customerNear: widget.customerNear,
                          )
                        : con
                            ? SizedBox(
                                width: double.infinity,
                                height:
                                    MediaQuery.of(context).size.height - 170,
                                child: GoogleMap(
                                  onMapCreated: _onMapCreated,
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(
                                        double.parse(
                                            widget.lattitude.toString()),
                                        double.parse(
                                            widget.longitude.toString())),
                                    zoom: 11.0,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId("marker1"),
                                      position: LatLng(
                                          double.parse(
                                              widget.lattitude.toString()),
                                          double.parse(
                                              widget.longitude.toString())),
                                      draggable: true,
                                      onDragEnd: (value) {
                                        // value is the new position
                                      },
                                      icon: BitmapDescriptor.defaultMarker,
                                    ),
                                    const Marker(
                                      markerId: MarkerId("marker2"),
                                      position: LatLng(37.415768808487435,
                                          -122.08440050482749),
                                    ),
                                  },
                                ),
                              )
                            : ListView.builder(
                                itemCount: 6,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return StatusCard(
                                      index: index,
                                      name: statuses[index],
                                      CardColor:
                                          statuses[index] == widget.status
                                              ? const Color(0xFFA51E22)
                                              : Colors.white);
                                })
                  ],
                ),
              ),
            ),
          ),
        ),
        // Visibility(
        //   visible: status,
        //   child: Padding(
        //     padding: const EdgeInsets.all(10.0),
        //     child: Material(
        //       child: InkWell(
        //         onTap: () {
        //           AddNote(ship_id: widget.shipment_id)
        //               .showBottomDialog(context);
        //         },
        //         child: Container(
        //           width: 50,
        //           height: 50,
        //           child: Center(
        //             child: Icon(
        //               Icons.note_add,
        //               color: Colors.white,
        //             ),
        //           ),
        //           decoration: BoxDecoration(
        //               color: Color(0xff73CC9F), shape: BoxShape.circle),
        //         ),
        //       ),
        //     ),
        //   ),
        // )
      ],
    );
  }

  List<String> statuses = [
    "in_progress",
    "ready_for_delivery",
    "in_delivery",
    "delivered",
    "canceled",
    "returned",
  ];

  Widget StatusCard(
      {String name = "", String date = "", Color? CardColor, int index = 0}) {
    DateTime createdDate = DateTime.parse(widget.createdAt);
    DateTime updatedDate = DateTime.parse(widget.updatedAt);

    // String formattedDate = DateFormat('dd/MM/yyyy - hh:mm a').format(
    //   statuses[index] == "in_progress" ? createdDate : updatedDate,
    // );

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: SizedBox(
        height: 80,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Container(
                    height: 27,
                    width: 1,
                    color: MAINCOLOR,
                  ),
                  statuses[index] == widget.status
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 5, top: 5),
                          child: Container(
                            height: 16,
                            width: 17,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: MAINCOLOR, width: 1)),
                            child: Center(
                              child: Container(
                                height: 12,
                                width: 12,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: MAINCOLOR),
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 5, top: 5),
                          child: Container(
                            height: 16,
                            width: 17,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: MAINCOLOR, width: 1)),
                          ),
                        ),
                  Container(
                    height: 27,
                    width: 1,
                    color: MAINCOLOR,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  color: CardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 15, left: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name == "in_progress"
                            ? "قيد المعالجة"
                            : name == "ready_for_delivery"
                                ? "جاهز للتوصيل"
                                : name == "in_delivery"
                                    ? "في التوصيل"
                                    : name == "delivered"
                                        ? " تم التسليم"
                                        : name == "canceled"
                                            ? "ملغى"
                                            : "مرجع",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statuses[index] == widget.status
                                ? Colors.white
                                : Colors.black),
                      ),
                      // Text(
                      //   formattedDate,
                      //   style: TextStyle(
                      //       fontSize: 12,
                      //       color: statuses[index] == widget.status
                      //           ? Colors.white
                      //           : const Color(0xff3C3C3C)),
                      // )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget DetailsScreen({
    int id = 0,
    String tracking_number = "",
    String from = "",
    String business_name = "",
    String business_phone = "",
    String consignee_name = "",
    String to = "",
    String consignee_phone1 = "",
    String consignee_phone2 = "",
    int quantity = 0,
    String status = "",
    String items_description = "",
    double cod_amount = 0.0,
    double total = 0.0,
    String resturantAdress = "",
    String customerAdress = "",
    String customerNear = "",
  }) {
    String statusArabic() {
      switch (status) {
        case "in_progress":
          return "قيد المعالجة";
        case "ready_for_delivery":
          return "استلام من المطعم";
        case "in_delivery":
          return "تسليم للعميل";
        case "delivered":
          return "تم التسليم";
        case "canceled":
          return "ملغى";
        default:
          return "مرجع";
      }
    }

    Color statusColor() {
      switch (status) {
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
        default:
          return MAINCOLOR;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // FROM (Restaurant)
          _detailCard(
            accent: MAINCOLOR,
            badge: _circleBadge(
              icon: Icons.storefront_rounded,
              label: AppLocalizations.of(context)!.from,
              color: MAINCOLOR,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(from,
                    style: TextStyle(
                      color: MAINCOLOR,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )),
                const SizedBox(height: 10),
                _detailLine(
                  icon: Icons.location_on_rounded,
                  text: resturantAdress.isEmpty ? "-" : resturantAdress,
                ),
                const SizedBox(height: 8),
                _detailLine(
                  icon: Icons.phone_rounded,
                  text: widget.business_phone.isEmpty
                      ? "-"
                      : widget.business_phone,
                  onTap: widget.business_phone.isEmpty
                      ? null
                      : () => showContactOptions(
                          context, widget.business_phone),
                  isAction: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // TO (Customer)
          _detailCard(
            accent: const Color(0xFF2980B9),
            badge: _circleBadge(
              icon: Icons.person_pin_circle_rounded,
              label: AppLocalizations.of(context)!.to,
              color: const Color(0xFF2980B9),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.consignee_name.length > 30
                      ? "${widget.consignee_name.substring(0, 30)}..."
                      : widget.consignee_name,
                  style: const TextStyle(
                    color: Color(0xFF2980B9),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                _detailLine(
                  icon: Icons.map_rounded,
                  text: customerAdress.isEmpty
                      ? "-"
                      : "العنوان: $customerAdress",
                ),
                if (customerNear.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _detailLine(
                    icon: Icons.near_me_rounded,
                    text: "بالقرب من: $customerNear",
                  ),
                ],
                const SizedBox(height: 8),
                if (consignee_phone1.isNotEmpty)
                  _detailLine(
                    icon: Icons.phone_rounded,
                    text: consignee_phone1,
                    onTap: () =>
                        showContactOptions(context, consignee_phone1),
                    isAction: true,
                  ),
                if (consignee_phone2.isNotEmpty &&
                    consignee_phone2 != consignee_phone1) ...[
                  const SizedBox(height: 6),
                  _detailLine(
                    icon: Icons.phone_rounded,
                    text: consignee_phone2,
                    onTap: () =>
                        showContactOptions(context, consignee_phone2),
                    isAction: true,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          // ORDER SUMMARY
          _detailCard(
            accent: const Color(0xFF27AE60),
            badge: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF27AE60).withOpacity(0.12),
                border: Border.all(
                    color: const Color(0xFF27AE60).withOpacity(0.4),
                    width: 2),
              ),
              child: const Icon(Icons.local_shipping_rounded,
                  color: Color(0xFF27AE60), size: 26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ملخص الطلبية",
                  style: TextStyle(
                    color: Color(0xFF2C3E50),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _summaryRow(
                  icon: Icons.flag_rounded,
                  iconColor: statusColor(),
                  bgColor: statusColor().withOpacity(0.12),
                  title: statusArabic(),
                  subtitle: "حالة الطلب",
                ),
                const Divider(height: 18, color: Color(0xFFF0F0F0)),
                _summaryRow(
                  icon: Icons.payments_rounded,
                  iconColor: const Color(0xFFE67E22),
                  bgColor: const Color(0xFFFFF7E6),
                  title:
                      "$total ${AppLocalizations.of(context)!.shekels}",
                  subtitle:
                      AppLocalizations.of(context)!.payement_when_recieving,
                ),
                const Divider(height: 18, color: Color(0xFFF0F0F0)),
                _summaryRow(
                  icon: Icons.inventory_2_rounded,
                  iconColor: const Color(0xFF2980B9),
                  bgColor: const Color(0xFFE6F0FA),
                  title: "$quantity طرود",
                  subtitle: "عدد الطرود",
                ),
                if (items_description.trim().isNotEmpty) ...[
                  const Divider(height: 18, color: Color(0xFFF0F0F0)),
                  _summaryRow(
                    icon: Icons.list_alt_rounded,
                    iconColor: MAINCOLOR,
                    bgColor: MAINCOLOR.withOpacity(0.1),
                    title: "التفاصيل",
                    subtitle: items_description,
                    subtitleMaxLines: 4,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailCard({
    required Color accent,
    required Widget badge,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: badge,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 14, 14),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }

  Widget _detailLine({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
    bool isAction = false,
  }) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 18,
            color: isAction ? MAINCOLOR : const Color(0xFF7F8C8D)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: isAction ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
              color: isAction
                  ? MAINCOLOR
                  : const Color(0xFF2C3E50),
              decoration:
                  isAction ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        ),
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: content,
      ),
    );
  }

  Widget _summaryRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    int subtitleMaxLines = 2,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF2C3E50)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: subtitleMaxLines,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7F8C8D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Padding line() {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Container(
        width: 2,
        height: 8,
        color: const Color(0xff1B425E),
      ),
    );
  }
}

class AddNote {
  final ship_id;

  AddNote({
    required this.ship_id,
  });
  void showBottomDialog(BuildContext context) {
    showGeneralDialog(
      barrierLabel: "showGeneralDialog",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      context: context,
      pageBuilder: (context, _, __) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: AddNoteDialog(
            ship_id: ship_id,
          ),
        );
      },
      transitionBuilder: (_, animation1, __, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: const Offset(0, 0),
          ).animate(animation1),
          child: child,
        );
      },
    );
  }
}

class DetectLocation {
  final ship_id;

  DetectLocation({
    required this.ship_id,
  });
  void showBottomDialog(BuildContext context) {
    showGeneralDialog(
      barrierLabel: "showGeneralDialog",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      context: context,
      pageBuilder: (context, _, __) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: DetectLocationDialog(
            detectLocaion: () {},
            shipment_id: ship_id,
          ),
        );
      },
      transitionBuilder: (_, animation1, __, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: const Offset(0, 0),
          ).animate(animation1),
          child: child,
        );
      },
    );
  }
}
