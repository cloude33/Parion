import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:line_icons/line_icons.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Uygulama genelinde kullanılan renkli ikonlar
class AppIcons {
  // ==================== FİNANSAL İKONLAR ====================

  /// Para ve finans ikonları
  static final IconData money = FontAwesomeIcons.moneyBill.data;
  static final IconData wallet = FontAwesomeIcons.wallet.data;
  static final IconData creditCard = FontAwesomeIcons.creditCard.data;
  static final IconData bank = FontAwesomeIcons.buildingColumns.data;
  static final IconData coins = FontAwesomeIcons.coins.data;
  static final IconData piggyBank = FontAwesomeIcons.piggyBank.data;
  static final IconData handHoldingDollar = FontAwesomeIcons.handHoldingDollar.data;
  static final IconData receipt = FontAwesomeIcons.receipt.data;
  static final IconData invoice = FontAwesomeIcons.fileInvoiceDollar.data;

  /// Gelir/Gider ikonları
  static final IconData income = FontAwesomeIcons.arrowTrendUp.data;
  static final IconData expense = FontAwesomeIcons.arrowTrendDown.data;
  static final IconData transfer = FontAwesomeIcons.rightLeft.data;
  static final IconData exchange = FontAwesomeIcons.arrowsRotate.data;

  // ==================== KATEGORİ İKONLARI ====================

  /// Yemek ve içecek
  static final IconData food = FontAwesomeIcons.utensils.data;
  static final IconData coffee = FontAwesomeIcons.mugHot.data;
  static final IconData pizza = FontAwesomeIcons.pizzaSlice.data;
  static final IconData burger = FontAwesomeIcons.burger.data;

  /// Ulaşım
  static final IconData car = FontAwesomeIcons.car.data;
  static final IconData bus = FontAwesomeIcons.bus.data;
  static final IconData plane = FontAwesomeIcons.plane.data;
  static final IconData train = FontAwesomeIcons.train.data;
  static final IconData bicycle = FontAwesomeIcons.bicycle.data;
  static final IconData motorcycle = FontAwesomeIcons.motorcycle.data;
  static final IconData taxi = FontAwesomeIcons.taxi.data;
  static final IconData gasStation = FontAwesomeIcons.gasPump.data;

  /// Alışveriş
  static final IconData shopping = FontAwesomeIcons.bagShopping.data;
  static final IconData shoppingCart = FontAwesomeIcons.cartShopping.data;
  static final IconData store = FontAwesomeIcons.store.data;
  static final IconData gift = FontAwesomeIcons.gift.data;
  static final IconData tshirt = FontAwesomeIcons.shirt.data;

  /// Sağlık
  static final IconData health = FontAwesomeIcons.heartPulse.data;
  static final IconData hospital = FontAwesomeIcons.hospital.data;
  static final IconData pills = FontAwesomeIcons.pills.data;
  static final IconData stethoscope = FontAwesomeIcons.stethoscope.data;

  /// Eğlence
  static final IconData entertainment = FontAwesomeIcons.masksTheater.data;
  static final IconData movie = FontAwesomeIcons.film.data;
  static final IconData music = FontAwesomeIcons.music.data;
  static final IconData gamepad = FontAwesomeIcons.gamepad.data;
  static final IconData camera = FontAwesomeIcons.camera.data;

  /// Ev ve yaşam
  static final IconData home = FontAwesomeIcons.house.data;
  static final IconData bed = FontAwesomeIcons.bed.data;
  static final IconData couch = FontAwesomeIcons.couch.data;
  static final IconData hammer = FontAwesomeIcons.hammer.data;
  static final IconData paintBrush = FontAwesomeIcons.paintbrush.data;

  // ==================== FATURA İKONLARI ====================

  /// Elektrik
  static final IconData electricity = FontAwesomeIcons.bolt.data;
  static final IconData lightbulb = FontAwesomeIcons.lightbulb.data;

  /// Su
  static final IconData water = FontAwesomeIcons.droplet.data;
  static final IconData faucet = FontAwesomeIcons.faucetDrip.data;

