import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../services/training_service.dart';
import '../../models/training_item.dart';

class TrainingDetailsPage extends StatefulWidget {
  final String trainingId;
  const TrainingDetailsPage({super.key, required this.trainingId});

  @override
  State<TrainingDetailsPage> createState() => _TrainingDetailsPageState();
}

class _TrainingDetailsPageState extends State<TrainingDetailsPage> {
  late TrainingService _service;
  TrainingItem? _course;
  List<Map<String, dynamic>> _modules = [];
  Map<String, List<Map<String, dynamic>>> _lessons = {};
  bool _loading = true;
  String? _selectedLessonId;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

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
      _course = await _service.getTrainingById(widget.trainingId);
      if (_course != null) {
        _modules = await _service.getModulesByTrainingId(_course!.id);
        for (final module in _modules) {
          final lessons = await _service.getLessonsByModuleId(module['id']);
          _lessons[module['id']] = lessons;
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _playLesson(Map<String, dynamic> lesson) {
    if (_videoController != null) {
      _videoController!.dispose();
    }
    
    setState(() {
      _selectedLessonId = lesson['id'];
      _videoInitialized = false;
    });
    
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_course == null) {
      return const Scaffold(body: Center(child: Text('Formation introuvable')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_course!.title),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Menu latéral des modules/leçons
          Container(
            width: 320,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: ListView.builder(
              itemCount: _modules.length,
              itemBuilder: (context, moduleIndex) {
                final module = _modules[moduleIndex];
                final lessons = _lessons[module['id']] ?? [];
                return ExpansionTile(
                  title: Text(
                    'Module ${module['module_index']} : ${module['title']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: lessons.map((lesson) {
                    final isSelected = _selectedLessonId == lesson['id'];
                    return ListTile(
                      leading: Icon(
                        lesson['content_type'] == 'video' ? Icons.play_circle_outline : Icons.description_outlined,
                        color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
                      ),
                      title: Text(
                        '${lesson['lesson_index']}. ${lesson['title']}',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF6366F1) : null,
                        ),
                      ),
                      onTap: () => _playLesson(lesson),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          
          // Zone de contenu principal
          Expanded(
            child: _selectedLessonId == null
                ? _buildCourseOverview()
                : _buildLessonContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseOverview() {
    // Récupérer l'URL de couverture depuis les buckets Supabase
    String? coverUrl;
    if (_course!.coverImageBucket != null && _course!.coverImagePath != null) {
      coverUrl = Supabase.instance.client.storage
          .from(_course!.coverImageBucket!)
          .getPublicUrl(_course!.coverImagePath!);
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (coverUrl != null && coverUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                coverUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 16),
          Text(_course!.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_course!.description ?? '', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _buildInfoChip(Icons.school_outlined, _course!.level),
              _buildInfoChip(Icons.category_outlined, _course!.category),
              _buildInfoChip(Icons.access_time_outlined, '${_modules.length} modules'),
              if (_course!.certificationIncluded)
                _buildInfoChip(Icons.verified_outlined, 'Certificat inclus', color: Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          if (!_course!.isFree)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_course!.priceAmount} ${_course!.currency}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                    child: const Text('Acheter', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLessonContent() {
    Map<String, dynamic>? currentLesson;
    
    // Boucle pour trouver la leçon sélectionnée (alternative à firstWhere)
    for (final lessons in _lessons.values) {
      Map<String, dynamic>? found;
      for (final lesson in lessons) {
        if (lesson['id'] == _selectedLessonId) {
          found = lesson;
          break;
        }
      }
      if (found != null) {
        currentLesson = found;
        break;
      }
    }
    
    if (currentLesson == null) {
      return const Center(child: Text('Leçon non trouvée'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(currentLesson['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (currentLesson['description'] != null)
            Text(currentLesson['description'], style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          
          if (currentLesson['content_type'] == 'video' && _videoController != null)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_videoController!),
                  if (!_videoInitialized)
                    const CircularProgressIndicator(),
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: VideoProgressIndicator(_videoController!, allowScrubbing: true),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          Text('Durée: ${currentLesson['duration_minutes']} minutes', style: const TextStyle(color: Colors.grey)),
          
          const SizedBox(height: 24),
          // Quiz si disponible
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _service.getQuizByLessonId(currentLesson['id']),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
              final questions = snapshot.data!;
              return _buildQuizSection(questions);
            },
          ),
          
          const SizedBox(height: 24),
          // Ressources si disponibles
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _service.getResourcesByLessonId(currentLesson['id']),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
              final resources = snapshot.data!;
              return _buildResourcesSection(resources);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuizSection(List<Map<String, dynamic>> questions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📝 Quiz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('${questions.length} question(s) pour valider vos connaissances'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter le quiz
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quiz en cours de développement')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('Commencer le quiz', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesSection(List<Map<String, dynamic>> resources) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📎 Ressources', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...resources.map((resource) => ListTile(
            leading: Icon(_getResourceIcon(resource['type']), color: const Color(0xFF6366F1)),
            title: Text(resource['title'] ?? 'Ressource'),
            trailing: const Icon(Icons.download, color: Color(0xFF6366F1)),
            onTap: () {
              // TODO: Télécharger la ressource
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Téléchargement en cours de développement')),
              );
            },
          )),
        ],
      ),
    );
  }

  IconData _getResourceIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': case 'docx': return Icons.description;
      case 'jpg': case 'jpeg': case 'png': return Icons.image;
      default: return Icons.attachment;
    }
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
