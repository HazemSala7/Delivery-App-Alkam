import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:optimus_opost/Constants/constants.dart';
import 'package:optimus_opost/Pages/notifications/notifications.dart';
import 'package:optimus_opost/Pages/shipment_detail/shipment_detail.dart';
import 'package:optimus_opost/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../Server/functions.dart';
import '../search_dialog/search_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class ShipmentsFromTo extends StatefulWidget {
  final status, from, to;
  const ShipmentsFromTo({super.key, this.status, this.from, this.to});

  @override
  State<ShipmentsFromTo> createState() => _ShipmentsFromToState();
}

class _ShipmentsFromToState extends State<ShipmentsFromTo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: MAINCOLOR,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25))),
              child: Padding(
                padding: const EdgeInsets.only(right: 15, left: 15, top: 20),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                actions: <Widget>[
                                  Column(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          Optimus.of(context)!.setLocale(
                                              Locale.fromSubtags(
                                                  languageCode: 'ar'));
                                          Navigator.pop(context);
                                        },
                                        child: Container(
                                            width: double.infinity,
                                            height: 50,
                                            color: MAINCOLOR,
                                            child: Center(
                                              child: Text(
                                                'Arabic',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            )),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Optimus.of(context)!.setLocale(
                                              Locale.fromSubtags(
                                                  languageCode: 'en'));
                                          Navigator.pop(context);
                                        },
                                        child: Container(
                                            width: double.infinity,
                                            height: 50,
                                            color: MAINCOLOR,
                                            child: Center(
                                              child: Text(
                                                'English',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            )),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Image.asset(
                          "assets/language.png",
                          height: 30,
                          width: 30,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.shipments,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Colors.white),
                      ),
                      FutureBuilder(
                          future: getNotificationsCount(),
                          builder: (context, AsyncSnapshot snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return NotificationCard(count: 0);
                            } else {
                              var shipments =
                                  snapshot.data[0]["action_data"]["count"] ?? 0;

                              return NotificationCard(count: shipments);
                            }
                          }),
                    ],
                  ),
                ),
              ),
            ),
            FutureBuilder(
                future: filterShipmentsFromTo(
                    widget.status ==
                            AppLocalizations.of(context)!.under_processing
                        ? "under"
                        : widget.status ==
                                AppLocalizations.of(context)!.delivered
                            ? "deliverd"
                            : widget.status ==
                                    AppLocalizations.of(context)!.returned
                                ? "returned"
                                : widget.status ==
                                        AppLocalizations.of(context)!.cancelled
                                    ? "canceleed"
                                    : "all",
                    widget.from,
                    widget.to),
                builder: (context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: SpinKitPulse(
                        color: Color(0xff800080),
                        size: 60,
                      ),
                    );
                  } else {
                    var shipments = [];
                    shipments = snapshot.data[0]["data"];
                    if (shipments.length == 0) {
                      return Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Center(
                              child: Text(
                            "لا يوحد شحنات",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17),
                          )));
                    } else {
                      return ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: shipments.length,
                          itemBuilder: (context, int index) {
                            return ShipmentCard(
                              tracking_number:
                                  shipments[index]["tracking_number"] ?? "-",
                              id: shipments[index]["id"] ?? 1,
                              quantity: shipments[index]["quantity"] ?? "-",
                              from: shipments[index]["business_address.city"]
                                      ["name"] ??
                                  "-",
                              to: shipments[index]["consignee.address"] ?? "-",
                              status: shipments[index]["last_status"]
                                      ["status"] ??
                                  "-",
                              business_name:
                                  shipments[index]["business.name"] ?? "-",
                              business_phone:
                                  shipments[index]["business.phone"] ?? "-",
                              consignee_name:
                                  shipments[index]["consignee.name"] ?? "-",
                              consignee_phone1:
                                  shipments[index]["consignee.phone1"] ?? "-",
                              consignee_phone2:
                                  shipments[index]["consignee.phone2"] ?? "-",
                              items_description:
                                  shipments[index]["items_description"] ?? "-",
                              cod_amount: shipments[index]["cod_amount"] ?? 0,
                            );
                          });
                    }
                  }
                }),
          ],
        ),
      ),
    );
  }

  Stack NotificationCard({int count = 0}) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => Notifications()));
          },
          icon: Icon(
            Icons.notifications,
            color: Colors.white,
            size: 35,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: Container(
            width: 20,
            height: 20,
            child: Center(
              child: Text(
                count.toString(),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: Colors.red),
          ),
        )
      ],
    );
  }

  Widget ShipmentCard({
    String tracking_number = "",
    String business_name = "",
    String business_phone = "",
    String consignee_name = "",
    String consignee_phone1 = "",
    String consignee_phone2 = "",
    String status = "",
    String items_description = "",
    int cod_amount = 0,
    // String status = "",
    String from = "",
    String to = "",
    int quantity = 0,
    int id = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 15, left: 15, top: 15),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ShipmentDetail(
                        name: tracking_number,
                        shipment_id: id.toString(),
                        from: from,
                        to: to,
                        cod_amount: cod_amount,
                        status: status,
                        quantity: quantity,
                        business_name: business_name,
                        business_phone: business_phone,
                        consignee_name: consignee_name,
                        consignee_phone1: consignee_phone1,
                        consignee_phone2: consignee_phone2,
                        items_description: items_description,
                      )));
        },
        child: Container(
          height: 198,
          width: double.infinity,
          decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 1), // changes position of shadow
                ),
              ],
              border: Border(
                bottom: BorderSide(
                  color: MAINCOLOR,
                  width: 3.0,
                ),
              ),
              color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.only(right: 15, left: 15, top: 15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tracking_number,
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Image.asset(
                            "assets/box.png",
                            height: 15,
                            fit: BoxFit.cover,
                          ),
                          Text(
                              "${quantity} ${AppLocalizations.of(context)!.shipments_card}"),
                        ],
                      ),
                      width: 120,
                      height: 30,
                      decoration: BoxDecoration(
                          color: Color.fromARGB(255, 241, 241, 241),
                          border: Border.all(color: Color(0xffDDDDDD))),
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Container(
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: MAINCOLOR, width: 2)),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        AppLocalizations.of(context)!.from,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        from,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Container(
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                          color: MAINCOLOR,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        AppLocalizations.of(context)!.to,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Container(
                        height: 20,
                        child: Text(
                          to.length > 25 ? to.substring(0, 25) + '...' : to,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: double.infinity,
                    height: 1,
                    color: Color.fromARGB(255, 228, 227, 227),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            "assets/money.png",
                            fit: BoxFit.cover,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Column(
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .payement_when_recieving,
                                style: TextStyle(
                                    color: Color(0xff3C3C3C), fontSize: 12),
                              ),
                              Text(
                                  "${cod_amount.toString()} ${AppLocalizations.of(context)!.shekels}"),
                            ],
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.shipment_details,
                            style: TextStyle(color: MAINCOLOR),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 20,
                            color: MAINCOLOR,
                          )
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SearchDialog {
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
          child: SearchScreen(),
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
