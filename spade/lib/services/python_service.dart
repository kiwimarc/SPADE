import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class _PythonCommandResult {
  _PythonCommandResult({
    required this.exitCode,
    required this.stdoutText,
    required this.stderrText,
  });

  final int exitCode;
  final String stdoutText;
  final String stderrText;
}

class PythonService {
  String? _executablePath;

  Future<void> init() async {
    final appDir = await getApplicationSupportDirectory();
    final pythonDir = Directory(path.join(appDir.path, 'python_dist'));
    _executablePath = path.join(pythonDir.path, 'python.exe');
    final checksumFile = File(path.join(pythonDir.path, '.dist_checksum'));

    final data = await rootBundle.load('assets/python_dist.zip');
    final bytes = data.buffer.asUint8List();
    final currentChecksum = sha256.convert(bytes).toString();

    print('Checking for Python distribution at: ${pythonDir.path}');

    if (await pythonDir.exists()) {
      if (await checksumFile.exists()) {
        final existingChecksum = (await checksumFile.readAsString()).trim();
        if (existingChecksum == currentChecksum) {
          print('Python distribution checksum verified.');
          return;
        }
        print('Python distribution checksum mismatch. Re-extracting...');
      } else {
        print('Python distribution checksum missing. Re-extracting...');
      }

      await pythonDir.delete(recursive: true);
    }

    print('Extracting Python distribution...');
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filename = path.join(pythonDir.path, file.name);
      if (file.isFile) {
        final outFile = File(filename);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filename).create(recursive: true);
      }
    }

    await checksumFile.create(recursive: true);
    await checksumFile.writeAsString(currentChecksum);

    print('Python extracted to: $_executablePath');
  }

  Future<Map<String, dynamic>> loadConfigFromFile(
    String configFilePath, {
    Map<String, dynamic> overrides = const {},
  }) async {
    final rawConfig = await File(configFilePath).readAsString();
    final decoded = jsonDecode(rawConfig);

    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Python config must be a JSON object.');
    }

    return {...decoded, ...overrides};
  }

  Future<void> saveConfigToFile(
    String outputPath,
    Map<String, dynamic> config,
  ) async {
    final configFile = File(outputPath);
    await configFile.create(recursive: true);
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(config),
    );
  }

  Future<String> extractAbfInfo(String abfFilePath) async {
    if (_executablePath == null) {
      await init();
    }

    final pythonDir = File(_executablePath!).parent.path;
    final scriptCandidates = <String>[
      path.join(pythonDir, 'extract_info.py'),
      path.join(pythonDir, 'cli', 'extract_info.py'),
    ];

    final scriptPath = scriptCandidates.firstWhere(
      (candidate) => File(candidate).existsSync(),
      orElse: () => scriptCandidates.first,
    );

    final process = await Process.start(
      _executablePath!,
      [scriptPath, abfFilePath],
      workingDirectory: pythonDir,
    );

    final stdoutText = await process.stdout.transform(const Utf8Decoder(allowMalformed: true)).join();
    final stderrText = await process.stderr.transform(const Utf8Decoder(allowMalformed: true)).join();
    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw Exception(
        'extract_info.py failed with exit code $exitCode: ${stderrText.trim()}',
      );
    }

    return stdoutText.trim();
  }

  Future<String> generateRawPreviewCsv({
    required String abfFilePath,
    required String outputDir,
    required int channel,
    int? sweepNumber,
  }) async {
    final stdoutText = await runViewRawCommand(
      abfFilePath: abfFilePath,
      outputDir: outputDir,
      channel: channel,
      sweepNumber: sweepNumber,
      exportCsv: true,
    );

    final regex = RegExp(r'Raw CSV saved at:\s*(.+)');
    final match = regex.firstMatch(stdoutText);
    if (match == null) {
      throw Exception('Could not determine preview CSV path from Python output.');
    }

    final csvPath = match.group(1)?.trim();
    if (csvPath == null || csvPath.isEmpty) {
      throw Exception('Python reported an empty preview CSV path.');
    }

    return csvPath;
  }

  Future<String> generateRawPreviewPlot({
    required String abfFilePath,
    required String outputDir,
    required int channel,
    List<int>? selectedSweeps,
  }) async {
    final stdoutText = await runViewRawCommand(
      abfFilePath: abfFilePath,
      outputDir: outputDir,
      channel: channel,
      selectedSweeps: selectedSweeps,
    );

    final regex = RegExp(r'Raw plot saved at:\s*(.+)');
    final match = regex.firstMatch(stdoutText);
    if (match == null) {
      throw Exception('Could not determine raw plot path from Python output.');
    }

    final plotPath = match.group(1)?.trim();
    if (plotPath == null || plotPath.isEmpty) {
      throw Exception('Python reported an empty raw plot path.');
    }

    return plotPath;
  }

  Future<String> createDefaultConfigFile(String outputPath) async {
    const defaultConfig = {
      'channel': 0,
      'clamp_channel': 0,
      'membrane_channel': 1,
      'stimuli_channel': 2,
      'export_format': 'png',
      'e_rev': 0,
      'i_rev': -60,
      'start_time': 0.0,
      'end_time': 0.5,
      'selected_sweeps': [],
      'sweep_number': null,
      'filename': null,
    };

    final configFile = File(outputPath);
    await configFile.create(recursive: true);
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(defaultConfig),
    );
    return configFile.path;
  }

  Future<int> runConfiguredAnalysis({
    required Map<String, dynamic> config,
    Map<String, dynamic> overrides = const {},
  }) async {
    final mergedConfig = {
      ...config,
      ...overrides,
    };
    final result = await _runMainCommand(config: mergedConfig, streamLogs: true);
    if (result.exitCode != 0) {
      throw Exception(
        'Python failed with exit code ${result.exitCode}: ${result.stderrText.trim()}',
      );
    }

    print('Python completed successfully.');
    return result.exitCode;
  }

  Future<String> runViewRawCommand({
    required String abfFilePath,
    required String outputDir,
    required int channel,
    int? sweepNumber,
    List<int>? selectedSweeps,
    double? startTime,
    double? endTime,
    bool exportCsv = false,
    String? exportFormat,
  }) async {
    return _runMainCommandWithOutput(
      config: {
        'view_raw': true,
        'export_csv': exportCsv,
        'abf_file': abfFilePath,
        'output_dir': outputDir,
        'channel': channel,
        'sweep_number': sweepNumber,
        'selected_sweeps': selectedSweeps == null || selectedSweeps.isEmpty
            ? null
            : selectedSweeps.join(','),
        'start_time': startTime,
        'end_time': endTime,
        'export_format': exportFormat,
      },
      errorPrefix: 'Raw command',
    );
  }

  Future<String> runExtractPeakCurrentCommand({
    required String abfFilePath,
    int channel = 0,
    int? sweepNumber,
    double? startTime,
    double? endTime,
  }) async {
    return _runMainCommandWithOutput(
      config: {
        'extract_peak_current': true,
        'abf_file': abfFilePath,
        'channel': channel,
        'sweep_number': sweepNumber,
        'start_time': startTime,
        'end_time': endTime,
      },
      errorPrefix: 'Peak current extraction',
    );
  }

  Future<String> runExtractIntegratedCurrentCommand({
    required String abfFilePath,
    int channel = 0,
    int? sweepNumber,
    double? startTime,
    double? endTime,
  }) async {
    return _runMainCommandWithOutput(
      config: {
        'extract_integrated_current': true,
        'abf_file': abfFilePath,
        'channel': channel,
        'sweep_number': sweepNumber,
        'start_time': startTime,
        'end_time': endTime,
      },
      errorPrefix: 'Integrated current extraction',
    );
  }

  Future<String> runExtractCurrentStatsCommand({
    required String abfFilePath,
    int channel = 0,
    int? sweepNumber,
    double? startTime,
    double? endTime,
  }) async {
    return _runMainCommandWithOutput(
      config: {
        'extract_current_stats': true,
        'abf_file': abfFilePath,
        'channel': channel,
        'sweep_number': sweepNumber,
        'start_time': startTime,
        'end_time': endTime,
      },
      errorPrefix: 'Current stats extraction',
    );
  }

  Future<String> runAnalyzeIvCommand({
    required String abfFilePattern,
    required String outputDir,
    int clampChannel = 0,
    int membraneChannel = 1,
    int stimuliChannel = 2,
    double? startTime,
    double? endTime,
    int eRev = 0,
    int iRev = -60,
    bool exportCsv = false,
    String? exportFormat,
  }) async {
    return _runMainCommandWithOutput(
      config: {
        'analyze_iv': true,
        'export_csv': exportCsv,
        'abf_file': abfFilePattern,
        'output_dir': outputDir,
        'clamp_channel': clampChannel,
        'membrane_channel': membraneChannel,
        'stimuli_channel': stimuliChannel,
        'start_time': startTime,
        'end_time': endTime,
        'e_rev': eRev,
        'i_rev': iRev,
        'export_format': exportFormat,
      },
      errorPrefix: 'I-V analysis',
    );
  }

  Future<String> _runMainCommandWithOutput({
    required Map<String, dynamic> config,
    required String errorPrefix,
  }) async {
    final result = await _runMainCommand(config: config);
    if (result.exitCode != 0) {
      throw Exception(
        '$errorPrefix failed with exit code ${result.exitCode}: ${result.stderrText.trim()}',
      );
    }
    return result.stdoutText.trim();
  }

  Future<_PythonCommandResult> _runMainCommand({
    required Map<String, dynamic> config,
    bool streamLogs = false,
  }) async {
    if (_executablePath == null) {
      await init();
    }

    final args = _buildMainScriptArguments(config);
    print('Running Python with args: $args');

    final process = await Process.start(
      _executablePath!,
      args,
      workingDirectory: File(_executablePath!).parent.path,
    );

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    final stdoutDone = Completer<void>();
    final stderrDone = Completer<void>();

    process.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(
          (line) {
            stdoutBuffer.writeln(line);
            if (streamLogs) {
              print('[python] $line');
            }
          },
          onDone: () => stdoutDone.complete(),
        );

    process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(
          (line) {
            stderrBuffer.writeln(line);
            if (streamLogs) {
              print('[python][stderr] $line');
            }
          },
          onDone: () => stderrDone.complete(),
        );

    final exitCode = await process.exitCode;
    await Future.wait([stdoutDone.future, stderrDone.future]);

    return _PythonCommandResult(
      exitCode: exitCode,
      stdoutText: stdoutBuffer.toString(),
      stderrText: stderrBuffer.toString(),
    );
  }

  List<String> _buildMainScriptArguments(Map<String, dynamic> config) {
    final pythonDir = File(_executablePath!).parent.path;
    final scriptPath = path.join(pythonDir, 'main.py');
    return <String>[scriptPath, ..._buildArguments(config)];
  }

  List<String> _buildArguments(Map<String, dynamic> config) {
    final args = <String>[];
    const parserFlags = <String>{
      'abf_file',
      'output_dir',
      'export_csv',
      'view_raw',
      'extract_peak_current',
      'extract_integrated_current',
      'extract_current_stats',
      'analyze_iv',
    };

    for (final entry in config.entries) {
      final key = entry.key;
      final value = entry.value;

      if (_isNullOrEmpty(value)) {
        continue;
      }

      if (value is bool) {
        if (value) {
          args.add('--$key');
        }
        continue;
      }

      if (parserFlags.contains(key)) {
        args.add('--$key');
        args.add(value.toString());
        continue;
      }

      args.add('$key=${value.toString()}');
    }

    return args;
  }

  bool _isNullOrEmpty(dynamic value) {
    if (value == null) {
      return true;
    }
    if (value is String) {
      return value.trim().isEmpty;
    }
    if (value is Iterable) {
      return value.isEmpty;
    }
    if (value is Map) {
      return value.isEmpty;
    }
    return false;
  }
}