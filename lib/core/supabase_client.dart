import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_secrets.dart';

/// Supabase 클라이언트 관리 클래스
///
/// [agency-backend-architect]: 다중 사용자 확장을 위해 기존 SQLite 로직을
/// Supabase(PostgreSQL)로 전환하는 첫 번째 단계입니다.
class SupabaseManager {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppSecrets.supabaseUrl,
      anonKey: AppSecrets.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// 데이터베이스 스키마 가이드 (Supabase SQL Editor에서 실행):
  ///
  /// -- 1. 사용자 테이블 (profiles)
  /// create table public.profiles (
  ///   id uuid references auth.users not null primary key,
  ///   full_name text,
  ///   avatar_url text,
  ///   updated_at timestamp with time zone default now()
  /// );
  ///
  /// -- 2. 인지 점수 테이블 (cognitive_scores)
  /// create table public.cognitive_scores (
  ///   id bigserial primary key,
  ///   user_id uuid references auth.users not null,
  ///   domain_type text not null, -- 'calculation', 'memory', etc.
  ///   score double precision not null,
  ///   measured_at timestamp with time zone default now()
  /// );
  ///
  /// -- 3. 음성 진단 기록 (voice_records)
  /// create table public.voice_records (
  ///   id bigserial primary key,
  ///   user_id uuid references auth.users not null,
  ///   audio_url text not null, -- Supabase Storage link
  ///   risk_score double precision,
  ///   analysis_result jsonb,
  ///   created_at timestamp with time zone default now()
  /// );
}
