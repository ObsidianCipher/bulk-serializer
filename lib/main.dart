import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String _kDefaultBackendUrl = 'http://localhost:5000/serialize';
const String _kDefaultPrefix = 'serial';
const String _kDefaultIndexer = '_';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF151E2D).withAlpha(220), const Color(0xFF101827).withAlpha(190)]
              : [Colors.white.withAlpha(210), const Color(0xFFF3F6FF).withAlpha(200)],
        ),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(18) : Colors.blue.withAlpha(30),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF4F7CF7)).withAlpha(28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class AnimatedGlassButton extends StatefulWidget {
  const AnimatedGlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.primary = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool primary;

  @override
  State<AnimatedGlassButton> createState() => _AnimatedGlassButtonState();
}

class _AnimatedGlassButtonState extends State<AnimatedGlassButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: widget.primary
                  ? const [Color(0xFF4F7CF7), Color(0xFF6E8DFF)]
                  : (isDark
                      ? [const Color(0xFF1B2230), const Color(0xFF1B2230)]
                      : [const Color(0xFFFFFFFF), const Color(0xFFEAF1FF)]),
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.primary ? const Color(0xFF4F7CF7) : Colors.black).withAlpha(22),
                blurRadius: _hovered ? 16 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.backendUrl,
    required this.defaultPrefix,
    required this.defaultIndexer,
  });

  final String backendUrl;
  final String defaultPrefix;
  final String defaultIndexer;

  AppSettings copyWith({
    String? backendUrl,
    String? defaultPrefix,
    String? defaultIndexer,
  }) {
    return AppSettings(
      backendUrl: backendUrl ?? this.backendUrl,
      defaultPrefix: defaultPrefix ?? this.defaultPrefix,
      defaultIndexer: defaultIndexer ?? this.defaultIndexer,
    );
  }
}

class BatchItemOutcome {
  const BatchItemOutcome({
    required this.path,
    required this.status,
    required this.summary,
    this.newName,
    this.message,
    this.index,
  });

  final String path;
  final String status;
  final String summary;
  final String? newName;
  final String? message;
  final int? index;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'path': path,
        'status': status,
        'summary': summary,
        'new_name': newName,
        'message': message,
        'index': index,
      };

  factory BatchItemOutcome.fromJson(Map<String, dynamic> json) {
    final rawPath = json['path'];
    final rawStatus = json['status'];
    return BatchItemOutcome(
      path: rawPath?.toString() ?? 'unknown',
      status: rawStatus?.toString() ?? 'error',
      summary: json['summary']?.toString() ?? 'No detail available.',
      newName: json['new_name']?.toString(),
      message: json['message']?.toString(),
      index: json['index'] is int ? json['index'] as int : null,
    );
  }
}

class BatchResult {
  const BatchResult({
    required this.id,
    required this.createdAt,
    required this.success,
    required this.title,
    required this.summary,
    required this.logs,
    required this.selectedPaths,
    required this.itemsProcessed,
    required this.totalItems,
    this.itemResults = const <BatchItemOutcome>[],
  });

  final String id;
  final DateTime createdAt;
  final bool success;
  final String title;
  final String summary;
  final List<String> logs;
  final List<String> selectedPaths;
  final int itemsProcessed;
  final int totalItems;
  final List<BatchItemOutcome> itemResults;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'success': success,
        'title': title,
        'summary': summary,
        'logs': logs,
        'selectedPaths': selectedPaths,
        'itemsProcessed': itemsProcessed,
        'totalItems': totalItems,
        'itemResults': itemResults.map((item) => item.toJson()).toList(),
      };

  factory BatchResult.fromJson(Map<String, dynamic> json) {
    final rawLogs = json['logs'];
    final rawSelectedPaths = json['selectedPaths'];
    final rawResults = json['itemResults'];

    return BatchResult(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      success: json['success'] == true,
      title: json['title']?.toString() ?? 'Imported batch',
      summary: json['summary']?.toString() ?? 'Imported result',
      logs: rawLogs is List ? rawLogs.map((entry) => entry.toString()).toList() : <String>[],
      selectedPaths: rawSelectedPaths is List
          ? rawSelectedPaths.map((entry) => entry.toString()).toList()
          : <String>[],
      itemsProcessed: json['itemsProcessed'] is int ? json['itemsProcessed'] as int : 0,
      totalItems: json['totalItems'] is int ? json['totalItems'] as int : 0,
      itemResults: rawResults is List
          ? rawResults
              .whereType<Map>()
              .map((entry) => BatchItemOutcome.fromJson(Map<String, dynamic>.from(entry)))
              .toList()
          : <BatchItemOutcome>[],
    );
  }
}

