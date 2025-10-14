import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://rdgdpyncadiibidqlxbv.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkZ2RweW5jYWRpaWJpZHFseGJ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzODAwNjcsImV4cCI6MjA3NTk1NjA2N30.cEahPvODZGiN2a_NpRd4vfqRhQpaui1ttKxe_sXVT1I';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
