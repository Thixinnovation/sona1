import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/services/admin_news_service.dart';
import 'package:thix_id/services/document_service.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:thix_id/theme.dart';

class AdminNewsPage extends StatefulWidget {
  final String role;
  const AdminNewsPage({super.key, required this.role});

  @override
  State<AdminNewsPage> createState() => _AdminNewsPageState();
}

class _AdminNewsPageState extends State<AdminNewsPage> {
  late final AdminNewsService _svc;
  final _docs = DocumentService();
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _news = const [];

  RealtimeChannel? _channel;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _svc = AdminNewsService();
    _search.addListener(_onSearchChanged);
    _load();
    _subscribeRealtime();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 160), () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _svc.listNews();
      if (!mounted) return;
      setState(() {
        _news = list;
      });
    } catch (e) {
      debugPrint('AdminNewsPage: load failed err=$e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeRealtime() {
    try {
      _channel = SupabaseConfig.client.channel('admin:news');
      (_channel as dynamic)
          .on(
            'postgres_changes',
            {
              'event': '*',
              'schema': 'public',
              'table': AdminNewsService.table,
            },
            (_) => unawaited(_load()),
          )
          .subscribe((status, [error]) {
            debugPrint('AdminNewsPage realtime: status=$status, error=$error');
          });
    } catch (e) {
      debugPrint('AdminNewsPage: realtime subscribe failed: $e');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    try {
      if (_channel != null) SupabaseConfig.client.removeChannel(_channel!);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _news
        : _news.where((e) {
            final title = (e['title'] ?? '').toString().toLowerCase();
            final category = (e['category'] ?? '').toString().toLowerCase();
            final source = (e['source'] ?? '').toString().toLowerCase();
            return title.contains(q) || category.contains(q) || source.contains(q);
          }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THIX INFO', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AdminCyberColors.text)),
                  const SizedBox(height: 4),
                  Text('Gérer les actualités institutionnelles • ${filtered.length} article(s)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminCyberColors.textDim)),
                ],
              ),
            ),
            SizedBox(
              width: 340,
              child: TextField(
                controller: _search,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminCyberColors.text),
                decoration: InputDecoration(
                  hintText: 'Rechercher titre, catégorie...',
                  hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminCyberColors.textDim),
                  prefixIcon: const Icon(Icons.search_rounded, color: AdminCyberColors.neonCyan),
                  filled: true,
                  fillColor: AdminCyberColors.panel.withValues(alpha: 0.72),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AdminCyberColors.stroke.withValues(alpha: 0.9))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AdminCyberColors.electricBlue, width: 1.2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AdminCyberColors.stroke.withValues(alpha: 0.9)),
                foregroundColor: AdminCyberColors.text,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded, color: AdminCyberColors.neonCyan),
              label: const Text('Actualiser'),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AdminCyberColors.electricBlue, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () => _openEditor(context, null),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Nouvel article', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : (_error != null)
                  ? _ErrorState(error: _error!, onRetry: _load)
                  : (filtered.isEmpty)
                      ? Center(child: Text('Aucun article.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminCyberColors.textDim)))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _NewsTile(
                            row: filtered[i],
                            documents: _docs,
                            onEdit: () => _openEditor(context, filtered[i]),
                            onDelete: () => _delete(context, filtered[i]),
                          ),
                        ),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, Map<String, dynamic> row) async {
    final id = (row['id'] ?? '').toString();
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminCyberColors.panel,
        title: Text('Supprimer', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AdminCyberColors.text)),
        content: Text('Supprimer cet article ?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminCyberColors.textDim)),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => context.pop(true), style: ElevatedButton.styleFrom(backgroundColor: AdminCyberColors.danger, elevation: 0), child: const Text('Supprimer', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.deleteNews(id: id);
      unawaited(_load());
    } catch (e) {
      debugPrint('AdminNewsPage: delete failed err=$e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression: $e')));
    }
  }

  Future<void> _openEditor(BuildContext context, Map<String, dynamic>? row) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewsEditor(initial: row, service: _svc),
    );
    if (saved == true) unawaited(_load());
  }
}

// ============================================================================
// News Tile
// ============================================================================

