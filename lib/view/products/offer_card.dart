import 'package:flutter/material.dart';

class OfferCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final double price;
  final int rating;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onCartPressed;
  final VoidCallback? onCardPressed;

  const OfferCard({
    required this.imageAsset,
    required this.title,
    required this.price,
    required this.rating,
    this.onFavoritePressed,
    this.onCartPressed,
    this.onCardPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final int clampedRating = rating.clamp(0, 5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(10), // ripple effect matches card
        child: Container(
          width: MediaQuery.of(context).size.width * 0.4,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  onTap: onCardPressed,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    child: imageAsset.startsWith('http')
                        ? Image.network(
                            imageAsset,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 120,
                              color: Colors.grey[300],
                              child: Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          )
                        : Image.asset(
                            imageAsset,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 120,
                              color: Colors.grey[300],
                              child: Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.favorite_border,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: onFavoritePressed,
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      _buildRatingStars(clampedRating),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.shopping_cart,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: onCartPressed,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        ),
      ),
    );
  }
}