import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/services/image_compress.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/animations.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/category_model.dart';
import '../../../products/presentation/providers/products_provider.dart';

class AdminProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AdminProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<AdminProductFormScreen> createState() =>
      _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends ConsumerState<AdminProductFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _careCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  bool _isActive = true;
  bool _featured = false;
  bool _isNew = true;
  bool _isOnSale = false;
  bool _isSustainable = false;
  String? _categoryId;
  List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL'];
  List<String> _images = [];
  Map<String, int> _stockBySize = {};
  String? _selectedCategoryName;
  bool _showMeasurements = false;
  String? _selectedMeasurementSize;
  Map<String, Map<String, List<int>>> _sizeMeasurements = {};

  bool _loading = false;
  bool _isEdit = false;
  bool _uploadingImage = false;

  late final AnimationController _animCtrl;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _anims = createStaggerAnimations(
      controller: _animCtrl,
      count: 10,
      delayPerItem: 0.06,
      itemDuration: 0.28,
    );
    if (widget.productId != null) {
      _isEdit = true;
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('*, categories(name)')
          .eq('id', widget.productId!)
          .single();

      final product = ProductModel.fromJson(response);
      _nameCtrl.text = product.name;
      _descCtrl.text = product.description ?? '';
      _priceCtrl.text = (product.price / 100).toStringAsFixed(2);
      _salePriceCtrl.text = product.salePrice != null
          ? (product.salePrice! / 100).toStringAsFixed(2)
          : '';
      _stockCtrl.text = product.stock.toString();
      _skuCtrl.text = product.sku ?? '';
      _materialCtrl.text = product.material ?? '';
      _careCtrl.text = product.careInstructions ?? '';
      _weightCtrl.text = product.weightGrams?.toString() ?? '';

      setState(() {
        _isActive = product.isActive;
        _featured = product.featured;
        _isNew = product.isNew;
        _isOnSale = product.isOnSale;
        _isSustainable = product.isSustainable;
        _categoryId = product.categoryId;
        _selectedCategoryName = product.categories?['name'] as String?;
        _sizes = List<String>.from(product.sizes);
        _images = List<String>.from(product.images);
        _stockBySize = Map<String, int>.from(product.stockBySize);
        if (product.sizeMeasurements != null &&
            (product.sizeMeasurements!).isNotEmpty) {
          _showMeasurements = true;
          _loadMeasurementsFromJson(product.sizeMeasurements!);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando producto: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _salePriceCtrl.dispose();
    _stockCtrl.dispose();
    _skuCtrl.dispose();
    _materialCtrl.dispose();
    _careCtrl.dispose();
    _weightCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══ COMPACT APP BAR ═══
          SliverAppBar(
            expandedHeight: 0,
            toolbarHeight: 52,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.06),
                  ),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              ),
              onPressed: () => context.pop(),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.gold500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _isEdit ? Icons.edit_rounded : Icons.add_rounded,
                    size: 13,
                    color: AppColors.gold500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isEdit ? 'Editar Producto' : 'Nuevo Producto',
                  style: AppTextStyles.h4.copyWith(fontSize: 15),
                ),
              ],
            ),
            centerTitle: true,
          ),

          // ═══ BODY — sectioned form ═══
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _fadeSlide(0, _buildImagesSection()),
                      const SizedBox(height: 16),
                      _fadeSlide(1, _buildBasicInfoSection()),
                      const SizedBox(height: 16),
                      _fadeSlide(2, _buildPricingSection()),
                      const SizedBox(height: 16),
                      _fadeSlide(3, _buildCategorySection(categoriesAsync)),
                      const SizedBox(height: 16),
                      _fadeSlide(4, _buildStockBySizeSection()),
                      const SizedBox(height: 16),
                      _fadeSlide(5, _buildSizeMeasurementsSection()),
                      const SizedBox(height: 16),
                      _fadeSlide(6, _buildDetailsSection()),
                      const SizedBox(height: 16),
                      _fadeSlide(7, _buildTogglesSection()),
                      const SizedBox(height: 28),
                      _fadeSlide(8, _buildSaveButton()),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fadeSlide(int index, Widget child) {
    final i = index.clamp(0, _anims.length - 1);
    return FadeSlideItem(index: index, animation: _anims[i], child: child);
  }

  // ─── SECTION CARD WRAPPER ───
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accent, size: 15),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ─── IMAGES ───
  Widget _buildImagesSection() {
    return _sectionCard(
      icon: Icons.image_rounded,
      title: 'Imágenes del producto',
      accent: const Color(0xFF6366F1),
      child: Column(
        children: [
          SizedBox(
            height: 130,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._images.asMap().entries.map(
                  (e) => _buildImageThumb(e.key, e.value),
                ),
                _buildAddImageButton(),
              ],
            ),
          ),
          if (_images.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Añade al menos una imagen del producto',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageThumb(int index, String url) {
    return Container(
      width: 100,
      height: 130,
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedImage(
              imageUrl: url,
              width: 100,
              height: 130,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _images.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _uploadingImage ? null : _pickImage,
      child: Container(
        width: 100,
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: _uploadingImage
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6366F1),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Añadir',
                    style: TextStyle(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── BASIC INFO ───
  Widget _buildBasicInfoSection() {
    return _sectionCard(
      icon: Icons.info_outline_rounded,
      title: 'Información básica',
      accent: AppColors.gold500,
      child: Column(
        children: [
          _premiumInput(
            controller: _nameCtrl,
            label: 'Nombre del producto',
            hint: 'Ej: Camiseta Premium Algodón',
            icon: Icons.label_outlined,
            required: true,
          ),
          const SizedBox(height: 14),
          _premiumInput(
            controller: _descCtrl,
            label: 'Descripción',
            hint: 'Describe el producto...',
            icon: Icons.description_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          _premiumInput(
            controller: _skuCtrl,
            label: 'SKU',
            hint: 'Ej: CAM-001-BLK',
            icon: Icons.qr_code_rounded,
          ),
        ],
      ),
    );
  }

  // ─── PRICING ───
  Widget _buildPricingSection() {
    return _sectionCard(
      icon: Icons.euro_rounded,
      title: 'Precios',
      accent: AppColors.accentEmerald,
      child: Row(
        children: [
          Expanded(
            child: _premiumInput(
              controller: _priceCtrl,
              label: 'Precio',
              hint: '0.00',
              icon: Icons.sell_rounded,
              keyboardType: TextInputType.number,
              required: true,
              prefix: '€',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _premiumInput(
              controller: _salePriceCtrl,
              label: 'Precio rebajado',
              hint: '0.00',
              icon: Icons.local_offer_rounded,
              keyboardType: TextInputType.number,
              prefix: '€',
            ),
          ),
        ],
      ),
    );
  }

  // ─── CATEGORY ───
  Widget _buildCategorySection(
    AsyncValue<List<CategoryModel>> categoriesAsync,
  ) {
    return _sectionCard(
      icon: Icons.category_rounded,
      title: 'Categoría',
      accent: AppColors.info,
      child: categoriesAsync.when(
        loading: () => Container(
          height: 50,
          alignment: Alignment.center,
          child: const BouncingDotsLoader(color: AppColors.gold500),
        ),
        error: (_, _) => const Text(
          'Error cargando categorías',
          style: TextStyle(color: AppColors.error, fontSize: 12),
        ),
        data: (categories) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.08)),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _categoryId,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.folder_outlined,
                color: AppColors.textMuted.withValues(alpha: 0.4),
                size: 18,
              ),
              hintText: 'Selecciona categoría',
              hintStyle: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: InputBorder.none,
            ),
            dropdownColor: AppColors.card,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            items: categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) {
              String? catName;
              for (final c in categories) {
                if (c.id == v) {
                  catName = c.name;
                  break;
                }
              }
              setState(() {
                _categoryId = v;
                _onCategoryChanged(catName);
              });
            },
          ),
        ),
      ),
    );
  }

  // ─── STOCK BY SIZE ───
  Widget _buildStockBySizeSection() {
    return _sectionCard(
      icon: Icons.straighten_rounded,
      title: 'Stock por talla',
      accent: AppColors.warning,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_rounded,
                  color: AppColors.warning.withValues(alpha: 0.6),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Stock total: ',
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${_stockBySize.values.fold(0, (a, b) => a + b)} uds',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _sizes.map((size) {
              final stock = _stockBySize[size] ?? 0;
              final hasStock = stock > 0;
              return Container(
                width: 100,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: hasStock
                      ? AppColors.success.withValues(alpha: 0.06)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasStock
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.border.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: hasStock
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.textMuted.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        size,
                        style: TextStyle(
                          color: hasStock
                              ? AppColors.success
                              : AppColors.textMuted.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 32,
                      child: TextFormField(
                        initialValue: stock.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          filled: false,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (v) {
                          setState(() {
                            _stockBySize[size] = int.tryParse(v) ?? 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── GARMENT TYPE & SIZE HELPERS ───

  String _detectGarmentType(String? categoryName) {
    if (categoryName == null || categoryName.isEmpty) return 'tops';
    final c = categoryName.toLowerCase();
    const footwearKw = [
      'bota',
      'botas',
      'zapato',
      'zapatos',
      'zapatilla',
      'zapatillas',
      'sandalia',
      'sandalias',
      'tacón',
      'tacones',
      'botín',
      'botines',
      'calzado',
      'deportiva',
      'deportivas',
      'casual',
      'casuales',
      'formal',
      'formales',
      'sneaker',
      'sneakers',
    ];
    for (final kw in footwearKw) {
      if (c.contains(kw)) return 'footwear';
    }
    const bottomKw = [
      'pantalón',
      'pantalon',
      'pantalones',
      'jean',
      'jeans',
      'falda',
      'faldas',
      'legging',
      'leggings',
      'short',
      'shorts',
      'bermuda',
      'jogger',
      'joggers',
    ];
    for (final kw in bottomKw) {
      if (c.contains(kw)) return 'bottoms';
    }
    const fullBodyKw = [
      'vestido',
      'vestidos',
      'mono',
      'monos',
      'jumpsuit',
      'body',
      'enterizo',
      'traje',
    ];
    for (final kw in fullBodyKw) {
      if (c.contains(kw)) return 'fullBody';
    }
    return 'tops';
  }

  List<String> _defaultSizesForType(String type) {
    if (type == 'footwear') {
      return [
        '35',
        '36',
        '37',
        '38',
        '39',
        '40',
        '41',
        '42',
        '43',
        '44',
        '45',
        '46',
      ];
    }
    return ['XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL'];
  }

  List<String> _measurementFieldsForType(String type) {
    switch (type) {
      case 'footwear':
        return ['pie_largo', 'pie_ancho'];
      case 'bottoms':
        return ['cintura', 'cadera', 'entrepierna'];
      case 'fullBody':
        return ['pecho', 'cintura', 'cadera', 'altura'];
      default:
        return ['pecho', 'cintura', 'altura'];
    }
  }

  String _measurementLabel(String field) {
    const labels = {
      'pecho': 'Contorno de pecho (cm)',
      'cintura': 'Contorno de cintura (cm)',
      'cadera': 'Contorno de cadera (cm)',
      'altura': 'Altura (cm)',
      'entrepierna': 'Entrepierna (cm)',
      'pie_largo': 'Longitud del pie (cm)',
      'pie_ancho': 'Anchura del pie (cm)',
    };
    return labels[field] ?? field;
  }

  String _garmentTypeLabel(String type) {
    const labels = {
      'tops': 'Parte superior',
      'bottoms': 'Parte inferior',
      'fullBody': 'Cuerpo entero',
      'footwear': 'Calzado',
    };
    return labels[type] ?? type;
  }

  void _onCategoryChanged(String? categoryName) {
    _selectedCategoryName = categoryName;
    final newSizes = _defaultSizesForType(_detectGarmentType(categoryName));
    final isCurrentNumeric =
        _sizes.isNotEmpty && RegExp(r'^\d+$').hasMatch(_sizes.first);
    final isNewNumeric =
        newSizes.isNotEmpty && RegExp(r'^\d+$').hasMatch(newSizes.first);
    if (isCurrentNumeric != isNewNumeric) {
      _sizes = newSizes;
      _stockBySize = {};
      _sizeMeasurements = {};
      _selectedMeasurementSize = null;
      _showMeasurements = false;
    }
  }

  int _getMeasurement(String size, String field, int index) {
    return _sizeMeasurements[size]?[field]?[index] ?? 0;
  }

  void _updateMeasurement(String size, String field, int index, int value) {
    _sizeMeasurements.putIfAbsent(size, () => {});
    _sizeMeasurements[size]!.putIfAbsent(field, () => [0, 0]);
    _sizeMeasurements[size]![field]![index] = value;
  }

  void _loadMeasurementsFromJson(Map<String, dynamic> json) {
    _sizeMeasurements = {};
    for (final sizeEntry in json.entries) {
      final measurements = sizeEntry.value as Map<String, dynamic>;
      _sizeMeasurements[sizeEntry.key] = {};
      for (final mEntry in measurements.entries) {
        final values = (mEntry.value as List)
            .map((e) => (e as num).toInt())
            .toList();
        _sizeMeasurements[sizeEntry.key]![mEntry.key] = values;
      }
    }
  }

  Map<String, dynamic>? _sizeMeasurementsToJson() {
    final result = <String, dynamic>{};
    for (final sizeEntry in _sizeMeasurements.entries) {
      final sizeData = <String, dynamic>{};
      for (final mEntry in sizeEntry.value.entries) {
        if (mEntry.value.length >= 2 &&
            (mEntry.value[0] > 0 || mEntry.value[1] > 0)) {
          sizeData[mEntry.key] = mEntry.value;
        }
      }
      if (sizeData.isNotEmpty) {
        result[sizeEntry.key] = sizeData;
      }
    }
    return result.isEmpty ? null : result;
  }

  // ─── SIZE MEASUREMENTS SECTION ───

  Widget _buildSizeMeasurementsSection() {
    final type = _detectGarmentType(_selectedCategoryName);
    final fields = _measurementFieldsForType(type);

    return _sectionCard(
      icon: Icons.straighten_rounded,
      title: 'Guía de medidas',
      accent: const Color(0xFF06B6D4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medidas personalizadas',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Para la guía de tallaje interactiva',
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _showMeasurements,
                onChanged: (v) => setState(() {
                  _showMeasurements = v;
                  if (v &&
                      _selectedMeasurementSize == null &&
                      _sizes.isNotEmpty) {
                    _selectedMeasurementSize = _sizes.first;
                  }
                }),
                activeThumbColor: const Color(0xFF06B6D4),
                activeTrackColor: const Color(
                  0xFF06B6D4,
                ).withValues(alpha: 0.3),
                inactiveThumbColor: AppColors.textMuted.withValues(alpha: 0.4),
                inactiveTrackColor: AppColors.surface,
              ),
            ],
          ),
          if (_showMeasurements) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type == 'footwear'
                        ? Icons.directions_walk_rounded
                        : type == 'bottoms'
                        ? Icons.accessibility_new_rounded
                        : Icons.person_rounded,
                    size: 14,
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tipo: ${_garmentTypeLabel(type)}',
                    style: TextStyle(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _sizes.map((size) {
                  final isSelected = _selectedMeasurementSize == size;
                  final hasMeasurements =
                      _sizeMeasurements[size]?.values.any(
                        (v) => v.length >= 2 && (v[0] > 0 || v[1] > 0),
                      ) ??
                      false;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedMeasurementSize = size),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF06B6D4).withValues(alpha: 0.15)
                              : hasMeasurements
                              ? AppColors.success.withValues(alpha: 0.06)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF06B6D4).withValues(alpha: 0.4)
                                : hasMeasurements
                                ? AppColors.success.withValues(alpha: 0.2)
                                : AppColors.border.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          size,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF06B6D4)
                                : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            if (_selectedMeasurementSize != null)
              ...fields.map((field) => _buildMeasurementRow(field)),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(String field) {
    final size = _selectedMeasurementSize!;
    final min = _getMeasurement(size, field, 0);
    final max = _getMeasurement(size, field, 1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _measurementLabel(field),
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TextFormField(
                    key: ValueKey('${size}_${field}_min'),
                    initialValue: min > 0 ? min.toString() : '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Mín',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        fontSize: 11,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) => setState(
                      () => _updateMeasurement(
                        size,
                        field,
                        0,
                        int.tryParse(v) ?? 0,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '—',
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TextFormField(
                    key: ValueKey('${size}_${field}_max'),
                    initialValue: max > 0 ? max.toString() : '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Máx',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        fontSize: 11,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) => setState(
                      () => _updateMeasurement(
                        size,
                        field,
                        1,
                        int.tryParse(v) ?? 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── DETAILS ───
  Widget _buildDetailsSection() {
    return _sectionCard(
      icon: Icons.layers_rounded,
      title: 'Detalles del producto',
      accent: AppColors.accentTeal,
      child: Column(
        children: [
          _premiumInput(
            controller: _materialCtrl,
            label: 'Material',
            hint: 'Ej: 100% Algodón orgánico',
            icon: Icons.texture_rounded,
          ),
          const SizedBox(height: 14),
          _premiumInput(
            controller: _careCtrl,
            label: 'Instrucciones de cuidado',
            hint: 'Ej: Lavar a máquina 30°',
            icon: Icons.dry_cleaning_rounded,
          ),
          const SizedBox(height: 14),
          _premiumInput(
            controller: _weightCtrl,
            label: 'Peso (gramos)',
            hint: 'Ej: 250',
            icon: Icons.scale_rounded,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  // ─── TOGGLES ───
  Widget _buildTogglesSection() {
    return _sectionCard(
      icon: Icons.tune_rounded,
      title: 'Opciones',
      accent: const Color(0xFFEC4899),
      child: Column(
        children: [
          _premiumToggle(
            'Activo',
            'Visible en la tienda',
            Icons.visibility_rounded,
            AppColors.success,
            _isActive,
            (v) => setState(() => _isActive = v),
          ),
          _divider(),
          _premiumToggle(
            'Destacado',
            'Aparece en sección destacados',
            Icons.star_rounded,
            AppColors.gold500,
            _featured,
            (v) => setState(() => _featured = v),
          ),
          _divider(),
          _premiumToggle(
            'Nuevo',
            'Badge de novedad',
            Icons.fiber_new_rounded,
            AppColors.info,
            _isNew,
            (v) => setState(() => _isNew = v),
          ),
          _divider(),
          _premiumToggle(
            'En rebaja',
            'Mostrar precio tachado',
            Icons.local_offer_rounded,
            AppColors.error,
            _isOnSale,
            (v) => setState(() => _isOnSale = v),
          ),
          _divider(),
          _premiumToggle(
            'Sostenible',
            'Badge eco-friendly',
            Icons.eco_rounded,
            AppColors.accentEmerald,
            _isSustainable,
            (v) => setState(() => _isSustainable = v),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(vertical: 4),
    color: AppColors.border.withValues(alpha: 0.04),
  );

  Widget _premiumToggle(
    String label,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (value ? color : AppColors.textMuted).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: (value ? color : AppColors.textMuted).withValues(
                alpha: 0.6,
              ),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textMuted.withValues(alpha: 0.4),
            inactiveTrackColor: AppColors.surface,
          ),
        ],
      ),
    );
  }

  // ─── SAVE BUTTON ───
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _loading ? null : _save,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _loading
              ? LinearGradient(
                  colors: [
                    AppColors.gold500.withValues(alpha: 0.3),
                    AppColors.gold700.withValues(alpha: 0.3),
                  ],
                )
              : const LinearGradient(
                  colors: [AppColors.gold500, AppColors.gold700],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _loading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.gold500.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: _loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isEdit ? Icons.save_rounded : Icons.add_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEdit ? 'ACTUALIZAR PRODUCTO' : 'CREAR PRODUCTO',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── REUSABLE PREMIUM INPUT ───
  Widget _premiumInput({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.08)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        validator: required
            ? (v) => v == null || v.isEmpty ? 'Campo requerido' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.3),
            fontSize: 12,
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  color: AppColors.textMuted.withValues(alpha: 0.35),
                  size: 18,
                )
              : null,
          prefixText: prefix != null ? '$prefix ' : null,
          prefixStyle: const TextStyle(
            color: AppColors.gold500,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppColors.error.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  // ─── PICK IMAGE ───
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Cámara',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Tomar foto',
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Galería',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Elegir imagen existente',
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    setState(() => _uploadingImage = true);

    try {
      final file = File(picked.path);
      final compressed = await ImageCompressService.compressFromPath(file.path);
      final bytes = compressed ?? await file.readAsBytes();
      final fileName = '${const Uuid().v4()}.jpg';
      final path = 'productos/$fileName';

      await Supabase.instance.client.storage
          .from('products-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('products-images')
          .getPublicUrl(path);

      setState(() => _images.add(publicUrl));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error subiendo imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _uploadingImage = false);
    }
  }

  // ─── SAVE ───
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    final name = _nameCtrl.text.trim();
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');

    final data = {
      'name': name,
      'slug': slug,
      'description': _descCtrl.text.trim(),
      'price': ((double.tryParse(_priceCtrl.text) ?? 0) * 100).round(),
      'sale_price': _salePriceCtrl.text.isNotEmpty
          ? ((double.tryParse(_salePriceCtrl.text) ?? 0) * 100).round()
          : null,
      'stock': _stockBySize.values.fold(0, (a, b) => a + b),
      'stock_by_size': _stockBySize,
      'sku': _skuCtrl.text.trim().isNotEmpty ? _skuCtrl.text.trim() : null,
      'category_id': _categoryId,
      'material': _materialCtrl.text.trim().isNotEmpty
          ? _materialCtrl.text.trim()
          : null,
      'care_instructions': _careCtrl.text.trim().isNotEmpty
          ? _careCtrl.text.trim()
          : null,
      'weight_grams': _weightCtrl.text.trim().isNotEmpty
          ? double.tryParse(_weightCtrl.text.trim())?.toInt()
          : null,
      'images': _images,
      'sizes': _sizes,
      'available_sizes': _stockBySize.entries
          .where((e) => e.value > 0)
          .map((e) => e.key)
          .toList(),
      'size_measurements': _sizeMeasurementsToJson(),
      'is_active': _isActive,
      'featured': _featured,
      'is_new': _isNew,
      'is_on_sale': _isOnSale,
      'is_sustainable': _isSustainable,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      if (_isEdit) {
        await Supabase.instance.client
            .from('products')
            .update(data)
            .eq('id', widget.productId!);
      } else {
        data['created_at'] = DateTime.now().toIso8601String();
        await Supabase.instance.client.from('products').insert(data);
      }

      ref.invalidate(productsProvider(const ProductsFilter(limit: 500)));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(_isEdit ? 'Producto actualizado' : 'Producto creado'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