void main() {
  runApp(const SerializerApp());
}

class SerializerApp extends StatefulWidget {
  const SerializerApp({super.key});

  @override
  State<SerializerApp> createState() => _SerializerAppState();
}

class _SerializerAppState extends State<SerializerApp> {
  bool _isDarkMode = false;
  AppSettings _settings = const AppSettings(
    backendUrl: _kDefaultBackendUrl,
    defaultPrefix: _kDefaultPrefix,
    defaultIndexer: _kDefaultIndexer,
  );
  List<BatchResult> _history = <BatchResult>[];

  void _handleSettingsChanged(AppSettings settings) {
    setState(() {
      _settings = settings;
    });
  }

  void _handleBatchComplete(BatchResult result) {
    setState(() {
      _history = <BatchResult>[result, ..._history];
    });
  }

  void _handleHistoryChanged(List<BatchResult> nextHistory) {
    setState(() {
      _history = nextHistory;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F7CF7),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7AA2FF),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Serializer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F7FF),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F9FF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF4F7CF7), width: 1.4),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: const Color(0xFF0C1220),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF121A2B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF161F2F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF8AA8FF), width: 1.4),
          ),
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: SerializerHomePage(
        title: 'Serializer',
        settings: _settings,
        history: _history,
        onThemeToggle: () {
          setState(() {
            _isDarkMode = !_isDarkMode;
          });
        },
        onSettingsChanged: _handleSettingsChanged,
        onBatchComplete: _handleBatchComplete,
        onHistoryChanged: _handleHistoryChanged,
      ),
    );
  }
}

class SerializerHomePage extends StatefulWidget {
  const SerializerHomePage({
    super.key,
    required this.title,
    required this.settings,
    required this.history,
    required this.onThemeToggle,
    required this.onSettingsChanged,
    required this.onBatchComplete,
    required this.onHistoryChanged,
  });

  final String title;
  final AppSettings settings;
  final List<BatchResult> history;
  final VoidCallback onThemeToggle;
  final ValueChanged<AppSettings> onSettingsChanged;
  final ValueChanged<BatchResult> onBatchComplete;
  final ValueChanged<List<BatchResult>> onHistoryChanged;

  @override
  State<SerializerHomePage> createState() => _SerializerHomePageState();
}

class _SerializerHomePageState extends State<SerializerHomePage> {
  late final TextEditingController _prefixController;
  String _indexerOption = _kDefaultIndexer;
  String _fileOp = 'fop1';
  List<String> _selectedPaths = <String>[];
  bool _isSubmitting = false;
  double _progressValue = 0.0;
  String _progressLabel = 'Idle';
  List<String> _logs = <String>[];

  @override
  void initState() {
    super.initState();
    _prefixController = TextEditingController(text: widget.settings.defaultPrefix);
    _indexerOption = widget.settings.defaultIndexer;
  }