  /// Doğalgaz
  static final IconData gas = FontAwesomeIcons.fire.data;
  static final IconData fireFlame = FontAwesomeIcons.fireFlameSimple.data;

  /// İnternet ve telefon
  static final IconData internet = FontAwesomeIcons.wifi.data;
  static final IconData phone = FontAwesomeIcons.phone.data;
  static final IconData mobile = FontAwesomeIcons.mobileScreen.data;
  static final IconData router = FontAwesomeIcons.wifi.data;

  /// Kira ve sigorta
  static final IconData rent = FontAwesomeIcons.houseChimney.data;
  static final IconData insurance = FontAwesomeIcons.shield.data;
  static final IconData umbrella = FontAwesomeIcons.umbrella.data;

  /// Abonelik
  static final IconData subscription = FontAwesomeIcons.repeat.data;
  static final IconData netflix = FontAwesomeIcons.tv.data;
  static final IconData spotify = FontAwesomeIcons.spotify.data;

  // ==================== UYGULAMA İKONLARI ====================

  /// Navigasyon
  static final IconData dashboard = FontAwesomeIcons.chartLine.data;
  static final IconData statistics = FontAwesomeIcons.chartPie.data;
  static final IconData calendar = FontAwesomeIcons.calendar.data;
  static final IconData settings = FontAwesomeIcons.gear.data;
  static final IconData profile = FontAwesomeIcons.user.data;

  /// Aksiyonlar
  static final IconData add = FontAwesomeIcons.plus.data;
  static final IconData edit = FontAwesomeIcons.penToSquare.data;
  static final IconData delete = FontAwesomeIcons.trash.data;
  static final IconData save = FontAwesomeIcons.floppyDisk.data;
  static final IconData search = FontAwesomeIcons.magnifyingGlass.data;
  static final IconData filter = FontAwesomeIcons.filter.data;
  static final IconData sort = FontAwesomeIcons.sort.data;

  /// Güvenlik
  static final IconData lock = FontAwesomeIcons.lock.data;
  static final IconData unlock = FontAwesomeIcons.lockOpen.data;
  static final IconData fingerprint = FontAwesomeIcons.fingerprint.data;
  static final IconData eye = FontAwesomeIcons.eye.data;
  static final IconData eyeSlash = FontAwesomeIcons.eyeSlash.data;
  static final IconData shield = FontAwesomeIcons.shieldHalved.data;

  /// Bildirimler
  static final IconData notification = FontAwesomeIcons.bell.data;
  static final IconData notificationOff = FontAwesomeIcons.bellSlash.data;
  static final IconData warning = FontAwesomeIcons.triangleExclamation.data;
  static final IconData info = FontAwesomeIcons.circleInfo.data;
  static final IconData success = FontAwesomeIcons.circleCheck.data;
  static final IconData error = FontAwesomeIcons.circleXmark.data;

  /// Yedekleme ve senkronizasyon
  static final IconData backup = FontAwesomeIcons.cloudArrowUp.data;
  static final IconData restore = FontAwesomeIcons.cloudArrowDown.data;
  static final IconData sync = FontAwesomeIcons.arrowsRotate.data;
  static final IconData cloud = FontAwesomeIcons.cloud.data;
  static final IconData download = FontAwesomeIcons.download.data;
  static final IconData upload = FontAwesomeIcons.upload.data;

  /// Sosyal medya
  static final IconData google = FontAwesomeIcons.google.data;
  static final IconData apple = FontAwesomeIcons.apple.data;
  static final IconData twitter = FontAwesomeIcons.twitter.data;

  // ==================== PHOSPHOR İKONLARI ====================

  /// Modern ve minimal ikonlar
  static const IconData walletPhosphor = LucideIcons.wallet;
  static const IconData chartPhosphor = LucideIcons.pieChart;
  static const IconData trendUpPhosphor = LucideIcons.trendingUp;
  static const IconData trendDownPhosphor = LucideIcons.trendingDown;
  static const IconData coinPhosphor = LucideIcons.coins;
  static const IconData creditCardPhosphor = LucideIcons.creditCard;

