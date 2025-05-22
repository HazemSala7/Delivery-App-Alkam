import 'package:flutter/material.dart';

var URL = "https://hrsps.com/login/api/";
var URL_LOGIN = URL + "login";
var URL_UPDATE_TOKEN = URL + "update-fcm-token";
var URL_SHIPMENTS = URL + "get_orders_depend_on_salesman_id";
var URL_SHIPMENTS_STATUS = URL + "filter_shipment_by_status_by_salesman";
var URL_MOBILE = URL + "consignee/oauth/token";
var URL_VERIFICATION_CODE = URL + "oauth/token";
var URL_NOTIFICATIONS = URL + "resources/user-notifications";
var URL_NOTIFICATIONS_COUNT =
    URL + "resources/user-notifications/local-action/get-count";
var URL_ADD_NOTE = URL + "resources/shipments/actions/resolve-pending";
var URL_ADD_LOCATION = URL + "consignee/tracking/shipment/location";
var URL_CONFIRM_SHIPMENT = URL + "confirm-order";
var URL_REJECT_SHIPMENT = URL + "reject-order";
var URL_SEND_NOTIFICATION = URL + "notify/specific";
