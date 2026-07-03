import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hydro_iot/core/config/config.dart';

class AppStrings {
  static const String appName = 'ꫀHydrotel';
  static const String appDescription = 'Smart Hydroponic Monitoring System';
  static const String errorMessage = 'An error has occurred. Please try again.';
  static const String loadingMessage = 'Loading, please wait...';
  static const String successMessage = 'Operation completed successfully!';
  static const String noDataMessage = 'No data available.';
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String unauthorizedMessage = 'Unauthorized access. Please log in again.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String invalidInputMessage = 'Invalid input. Please check your data.';
  static const String timeoutMessage = 'Request timed out. Please try again.';
  static const String maintenanceMessage = 'The system is currently under maintenance. Please try again later.';
  static String appVersion = dotenv.env['APP_VERSION'] ?? '1.0.0';
}

class EndpointStrings {
  static final baseUrl = BaseConfigs.baseUrl;
  static final login = '$baseUrl/auth/login';
  static final googleLogin = '$baseUrl/auth/google';
  static final register = '$baseUrl/auth/register';
  static final resetPassword = '$baseUrl/auth/password/reset';
  static final userProfile = '$baseUrl/auth/profile';
  static final updateProfile = '$baseUrl/users/profile';
  static final devices = '$baseUrl/devices';
  static final getMyDevices = '$devices/me';
  static final registerMyDevice = '$devices/register';
  static final plants = '$baseUrl/plants';
  static final cropcycle = '$baseUrl/crop-cycle';
  static final cropcycleByUser = '$cropcycle/user';
  static final cropcycleByDevice = '$cropcycle/device';
  static final sensors = '$baseUrl/sensors';
  static final historySensor = '$sensors/summaries';
  static final sendEmail = '$resetPassword/request';
  static final verifyOtp = '$resetPassword/verify';
  static final notif = '$baseUrl/notif';
  static final registerFcmToken = '$notif/register-token';
  static final notifHistory = '$notif/history';
  static final calibration = '$baseUrl/calibration';
}

enum DeviceStatus { active, idle, offline, calibrating }

String getDeviceStatusText(DeviceStatus status) {
  switch (status) {
    case DeviceStatus.active:
      return 'ACTIVE';
    case DeviceStatus.idle:
      return 'IDLE';
    case DeviceStatus.offline:
      return 'OFFLINE';
    case DeviceStatus.calibrating:
      return 'CALIBRATING';
  }
}

enum PlantStatus { planned, ongoing, finished, failed }

String getPlantStatusText(PlantStatus status) {
  switch (status) {
    case PlantStatus.planned:
      return 'PLANNED';
    case PlantStatus.ongoing:
      return 'ONGOING';
    case PlantStatus.finished:
      return 'FINISHED';
    case PlantStatus.failed:
      return 'FAILED';
  }
}