  // ==================== LINE İKONLARI ====================

  /// İnce çizgili ikonlar
  static const IconData walletLine = LineIcons.wallet;
  static const IconData chartLine = LineIcons.lineChart;
  static const IconData moneyLine = LineIcons.moneyBill;
  static const IconData creditCardLine = LineIcons.creditCard;
  static const IconData bankLine = LineIcons.university;

  // ==================== MODERN İKONLAR ====================

  /// Minimal ve modern ikonlar (resimdeki gibi)
  static const IconData shoppingModern = LucideIcons.shoppingCart;
  static const IconData foodModern = LucideIcons.utensils;
  static const IconData phoneModern = LucideIcons.smartphone;
  static const IconData entertainmentModern = LucideIcons.music;
  static const IconData educationModern = LucideIcons.bookOpen;
  static const IconData beautyModern = LucideIcons.sparkles;
  static const IconData sportsModern = LucideIcons.trophy;
  static const IconData socialModern = LucideIcons.users;
  static const IconData transportModern = LucideIcons.bus;
  static const IconData clothingModern = LucideIcons.shirt;
  static const IconData carModern = LucideIcons.car;
  static const IconData wineModern = LucideIcons.wine;
  static const IconData insuranceModern = LucideIcons.shield;
  static const IconData electronicsModern = LucideIcons.laptop;
  static const IconData travelModern = LucideIcons.plane;
  static const IconData healthModern = LucideIcons.heart;
  static const IconData petModern = LucideIcons.heart;
  static const IconData repairModern = LucideIcons.wrench;
  static const IconData housingModern = LucideIcons.building;
  static const IconData homeModern = LucideIcons.home;
  static const IconData giftModern = LucideIcons.gift;
  static const IconData donationModern = LucideIcons.heart;
  static const IconData lotteryModern = LucideIcons.coins;
  static const IconData shoppingBagModern = LucideIcons.shoppingBag;
  static const IconData babyModern = LucideIcons.baby;
  static const IconData vegetableModern = LucideIcons.carrot;
  static const IconData fruitModern = LucideIcons.apple;
  static const IconData otherModern = LucideIcons.moreHorizontal;

  // ==================== LUCIDE İKONLARI ====================

  /// Modern ve temiz ikonlar
  static const IconData walletLucide = LucideIcons.wallet;
  static const IconData trendingUpLucide = LucideIcons.trendingUp;
  static const IconData trendingDownLucide = LucideIcons.trendingDown;
  static const IconData pieChartLucide = LucideIcons.pieChart;
  static const IconData barChartLucide = LucideIcons.barChart;

  // ==================== RENKLI İKON YARDIMCILARı ====================

