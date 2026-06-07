import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';

// Pages
import 'presentation/home/home_page.dart';
import 'presentation/auth/login_page.dart';
import 'presentation/auth/personal_registration_page.dart';
import 'presentation/auth/enterprise_registration_page.dart';
import 'presentation/payment/payment_gateway_page.dart';
import 'presentation/payment/activation_receipt_page.dart';
import 'presentation/profile/public_profile_page.dart';
import 'presentation/dashboard/user_dashboard_page.dart';
import 'presentation/enterprise/enterprise_dashboard_page.dart';
import 'presentation/chat/thix_chat_page.dart';
import 'presentation/vault/document_vault_page.dart';
import 'presentation/settings/settings_page.dart';
import 'presentation/network/network_page.dart';
import 'presentation/jobs/jobs_page.dart';
import 'presentation/jobs/job_apply_page.dart';
import 'presentation/jobs/job_details_page.dart';
import 'presentation/jobs/job_dashboard_page.dart';
import 'presentation/recruiter/recruiter_portal_page.dart';
import 'presentation/opportunities/opportunities_page.dart';
import 'presentation/opportunities/opportunity_apply_page.dart';
import 'presentation/opportunities/opportunity_details_page.dart';
import 'presentation/events/events_page.dart';
import 'presentation/events/event_details_page.dart';
import 'presentation/events/event_register_page.dart';
import 'presentation/events/event_ticket_page.dart';
import 'presentation/events/user_event_dashboard_page.dart';
import 'presentation/education/education_page.dart';
import 'presentation/training/training_home_page.dart';
import 'presentation/training/training_details_page.dart';
import 'presentation/training/learning_dashboard_page.dart';
import 'presentation/training/lesson_player_page.dart';
import 'presentation/admin/admin_page.dart';
import 'presentation/thix_market/thix_market_page.dart';
import 'presentation/thix_market/cart_page.dart';
import 'presentation/thix_market/checkout_page.dart';
import 'presentation/thix_market/order_history_page.dart';
import 'presentation/thix_sante/thix_sante_page.dart';
import 'presentation/thix_reservation/thix_reservation_page.dart';
import 'presentation/thix_money/thix_money_page.dart';
import 'presentation/thix_media/thix_media_page.dart';

// Modèles
import 'models/event_item.dart';

class NoTransitionPage<T> extends Page<T> {
  final Widget child;
  const NoTransitionPage({required this.child, super.key});

  @override
  Route<T> createRoute(BuildContext context) {
    return MaterialPageRoute(builder: (context) => child, settings: this);
  }
}

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String personalReg = '/personal-reg';
  static const String enterpriseReg = '/enterprise-reg';
  static const String userDashboard = '/user-dashboard';
  static const String enterpriseDashboard = '/enterprise-dashboard';
  static const String chat = '/chat';
  static const String vault = '/vault';
  static const String settings = '/settings';
  static const String network = '/network';
  static const String jobs = '/jobs';
  static const String opportunities = '/opportunities';
  static const String events = '/events';
  static const String education = '/education';
  static const String trainingHome = '/training';
  static const String admin = '/admin';
  static const String market = '/market';
  static const String marketCart = '/market/cart';
  static const String marketCheckout = '/market/checkout';
  static const String marketOrders = '/market/orders';
}

