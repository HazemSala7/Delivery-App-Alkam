import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimus_opost/Constants/constants.dart';
import 'package:optimus_opost/Pages/login_screen/login_screen.dart';
import 'package:optimus_opost/Pages/notifications/notifications.dart';
import 'package:optimus_opost/Pages/shipments/driver_orders/driver_orders.dart';
import 'package:optimus_opost/Pages/shipments/shipment_card_widget.dart';
import 'package:optimus_opost/Server/server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Server/functions.dart';
// ignore: depend_on_referenced_packages
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
  TextEditingController searchController = TextEditingController();
  String salesmanId = "";
  bool isLoading = false;
  late StreamController<List<dynamic>> _streamController;
  Timer? _timer;
  bool status = false;
  String driverSerial = "";
  String driverName = "";
  List<dynamic> previousShipments = [];
  List<String> seenShipmentIds = [];
  int currentPage = 1;
  bool hasMorePages = true;
  final ScrollController _scrollController = ScrollController();
  final String _PREF_PENDING_AUTO_REJECT = 'pending_auto_reject';
  List<String> rejectedShipmentIds = [];
  List<Map<String, dynamic>> _newShipmentsQueue = [];
  Map<String, Timer> _autoRejectTimers = {}; // Renamed from _autoDismissTimers
  Map<String, Timer> _hideButtonTimers = {};
  List<Map<String, dynamic>> _activeShipments = [];
  Map<String, bool> _showDeliveryButtonForShipment = {};
  Map<String, int> _remainingSecondsForShipment = {};

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<dynamic>>();
    status = widget.status == "true";
    // restore auto-reject timers from prefs before first fetch
    _restoreAutoRejectTimers();
    // initial load
    loadData();
    // restore any existing delivery button hide timers
    _checkDeliveryButtonTimer();
    // poll periodically for updates
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      if (!mounted) return;
      await fetchShipments(false, page: 1);
    });
  }

  /// Restore/hydrate any delivery-button hide timers previously saved in prefs.
  Future<void> _checkDeliveryButtonTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final hideTimes = prefs.getStringList('delivery_button_hide_times') ?? [];

    // Cancel and clear previous timers/state
    _hideButtonTimers.forEach((_, t) => t.cancel());
    _hideButtonTimers.clear();
    _showDeliveryButtonForShipment.clear();
    _remainingSecondsForShipment.clear();

    final hideTimesCopy = List<String>.from(hideTimes);
    final hideTimesToRemove = <String>[];

    for (var entry in hideTimesCopy) {
      final parts = entry.split('|');
      if (parts.length != 2) continue;
      final shipmentId = parts[0];
      final hideTimeMillis = int.tryParse(parts[1]);
      if (hideTimeMillis == null) continue;

      final endTime = DateTime.fromMillisecondsSinceEpoch(hideTimeMillis);
      final now = DateTime.now();

      if (now.isBefore(endTime)) {
        // mark initially
        _showDeliveryButtonForShipment[shipmentId] = false;
        _remainingSecondsForShipment[shipmentId] =
            endTime.difference(now).inSeconds;

        // create a per-second timer that updates the remaining seconds and when complete, toggles show
        _hideButtonTimers[shipmentId]?.cancel();
        _hideButtonTimers[shipmentId] =
            Timer.periodic(const Duration(seconds: 1), (t) {
          final current = DateTime.now();
          if (current.isBefore(endTime)) {
            if (!mounted) return;
            setState(() {
              _remainingSecondsForShipment[shipmentId] =
                  endTime.difference(current).inSeconds;
            });
          } else {
            t.cancel();
            _hideButtonTimers.remove(shipmentId);
            if (!mounted) return;
            setState(() {
              _showDeliveryButtonForShipment[shipmentId] = true;
              _remainingSecondsForShipment[shipmentId] = 0;
            });
            hideTimesToRemove.add(entry);
          }
        });
      } else {
        // already expired
        _showDeliveryButtonForShipment[shipmentId] = true;
        _remainingSecondsForShipment[shipmentId] = 0;
        hideTimesToRemove.add(entry);
      }
    }

    if (hideTimesToRemove.isNotEmpty) {
      final newHideTimes =
          hideTimes.where((e) => !hideTimesToRemove.contains(e)).toList();
      await prefs.setStringList('delivery_button_hide_times', newHideTimes);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoRejectTimers.forEach((_, t) => t.cancel());
    _hideButtonTimers.forEach((_, t) => t.cancel());
    if (!_streamController.isClosed) {
      _streamController.close();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      salesmanId = prefs.getString('salesmanId') ?? "";
      driverName = prefs.getString('driver_name') ?? "";
      driverSerial = prefs.getString('driver_serial') ?? "";
      seenShipmentIds = prefs.getStringList('seenShipmentIds') ?? [];
      rejectedShipmentIds = prefs.getStringList('rejectedShipmentIds') ?? [];
      isLoading = true;
    });

    await fetchShipments(false, page: 1);
  }

  /// Helper to persist seen id in SharedPreferences (idempotent)
  Future<void> _markSeenId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    seenShipmentIds = prefs.getStringList('seenShipmentIds') ?? [];
    if (!seenShipmentIds.contains(id)) {
      seenShipmentIds.add(id);
      await prefs.setStringList('seenShipmentIds', seenShipmentIds);
    }
  }

  /// Helper to remove id from seen list (idempotent)
  Future<void> _unmarkSeenId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('seenShipmentIds') ?? [];
    if (list.contains(id)) {
      list.remove(id);
      await prefs.setStringList('seenShipmentIds', list);
      // update in-memory copy too
      seenShipmentIds = list;
    } else {
      // still ensure in-memory
      seenShipmentIds = list;
    }
  }

  Future<void> fetchShipments(bool fromChange, {int page = 1}) async {
    try {
      if (page == 1 && !fromChange) {
        if (mounted) setState(() => isLoading = true);
      }

      final String url = "$URL_SHIPMENTS/$salesmanId?page=$page";
      final response = await getRequest(url);
      print(url);
      if (response != null &&
          response["orders"] != null &&
          response["orders"]["data"] is List) {
        final List<dynamic> newShipments =
            List<dynamic>.from(response["orders"]["data"]);

        int lastPage = response["orders"]["last_page"] ?? 1;
        currentPage = response["orders"]["current_page"] ?? 1;
        hasMorePages = currentPage < lastPage;

        // Load seenIDs from prefs (source of truth)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        seenShipmentIds = prefs.getStringList('seenShipmentIds') ?? [];
        rejectedShipmentIds = prefs.getStringList('rejectedShipmentIds') ?? [];
        List<String> activeIds = prefs.getStringList('activeShipmentIds') ?? [];
        final pendingRejects = await _getPendingAutoRejectMap();

        final List<Map<String, dynamic>> tmpActive = [];
        final List<Map<String, dynamic>> tmpNewQueue = [];

        for (var shipment in newShipments) {
          final String id = shipment["id"].toString();
          final String status = shipment["status"]?.toString() ?? "";

          // If server reports delivered/canceled, clean up any local state
          if (status == "delivered" || status == "canceled") {
            // remove from seen/active/pending and cancel timers
            if (seenShipmentIds.contains(id)) {
              seenShipmentIds.remove(id);
            }
            if (activeIds.contains(id)) {
              activeIds.remove(id);
            }
            _autoRejectTimers[id]?.cancel();
            _autoRejectTimers.remove(id);
            await _removePendingAutoReject(id);
            await prefs.setStringList('seenShipmentIds', seenShipmentIds);
            await prefs.setStringList('activeShipmentIds', activeIds);
            continue;
          }

          if (rejectedShipmentIds.contains(id)) {
            rejectedShipmentIds.remove(id);
            await prefs.setStringList(
                'rejectedShipmentIds', rejectedShipmentIds);
          }

          // Confirmed/active shipments
          if (activeIds.contains(id) || seenShipmentIds.contains(id)) {
            tmpActive.add(Map<String, dynamic>.from(shipment));
            continue;
          }

          // Pending (we saw this earlier and persisted an auto-reject time)
          if (pendingRejects.containsKey(id)) {
            tmpNewQueue.add(Map<String, dynamic>.from(shipment));
            // restore timer if it's not in memory
            if (_autoRejectTimers[id] == null) {
              _startAutoRejectTimer(id, endTimeMillis: pendingRejects[id]);
            }
            continue;
          }

          // Brand-new shipment: add to new queue and create persisted auto-reject timer
          tmpNewQueue.add(Map<String, dynamic>.from(shipment));
          _startAutoRejectTimer(
              id); // will persist pending entry with default 20s expiry
        }

// Persist seen/active changes if any were modified above
        await prefs.setStringList('seenShipmentIds', seenShipmentIds);
        await prefs.setStringList('activeShipmentIds', activeIds);

// Commit to in-memory lists and push to stream
        if (!mounted) return;
        setState(() {
          _activeShipments = tmpActive;
          _newShipmentsQueue = tmpNewQueue;
        });

// push to stream (new first)
        if (!_streamController.isClosed) {
          _streamController.add([..._newShipmentsQueue, ..._activeShipments]);
        }
      } else {
        if (!_streamController.isClosed) _streamController.add([]);
      }
    } catch (e, st) {
      if (!_streamController.isClosed) {
        _streamController.addError('Failed to load shipments');
      }
      debugPrint("fetchShipments error: $e\n$st");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<dynamic> postRequest(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed POST with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint("POST request error: $e");
      return null;
    }
  }

  Future<void> confirmShipment(String shipmentId) async {
    try {
      final res = await postRequest("$URL_CONFIRM_SHIPMENT/$shipmentId", {});
      if (res != null && res["status"] == true) {
        // remove pending auto-reject and cancel timer
        _autoRejectTimers[shipmentId]?.cancel();
        _autoRejectTimers.remove(shipmentId);
        await _removePendingAutoReject(shipmentId);

        // persist that it's seen/confirmed (accepted)
        await _markSeenId(shipmentId);

        // move locally from new -> active if present
        if (mounted) {
          setState(() {
            final matchedIndex = _newShipmentsQueue
                .indexWhere((s) => s["id"].toString() == shipmentId);
            if (matchedIndex != -1) {
              final item =
                  Map<String, dynamic>.from(_newShipmentsQueue[matchedIndex]);
              _newShipmentsQueue.removeAt(matchedIndex);
              if (!_activeShipments
                  .any((s) => s["id"].toString() == shipmentId)) {
                _activeShipments.add(item);
              }
            }
          });
        }

        // persist activeShipmentIds
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> activeIds = prefs.getStringList('activeShipmentIds') ?? [];
        if (!activeIds.contains(shipmentId)) {
          activeIds.add(shipmentId);
          await prefs.setStringList('activeShipmentIds', activeIds);
        }

        // Refresh from server to make sure status is consistent
        if (mounted) await fetchShipments(false, page: 1);

        Fluttertoast.showToast(msg: "تم استقبال الطلب");
      } else {
        Fluttertoast.showToast(msg: "حدث مشكلة اثناء تأكيد استقبال الطلب");
      }
    } catch (e) {
      debugPrint("Error confirming shipment: $e");
      Fluttertoast.showToast(msg: "حدث خطأ أثناء تأكيد الطلب");
    }
  }

  /// Start the delivery button hide timer for 2 minutes (preserves state in prefs)
  Future<void> startDeliveryButtonTimer(String shipmentId) async {
    final prefs = await SharedPreferences.getInstance();
    final hideTime = DateTime.now().add(const Duration(minutes: 2));

    List<String> hideTimes =
        prefs.getStringList('delivery_button_hide_times') ?? [];
    // keep only latest entry for this id
    hideTimes.removeWhere((e) => e.startsWith("$shipmentId|"));
    hideTimes.add("$shipmentId|${hideTime.millisecondsSinceEpoch}");
    await prefs.setStringList('delivery_button_hide_times', hideTimes);

    if (!mounted) return;
    setState(() {
      _showDeliveryButtonForShipment[shipmentId] = false;
      _remainingSecondsForShipment[shipmentId] = 120;
    });

    // cancel previous timer for this shipment if any
    _hideButtonTimers[shipmentId]?.cancel();
    _hideButtonTimers[shipmentId] =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now();
      // re-read end time from prefs in case app restarted or value changed
      final stored = (await SharedPreferences.getInstance())
              .getStringList('delivery_button_hide_times') ??
          [];
      final entry = stored.firstWhere((e) => e.startsWith("$shipmentId|"),
          orElse: () => "");
      if (entry.isEmpty) {
        timer.cancel();
        _hideButtonTimers.remove(shipmentId);
        if (!mounted) return;
        setState(() {
          _showDeliveryButtonForShipment[shipmentId] = true;
          _remainingSecondsForShipment[shipmentId] = 0;
        });
        return;
      }
      final millis = int.tryParse(entry.split('|').elementAt(1).trim()) ?? 0;
      final end = DateTime.fromMillisecondsSinceEpoch(millis);

      if (now.isBefore(end)) {
        if (!mounted) return;
        setState(() {
          _remainingSecondsForShipment[shipmentId] =
              end.difference(now).inSeconds;
        });
      } else {
        timer.cancel();
        _hideButtonTimers.remove(shipmentId);
        if (!mounted) return;
        setState(() {
          _showDeliveryButtonForShipment[shipmentId] = true;
          _remainingSecondsForShipment[shipmentId] = 0;
        });
        hideTimes.removeWhere((e) => e.startsWith("$shipmentId|"));
        await prefs.setStringList('delivery_button_hide_times', hideTimes);
      }
    });
  }

  void _startAutoRejectTimer(String shipmentId, {int? endTimeMillis}) {
    // cancel existing timer if any
    _autoRejectTimers[shipmentId]?.cancel();

    final now = DateTime.now();
    final int endMillis = endTimeMillis ??
        now.add(const Duration(seconds: 20)).millisecondsSinceEpoch;
    final end = DateTime.fromMillisecondsSinceEpoch(endMillis);
    final dur = end.difference(now);

    if (dur <= Duration.zero) {
      // already expired — trigger immediate rejection
      _removePendingAutoReject(shipmentId);
      _rejectShipmentFromTimer(shipmentId);
      return;
    }

    // persist pending info so it survives hot restart
    _persistPendingAutoReject(shipmentId, endMillis);

    _autoRejectTimers[shipmentId] = Timer(dur, () async {
      _autoRejectTimers.remove(shipmentId);
      await _removePendingAutoReject(shipmentId);
      if (!mounted) return;
      await _rejectShipmentFromTimer(shipmentId);
    });
  }

  Future<void> _rejectShipmentFromTimer(String shipmentId) async {
    try {
      final res = await postRequest("$URL_REJECT_SHIPMENT/$shipmentId", {});
      if (res != null && res["status"] == true) {
        Fluttertoast.showToast(msg: "تم رفض الطلب", timeInSecForIosWeb: 3);

        // persist rejected id
        SharedPreferences prefs = await SharedPreferences.getInstance();
        rejectedShipmentIds = prefs.getStringList('rejectedShipmentIds') ?? [];
        if (!rejectedShipmentIds.contains(shipmentId)) {
          rejectedShipmentIds.add(shipmentId);
          await prefs.setStringList('rejectedShipmentIds', rejectedShipmentIds);
        }

        // remove pending and cancel timer
        await _removePendingAutoReject(shipmentId);
        _autoRejectTimers[shipmentId]?.cancel();
        _autoRejectTimers.remove(shipmentId);

        // remove from visible queues
        if (mounted) {
          setState(() {
            _newShipmentsQueue
                .removeWhere((s) => s["id"].toString() == shipmentId);
            _activeShipments
                .removeWhere((s) => s["id"].toString() == shipmentId);
          });
        }

        if (!_streamController.isClosed) {
          _streamController.add([..._newShipmentsQueue, ..._activeShipments]);
        }
      } else {
        debugPrint("Failed to auto-reject shipment $shipmentId");
      }
    } catch (e) {
      debugPrint("Error auto-rejecting shipment: $e");
    }
  }

  /// --- Helpers to persist/restore pending auto-reject entries
  Future<Map<String, int>> _getPendingAutoRejectMap() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_PREF_PENDING_AUTO_REJECT) ?? [];
    final map = <String, int>{};
    for (var e in list) {
      final parts = e.split('|');
      if (parts.length != 2) continue;
      final id = parts[0];
      final millis = int.tryParse(parts[1]) ?? 0;
      map[id] = millis;
    }
    return map;
  }

  Future<void> _persistPendingAutoReject(String id, int endMillis) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_PREF_PENDING_AUTO_REJECT) ?? [];
    list.removeWhere((e) => e.startsWith('$id|'));
    list.add('$id|$endMillis');
    await prefs.setStringList(_PREF_PENDING_AUTO_REJECT, list);
  }

  Future<void> _removePendingAutoReject(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_PREF_PENDING_AUTO_REJECT) ?? [];
    list.removeWhere((e) => e.startsWith('$id|'));
    await prefs.setStringList(_PREF_PENDING_AUTO_REJECT, list);
  }

  /// Restores timers from persisted pending list. If an entry already expired,
  /// it triggers immediate rejection.
  Future<void> _restoreAutoRejectTimers() async {
    final pending = await _getPendingAutoRejectMap();
    final now = DateTime.now();
    for (final entry in pending.entries.toList()) {
      final id = entry.key;
      final endMillis = entry.value;
      final end = DateTime.fromMillisecondsSinceEpoch(endMillis);

      if (now.isBefore(end)) {
        // schedule the timer to fire at the persisted expiry
        _autoRejectTimers[id]?.cancel();
        final dur = end.difference(now);
        _autoRejectTimers[id] = Timer(dur, () async {
          _autoRejectTimers.remove(id);
          await _removePendingAutoReject(id);
          if (!mounted) return;
          await _rejectShipmentFromTimer(id);
        });
      } else {
        // expired while app was closed -> reject immediately
        await _removePendingAutoReject(id);
        if (!mounted) continue;
        await _rejectShipmentFromTimer(id);
      }
    }
  }

  Future<void> changeOrderStatus(
      String orderId, String newStatus, int userId, String msg) async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://hrsps.com/login/api/change_order_status'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(
            <String, String>{'order_id': orderId, 'status': newStatus}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh the shipments list
        await fetchShipments(true, page: 1);

        // Send notification to user
        await sendNotification(
          userIds: [userId],
          title: 'تحديث بخصوص حالة الطلب',
          body: msg,
        );

        // If moving to in_delivery, start per-shipment delivery button timer
        if (newStatus == "in_delivery") {
          await startDeliveryButtonTimer(orderId);
        }

        // Optionally update local active shipments list
        if (mounted) {
          setState(() {
            int index = _activeShipments
                .indexWhere((s) => s["id"].toString() == orderId);
            if (index != -1) {
              _activeShipments[index]["status"] = newStatus;
            }
            if (newStatus == "delivered") {
              _activeShipments
                  .removeWhere((s) => s["id"].toString() == orderId);
            }
          });
        }
      } else {
        throw Exception(
            'Failed to change order status: ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error changing order status');
      debugPrint('changeOrderStatus error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> sendNotification({
    required List<int> userIds,
    required String title,
    required String body,
  }) async {
    String notificationUrl = URL_SEND_NOTIFICATION;

    try {
      final response = await http.post(
        Uri.parse(notificationUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_ids': userIds,
          'title': title,
          'body': body,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Notification sent successfully');
      } else {
        debugPrint('Failed to send notification: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
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
        if (count > 0)
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MAINCOLOR,
      child: SafeArea(
        child: Scaffold(
          drawer: _buildDrawer(),
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: MAINCOLOR,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              "الطلبيات",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              notificationCard(count: 0),
            ],
          ),
          body: StreamBuilder<List<dynamic>>(
            stream: _streamController.stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: SpinKitPulse(color: MAINCOLOR, size: 60),
                );
              }

              final shipments = snapshot.data ?? [];

              if (shipments.isEmpty) {
                return const Center(
                  child: Text(
                    "لا يوجد شحنات حالية",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }

              List<Widget> shipmentCards = [];

              String buildItemsDescription(Map<String, dynamic> shipment) {
                if (shipment["items"] != null && shipment["items"] is List) {
                  return (shipment["items"] as List)
                      .map((item) => item["product"]?["name"] ?? "")
                      .join(", ");
                }
                return "";
              }

              for (var s in _newShipmentsQueue) {
                final id = s["id"].toString();
                shipmentCards.add(
                  ShipmentCardWidget(
                    key: ValueKey(id), // Unique key per shipment
                    newOrder: true,
                    trackingNumber: id,
                    id: s["id"] ?? 0,
                    from: s["restaurant"]?["name"] ?? "-",
                    to: s["customer_name"] ?? "-",
                    status: s["status"] ?? "-",
                    userId: s["user_id"] ?? 1,
                    shipment: s,
                    newShipmentsQueue: _newShipmentsQueue,
                    showDeliveryButtonForShipment:
                        _showDeliveryButtonForShipment,
                    remainingSecondsForShipment: _remainingSecondsForShipment,
                    autoDismissTimers: _autoRejectTimers,
                    activeShipments: _activeShipments,
                    confirmShipment: confirmShipment,
                    changeOrderStatus: changeOrderStatus,
                    mainColor: MAINCOLOR,
                    productsArray: s,
                    lattitude: s["lattitude"]?.toString() ??
                        s["restaurant"]?["lattitude"]?.toString() ??
                        "",
                    longitude: s["longitude"]?.toString() ??
                        s["restaurant"]?["longitude"]?.toString() ??
                        "",
                    businessName: s["restaurant"]?["name"] ?? "-",
                    businessPhone: s["restaurant"]?["phone_number"] ?? "-",
                    consigneeName: s["customer_name"] ?? "-",
                    consigneePhone1: s["mobile"] ?? "",
                    consigneePhone2: s["mobile_2"] ?? "",
                    itemsDescription: buildItemsDescription(s),
                    codAmount: s["total"] != null
                        ? double.tryParse(s["total"].toString()) ?? 0.0
                        : 0.0,
                    type: s["type"] ?? "",
                    quantity: s["items_length"] ?? 0,
                    createdAt: s["created_at"] ?? "",
                    updatedAt: s["updated_at"] ?? "",
                    resturantAdress: s["restaurant"]?["address"] ?? "",
                    customerAdress: s["area"] ?? "",
                    customerNear: s["address"] ?? "",
                  ),
                );
              }

              for (var s in _activeShipments) {
                final id = s["id"].toString();
                shipmentCards.add(
                  ShipmentCardWidget(
                    key: ValueKey(id),
                    newOrder: false,
                    trackingNumber: id,
                    id: s["id"] ?? 0,
                    from: s["restaurant"]?["name"] ?? "-",
                    to: s["customer_name"] ?? "-",
                    status: s["status"] ?? "-",
                    userId: s["user_id"] ?? 1,
                    shipment: s,
                    newShipmentsQueue: _newShipmentsQueue,
                    showDeliveryButtonForShipment:
                        _showDeliveryButtonForShipment,
                    remainingSecondsForShipment: _remainingSecondsForShipment,
                    autoDismissTimers: _autoRejectTimers,
                    activeShipments: _activeShipments,
                    confirmShipment: confirmShipment,
                    changeOrderStatus: changeOrderStatus,
                    mainColor: MAINCOLOR,
                    productsArray: s,
                    lattitude: s["lattitude"]?.toString() ??
                        s["restaurant"]?["lattitude"]?.toString() ??
                        "",
                    longitude: s["longitude"]?.toString() ??
                        s["restaurant"]?["longitude"]?.toString() ??
                        "",
                    businessName: s["restaurant"]?["name"] ?? "-",
                    businessPhone: s["restaurant"]?["phone_number"] ?? "-",
                    consigneeName: s["customer_name"] ?? "-",
                    consigneePhone1: s["mobile"] ?? "",
                    consigneePhone2: s["mobile_2"] ?? "",
                    itemsDescription: buildItemsDescription(s),
                    codAmount: s["total"] != null
                        ? double.tryParse(s["total"].toString()) ?? 0.0
                        : 0.0,
                    type: s["type"] ?? "",
                    quantity: s["items_length"] ?? 0,
                    createdAt: s["created_at"] ?? "",
                    updatedAt: s["updated_at"] ?? "",
                    resturantAdress: s["restaurant"]?["address"] ?? "",
                    customerAdress: s["area"] ?? "",
                    customerNear: s["address"] ?? "",
                  ),
                );
              }

              // 🟨 Return scrollable list of cards
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: shipmentCards,
                ),
              );
            },
          ),
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
            leading: Icon(
              Icons.list_sharp,
              color: MAINCOLOR,
            ),
            title: const Text('طلبيات السائق',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
            onTap: () async {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DriverOrders(
                    userId: salesmanId,
                    userName: driverName,
                  ),
                ),
              );
            },
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
  var productsArray, total, deliveryPrice, mealsPrice;

  ProductDetailsBottomSheet(
      {super.key,
      required this.productsArray,
      required this.total,
      required this.deliveryPrice,
      required this.mealsPrice});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
          child: Column(
            children: [
              const Row(
                children: [
                  Text(
                    "تفاصيل الطلبية",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              Row(
                children: [
                  Text(
                    "التوصيل : ${deliveryPrice} ",
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    width: 50,
                  ),
                  Text(
                    "الطلبية : ${mealsPrice} ",
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
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                product["product"] == null
                                    ? "-"
                                    : "سعر المنتج : ${product["product"]['price']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                product["product"] == null
                                    ? "-"
                                    : "الكمية : ${product['qty']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Visibility(
                                visible: product["components"].isNotEmpty,
                                child: Text(
                                  product["product"] == null
                                      ? "-"
                                      : "المكونات:",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Visibility(
                                visible: product["components"].isNotEmpty,
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
                              Visibility(
                                visible: product['drinks'].isNotEmpty,
                                child: Text(
                                  product["product"] == null
                                      ? "-"
                                      : "المشروبات:",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Visibility(
                                visible: product['drinks'].isNotEmpty,
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


// Expanded(
//                               flex: 1,
//                               child: InkWell(
//                                 onTap: () {
//                                   showDialog(
//                                     context: context,
//                                     builder: (BuildContext context) {
//                                       return AlertDialog(
//                                         content: const Text(
//                                           "هل تريد بالتأكيد الغاء الطلب ؟ ",
//                                           style: TextStyle(
//                                               fontWeight: FontWeight.bold),
//                                         ),
//                                         actions: <Widget>[
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceAround,
//                                             children: [
//                                               InkWell(
//                                                 onTap: () async {
//                                                   Navigator.of(context).pop();
//                                                   await changeOrderStatus(
//                                                       tracking_number,
//                                                       "canceled",
//                                                       userId,
//                                                       'تم الغاء طلبك');
//                                                   Fluttertoast.showToast(
//                                                     msg: 'لقد تم الغاء الطلب',
//                                                     backgroundColor:
//                                                         Colors.green,
//                                                     textColor: Colors.white,
//                                                   );
//                                                 },
//                                                 child: Container(
//                                                   height: 50,
//                                                   width: 100,
//                                                   decoration: BoxDecoration(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               10),
//                                                       color: MAINCOLOR),
//                                                   child: const Center(
//                                                     child: Text(
//                                                       "نعم",
//                                                       style: TextStyle(
//                                                           fontWeight:
//                                                               FontWeight.bold,
//                                                           fontSize: 15,
//                                                           color: Colors.white),
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//                                               InkWell(
//                                                 onTap: () {
//                                                   Navigator.pop(context);
//                                                 },
//                                                 child: Container(
//                                                   height: 50,
//                                                   width: 100,
//                                                   decoration: BoxDecoration(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               10),
//                                                       color: MAINCOLOR),
//                                                   child: const Center(
//                                                     child: Text(
//                                                       "لا",
//                                                       style: TextStyle(
//                                                           fontWeight:
//                                                               FontWeight.bold,
//                                                           fontSize: 15,
//                                                           color: Colors.white),
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//                                             ],
//                                           )
//                                         ],
//                                       );
//                                     },
//                                   );
//                                 },
//                                 child: Container(
//                                   height: 40,
//                                   decoration:
//                                       const BoxDecoration(color: Colors.red),
//                                   child: const Center(
//                                     child: Text(
//                                       "الغاء الطلب",
//                                       style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.white),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),