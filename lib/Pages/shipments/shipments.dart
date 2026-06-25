import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimus_opost/Constants/constants.dart';
import 'package:optimus_opost/Pages/login_screen/login_screen.dart';
import 'package:optimus_opost/Pages/notifications/notifications.dart';
import 'package:optimus_opost/Pages/shipments/driver_orders/driver_orders.dart';
import 'package:optimus_opost/Pages/shipments/shipment_card_widget.dart';
import 'package:optimus_opost/Server/server.dart';
import 'package:optimus_opost/Server/order_refresh_bus.dart';
import 'package:optimus_opost/Server/driver_topic.dart';
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
  double _balance = 0.0;
  double _commissionRate = 0.0;
  bool _lowBalance = false;
  bool _blocked = false;
  int _ordersRemaining = -1;
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

  // --- New-order announcement / live-update plumbing ---
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _alertPlayer = AudioPlayer();
  bool _ttsReady = false;
  bool _isFetching = false;
  bool _isAppInForeground = true;
  DateTime? _lastUpdatedAt;
  // Tracks IDs we have already announced this session so we never spam.
  final Set<String> _announcedIds = <String>{};
  // Tracks the IDs of orders currently in the new-queue across polls.
  Set<String> _knownNewIds = <String>{};

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<dynamic>>();
    status = widget.status == "true";
    WidgetsBinding.instance
        .addObserver(_LifecycleHook(onResume: _onAppResumed, onPause: _onAppPaused));
    _initTts();
    // restore auto-reject timers from prefs before first fetch
    _restoreAutoRejectTimers();
    // initial load
    loadData();
    // restore any existing delivery button hide timers
    _checkDeliveryButtonTimer();
    // Poll at a reasonable cadence. Skip the tick when:
    //  * a previous fetch is still in-flight (handled by _isFetching guard)
    //  * the app is in the background (saves battery + avoids pile-up)
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) async {
      if (!mounted) return;
      if (!_isAppInForeground) return;
      if (_isFetching) return;
      await fetchShipments(false, page: 1);
    });

    // Refresh instantly when a new-order push arrives (don't wait for the
    // next 8s poll). Critical for fast/smooth updates on 3G.
    OrderRefreshBus.tick.addListener(_onPushRefresh);
  }

  void _onPushRefresh() {
    if (!mounted) return;
    fetchBalance(); // a recharge push also updates the balance
    if (_isFetching) return;
    fetchShipments(false, page: 1);
  }

  Future<void> fetchBalance() async {
    if (salesmanId.isEmpty) return;
    try {
      final res = await getRequest("$URL_DRIVER_BALANCE$salesmanId");
      if (res is Map && res["balance"] != null) {
        final b = double.tryParse(res["balance"].toString()) ?? 0.0;
        final low = res["low_balance"] == true;
        final blocked = res["blocked"] == true;
        final rate = double.tryParse(res["commission_rate"].toString()) ?? 0.0;
        final remaining = res["orders_remaining"] == null
            ? -1
            : int.tryParse(res["orders_remaining"].toString()) ?? -1;
        if (mounted) {
          setState(() {
            _balance = b;
            _commissionRate = rate;
            _lowBalance = low;
            _blocked = blocked;
            _ordersRemaining = remaining;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("ar-SA");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.05);
      _ttsReady = true;
    } catch (e) {
      debugPrint("TTS init failed: $e");
    }
  }

  Future<void> _onAppResumed() async {
    // Immediately refresh when app comes back to the foreground.
    _isAppInForeground = true;
    if (!mounted) return;
    fetchBalance();
    if (_isFetching) return;
    await fetchShipments(false, page: 1);
  }

  void _onAppPaused() {
    _isAppInForeground = false;
  }

  /// Plays a sound + speaks an Arabic announcement + buzzes the phone.
  Future<void> _announceNewOrder({String? orderId}) async {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    // System alert chime (works without any asset).
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
    // Try a louder asset chime if user provided one.
    try {
      await _alertPlayer.stop();
      await _alertPlayer.play(AssetSource('notification.mp3'),
          volume: 1.0);
    } catch (_) {
      // No asset is fine — TTS will still announce.
    }
    if (_ttsReady) {
      try {
        await _tts.stop();
        final msg = orderId == null
            ? "لديك طلب جديد"
            : "لديك طلب جديد رقم $orderId";
        await _tts.speak(msg);
      } catch (e) {
        debugPrint("TTS speak failed: $e");
      }
    }
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
    OrderRefreshBus.tick.removeListener(_onPushRefresh);
    _autoRejectTimers.forEach((_, t) => t.cancel());
    _hideButtonTimers.forEach((_, t) => t.cancel());
    try {
      _tts.stop();
    } catch (_) {}
    try {
      _alertPlayer.dispose();
    } catch (_) {}
    if (!_streamController.isClosed) {
      _streamController.close();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Resolve the salesman id used by the orders API. Older builds may have
    // saved the wrong field; fall back to driver_serial which is the value
    // the backend keys orders by (e.g. "8608").
    String resolvedSalesmanId = prefs.getString('salesmanId') ?? "";
    final serial = prefs.getString('driver_serial') ?? "";
    if (resolvedSalesmanId.trim().isEmpty && serial.trim().isNotEmpty) {
      resolvedSalesmanId = serial;
      await prefs.setString('salesmanId', resolvedSalesmanId);
    }

    setState(() {
      salesmanId = resolvedSalesmanId;
      driverName = prefs.getString('driver_name') ?? "";
      driverSerial = serial;
      seenShipmentIds = prefs.getStringList('seenShipmentIds') ?? [];
      rejectedShipmentIds = prefs.getStringList('rejectedShipmentIds') ?? [];
      isLoading = true;
    });

    debugPrint("[Shipments] resolved salesmanId='$salesmanId' "
        "driver_serial='$driverSerial'");

    await fetchShipments(false, page: 1);
    fetchBalance();
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
    if (_isFetching) return; // avoid overlap from fast polling
    _isFetching = true;
    try {
      if (page == 1 && !fromChange) {
        if (mounted) setState(() => isLoading = true);
      }

      final String url = "$URL_SHIPMENTS/$salesmanId?page=$page";
      final response = await getRequest(url);
      if (response is Map &&
          response["orders"] is Map &&
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

          // Pending (we saw this earlier and persisted an auto-reject time).
          // If the persisted window already elapsed (e.g. app was closed),
          // start a FRESH 20s window so the driver actually gets to see it.
          if (pendingRejects.containsKey(id)) {
            tmpNewQueue.add(Map<String, dynamic>.from(shipment));
            final endMillis = pendingRejects[id]!;
            final end = DateTime.fromMillisecondsSinceEpoch(endMillis);
            if (DateTime.now().isAfter(end)) {
              // stale -> reset to a fresh 20s window
              await _removePendingAutoReject(id);
              _autoRejectTimers[id]?.cancel();
              _autoRejectTimers.remove(id);
              _startAutoRejectTimer(id);
            } else if (_autoRejectTimers[id] == null) {
              _startAutoRejectTimer(id, endTimeMillis: endMillis);
            }
            continue;
          }

          // Brand-new shipment: show it for 20s and auto-reject if untouched.
          tmpNewQueue.add(Map<String, dynamic>.from(shipment));
          if (_autoRejectTimers[id] == null) {
            _startAutoRejectTimer(id);
          }
        }

// Persist seen/active changes if any were modified above
        await prefs.setStringList('seenShipmentIds', seenShipmentIds);
        await prefs.setStringList('activeShipmentIds', activeIds);

        // Detect freshly arrived orders and announce them.
        // Important: materialise the filtered iterable to a concrete List
        // BEFORE mutating _announcedIds, otherwise the lazy `where` filter
        // will re-evaluate after addAll() and yield nothing (causing a
        // `Bad state: No element` on .first).
        final newIdsThisFetch =
            tmpNewQueue.map((e) => e["id"].toString()).toSet();
        final freshIds = newIdsThisFetch.difference(_knownNewIds);
        final brandNew = freshIds
            .where((id) => !_announcedIds.contains(id))
            .toList(growable: false);
        if (brandNew.isNotEmpty) {
          _announcedIds.addAll(brandNew);
          // Announce once per batch (spoken line uses the first new id).
          // Fire-and-forget so it never blocks rendering of active orders.
          _announceNewOrder(orderId: brandNew.first);
        }
        _knownNewIds = newIdsThisFetch;

// Commit to in-memory lists and push to stream
        if (!mounted) return;
        setState(() {
          _activeShipments = tmpActive;
          _newShipmentsQueue = tmpNewQueue;
          _lastUpdatedAt = DateTime.now();
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
      _isFetching = false;
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

  /// Restores timers from persisted pending list.
  /// Important: we never auto-reject on restore. If an entry expired while the
  /// app was closed we simply drop it; the next fetch will start a fresh 20s
  /// window so the driver always gets to actually see the card.
  Future<void> _restoreAutoRejectTimers() async {
    final pending = await _getPendingAutoRejectMap();
    final now = DateTime.now();
    for (final entry in pending.entries.toList()) {
      final id = entry.key;
      final end = DateTime.fromMillisecondsSinceEpoch(entry.value);
      _autoRejectTimers[id]?.cancel();
      _autoRejectTimers.remove(id);
      if (now.isBefore(end)) {
        final dur = end.difference(now);
        _autoRejectTimers[id] = Timer(dur, () async {
          _autoRejectTimers.remove(id);
          await _removePendingAutoReject(id);
          if (!mounted) return;
          await _rejectShipmentFromTimer(id);
        });
      } else {
        // Stale -> drop. fetchShipments will assign a fresh window.
        await _removePendingAutoReject(id);
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

        // Balance changes when an order is delivered (company commission is
        // deducted server-side) — refresh it so the banner updates instantly.
        fetchBalance();

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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        drawer: _buildDrawer(),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: StreamBuilder<List<dynamic>>(
                  stream: _streamController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return Center(
                        child: SpinKitPulse(color: MAINCOLOR, size: 60),
                      );
                    }

                    final shipments = snapshot.data ?? [];

                    if (shipments.isEmpty) {
                      return _buildEmptyState();
                    }

                    String buildItemsDescription(
                        Map<String, dynamic> shipment) {
                      if (shipment["items"] != null &&
                          shipment["items"] is List) {
                        return (shipment["items"] as List)
                            .map((item) => item["product"]?["name"] ?? "")
                            .join(", ");
                      }
                      return "";
                    }

                    final List<Widget> children = [];

                    if (_newShipmentsQueue.isNotEmpty) {
                      children.add(_buildSectionHeader(
                        title: "طلبات جديدة",
                        count: _newShipmentsQueue.length,
                        icon: Icons.fiber_new_rounded,
                        accent: const Color(0xFFE67E22),
                      ));
                      for (var s in _newShipmentsQueue) {
                        children.add(_buildShipmentEntry(
                            s, true, buildItemsDescription));
                      }
                    }

                    if (_activeShipments.isNotEmpty) {
                      children.add(_buildSectionHeader(
                        title: "الطلبيات النشطة",
                        count: _activeShipments.length,
                        icon: Icons.local_shipping_rounded,
                        accent: const Color(0xFF27AE60),
                      ));
                      for (var s in _activeShipments) {
                        children.add(_buildShipmentEntry(
                            s, false, buildItemsDescription));
                      }
                    }

                    return RefreshIndicator(
                      color: MAINCOLOR,
                      onRefresh: () => fetchShipments(false, page: 1),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MAINCOLOR,
            Color.lerp(MAINCOLOR, Colors.black, 0.25) ?? MAINCOLOR,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: MAINCOLOR.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
        child: Column(
          children: [
            Row(
              children: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "الطلبيات",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        driverName.isEmpty ? "مرحباً بك" : "مرحباً، $driverName",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _buildLiveIndicator(),
                    ],
                  ),
                ),
                notificationCard(count: 0),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.fiber_new_rounded,
                    label: "طلبات جديدة",
                    value: _newShipmentsQueue.length.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    icon: Icons.local_shipping_rounded,
                    label: "نشطة",
                    value: _activeShipments.length.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    icon: Icons.badge_rounded,
                    label: "السائق",
                    value: driverSerial.isEmpty ? "-" : "#$driverSerial",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _balanceBanner(),
            if (_blocked || _lowBalance) ...[
              const SizedBox(height: 10),
              _warningBanner(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _warningBanner() {
    final bool blocked = _blocked;
    final Color bg = blocked ? const Color(0xFFB71C1C) : const Color(0xFFFF8F00);
    final IconData icon =
        blocked ? Icons.block : Icons.warning_amber_rounded;
    final String text = blocked
        ? "توقّف استقبال الطلبات — رصيدك انتهى. الرجاء شحن الرصيد لاستئناف استلام الطلبات."
        : (_ordersRemaining >= 0
            ? "رصيدك قارب على الانتهاء — يكفي لحوالي $_ordersRemaining طلبيات. الرجاء الشحن قريباً."
            : "رصيدك قارب على الانتهاء — الرجاء الشحن قريباً.");
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white, size: 26),
          const SizedBox(width: 12),
          const Text(
            "الرصيد الحالي",
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            "${_balance.toStringAsFixed(2)} شيكل",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required IconData icon,
    required Color accent,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 16, 6, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Container(
            height: 1,
            width: 40,
            color: const Color(0xFFE0E0E0),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: MAINCOLOR,
      onRefresh: () => fetchShipments(false, page: 1),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          Center(
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MAINCOLOR.withOpacity(0.08),
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 70,
                color: MAINCOLOR.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              "لا يوجد شحنات حالية",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                "اسحب للأسفل لتحديث القائمة، أو انتظر وصول طلب جديد",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7F8C8D),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentEntry(
    dynamic s,
    bool isNew,
    String Function(Map<String, dynamic>) buildItemsDescription,
  ) {
    final id = s["id"].toString();
    return ShipmentCardWidget(
      key: ValueKey(id),
      newOrder: isNew,
      trackingNumber: id,
      id: s["id"] ?? 0,
      from: s["restaurant"]?["name"] ?? "-",
      to: s["customer_name"] ?? "-",
      status: s["status"] ?? "-",
      userId: s["user_id"] ?? 1,
      shipment: s,
      newShipmentsQueue: _newShipmentsQueue,
      showDeliveryButtonForShipment: _showDeliveryButtonForShipment,
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
    );
  }

  // Legacy duplicate-card builders kept below as no-ops to preserve diff context.
  void _unusedLegacyKeep() {}

  Widget _buildLiveIndicator() {
    final updated = _lastUpdatedAt;
    final isLive = !_isFetching;
    final dotColor = isLive ? const Color(0xFF2ECC71) : const Color(0xFFF1C40F);
    String timeLabel;
    if (updated == null) {
      timeLabel = "...جاري التحميل";
    } else {
      final diff = DateTime.now().difference(updated);
      if (diff.inSeconds < 5) {
        timeLabel = "محدث الآن";
      } else if (diff.inMinutes < 1) {
        timeLabel = "محدث قبل ${diff.inSeconds} ث";
      } else {
        timeLabel = "محدث قبل ${diff.inMinutes} د";
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulsingDot(color: dotColor),
        const SizedBox(width: 6),
        Text(
          isLive ? "مباشر • $timeLabel" : "تحديث... ",
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  MAINCOLOR,
                  Color.lerp(MAINCOLOR, Colors.black, 0.3) ?? MAINCOLOR,
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: Image.asset(
                        "assets/logo.png",
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  driverName.isEmpty ? "السائق" : driverName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(
                    "# ${driverSerial.isEmpty ? '-' : driverSerial}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _drawerInfo(
            icon: Icons.percent_rounded,
            label: 'نسبة العمولة',
            value: '${_commissionRate.toStringAsFixed(_commissionRate % 1 == 0 ? 0 : 2)}%',
            valueColor: const Color(0xFFE67E22),
          ),
          _drawerInfo(
            icon: Icons.account_balance_wallet_rounded,
            label: 'الرصيد الحالي',
            value: '${_balance.toStringAsFixed(2)} شيكل',
            valueColor: _blocked
                ? Colors.red.shade700
                : (_lowBalance ? const Color(0xFFFF8F00) : const Color(0xFF218049)),
          ),
          const Divider(height: 1),
          const SizedBox(height: 4),
          _drawerItem(
            icon: Icons.list_alt_rounded,
            label: 'طلبيات السائق',
            onTap: () {
              Navigator.of(context).pop();
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
          _drawerItem(
            icon: Icons.notifications_rounded,
            label: 'الإشعارات',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const Notifications()));
            },
          ),
          const Spacer(),
          const Divider(height: 1),
          _drawerItem(
            icon: Icons.logout_rounded,
            label: 'تسجيل الخروج',
            color: Colors.red.shade600,
            onTap: () async {
              // Stop targeted pushes to THIS device after logout.
              await DriverTopic.unsubscribeForCurrentUser();
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('login', false);
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerInfo({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tint = color ?? MAINCOLOR;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: tint, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: color ?? const Color(0xFF2C3E50),
                    ),
                  ),
                ),
                Icon(Icons.chevron_left_rounded,
                    color: Colors.grey.shade400, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small pulsing dot used by the live indicator.
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final v = 0.5 + (_c.value * 0.5);
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(v),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(v * 0.7),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Lightweight WidgetsBindingObserver that pauses/resumes background work.
class _LifecycleHook with WidgetsBindingObserver {
  final Future<void> Function() onResume;
  final void Function() onPause;
  _LifecycleHook({required this.onResume, required this.onPause});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      onPause();
    }
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