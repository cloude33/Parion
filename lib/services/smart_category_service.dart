import '../models/transaction.dart';
import '../models/category.dart';
import 'data_service.dart';

class SmartCategoryService {
  static final SmartCategoryService _instance =
      SmartCategoryService._internal();
  factory SmartCategoryService() => _instance;
  SmartCategoryService._internal();

  final DataService _dataService = DataService();
  
  Future<CategorySuggestion?> suggestCategory(
    String description,
    String type,
  ) async {
    if (description.trim().isEmpty) return null;

    final transactions = await _dataService.getTransactions();
    final wallets = await _dataService.getWallets();
    final categories = (await _dataService.getCategories()).cast<Category>();
    final relevantTransactions = transactions
        .where((t) => t.type == type)
        .toList();

    if (relevantTransactions.isEmpty) return null;
    final suggestions = <CategorySuggestion>[];
    
    // Tam eşleşme kontrolü
    final exactMatch = _findExactMatch(description, relevantTransactions);
    if (exactMatch != null) {
      final matchingTransactions = _getMatchingTransactions(
        description,
        relevantTransactions,
        exactMatch,
      );
      
      // Ortalama tutar ve en sık kullanılan cüzdan hesapla
      final amountWalletInfo = _calculateAmountAndWalletSuggestion(
        matchingTransactions,
        wallets,
      );
      
      suggestions.add(
        CategorySuggestion(
          category: exactMatch,
          confidence: 1.0,
          reason: 'Tam eşleşme',
          matchedTransactions: matchingTransactions,
          suggestedAmount: amountWalletInfo['amount'],
          suggestedWalletId: amountWalletInfo['walletId'],
          suggestedWalletName: amountWalletInfo['walletName'],
          transactionCount: matchingTransactions.length,
        ),
      );
    }
    
    final partialMatches = _findPartialMatches(
      description,
      relevantTransactions,
      categories,
      wallets,
    );
    suggestions.addAll(partialMatches);
    
    final keywordMatches = _findKeywordMatches(description, type, categories);
    suggestions.addAll(keywordMatches);

    if (suggestions.isEmpty) return null;
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions.first;
  }
  
  /// Eşleşen işlemlerden ortalama tutar ve en sık kullanılan cüzdanı hesaplar
  Map<String, dynamic> _calculateAmountAndWalletSuggestion(
    List<Transaction> transactions,
    List wallets,
  ) {
    if (transactions.isEmpty) {
      return {'amount': null, 'walletId': null, 'walletName': null};
    }
    
    // Ortalama tutar hesapla
    final totalAmount = transactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
    final averageAmount = totalAmount / transactions.length;
    
    // En sık kullanılan cüzdanı bul
    final walletCounts = <String, int>{};
    for (var t in transactions) {
      walletCounts[t.walletId] = (walletCounts[t.walletId] ?? 0) + 1;
    }
    
    String? mostUsedWalletId;
    int maxCount = 0;
    walletCounts.forEach((walletId, count) {
      if (count > maxCount) {
        maxCount = count;
        mostUsedWalletId = walletId;
      }
    });
    
    // Cüzdan adını bul
    String? walletName;
    if (mostUsedWalletId != null) {
      final wallet = wallets.firstWhere(
        (w) => w.id == mostUsedWalletId,
        orElse: () => null,
      );
      walletName = wallet?.name;
    }
    
    return {
      'amount': averageAmount,
      'walletId': mostUsedWalletId,
      'walletName': walletName,
    };
  }
  
