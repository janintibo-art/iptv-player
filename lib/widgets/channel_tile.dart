import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../services/prefs_service.dart';

class ChannelTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteChanged;

  const ChannelTile({
    super.key,
    required this.channel,
    required this.onTap,
    this.onFavoriteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fav = Prefs.isFavorite(channel);

    return ListTile(
      leading: Prefs.showLogos && channel.logo.isNotEmpty
          ? SizedBox(
              width: 44,
              height: 44,
              child: Image.network(
                channel.logo,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.tv, size: 28),
              ),
            )
          : const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.tv, size: 28),
            ),
      title: Text(
        channel.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          if (channel.group.isNotEmpty) channel.group,
          if (channel.countryCode.isNotEmpty) channel.countryCode,
        ].join('  •  '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: IconButton(
        icon: Icon(fav ? Icons.star : Icons.star_border,
            color: fav ? Colors.amber : null),
        tooltip: fav ? 'Retirer des favoris' : 'Ajouter aux favoris',
        onPressed: () async {
          await Prefs.toggleFavorite(channel);
          onFavoriteChanged?.call();
        },
      ),
      onTap: onTap,
    );
  }
}
