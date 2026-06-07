import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../models/training_item.dart';

class TrainingService {
  final SupabaseClient _supabase;

  TrainingService(this._supabase);

  // ==================== COURS ====================
  
  Future<List<TrainingItem>> listPublishedTrainings() async {
    final response = await _supabase
        .from('thix_trainings')
        .select('*')
        .eq('is_published', true)
        .order('created_at', ascending: false);
    return (response as List).map((e) => TrainingItem.fromJson(e)).toList();
  }

  Future<List<TrainingItem>> listAllTrainings() async {
    final response = await _supabase
        .from('thix_trainings')
        .select('*')
        .order('created_at', ascending: false);
    return (response as List).map((e) => TrainingItem.fromJson(e)).toList();
  }

  Future<TrainingItem?> getTrainingById(String id) async {
    final response = await _supabase
        .from('thix_trainings')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return TrainingItem.fromJson(response);
  }

  // ==================== COVER URL HELPER ====================
  
  String? getCoverUrl(TrainingItem training) {
    if (training.coverImageBucket == null || training.coverImagePath == null) return null;
    return _supabase.storage.from(training.coverImageBucket!).getPublicUrl(training.coverImagePath!);
  }

  // ==================== MODULES ====================
  
  Future<List<Map<String, dynamic>>> getModulesByTrainingId(String trainingId) async {
    final response = await _supabase
        .from('training_modules')
        .select('*')
        .eq('training_id', trainingId)
        .order('module_index');
    return response is List ? response.cast<Map<String, dynamic>>() : [];
  }

  // ==================== LEÇONS ====================
  
  Future<List<Map<String, dynamic>>> getLessonsByModuleId(String moduleId) async {
    final response = await _supabase
        .from('training_lessons')
        .select('*')
        .eq('module_id', moduleId)
        .order('lesson_index');
    return response is List ? response.cast<Map<String, dynamic>>() : [];
  }

  Future<List<Map<String, dynamic>>> getAllLessonsByTrainingId(String trainingId) async {
    final modules = await getModulesByTrainingId(trainingId);
    List<Map<String, dynamic>> allLessons = [];
    for (final module in modules) {
      final lessons = await getLessonsByModuleId(module['id']);
      allLessons.addAll(lessons);
    }
    return allLessons;
  }

  // ==================== QUIZ ====================
  
  Future<List<Map<String, dynamic>>> getQuizByLessonId(String lessonId) async {
    final response = await _supabase
        .from('quiz_questions')
        .select('*')
        .eq('lesson_id', lessonId);
    return response is List ? response.cast<Map<String, dynamic>>() : [];
  }

  // ==================== RESSOURCES ====================
  
  Future<List<Map<String, dynamic>>> getResourcesByLessonId(String lessonId) async {
    final response = await _supabase
        .from('lesson_resources')
        .select('*')
        .eq('lesson_id', lessonId);
    return response is List ? response.cast<Map<String, dynamic>>() : [];
  }

  // ==================== ENROLLEMENTS ====================
  
  Future<Map<String, dynamic>?> fetchEnrollmentById(String enrollmentId) async {
    final response = await _supabase
        .from('user_enrollments')
        .select('*')
        .eq('id', enrollmentId)
        .maybeSingle();
    return response as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> fetchUserEnrollments(String userId) async {
    final response = await _supabase
        .from('user_enrollments')
        .select('*, training:thix_trainings(*)')
        .eq('user_id', userId);
    return response is List ? response.cast<Map<String, dynamic>>() : [];
  }

  Future<void> saveProgress(String enrollmentId, String lessonId, int progressPercent) async {
    await _supabase.from('user_enrollments').update({
      'current_lesson_id': lessonId,
      'progress_percent': progressPercent,
      'last_accessed_at': DateTime.now().toIso8601String(),
    }).eq('id', enrollmentId);
  }

  Future<void> enrollUser(String userId, String trainingId) async {
    final existing = await _supabase
        .from('user_enrollments')
        .select('id')
        .eq('user_id', userId)
        .eq('training_id', trainingId)
        .maybeSingle();
    
    if (existing == null) {
      await _supabase.from('user_enrollments').insert({
        'user_id': userId,
        'training_id': trainingId,
        'progress_percent': 0,
        'started_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ==================== ADMIN ====================

  Future<String> createCourse(Map<String, dynamic> data) async {
    final response = await _supabase.from('thix_trainings').insert(data).select();
    return (response as List).first['id'] as String;
  }

  Future<void> updateCourse(String id, Map<String, dynamic> data) async {
    await _supabase.from('thix_trainings').update(data).eq('id', id);
  }

  Future<String> createModule(Map<String, dynamic> data) async {
    final response = await _supabase.from('training_modules').insert(data).select();
    return (response as List).first['id'] as String;
  }

  Future<String> createLesson(Map<String, dynamic> data) async {
    final response = await _supabase.from('training_lessons').insert(data).select();
    return (response as List).first['id'] as String;
  }

  Future<void> deleteItem(String table, String id) async {
    await _supabase.from(table).delete().eq('id', id);
  }

  Future<void> uploadLessonVideo(String lessonId, PlatformFile file) async {
    final ext = file.name.split('.').last;
    final path = 'training_videos/$lessonId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    
    if (kIsWeb) {
      await _supabase.storage.from('training_videos').uploadBinary(path, file.bytes!);
    } else {
      final fileBytes = await File(file.path!).readAsBytes();
      await _supabase.storage.from('training_videos').uploadBinary(path, fileBytes);
    }
    
    final videoUrl = _supabase.storage.from('training_videos').getPublicUrl(path);
    await _supabase.from('training_lessons').update({'content_url': videoUrl}).eq('id', lessonId);
  }

  Future<void> addQuizQuestion(String lessonId, Map<String, dynamic> question) async {
    await _supabase.from('quiz_questions').insert({
      'lesson_id': lessonId,
      ...question,
    });
  }

  Future<void> addResource(String lessonId, PlatformFile file, String title) async {
    final ext = file.name.split('.').last;
    final path = 'training_resources/$lessonId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    
    if (kIsWeb) {
      await _supabase.storage.from('training_resources').uploadBinary(path, file.bytes!);
    } else {
      final fileBytes = await File(file.path!).readAsBytes();
      await _supabase.storage.from('training_resources').uploadBinary(path, fileBytes);
    }
    
    final resourceUrl = _supabase.storage.from('training_resources').getPublicUrl(path);
    await _supabase.from('lesson_resources').insert({
      'lesson_id': lessonId,
      'title': title,
      'type': ext,
      'url': resourceUrl,
      'file_size': file.size,
    });
  }
}
