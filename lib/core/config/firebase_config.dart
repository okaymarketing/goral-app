// Firebase configuration for multiple environments
class FirebaseConfig {
  static const String devProjectId = 'goral-app-dev';
  static const String stagingProjectId = 'goral-app-staging';
  static const String prodProjectId = 'goral-app-prod';

  static String get currentProjectId {
    const String env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'staging':
        return stagingProjectId;
      case 'production':
        return prodProjectId;
      default:
        return devProjectId;
    }
  }
}