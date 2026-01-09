import 'package:flutter/material.dart';
import '../models/bill_template.dart';
import '../l10n/app_localizations.dart';

class BillHelper {
  static String getCategoryName(BuildContext context, BillTemplateCategory category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case BillTemplateCategory.electricity:
        return l10n.billElectricity;
      case BillTemplateCategory.water:
        return l10n.billWater;
      case BillTemplateCategory.gas:
        return l10n.billGas;
      case BillTemplateCategory.internet:
        return l10n.billInternet;
      case BillTemplateCategory.phone:
        return l10n.billPhone;
      case BillTemplateCategory.rent:
        return l10n.billRent;
      case BillTemplateCategory.insurance:
        return l10n.billInsurance;
      case BillTemplateCategory.subscription:
        return l10n.billSubscription;
      case BillTemplateCategory.other:
        return l10n.billOther;
    }
  }

  static IconData getCategoryIcon(BillTemplateCategory category) {
    switch (category) {
      case BillTemplateCategory.electricity:
        return Icons.bolt;
      case BillTemplateCategory.water:
        return Icons.water_drop;
      case BillTemplateCategory.gas:
        return Icons.local_fire_department;
      case BillTemplateCategory.internet:
        return Icons.wifi;
      case BillTemplateCategory.phone:
        return Icons.phone;
      case BillTemplateCategory.rent:
        return Icons.home;
      case BillTemplateCategory.insurance:
        return Icons.shield;
      case BillTemplateCategory.subscription:
        return Icons.subscriptions;
      case BillTemplateCategory.other:
        return Icons.receipt;
    }
  }
}
