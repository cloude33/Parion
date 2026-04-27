import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../services/data_service.dart';
import '../widgets/icon_picker_dialog.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subCategoryController = TextEditingController();
  String _selectedType = 'expense';
  bool _isBank = false;
  IconData _selectedIcon = Icons.category;
  Color _selectedColor = const Color(0xFF007AFF);
  final DataService _dataService = DataService();
  final List<String> _subCategories = [];

  // Extended color palette - iOS style
  final List<Color> _colorOptions = [
    // Row 1 - Primary colors
    const Color(0xFF007AFF), // iOS Blue
    const Color(0xFF34C759), // iOS Green
    const Color(0xFFFF9500), // iOS Orange
    const Color(0xFFFF3B30), // iOS Red
    const Color(0xFFAF52DE), // iOS Purple
    const Color(0xFFFF2D55), // iOS Pink
    const Color(0xFF5856D6), // iOS Indigo
    const Color(0xFF00C7BE), // iOS Teal
    // Row 2 - Secondary colors
    const Color(0xFF5AC8FA), // Light Blue
    const Color(0xFF4CD964), // Bright Green
    const Color(0xFFFFCC00), // Yellow
    const Color(0xFFFF6B6B), // Coral
    const Color(0xFF9B59B6), // Amethyst
    const Color(0xFFE91E63), // Material Pink
    const Color(0xFF3F51B5), // Material Indigo
    const Color(0xFF009688), // Material Teal
    // Row 3 - Dark/Muted colors
    const Color(0xFF8E8E93), // iOS Gray
    const Color(0xFF636366), // Dark Gray
    const Color(0xFF48484A), // Charcoal
    const Color(0xFF1C1C1E), // Near Black
    const Color(0xFF2C3E50), // Dark Blue
    const Color(0xFF27AE60), // Emerald
    const Color(0xFFE67E22), // Carrot
    const Color(0xFFC0392B), // Pomegranate
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _subCategoryController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      final newCategory = Category(
        id: const Uuid().v4(),
        name: _nameController.text,
        type: _selectedType,
        icon: _selectedIcon,
        color: _selectedColor,
        isBank: _isBank,
        subCategories: _subCategories,
      );

      await _dataService.addCategory(newCategory);

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _addSubCategory() {
    final subCat = _subCategoryController.text.trim();
    if (subCat.isNotEmpty && !_subCategories.contains(subCat)) {
      setState(() {
        _subCategories.add(subCat);
        _subCategoryController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _selectedColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yeni Kategori',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveCategory,
            child: Text(
              'Kaydet',
              style: TextStyle(
                color: _selectedColor,
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Preview Card at top
              _buildPreviewCard(cardColor, textColor, secondaryTextColor),
              
              const SizedBox(height: 24),

              // Category Name Section
              _buildSectionCard(
                cardColor: cardColor,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    placeholder: 'Kategori adı',
                    textColor: textColor,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen kategori adı girin';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Type Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'TÜR',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildSectionCard(
                cardColor: cardColor,
                children: [
                  _buildSegmentedControl(textColor),
                ],
              ),

              const SizedBox(height: 24),

              // Icon & Bank Section
              _buildSectionCard(
                cardColor: cardColor,
                children: [
                  _buildIconSelector(textColor, secondaryTextColor),
                  Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                  _buildBankToggle(textColor),
                ],
              ),

              const SizedBox(height: 24),

              // Color Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'RENK SEÇ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildColorPicker(cardColor),

              const SizedBox(height: 24),

              // Subcategories Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'ALT KATEGORİLER',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildSubcategoriesSection(cardColor, textColor, secondaryTextColor),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(Color cardColor, Color textColor, Color? secondaryTextColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _selectedColor,
            _selectedColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _selectedIcon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isEmpty ? 'Kategori Adı' : _nameController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedType == 'income' ? 'Gelir Kategorisi' : 'Gider Kategorisi',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                if (_subCategories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: _subCategories.take(3).map((sub) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sub,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Color cardColor, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required Color textColor,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: textColor, fontSize: 17),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildSegmentedControl(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _selectedType,
        children: {
          'expense': Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_upward,
                  size: 16,
                  color: _selectedType == 'expense' ? _selectedColor : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  'Gider',
                  style: TextStyle(
                    color: _selectedType == 'expense' ? _selectedColor : textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          'income': Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_downward,
                  size: 16,
                  color: _selectedType == 'income' ? _selectedColor : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  'Gelir',
                  style: TextStyle(
                    color: _selectedType == 'income' ? _selectedColor : textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        },
        onValueChanged: (value) {
          if (value != null) {
            setState(() => _selectedType = value);
          }
        },
      ),
    );
  }

  Widget _buildIconSelector(Color textColor, Color? secondaryTextColor) {
    return ListTile(
      onTap: () async {
        final selectedIcon = await showDialog<IconData>(
          context: context,
          builder: (context) => IconPickerDialog(
            initialIcon: _selectedIcon,
            selectedColor: _selectedColor,
          ),
        );
        if (selectedIcon != null) {
          setState(() => _selectedIcon = selectedIcon);
        }
      },
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _selectedColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_selectedIcon, color: Colors.white, size: 24),
      ),
      title: Text(
        'İkon',
        style: TextStyle(color: textColor, fontSize: 17),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: secondaryTextColor,
      ),
    );
  }

  Widget _buildBankToggle(Color textColor) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF34C759),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.account_balance, color: Colors.white, size: 24),
      ),
      title: Text(
        'Banka Kategorisi',
        style: TextStyle(color: textColor, fontSize: 17),
      ),
      trailing: CupertinoSwitch(
        value: _isBank,
        activeTrackColor: _selectedColor,
        onChanged: (value) {
          setState(() {
            _isBank = value;
            if (value) {
              _selectedIcon = Icons.account_balance;
            }
          });
        },
      ),
    );
  }

  Widget _buildColorPicker(Color cardColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: _colorOptions.length,
        itemBuilder: (context, index) {
          final color = _colorOptions[index];
          final isSelected = _selectedColor == color;
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubcategoriesSection(Color cardColor, Color textColor, Color? secondaryTextColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subCategoryController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Alt kategori adı',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _selectedColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => _addSubCategory(),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: _addSubCategory,
                    icon: const Icon(Icons.add, color: Colors.white),
                    tooltip: 'Ekle',
                  ),
                ),
              ],
            ),
          ),
          if (_subCategories.isNotEmpty) ...[
            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subCategories.map((sub) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sub,
                          style: TextStyle(
                            color: _selectedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() => _subCategories.remove(sub));
                          },
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: _selectedColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
