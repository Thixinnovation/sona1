import 'dart:convert';

// models/training_course.dart
class TrainingCourse {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final String level;
  final String language;
  final String deliveryMode;
  final bool isFree;
  final double priceAmount;
  final String currency;
  final bool certificationIncluded;
  final bool isFeatured;
  final bool isPublished;
  final double rating;
  final int reviewsCount;
  final int studentsCount;
  final double completionRate;
  final String? coverUrl;
  final String? instructorName;
  final String? instructorAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TrainingModule> modules;

  TrainingCourse({
    required this.id,
    required this.title,
    this.description,
    this.category,
    required this.level,
    required this.language,
    required this.deliveryMode,
    required this.isFree,
    required this.priceAmount,
    required this.currency,
    required this.certificationIncluded,
    required this.isFeatured,
    required this.isPublished,
    required this.rating,
    required this.reviewsCount,
    required this.studentsCount,
    required this.completionRate,
    this.coverUrl,
    this.instructorName,
    this.instructorAvatar,
    required this.createdAt,
    required this.updatedAt,
    this.modules = const [],
  });

  factory TrainingCourse.fromJson(Map<String, dynamic> json) {
    return TrainingCourse(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      level: json['level'] as String,
      language: json['language'] as String,
      deliveryMode: json['delivery_mode'] as String,
      isFree: json['is_free'] as bool,
      priceAmount: (json['price_amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String,
      certificationIncluded: json['certification_included'] as bool,
      isFeatured: json['is_featured'] as bool,
      isPublished: json['is_published'] as bool,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      studentsCount: json['students_count'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
      coverUrl: json['cover_url'] as String?,
      instructorName: json['instructor_name'] as String?,
      instructorAvatar: json['instructor_avatar'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      modules: [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'level': level,
    'language': language,
    'delivery_mode': deliveryMode,
    'is_free': isFree,
    'price_amount': priceAmount,
    'currency': currency,
    'certification_included': certificationIncluded,
    'is_featured': isFeatured,
    'is_published': isPublished,
    'rating': rating,
    'reviews_count': reviewsCount,
    'students_count': studentsCount,
    'completion_rate': completionRate,
    'cover_url': coverUrl,
    'instructor_name': instructorName,
    'instructor_avatar': instructorAvatar,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

// models/training_module.dart
class TrainingModule {
  final String id;
  final String trainingId;
  final String title;
  final String? description;
  final int moduleIndex;
  final List<TrainingLesson> lessons;

  TrainingModule({
    required this.id,
    required this.trainingId,
    required this.title,
    this.description,
    required this.moduleIndex,
    this.lessons = const [],
  });

  factory TrainingModule.fromJson(Map<String, dynamic> json) {
    return TrainingModule(
      id: json['id'] as String,
      trainingId: json['training_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      moduleIndex: json['module_index'] as int,
      lessons: [],
    );
  }
}

// models/training_lesson.dart
class TrainingLesson {
  final String id;
  final String moduleId;
  final String title;
  final String? description;
  final int lessonIndex;
  final String contentType; // video, document, quiz, assignment
  final String? contentUrl; // URL vidéo ou document
  final int durationMinutes;
  final bool isPreview;
  final List<LessonResource> resources;
  final List<QuizQuestion>? quiz;

  TrainingLesson({
    required this.id,
    required this.moduleId,
    required this.title,
    this.description,
    required this.lessonIndex,
    required this.contentType,
    this.contentUrl,
    required this.durationMinutes,
    required this.isPreview,
    this.resources = const [],
    this.quiz,
  });

  factory TrainingLesson.fromJson(Map<String, dynamic> json) {
    return TrainingLesson(
      id: json['id'] as String,
      moduleId: json['module_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      lessonIndex: json['lesson_index'] as int,
      contentType: json['content_type'] as String,
      contentUrl: json['content_url'] as String?,
      durationMinutes: json['duration_minutes'] as int,
      isPreview: json['is_preview'] as bool,
      resources: [],
      quiz: null,
    );
  }
}

// models/quiz_question.dart
class QuizQuestion {
  final String id;
  final String lessonId;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.lessonId,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctOptionIndex: json['correct_option_index'] as int,
      explanation: json['explanation'] as String?,
    );
  }
}

// models/lesson_resource.dart
class LessonResource {
  final String id;
  final String lessonId;
  final String title;
  final String type; // pdf, doc, image, link
  final String url;
  final int fileSize;

  LessonResource({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.type,
    required this.url,
    required this.fileSize,
  });
}
