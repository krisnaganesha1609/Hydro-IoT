import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydro_iot/src/auth/application/controllers/auth_controller.dart';
import 'package:hydro_iot/src/auth/presentation/screens/auth_screen.dart';
import 'package:hydro_iot/src/auth/presentation/screens/change_password_screen.dart';
import 'package:hydro_iot/src/auth/presentation/screens/forgot_password_screen.dart';
import 'package:hydro_iot/src/auth/presentation/screens/landing_screen.dart';
import 'package:hydro_iot/src/auth/presentation/screens/login_screen.dart';
import 'package:hydro_iot/src/auth/presentation/screens/otp_password_screen.dart';
import 'package:hydro_iot/src/auth/presentation/screens/register_screen.dart';
import 'package:hydro_iot/src/common/error_screen.dart';
import 'package:hydro_iot/src/common/home/navbar.dart';
import 'package:hydro_iot/src/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:hydro_iot/src/dashboard/presentation/screens/search_crop_cycle_screen.dart';
import 'package:hydro_iot/src/devices/presentation/screens/add_device/add_device_form_screen.dart';
import 'package:hydro_iot/src/devices/presentation/screens/add_device/add_device_pairing_step_screen.dart';
import 'package:hydro_iot/src/devices/presentation/screens/add_device/add_device_preparing_screen.dart';
import 'package:hydro_iot/src/devices/presentation/screens/search_device_screen.dart';
import 'package:hydro_iot/src/devices/presentation/screens/add_device/add_device_screen.dart';
import 'package:hydro_iot/src/devices/presentation/screens/detail_device_screen.dart';
import 'package:hydro_iot/src/devices/presentation/screens/devices_screen.dart';
import 'package:hydro_iot/src/devices/presentation/screens/history/sensor_history_screen.dart';
import 'package:hydro_iot/src/devices/presentation/screens/setting_device_screen.dart';
import 'package:hydro_iot/src/devices/presentation/screens/start_calibration_screen.dart';
import 'package:hydro_iot/src/devices/presentation/screens/view_all_session_screen.dart';
import 'package:hydro_iot/src/devices/presentation/screens/add_device/serial_number_scanner_screen.dart';
import 'package:hydro_iot/src/notification/presentation/screens/notification_screen.dart';
import 'package:hydro_iot/src/profile/presentation/screens/change_password_request_screen.dart';
import 'package:hydro_iot/src/profile/presentation/screens/change_password_screen.dart';
import 'package:hydro_iot/src/profile/presentation/screens/change_password_verify_otp_screen.dart';
import 'package:hydro_iot/src/profile/presentation/screens/profile_screen.dart';
import 'package:hydro_iot/utils/utils.dart';

