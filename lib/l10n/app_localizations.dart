import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @shipments.
  ///
  /// In en, this message translates to:
  /// **'Shipments'**
  String get shipments;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @search_in_shipments.
  ///
  /// In en, this message translates to:
  /// **'Search in shipments'**
  String get search_in_shipments;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @under_processing.
  ///
  /// In en, this message translates to:
  /// **'Under Processing'**
  String get under_processing;

  /// No description provided for @being_processed.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get being_processed;

  /// No description provided for @equipped.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get equipped;

  /// No description provided for @pending_pickup.
  ///
  /// In en, this message translates to:
  /// **'Pending pickup'**
  String get pending_pickup;

  /// No description provided for @cod_pickup.
  ///
  /// In en, this message translates to:
  /// **'Cod pickup'**
  String get cod_pickup;

  /// No description provided for @in_accounting.
  ///
  /// In en, this message translates to:
  /// **'In accounting'**
  String get in_accounting;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @picked_up.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get picked_up;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @returned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returned;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @from_date.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get from_date;

  /// No description provided for @to_date.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get to_date;

  /// No description provided for @shipments_status.
  ///
  /// In en, this message translates to:
  /// **'Shipments Status'**
  String get shipments_status;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @shipment_details.
  ///
  /// In en, this message translates to:
  /// **'Shipment Details'**
  String get shipment_details;

  /// No description provided for @payement_when_recieving.
  ///
  /// In en, this message translates to:
  /// **'Payement when recieving'**
  String get payement_when_recieving;

  /// No description provided for @shekels.
  ///
  /// In en, this message translates to:
  /// **'Shekels'**
  String get shekels;

  /// No description provided for @shipments_card.
  ///
  /// In en, this message translates to:
  /// **'Shipments'**
  String get shipments_card;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @offer.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offer;

  /// No description provided for @alqaima.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get alqaima;

  /// No description provided for @qaf.
  ///
  /// In en, this message translates to:
  /// **'Common Questions'**
  String get qaf;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contact;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms Of Use'**
  String get terms;

  /// No description provided for @who.
  ///
  /// In en, this message translates to:
  /// **'Who We Are'**
  String get who;

  /// No description provided for @favourite.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get favourite;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'My Order'**
  String get order;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy And Policy'**
  String get privacy;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @dialogl1.
  ///
  /// In en, this message translates to:
  /// **'You have to login first'**
  String get dialogl1;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'ok'**
  String get ok;

  /// No description provided for @enterphone.
  ///
  /// In en, this message translates to:
  /// **'enter phone number'**
  String get enterphone;

  /// No description provided for @enterpassword.
  ///
  /// In en, this message translates to:
  /// **'enter password'**
  String get enterpassword;

  /// No description provided for @donthaveaccount.
  ///
  /// In en, this message translates to:
  /// **'Dont have an account ? '**
  String get donthaveaccount;

  /// No description provided for @youcansignup.
  ///
  /// In en, this message translates to:
  /// **'You can sign up here '**
  String get youcansignup;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'enter username'**
  String get username;

  /// No description provided for @confirmpassword.
  ///
  /// In en, this message translates to:
  /// **'confirm password'**
  String get confirmpassword;

  /// No description provided for @youcansigninhere.
  ///
  /// In en, this message translates to:
  /// **'You can sign in here '**
  String get youcansigninhere;

  /// No description provided for @doyouhaveaccount.
  ///
  /// In en, this message translates to:
  /// **'Do you have an account ? '**
  String get doyouhaveaccount;

  /// No description provided for @logoutsure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure want to logout? '**
  String get logoutsure;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @toastlogout.
  ///
  /// In en, this message translates to:
  /// **'You have been successfully logged out'**
  String get toastlogout;

  /// No description provided for @loginsuccess.
  ///
  /// In en, this message translates to:
  /// **'You have been successfully logged in'**
  String get loginsuccess;

  /// No description provided for @loginempty.
  ///
  /// In en, this message translates to:
  /// **'phone number or password is empty'**
  String get loginempty;

  /// No description provided for @incorrectpass.
  ///
  /// In en, this message translates to:
  /// **'password is incorrct!'**
  String get incorrectpass;

  /// No description provided for @incorrectphone.
  ///
  /// In en, this message translates to:
  /// **'phonenumber is incorrect!'**
  String get incorrectphone;

  /// No description provided for @phoneorpassin.
  ///
  /// In en, this message translates to:
  /// **'phone number or password is incorrect!'**
  String get phoneorpassin;

  /// No description provided for @regempty.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all blanks'**
  String get regempty;

  /// No description provided for @regsuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account has been successfully registered'**
  String get regsuccess;

  /// No description provided for @regphonefailed.
  ///
  /// In en, this message translates to:
  /// **'The phone number entered is already registered'**
  String get regphonefailed;

  /// No description provided for @editprofile.
  ///
  /// In en, this message translates to:
  /// **'Edit my profile'**
  String get editprofile;

  /// No description provided for @deletecart.
  ///
  /// In en, this message translates to:
  /// **'It has been successfully removed from the cart'**
  String get deletecart;

  /// No description provided for @alreadydeletecart.
  ///
  /// In en, this message translates to:
  /// **'already deleted'**
  String get alreadydeletecart;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @buynow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buynow;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'price'**
  String get price;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'quantity'**
  String get qty;

  /// No description provided for @namecon.
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get namecon;

  /// No description provided for @phonecon.
  ///
  /// In en, this message translates to:
  /// **'phone number'**
  String get phonecon;

  /// No description provided for @mailcon.
  ///
  /// In en, this message translates to:
  /// **'mail'**
  String get mailcon;

  /// No description provided for @subcon.
  ///
  /// In en, this message translates to:
  /// **'subject of the message'**
  String get subcon;

  /// No description provided for @bodycon.
  ///
  /// In en, this message translates to:
  /// **'body of the message'**
  String get bodycon;

  /// No description provided for @consuccess.
  ///
  /// In en, this message translates to:
  /// **'Your message was sent successfully'**
  String get consuccess;

  /// No description provided for @confailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send the message'**
  String get confailed;

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get number;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @case1.
  ///
  /// In en, this message translates to:
  /// **'Case'**
  String get case1;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'female'**
  String get female;

  /// No description provided for @editsuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account has been successfully modified'**
  String get editsuccess;

  /// No description provided for @editfailed.
  ///
  /// In en, this message translates to:
  /// **'Edit operation failed'**
  String get editfailed;

  /// No description provided for @editsave.
  ///
  /// In en, this message translates to:
  /// **'save the changes'**
  String get editsave;

  /// No description provided for @queseditpass.
  ///
  /// In en, this message translates to:
  /// **'Do you want to change the password'**
  String get queseditpass;

  /// No description provided for @editpassword.
  ///
  /// In en, this message translates to:
  /// **'Edit PassWord'**
  String get editpassword;

  /// No description provided for @oldpassword.
  ///
  /// In en, this message translates to:
  /// **'Old PassWord'**
  String get oldpassword;

  /// No description provided for @newpassword.
  ///
  /// In en, this message translates to:
  /// **'New PassWord'**
  String get newpassword;

  /// No description provided for @confirmnewpass.
  ///
  /// In en, this message translates to:
  /// **'Confirm newpassword'**
  String get confirmnewpass;

  /// No description provided for @updatepass.
  ///
  /// In en, this message translates to:
  /// **'Update my password'**
  String get updatepass;

  /// No description provided for @dontmatch.
  ///
  /// In en, this message translates to:
  /// **'The new password does not match the password'**
  String get dontmatch;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'product'**
  String get product;

  /// No description provided for @getgeoarea.
  ///
  /// In en, this message translates to:
  /// **'Choose a geographical area'**
  String get getgeoarea;

  /// No description provided for @getarea.
  ///
  /// In en, this message translates to:
  /// **'Choose the area'**
  String get getarea;

  /// No description provided for @getcountry.
  ///
  /// In en, this message translates to:
  /// **'Choose the country'**
  String get getcountry;

  /// No description provided for @confirmbuy.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get confirmbuy;

  /// No description provided for @deliveryprice.
  ///
  /// In en, this message translates to:
  /// **'Delivery price'**
  String get deliveryprice;

  /// No description provided for @totally.
  ///
  /// In en, this message translates to:
  /// **'Total all'**
  String get totally;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'notes'**
  String get notes;

  /// No description provided for @nearof.
  ///
  /// In en, this message translates to:
  /// **'near of '**
  String get nearof;

  /// No description provided for @codeoffer.
  ///
  /// In en, this message translates to:
  /// **'Discount code, if any'**
  String get codeoffer;

  /// No description provided for @areaempty.
  ///
  /// In en, this message translates to:
  /// **'Please enter the nearest area and choose the area'**
  String get areaempty;

  /// No description provided for @confirmincorrectcoe.
  ///
  /// In en, this message translates to:
  /// **'The entered code is incorrect'**
  String get confirmincorrectcoe;

  /// No description provided for @confirmincorrectphone.
  ///
  /// In en, this message translates to:
  /// **'The phone number entered is incorrect'**
  String get confirmincorrectphone;

  /// No description provided for @confirmincorrectpassword.
  ///
  /// In en, this message translates to:
  /// **'The password entered is incorrect'**
  String get confirmincorrectpassword;

  /// No description provided for @firstlineconfirm.
  ///
  /// In en, this message translates to:
  /// **'Your account activation code has been sent to the phone number:'**
  String get firstlineconfirm;

  /// No description provided for @secondlineconfirm.
  ///
  /// In en, this message translates to:
  /// **'Enter the code in the box below'**
  String get secondlineconfirm;

  /// No description provided for @entercode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code here'**
  String get entercode;

  /// No description provided for @confirmcode.
  ///
  /// In en, this message translates to:
  /// **'Confirm Code'**
  String get confirmcode;

  /// No description provided for @notcorrectreg.
  ///
  /// In en, this message translates to:
  /// **'Password does not match'**
  String get notcorrectreg;

  /// No description provided for @suggestedproducts.
  ///
  /// In en, this message translates to:
  /// **'Suggested Products'**
  String get suggestedproducts;

  /// No description provided for @takegallery.
  ///
  /// In en, this message translates to:
  /// **'Take the picture from gallery'**
  String get takegallery;

  /// No description provided for @takecamera.
  ///
  /// In en, this message translates to:
  /// **'Take the picture from camera'**
  String get takecamera;

  /// No description provided for @confirmconfirm.
  ///
  /// In en, this message translates to:
  /// **'Please enter the full code'**
  String get confirmconfirm;

  /// No description provided for @reqnum.
  ///
  /// In en, this message translates to:
  /// **'request number'**
  String get reqnum;

  /// No description provided for @reqtot.
  ///
  /// In en, this message translates to:
  /// **'total '**
  String get reqtot;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'time'**
  String get time;

  /// No description provided for @qaid.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get qaid;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @sin_cart.
  ///
  /// In en, this message translates to:
  /// **'add to cart'**
  String get sin_cart;

  /// No description provided for @sin_product.
  ///
  /// In en, this message translates to:
  /// **'product'**
  String get sin_product;

  /// No description provided for @feaa.
  ///
  /// In en, this message translates to:
  /// **'category :'**
  String get feaa;

  /// No description provided for @alqeema.
  ///
  /// In en, this message translates to:
  /// **'the value :'**
  String get alqeema;

  /// No description provided for @modern.
  ///
  /// In en, this message translates to:
  /// **'Just arrived'**
  String get modern;

  /// No description provided for @req_suc.
  ///
  /// In en, this message translates to:
  /// **'Your request has been successfully sent'**
  String get req_suc;

  /// No description provided for @code_failed.
  ///
  /// In en, this message translates to:
  /// **'The entered code is incorrect'**
  String get code_failed;

  /// No description provided for @code_fexpired.
  ///
  /// In en, this message translates to:
  /// **'The entered code has expired'**
  String get code_fexpired;

  /// No description provided for @code_dis.
  ///
  /// In en, this message translates to:
  /// **'has been discount'**
  String get code_dis;

  /// No description provided for @code_total.
  ///
  /// In en, this message translates to:
  /// **'Your total is more than the allowed limit'**
  String get code_total;

  /// No description provided for @limit_buy.
  ///
  /// In en, this message translates to:
  /// **'permissible limit:'**
  String get limit_buy;

  /// No description provided for @my_points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get my_points;

  /// No description provided for @instead.
  ///
  /// In en, this message translates to:
  /// **'instead'**
  String get instead;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
