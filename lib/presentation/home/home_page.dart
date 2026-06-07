import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/nav.dart';

import 'package:thix_id/presentation/common/full_screen_message.dart';
import 'package:thix_id/presentation/common/alert_info_sheet.dart';
import 'package:thix_id/presentation/common/notifications_sheet.dart';
import 'package:thix_id/presentation/common/thix_identity_sheets.dart';
import 'package:thix_id/presentation/emergency/emergency_overlay.dart';

import 'package:thix_id/services/firestore_user_service.dart';
import 'package:thix_id/services/notification_service.dart';
import 'package:thix_id/services/notification_counters_service.dart';
import 'package:thix_id/services/thix_id_service.dart';

/// Palette Ultra-Premium Institutionnelle - THIX ID 2026
class ThixPremiumColors {
  static const Color primaryDark = Color(0xFF0B1B3D); // Nouvelle couleur demandée
  static const Color primaryElectric = Color(0xFF1A2D56);
  static const Color accentBlue = Color(0xFF002B5C);
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF3E5AB);
  static const Color goldDark = Color(0xFFAA7C11);
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF060C1A);
  static const Color grayDark = Color(0xFF111827);
  static const Color grayMedium = Color(0xFF6B7280);
  static const Color grayLight = Color(0xFFE5E7EB);
}

enum _AccountRequestChoice { personal, enterprise }

// ==================== BOUTON D'OPTION POUR LA FEUILLE DE COMPTE ====================
class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _OptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: ThixPremiumColors.goldPrimary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ThixPremiumColors.primaryDark, ThixPremiumColors.primaryElectric],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ThixPremiumColors.goldDark, ThixPremiumColors.goldPrimary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: ThixPremiumColors.primaryDark, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: ThixPremiumColors.goldPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: ThixPremiumColors.grayMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: ThixPremiumColors.goldPrimary),
          ],
        ),
      ),
    );
  }
}