  /// Kategori renkli ikonları
  static Widget getCategoryIcon(
    String category, {
    double size = 24,
    Color? color,
  }) {
    IconData iconData;
    Color defaultColor;

    switch (category.toLowerCase()) {
      case 'alışveriş':
      case 'alisveris':
      case 'shopping':
        iconData = shoppingModern;
        defaultColor = Colors.purple;
        break;
      case 'gıda':
      case 'gida':
      case 'yemek':
      case 'food':
        iconData = foodModern;
        defaultColor = Colors.orange;
        break;
      case 'telefon':
      case 'phone':
        iconData = phoneModern;
        defaultColor = Colors.blue;
        break;
      case 'eğlence':
      case 'eglence':
      case 'entertainment':
        iconData = entertainmentModern;
        defaultColor = Colors.pink;
        break;
      case 'eğitim':
      case 'egitim':
      case 'education':
        iconData = educationModern;
        defaultColor = Colors.indigo;
        break;
      case 'güzellik':
      case 'guzellik':
      case 'beauty':
        iconData = beautyModern;
        defaultColor = Colors.pink.shade300;
        break;
      case 'spor':
      case 'sports':
        iconData = sportsModern;
        defaultColor = Colors.cyan;
        break;
      case 'sosyal':
      case 'social':
        iconData = socialModern;
        defaultColor = Colors.teal;
        break;
      case 'toplu taşıma':
      case 'toplu tasima':
      case 'transport':
        iconData = transportModern;
        defaultColor = Colors.blue.shade600;
        break;
      case 'giyim':
      case 'clothing':
        iconData = clothingModern;
        defaultColor = Colors.purple.shade300;
        break;
      case 'araba':
      case 'car':
        iconData = carModern;
        defaultColor = Colors.red;
        break;
      case 'şarap':
      case 'sarap':
      case 'wine':
        iconData = wineModern;
        defaultColor = Colors.red.shade700;
        break;
      case 'sigara':
      case 'insurance':
        iconData = insuranceModern;
        defaultColor = Colors.grey;
        break;
      case 'elektronik':
      case 'electronics':
        iconData = electronicsModern;
        defaultColor = Colors.blue.shade800;
        break;
      case 'yolculuk':
      case 'travel':
        iconData = travelModern;
        defaultColor = Colors.orange.shade600;
        break;
      case 'sağlık':
      case 'saglik':
      case 'health':
        iconData = healthModern;
        defaultColor = Colors.red;
        break;
      case 'evcil hayvan':
      case 'pet':
        iconData = petModern;
        defaultColor = Colors.brown;
        break;
      case 'onarım':
      case 'onarim':
      case 'repair':
        iconData = repairModern;
        defaultColor = Colors.grey.shade600;
        break;
      case 'konut':
      case 'housing':
        iconData = housingModern;
        defaultColor = Colors.brown.shade400;
        break;
      case 'ev':
      case 'home':
        iconData = homeModern;
        defaultColor = Colors.green;
        break;
      case 'hediye':
      case 'gift':
        iconData = giftModern;
        defaultColor = Colors.red.shade400;
        break;
      case 'bağış yapmak':
      case 'bagis yapmak':
      case 'donation':
        iconData = donationModern;
        defaultColor = Colors.pink.shade400;
        break;
      case 'piyango':
      case 'lottery':
        iconData = lotteryModern;
        defaultColor = Colors.yellow.shade700;
        break;
      case 'alıştırmalıklar':
      case 'alistirmalikar':
      case 'shopping_bag':
        iconData = shoppingBagModern;
        defaultColor = Colors.purple.shade400;
        break;
      case 'bebek':
      case 'baby':
        iconData = babyModern;
        defaultColor = Colors.pink.shade200;
        break;
      case 'sebze':
      case 'vegetable':
        iconData = vegetableModern;
        defaultColor = Colors.green.shade600;
        break;
      case 'meyve':
      case 'fruit':
        iconData = fruitModern;
        defaultColor = Colors.red.shade400;
        break;
      case 'ayar':
      case 'other':
        iconData = otherModern;
        defaultColor = Colors.grey.shade500;
        break;
      case 'ulaşım':
      case 'ulasim':
        iconData = car;
        defaultColor = Colors.blue;
        break;
      case 'elektrik':
      case 'electricity':
        iconData = electricity;
        defaultColor = Colors.yellow.shade700;
        break;
      case 'su':
      case 'water':
        iconData = water;
        defaultColor = Colors.blue.shade600;
        break;
      case 'doğalgaz':
      case 'dogalgaz':
      case 'gas':
        iconData = gas;
        defaultColor = Colors.orange.shade700;
        break;
      case 'internet':
        iconData = internet;
        defaultColor = Colors.indigo;
        break;
      case 'kira':
      case 'rent':
        iconData = rent;
        defaultColor = Colors.brown;
        break;
      case 'sigorta':
        iconData = insurance;
        defaultColor = Colors.cyan;
        break;
      case 'abonelik':
      case 'subscription':
        iconData = subscription;
        defaultColor = Colors.deepPurple;
        break;
      default:
        iconData = money;
        defaultColor = Colors.grey;
    }

    return Icon(iconData, size: size, color: color ?? defaultColor);
  }

