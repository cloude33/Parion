# Parion App Context

## Overview
Parion is a Flutter application designed for financial tracking. It handles wallets, credit cards, transactions (income/expense), goals, bills, recurring transactions, loans, and KMH (Kredili Mevduat Hesabı) tracking. 

## Key Directories
- `lib/models/`: Contains data models like `Wallet`, `Transaction`, `CreditCard`, `CreditCardTransaction`, `Goal`, `Loan`, `KmhAlert`, `User`, `Category`.
- `lib/screens/`: Contains the UI screens.
  - `home_screen.dart`: Main dashboard screen showing summary, list of transactions, and quick links.
  - `add_transaction_screen.dart`, `edit_transaction_screen.dart`: For managing regular transactions.
  - `statistics_screen.dart`: For charts and reports.
  - `settings_screen.dart`: App configuration.
- `lib/services/`: Business logic, local storage or API integrations.
  - `data_service.dart`: Main data repository.
  - `credit_card_service.dart`: Credit card related operations.
  - `notification_service.dart`: Handles app notifications.
- `lib/utils/`: Helpers like `currency_helper.dart` for formatting and `app_icons.dart` for category icons.
- `lib/widgets/`: Reusable UI components.

## Application Structure
- The app uses a bottom navigation bar (`AppBottomNavBar`) typically found in `HomeScreen` to switch between main views: Home, Credit Cards, KMH List, Statistics, and Settings.
- Data persistence seems to rely on local storage (maybe shared_preferences or Hive/sqflite, handled by `DataService`).
- State management mostly uses `StatefulWidget` and `setState` inside screens, loading data via services in `initState`/`didChangeAppLifecycleState`.

## User Objective Details
The user is focusing on the `home_screen.dart`. The home screen displays a summary card, KMH alerts, recent transactions, and goals. It also has a toggle between list and calendar modes.
