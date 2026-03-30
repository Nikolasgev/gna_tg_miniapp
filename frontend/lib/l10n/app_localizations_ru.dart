// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Telegram Store';

  @override
  String get catalog => 'Каталог';

  @override
  String get catalogProducts => 'Каталог товаров';

  @override
  String get cart => 'Корзина';

  @override
  String get cartEmpty => 'Корзина пуста';

  @override
  String get addItemsFromCatalog => 'Добавьте товары из каталога';

  @override
  String get goToCatalog => 'Перейти в каталог';

  @override
  String get total => 'Итого';

  @override
  String get subtotal => 'Товары';

  @override
  String get notAvailable => 'Недоступно';

  @override
  String get checkout => 'Оформление заказа';

  @override
  String get ordersHistory => 'История заказов';

  @override
  String get ordersHistorySubtitle => 'Ваши предыдущие заказы';

  @override
  String get noOrders => 'Нет заказов';

  @override
  String get ordersWillAppearHere => 'Ваши заказы будут отображаться здесь';

  @override
  String get settings => 'Настройки';

  @override
  String get settingsSubtitle => 'Язык и тема';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get lightTheme => 'Светлая тема';

  @override
  String get useLightColorScheme => 'Использовать светлую цветовую схему';

  @override
  String get darkTheme => 'Темная тема';

  @override
  String get useDarkColorScheme => 'Использовать темную цветовую схему';

  @override
  String get language => 'Язык';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'English';

  @override
  String get support => 'Поддержка';

  @override
  String get supportSubtitle => 'Связаться с нами';

  @override
  String get contactUs => 'Свяжитесь с нами';

  @override
  String get contactUsDescription =>
      'Если у вас возникли вопросы или проблемы, мы всегда готовы помочь!';

  @override
  String get writeInTelegram => 'Написать в Telegram';

  @override
  String get writeByEmail => 'Написать на почту';

  @override
  String get faq => 'Часто задаваемые вопросы';

  @override
  String get faqCancelOrder => 'Как отменить заказ?';

  @override
  String get faqCancelOrderAnswer =>
      'Вы можете отменить заказ в разделе \"История заказов\" до момента его принятия в обработку.';

  @override
  String get faqChangeAddress => 'Как изменить адрес доставки?';

  @override
  String get faqChangeAddressAnswer =>
      'Адрес доставки можно изменить при оформлении заказа или связавшись с поддержкой.';

  @override
  String get faqPaymentMethods => 'Какие способы оплаты доступны?';

  @override
  String get faqPaymentMethodsAnswer =>
      'Мы принимаем оплату наличными при получении и онлайн через YooKassa.';

  @override
  String get filters => 'Фильтры';

  @override
  String get all => 'Все';

  @override
  String get loadingError => 'Ошибка загрузки';

  @override
  String get retry => 'Повторить';

  @override
  String get productsNotFound => 'Товары не найдены';

  @override
  String get tryChangeSearchParams => 'Попробуйте изменить параметры поиска';

  @override
  String get ensureBackendRunning =>
      'Убедитесь, что бэкенд запущен:\ncd backend && docker-compose up -d';

  @override
  String get deliveryAddressRequired => 'Укажите адрес доставки';

  @override
  String get cartIsEmpty => 'Корзина пуста';

  @override
  String get orderDetails => 'Детали заказа';

  @override
  String orderNumber(String number) {
    return 'Заказ #$number';
  }

  @override
  String get orderStatus => 'Статус';

  @override
  String get orderTotal => 'Итого';

  @override
  String get customerInfo => 'Информация о клиенте';

  @override
  String get deliveryInfo => 'Информация о доставке';

  @override
  String get paymentInfo => 'Информация об оплате';

  @override
  String get items => 'Товары';

  @override
  String get name => 'Имя';

  @override
  String get phone => 'Телефон';

  @override
  String get address => 'Адрес';

  @override
  String get deliveryMethod => 'Способ доставки';

  @override
  String get pickup => 'Самовывоз';

  @override
  String get delivery => 'Доставка';

  @override
  String get paymentMethod => 'Способ оплаты';

  @override
  String get cash => 'Наличными';

  @override
  String get online => 'Онлайн';

  @override
  String get comment => 'Комментарий';

  @override
  String get placeOrder => 'Оформить заказ';

  @override
  String get statusNew => 'Новый';

  @override
  String get statusAccepted => 'Принят';

  @override
  String get statusPreparing => 'Готовится';

  @override
  String get statusReady => 'Готов';

  @override
  String get statusCancelled => 'Отменен';

  @override
  String get statusCompleted => 'Завершен';

  @override
  String get paymentStatusPending => 'Ожидает оплаты';

  @override
  String get paymentStatusPaid => 'Оплачен';

  @override
  String get paymentStatusFailed => 'Ошибка оплаты';

  @override
  String get paymentStatusRefunded => 'Возврат';

  @override
  String get addToCart => 'В корзину';

  @override
  String get removeFromCart => 'Удалить из корзины';

  @override
  String get quantity => 'Количество';

  @override
  String get price => 'Цена';

  @override
  String get description => 'Описание';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get edit => 'Редактировать';

  @override
  String get back => 'Назад';

  @override
  String get close => 'Закрыть';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get loading => 'Загрузка...';

  @override
  String get error => 'Ошибка';

  @override
  String get success => 'Успешно';

  @override
  String get unknownState => 'Неизвестное состояние';

  @override
  String get unknown => 'Неизвестно';

  @override
  String get orderCreatedSuccessfully => 'Заказ успешно создан!';

  @override
  String orderCreationError(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get contactInfo => 'Контактные данные';

  @override
  String get enterName => 'Введите имя';

  @override
  String get enterPhone => 'Введите телефон';

  @override
  String get enterDeliveryAddress => 'Введите адрес доставки';

  @override
  String get deliveryMethodSection => 'Способ получения';

  @override
  String get deliveryAddress => 'Адрес доставки';

  @override
  String get product => 'Товар';

  @override
  String get cancelOrder => 'Отменить заказ';

  @override
  String get createdDate => 'Дата создания';

  @override
  String get onlinePayment => 'Онлайн оплата';

  @override
  String get systemTheme => 'Системная тема';

  @override
  String get followSystemSettings => 'Следовать системным настройкам';

  @override
  String get redirectingToPayment =>
      'Вы будете перенаправлены на страницу оплаты ЮKassa для завершения платежа.';

  @override
  String get proceedToPayment => 'Перейти к оплате';

  @override
  String get couldNotOpenPaymentPage => 'Не удалось открыть страницу оплаты';

  @override
  String get errorOpeningPaymentPage => 'Ошибка при открытии страницы оплаты';
}
