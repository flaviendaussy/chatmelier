class AppConstants {
  static const String appName = 'Chatmelier';
  static const String avatarsBucket = 'avatars';
  static const String labelsBucket = 'labels';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fvnybncauhbpsnikzeeq.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_P3P36VFswbjyOXxplwniPg_D_NuGYNF',
  );

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AQ.Ab8RN6JFZQNPfXmDdjdGT0posCOmn_4wPIFv_TiviorSGL6BDg',
  );
}
