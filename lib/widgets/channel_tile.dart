import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../services/epg_service.dart';
import '../services/prefs_service.dart';
import '../services/stream_check_service.dart';

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
    final etat = StreamCheckService.instance.etat(channel);
    final horsLigne = etat == EtatFlux.horsLigne;
    final emission = EpgService.instance.maintenant(channel.tvgId);

    Widget vignette = Prefs.showLogos && channel.logo.isNotEmpty
        ? Image.network(
            channel.logo,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.tv, size: 28),
          )
        : const Icon(Icons.tv, size: 28);

    if (horsLigne) {
      vignette = Opacity(opacity: 0.35, child: vignette);
    }

    return ListTile(
      leading: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          children: [
            Positioned.fill(child: vignette),
            if (etat != EtatFlux.inconnu)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: etat == EtatFlux.enLigne
                        ? const Color(0xFF3FBF5F)
                        : const Color(0xFFC94B4B),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF10141A), width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
      title: Text(
        channel.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: horsLigne ? Colors.white38 : null),
      ),
      subtitle: Text(
        emission != null
            ? emission.titre
            : [
                if (horsLigne) 'hors ligne',
                if (channel.group.isNotEmpty) channel.group,
                if (channel.countryCode.isNotEmpty) channel.countryCode,
              ].join('  •  '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: horsLigne
              ? const Color(0xFFC94B4B)
              : (emission != null ? const Color(0xFF7FD4E8) : null),
        ),
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
