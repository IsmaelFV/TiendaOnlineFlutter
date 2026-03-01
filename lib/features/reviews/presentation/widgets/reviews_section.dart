import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/extensions/date_extensions.dart';

/// Provider de reviews para un producto
final reviewsProvider = FutureProvider.family<List<ReviewData>, String>((
  ref,
  productId,
) async {
  final response = await Supabase.instance.client
      .from('reviews')
      .select()
      .eq('product_id', productId)
      .order('created_at', ascending: false);

  return (response as List)
      .map((json) => ReviewData.fromJson(json as Map<String, dynamic>))
      .toList();
});

/// Modelo de review simple
class ReviewData {
  final String id;
  final String productId;
  final String userId;
  final String? userName;
  final int rating;
  final String? comment;
  final String? createdAt;

  ReviewData({
    required this.id,
    required this.productId,
    required this.userId,
    this.userName,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory ReviewData.fromJson(Map<String, dynamic> json) => ReviewData(
    id: json['id'] as String,
    productId: json['product_id'] as String,
    userId: json['user_id'] as String,
    userName: json['user_name'] as String?,
    rating: json['rating'] as int? ?? 0,
    comment: json['comment'] as String?,
    createdAt: json['created_at'] as String?,
  );
}

class ReviewsSection extends ConsumerStatefulWidget {
  final String productId;
  const ReviewsSection({super.key, required this.productId});

  @override
  ConsumerState<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<ReviewsSection> {
  bool _showForm = false;
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(reviewsProvider(widget.productId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reseñas', style: AppTextStyles.h4),
            if (Supabase.instance.client.auth.currentUser != null)
              TextButton.icon(
                onPressed: () => setState(() => _showForm = !_showForm),
                icon: Icon(
                  _showForm ? Icons.close : Icons.rate_review,
                  size: 18,
                ),
                label: Text(_showForm ? 'Cancelar' : 'Escribir reseña'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Formulario de reseña
        if (_showForm) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu valoración',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRating = index + 1),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          index < _selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: AppColors.gold500,
                          size: 30,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Escribe tu comentario (opcional)...',
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submitReview,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('ENVIAR RESEÑA'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Lista de reseñas
        reviewsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => Text(
            'No se pudieron cargar las reseñas',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Sé el primero en dejar una reseña',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              );
            }

            // Media de ratings
            final avgRating =
                reviews.fold<int>(0, (sum, r) => sum + r.rating) /
                reviews.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumen
                Row(
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.gold500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < avgRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: AppColors.gold500,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${reviews.length})',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Lista de reseñas (máximo 5 visibles)
                ...reviews.take(5).map((review) => _buildReviewCard(review)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewCard(ReviewData review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    color: AppColors.gold500,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                review.userName ?? 'Anónimo',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (review.createdAt != null)
                Text(
                  DateTime.tryParse(review.createdAt!)?.shortDate ?? '',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    setState(() => _submitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('reviews').insert({
        'product_id': widget.productId,
        'user_id': user.id,
        'user_name': user.userMetadata?['full_name'] ?? 'Anónimo',
        'rating': _selectedRating,
        'comment': _commentController.text.isNotEmpty
            ? _commentController.text
            : null,
      });

      ref.invalidate(reviewsProvider(widget.productId));
      setState(() {
        _showForm = false;
        _commentController.clear();
        _selectedRating = 5;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reseña enviada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar la reseña')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
