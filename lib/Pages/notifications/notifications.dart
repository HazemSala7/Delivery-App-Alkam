import 'package:flutter/material.dart';
import '../../Constants/constants.dart';
import '../shipment_detail/shipment_detail.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: MAINCOLOR,
      child: SafeArea(
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: MAINCOLOR,
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                      ),
                      const Text(
                        "التنبيهات",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
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
                ),
                Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: 1,
                        itemBuilder: (context, int index) {
                          return NotificationCard(
                              title: "عنوان التنبيه",
                              body: "هذا مثال لاشعار",
                              id: 0,
                              name: "shipment.tracking_number",
                              read: "قبل 2 دقيقه");
                        })),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget NotificationCard(
      {String title = "",
      String body = "",
      String read = "",
      int id = 0,
      String name = ""}) {
    return Padding(
      padding: const EdgeInsets.only(right: 20, left: 20, top: 15),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ShipmentDetail(
                        shipment_id: id.toString(),
                        name: name.toString(),
                      )));
        },
        child: Container(
          width: double.infinity,
          // height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                                color: Color(0xffF1F1F1),
                                shape: BoxShape.circle),
                            width: 40,
                            height: 40,
                            child: Center(
                              child: Icon(
                                Icons.notifications_none,
                                color: MAINCOLOR,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          Text(
                            title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          )
                        ],
                      ),
                      Text(
                        read,
                        style: const TextStyle(color: Color(0xff999999)),
                      )
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(),
                    ),
                    Expanded(
                      flex: 6,
                      child: Text(
                        body,
                        style: const TextStyle(color: Color(0xff666666)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
