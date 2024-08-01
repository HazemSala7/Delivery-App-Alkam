import 'dart:async';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:location/location.dart';
import 'package:flutter/material.dart';
import 'package:optimus_opost/Components/button_widget/button_widget.dart';
import 'package:optimus_opost/Pages/shipment_detail/add_note_diaog/add_note_dialog.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:optimus_opost/Pages/shipment_detail/detect_location/detect_location.dart';
import 'package:optimus_opost/Server/functions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Constants/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      lattitude,
      longitude,
      items_description;
  const ShipmentDetail(
      {super.key,
      this.name,
      this.shipment_id,
      this.from,
      this.to,
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
      this.items_description});

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

  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: MAINCOLOR,
                      borderRadius: BorderRadius.only(
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
                            Container(
                              width: 25,
                              height: 25,
                            ),
                            Text(
                              widget.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: Colors.white),
                            ),
                            IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: Icon(
                                  Icons.arrow_forward_outlined,
                                  size: 35,
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
                                color: Color.fromARGB(98, 123, 128, 125),
                                borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                            color:
                                                details ? Colors.white : null,
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
                                                fontSize: 18),
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
                                            color: con ? Colors.white : null,
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
                                                fontSize: 18),
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
                                            color: status ? Colors.white : null,
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
                                                fontSize: 18),
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
                      )
                    : con
                        ? Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height - 170,
                            child: GoogleMap(
                              onMapCreated: _onMapCreated,
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                    double.parse(widget.lattitude.toString()),
                                    double.parse(widget.longitude.toString())),
                                zoom: 11.0,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId("marker1"),
                                  position: LatLng(
                                      double.parse(widget.lattitude.toString()),
                                      double.parse(
                                          widget.longitude.toString())),
                                  draggable: true,
                                  onDragEnd: (value) {
                                    // value is the new position
                                  },
                                  icon: BitmapDescriptor.defaultMarker,
                                ),
                                Marker(
                                  markerId: const MarkerId("marker2"),
                                  position: const LatLng(
                                      37.415768808487435, -122.08440050482749),
                                ),
                              },
                            ),
                          )
                        : ListView.builder(
                            itemCount: 5,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return StatusCard(
                                  index: index,
                                  name: statuses[index],
                                  CardColor: index == 0
                                      ? Color(0xffFDBD69)
                                      : Colors.white);
                            })
              ],
            ),
          ),
        ),
        Visibility(
          visible: status,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Material(
              child: InkWell(
                onTap: () {
                  AddNote(ship_id: widget.shipment_id)
                      .showBottomDialog(context);
                },
                child: Container(
                  width: 50,
                  height: 50,
                  child: Center(
                    child: Icon(
                      Icons.note_add,
                      color: Colors.white,
                    ),
                  ),
                  decoration: BoxDecoration(
                      color: Color(0xff73CC9F), shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  List<String> statuses = [
    "قيد التجهيز",
    "جاهز للتسليم",
    "تم التسليم",
    "مرتجع",
    "عالق"
  ];

  Widget StatusCard(
      {String name = "", String date = "", Color? CardColor, int index = 0}) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Container(
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
                  index == 0
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 5, top: 5),
                          child: Container(
                            height: 16,
                            width: 17,
                            child: Center(
                              child: Container(
                                height: 12,
                                width: 12,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: MAINCOLOR),
                              ),
                            ),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: MAINCOLOR, width: 1)),
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
                        name,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: index == 0 ? Colors.white : Colors.black),
                      ),
                      Text(
                        "01/03/2023 - 12:30PM",
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                index == 0 ? Colors.white : Color(0xff3C3C3C)),
                      )
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
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, right: 20, left: 20),
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.from,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18),
                      ),
                    ),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xff1B425E)),
                  ),
                  line(),
                  line(),
                  line(),
                  line(),
                  line(),
                  line(),
                  line(),
                  line(),
                  line(),
                ],
              ),
              SizedBox(
                width: 20,
              ),
              Container(
                width: 280,
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 15, left: 15),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person_pin,
                            color: Color(0xffDA6528),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Text(
                            from,
                            style: TextStyle(
                                color: Color(0xffDA6528),
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.map,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Text(
                            business_name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                InkWell(
                                  onTap: () {
                                    launch("tel://$consignee_phone1");
                                  },
                                  child: Text(
                                    widget.business_phone,
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    launch("tel://$consignee_phone1");
                                  },
                                  child: Text(
                                    widget.business_phone,
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 20, left: 20),
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.to,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18),
                      ),
                    ),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xff1B425E)),
                  ),
                  line(),
                  line(),
                  line(),
                  line(),
                  line(),
                  line(),
                  line(),
                  line(),
                  line(),
                ],
              ),
              SizedBox(
                width: 20,
              ),
              Container(
                width: 280,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, right: 15, left: 15),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person_pin,
                            color: Color(0xffDA6528),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Text(
                            widget.consignee_name.length > 25
                                ? widget.consignee_name.substring(0, 25) + '...'
                                : widget.consignee_name,
                            style: TextStyle(
                                color: Color(0xffDA6528),
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.map,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Container(
                            // width: 300,
                            height: 44,
                            child: Text(
                              widget.to.length > 70
                                  ? widget.to.substring(0, 70) + '...'
                                  : widget.to,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                InkWell(
                                  onTap: () {
                                    launch("tel://$consignee_phone1");
                                  },
                                  child: Text(
                                    consignee_phone1.length > 25
                                        ? widget.consignee_phone1
                                                .substring(0, 25) +
                                            '...'
                                        : widget.consignee_phone1,
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    launch("tel://$consignee_phone2");
                                  },
                                  child: Text(
                                    consignee_phone2.length > 25
                                        ? widget.consignee_phone2
                                                .substring(0, 25) +
                                            '...'
                                        : widget.consignee_phone2,
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.only(top: 20, right: 20, left: 20, bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    child: Center(child: Image.asset("assets/truck.png")),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xff1B425E)),
                  ),
                ],
              ),
              SizedBox(
                width: 20,
              ),
              Container(
                width: 280,
                // height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 10, right: 15, left: 15, bottom: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            "assets/goods.png",
                            height: 35,
                            width: 35,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                "حاله الطلب",
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          Image.asset(
                            "assets/exchange_money.png",
                            height: 35,
                            width: 35,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${cod_amount} ${AppLocalizations.of(context)!.shekels}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                AppLocalizations.of(context)!
                                    .payement_when_recieving,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          Image.asset(
                            "assets/shipments.png",
                            height: 35,
                            width: 35,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${quantity} طرود",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                "عدد الطرود",
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          Image.asset(
                            "assets/shipments.png",
                            height: 35,
                            width: 35,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "التفاصيل",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Container(
                                width: 180,
                                child: Text(
                                  items_description,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              )
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
        color: Color(0xff1B425E),
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