import '../../src/auth/presentation/screens/splash_screen.dart';
import '../../src/devices/presentation/screens/calibration/calibration_steps_screen.dart';
import '../../utils/connectivity_wrapper.dart';

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    // Ikut mendengarkan status dari AuthController
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: NavigationService.rootNavigatorKey,
    initialLocation: '/${SplashScreen.path}',
    routes: [
      GoRoute(
        path: '/${SplashScreen.path}',
        name: SplashScreen.path,
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/${LandingScreen.path}',
        name: LandingScreen.path,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ConnectivityWrapper(child: LandingScreen()),

          transitionDuration: const Duration(milliseconds: 720),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
            final pageOpacity = Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.20, 1.0, curve: Curves.easeOut),
              ),
            );
            final curtainSlide = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0.0, -1.02),
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic));
            return Stack(
              children: [
                FadeTransition(opacity: pageOpacity, child: child),
                SlideTransition(
                  position: curtainSlide,
                  child: Container(color: Colors.white, width: double.infinity, height: double.infinity),
                ),
              ],
            );
          },
        ),
      ),
      GoRoute(
        path: '/${AuthScreen.path}',
        name: AuthScreen.path,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ConnectivityWrapper(child: AuthScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/${LoginScreen.path}',
        name: LoginScreen.path,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ConnectivityWrapper(child: LoginScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween = Tween(begin: begin, end: end);
            final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
            return SlideTransition(position: tween.animate(curvedAnimation), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/${RegisterScreen.path}',
        name: RegisterScreen.path,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ConnectivityWrapper(child: RegisterScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween = Tween(begin: begin, end: end);
            final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
            return SlideTransition(position: tween.animate(curvedAnimation), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/${ForgotPasswordScreen.path}',
        name: ForgotPasswordScreen.path,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ConnectivityWrapper(child: ForgotPasswordScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween = Tween(begin: begin, end: end);
            final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
            return SlideTransition(position: tween.animate(curvedAnimation), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/${OtpPasswordScreen.path}',
        name: OtpPasswordScreen.path,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ConnectivityWrapper(child: OtpPasswordScreen(email: extra?['email'] as String)),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              final tween = Tween(begin: begin, end: end);
              final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
              return SlideTransition(position: tween.animate(curvedAnimation), child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/${ChangePasswordScreen.path}',
        name: ChangePasswordScreen.path,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ConnectivityWrapper(
              child: ChangePasswordScreen(email: extra?['email'] as String, resetToken: extra?['resetToken'] as String),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              final tween = Tween(begin: begin, end: end);
              final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
              return SlideTransition(position: tween.animate(curvedAnimation), child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/${AddDeviceScreen.path}',
        name: AddDeviceScreen.path,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ConnectivityWrapper(child: AddDeviceScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween = Tween(begin: begin, end: end);
            final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
            return SlideTransition(position: tween.animate(curvedAnimation), child: child);
          },
        ),
        routes: [
          GoRoute(
            path: '/${SerialNumberScannerScreen.path}',
            name: SerialNumberScannerScreen.path,
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const ConnectivityWrapper(child: SerialNumberScannerScreen()),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  final tween = Tween(begin: begin, end: end);
                  final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
                  return SlideTransition(position: tween.animate(curvedAnimation), child: child);
                },
              );
            },
          ),
          GoRoute(
            path: '/${AddDeviceFormScreen.path}',
            name: AddDeviceFormScreen.path,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CustomTransitionPage(
                key: state.pageKey,
                child: ConnectivityWrapper(child: AddDeviceFormScreen(serialNumber: extra?['serialNumber'] as String? ?? '')),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  final tween = Tween(begin: begin, end: end);
                  final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
                  return SlideTransition(position: tween.animate(curvedAnimation), child: child);
                },
              );
            },
          ),
          GoRoute(
            path: '/${AddDevicePreparingScreen.path}',
            name: AddDevicePreparingScreen.path,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CustomTransitionPage(
                key: state.pageKey,
                child: ConnectivityWrapper(
                  child: AddDevicePreparingScreen(
                    serialNumber: extra?['serialNumber'] as String? ?? '',
                    deviceName: extra?['deviceName'] as String? ?? '',
                    deviceDescription: extra?['deviceDescription'] as String? ?? '',
                  ),
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  final tween = Tween(begin: begin, end: end);
                  final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
                  return SlideTransition(position: tween.animate(curvedAnimation), child: child);
                },
              );
            },
          ),
          GoRoute(
            path: '/${AddDevicePairingStepScreen.path}',
            name: AddDevicePairingStepScreen.path,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CustomTransitionPage(
                key: state.pageKey,
                child: ConnectivityWrapper(
                  child: AddDevicePairingStepScreen(
                    serialNumber: extra?['serialNumber'] as String? ?? '',
                    deviceName: extra?['deviceName'] as String? ?? '',
                    deviceDescription: extra?['deviceDescription'] as String? ?? '',
                  ),
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  final tween = Tween(begin: begin, end: end);
                  final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
                  return SlideTransition(position: tween.animate(curvedAnimation), child: child);
                },
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/${SettingDeviceScreen.path}',
        name: SettingDeviceScreen.path,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ConnectivityWrapper(
              child: SettingDeviceScreen(
                deviceId: extra['deviceId'] as String,
                deviceName: extra['deviceName'] as String,
                deviceDescription: extra['deviceDescription'] as String,
                addedAt: extra['addedAt'] as String,
                updatedAt: extra['updatedAt'] as String,
                ssid: extra['ssid'] as String,
                serialNumber: extra['serialNumber'] as String,
              ),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              final tween = Tween(begin: begin, end: end);
              final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
              return SlideTransition(position: tween.animate(curvedAnimation), child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/${ChangePasswordRequestScreen.path}',
        name: ChangePasswordRequestScreen.path,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ConnectivityWrapper(child: ChangePasswordRequestScreen(email: extra?['email'] as String)),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              final tween = Tween(begin: begin, end: end);
              final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
              return SlideTransition(position: tween.animate(curvedAnimation), child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/${ChangePasswordVerifyOtpScreen.path}',
        name: ChangePasswordVerifyOtpScreen.path,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ConnectivityWrapper(child: ChangePasswordVerifyOtpScreen(email: extra?['email'] as String)),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              final tween = Tween(begin: begin, end: end);
              final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
              return SlideTransition(position: tween.animate(curvedAnimation), child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/${AuthedChangePasswordScreen.path}',
        name: AuthedChangePasswordScreen.path,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ConnectivityWrapper(
              child: AuthedChangePasswordScreen(email: extra['email'] as String, resetToken: extra['resetToken'] as String),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              final tween = Tween(begin: begin, end: end);
              final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
              return SlideTransition(position: tween.animate(curvedAnimation), child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/${SensorHistoryScreen.path}',
        name: SensorHistoryScreen.path,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ConnectivityWrapper(child: SensorHistoryScreen(cropCycleId: extra['cropCycleId'] as String)),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              final tween = Tween(begin: begin, end: end);
              final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
              return SlideTransition(position: tween.animate(curvedAnimation), child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/${StartCalibrationScreen.path}',
        name: StartCalibrationScreen.path,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ConnectivityWrapper(child: StartCalibrationScreen(serial: extra?['serialNumber'] as String? ?? '')),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              final tween = Tween(begin: begin, end: end);
              final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
              return SlideTransition(position: tween.animate(curvedAnimation), child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/${CalibrationStepsScreen.path}',
        name: CalibrationStepsScreen.path,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ConnectivityWrapper(child: CalibrationStepsScreen(serial: extra?['serialNumber'] as String? ?? '')),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              final tween = Tween(begin: begin, end: end);
              final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
              return SlideTransition(position: tween.animate(curvedAnimation), child: child);
            },
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) => CustomTransitionPage(
          key: state.pageKey,
          child: ConnectivityWrapper(child: Navbar(navigationShell: navigationShell)),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/${DashboardScreen.path}',
                name: DashboardScreen.path,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const ConnectivityWrapper(child: DashboardScreen()),
                  transitionDuration: const Duration(milliseconds: 720),
                  reverseTransitionDuration: const Duration(milliseconds: 350),
                  transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
                    final pageOpacity = Tween<double>(begin: 0.85, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: const Interval(0.20, 1.0, curve: Curves.easeOut),
                      ),
                    );
                    final curtainSlide = Tween<Offset>(
                      begin: Offset.zero,
                      end: const Offset(0.0, -1.02),
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic));
                    return Stack(
                      children: [
                        FadeTransition(opacity: pageOpacity, child: child),
                        SlideTransition(
                          position: curtainSlide,
                          child: Container(color: Colors.white, width: double.infinity, height: double.infinity),
                        ),
                      ],
                    );
                  },
                ),
                routes: [
                  GoRoute(
                    path: '/${SearchDeviceScreen.path}',
                    name: SearchDeviceScreen.path,
                    pageBuilder: (context, state) => CustomTransitionPage(
                      key: state.pageKey,
                      child: const ConnectivityWrapper(child: SearchDeviceScreen()),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  ),
                  GoRoute(
                    path: '/${SearchCropCycleScreen.path}',
                    name: SearchCropCycleScreen.path,
                    pageBuilder: (context, state) => CustomTransitionPage(
                      key: state.pageKey,
                      child: const ConnectivityWrapper(child: SearchCropCycleScreen()),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/${DevicesScreen.path}',
                name: DevicesScreen.path,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const ConnectivityWrapper(child: DevicesScreen()),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
                routes: [
                  GoRoute(
                    path: '/:serialNumber',
                    name: 'deviceDetail',
                    pageBuilder: (context, state) {
                      final serialNumber = state.pathParameters['serialNumber']!;
                      final extra = state.extra as Map<String, dynamic>;
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: ConnectivityWrapper(
                          child: DetailDeviceScreen(
                            deviceId: serialNumber,
                            deviceName: extra['deviceName'] as String,
                            pH: extra['pH'] as double,
                            ppm: (extra['ppm'] as double).toInt(),
                            deviceDescription: extra['deviceDescription'] as String?,
                          ),
                        ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                      );
                    },
                    routes: [
                      GoRoute(
                        path: '/${ViewAllPlantSessionScreen.path}',
                        name: ViewAllPlantSessionScreen.path,
                        pageBuilder: (context, state) {
                          final serialNumber = state.pathParameters['serialNumber']!;
                          final extra = state.extra as Map<String, dynamic>;
                          return CustomTransitionPage(
                            key: state.pageKey,
                            child: ConnectivityWrapper(
                              child: ViewAllPlantSessionScreen(
                                deviceId: extra['deviceId'] as String,
                                deviceName: extra['deviceName'] as String,
                                serialNumber: serialNumber,
                              ),
                            ),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/${NotificationCenterScreen.path}',
                name: NotificationCenterScreen.path,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const ConnectivityWrapper(child: NotificationCenterScreen()),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/${ProfileScreen.path}',
                name: ProfileScreen.path,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const ConnectivityWrapper(child: ProfileScreen()),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    observers: [routeObserver],
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => ErrorScreen(errorMessage: state.error!.message),
    refreshListenable: GoRouterRefreshNotifier(ref),
    redirect: (context, state) async {
      if (state.matchedLocation == '/${SplashScreen.path}') {
        return null;
      }
      final isLoggedIn = await Storage().readIsLoggedIn;
      final role = await Storage().readRole();
      debugPrint('isLoggedIn: $isLoggedIn, role: $role, path: ${state.matchedLocation}');
      final publicPaths = [
        '/',
        '/${LandingScreen.path}',
        '/${AuthScreen.path}',
        '/${LoginScreen.path}',
        '/${RegisterScreen.path}',
        '/${ChangePasswordScreen.path}',
        '/${ForgotPasswordScreen.path}',
        '/${OtpPasswordScreen.path}',
      ];

      if (isLoggedIn == null) {
        return '/${LandingScreen.path}';
      }
      if (role == 'ADMIN' && isLoggedIn) {
        await Storage().clearSession();
        return '/${AuthScreen.path}';
      }
      if (!isLoggedIn && !publicPaths.contains(state.matchedLocation)) {
        await Storage().clearSession();
        return '/${AuthScreen.path}';
      }
      if (isLoggedIn && publicPaths.contains(state.matchedLocation)) {
        return '/${DashboardScreen.path}';
      }
      return null;
    },
  );
});

/// Route observer to use with RouteAware
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