class AppRouter {
  static GoRouter create(AuthController auth) {
    return GoRouter(
      initialLocation: AppRoutes.home,
      refreshListenable: auth,
      redirect: (context, state) {
        final isLoggedIn = auth.isAuthenticated;
        final location = state.matchedLocation;

        final isAuthPage = location == AppRoutes.login ||
            location == AppRoutes.personalReg ||
            location == AppRoutes.enterpriseReg;

        if (!isLoggedIn && !isAuthPage) {
          return AppRoutes.login;
        }
        if (isLoggedIn && isAuthPage) {
          return AppRoutes.userDashboard;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => const NoTransitionPage(child: HomePagePremium()),
        ),
        GoRoute(
          path: AppRoutes.login,
          pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage()),
        ),
        GoRoute(
          path: AppRoutes.personalReg,
          pageBuilder: (context, state) => const NoTransitionPage(child: PersonalRegistrationPage()),
        ),
        GoRoute(
          path: AppRoutes.enterpriseReg,
          pageBuilder: (context, state) => const NoTransitionPage(child: EnterpriseRegistrationPage()),
        ),
        GoRoute(
          path: AppRoutes.userDashboard,
          pageBuilder: (context, state) => const NoTransitionPage(child: UserDashboardPage()),
        ),
        GoRoute(
          path: AppRoutes.enterpriseDashboard,
          pageBuilder: (context, state) => const NoTransitionPage(child: EnterpriseDashboardPage()),
        ),
        GoRoute(
          path: AppRoutes.chat,
          pageBuilder: (context, state) => const NoTransitionPage(child: ThixChatPage()),
        ),
        GoRoute(
          path: AppRoutes.vault,
          pageBuilder: (context, state) => const NoTransitionPage(child: DocumentVaultPage()),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => const NoTransitionPage(child: SettingsPage()),
        ),
        GoRoute(
          path: AppRoutes.network,
          pageBuilder: (context, state) => const NoTransitionPage(child: NetworkPage()),
        ),
        GoRoute(
          path: AppRoutes.jobs,
          pageBuilder: (context, state) => const NoTransitionPage(child: JobsPage()),
        ),
        GoRoute(
          path: AppRoutes.opportunities,
          pageBuilder: (context, state) => const NoTransitionPage(child: OpportunitiesPage()),
        ),
        GoRoute(
          path: AppRoutes.events,
          pageBuilder: (context, state) => const NoTransitionPage(child: EventsPage()),
        ),

        // ==================== JOB ROUTES ====================
        GoRoute(
          path: '/jobs/:jobId',
          pageBuilder: (context, state) {
            final jobId = state.pathParameters['jobId'] ?? '';
            final applied = (state.uri.queryParameters['applied'] ?? '').trim() == '1';
            return NoTransitionPage(child: JobDetailsPage(jobId: jobId, applied: applied));
          },
        ),
        GoRoute(
          path: '/jobs/:jobId/apply',
          pageBuilder: (context, state) {
            final jobId = state.pathParameters['jobId'] ?? '';
            return NoTransitionPage(child: JobApplyPage(jobId: jobId));
          },
        ),
        GoRoute(
          path: '/job-dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(child: JobDashboardPage()),
        ),
        GoRoute(
          path: '/recruiter',
          pageBuilder: (context, state) => const NoTransitionPage(child: RecruiterPortalPage()),
        ),

        // ==================== OPPORTUNITIES ROUTES ====================
        GoRoute(
          path: '/opportunities/:opportunityId',
          pageBuilder: (context, state) {
            final opportunityId = state.pathParameters['opportunityId'] ?? '';
            final applied = (state.uri.queryParameters['applied'] ?? '').trim() == '1';
            return NoTransitionPage(child: OpportunityDetailsPage(opportunityId: opportunityId, applied: applied));
          },
        ),
        GoRoute(
          path: '/opportunities/:opportunityId/apply',
          pageBuilder: (context, state) {
            final opportunityId = state.pathParameters['opportunityId'] ?? '';
            return NoTransitionPage(child: OpportunityApplyPage(opportunityId: opportunityId));
          },
        ),

        // ==================== EVENTS ROUTES ====================
        GoRoute(
          path: '/events/:eventId',
          pageBuilder: (context, state) {
            final eventId = state.pathParameters['eventId'] ?? '';
            final registered = (state.uri.queryParameters['registered'] ?? '').trim() == '1';
            return NoTransitionPage(child: EventDetailsPage(eventId: eventId));
          },
        ),
        GoRoute(
          path: '/events/:eventId/register',
          pageBuilder: (context, state) {
            final eventId = state.pathParameters['eventId'] ?? '';
            return NoTransitionPage(
              child: EventRegisterPage(
                event: EventItem(
                  id: eventId,
                  title: 'Chargement...',
                  description: '',
                  category: 'Autre',
                  location: '',
                  startsAt: DateTime.now(),
                  endsAt: DateTime.now().add(const Duration(hours: 1)),
                  price: 0,
                  isRecommended: false,
                  isPublished: true,
                  maxParticipants: 0,
                  registeredParticipants: 0,
                  createdAt: DateTime.now(),
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: '/events/:eventId/ticket/:registrationId',
          pageBuilder: (context, state) {
            final eventId = state.pathParameters['eventId'] ?? '';
            final registrationId = state.pathParameters['registrationId'] ?? '';
            return NoTransitionPage(
              child: EventTicketPage(eventId: eventId, registrationId: registrationId),
            );
          },
        ),
        GoRoute(
          path: '/events/me',
          pageBuilder: (context, state) => const NoTransitionPage(child: UserEventDashboardPage()),
        ),

        // ==================== TRAINING ROUTES ====================
        GoRoute(
          path: AppRoutes.trainingHome,
          pageBuilder: (context, state) => const NoTransitionPage(child: TrainingHomePage()),
        ),
        GoRoute(
          path: '/training/:trainingId',
          pageBuilder: (context, state) {
            final trainingId = state.pathParameters['trainingId'] ?? '';
            return NoTransitionPage(child: TrainingDetailsPage(trainingId: trainingId));
          },
        ),
        GoRoute(
          path: '/learning-dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(child: LearningDashboardPage()),
        ),
        GoRoute(
          path: '/lesson/:enrollmentId',
          pageBuilder: (context, state) {
            final enrollmentId = state.pathParameters['enrollmentId'] ?? '';
            return NoTransitionPage(child: LessonPlayerPage(enrollmentId: enrollmentId));
          },
        ),

        // ==================== EDUCATION ROUTE ====================
        GoRoute(
          path: AppRoutes.education,
          pageBuilder: (context, state) => const NoTransitionPage(child: EducationPage()),
        ),

        // ==================== THIX MARKET ROUTES ====================
        GoRoute(
          path: AppRoutes.market,
          name: 'market',
          pageBuilder: (context, state) => const NoTransitionPage(child: ThixMarketPage()),
        ),
        GoRoute(
          path: AppRoutes.marketCart,
          name: 'marketCart',
          pageBuilder: (context, state) => const NoTransitionPage(child: CartPage()),
        ),
        GoRoute(
          path: AppRoutes.marketCheckout,
          name: 'marketCheckout',
          pageBuilder: (context, state) => const NoTransitionPage(child: CheckoutPage()),
        ),
        GoRoute(
          path: AppRoutes.marketOrders,
          name: 'marketOrders',
          pageBuilder: (context, state) => const NoTransitionPage(child: OrderHistoryPage()),
        ),

        // ==================== THIX SERVICES ROUTES ====================
        GoRoute(
          path: '/sante',
          pageBuilder: (context, state) => const NoTransitionPage(child: ThixSantePage()),
        ),
        GoRoute(
          path: '/reservation',
          pageBuilder: (context, state) => const NoTransitionPage(child: ThixReservationPage()),
        ),
        GoRoute(
          path: '/thix-money',
          pageBuilder: (context, state) => const NoTransitionPage(child: ThixMoneyPage()),
        ),
        GoRoute(
          path: '/thix-media',
          pageBuilder: (context, state) => const NoTransitionPage(child: ThixMediaPage()),
        ),

        // ==================== ADMIN ROUTES ====================
        GoRoute(
          path: AppRoutes.admin,
          name: 'adminRoot',
          redirect: (_, __) => '/admin/overview',
        ),
        GoRoute(
          path: '/admin/:module',
          name: 'admin',
          pageBuilder: (context, state) {
            final moduleName = state.pathParameters['module'] ?? 'overview';
            final module = _stringToModule(moduleName);
            return NoTransitionPage(
              child: AdminPage(module: module),
            );
          },
        ),
      ],
    );
  }
  
  // Helper pour convertir string en AdminModule
  static AdminModule _stringToModule(String name) {
    final slug = name.toLowerCase().trim();

    switch (slug) {
      case 'overview':
        return AdminModule.overview;
      
      case 'account-access-requests':
      case 'access-requests':
      case 'accessrequests':
        return AdminModule.accessRequests;

      case 'user-management':
      case 'users':
        return AdminModule.users;

      case 'verification-center':
      case 'verification':
        return AdminModule.verification;

      case 'events':
        return AdminModule.events;
      case 'trainings':
        return AdminModule.trainings;

      case 'thix-uid':
      case 'uid':
        return AdminModule.uid;

      case 'jobs-opportunities':
      case 'jobs':
        return AdminModule.jobs;

      case 'info-news':
      case 'news':
        return AdminModule.news;

      case 'thix-chat-admin':
      case 'chat':
        return AdminModule.chat;

      case 'sos-emergency':
      case 'sos':
        return AdminModule.sos;

      case 'institutions':
        return AdminModule.institutions;

      case 'analytics':
        return AdminModule.analytics;

      case 'cybersecurity':
        return AdminModule.cybersecurity;

      case 'api-integrations':
      case 'api':
        return AdminModule.api;

      case 'audit-activity':
      case 'audit':
        return AdminModule.audit;

      case 'thix-media':
      case 'media':
        return AdminModule.media;

      case 'settings':
        return AdminModule.settings;

      default:
        print('⚠️ Module inconnu: $slug → fallback sur overview');
        return AdminModule.overview;
    }
  }
}
