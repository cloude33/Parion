import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../models/user.dart';
import '../../services/safe_to_spend_service.dart';
import '../../utils/currency_helper.dart';

/// Home-screen card that answers "how much can I still spend today?".
///
/// It listens to [refreshToken] so the home screen can rebuild the numbers
/// after transactions, wallets or loans change without owning the calculation.
class SafeToSpendCard extends StatefulWidget {
  const SafeToSpendCard({super.key, this.user, this.refreshToken = 0});

  final User? user;
  final int refreshToken;

  @override
  State<SafeToSpendCard> createState() => _SafeToSpendCardState();
}

class _SafeToSpendCardState extends State<SafeToSpendCard> {
  final SafeToSpendService _service = SafeToSpendService();

  SafeToSpendBreakdown? _breakdown;
  bool _loading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SafeToSpendCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final breakdown = await _service.calculate();
      if (!mounted) return;
      setState(() {
        _breakdown = breakdown;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  String _money(double value) =>
      CurrencyHelper.formatAmount(value, widget.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final breakdown = _breakdown;

    if (_loading && breakdown == null) {
      return const SizedBox(
        height: 104,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (breakdown == null) {
      return const SizedBox(height: 104);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.savings_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'GÜVENLE HARCANABİLİR',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const Spacer(),
            Text(
              'bugün',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            _money(breakdown.perDay),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          breakdown.remainingDays == 1
              ? 'Ayın son günü için kalan tutar'
              : 'Ayın kalan ${breakdown.remainingDays} gününe bölündü',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildStat('Kalan bütçe', _money(breakdown.available)),
            _buildStat('Sabit ödemeler', _money(breakdown.upcomingFixed)),
            _buildStat('Harcanan', _money(breakdown.spentSoFar)),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: 12),
          if (breakdown.upcomingItems.isEmpty)
            Text(
              'Bu ay için bekleyen sabit ödeme yok.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            )
          else ...[
            Text(
              'Bu ayın kalan ödemeleri',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in breakdown.upcomingItems.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${item.label} · ${item.dueDate.day}. gün',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _money(item.amount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (breakdown.upcomingItems.length > 5)
              Text(
                '+${breakdown.upcomingItems.length - 5} ödeme daha',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
          ],
          const SizedBox(height: 10),
          Text(
            breakdown.usesBalanceFallback
                ? 'Bu ay gelir kaydı olmadığı için toplam bakiye üzerinden hesaplandı. '
                      'Kredi kartı ekstreleri de dahil edilmiştir.'
                : 'Bu ayın gelirinden harcananlar ve kalan sabit ödemeler düşüldü. '
                      'Kredi kartı ekstreleri de dahil edilmiştir.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
