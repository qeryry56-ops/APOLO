import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../widgets/dl_settings_kit.dart';
import '../widgets/marketplace_zone_sheet.dart';

/// Dedicated full-screen settings route for choosing the Marketplace GPS zone.
class SettingsZoneScreen extends StatelessWidget {
  const SettingsZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final s = state.s;
        final palette = ApoloDlPalette.of(context);

        return Directionality(
          textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: palette.bg,
            body: SafeArea(
              child: Column(
                children: [
                  ApoloDlTopNav(
                    title: s.tr(
                      'منطقة الإعلانات (GPS)',
                      'Zone des annonces',
                      'Marketplace Zone',
                    ),
                    size: ApoloDlTopNavSize.md,
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: MarketplaceZoneContent(
                          state: state,
                          embeddedInScreen: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