class _NewsTile extends StatelessWidget {
  final Map<String, dynamic> row;
  final DocumentService documents;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NewsTile({required this.row, required this.documents, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final title = (row['title'] ?? '—').toString();
    final category = (row['category'] ?? '—').toString();
    final source = (row['source'] ?? '—').toString();
    final status = (row['status'] ?? 'published').toString();
    final severity = (row['severity'] ?? '').toString();
    final isFeatured = (row['is_featured'] == true) || (row['is_featured']?.toString() == 'true');
    final coverBucket = (row['cover_image_bucket'] ?? AdminNewsService.coverBucketDefault).toString();
    final coverPath = (row['cover_image_path'] ?? '').toString();
    final createdAt = (row['created_at'] ?? '').toString();

    final borderColor = isFeatured ? Colors.amber : AdminCyberColors.stroke.withValues(alpha: 0.9);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AdminCyberColors.panel.withValues(alpha: 0.78),
        border: Border.all(color: borderColor, width: isFeatured ? 1.4 : 1),
      ),
      child: Row(
        children: [
          _NewsCoverThumb(bucket: coverBucket, storagePath: coverPath, documents: documents, isFeatured: isFeatured),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AdminCyberColors.text))),
                    if (isFeatured) const SizedBox(width: 8),
                    if (isFeatured) const _TagBadge(label: 'À la une', icon: Icons.stars_rounded, color: Colors.amber),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$category • $source • $createdAt',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminCyberColors.textDim),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _Chip(icon: Icons.article_rounded, label: status, color: status == 'published' ? AdminCyberColors.success : AdminCyberColors.textDim),
                    if (severity.isNotEmpty) _Chip(icon: Icons.warning_rounded, label: severity, color: AdminCyberColors.danger),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(tooltip: 'Modifier', onPressed: onEdit, icon: const Icon(Icons.edit_rounded, color: AdminCyberColors.neonCyan)),
          IconButton(tooltip: 'Supprimer', onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: AdminCyberColors.danger)),
        ],
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _TagBadge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _NewsCoverThumb extends StatefulWidget {
  final String bucket;
  final String storagePath;
  final DocumentService documents;
  final bool isFeatured;
  const _NewsCoverThumb({required this.bucket, required this.storagePath, required this.documents, required this.isFeatured});

  @override
  State<_NewsCoverThumb> createState() => _NewsCoverThumbState();
}

class _NewsCoverThumbState extends State<_NewsCoverThumb> {
  String? _url;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _NewsCoverThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath || oldWidget.bucket != widget.bucket) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final p = widget.storagePath.trim();
    if (p.isEmpty) {
      if (mounted) setState(() => _url = null);
      return;
    }
    if (p.startsWith('http://') || p.startsWith('https://')) {
      if (mounted) setState(() => _url = p);
      return;
    }
    try {
      final url = await widget.documents.createDownloadUrl(storagePath: p, bucketName: widget.bucket.trim().isEmpty ? AdminNewsService.coverBucketDefault : widget.bucket);
      if (!mounted) return;
      setState(() => _url = url);
    } catch (e) {
      debugPrint('_NewsCoverThumb resolve failed bucket=${widget.bucket} path=${widget.storagePath} err=$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.isFeatured ? Colors.amber : AdminCyberColors.stroke.withValues(alpha: 0.9);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.2),
        color: AdminCyberColors.black.withValues(alpha: 0.18),
      ),
      clipBehavior: Clip.antiAlias,
      child: _url == null
          ? Container(
              decoration: BoxDecoration(gradient: AdminCyberGradients.glowViolet()),
              child: const Icon(Icons.newspaper_rounded, color: Colors.white, size: 20),
            )
          : Image.network(
              _url!,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(gradient: AdminCyberGradients.glowViolet()),
                child: const Icon(Icons.broken_image_rounded, color: Colors.white, size: 20),
              ),
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _Chip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AdminCyberColors.textDim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: AdminCyberColors.black.withValues(alpha: 0.22), border: Border.all(color: AdminCyberColors.stroke.withValues(alpha: 0.7))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c)),
        ],
      ),
    );
  }
}

// ============================================================================
// News Editor
// ============================================================================

class _NewsEditor extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final AdminNewsService service;
  const _NewsEditor({required this.initial, required this.service});

  @override
  State<_NewsEditor> createState() => _NewsEditorState();
}

class _NewsEditorState extends State<_NewsEditor> {
  final _docs = DocumentService();

  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _category;
  late final TextEditingController _source;
  late final TextEditingController _severity;
  late final TextEditingController _content;

  bool _featured = false;
  bool _published = true;
  String _status = 'published';

