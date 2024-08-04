import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimus_opost/Constants/constants.dart';
import 'package:optimus_opost/Pages/login_screen/login_screen.dart';
import 'package:optimus_opost/Pages/notifications/notifications.dart';
import 'package:optimus_opost/Pages/shipment_detail/shipment_detail.dart';
import 'package:optimus_opost/Server/server.dart';
import 'package:optimus_opost/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Server/functions.dart';
import '../search_dialog/search_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class Shipments extends StatefulWidget {
  final String status;

  const Shipments({
    super.key,
    required this.status,
  });

  @override
  State<Shipments> createState() => _ShipmentsState();
}

class _ShipmentsState extends State<Shipments> {
  bool searchCheck = false;
  List<bool> clicked = [true, false, false, false, false, false];
  TextEditingController searchController = TextEditingController();
  String salesmanId = "";
  bool isLoading = false;
  late StreamController<List<dynamic>> _streamController;
  Timer? _timer;
  bool status = false;
  String driverSerial = "";
  String driverName = "";
  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<dynamic>>();
    status = widget.status == "true" ? true : false;
    loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _streamController.close();
    super.dispose();
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      salesmanId = prefs.getString('salesmanId') ?? "";
      driverName = prefs.getString('driver_name') ?? "";
      driverSerial = prefs.getString('driver_serial') ?? "";
    });
    await fetchShipments(false);
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchShipments(false);
    });
  }

  Future<void> fetchShipments(bool fromChange) async {
    if (fromChange) {
      setState(() {
        isLoading = true;
      });
    }
    try {
      var response = await getRequest(clicked[0]
          ? "$URL_SHIPMENTS/$salesmanId"
          : clicked[1]
              ? "$URL_SHIPMENTS_STATUS/pending/$salesmanId"
              : clicked[2]
                  ? "$URL_SHIPMENTS_STATUS/in_progress/$salesmanId"
                  : clicked[3]
                      ? "$URL_SHIPMENTS_STATUS/delivered/$salesmanId"
                      : clicked[4]
                          ? "$URL_SHIPMENTS_STATUS/returned/$salesmanId"
                          : "$URL_SHIPMENTS_STATUS/canceled/$salesmanId");

      if (response != null && response["orders"] is List) {
        _streamController.add(response["orders"]);
      } else {
        _streamController.add([]);
      }
    } catch (e) {
      _streamController.addError('Failed to load shipments');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> changeOrderStatus(String orderId, String status) async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse('https://ustore.ps/login/api/change_order_status'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body:
            jsonEncode(<String, String>{'order_id': orderId, 'status': status}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchShipments(true);
      } else {
        throw Exception('Failed to change order status');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error changing order status');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateSalesmanStatus(bool status) async {
    final response = await http.put(
      Uri.parse('https://ustore.ps/login/api/drivers/$salesmanId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'active': status.toString(),
      }),
    );

    if (response.statusCode == 200) {
      // Handle successful response
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('status', status.toString());
      print('Status updated successfully');
    } else {
      // Handle error response
      print('Failed to update status');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> status = [
      "الكل",
      "قيد المعالجة",
      "جاهز للتسليم",
      "تم التسليم",
      "مرجع",
      "ملغي",
    ];

    return Container(
      color: MAINCOLOR,
      child: SafeArea(
        child: Scaffold(
          drawer: _buildDrawer(),
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: MAINCOLOR,
            iconTheme: const IconThemeData(
              color: Colors.white,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            title: Text(
              AppLocalizations.of(context)!.shipments,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            actions: [
              notificationCard(count: 0),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: SizedBox(
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
                  child: StreamBuilder(
                      stream: _streamController.stream,
                      builder: (context, AsyncSnapshot snapshot) {
                        if (isLoading ||
                            snapshot.connectionState ==
                                ConnectionState.waiting) {
                          return SizedBox(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: SpinKitPulse(
                              color: MAINCOLOR,
                              size: 60,
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else if (!snapshot.hasData || snapshot.data.isEmpty) {
                          return SizedBox(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: const Center(
                              child: Text(
                                "لا يوجد شحنات",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          );
                        } else {
                          var shipments = snapshot.data;
                          return ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: shipments.length,
                            itemBuilder: (context, int index) {
                              return ShipmentCard(
                                tracking_number:
                                    shipments[index]["id"].toString(),
                                id: shipments[index]["id"] ?? 1,
                                lattitude:
                                    shipments[index]["lattitude"].toString(),
                                longitude:
                                    shipments[index]["longitude"].toString(),
                                quantity: shipments[index]["items_length"] ?? 0,
                                from: shipments[index]["restaurant"] == null
                                    ? "-"
                                    : shipments[index]["restaurant"]["name"] ??
                                        "-",
                                to: shipments[index]["customer_name"] ?? "-",
                                status: shipments[index]["status"] ?? "-",
                                productsArray: shipments[index]["items"] ?? "-",
                                type: shipments[index]["type"] ?? "-",
                                business_name: shipments[index]["restaurant"] ==
                                        null
                                    ? "-"
                                    : shipments[index]["restaurant"]["name"] ??
                                        "-",
                                business_phone:
                                    shipments[index]["restaurant"] == null
                                        ? "-"
                                        : shipments[index]["restaurant"]
                                                ["phone_number"] ??
                                            "-",
                                consignee_name:
                                    shipments[index]["customer_name"] ?? "-",
                                consignee_phone1:
                                    shipments[index]["mobile"] ?? "-",
                                consignee_phone2:
                                    shipments[index]["mobile"] ?? "-",
                                items_description: "-",
                                cod_amount: double.parse(
                                    shipments[index]["total"].toString()),
                                createdAt:
                                    shipments[index]["created_at"] ?? "-",
                                updatedAt:
                                    shipments[index]["updated_at"] ?? "-",
                                customerAdress:
                                    shipments[index]["address"] ?? "-",
                                customerNear: shipments[index]["area"] ?? "-",
                                resturantAdress:
                                    shipments[index]["restaurant"] == null
                                        ? "-"
                                        : shipments[index]["restaurant"]
                                                ["address"] ??
                                            "-",
                              );
                            },
                          );
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

  Stack notificationCard({int count = 0}) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Notifications()));
          },
          icon: const Icon(
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
            decoration:
                const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
            child: Center(
              child: Text(
                count.toString(),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
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
          fetchShipments(false);
          setState(() {});
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
              border: Border.all(
                  color: clicked[index] ? MAINCOLOR : const Color(0xffDDDDDD)),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                name,
                style: TextStyle(
                    color:
                        clicked[index] ? MAINCOLOR : const Color(0xffA1A1A1)),
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
    String createdAt = "",
    String updatedAt = "",
    String resturantAdress = "",
    String customerAdress = "",
    String customerNear = "",
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
                        createdAt: createdAt,
                        updatedAt: updatedAt,
                        customerAdress: customerAdress,
                        customerNear: customerNear,
                        resturantAdress: resturantAdress,
                      )));
        },
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: status == "delivered" ||
                      status == "canceled" ||
                      status == "returned"
                  ? 180
                  : 240,
              width: double.infinity,
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 1),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(right: 15, left: 15, top: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tracking_number,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          width: 120,
                          height: 30,
                          decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 241, 241, 241),
                              border:
                                  Border.all(color: const Color(0xffDDDDDD))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Image.asset(
                                "assets/box.png",
                                height: 15,
                                fit: BoxFit.cover,
                              ),
                              Text(
                                  "$quantity ${AppLocalizations.of(context)!.shipments_card}"),
                            ],
                          ),
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
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          AppLocalizations.of(context)!.from,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          from,
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          AppLocalizations.of(context)!.to,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          height: 20,
                          child: Text(
                            to.length > 25 ? '${to.substring(0, 25)}...' : to,
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                      color: const Color.fromARGB(255, 228, 227, 227),
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
                            const SizedBox(
                              width: 10,
                            ),
                            Column(
                              children: [
                                Text(
                                  type.toString() == "load"
                                      ? "ادفع للمطعم"
                                      : "استلم من الزبون",
                                  style: const TextStyle(
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
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: MAINCOLOR)),
                            width: 150,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .shipment_details,
                                    style: TextStyle(color: MAINCOLOR),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 20,
                                    color: MAINCOLOR,
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Visibility(
                    visible: status == "delivered" ||
                            status == "canceled" ||
                            status == "returned"
                        ? false
                        : true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SizedBox(
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
                                        content: const Text(
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
                                                onTap: () {
                                                  changeOrderStatus(
                                                      tracking_number,
                                                      "canceled");

                                                  Navigator.of(context).pop();
                                                },
                                                child: Container(
                                                  height: 50,
                                                  width: 100,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      color: MAINCOLOR),
                                                  child: const Center(
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
                                                  child: const Center(
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
                                  decoration:
                                      const BoxDecoration(color: Colors.red),
                                  child: const Center(
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
                                        content: const Text(
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
                                                onTap: () {
                                                  changeOrderStatus(
                                                      tracking_number,
                                                      "delivered");

                                                  Navigator.of(context).pop();
                                                },
                                                child: Container(
                                                  height: 50,
                                                  width: 100,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      color: MAINCOLOR),
                                                  child: const Center(
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
                                                  child: const Center(
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
                                  decoration:
                                      BoxDecoration(color: Colors.green),
                                  child: const Center(
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
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(
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

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: MAINCOLOR,
            ),
            child: Column(
              children: [
                const Text(
                  'أهلا و سهلا بكم في تطبيق              J-Food Business',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 10,
                ),
                Image.asset(
                  "assets/logo.png",
                  height: 70,
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(driverName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            trailing: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: MAINCOLOR)),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text("# $driverSerial",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
          ),
          Divider(
            color: MAINCOLOR,
          ),
          ListTile(
            title: Text(status ? "السائق متاح" : "السائق غير متاح",
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
            trailing: Switch(
              activeColor: MAINCOLOR,
              value: status,
              onChanged: (val) {
                setState(() {
                  status = val;
                });
                updateSalesmanStatus(val);
              },
            ),
          ),
          Divider(
            color: MAINCOLOR,
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: MAINCOLOR,
            ),
            title: const Text('تسجيل الخروج',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
            onTap: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('login', false);
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => true);
            },
          ),
        ],
      ),
    );
  }
}

class ProductDetailsBottomSheet extends StatelessWidget {
  var productsArray, total;

  ProductDetailsBottomSheet(
      {super.key, required this.productsArray, required this.total});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
            child: Column(
              children: [
                const Row(
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
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      width: 50,
                    ),
                    Text(
                      "المجموع الكلي : $total",
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: productsArray.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final product = productsArray[index];

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Visibility(
                            visible: product["product"] == null ? false : true,
                            child: Expanded(
                              child: Image.network(
                                product["product"] == null
                                    ? "-"
                                    : product["product"]['image'],
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product["product"] == null
                                      ? "-"
                                      : "أسم المنتج : ${product["product"]['name']}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  product["product"] == null
                                      ? "-"
                                      : "سعر المنتج : ${product["product"]['price']}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  product["product"] == null
                                      ? "-"
                                      : "الكمية : ${product['qty']}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  product["product"] == null
                                      ? "-"
                                      : "المكونات:",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Visibility(
                                  visible:
                                      product["product"] == null ? false : true,
                                  child: SizedBox(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: product['components'].length,
                                      itemBuilder: (context, index) {
                                        final component =
                                            product['components'][index];
                                        return Text(
                                          "- ${component['com_name']}: ${component['com_price']}.",
                                          style: const TextStyle(fontSize: 14),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  product["product"] == null
                                      ? "-"
                                      : "المشروبات:",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Visibility(
                                  visible:
                                      product["product"] == null ? false : true,
                                  child: SizedBox(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: product['drinks'].length,
                                      itemBuilder: (context, index) {
                                        final drink = product['drinks'][index];
                                        return Text(
                                          "- ${drink['drink_name']}: ${drink['drink_price']}.",
                                          style: const TextStyle(fontSize: 14),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

// class SearchDialog {
//   void showBottomDialog(BuildContext context) {
//     showGeneralDialog(
//       barrierLabel: "showGeneralDialog",
//       barrierDismissible: true,
//       barrierColor: Colors.black.withOpacity(0.6),
//       transitionDuration: const Duration(milliseconds: 400),
//       context: context,
//       pageBuilder: (context, _, __) {
//         return const Align(
//           alignment: Alignment.bottomCenter,
//           child: SearchScreen(),
//         );
//       },
//       transitionBuilder: (_, animation1, __, child) {
//         return SlideTransition(
//           position: Tween(
//             begin: const Offset(0, 1),
//             end: const Offset(0, 0),
//           ).animate(animation1),
//           child: child,
//         );
//       },
//     );
//   }
// }
