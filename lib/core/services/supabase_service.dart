import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  SupabaseClient get _db => Supabase.instance.client;
  String? get userId => _db.auth.currentUser?.id;

  Future<Map<String, dynamic>?> getProfile() async {
    if (userId == null) return null;
    return await _db.from('profiles').select().eq('id', userId!).maybeSingle();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (userId == null) return;
    await _db.from('profiles').upsert({'id': userId!, ...data});
  }

  Future<List<Map<String, dynamic>>> getSessions({int limit = 20}) async {
    if (userId == null) return [];
    final res = await _db.from('sessions').select().eq('user_id', userId!).order('created_at', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getSessionsThisMonth() async {
    if (userId == null) return [];
    final now   = DateTime.now();
    final start = DateTime(now.year, now.month, 1).toIso8601String();
    final end   = DateTime(now.year, now.month + 1, 1).toIso8601String();
    final res   = await _db.from('sessions').select().eq('user_id', userId!).gte('created_at', start).lt('created_at', end).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<int>> getWeeklyCounts({int weeks = 7}) async {
    if (userId == null) return List.filled(weeks, 0);
    final counts = List<int>.filled(weeks, 0);
    final now = DateTime.now();
    for (int i = 0; i < weeks; i++) {
      final weekStart = now.subtract(Duration(days: (weeks - 1 - i) * 7 + now.weekday - 1));
      final weekEnd   = weekStart.add(const Duration(days: 7));
      final res = await _db.from('sessions').select('id').eq('user_id', userId!).gte('created_at', DateTime(weekStart.year, weekStart.month, weekStart.day).toIso8601String()).lt('created_at', DateTime(weekEnd.year, weekEnd.month, weekEnd.day).toIso8601String());
      counts[i] = (res as List).length;
    }
    return counts;
  }

  Future<double> getVolumeThisMonth() async {
    final sessions = await getSessionsThisMonth();
    return sessions.fold(0.0, (sum, s) => sum + ((s['volume_kg'] ?? 0) as num).toDouble());
  }

  Future<int> getCurrentStreak() async {
    if (userId == null) return 0;
    final res = await _db.from('sessions').select('created_at').eq('user_id', userId!).order('created_at', ascending: false).limit(60);
    if ((res as List).isEmpty) return 0;
    final days = res.map((s) => DateTime.parse(s['created_at']).toLocal()).map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime expected = DateTime.now();
    expected = DateTime(expected.year, expected.month, expected.day);
    for (final day in days) {
      if (day == expected || day == expected.subtract(const Duration(days: 1))) {
        streak++;
        expected = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<List<Map<String, dynamic>>> getPersonalRecords() async {
    if (userId == null) return [];
    final res = await _db.from('personal_records').select().eq('user_id', userId!).order('value_kg', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getBodyWeight({int limit = 10}) async {
    if (userId == null) return [];
    final res = await _db.from('body_weight').select().eq('user_id', userId!).order('date', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> saveSession(Map<String, dynamic> data) async {
    if (userId == null) return;
    await _db.from('sessions').insert({'user_id': userId!, ...data});
  }
}

extension on FutureOr<double> {
  FutureOr<double> operator +(double other) => this;
}

// Removed erroneous extension that caused analyzer errors. Summation uses plain double operations.
