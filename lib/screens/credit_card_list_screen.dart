import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../models/card_design/card_brand.dart';
import '../services/credit_card_service.dart';
import '../services/data_service.dart';
import '../utils/bank_card_entity_helper.dart';
import '../widgets/cards/bank_card_carousel.dart';
import '../widgets/cards/bank_card_theme_picker.dart';
import '../widgets/cards/bank_card_widget.dart';
import 'add_credit_card_screen.dart';
import 'credit_card_detail_screen.dart';
import 'card_reporting_screen.dart';
import 'installment_tracking_screen.dart';

class CreditCardListScreen extends StatefulWidget {
  const CreditCardListScreen({super.key});

  @override
  State<CreditCardListScreen> createState() => _CreditCardListScreenState();
}

class _CreditCardListScreenState extends State<CreditCardListScreen> {
  final CreditCardService _cardService = CreditCardService();
  final DataService _dataService = DataService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  List<CreditCard> _cards = [];
  Map<String, Map<String, dynamic>> _cardDetails = {};
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Credit Cards, 1: Installments

  double _totalDebt = 0;
  double _totalAvailableCredit = 0;
  double _totalDueThisMonth = 0;
  String _userName = '';

  /// Carousel & list senkronizasyonu.
  final PageController _carouselController = PageController(viewportFraction: 0.92);
  int _currentCarouselIndex = 0;

