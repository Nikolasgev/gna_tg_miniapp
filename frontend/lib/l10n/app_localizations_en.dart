// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Telegram Store';

  @override
  String get catalog => 'Catalog';

  @override
  String get catalogProducts => 'Products Catalog';

  @override
  String get cart => 'Cart';

  @override
  String get cartEmpty => 'Cart is empty';

  @override
  String get addItemsFromCatalog => 'Add items from catalog';

  @override
  String get goToCatalog => 'Go to catalog';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get notAvailable => 'Not Available';

  @override
  String get checkout => 'Checkout';

  @override
  String get ordersHistory => 'Orders History';

  @override
  String get ordersHistorySubtitle => 'Your previous orders';

  @override
  String get noOrders => 'No orders';

  @override
  String get ordersWillAppearHere => 'Your orders will appear here';

  @override
  String get settings => 'Settings';

  @override
  String get settingsSubtitle => 'Language and theme';

  @override
  String get appearance => 'Appearance';

  @override
  String get lightTheme => 'Light theme';

  @override
  String get useLightColorScheme => 'Use light color scheme';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get useDarkColorScheme => 'Use dark color scheme';

  @override
  String get language => 'Language';

  @override
  String get russian => 'Russian';

  @override
  String get english => 'English';

  @override
  String get support => 'Support';

  @override
  String get supportSubtitle => 'Contact us';

  @override
  String get contactUs => 'Contact us';

  @override
  String get contactUsDescription =>
      'If you have any questions or problems, we are always ready to help!';

  @override
  String get writeInTelegram => 'Write in Telegram';

  @override
  String get writeByEmail => 'Write by email';

  @override
  String get faq => 'Frequently Asked Questions';

  @override
  String get faqCancelOrder => 'How to cancel an order?';

  @override
  String get faqCancelOrderAnswer =>
      'You can cancel an order in the \"Orders History\" section until it is accepted for processing.';

  @override
  String get faqChangeAddress => 'How to change delivery address?';

  @override
  String get faqChangeAddressAnswer =>
      'The delivery address can be changed when placing an order or by contacting support.';

  @override
  String get faqPaymentMethods => 'What payment methods are available?';

  @override
  String get faqPaymentMethodsAnswer =>
      'We accept cash on delivery and online via YooKassa.';

  @override
  String get filters => 'Filters';

  @override
  String get all => 'All';

  @override
  String get loadingError => 'Loading error';

  @override
  String get retry => 'Retry';

  @override
  String get productsNotFound => 'Products not found';

  @override
  String get tryChangeSearchParams => 'Try changing search parameters';

  @override
  String get ensureBackendRunning =>
      'Make sure the backend is running:\ncd backend && docker-compose up -d';

  @override
  String get deliveryAddressRequired => 'Please specify delivery address';

  @override
  String get cartIsEmpty => 'Cart is empty';

  @override
  String get orderDetails => 'Order Details';

  @override
  String orderNumber(String number) {
    return 'Order #$number';
  }

  @override
  String get orderStatus => 'Status';

  @override
  String get orderTotal => 'Total';

  @override
  String get customerInfo => 'Customer Information';

  @override
  String get deliveryInfo => 'Delivery Information';

  @override
  String get paymentInfo => 'Payment Information';

  @override
  String get items => 'Items';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get deliveryMethod => 'Delivery Method';

  @override
  String get pickup => 'Pickup';

  @override
  String get delivery => 'Delivery';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get cash => 'Cash';

  @override
  String get online => 'Online';

  @override
  String get comment => 'Comment';

  @override
  String get placeOrder => 'Place Order';

  @override
  String get statusNew => 'New';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusPreparing => 'Preparing';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get paymentStatusPending => 'Pending';

  @override
  String get paymentStatusPaid => 'Paid';

  @override
  String get paymentStatusFailed => 'Failed';

  @override
  String get paymentStatusRefunded => 'Refunded';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get removeFromCart => 'Remove from Cart';

  @override
  String get quantity => 'Quantity';

  @override
  String get price => 'Price';

  @override
  String get description => 'Description';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get unknownState => 'Unknown state';

  @override
  String get unknown => 'Unknown';

  @override
  String get orderCreatedSuccessfully => 'Order created successfully!';

  @override
  String orderCreationError(String message) {
    return 'Error: $message';
  }

  @override
  String get contactInfo => 'Contact Information';

  @override
  String get enterName => 'Enter name';

  @override
  String get enterPhone => 'Enter phone';

  @override
  String get enterDeliveryAddress => 'Enter delivery address';

  @override
  String get deliveryMethodSection => 'Delivery Method';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get product => 'Product';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get createdDate => 'Created Date';

  @override
  String get onlinePayment => 'Online Payment';

  @override
  String get systemTheme => 'System Theme';

  @override
  String get followSystemSettings => 'Follow system settings';

  @override
  String get redirectingToPayment =>
      'You will be redirected to the YooKassa payment page to complete the payment.';

  @override
  String get proceedToPayment => 'Proceed to Payment';

  @override
  String get couldNotOpenPaymentPage => 'Could not open payment page';

  @override
  String get errorOpeningPaymentPage => 'Error opening payment page';
}
