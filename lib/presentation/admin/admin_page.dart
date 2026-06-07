import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/admin/admin_routes.dart';
import 'package:thix_id/presentation/admin/admin_shell.dart';
import 'package:thix_id/presentation/admin/pages/admin_overview_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_jobs_opportunities_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_news_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_placeholder_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_sos_emergency_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_user_management_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_verification_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_events_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_trainings_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_audit_activity_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_access_requests_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_media_page.dart';
import 'package:thix_id/services/admin_rbac_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class AdminPage extends StatefulWidget {
  final AdminModule module;

  const AdminPage({super.key, required this.module});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _rbac = AdminRbacService();
  String? _role;
  bool _loading = true;

  RealtimeChannel? _roleChannel;
  
  // ✅ Clé pour forcer le rafraîchissement du contenu
  Key _contentKey = const ValueKey('admin_content');

  @override
  void initState() {
    super.initState();
    _loadRole();
    _subscribeRoleRealtime();
  }

  void _subscribeRoleRealtime() {
    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null || uid.trim().isEmpty) return;
    
    try {
      _roleChannel = SupabaseConfig.client.channel('admin:rbac:$uid');
      
      (_roleChannel as dynamic)
          .on(
            'postgres_changes',
            {
              'event': '*',
              'schema': 'public',
              'table': AdminRbacService.table,
              'filter': 'user_id=eq.$uid',
            },
            (_) => _loadRole(),
          )
          .subscribe((status, [error]) {
            debugPrint('AdminPage realtime: status=$status, error=$error');
          });
    } catch (e) {
      debugPrint('AdminPage: role realtime subscribe failed err=$e');
    }
  }

  @override
  void dispose() {
    try {
      if (_roleChannel != null) SupabaseConfig.client.removeChannel(_roleChannel!);
    } catch (_) {}
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AdminPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ Force le rebuild quand le module change
    if (oldWidget.module != widget.module) {
      debugPrint('🔄 Module changé: ${oldWidget.module.slug} → ${widget.module.slug}');
      _contentKey = ValueKey('admin_${widget.module.slug}_${DateTime.now().millisecondsSinceEpoch}');
      setState(() {});
    }
  }

  Future<void> _loadRole() async {
    setState(() => _loading = true);
    try {
      final r = await _rbac.fetchMyRole();
      if (!mounted) return;
      setState(() => _role = r);
    } catch (e) {
      debugPrint('AdminPage: fetch role failed err=$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AdminShell(
        module: widget.module,
        role: null,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_role == null) {
      return AdminShell(
        module: widget.module,
        role: null,
        child: AdminPlaceholderPage(
          title: 'Access Restricted',
          description: 'Your account is authenticated, but no admin role is assigned.\n\nAsk a Super Admin to grant access in `thix_admin_memberships`.',
          icon: Icons.lock_rounded,
        ),
      );
    }

    // ✅ Utilise la clé pour forcer le rebuild
    return AdminShell(
      key: _contentKey,
      module: widget.module, 
      role: _role, 
      child: _moduleChild(widget.module)
    );
  }

  Widget _moduleChild(AdminModule module) {
    switch (module) {
      case AdminModule.overview:
        return const AdminOverviewPage();
      case AdminModule.accessRequests:
        return const AdminAccessRequestsPage();
      case AdminModule.users:
        return const AdminUserManagementPage();
      case AdminModule.verification:
        return const AdminVerificationPage();
      case AdminModule.events:
        return const AdminEventsPage();
      case AdminModule.trainings:
        return const AdminTrainingsPage();
      case AdminModule.uid:
        return const AdminPlaceholderPage(
          title: 'THIX UID Management',
          description: 'Generate & lifecycle-manage THIX UIDs, link biometrics, validate identities.',
          icon: Icons.badge_rounded,
        );
      case AdminModule.jobs:
        return const AdminJobsOpportunitiesPage();
      case AdminModule.news:
        return AdminNewsPage(role: _role ?? '');
      case AdminModule.chat:
        return const AdminPlaceholderPage(
          title: 'THIX Chat Admin',
          description: 'Moderation, abuse reports, conversation analytics, secure monitoring policies.',
          icon: Icons.forum_rounded,
        );
      case AdminModule.sos:
        return const AdminSosEmergencyPage();
      case AdminModule.institutions:
        return const AdminPlaceholderPage(
          title: 'University & Institution Panel',
          description: 'Partner onboarding, academic validation workflows, bulk certification tools, analytics.',
          icon: Icons.account_balance_rounded,
        );
      case AdminModule.analytics:
        return const AdminPlaceholderPage(
          title: 'Analytics & Reporting',
          description: 'Realtime charts, growth, fraud analytics, engagement, exports.',
          icon: Icons.query_stats_rounded,
        );
      case AdminModule.cybersecurity:
        return const AdminPlaceholderPage(
          title: 'Cybersecurity Center',
          description: 'Threat monitoring, anomaly detection, audit logs, encryption status, server health.',
          icon: Icons.shield_rounded,
        );
      case AdminModule.api:
        return const AdminPlaceholderPage(
          title: 'API & Integration Center',
          description: 'API keys, external integrations, government APIs, enterprise dashboards.',
          icon: Icons.api_rounded,
        );
      case AdminModule.settings:
        return const AdminPlaceholderPage(
          title: 'Admin Settings',
          description: 'Branding, localization, permissions system, notification rules.',
          icon: Icons.tune_rounded,
        );
      case AdminModule.audit:
        return const AdminAuditActivityPage();
      case AdminModule.media:
        return const AdminMediaPage();
      
      default:
        return AdminPlaceholderPage(
          title: 'Module non implémenté',
          description: 'Le module "${module.slug}" est en cours de développement.\n\nCette section sera disponible prochainement.',
          icon: Icons.construction,
        );
    }
  }
}

enum AdminModule {
  overview,
  accessRequests,
  users,
  verification,
  events,
  trainings,
  uid,
  jobs,
  news,
  chat,
  sos,
  institutions,
  analytics,
  cybersecurity,
  api,
  settings,
  audit,
  media,
}

extension AdminModuleX on AdminModule {
  String get slug {
    switch (this) {
      case AdminModule.overview:
        return 'overview';
      case AdminModule.accessRequests:
        return 'access-requests';
      case AdminModule.users:
        return 'users';
      case AdminModule.verification:
        return 'verification';
      case AdminModule.events:
        return 'events';
      case AdminModule.trainings:
        return 'trainings';
      case AdminModule.uid:
        return 'uid';
      case AdminModule.jobs:
        return 'jobs';
      case AdminModule.news:
        return 'news';
      case AdminModule.chat:
        return 'chat';
      case AdminModule.sos:
        return 'sos';
      case AdminModule.institutions:
        return 'institutions';
      case AdminModule.analytics:
        return 'analytics';
      case AdminModule.cybersecurity:
        return 'cybersecurity';
      case AdminModule.api:
        return 'api';
      case AdminModule.settings:
        return 'settings';
      case AdminModule.audit:
        return 'audit';
      case AdminModule.media:
        return 'media';
    }
  }

  static AdminModule fromSlug(String? slug) {
    final s = (slug ?? '').trim().toLowerCase();
    for (final m in AdminModule.values) {
      if (m.slug == s) return m;
    }
    return AdminModule.overview;
  }
}