  PlatformFile? _pickedCover;
  String? _coverBucket;
  String? _coverPath;
  String? _coverResolvedUrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: (widget.initial?['title'] ?? '').toString());
    _subtitle = TextEditingController(text: (widget.initial?['subtitle'] ?? '').toString());
    _category = TextEditingController(text: (widget.initial?['category'] ?? 'Actualités').toString());
    _source = TextEditingController(text: (widget.initial?['source'] ?? 'THIX').toString());
    _severity = TextEditingController(text: (widget.initial?['severity'] ?? 'Info').toString());
    _content = TextEditingController(text: (widget.initial?['content'] ?? '').toString());

    _featured = (widget.initial?['is_featured'] == true) || (widget.initial?['is_featured']?.toString() == 'true');
    _status = (widget.initial?['status'] ?? 'published').toString();
    _published = _status == 'published';

    _coverBucket = (widget.initial?['cover_image_bucket'] ?? AdminNewsService.coverBucketDefault).toString();
    _coverPath = (widget.initial?['cover_image_path'] ?? '').toString().trim().isEmpty ? null : (widget.initial?['cover_image_path'] ?? '').toString();

    unawaited(_resolveCoverUrl());
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _category.dispose();
    _source.dispose();
    _severity.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _resolveCoverUrl() async {
    final bucket = (_coverBucket ?? AdminNewsService.coverBucketDefault).trim();
    final path = (_coverPath ?? '').trim();
    if (path.isEmpty) {
      if (mounted) setState(() => _coverResolvedUrl = null);
      return;
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      if (mounted) setState(() => _coverResolvedUrl = path);
      return;
    }
    try {
      final url = await _docs.createDownloadUrl(storagePath: path, bucketName: bucket);
      if (!mounted) return;
      setState(() => _coverResolvedUrl = url);
    } catch (e) {
      debugPrint('_NewsEditor resolve cover failed bucket=$bucket path=$path err=$e');
    }
  }

  Future<void> _pickCover() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
        withData: true,
        allowMultiple: false,
      );
      if (res == null || res.files.isEmpty) return;
      setState(() {
        _pickedCover = res.files.first;
      });
    } catch (e) {
      debugPrint('AdminNewsPage: cover pick failed err=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur sélection image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final maxW = MediaQuery.sizeOf(context).width < 720 ? double.infinity : 720.0;
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.viewInsetsOf(context).bottom),
            decoration: BoxDecoration(color: AdminCyberColors.panelHi, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AdminCyberColors.stroke.withValues(alpha: 0.9))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(isEdit ? 'Modifier l\'article' : 'Nouvel article', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AdminCyberColors.text, fontWeight: FontWeight.w900))),
                    IconButton(onPressed: () => context.pop(false), icon: const Icon(Icons.close_rounded, color: AdminCyberColors.textDim)),
                  ],
                ),
                const SizedBox(height: 12),
                _CoverField(
                  resolvedUrl: _coverResolvedUrl,
                  pickedFile: _pickedCover,
                  onPick: _saving ? null : _pickCover,
                ),
                const SizedBox(height: 12),

                _TwoCol(
                  wide: wide,
                  left: _Field(label: 'Titre', controller: _title, icon: Icons.title_rounded),
                  right: _Field(label: 'Sous-titre', controller: _subtitle, icon: Icons.subtitles_rounded),
                ),
                const SizedBox(height: 10),

                _TwoCol(
                  wide: wide,
                  left: _Field(label: 'Catégorie', controller: _category, icon: Icons.category_rounded),
                  right: _Field(label: 'Source', controller: _source, icon: Icons.source_rounded),
                ),
                const SizedBox(height: 10),

                _TwoCol(
                  wide: wide,
                  left: _Field(label: 'Sévérité', controller: _severity, icon: Icons.warning_rounded),
                  right: _SwitchField(label: 'À la une', icon: Icons.stars_rounded, value: _featured, onChanged: _saving ? null : (v) => setState(() => _featured = v)),
                ),
                const SizedBox(height: 10),

                _SwitchField(label: 'Publié', icon: Icons.visibility_rounded, value: _published, onChanged: _saving ? null : (v) => setState(() => _published = v)),
                const SizedBox(height: 10),

                _MultilineField(label: 'Contenu', controller: _content, icon: Icons.description_rounded, minLines: 5),
                const SizedBox(height: 14),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AdminCyberColors.electricBlue, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: _saving ? null : _save,
                  icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded, color: Colors.white),
                  label: Text(_saving ? 'Sauvegarde…' : (isEdit ? 'Enregistrer' : 'Publier'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Titre requis.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final newsId = await widget.service.upsertNews(
        id: (widget.initial?['id'] ?? '').toString().trim().isEmpty ? null : (widget.initial?['id'] ?? '').toString().trim(),
        title: title,
        subtitle: _subtitle.text,
        category: _category.text,
        source: _source.text,
        severity: _severity.text,
        content: _content.text,
        isFeatured: _featured,
        status: _published ? 'published' : 'draft',
      );

      final picked = _pickedCover;
      if (picked != null) {
        final uid = SupabaseConfig.client.auth.currentUser?.id ?? 'admin';
        final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
        final safeName = picked.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final objectPath = 'news/$newsId/cover_${ts}_$safeName';
        final bucket = AdminNewsService.coverBucketDefault;
        final uploadedPath = await _docs.uploadPickedFileToBucket(bucketName: bucket, uid: uid, objectPath: objectPath, file: picked);
        await widget.service.updateCoverImage(newsId: newsId, bucket: bucket, storagePath: uploadedPath);
      }

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      debugPrint('AdminNewsPage: save failed err=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ============================================================================
// Form Fields
// ============================================================================

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  const _Field({required this.label, required this.controller, required this.icon, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminCyberColors.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminCyberColors.textDim),
        prefixIcon: Icon(icon, color: AdminCyberColors.neonCyan),
        filled: true,
        fillColor: AdminCyberColors.panel.withValues(alpha: 0.72),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AdminCyberColors.stroke.withValues(alpha: 0.9))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AdminCyberColors.electricBlue, width: 1.2)),
      ),
    );
  }
}

