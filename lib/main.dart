import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 117, 186, 235)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 117, 186, 235),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MyHomePage(
        title: 'Serializer',
        onThemeToggle: () {
          setState(() {
            _isDarkMode = !_isDarkMode;
          });
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.onThemeToggle,
  });

  final String title;
  final VoidCallback onThemeToggle;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TextEditingController _controller;
  String _indexerOption = '_';
  String _fileOp = 'fop1';
  List<String> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title, textAlign: TextAlign.center),
        actions: [
          IconButton(
            icon: Theme.of(context).brightness == Brightness.dark
                ? const Icon(Icons.light_mode)
                : const Icon(Icons.dark_mode),
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter the string for serialization',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 8,
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select the file indexer for serialization:'),
                        RadioListTile<String>(
                          title: const Text('Underscore (_)'),
                          value: '_',
                          groupValue: _indexerOption,
                          onChanged: (value) {
                            setState(() {
                              _indexerOption = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Dash (-)'),
                          value: '-',
                          groupValue: _indexerOption,
                          onChanged: (value) {
                            setState(() {
                              _indexerOption = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Space ( )'),
                          value: ' ',
                          groupValue: _indexerOption,
                          onChanged: (value) {
                            setState(() {
                              _indexerOption = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Card(
                elevation: 8,
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select the method of file operation :'),
                        const SizedBox(height: 8.0),
                        RadioListTile<String>(
                          title: const Text('Select File in order'),
                          value: 'fop1',
                          groupValue: _fileOp,
                          onChanged: (value) {
                            setState(() {
                              _fileOp = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Select Directory'),
                          value: 'fop2',
                          groupValue: _fileOp,
                          onChanged: (value) {
                            setState(() {
                              _fileOp = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Card(
                elevation: 8,
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('File Operations :'),
                        const SizedBox(height: 8.0),
                        ElevatedButton(
                          onPressed: () async {
                            if (_fileOp == 'fop1') {
                              final XTypeGroup typeGroup = XTypeGroup(
                                label: 'files',
                              );
                              final List<XFile> files = await openFiles(
                                acceptedTypeGroups: <XTypeGroup>[typeGroup],
                              );
                              if (files.isNotEmpty) {
                                setState(() {
                                  _selectedFiles.addAll(files.map((f) => f.path));
                                });
                              }
                            } else {
                              final String? directoryPath = await getDirectoryPath();
                              if (directoryPath != null) {
                                setState(() {
                                  _selectedFiles.add(directoryPath);
                                });
                              }
                            }
                          },
                          child: const Text('Select'),
                        ),
                        const SizedBox(height: 12.0),
                        if (_selectedFiles.isNotEmpty)
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                _selectedFiles.join('\n'),
                                style: const TextStyle(fontSize: 12.0),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Center(
            child: ElevatedButton(
              onPressed: _selectedFiles.isEmpty
                  ? null
                  : () async {
                      try {
                        final response = await http.post(
                          Uri.parse('http://localhost:5000/serialize'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'files': _selectedFiles,
                            'indexer': _indexerOption,
                            'operation': _fileOp,
                          }),
                        ).timeout(const Duration(seconds: 10));

                        if (response.statusCode == 200) {
                          final result = jsonDecode(response.body);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Serialization complete: ${result['results'].length} items processed'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error: Backend returned an error'),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: Unable to connect to backend - $e'),
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Serialize'),
              
            ),
          ),
        ],
      ),
    );
  }
}
