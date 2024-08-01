import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimus_opost/Constants/constants.dart';
import 'package:optimus_opost/Pages/notifications/notifications.dart';
import 'package:optimus_opost/Pages/shipment_detail/shipment_detail.dart';
import 'package:optimus_opost/Server/server.dart';
import 'package:optimus_opost/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../Server/functions.dart';
import '../search_dialog/search_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class Shipments extends StatefulWidget {
  const Shipments({super.key});

  @override
  State<Shipments> createState() => _ShipmentsState();
}

class _ShipmentsState extends State<Shipments> {
  @override
  bool searchCheck = false;
  List<bool> clicked = [true, false, false, false, false, false];
  TextEditingController searchController = TextEditingController();
  Widget build(BuildContext context) {
    List<String> status = [
      AppLocalizations.of(context)!.all,
      AppLocalizations.of(context)!.under_processing,
      "جاهز للتسليم",
      AppLocalizations.of(context)!.delivered,
      AppLocalizations.of(context)!.returned,
      AppLocalizations.of(context)!.cancelled,
    ];

    return Container(
      color: MAINCOLOR,
      child: SafeArea(
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 70,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: MAINCOLOR,
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25))),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 20,
                            ),
                            Text(
                              AppLocalizations.of(context)!.shipments,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Colors.white),
                            ),
                            NotificationCard(count: 0)
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Container(
                    height: 40,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: ListView.builder(
                          itemCount: status.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return StatusCard(
                                index: index, name: status[index]);
                          }),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: FutureBuilder(
                      future: searchCheck
                          ? filterShipmentsTrackingNumber(searchController.text)
                          : clicked[0]
                              ? getRequest(URL_SHIPMENTS)
                              : clicked[1]
                                  ? getRequest("$URL_SHIPMENTS_STATUS/pending")
                                  : clicked[2]
                                      ? getRequest(
                                          "$URL_SHIPMENTS_STATUS/delivered")
                                      : clicked[3]
                                          ? getRequest(
                                              "$URL_SHIPMENTS_STATUS/returned")
                                          : clicked[4]
                                              ? getRequest(
                                                  "$URL_SHIPMENTS_STATUS/canceleed")
                                              : "all",
                      builder: (context, AsyncSnapshot snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: SpinKitPulse(
                              color: MAINCOLOR,
                              size: 60,
                            ),
                          );
                        } else {
                          var shipments = [];
                          shipments = snapshot.data["orders"];
                          if (shipments.length == 0) {
                            return Container(
                                width: double.infinity,
                                height:
                                    MediaQuery.of(context).size.height * 0.7,
                                child: Center(
                                    child: Text(
                                  "لا يوحد شحنات",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17),
                                )));
                          } else {
                            return ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: shipments.length,
                                itemBuilder: (context, int index) {
                                  return ShipmentCard(
                                    tracking_number:
                                        shipments[index]["id"].toString(),
                                    id: shipments[index]["id"] ?? 1,
                                    lattitude: shipments[index]["lattitude"]
                                        .toString(),
                                    longitude: shipments[index]["longitude"]
                                        .toString(),
                                    quantity:
                                        shipments[index]["items_length"] ?? 0,
                                    from: shipments[index]["restaurant"]
                                            ["name"] ??
                                        "-",
                                    to: shipments[index]["customer_name"] ??
                                        "-",
                                    status: shipments[index]["status"] ?? "-",
                                    productsArray: shipments[index]
                                            ["order_details"] ??
                                        "-",
                                    type: shipments[index]["type"] ?? "-",
                                    business_name: shipments[index]
                                            ["restaurant"]["name"] ??
                                        "-",
                                    business_phone: shipments[index]
                                            ["restaurant"]["phone_number"] ??
                                        "-",
                                    consignee_name: shipments[index]
                                            ["customer_name"] ??
                                        "-",
                                    consignee_phone1:
                                        shipments[index]["mobile"] ?? "-",
                                    consignee_phone2:
                                        shipments[index]["mobile"] ?? "-",
                                    items_description: "-",
                                    cod_amount: double.parse(
                                        shipments[index]["total"].toString()),
                                  );
                                });
                          }
                        }
                      }),
                ),
              ],
            ),
          ),
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

  Widget StatusCard({String name = "", int index = 0}) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: InkWell(
        onTap: () {
          for (int i = 0; i < clicked.length; i++) {
            clicked[i] = false;
          }
          clicked[index] = true;
          setState(() {});
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
              border: Border.all(
                  color: clicked[index] ? MAINCOLOR : Color(0xffDDDDDD)),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                name,
                style: TextStyle(
                    color: clicked[index] ? MAINCOLOR : Color(0xffA1A1A1)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget ShipmentCard({
    String tracking_number = "",
    String lattitude = "",
    String longitude = "",
    String business_name = "",
    String business_phone = "",
    String consignee_name = "",
    String consignee_phone1 = "",
    String consignee_phone2 = "",
    String status = "",
    String items_description = "",
    double cod_amount = 0.0,
    String type = "",
    String from = "",
    String to = "",
    var productsArray,
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
                        lattitude: lattitude,
                        longitude: longitude,
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
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 240,
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
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(right: 15, left: 15, top: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tracking_number,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
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
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
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
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
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
                    padding:
                        const EdgeInsets.only(right: 15, left: 15, top: 15),
                    child: Container(
                      width: double.infinity,
                      height: 1,
                      color: Color.fromARGB(255, 228, 227, 227),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
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
                              width: 10,
                            ),
                            Column(
                              children: [
                                Text(
                                  type.toString() == "load"
                                      ? "ادفع للمطعم"
                                      : "استلم من الزبون",
                                  style: TextStyle(
                                      color: Color(0xff3C3C3C), fontSize: 12),
                                ),
                                Text(
                                    "${cod_amount.toString()} ${AppLocalizations.of(context)!.shekels}"),
                              ],
                            )
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return ProductDetailsBottomSheet(
                                    total: cod_amount.toString(),
                                    productsArray: productsArray);
                              },
                            );
                          },
                          child: Row(
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
                          ),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      width: double.infinity,
                      height: 40,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      content: Text(
                                        "هل تريد بالتأكيد الغاء الطلب ؟ ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      actions: <Widget>[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            InkWell(
                                              onTap: () async {},
                                              child: Container(
                                                height: 50,
                                                width: 100,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    color: MAINCOLOR),
                                                child: Center(
                                                  child: Text(
                                                    "نعم",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                height: 50,
                                                width: 100,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    color: MAINCOLOR),
                                                child: Center(
                                                  child: Text(
                                                    "لا",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(color: Colors.red),
                                child: Center(
                                  child: Text(
                                    "الغاء الطلب",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      content: Text(
                                        "هل تريد بالتأكيد اكتمال الطلب ؟ ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      actions: <Widget>[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            InkWell(
                                              onTap: () async {},
                                              child: Container(
                                                height: 50,
                                                width: 100,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    color: MAINCOLOR),
                                                child: Center(
                                                  child: Text(
                                                    "نعم",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                height: 50,
                                                width: 100,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    color: MAINCOLOR),
                                                child: Center(
                                                  child: Text(
                                                    "لا",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(color: Colors.green),
                                child: Center(
                                  child: Text(
                                    "اكتمال الطلب",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    type.toString() == "load" ? "تحميل" : "استلام",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  Container(
                    width: 60,
                    height: 10,
                    decoration: BoxDecoration(
                        color: type.toString() == "receive"
                            ? Colors.green
                            : Colors.red,
                        borderRadius: BorderRadius.circular(10)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailsBottomSheet extends StatelessWidget {
  var productsArray, total;

  ProductDetailsBottomSheet({required this.productsArray, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      "تفاصيل الطلبية",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "عدد المنتجات : ${productsArray.length} ",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      width: 50,
                    ),
                    Text(
                      "المجموع الكلي : ${total}",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: productsArray.length,
              itemBuilder: (context, index) {
                final product = productsArray[index];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Image.network(
                            product["product"]['image'],
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "أسم المنتج : ${product["product"]['name']}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text(
                                "سعر المنتج : ${product["product"]['price']}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text(
                                "كمية المنتج : ${product['qty']}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.grey,
                    )
                  ],
                );
              },
            ),
          ),
        ],
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