// ==================== FEUILLE DE DEMANDE DE COMPTE ====================
class AccountRequestSheet extends StatelessWidget {
  const AccountRequestSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ThixPremiumColors.primaryDark, ThixPremiumColors.primaryElectric],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 35,
              height: 4,
              decoration: BoxDecoration(
                color: ThixPremiumColors.goldPrimary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Créer un compte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ThixPremiumColors.goldPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _OptionButton(
              icon: Icons.person_outline,
              title: 'Compte Personnel',
              subtitle: 'Pour un profil individuel',
              onTap: () {
                Navigator.pop(context, _AccountRequestChoice.personal);
              },
            ),
            const SizedBox(height: 12),
            _OptionButton(
              icon: Icons.business_outlined,
              title: 'Compte Entreprise',
              subtitle: 'Pour une organisation',
              onTap: () {
                Navigator.pop(context, _AccountRequestChoice.enterprise);
              },
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

// ==================== PAGE PRINCIPALE ====================
class HomePagePremium extends StatefulWidget {
  const HomePagePremium({super.key});

  @override
  State<HomePagePremium> createState() => _HomePagePremiumState();
}

class _HomePagePremiumState extends State<HomePagePremium>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;
  late AnimationController _animationController;
  double _scrollOffset = 0;

  final _notifications = NotificationService();
  final _counters = NotificationCountersService();

  static final RegExp _uidLikeRegex = RegExp(r'^[A-Za-z0-9_-]{20,}$');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToChat() {
    final auth = context.read<AuthController>();
    if (auth.isAuthenticated) {
      context.push(AppRoutes.chat);
    } else {
      context.push(AppRoutes.login);
    }
  }

  void _navigateToProfile() {
    final auth = context.read<AuthController>();
    if (auth.isAuthenticated) {
      final user = auth.currentUser;
      if (user?.accountType == AccountType.enterprise) {
        context.push(AppRoutes.enterpriseDashboard);
      } else {
        context.push(AppRoutes.userDashboard);
      }
    } else {
      context.push(AppRoutes.login);
    }
  }

  void _showEmergencyOverlay() async {
    await EmergencyOverlay.show(context);
  }

  Future<void> _handleHomeSearchVerify() async {
    final raw = _searchController.text.trim();

    if (raw.isEmpty) {
      await FullScreenMessage.showError(
        context,
        title: 'Identifiant requis',
        message: "Saisissez un THIX ID puis appuyez sur Vérifier.",
      );
      return;
    }

    final normalized = ThixIdService.normalize(raw);
    final isThix = normalized.startsWith('THIX-') && ThixIdService.isValid(normalized);
    final isUid = _uidLikeRegex.hasMatch(raw);

    if (!isThix && !isUid) {
      await FullScreenMessage.showError(
        context,
        title: 'Identifiant invalide',
        message: 'Format THIX ID incorrect.',
      );
      return;
    }

    setState(() => _searching = true);

    try {
      final userService = FirestoreUserService();
      AppUser? user;

      if (isThix) {
        user = await userService.fetchUserByThixId(normalized);
      } else {
        user = await userService.fetchUserByUid(raw);
      }

      if (!mounted) return;

      if (user == null) {
        await FullScreenMessage.showError(
          context,
          title: 'Profil introuvable',
          message: "Aucun profil trouvé.",
        );
        return;
      }

      final thix = user.thixId.trim().toUpperCase();

      if (thix.isNotEmpty && ThixIdService.isValid(thix)) {
        context.push('${AppRoutes.publicProfile}?thixId=$thix');
      } else {
        await ThixIdentitySheets.showVerifySheet(
          context,
          initialUidOrThixId: user.id,
        );
      }
    } catch (e) {
      if (!mounted) return;
      await FullScreenMessage.showError(
        context,
        title: 'Erreur',
        message: "Impossible d'effectuer la vérification.",
      );
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  void _onProfileTap() {
    final auth = context.read<AuthController>();
    if (auth.isAuthenticated) {
      final t = auth.currentUser?.accountType;
      context.push(
        t == AccountType.enterprise
            ? AppRoutes.enterpriseDashboard
            : AppRoutes.userDashboard,
      );
    } else {
      context.push(AppRoutes.login);
    }
  }

  Future<void> _handleRequestAccount(BuildContext context) async {
    final auth = context.read<AuthController>();
    final res = await showModalBottomSheet<_AccountRequestChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AccountRequestSheet(),
    );

    switch (res) {
      case _AccountRequestChoice.personal:
        if (auth.isAuthenticated) {
          await auth.signOut();
        }
        if (context.mounted) {
          context.push(AppRoutes.personalReg);
        }
        return;

      case _AccountRequestChoice.enterprise:
        if (auth.isAuthenticated) {
          await auth.signOut();
        }
        if (context.mounted) {
          context.push(AppRoutes.enterpriseReg);
        }
        return;

      case null:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final safeTop = MediaQuery.paddingOf(context).top;
    final badgeCountsStream = auth.currentUser == null
        ? Stream.value(SectionBadgeCounts.zero)
        : _counters.streamCounts(auth.currentUser!.id);

    return Scaffold(
      backgroundColor: ThixPremiumColors.backgroundDark,
      extendBody: true,
      body: Stack(
        children: [
          // Background futuriste avec effet de grille et particules
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  ThixPremiumColors.primaryDark,
                  ThixPremiumColors.backgroundDark,
                ],
              ),
            ),
            child: CustomPaint(
              painter: _FuturisticGridPainter(),
              child: Container(),
            ),
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                setState(() {
                  _scrollOffset = notification.metrics.pixels;
                });
              }
              return false;
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _PremiumHeader(
                    safeTop: safeTop,
                    onProfileTap: _onProfileTap,
                    onRequestAccount: () => _handleRequestAccount(context),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            title: 'Scanner un QR',
                            subtitle: 'Scannez en sécurité',
                            icon: Icons.qr_code_scanner_rounded,
                            onTap: () {
                              ThixIdentitySheets.showQrScanSheet(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            title: 'Lire via NFC',
                            subtitle: 'Approchez l\'appareil',
                            icon: Icons.fingerprint_rounded,
                            onTap: () {
                              ThixIdentitySheets.showNfcScanSheet(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _NotificationPreviewCard(
                      onTap: () {
                        if (!auth.isAuthenticated) {
                          context.push(AppRoutes.login);
                          return;
                        }
                        NotificationsSheet.show(context);
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'THIX SERVICES',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: ThixPremiumColors.goldPrimary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: ThixPremiumColors.goldPrimary.withOpacity(0.5)),
                            ),
                            child: const Text(
                              'Tout voir',
                              style: TextStyle(
                                color: ThixPremiumColors.goldLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverToBoxAdapter(
                    child: StreamBuilder<SectionBadgeCounts>(
                      stream: badgeCountsStream,
                      builder: (context, snap) {
                        final counts = snap.data ?? SectionBadgeCounts.zero;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 4,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.95,
                          children: [
                            _PremiumServiceCard(
                              icon: Icons.play_circle_filled,
                              title: 'THIX MEDIA',
                              iconColor: Colors.blue,
                              badgeCount: counts.media,
                              onTap: () => context.push(AppRoutes.thixMedia),
                            ),
                            _PremiumServiceCard(
                              icon: Icons.storefront_rounded,
                              title: 'THIX Market',
                              iconColor: const Color(0xFFFF9800),
                              onTap: () => context.push(AppRoutes.thixMarket),
                            ),
                            _PremiumServiceCard(
                              icon: Icons.school_rounded,
                              title: 'Formations',
                              iconColor: const Color(0xFF0057D9),
                              badgeCount: counts.formations,
                              onTap: () => context.push(AppRoutes.trainingHome),
                            ),
                            _PremiumServiceCard(
                              icon: Icons.work_rounded,
                              title: 'Emplois',
                              iconColor: const Color(0xFF00A86B),
                              badgeCount: counts.jobs,
                              onTap: () => context.push(AppRoutes.jobs),
                            ),
                            _PremiumServiceCard(
                              icon: Icons.newspaper_rounded,
                              title: 'THIX INFO',
                              iconColor: const Color(0xFFFF9800),
                              badgeCount: counts.info,
                              onTap: () => AlertInfoSheet.show(context),
                            ),
                            _PremiumServiceCard(
                              icon: Icons.lightbulb_rounded,
                              title: 'Opportunités',
                              iconColor: ThixPremiumColors.goldPrimary,
                              onTap: () => context.push(AppRoutes.opportunities),
                            ),
                            _PremiumServiceCard(
                              icon: Icons.event_rounded,
                              title: 'Événements',
                              iconColor: const Color(0xFFE63946),
                              badgeCount: counts.events,
                              onTap: () => context.push(AppRoutes.events),
                            ),
                            _PremiumServiceCard(
                              icon: Icons.groups_rounded,
                              title: 'Réseau Pro',
                              iconColor: const Color(0xFF0077B6),
                              onTap: () => context.push(AppRoutes.network),
                            ),
                            _PremiumServiceCard(
                              icon: Icons.local_hospital_rounded,
                              title: 'THIX Santé',
                              iconColor: const Color(0xFFE63946),
                              onTap: () => context.push(AppRoutes.thixSante),
                            ),
                            _PremiumServiceCard(
                              icon: Icons.account_balance_wallet_rounded,
                              title: 'Thix Money',
                              iconColor: const Color(0xFF00A86B),
                              onTap: () => context.push(AppRoutes.thixMoney),
                            ),
                            _PremiumServiceCard(
                              icon: Icons.account_balance_rounded,
                              title: 'Services Gov',
                              iconColor: const Color(0xFF0057D9),
                              onTap: () {},
                            ),
                            _PremiumServiceCard(
                              icon: Icons.confirmation_number_rounded,
                              title: 'Réservation',
                              iconColor: const Color(0xFF9C27B0),
                              onTap: () => context.push(AppRoutes.reservation),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          ),
          Positioned(
            top: (safeTop + 155 - _scrollOffset).clamp(safeTop + 8, safeTop + 155),
            left: 16,
            right: 16,
            child: Opacity(
              opacity: (1.0 - (_scrollOffset / 100)).clamp(0.0, 1.0),
              child: _SearchBarOverlay(
                controller: _searchController,
                isSearching: _searching,
                onVerify: _handleHomeSearchVerify,
              ),
            ),
          ),
          if (_searching)
            Positioned.fill(
              child: Container(
                color: ThixPremiumColors.primaryDark.withOpacity(0.8),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: ThixPremiumColors.goldPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _FloatingBottomNav(
        onScanTap: () => ThixIdentitySheets.showQrScanSheet(context),
        onChatTap: _navigateToChat,
        onProfileTap: _navigateToProfile,
        onEmergencyTap: _showEmergencyOverlay,
      ),
    );
  }
}

// ==================== PAINTER FUTURISTE ====================
class _FuturisticGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ThixPremiumColors.goldPrimary.withOpacity(0.03)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Lignes de grille horizontales
    for (var i = 0; i < size.height / 40; i++) {
      canvas.drawLine(
        Offset(0, i * 40),
        Offset(size.width, i * 40),
        paint,
      );
    }

    // Lignes de grille verticales
    for (var i = 0; i < size.width / 40; i++) {
      canvas.drawLine(
        Offset(i * 40, 0),
        Offset(i * 40, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==================== HEADER PREMIUM ====================
class _PremiumHeader extends StatelessWidget {
  final double safeTop;
  final VoidCallback onProfileTap;
  final VoidCallback onRequestAccount;
  const _PremiumHeader({
    required this.safeTop,
    required this.onProfileTap,
    required this.onRequestAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ThixPremiumColors.primaryDark, ThixPremiumColors.primaryElectric],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: ThixPremiumColors.goldPrimary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ThixPremiumColors.goldPrimary.withOpacity(0.08),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            left: -50,
            bottom: -30,
            child: Icon(
              Icons.fingerprint_rounded,
              size: 120,
              color: ThixPremiumColors.goldPrimary.withOpacity(0.03),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, safeTop + 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [ThixPremiumColors.goldDark, ThixPremiumColors.goldPrimary],
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Card(
                              margin: EdgeInsets.zero,
                              color: ThixPremiumColors.primaryDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              child: Icon(
                                Icons.fingerprint_rounded,
                                color: ThixPremiumColors.goldPrimary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'THIX ID',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'Identité Sécurisée.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onRequestAccount,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: ThixPremiumColors.goldPrimary.withOpacity(0.5)),
                            ),
                            child: const Text(
                              'Créer un compte',
                              style: TextStyle(
                                color: ThixPremiumColors.goldLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: onProfileTap,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ThixPremiumColors.goldPrimary.withOpacity(0.6),
                                width: 1.5,
                              ),
                              gradient: LinearGradient(
                                colors: [ThixPremiumColors.primaryDark, ThixPremiumColors.primaryElectric],
                              ),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: ThixPremiumColors.goldPrimary,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bienvenue !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Que voulez-vous faire aujourd’hui ?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== BARRE DE RECHERCHE ====================
class _SearchBarOverlay extends StatefulWidget {
  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onVerify;
  const _SearchBarOverlay({
    required this.controller,
    required this.isSearching,
    required this.onVerify,
  });

  @override
  State<_SearchBarOverlay> createState() => _SearchBarOverlayState();
}

class _SearchBarOverlayState extends State<_SearchBarOverlay> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ThixPremiumColors.primaryDark, ThixPremiumColors.primaryElectric],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ThixPremiumColors.goldPrimary.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: ThixPremiumColors.goldPrimary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: ThixPremiumColors.goldPrimary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              enabled: !widget.isSearching,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Rechercher un THIX ID...',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.isSearching ? null : widget.onVerify,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [ThixPremiumColors.goldDark, ThixPremiumColors.goldPrimary],
                ),
              ),
              child: const Center(
                child: Text(
                  'Vérifier',
                  style: TextStyle(
                    color: ThixPremiumColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== CARTE ACTION RAPIDE ====================
class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ThixPremiumColors.primaryDark, ThixPremiumColors.primaryElectric],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThixPremiumColors.goldPrimary.withOpacity(0.4), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ThixPremiumColors.goldDark, ThixPremiumColors.goldPrimary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: ThixPremiumColors.primaryDark, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: ThixPremiumColors.goldLight,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CARTE APERÇU NOTIFICATIONS ====================
class _NotificationPreviewCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NotificationPreviewCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ThixPremiumColors.primaryDark, ThixPremiumColors.primaryElectric],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ThixPremiumColors.goldPrimary.withOpacity(0.4), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [ThixPremiumColors.goldDark, ThixPremiumColors.goldPrimary],
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: ThixPremiumColors.primaryDark,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: ThixPremiumColors.goldLight,
                    ),
                  ),
                  Text(
                    'Nouvelles mises à jour disponibles',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: ThixPremiumColors.goldPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CARTE SERVICE PREMIUM ====================
class _PremiumServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final int? badgeCount;
  final VoidCallback onTap;
  const _PremiumServiceCard({
    required this.icon,
    required this.title,
    required this.iconColor,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ThixPremiumColors.primaryDark, ThixPremiumColors.primaryElectric],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThixPremiumColors.goldPrimary.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: ThixPremiumColors.goldPrimary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ThixPremiumColors.goldDark, ThixPremiumColors.goldPrimary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: ThixPremiumColors.primaryDark, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ThixPremiumColors.goldLight,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ThixPremiumColors.goldDark, ThixPremiumColors.goldPrimary],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${badgeCount}',
                    style: const TextStyle(
                      color: ThixPremiumColors.primaryDark,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== NAVIGATION BASSE FLOTTANTE ====================
class _FloatingBottomNav extends StatelessWidget {
  final VoidCallback onScanTap;
  final VoidCallback onChatTap;
  final VoidCallback onProfileTap;
  final VoidCallback onEmergencyTap;
  const _FloatingBottomNav({
    required this.onScanTap,
    required this.onChatTap,
    required this.onProfileTap,
    required this.onEmergencyTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 65,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ThixPremiumColors.primaryDark.withOpacity(0.95),
                ThixPremiumColors.primaryElectric.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: ThixPremiumColors.goldPrimary.withOpacity(0.4), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_filled, label: 'Accueil', active: true, onTap: () {}),
              _NavItem(icon: Icons.grid_view_rounded, label: 'Services', active: false, onTap: () {}),
              GestureDetector(
                onTap: onEmergencyTap,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages', active: false, onTap: onChatTap),
              _NavItem(icon: Icons.person_outline_rounded, label: 'Profil', active: false, onTap: onProfileTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: active ? ThixPremiumColors.goldPrimary : Colors.white54,
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              color: active ? ThixPremiumColors.goldPrimary : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
