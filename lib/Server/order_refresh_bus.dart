import 'package:flutter/foundation.dart';

/// A tiny global event bus used to trigger an immediate shipments refresh
/// the moment a new-order push notification arrives — instead of waiting for
/// the next polling tick. This is the key to making new orders show up fast
/// and smoothly on slow (3G) connections.
///
/// The FCM handler in main.dart calls [ping]; the shipments screen listens on
/// [tick] and fetches right away.
class OrderRefreshBus {
  OrderRefreshBus._();

  static final ValueNotifier<int> tick = ValueNotifier<int>(0);

  /// Signal that something changed server-side (e.g. a new order push) and the
  /// shipments list should refresh now.
  static void ping() {
    tick.value = tick.value + 1;
  }
}