  String? _findExactMatch(String description, List<Transaction> transactions) {
    final normalized = _normalizeText(description);

    for (var transaction in transactions) {
      if (_normalizeText(transaction.description) == normalized) {
        return transaction.category;
      }
    }

    return null;
  }
  List<CategorySuggestion> _findPartialMatches(
    String description,
    List<Transaction> transactions,
    List<Category> categories,
    List wallets,
  ) {
    final suggestions = <CategorySuggestion>[];
    final descWords = _extractWords(description);

    if (descWords.isEmpty) return suggestions;
    final categoryScores = <String, CategoryScore>{};

    for (var transaction in transactions) {
      final transWords = _extractWords(transaction.description);
      final similarity = _calculateSimilarity(descWords, transWords);

      if (similarity > 0.3) {
        final category = transaction.category;
        if (!categoryScores.containsKey(category)) {
          categoryScores[category] = CategoryScore(
            category: category,
            totalScore: 0,
            count: 0,
            matchedTransactions: [],
          );
        }

        categoryScores[category]!.totalScore += similarity;
        categoryScores[category]!.count++;
        categoryScores[category]!.matchedTransactions.add(transaction);
      }
    }
    for (var entry in categoryScores.entries) {
      final avgScore = entry.value.totalScore / entry.value.count;
      final confidence = avgScore * (entry.value.count / transactions.length);

      if (confidence > 0.2) {
        final matchedTrans = entry.value.matchedTransactions.take(5).toList();
        final amountWalletInfo = _calculateAmountAndWalletSuggestion(
          matchedTrans,
          wallets,
        );
        
        suggestions.add(
          CategorySuggestion(
            category: entry.key,
            confidence: confidence,
            reason: '${entry.value.count} benzer işlem',
            matchedTransactions: matchedTrans.take(3).toList(),
            suggestedAmount: amountWalletInfo['amount'],
            suggestedWalletId: amountWalletInfo['walletId'],
            suggestedWalletName: amountWalletInfo['walletName'],
            transactionCount: entry.value.count,
          ),
        );
      }
    }

    return suggestions;
  }
  List<CategorySuggestion> _findKeywordMatches(
    String description,
    String type,
    List<Category> categories,
  ) {
    final suggestions = <CategorySuggestion>[];
    final normalized = _normalizeText(description);
    final keywordMap = _getKeywordMap(type);

    for (var entry in keywordMap.entries) {
      final categoryName = entry.key;
      final keywords = entry.value;

      for (var keyword in keywords) {
        if (normalized.contains(_normalizeText(keyword))) {
          final categoryExists = categories.any(
            (c) => c.name == categoryName && c.type == type,
          );

          if (categoryExists) {
            suggestions.add(
              CategorySuggestion(
                category: categoryName,
                confidence: 0.7,
                reason: 'Anahtar kelime: "$keyword"',
                matchedTransactions: [],
              ),
            );
            break;
          }
        }
      }
    }

    return suggestions;
  }
  Map<String, List<String>> _getKeywordMap(String type) {
    if (type == 'expense') {
      return {
        'Yiyecek': [
          'market',
          'süpermarket',
          'migros',
          'a101',
          'bim',
          'şok',
          'carrefour',
          'yemek',
          'restaurant',
          'restoran',
          'cafe',
          'kahve',
          'starbucks',
          'mcdonald',
          'burger king',
          'kfc',
          'popeyes',
          'dominos',
          'pizza',
          'döner',
          'kebap',
          'lokanta',
          'kahvaltı',
          'file',
          'metro market',
          'macro',
          'happy center',
          'kiler',
          'onur market',
          'çağdaş',
          'özdilek',
          'gratis',
        ],
        'Ulaşım': [
          'benzin',
          'akaryakıt',
          'otobüs',
          'metro',
          'taksi',
          'uber',
          'bitaksi',
          'otopark',
          'shell',
          'opet',
          'bp',
          'petrol ofisi',
          'total',
          'lukoil',
          'eshot',
          'izban',
          'iett',
          'ego',
          'kent kart',
          'istanbulkart',
          'bilet',
          'köprü',
          'geçiş',
          'hgs',
          'ogs',
          'vapur',
          'feribot',
          'tren',
          'tcdd',
          'thy',
          'pegasus',
          'anadolujet',
          'sunexpress',
          'uçak',
          'havaalanı',
          'otogar',
          'servis',
        ],
        'Faturalar': [
          'elektrik',
          'su',
          'doğalgaz',
          'internet',
          'telefon',
          'fatura',
          'aidat',
          'turkcell',
          'vodafone',
          'türk telekom',
          'superonline',
          'ttnet',
          'gediz',
          'izsu',
          'izmirgaz',
          'igdaş',
          'iski',
          'enerjisa',
          'clk',
          'toroslar',
          'başkent',
          'aydem',
          'dicle',
          'boğaziçi',
          'gediz edaş',
          'abonelik',
          'kontör',
        ],
        'Sağlık': [
          'eczane',
          'hastane',
          'doktor',
          'ilaç',
          'sağlık',
          'diş',
          'muayene',
          'klinik',
          'laboratuvar',
          'tahlil',
          'röntgen',
          'mr',
          'tomografi',
          'aşı',
          'vitamin',
          'dermokozmetik',
          'optik',
          'gözlük',
          'lens',
        ],
        'Eğlence': [
          'sinema',
          'konser',
          'tiyatro',
          'netflix',
          'spotify',
          'eğlence',
          'youtube premium',
          'disney',
          'amazon prime',
          'exxen',
          'blu tv',
          'gain',
          'oyun',
          'playstation',
          'xbox',
          'steam',
          'apple music',
          'deezer',
          'fizy',
        ],
        'Giyim': [
          'giyim',
          'ayakkabı',
          'kıyafet',
          'zara',
          'h&m',
          'mango',
          'lcwaikiki',
          'defacto',
          'koton',
          'mavi',
          'boyner',
          'vakko',
          'beymen',
          'network',
          'marks spencer',
          'ipekyol',
          'machka',
          'adl',
          'skechers',
          'nike',
          'adidas',
          'puma',
          'flo',
          'deichmann',
          'kiğılı',
          'altınyıldız',
          'damat tween',
          'pierre cardin',
        ],
        'Eğitim': [
          'okul',
          'kurs',
          'kitap',
          'eğitim',
          'üniversite',
          'dershane',
          'özel ders',
          'yds',
          'toefl',
          'ielts',
          'udemy',
          'coursera',
          'kırtasiye',
          'bosphorus kitap',
          'd&r',
          'idefix',
          'kitapyurdu',
        ],
        'Alışveriş': [
          'amazon',
          'trendyol',
          'hepsiburada',
          'n11',
          'gittigidiyor',
          'çiçeksepeti',
          'teknosa',
          'mediamarkt',
          'vatan',
          'ikea',
          'koçtaş',
          'bauhaus',
          'bricomarche',
          'ev depo',
          'english home',
          'madame coco',
          'yataş',
        ],
        'Fitness': [
          'spor',
          'fitness',
          'gym',
          'yoga',
          'pilates',
          'marsgym',
          'macfit',
          'spor salonu',
          'fitness merkezi',
          'havuz',
          'yüzme',
        ],
        'Kişisel Bakım': [
          'kuaför',
          'berber',
          'güzellik',
          'spa',
          'masaj',
          'manikür',
          'pedikür',
          'waxing',
          'epilasyon',
          'saç',
          'cilt bakımı',
        ],
        'Ev & Yaşam': [
          'temizlik',
          'deterjan',
          'ev gereçleri',
          'mobilya',
          'beyaz eşya',
          'küçük ev aletleri',
          'tamirat',
          'tesisatçı',
          'elektrikçi',
        ],
        'Evcil Hayvan': [
          'veteriner',
          'petshop',
          'mama',
          'kedi',
          'köpek',
          'kuş',
          'akvaryum',
        ],
        'Hediye': [
          'hediye',
          'doğum günü',
          'kutlama',
          'çiçek',
          'pasta',
        ],
        'Sigorta': [
          'sigorta',
          'kasko',
          'trafik',
          'sağlık sigortası',
          'hayat sigortası',
        ],
      };
    } else {
      return {
        'Maaş': ['maaş', 'ücret', 'salary', 'gelir', 'bordro'],
        'Yatırım': [
          'yatırım',
          'hisse',
          'borsa',
          'kripto',
          'bitcoin',
          'ethereum',
          'altın',
          'döviz',
          'faiz',
          'temettü',
          'kar payı',
        ],
        'Hediye': ['hediye', 'gift', 'bayram', 'doğum günü'],
        'Ödül': ['ödül', 'bonus', 'prim', 'ikramiye'],
        'Kira': ['kira geliri', 'kira', 'kiracı'],
        'Freelance': ['freelance', 'serbest', 'danışmanlık', 'proje'],
        'İade': ['iade', 'geri ödeme', 'refund', 'cashback'],
        'Satış': ['satış', 'ikinci el', 'sahibinden', 'letgo'],
      };
    }
  }
  List<Transaction> _getMatchingTransactions(
    String description,
    List<Transaction> transactions,
    String category,
  ) {
    final normalized = _normalizeText(description);
    final descWords = _extractWords(description);

    return transactions
        .where((t) => t.category == category)
        .where((t) {
          final transNormalized = _normalizeText(t.description);
          final transWords = _extractWords(t.description);

          return transNormalized == normalized ||
              _calculateSimilarity(descWords, transWords) > 0.5;
        })
        .take(5)
        .toList();
  }
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
  List<String> _extractWords(String text) {
    final normalized = _normalizeText(text);
    final words = normalized.split(' ');
    final stopWords = {'ve', 'ile', 'için', 'bir', 'bu', 'şu', 'o', 'de', 'da'};

    return words.where((w) => w.length > 2 && !stopWords.contains(w)).toList();
  }
  double _calculateSimilarity(List<String> words1, List<String> words2) {
    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final set1 = words1.toSet();
    final set2 = words2.toSet();

    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;

    return union > 0 ? intersection / union : 0.0;
  }
  Future<Map<String, CategoryStats>> getCategoryStats(String type) async {
    final transactions = await _dataService.getTransactions();
    final stats = <String, CategoryStats>{};

    for (var transaction in transactions.where((t) => t.type == type)) {
      if (!stats.containsKey(transaction.category)) {
        stats[transaction.category] = CategoryStats(
          category: transaction.category,
          count: 0,
          totalAmount: 0,
          descriptions: {},
        );
      }

      stats[transaction.category]!.count++;
      stats[transaction.category]!.totalAmount += transaction.amount;

      final normalized = _normalizeText(transaction.description);
      stats[transaction.category]!.descriptions[normalized] =
          (stats[transaction.category]!.descriptions[normalized] ?? 0) + 1;
    }

    return stats;
  }
  Future<List<Transaction>> findSimilarTransactions(
    String description,
    String type,
  ) async {
    final transactions = await _dataService.getTransactions();
    final descWords = _extractWords(description);

    if (descWords.isEmpty) return [];

    final similar = <TransactionSimilarity>[];

    for (var transaction in transactions.where((t) => t.type == type)) {
      final transWords = _extractWords(transaction.description);
      final similarity = _calculateSimilarity(descWords, transWords);

      if (similarity > 0.3) {
        similar.add(
          TransactionSimilarity(
            transaction: transaction,
            similarity: similarity,
          ),
        );
      }
    }

    similar.sort((a, b) => b.similarity.compareTo(a.similarity));
    return similar.take(10).map((s) => s.transaction).toList();
  }
}
class CategorySuggestion {
  final String category;
  final double confidence;
  final String reason;
  final List<Transaction> matchedTransactions;
  final double? suggestedAmount;  // Ortalama tutar önerisi
  final String? suggestedWalletId;  // En sık kullanılan cüzdan
  final String? suggestedWalletName; // Cüzdan adı
  final int transactionCount;  // Bu açıklama ile kaç işlem yapılmış

  CategorySuggestion({
    required this.category,
    required this.confidence,
    required this.reason,
    required this.matchedTransactions,
    this.suggestedAmount,
    this.suggestedWalletId,
    this.suggestedWalletName,
    this.transactionCount = 0,
  });
}

class CategoryScore {
  final String category;
  double totalScore;
  int count;
  List<Transaction> matchedTransactions;

  CategoryScore({
    required this.category,
    required this.totalScore,
    required this.count,
    required this.matchedTransactions,
  });
}

class CategoryStats {
  final String category;
  int count;
  double totalAmount;
  Map<String, int> descriptions;

  CategoryStats({
    required this.category,
    required this.count,
    required this.totalAmount,
    required this.descriptions,
  });

  double get averageAmount => count > 0 ? totalAmount / count : 0;
}

class TransactionSimilarity {
  final Transaction transaction;
  final double similarity;

  TransactionSimilarity({required this.transaction, required this.similarity});
}