  /// Marka filtresi. null = tümü.
  CardBrand? _brandFilter;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);

    try {
      final cards = await _cardService.getActiveCards();
      final totalDebt = await _cardService.getTotalDebtAllCards();
      final totalAvailable = await _cardService.getTotalAvailableCredit();
      final totalDue = await _cardService.getTotalDueThisMonth();
      final details = <String, Map<String, dynamic>>{};
      for (var card in cards) {
        details[card.id] = await _cardService.getCardWithDetails(card.id);
      }
      
      final user = await _dataService.getCurrentUser();

      setState(() {
        _cards = cards;
        _cardDetails = details;
        _totalDebt = totalDebt;
        _totalAvailableCredit = totalAvailable;
        _totalDueThisMonth = totalDue;
        _userName = user?.name ?? 'KART SAHİBİ';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _deleteCard(CreditCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kartı Sil'),
        content: Text(
          '${card.bankName} ${card.cardName} kartını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _cardService.deleteCard(card.id);
        _loadCards();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Kart silindi')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _selectedTab == 0 ? 'Kredi Kartlarım' : 'Taksit Takibi',
        ),
        actions: [
          if (_selectedTab == 0)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'Raporlar',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CardReportingScreen(),
                  ),
                );
              },
            ),
          if (_selectedTab == 0)
            IconButton(
              icon: const Icon(Icons.style_outlined),
              tooltip: 'Kart Tasarımları',
              onPressed: _openThemeGallery,
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCards),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTabSelector(),
                if (_selectedTab == 0) _buildSummaryCard(),
                Expanded(
                  child: _selectedTab == 0
                      ? (_cards.isEmpty ? _buildEmptyState() : _buildCardList())
                      : const InstallmentTrackingScreen(),
                ),
              ],
            ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: _navigateToAddCard,
              tooltip: 'Kart Ekle',
              child: const Icon(Icons.add_card),
            )
          : null,
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2E)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? const Color(0xFF00BFA5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: _selectedTab == 0
                          ? Colors.white
                          : Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Kartlar',
                      style: TextStyle(
                        color: _selectedTab == 0
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: _selectedTab == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? const Color(0xFF00BFA5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.format_list_numbered,
                      color: _selectedTab == 1
                          ? Colors.white
                          : Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Taksitler',
                      style: TextStyle(
                        color: _selectedTab == 1
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: _selectedTab == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Toplam Borç',
                  _currencyFormat.format(_totalDebt),
                  Colors.red,
                  Icons.credit_card,
                ),
                _buildSummaryItem(
                  'Kullanılabilir Limit',
                  _currencyFormat.format(_totalAvailableCredit),
                  Colors.green,
                  Icons.account_balance_wallet,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Bu Ay Ödenecek: ${_currencyFormat.format(_totalDueThisMonth)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Henüz kredi kartı eklenmemiş',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Kredi kartlarınızı takip etmeye başlamak için\n"Kart Ekle" butonuna tıklayın',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList() {
    final filteredCards = _filterCards();
    final displayCards = filteredCards.isEmpty ? _cards : filteredCards;

    if (displayCards.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      slivers: [
        // 1. Marka filtre şeridi
        SliverToBoxAdapter(child: _buildBrandFilterStrip()),

        // 2. Öne çıkan kart carousel'i
        SliverToBoxAdapter(child: _buildCarouselSection(displayCards)),

        // 3. Tüm kartlar başlığı
        SliverToBoxAdapter(child: _buildListHeader(displayCards.length)),

        // 4. Sıralanabilir kompakt liste
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverReorderableList(
            itemCount: displayCards.length,
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) async {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = displayCards.removeAt(oldIndex);
                displayCards.insert(newIndex, item);
                // Filtre devrede değilse _cards'ı da güncelle
                if (_brandFilter == null) {
                  _cards
                    ..clear()
                    ..addAll(displayCards);
                }
              });

              await _cardService.reorderCards(_cards);
            },
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (BuildContext context, Widget? child) {
                  final double animValue = Curves.easeInOut.transform(
                    animation.value,
                  );
                  final double elevation = lerpDouble(0, 6, animValue)!;
                  return Material(
                    elevation: elevation,
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final card = displayCards[index];
              return Padding(
                key: ValueKey(card.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildCompactListItem(card, index, displayCards),
              );
            },
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  /// Mevcut marka filtresine göre kartları daraltır.
  List<CreditCard> _filterCards() {
    if (_brandFilter == null) return _cards;
    return _cards
        .where((c) =>
            BankCardEntityHelper.resolveBrand(c) == _brandFilter)
        .toList();
  }

  /// Yatay kaydırılabilir marka filtre şeridi.
  Widget _buildBrandFilterStrip() {
    final availableBrands = <CardBrand>{
      for (final c in _cards) BankCardEntityHelper.resolveBrand(c),
    }.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    if (availableBrands.length < 2) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          _FilterChip(
            label: 'Tümü',
            isSelected: _brandFilter == null,
            onTap: () => _setBrandFilter(null),
          ),
          const SizedBox(width: 6),
          ...availableBrands.map(
            (b) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(
                label: b.displayName,
                isSelected: _brandFilter == b,
                onTap: () => _setBrandFilter(b),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setBrandFilter(CardBrand? brand) {
    setState(() {
      _brandFilter = brand;
      _currentCarouselIndex = 0;
      // Filtre değiştiğinde carousel'i başa sar
      if (_carouselController.hasClients) {
        _carouselController.jumpToPage(0);
      }
    });
  }

  /// Carousel bölümü: başlık + PageView + gösterge noktaları.
  Widget _buildCarouselSection(List<CreditCard> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              Text(
                'Öne Çıkan',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              Text(
                '${_currentCarouselIndex + 1}/${cards.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
        BankCardCarousel(
          controller: _carouselController,
          cards: cards
              .map((c) => _buildCarouselCard(
                    c,
                    _cardDetails[c.id],
                  ))
              .toList(),
          height: 240,
          showIndicator: true,
          onPageChanged: _onCarouselPageChanged,
        ),
      ],
    );
  }

  /// Carousel içinde gösterilecek tam boy kart.
  Widget _buildCarouselCard(
    CreditCard card,
    Map<String, dynamic>? details,
  ) {
    final currentDebt = (details?['currentDebt'] as double?) ?? 0;
    return BankCardWidget(
      bankName: card.bankName,
      last4Digits: card.last4Digits,
      brand: BankCardEntityHelper.resolveBrand(card),
      cardHolderName: _userName.isEmpty ? null : _userName,
      expirationDate: card.expirationDate,
      network: BankCardEntityHelper.resolveNetwork(card),
      currentDebt: currentDebt,
      creditLimit: card.creditLimit,
      showDebtInfo: true,
      onTap: () => _navigateToCardDetail(card),
    );
  }

  void _onCarouselPageChanged(int index) {
    setState(() => _currentCarouselIndex = index);
  }

  /// "Tüm Kartlar (n)" başlığı.
  Widget _buildListHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Text(
            'Tüm Kartlar',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const Spacer(),
          if (_brandFilter != null)
            TextButton.icon(
              onPressed: () => _setBrandFilter(null),
              icon: const Icon(Icons.clear, size: 14),
              label: const Text('Filtreyi temizle'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
        ],
      ),
    );
  }

  /// Kompakt liste satırı: mini kart + banka adı + son 4 + aksiyonlar.
  Widget _buildCompactListItem(
    CreditCard card,
    int index,
    List<CreditCard> contextCards,
  ) {
    final cardIndex = _cards.indexOf(card);
    final canReorder = _brandFilter == null;
    return BankCardListItem(
      bankName: card.bankName,
      last4Digits: card.last4Digits,
      brand: BankCardEntityHelper.resolveBrand(card),
      cardHolderName: _userName,
      isSelected: _brandFilter == null && index == _currentCarouselIndex,
      onTap: () => _navigateToCardDetail(card),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canReorder && cardIndex >= 0)
            ReorderableDragStartListener(
              index: cardIndex,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.drag_handle, size: 22),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Kart işlemleri',
            onSelected: (value) {
              if (value == 'delete') {
                _deleteCard(card);
              } else if (value == 'detail') {
                _navigateToCardDetail(card);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'detail',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Detay'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Future<void> _navigateToAddCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCreditCardScreen()),
    );

    if (result == true) {
      _loadCards();
    }
  }

  Future<void> _navigateToCardDetail(CreditCard card) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreditCardDetailScreen(card: card),
      ),
    );

    if (result == true) {
      _loadCards();
    }
  }

  /// Tüm temaları alt sayfa olarak açar; seçilen temayı filtre olarak uygular.
  Future<void> _openThemeGallery() async {
    final selected = await showModalBottomSheet<CardBrand>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(sheetContext).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          'Kart Tasarımları',
                          style: Theme.of(sheetContext)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: BankCardThemePicker(
                        selected: _brandFilter,
                        onSelected: (b) {
                          Navigator.pop(sheetContext, b);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected != null && mounted) {
      _setBrandFilter(selected);
    }
  }
}

/// Marka filtre şeridinde kullanılan küçük chip.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isSelected
          ? scheme.primary
          : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? scheme.onPrimary
                  : scheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}