  /// Kategori rengini getirir
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'yemek':
      case 'food':
        return Colors.orange;
      case 'ulaşım':
      case 'transport':
        return Colors.blue;
      case 'alışveriş':
      case 'shopping':
        return Colors.purple;
      case 'sağlık':
      case 'health':
        return Colors.red;
      case 'eğlence':
      case 'entertainment':
        return Colors.pink;
      case 'ev':
      case 'home':
        return Colors.green;
      case 'elektrik':
      case 'electricity':
        return Colors.yellow.shade700;
      case 'su':
      case 'water':
        return Colors.blue.shade600;
      case 'doğalgaz':
      case 'gas':
        return Colors.orange.shade700;
      case 'internet':
        return Colors.indigo;
      case 'telefon':
      case 'phone':
        return Colors.teal;
      case 'kira':
      case 'rent':
        return Colors.brown;
      case 'sigorta':
      case 'insurance':
        return Colors.cyan;
      case 'abonelik':
      case 'subscription':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  /// Finansal durum renkli ikonları
  static Widget getFinancialStatusIcon(String type, {double size = 24}) {
    switch (type.toLowerCase()) {
      case 'income':
      case 'gelir':
        return Icon(income, size: size, color: Colors.green);
      case 'expense':
      case 'gider':
        return Icon(expense, size: size, color: Colors.red);
      case 'transfer':
        return Icon(transfer, size: size, color: Colors.blue);
      default:
        return Icon(money, size: size, color: Colors.grey);
    }
  }

  /// Yedekleme durumu renkli ikonları
  static Widget getBackupStatusIcon(String status, {double size = 24}) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'başarılı':
        return Icon(success, size: size, color: Colors.green);
      case 'error':
      case 'hata':
        return Icon(error, size: size, color: Colors.red);
      case 'warning':
      case 'uyarı':
        return Icon(warning, size: size, color: Colors.orange);
      case 'info':
      case 'bilgi':
        return Icon(info, size: size, color: Colors.blue);
      case 'uploading':
      case 'yükleniyor':
        return Icon(upload, size: size, color: Colors.blue);
      case 'downloading':
      case 'indiriliyor':
        return Icon(download, size: size, color: Colors.green);
      default:
        return Icon(cloud, size: size, color: Colors.grey);
    }
  }

  /// Güvenlik durumu renkli ikonları
  static Widget getSecurityIcon(String type, {double size = 24}) {
    switch (type.toLowerCase()) {
      case 'locked':
      case 'kilitli':
        return Icon(lock, size: size, color: Colors.red);
      case 'unlocked':
      case 'açık':
        return Icon(unlock, size: size, color: Colors.green);
      case 'biometric':
      case 'biyometrik':
        return Icon(fingerprint, size: size, color: Colors.blue);
      case 'secure':
      case 'güvenli':
        return Icon(shield, size: size, color: Colors.green);
      default:
        return Icon(lock, size: size, color: Colors.grey);
    }
  }
}

/// Renkli ikon tema sınıfı
class AppIconTheme {
  static const Color primary = Color(0xFF2C6BED);
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;

  /// Kategori renkleri
  static const Map<String, Color> categoryColors = {
    'yemek': Colors.orange,
    'ulaşım': Colors.blue,
    'alışveriş': Colors.purple,
    'sağlık': Colors.red,
    'eğlence': Colors.pink,
    'ev': Colors.green,
    'elektrik': Colors.yellow,
    'su': Colors.blue,
    'doğalgaz': Colors.orange,
    'internet': Colors.indigo,
    'telefon': Colors.teal,
    'kira': Colors.brown,
    'sigorta': Colors.cyan,
    'abonelik': Colors.deepPurple,
  };

  /// Gradient renkler
  static const List<Color> primaryGradient = [
    Color(0xFF2C6BED),
    Color(0xFF1E40AF),
  ];

  static const List<Color> successGradient = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];

  static const List<Color> errorGradient = [
    Color(0xFFEF4444),
    Color(0xFFDC2626),
  ];
}