class _MultilineField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final int minLines;
  const _MultilineField({required this.label, required this.controller, required this.icon, required this.minLines});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines + 4,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminCyberColors.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminCyberColors.textDim),
        prefixIcon: Icon(icon, color: AdminCyberColors.neonCyan),
        filled: true,
        fillColor: AdminCyberColors.panel.withValues(alpha: 0.72),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AdminCyberColors.stroke.withValues(alpha: 0.9))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AdminCyberColors.electricBlue, width: 1.2)),
        alignLabelWithHint: true,
      ),
    );
  }
}

class _SwitchField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _SwitchField({required this.label, required this.icon, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AdminCyberColors.panel.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminCyberColors.stroke.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AdminCyberColors.neonCyan, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminCyberColors.text, fontWeight: FontWeight.w700))),
          Switch.adaptive(value: value, onChanged: onChanged, activeColor: AdminCyberColors.neonCyan),
        ],
      ),
    );
  }
}

class _TwoCol extends StatelessWidget {
  final bool wide;
  final Widget left;
  final Widget right;
  const _TwoCol({required this.wide, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        children: [
          left,
          const SizedBox(height: 10),
          right,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _CoverField extends StatelessWidget {
  final String? resolvedUrl;
  final PlatformFile? pickedFile;
  final VoidCallback? onPick;
  const _CoverField({required this.resolvedUrl, required this.pickedFile, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final border = AdminCyberColors.stroke.withValues(alpha: 0.9);
    final url = resolvedUrl;
    final picked = pickedFile;

    Widget preview;
    if (picked != null && picked.bytes != null) {
      preview = Image.memory(picked.bytes!, fit: BoxFit.cover);
    } else if (url != null && url.trim().isNotEmpty) {
      preview = Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: AdminCyberColors.textDim));
    } else {
      preview = Container(
        decoration: BoxDecoration(gradient: AdminCyberGradients.glowViolet()),
        child: const Center(child: Icon(Icons.image_rounded, color: Colors.white, size: 28)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminCyberColors.panel.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(width: 88, height: 56, child: preview)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Image de couverture', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AdminCyberColors.text, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(picked?.name ?? 'PNG/JPG/WebP recommandé (thumbnail dans la liste).', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminCyberColors.textDim)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AdminCyberColors.stroke.withValues(alpha: 0.9)),
              foregroundColor: AdminCyberColors.text,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onPick,
            icon: const Icon(Icons.upload_rounded, color: AdminCyberColors.neonCyan),
            label: const Text('Upload'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Error State
// ============================================================================

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AdminCyberColors.stroke.withValues(alpha: 0.9)),
            color: AdminCyberColors.panel.withValues(alpha: 0.78),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Supabase error', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AdminCyberColors.text)),
              const SizedBox(height: 8),
              Text(error, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminCyberColors.textDim, height: 1.4)),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AdminCyberColors.stroke.withValues(alpha: 0.9)),
                  foregroundColor: AdminCyberColors.text,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, color: AdminCyberColors.neonCyan),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
