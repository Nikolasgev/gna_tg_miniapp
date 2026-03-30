import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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
    Locale('en'),
    Locale('ru'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Telegram Store'**
  String get appTitle;

  /// Catalog screen title
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalog;

  /// Catalog products title
  ///
  /// In en, this message translates to:
  /// **'Products Catalog'**
  String get catalogProducts;

  /// Cart screen title
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// Message when cart is empty
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartEmpty;

  /// Hint to add items from catalog
  ///
  /// In en, this message translates to:
  /// **'Add items from catalog'**
  String get addItemsFromCatalog;

  /// Button to go to catalog
  ///
  /// In en, this message translates to:
  /// **'Go to catalog'**
  String get goToCatalog;

  /// Total price label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// Checkout screen title
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// Orders history screen title
  ///
  /// In en, this message translates to:
  /// **'Orders History'**
  String get ordersHistory;

  /// Orders history menu subtitle
  ///
  /// In en, this message translates to:
  /// **'Your previous orders'**
  String get ordersHistorySubtitle;

  /// Message when no orders
  ///
  /// In en, this message translates to:
  /// **'No orders'**
  String get noOrders;

  /// Message when orders list is empty
  ///
  /// In en, this message translates to:
  /// **'Your orders will appear here'**
  String get ordersWillAppearHere;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Settings menu subtitle
  ///
  /// In en, this message translates to:
  /// **'Language and theme'**
  String get settingsSubtitle;

  /// Appearance section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Light theme switch label
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get lightTheme;

  /// Light theme switch subtitle
  ///
  /// In en, this message translates to:
  /// **'Use light color scheme'**
  String get useLightColorScheme;

  /// Dark theme switch label
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// Dark theme switch subtitle
  ///
  /// In en, this message translates to:
  /// **'Use dark color scheme'**
  String get useDarkColorScheme;

  /// Language section title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Russian language option
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Support screen title
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Support menu subtitle
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get supportSubtitle;

  /// Contact us section title
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// Contact us description
  ///
  /// In en, this message translates to:
  /// **'If you have any questions or problems, we are always ready to help!'**
  String get contactUsDescription;

  /// Telegram contact option
  ///
  /// In en, this message translates to:
  /// **'Write in Telegram'**
  String get writeInTelegram;

  /// Email contact option
  ///
  /// In en, this message translates to:
  /// **'Write by email'**
  String get writeByEmail;

  /// FAQ section title
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faq;

  /// FAQ question about canceling order
  ///
  /// In en, this message translates to:
  /// **'How to cancel an order?'**
  String get faqCancelOrder;

  /// FAQ answer about canceling order
  ///
  /// In en, this message translates to:
  /// **'You can cancel an order in the \"Orders History\" section until it is accepted for processing.'**
  String get faqCancelOrderAnswer;

  /// FAQ question about changing address
  ///
  /// In en, this message translates to:
  /// **'How to change delivery address?'**
  String get faqChangeAddress;

  /// FAQ answer about changing address
  ///
  /// In en, this message translates to:
  /// **'The delivery address can be changed when placing an order or by contacting support.'**
  String get faqChangeAddressAnswer;

  /// FAQ question about payment methods
  ///
  /// In en, this message translates to:
  /// **'What payment methods are available?'**
  String get faqPaymentMethods;

  /// FAQ answer about payment methods
  ///
  /// In en, this message translates to:
  /// **'We accept cash on delivery and online via YooKassa.'**
  String get faqPaymentMethodsAnswer;

  /// Filters button tooltip
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// All categories filter
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Error message when loading fails
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get loadingError;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Message when products not found
  ///
  /// In en, this message translates to:
  /// **'Products not found'**
  String get productsNotFound;

  /// Hint to change search parameters
  ///
  /// In en, this message translates to:
  /// **'Try changing search parameters'**
  String get tryChangeSearchParams;

  /// Message to ensure backend is running
  ///
  /// In en, this message translates to:
  /// **'Make sure the backend is running:\ncd backend && docker-compose up -d'**
  String get ensureBackendRunning;

  /// Error when delivery address is required
  ///
  /// In en, this message translates to:
  /// **'Please specify delivery address'**
  String get deliveryAddressRequired;

  /// Error when cart is empty
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartIsEmpty;

  /// Order details screen title
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// Order number display
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String orderNumber(String number);

  /// Order status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orderStatus;

  /// Order total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get orderTotal;

  /// Customer information section title
  ///
  /// In en, this message translates to:
  /// **'Customer Information'**
  String get customerInfo;

  /// Delivery information section title
  ///
  /// In en, this message translates to:
  /// **'Delivery Information'**
  String get deliveryInfo;

  /// Payment information section title
  ///
  /// In en, this message translates to:
  /// **'Payment Information'**
  String get paymentInfo;

  /// Items section title
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Phone field label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Address field label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Delivery method label
  ///
  /// In en, this message translates to:
  /// **'Delivery Method'**
  String get deliveryMethod;

  /// Pickup delivery method
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// Delivery method
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// Payment method label
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// Cash payment method
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// Online payment method
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// Comment field label
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// Place order button text
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// Order status: new
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statusNew;

  /// Order status: accepted
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// Order status: preparing
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get statusPreparing;

  /// Order status: ready
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// Order status: cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// Order status: completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// Payment status: pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get paymentStatusPending;

  /// Payment status: paid
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paymentStatusPaid;

  /// Payment status: failed
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get paymentStatusFailed;

  /// Payment status: refunded
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get paymentStatusRefunded;

  /// Add to cart button text
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// Remove from cart button text
  ///
  /// In en, this message translates to:
  /// **'Remove from Cart'**
  String get removeFromCart;

  /// Quantity label
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Price label
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Description label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Back button text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success message
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Unknown state message
  ///
  /// In en, this message translates to:
  /// **'Unknown state'**
  String get unknownState;

  /// Unknown status
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Success message when order is created
  ///
  /// In en, this message translates to:
  /// **'Order created successfully!'**
  String get orderCreatedSuccessfully;

  /// Error message when order creation fails
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String orderCreationError(String message);

  /// Contact information section title
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfo;

  /// Validation error for name field
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// Validation error for phone field
  ///
  /// In en, this message translates to:
  /// **'Enter phone'**
  String get enterPhone;

  /// Validation error for delivery address field
  ///
  /// In en, this message translates to:
  /// **'Enter delivery address'**
  String get enterDeliveryAddress;

  /// Delivery method section title
  ///
  /// In en, this message translates to:
  /// **'Delivery Method'**
  String get deliveryMethodSection;

  /// Delivery address field label
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// Product screen title
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// Cancel order button label
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// Created date label
  ///
  /// In en, this message translates to:
  /// **'Created Date'**
  String get createdDate;

  /// Online payment method
  ///
  /// In en, this message translates to:
  /// **'Online Payment'**
  String get onlinePayment;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

  /// System theme subtitle
  ///
  /// In en, this message translates to:
  /// **'Follow system settings'**
  String get followSystemSettings;

  /// Message shown when redirecting to payment page
  ///
  /// In en, this message translates to:
  /// **'You will be redirected to the YooKassa payment page to complete the payment.'**
  String get redirectingToPayment;

  /// Button text to proceed to payment page
  ///
  /// In en, this message translates to:
  /// **'Proceed to Payment'**
  String get proceedToPayment;

  /// Error message when payment page cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open payment page'**
  String get couldNotOpenPaymentPage;

  /// Error message when there's an error opening payment page
  ///
  /// In en, this message translates to:
  /// **'Error opening payment page'**
  String get errorOpeningPaymentPage;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