  @override
  void didUpdateWidget(covariant SerializerHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _prefixController.text = widget.settings.defaultPrefix;
      _indexerOption = widget.settings.defaultIndexer;
    }
  }

  @override
  void dispose() {
    _prefixController.dispose();
    super.dispose();
  }

  String get _normalizedPrefix =>
      _prefixController.text.trim().isEmpty ? _kDefaultPrefix : _prefixController.text.trim();

  Future<void> _openSettings() async {
    final updated = await Navigator.push<AppSettings>(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(settings: widget.settings),
      ),
    );

    if (updated != null && mounted) {
      widget.onSettingsChanged(updated);
    }
  }

  Future<void> _openHistory() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsHistoryScreen(
          history: widget.history,
          onHistoryChanged: widget.onHistoryChanged,
        ),
      ),
    );
  }

  List<BatchItemOutcome> _summarizeItemResults(dynamic rawResults) {
    final items = rawResults is List ? rawResults : <dynamic>[];
    final details = <BatchItemOutcome>[];

    for (final item in items) {
      if (item is! Map) {
        continue;
      }

      final map = Map<String, dynamic>.from(item);
      final pathValue = map['path'];
      final path = pathValue?.toString() ?? 'unknown';
      final status = map['status']?.toString() ?? 'error';
      final detailSummary = map['message']?.toString() ?? 'Processed successfully';
      final newName = map['new_name']?.toString() ?? map['newName']?.toString();
      final index = map['index'] is int ? map['index'] as int : null;

      if (status == 'success' && map['renamed_files'] is List) {
        final renamedFiles = map['renamed_files'] as List<dynamic>;
        for (final renamed in renamedFiles) {
          if (renamed is! Map) {
            continue;
          }
          final renamedMap = Map<String, dynamic>.from(renamed);
          final oldName = renamedMap['old_name']?.toString() ?? 'unknown';
          final renamedName = renamedMap['new_name']?.toString() ?? 'unknown';
          details.add(
            BatchItemOutcome(
              path: '$path/$oldName',
              status: 'success',
              summary: 'Renamed to $renamedName',
              newName: renamedName,
              index: renamedMap['index'] is int ? renamedMap['index'] as int : null,
            ),
          );
        }
        continue;
      }

      details.add(
        BatchItemOutcome(
          path: path,
          status: status,
          summary: status == 'success'
              ? (newName == null ? 'Processed successfully' : 'Renamed to $newName')
              : detailSummary,
          newName: newName,
          message: map['message']?.toString(),
          index: index,
        ),
      );
    }

    return details;
  }

  void _appendLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toLocal().toString().split('.').first}: $message');
    });
  }

  void _addDroppedPaths(List<String> paths) {
    if (paths.isEmpty) {
      return;
    }

    final filtered = paths.where((path) => path.trim().isNotEmpty).toList();
    final cleaned = <String>[];

    for (final path in filtered) {
      final entityType = FileSystemEntity.typeSync(path);
      if (_fileOp == 'fop2' && entityType == FileSystemEntityType.directory) {
        cleaned.add(path);
      } else if (_fileOp == 'fop1' && entityType != FileSystemEntityType.directory) {
        cleaned.add(path);
      } else if (entityType == FileSystemEntityType.notFound) {
        _showMessage('Dropped path is unavailable: $path');
      }
    }

    if (cleaned.isEmpty) {
      _showMessage(
        _fileOp == 'fop2'
            ? 'Drop a folder into this area when directory mode is selected.'
            : 'Drop one or more files into this area when file mode is selected.',
      );
      return;
    }

    final unique = cleaned.toSet().toList();

    setState(() {
      _selectedPaths = <String>{..._selectedPaths, ...unique}.toList()..sort();
    });
    _appendLog('Added ${unique.length} dropped item(s).');
  }

  Future<void> _pickFiles() async {
    final List<XFile> files = await openFiles();
    if (!mounted || files.isEmpty) {
      return;
    }

    final paths = files.map((file) => file.path).whereType<String>().toList();
    _addDroppedPaths(paths);
  }

  Future<void> _pickDirectory() async {
    final String? directory = await getDirectoryPath();
    if (!mounted || directory == null) {
      return;
    }

    setState(() {
      _selectedPaths = {..._selectedPaths, directory}.toList()..sort();
    });
    _appendLog('Selected directory: $directory');
  }

  Future<void> _serialize() async {
    if (_selectedPaths.isEmpty) {
      _showMessage('Select at least one file or directory before serializing.');
      return;
    }

    final requestBody = {
      'files': _selectedPaths,
      'prefix': _normalizedPrefix,
      'indexer': _indexerOption,
      'operation': _fileOp,
    };

    final logs = <String>[
      'Starting batch for ${_selectedPaths.length} item(s).',
      'Backend URL: ${widget.settings.backendUrl}',
      'Payload: ${jsonEncode(requestBody)}',
    ];

    setState(() {
      _isSubmitting = true;
      _progressValue = 0.1;
      _progressLabel = 'Preparing batch';
      _logs = logs;
    });

    try {
      final response = await http
          .post(
            Uri.parse(widget.settings.backendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      setState(() {
        _progressValue = 0.7;
        _progressLabel = 'Awaiting backend response';
      });

      final Map<String, dynamic> decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == 'success') {
        final List<dynamic> results = decoded['results'] as List<dynamic>? ?? <dynamic>[];
        final itemResults = _summarizeItemResults(results);
        final processedCount = itemResults.where((item) => item.status == 'success').length;
        final summary = 'Processed $processedCount item(s) successfully.';
        final newest = BatchResult(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          success: true,
          title: 'Serialization succeeded',
          summary: summary,
          logs: <String>[...logs, 'Backend responded with status 200.', 'Result count: ${results.length}.'],
          selectedPaths: List<String>.from(_selectedPaths),
          itemsProcessed: processedCount,
          totalItems: _selectedPaths.length,
          itemResults: itemResults,
        );

        setState(() {
          _progressValue = 1.0;
          _progressLabel = 'Complete';
          _isSubmitting = false;
        });

        widget.onBatchComplete(newest);
        _showMessage(summary);
        return;
      }

      final String backendError = (decoded['error'] as String?) ?? 'Unknown backend error';
      final failure = BatchResult(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        success: false,
        title: 'Serialization failed',
        summary: 'Request failed: $backendError',
        logs: <String>[...logs, 'Backend responded with status ${response.statusCode}.', 'Error: $backendError'],
        selectedPaths: List<String>.from(_selectedPaths),
        itemsProcessed: 0,
        totalItems: _selectedPaths.length,
        itemResults: const <BatchItemOutcome>[],
      );

      widget.onBatchComplete(failure);
      throw Exception(backendError);
    } catch (error) {
      final failure = BatchResult(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        success: false,
        title: 'Connection problem',
        summary: 'Unable to serialize files: $error',
        logs: <String>[..._logs, 'Exception: $error'],
        selectedPaths: List<String>.from(_selectedPaths),
        itemsProcessed: 0,
        totalItems: _selectedPaths.length,
        itemResults: const <BatchItemOutcome>[],
      );

      widget.onBatchComplete(failure);
      if (!mounted) {
        return;
      }

      setState(() {
        _progressValue = 0.0;
        _progressLabel = 'Failed';
        _isSubmitting = false;
      });
      _showMessage('Unable to serialize files: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Results history',
            onPressed: _openHistory,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: 'Toggle theme',
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF0A1120), Color(0xFF101A2B)]
                : const [Color(0xFFF4F7FF), Color(0xFFEAF1FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1020),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF1D2B41), Color(0xFF152134)]
                              : const [Color(0xFF4F7CF7), Color(0xFF6C8FF8)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F7CF7).withValues(alpha: 0.3),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.2),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Serialize file names with a clean naming pattern',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.history.length} recent batch(es) ready to review',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.82),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Naming setup',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _prefixController,
                            decoration: InputDecoration(
                              labelText: 'Name prefix',
                              hintText: 'e.g. serial, report, batch',
                              prefixIcon: const Icon(Icons.label_important_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isSubmitting || _progressValue > 0)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _progressLabel,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  Text('${(_progressValue * 100).round()}%'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                height: 10,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: theme.colorScheme.surfaceVariant,
                                ),
                                child: FractionallySizedBox(
                                  widthFactor: _progressValue.clamp(0.0, 1.0),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF4F7CF7), Color(0xFF6ED0FF)],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (widget.history.isNotEmpty)
                      GlassCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: _HistoryMetricTile(
                                label: 'Successful',
                                value: widget.history.where((item) => item.success).length.toString(),
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _HistoryMetricTile(
                                label: 'Failed',
                                value: widget.history.where((item) => !item.success).length.toString(),
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _HistoryMetricTile(
                                label: 'Latest',
                                value: widget.history.first.success ? 'OK' : 'ERR',
                                color: widget.history.first.success ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: 320,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              child: GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Index separator',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    RadioListTile<String>(
                                      title: const Text('Underscore (_)'),
                                      value: '_',
                                      groupValue: _indexerOption,
                                      onChanged: (value) => setState(() => _indexerOption = value!),
                                    ),
                                    RadioListTile<String>(
                                      title: const Text('Dash (-)'),
                                      value: '-',
                                      groupValue: _indexerOption,
                                      onChanged: (value) => setState(() => _indexerOption = value!),
                                    ),
                                    RadioListTile<String>(
                                      title: const Text('Space ( )'),
                                      value: ' ',
                                      groupValue: _indexerOption,
                                      onChanged: (value) => setState(() => _indexerOption = value!),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 320,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              child: GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selection mode',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    RadioListTile<String>(
                                      title: const Text('Select files in order'),
                                      value: 'fop1',
                                      groupValue: _fileOp,
                                      onChanged: (value) => setState(() => _fileOp = value!),
                                    ),
                                    RadioListTile<String>(
                                      title: const Text('Select a directory'),
                                      value: 'fop2',
                                      groupValue: _fileOp,
                                      onChanged: (value) => setState(() => _fileOp = value!),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 320,
                          child: DropTarget(
                            onDragDone: (details) {
                              final paths = details.files
                                  .map((file) => file.path)
                                  .whereType<String>()
                                  .toList();
                              _addDroppedPaths(paths);
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.precise,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                child: GlassCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Selected items',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          AnimatedGlassButton(
                                            onPressed: _fileOp == 'fop1' ? _pickFiles : _pickDirectory,
                                            primary: true,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.folder_open, color: Colors.white),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _fileOp == 'fop1' ? 'Add files' : 'Browse folder',
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (_selectedPaths.isNotEmpty)
                                            AnimatedGlassButton(
                                              onPressed: () => setState(() => _selectedPaths.clear()),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.clear),
                                                  SizedBox(width: 8),
                                                  Text('Clear'),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _selectedPaths.isEmpty
                                            ? 'No item selected yet. Drag files here.'
                                            : '${_selectedPaths.length} item(s) selected',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 12),
                                      if (_selectedPaths.isNotEmpty)
                                        Container(
                                          constraints: const BoxConstraints(maxHeight: 220),
                                          child: SingleChildScrollView(
                                            child: SelectableText(
                                              _selectedPaths.join('\n'),
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedGlassButton(
                        onPressed: _isSubmitting || _selectedPaths.isEmpty ? null : _serialize,
                        primary: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSubmitting)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              const Icon(Icons.sync, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _isSubmitting ? 'Processing...' : 'Serialize',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_logs.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Execution log',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ..._logs.map(
                              (log) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  log,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

enum HistoryFilter { all, success, failed }
enum HistorySort { newest, oldest }

class _HistoryMetricTile extends StatelessWidget {
  const _HistoryMetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class ResultsHistoryScreen extends StatefulWidget {
  const ResultsHistoryScreen({
    super.key,
    required this.history,
    required this.onHistoryChanged,
  });

  final List<BatchResult> history;
  final ValueChanged<List<BatchResult>> onHistoryChanged;

  @override
  State<ResultsHistoryScreen> createState() => _ResultsHistoryScreenState();
}

class _ResultsHistoryScreenState extends State<ResultsHistoryScreen> {
  late List<BatchResult> _history;
  HistoryFilter _filter = HistoryFilter.all;
  HistorySort _sort = HistorySort.newest;

  @override
  void initState() {
    super.initState();
    _history = List<BatchResult>.from(widget.history);
  }

  @override
  void didUpdateWidget(covariant ResultsHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.history != widget.history) {
      _history = List<BatchResult>.from(widget.history);
    }
  }

  List<BatchResult> get _visibleHistory {
    final filtered = switch (_filter) {
      HistoryFilter.success => _history.where((item) => item.success).toList(),
      HistoryFilter.failed => _history.where((item) => !item.success).toList(),
      HistoryFilter.all => List<BatchResult>.from(_history),
    };

    filtered.sort((a, b) {
      final comparison = a.createdAt.compareTo(b.createdAt);
      return _sort == HistorySort.newest ? -comparison : comparison;
    });

    return filtered;
  }

  Future<void> _exportHistory() async {
    final location = await getSaveLocation(
      suggestedName: 'serializer_history.json',
      acceptedTypeGroups: <XTypeGroup>[
        const XTypeGroup(label: 'JSON files', extensions: <String>['json']),
      ],
    );

    if (location == null || !mounted) {
      return;
    }

    final file = File(location.path);
    final payload = jsonEncode({
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'history': _history.map((result) => result.toJson()).toList(),
    });

    await file.writeAsString(payload);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('History exported to ${file.path}')),
    );
  }

  Future<void> _importHistory() async {
    final file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[
        const XTypeGroup(label: 'JSON files', extensions: <String>['json']),
      ],
    );

    if (file == null) {
      return;
    }

    try {
      final content = await File(file.path).readAsString();
      final decoded = jsonDecode(content);
      final rawHistory = decoded is Map && decoded['history'] is List ? decoded['history'] as List : <dynamic>[];
      final importedHistory = rawHistory
          .whereType<Map>()
          .map((entry) => BatchResult.fromJson(Map<String, dynamic>.from(entry)))
          .toList();

      if (importedHistory.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No history entries were found in that file.')),
        );
        return;
      }

      setState(() {
        _history = importedHistory;
      });
      widget.onHistoryChanged(importedHistory);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${importedHistory.length} batch result(s).')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to import history: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final visibleHistory = _visibleHistory;
    final successCount = _history.where((item) => item.success).length;
    final failedCount = _history.where((item) => !item.success).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results history'),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: <Widget>[
          TextButton.icon(
            onPressed: _exportHistory,
            icon: const Icon(Icons.upload_file),
            label: const Text('Export history'),
          ),
          TextButton.icon(
            onPressed: _importHistory,
            icon: const Icon(Icons.download),
            label: const Text('Import history'),
          ),
        ],
      ),
      body: _history.isEmpty
          ? const Center(
              child: Text('No batch results yet. Run a serialization job to begin.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Batch summary',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _HistoryMetricTile(
                              label: 'Success',
                              value: successCount.toString(),
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _HistoryMetricTile(
                              label: 'Failed',
                              value: failedCount.toString(),
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _filter == HistoryFilter.all,
                            onSelected: (_) => setState(() => _filter = HistoryFilter.all),
                          ),
                          ChoiceChip(
                            label: const Text('Success'),
                            selected: _filter == HistoryFilter.success,
                            onSelected: (_) => setState(() => _filter = HistoryFilter.success),
                          ),
                          ChoiceChip(
                            label: const Text('Failed'),
                            selected: _filter == HistoryFilter.failed,
                            onSelected: (_) => setState(() => _filter = HistoryFilter.failed),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<HistorySort>(
                        segments: const <ButtonSegment<HistorySort>>[
                          ButtonSegment<HistorySort>(value: HistorySort.newest, label: Text('Newest')),
                          ButtonSegment<HistorySort>(value: HistorySort.oldest, label: Text('Oldest')),
                        ],
                        selected: <HistorySort>{_sort},
                        onSelectionChanged: (selection) {
                          setState(() => _sort = selection.first);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...visibleHistory.map((result) {
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: ListTile(
                          leading: Icon(
                            result.success ? Icons.check_circle : Icons.error,
                            color: result.success ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            result.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${result.createdAt.toLocal().toString().split('.').first} • ${result.itemsProcessed}/${result.totalItems} processed\n${result.summary}',
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const <Widget>[
                              Text('View details'),
                              Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResultDetailScreen(result: result),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class ResultDetailScreen extends StatelessWidget {
  const ResultDetailScreen({
    super.key,
    required this.result,
  });

  final BatchResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result details'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        result.success ? Icons.check_circle : Icons.error,
                        color: result.success ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.title,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(result.summary),
                  const SizedBox(height: 8),
                  Text(
                    '${result.createdAt.toLocal().toString().split('.').first} • ${result.itemsProcessed}/${result.totalItems} processed',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Per-file outcomes',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (result.itemResults.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No per-file details were recorded for this batch.'),
              ),
            )
          else
            ...result.itemResults.map((item) {
              final isSuccessful = item.status == 'success';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    isSuccessful ? Icons.check : Icons.warning_amber_rounded,
                    color: isSuccessful ? Colors.green : Colors.red,
                  ),
                  title: Text(item.path),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 4),
                      Text(item.summary),
                      if (item.message != null && item.message!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(item.message!),
                      ],
                      if (item.newName != null && item.newName!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text('Target name: ${item.newName!}'),
                      ],
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),
          Text(
            'Selected paths',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...result.selectedPaths.map(
            (path) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $path'),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Logs',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...result.logs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(log),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
  });

  final AppSettings settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _backendController;
  late final TextEditingController _prefixController;
  late String _selectedIndexer;

  @override
  void initState() {
    super.initState();
    _backendController = TextEditingController(text: widget.settings.backendUrl);
    _prefixController = TextEditingController(text: widget.settings.defaultPrefix);
    _selectedIndexer = widget.settings.defaultIndexer;
  }

  @override
  void dispose() {
    _backendController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  Future<void> _testBackendConnection() async {
    final String url = _backendController.text.trim();
    if (url.isEmpty) {
      _showMessage('Enter a backend URL first.');
      return;
    }

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (!mounted) {
        return;
      }
      final bool okay = response.statusCode == 200;
      _showMessage(okay ? 'Connection successful.' : 'Server responded with ${response.statusCode}.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Connection failed: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _saveSettings() {
    final nextSettings = AppSettings(
      backendUrl: _backendController.text.trim().isEmpty
          ? _kDefaultBackendUrl
          : _backendController.text.trim(),
      defaultPrefix: _prefixController.text.trim().isEmpty
          ? _kDefaultPrefix
          : _prefixController.text.trim(),
      defaultIndexer: _selectedIndexer,
    );

    Navigator.pop(context, nextSettings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure defaults for the serializer',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _backendController,
                    decoration: const InputDecoration(
                      labelText: 'Backend URL',
                      hintText: 'http://localhost:5000/serialize',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _prefixController,
                    decoration: const InputDecoration(
                      labelText: 'Default name prefix',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Default separator',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<String>(
                    title: const Text('Underscore (_)'),
                    value: '_',
                    groupValue: _selectedIndexer,
                    onChanged: (value) => setState(() => _selectedIndexer = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Dash (-)'),
                    value: '-',
                    groupValue: _selectedIndexer,
                    onChanged: (value) => setState(() => _selectedIndexer = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Space ( )'),
                    value: ' ',
                    groupValue: _selectedIndexer,
                    onChanged: (value) => setState(() => _selectedIndexer = value!),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _testBackendConnection,
                        icon: const Icon(Icons.wifi_tethering),
                        label: const Text('Test backend'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          _backendController.text = _kDefaultBackendUrl;
                          _prefixController.text = _kDefaultPrefix;
                          _selectedIndexer = _kDefaultIndexer;
                        },
                        child: const Text('Reset defaults'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
