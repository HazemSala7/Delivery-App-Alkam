import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:optimus_opost/Constants/constants.dart';

class DriverOrders extends StatefulWidget {
  final String userId;
  final String userName;
  const DriverOrders({super.key, required this.userId, required this.userName});

  @override
  State<DriverOrders> createState() => _DriverOrdersState();
}

class _DriverOrdersState extends State<DriverOrders> {
  DateTime selectedDate = DateTime.now();

  int totalOrders = 0;
  double totalCash = 0.0;
  List<dynamic> orders = [];
  int currentPage = 1;
  int lastPage = 1;
  final ScrollController _scrollController = ScrollController();
  bool isLoadingMore = false;
  bool isLoading = false;

  Future<void> _fetchOrders({bool loadMore = false}) async {
    if (loadMore && (isLoadingMore || currentPage >= lastPage)) return;

    if (loadMore) {
      setState(() => isLoadingMore = true);
      currentPage++;
    } else {
      setState(() => isLoading = true);
      currentPage = 1;
      orders.clear();
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final url = Uri.parse(
        "https://hrsps.com/login/api/salesmen/${widget.userId}/orders/summary?date=$dateStr&page=$currentPage");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        totalOrders = data["total_orders"] ?? 0;
        totalCash = double.tryParse(data["total_value"].toString()) ?? 0.0;
        if (loadMore) {
          orders.addAll(data["orders"]["data"] ?? []);
        } else {
          orders = data["orders"]["data"] ?? [];
        }
        currentPage = data["orders"]["current_page"];
        lastPage = data["orders"]["last_page"];
        isLoadingMore = false;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      throw Exception("Failed to load orders");
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: MAINCOLOR,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        currentPage = 1;
      });
      await _fetchOrders();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchOrders();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !isLoadingMore) {
        _fetchOrders(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MAINCOLOR,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text(
              "جميع الطلبيات",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: MAINCOLOR,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "السائق: ${widget.userName}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: MAINCOLOR,
                      ),
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label:
                          Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Summary card
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Text("عدد الطلبيات",
                                style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),
                            Text("$totalOrders",
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("المجموع",
                                style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(totalCash.toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Text("الطلبيات",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Expanded(
                        child: orders.isEmpty
                            ? const Center(
                                child: Text(
                                  "لا يوجد طلبيات في هذا اليوم",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            : SingleChildScrollView(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  border: TableBorder.all(
                                      color: Colors.grey.shade300),
                                  columns: const [
                                    DataColumn(
                                        label: Text(
                                      "رقم الطلب",
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      "اسم الزبون",
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      "اسم المطعم",
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      "المجموع",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    )),
                                  ],
                                  rows: orders
                                      .map((order) => DataRow(cells: [
                                            DataCell(Text(
                                              order["id"].toString(),
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            )),
                                            DataCell(Text(
                                              order["customer_name"] ?? "",
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            )),
                                            DataCell(Text(
                                              order["restaurant"]["name"]
                                                  .toString(),
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            )),
                                            DataCell(Text(
                                              "${order["total"]}",
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            )),
                                          ]))
                                      .toList(),
                                ),
                              ),
                      ),

                if (isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
