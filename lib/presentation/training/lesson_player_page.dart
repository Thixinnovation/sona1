import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../services/training_service.dart';

class LessonPlayerPage extends StatefulWidget {
  final String enrollmentId;
  const LessonPlayerPage({super.key, required this.enrollmentId});

  @override
  State<LessonPlayerPage> createState() => _LessonPlayerPageState();
}

class _LessonPlayerPageState extends State<LessonPlayerPage> {
  late TrainingService _service;
  Map<String, dynamic>? _enrollment;
  List<Map<String, dynamic>> _lessons = [];
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = TrainingService(Supabase.instance.client);
    _loadData();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _enrollment = await _service.fetchEnrollmentById(widget.enrollmentId);
      if (_enrollment != null) {
        final trainingId = _enrollment!['training_id'];
        _lessons = await _service.getAllLessonsByTrainingId(trainingId);
        _currentIndex = _lessons.indexWhere((l) => l['id'] == _enrollment!['current_lesson_id']);
        if (_currentIndex == -1) _currentIndex = 0;
        _loadLesson(_currentIndex);
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _loadLesson(int index) {
    if (_videoController != null) {
      _videoController!.dispose();
    }
    
    final lesson = _lessons[index];
    setState(() => _videoInitialized = false);
    
    if (lesson['content_url'] != null && lesson['content_type'] == 'video') {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(lesson['content_url']));
      _videoController!.initialize().then((_) {
        if (mounted) {
          setState(() => _videoInitialized = true);
          _videoController!.play();
        }
      });
    }
  }

  Future<void> _saveProgress() async {
    final progressPercent = ((_currentIndex + 1) / _lessons.length * 100).toInt();
    await _service.saveProgress(
      widget.enrollmentId,
      _lessons[_currentIndex]['id'],
      progressPercent,
    );
  }

  void _nextLesson() {
    if (_currentIndex + 1 < _lessons.length) {
      setState(() {
        _currentIndex++;
        _loadLesson(_currentIndex);
      });
      _saveProgress();
    }
  }

  void _previousLesson() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _loadLesson(_currentIndex);
      });
      _saveProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_lessons.isEmpty) {
      return const Scaffold(body: Center(child: Text('Aucune leçon')));
    }
    
    final currentLesson = _lessons[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentLesson['title'] ?? 'Leçon'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveProgress,
            child: const Text('Sauvegarder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Vidéo
          Expanded(
            flex: 3,
            child: currentLesson['content_type'] == 'video' && _videoController != null
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_videoController!),
                      if (!_videoInitialized)
                        const CircularProgressIndicator(),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: VideoProgressIndicator(_videoController!, allowScrubbing: true),
                      ),
                    ],
                  )
                : const Center(child: Text('Contenu non disponible')),
          ),
          // Description et navigation
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentLesson['title'] ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentLesson['description'] ?? 'Aucune description',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (_currentIndex + 1) / _lessons.length,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leçon ${_currentIndex + 1} sur ${_lessons.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _currentIndex > 0 ? _previousLesson : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Précédent'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _currentIndex + 1 < _lessons.length ? _nextLesson : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(_currentIndex + 1 < _lessons.length ? 'Suivant' : 'Terminer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
