import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../models/wallet.dart';
import '../services/data_service.dart';

class LoanDetailScreen extends StatefulWidget {
  final Loan loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  late Loan _loan;
  final DataService _dataService = DataService();
  List<Wallet> _wallets = [];

  @override
  void initState() {
    super.initState();
    _loan = widget.loan;
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final wallets = await _dataService.getWallets();
    setState(() {
      _wallets = wallets;
    });
  }

  Future<void> _payInstallment(LoanInstallment installment) async {
    if (_wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödeme yapılacak cüzdan bulunamadı!')),
      );
      return;
    }

    String? selectedWalletId =
        _loan.walletId; // Varsayılan olarak kredinin cüzdanı

    // Eğer kredinin cüzdanı silinmişse veya listede yoksa ilk cüzdanı seç
    if (!_wallets.any((w) => w.id == selectedWalletId)) {
      selectedWalletId = _wallets.first.id;
    }

    final currencyFormat = NumberFormat('#,##0.00', 'tr_TR');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Taksit Ödemesi'),
        content: StatefulBuilder(
          builder: (dialogContext, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${installment.installmentNumber}. Taksit Tutarı: ${currencyFormat.format(installment.amount)} TL\n\nÖdeme yapılacak cüzdanı seçiniz:',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedWalletId,
                  decoration: const InputDecoration(
                    labelText: 'Cüzdan',
                    border: OutlineInputBorder(),
                  ),
                  items: _wallets.map((wallet) {
                    return DropdownMenuItem(
                      value: wallet.id,
                      child: Text(
                        '${wallet.name} (${currencyFormat.format(wallet.balance)} TL)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedWalletId = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedWalletId == null) return;
              try {
                // Dialog'u kapat
                Navigator.pop(dialogContext);

                // Yükleniyor göster
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                await _dataService.payLoanInstallment(
                  loanId: _loan.id,
                  installmentNumber: installment.installmentNumber,
                  walletId: selectedWalletId!,
                );

                // Güncel krediyi çek
                final loans = await _dataService.getLoans();
                final updatedLoan = loans.firstWhere((l) => l.id == _loan.id);

                if (mounted) {
                  // Yükleniyor'u kapat
                  Navigator.pop(context);

                  setState(() {
                    _loan = updatedLoan;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Taksit ödemesi başarıyla gerçekleşti.'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  // Yükleniyor'u kapat (hata durumunda da)
                  Navigator.maybePop(context);

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                }
              }
            },
            child: const Text('Öde'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00', 'tr_TR');
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kredi Detayları'),
        backgroundColor: const Color(0xFF5E5CE6),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            _buildHeaderInfo(currencyFormat),
            const SizedBox(height: 24),

            // Payment Plan Title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: const Color(0xFF43A047), // Green like the image
              child: const Text(
                'Ödeme Planı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                columnSpacing: 20,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Tarih',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Taksit',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Anapara',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Faiz',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Fon',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Vergi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Kalan\nAnapara',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Ödeme\nTarihi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Ödeme\nTutarı',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Gecikme\nFaizi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'İşlem',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ), // Yeni sütun
                ],
                rows: [
                  ..._loan.installments.map((installment) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (installment.isPaid)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4.0),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                              Text(dateFormat.format(installment.dueDate)),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(currencyFormat.format(installment.amount)),
                        ),
                        DataCell(
                          Text(
                            currencyFormat.format(installment.principalAmount),
                          ),
                        ),
                        DataCell(
                          Text(
                            currencyFormat.format(installment.interestAmount),
                          ),
                        ),
                        DataCell(
                          Text(currencyFormat.format(installment.kkdfAmount)),
                        ),
                        DataCell(
                          Text(currencyFormat.format(installment.bsmvAmount)),
                        ),
                        DataCell(
                          Text(
                            currencyFormat.format(
                              installment.remainingPrincipalAmount,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            installment.paymentDate != null
                                ? dateFormat.format(installment.paymentDate!)
                                : '-',
                          ),
                        ),
                        DataCell(
                          Text(
                            installment.isPaid
                                ? currencyFormat.format(installment.amount)
                                : '0,00',
                          ),
                        ),
                        DataCell(const Text('0,00')),
                        DataCell(
                          installment.isPaid
                              ? const SizedBox.shrink()
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5E5CE6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    minimumSize: const Size(0, 32),
                                  ),
                                  onPressed: () => _payInstallment(installment),
                                  child: const Text(
                                    'Öde',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                        ),
                      ],
                    );
                  }),
                  // Footer Row
                  DataRow(
                    color: WidgetStateProperty.all(Colors.grey.shade100),
                    cells: [
                      const DataCell(
                        Text(
                          'TOPLAM',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          currencyFormat.format(
                            _calculateTotal(
                              _loan.installments,
                              (i) => i.amount,
                            ),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          currencyFormat.format(
                            _calculateTotal(
                              _loan.installments,
                              (i) => i.principalAmount,
                            ),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          currencyFormat.format(
                            _calculateTotal(
                              _loan.installments,
                              (i) => i.interestAmount,
                            ),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          currencyFormat.format(
                            _calculateTotal(
                              _loan.installments,
                              (i) => i.kkdfAmount,
                            ),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          currencyFormat.format(
                            _calculateTotal(
                              _loan.installments,
                              (i) => i.bsmvAmount,
                            ),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      DataCell(
                        Text(
                          currencyFormat.format(
                            _calculateTotal(
                              _loan.installments,
                              (i) => i.isPaid ? i.amount : 0,
                            ),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const DataCell(
                        Text(
                          '0,00',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const DataCell(Text('')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotal(
    List<LoanInstallment> installments,
    double Function(LoanInstallment) selector,
  ) {
    return installments.fold(0.0, (sum, item) => sum + selector(item));
  }

  Widget _buildHeaderInfo(NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kredi hesabınızın ödeme planı aşağıdaki gibidir.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        _buildInfoRow('Kredi Hesabı', ': ${_loan.name}'),
        _buildInfoRow('Banka', ': ${_loan.bankName}'),
        _buildInfoRow(
          'Kredi Tutarı',
          ': ${currencyFormat.format(_loan.totalAmount)} TL',
        ),
        _buildInfoRow(
          'Kalan Borç',
          ': ${currencyFormat.format(_loan.remainingAmount)} TL',
        ),
        if (_loan.installments.isNotEmpty &&
            _loan.installments.first.principalAmount > 0)
          _buildInfoRow(
            'Faiz Oranı (%)',
            ': %${_calculateRate(_loan).toStringAsFixed(2)}',
          ),

        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Tarih : ${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
          ),
        ),
      ],
    );
  }

  double _calculateRate(Loan loan) {
    if (loan.installments.isEmpty) return 0.0;
    final i = loan.installments.first;
    if (loan.totalAmount <= 0) return 0.0;
    return (i.interestAmount / loan.totalAmount) * 100;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
