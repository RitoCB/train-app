class AppConstants {
  AppConstants._();

  static const appName = 'TrainApp';
  static const appVersion = '1.0.0';

  // Supabase — reemplaza con tus credenciales
 static const supabaseUrl     = 'https://nkifnnoeisilmxxnaopi.supabase.co';
static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5raWZubm9laXNpbG14eG5hb3BpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5MzMyNTQsImV4cCI6MjA5OTUwOTI1NH0.32dXFy7g79I_umNZiP38O9mR1-H9lp1VXOOrlccyd08'; // la tuya completa
  // Hive boxes
  static const boxUser     = 'user';
  static const boxSessions = 'sessions';
  static const boxSettings = 'settings';

  // SharedPrefs / Secure Storage keys
  static const keyOnboardingDone = 'onboarding_done';
  static const keySportType      = 'sport_type';

  // Tipos de deporte
  static const sportGym      = 'gym';
  static const sportMartial  = 'martial';
  static const sportEndurance = 'endurance';
  static const sportCustom   = 'custom';
}
