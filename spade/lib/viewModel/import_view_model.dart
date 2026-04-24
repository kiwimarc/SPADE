import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../model/backend_model.dart';
import '../shared/backend_status.dart';
import '../services/python_service.dart';

class ImportViewModel extends ChangeNotifier {
  ImportViewModel({
    BackendModel? backendModel,
    PythonService? pythonService,
  })  : _backendModel = backendModel ?? BackendModel(),
        _pythonService = pythonService ?? PythonService();

  final List<String> _selectedFilePaths = [];
  final Map<String, String> _rawInfoByFilePath = {};
  final List<int> _availableChannelIndices = [];
  final List<int> _availableSweepIndices = [];
  final List<String> _selectedSweepTokens = [];
  final List<double> _previewTimesSec = [];
  final List<double> _previewValues = [];
  final Map<int, List<double>> _previewTimesByChannel = {};
  final Map<int, List<double>> _previewValuesByChannel = {};
  final Map<int, String> _rawPlotPathsByChannel = {};
  final List<String> _analysisPlotPaths = [];
  final List<String> _analysisCsvPaths = [];
  bool _rawDataConfigured = false;
  final ValueNotifier<bool> _rawDataConfiguredNotifier = ValueNotifier<bool>(false);
  bool _analysisRunning = false;
  String? _analysisConfigPath;
  String _analysisExportFormat = 'png';
  bool _analysisExportCsv = false;
  String? _analysisOutputDir;
  bool _isLoadingRawInfo = false;
  bool _isLoadingPreviewPlot = false;
  bool _isLoadingRawPlots = false;
  String? _rawInfoError;
  String? _previewError;
  String? _rawPlotError;
  int _clampChannel = 0;
  int _membraneChannel = 1;
  int _stimuliChannel = 2;
  double? _startTimeSec = 0.0;
  double? _endTimeSec = 0.5;
  Color _lineColor = const Color(0xFF00ADB5);
  Color _backgroundColor = const Color(0xFFFFFFFF);
  Color _gridColor = const Color(0xFF222831);
  final ScrollController filesScrollController = ScrollController();
  final BackendModel _backendModel;
  final PythonService _pythonService;

  List<String> get selectedFilePaths => List.unmodifiable(_selectedFilePaths);
  Map<String, String> get rawInfoByFilePath => Map.unmodifiable(_rawInfoByFilePath);
  List<int> get availableChannelIndices => List.unmodifiable(_availableChannelIndices);
  List<int> get availableSweepIndices => List.unmodifiable(_availableSweepIndices);
  List<String> get selectedSweepTokens => List.unmodifiable(_selectedSweepTokens);
  List<double> get previewTimesSec => List.unmodifiable(_previewTimesSec);
  List<double> get previewValues => List.unmodifiable(_previewValues);
  List<int> get previewChannels {
    final channels = _previewValuesByChannel.keys.toList()..sort();
    return List.unmodifiable(channels);
  }
  bool get isLoadingRawPlots => _isLoadingRawPlots;
  String? get rawPlotError => _rawPlotError;
  bool get hasSelectedFiles => _selectedFilePaths.isNotEmpty;
  bool get hasConfiguredRawData => _rawDataConfigured;
  ValueNotifier<bool> get rawDataConfiguredListenable => _rawDataConfiguredNotifier;
  bool get hasEnabledDownstreamTabs => hasSelectedFiles && _rawDataConfigured;
  bool get isAnalysisRunning => _analysisRunning;
  String? get analysisConfigPath => _analysisConfigPath;
  String get analysisExportFormat => _analysisExportFormat;
  bool get analysisExportCsv => _analysisExportCsv;
  String? get analysisOutputDir => _analysisOutputDir;
  List<String> get analysisPlotPaths => List.unmodifiable(_analysisPlotPaths);
  List<String> get analysisCsvPaths => List.unmodifiable(_analysisCsvPaths);
  bool get isLoadingRawInfo => _isLoadingRawInfo;
  bool get isLoadingPreviewPlot => _isLoadingPreviewPlot;
  String? get rawInfoError => _rawInfoError;
  String? get previewError => _previewError;
  int get clampChannel => _clampChannel;
  int get membraneChannel => _membraneChannel;
  int get stimuliChannel => _stimuliChannel;
  double? get startTimeSec => _startTimeSec;
  double? get endTimeSec => _endTimeSec;
  Color get lineColor => _lineColor;
  Color get backgroundColor => _backgroundColor;
  Color get gridColor => _gridColor;
  bool get hasRawPlots => _rawPlotPathsByChannel.isNotEmpty;
  bool get hasAnalysisConfigPath =>
      _analysisConfigPath != null && _analysisConfigPath!.isNotEmpty;
  bool get hasLoadedRawInfo => _rawInfoByFilePath.isNotEmpty && _rawInfoError == null;
  bool get hasPreviewPlot {
    if (_previewTimesByChannel.isEmpty || _previewValuesByChannel.isEmpty) {
      return false;
    }

    for (final channel in _previewValuesByChannel.keys) {
      final times = _previewTimesByChannel[channel] ?? const <double>[];
      final values = _previewValuesByChannel[channel] ?? const <double>[];
      if (times.isNotEmpty && values.isNotEmpty) {
        return true;
      }
    }

    return false;
  }
  bool get hasSweepAndWindowConfigured {
    if (_selectedSweepTokens.isEmpty || _startTimeSec == null || _endTimeSec == null) {
      return false;
    }
    return _endTimeSec! > _startTimeSec!;
  }

  bool get hasCompletedRawFlow => hasLoadedRawInfo && hasSweepAndWindowConfigured;

  Map<String, dynamic> get stagedAnalysisConfig {
    final config = <String, dynamic>{
      'view_raw': false,
      'extract_peak_current': false,
      'extract_integrated_current': false,
      'extract_current_stats': false,
      'analyze_iv': false,
      'export_csv': _analysisExportCsv,
      'export_format': _analysisExportFormat,
      'channel': _clampChannel,
      'clamp_channel': _clampChannel,
      'membrane_channel': _membraneChannel,
      'stimuli_channel': _stimuliChannel,
      'e_rev': 0,
      'i_rev': -60,
      'start_time': _startTimeSec ?? 0.0,
      'end_time': _endTimeSec ?? 0.5,
      'selected_sweeps': _selectedSweepTokens.join(','),
      'plot_line_color': _colorToHex(_lineColor),
      'plot_background_color': _colorToHex(_backgroundColor),
      'plot_grid_color': _colorToHex(_gridColor),
    };

    if (_selectedSweepTokens.length == 1) {
      config['sweep_number'] = _selectedSweepTokens.first;
    }

    return config;
  }

  Future<void> initializePythonBackend() async {
    _backendModel.updateStatus(BackendStatus.initializing);

    try {
      await _pythonService.init();
      _backendModel.updateStatus(BackendStatus.ready);
    } catch (_) {
      _backendModel.updateStatus(BackendStatus.error);
    }
  }

  Future<void> pickAbfFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['abf'],
      dialogTitle: 'Select ABF Files',
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    var hasNewFiles = false;
    for (final file in result.files) {
      final filePath = file.path;
      if (filePath != null && !_selectedFilePaths.contains(filePath)) {
        _selectedFilePaths.add(filePath);
        hasNewFiles = true;
      }
    }

    if (hasNewFiles) {
      _rawInfoByFilePath.clear();
      _rawInfoError = null;
      _clearPreviewData();
      _clearAnalysisOutputs();
      _previewError = null;
      _availableChannelIndices.clear();
      _availableSweepIndices.clear();
      _selectedSweepTokens.clear();
      _rawDataConfigured = false;
      notifyListeners();
    }
  }

  void removeFile(String filePath) {
    if (_selectedFilePaths.remove(filePath)) {
      _rawInfoByFilePath.remove(filePath);
      if (_selectedFilePaths.isEmpty) {
        _rawDataConfigured = false;
        _rawInfoError = null;
        _clearPreviewData();
        _clearAnalysisOutputs();
        _previewError = null;
        _availableChannelIndices.clear();
        _availableSweepIndices.clear();
        _selectedSweepTokens.clear();
      }
      notifyListeners();
    }
  }

  void setRawDataConfigured(bool value) {
    final nextValue = hasSelectedFiles && hasCompletedRawFlow ? value : false;

    if (_rawDataConfigured == nextValue) {
      return;
    }

    _rawDataConfigured = nextValue;
    _rawDataConfiguredNotifier.value = nextValue;
  }

  Future<void> loadRawInfoForSelectedFiles() async {
    if (_isLoadingRawInfo || _selectedFilePaths.isEmpty) {
      return;
    }

    _isLoadingRawInfo = true;
    _rawInfoError = null;
    _rawInfoByFilePath.clear();
    _backendModel.updateStatus(BackendStatus.computing);
    notifyListeners();

    try {
      for (final filePath in _selectedFilePaths) {
        final info = await _pythonService.extractAbfInfo(filePath);
        _rawInfoByFilePath[filePath] = info;
      }
      _updateAvailableChannelsFromRawInfo();
      _updateAvailableSweepsFromRawInfo();
      _backendModel.updateStatus(BackendStatus.ready);
    } catch (e) {
      _rawInfoError = e.toString();
      _rawInfoByFilePath.clear();
      _backendModel.updateStatus(BackendStatus.error);
    } finally {
      _isLoadingRawInfo = false;
      _syncRawDataConfigured();
      notifyListeners();
    }
  }

  void setClampChannel(int channel) {
    if (_clampChannel == channel) {
      return;
    }
    _clampChannel = channel;
    _clearPreviewData();
    _previewError = null;
    notifyListeners();
  }

  void setMembraneChannel(int channel) {
    if (_membraneChannel == channel) {
      return;
    }
    _membraneChannel = channel;
    _clearPreviewData();
    _previewError = null;
    notifyListeners();
  }

  void setStimuliChannel(int channel) {
    if (_stimuliChannel == channel) {
      return;
    }
    _stimuliChannel = channel;
    _clearPreviewData();
    _previewError = null;
    notifyListeners();
  }

  void setSelectedSweepsFromText(String text) {
    final tokens = text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    _selectedSweepTokens
      ..clear()
      ..addAll(tokens);
    _syncRawDataConfigured();
    notifyListeners();
  }

  void toggleSweepSelection(int sweepIndex, bool selected) {
    final token = sweepIndex.toString();
    final hasToken = _selectedSweepTokens.contains(token);

    if (selected && !hasToken) {
      _selectedSweepTokens.add(token);
    }
    if (!selected && hasToken) {
      _selectedSweepTokens.remove(token);
    }

    _selectedSweepTokens.sort((a, b) {
      final ai = int.tryParse(a) ?? 0;
      final bi = int.tryParse(b) ?? 0;
      return ai.compareTo(bi);
    });

    _syncRawDataConfigured();
    notifyListeners();
  }

  Future<void> buildPreviewPlot({
    String? abfFilePath,
    int? sweepNumber,
  }) async {
    if (_isLoadingPreviewPlot || _selectedFilePaths.isEmpty) {
      return;
    }

    _isLoadingPreviewPlot = true;
    _previewError = null;
    _clearPreviewData();
    _backendModel.updateStatus(BackendStatus.computing);
    notifyListeners();

    try {
      final selectedFile = _resolvePreviewFilePath(abfFilePath);
      if (selectedFile == null) {
        throw Exception('No ABF file is available for preview generation.');
      }

      final selectedSweep = sweepNumber ?? _parseSingleSweep();
      final tempDir = await getTemporaryDirectory();

      final channelsToBuild = <int>{
        _clampChannel,
        _membraneChannel,
        _stimuliChannel,
      };

      for (final channel in channelsToBuild) {
        final csvPath = await _pythonService.generateRawPreviewCsv(
          abfFilePath: selectedFile,
          outputDir: tempDir.path,
          channel: channel,
          sweepNumber: selectedSweep,
        );

        final parsed = await _parsePreviewCsv(csvPath);
        _previewTimesByChannel[channel] = parsed.times;
        _previewValuesByChannel[channel] = parsed.values;
      }

      final primaryChannel = _previewTimesByChannel.containsKey(_clampChannel)
          ? _clampChannel
          : channelsToBuild.first;

      _previewTimesSec
        ..clear()
        ..addAll(_previewTimesByChannel[primaryChannel] ?? const <double>[]);
      _previewValues
        ..clear()
        ..addAll(_previewValuesByChannel[primaryChannel] ?? const <double>[]);

      _backendModel.updateStatus(BackendStatus.ready);
    } catch (e) {
      _previewError = e.toString();
      _clearPreviewData();
      _backendModel.updateStatus(BackendStatus.error);
    } finally {
      _isLoadingPreviewPlot = false;
      _syncRawDataConfigured();
      notifyListeners();
    }
  }

  Future<void> buildRawChannelPlots({String? abfFilePath}) async {
    if (_isLoadingRawPlots || _selectedFilePaths.isEmpty) {
      return;
    }

    final selectedSweeps = _selectedSweepTokens
        .map(int.tryParse)
        .whereType<int>()
        .toList();

    if (selectedSweeps.isEmpty) {
      _rawPlotError = 'Select at least one sweep before plotting.';
      notifyListeners();
      return;
    }

    _isLoadingRawPlots = true;
    _rawPlotError = null;
    _rawPlotPathsByChannel.clear();
    _backendModel.updateStatus(BackendStatus.computing);
    notifyListeners();

    try {
      final selectedFile = _resolvePreviewFilePath(abfFilePath);
      if (selectedFile == null) {
        throw Exception('No ABF file is available for raw plotting.');
      }

      final tempDir = await getTemporaryDirectory();
      final channels = <int>{_clampChannel, _membraneChannel, _stimuliChannel};
      for (final channel in channels) {
        final plotPath = await _pythonService.generateRawPreviewPlot(
          abfFilePath: selectedFile,
          outputDir: tempDir.path,
          channel: channel,
          selectedSweeps: selectedSweeps,
        );
        _rawPlotPathsByChannel[channel] = plotPath;
      }
      _backendModel.updateStatus(BackendStatus.ready);
    } catch (e) {
      _rawPlotError = e.toString();
      _rawPlotPathsByChannel.clear();
      _backendModel.updateStatus(BackendStatus.error);
    } finally {
      _isLoadingRawPlots = false;
      notifyListeners();
    }
  }

  void setStartTimeFromText(String text) {
    _startTimeSec = double.tryParse(text.trim());
    _syncRawDataConfigured();
    notifyListeners();
  }

  void setEndTimeFromText(String text) {
    _endTimeSec = double.tryParse(text.trim());
    _syncRawDataConfigured();
    notifyListeners();
  }

  void setLineColor(Color color) {
    _lineColor = color;
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    _backgroundColor = color;
    notifyListeners();
  }

  void setGridColor(Color color) {
    _gridColor = color;
    notifyListeners();
  }

  void setAnalysisExportFormat(String format) {
    if (_analysisExportFormat == format) {
      return;
    }

    _analysisExportFormat = format;
    notifyListeners();
  }

  void setAnalysisExportCsv(bool value) {
    if (_analysisExportCsv == value) {
      return;
    }

    _analysisExportCsv = value;
    notifyListeners();
  }

  Future<void> pickAnalysisConfigFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      dialogTitle: 'Select Analysis JSON Config',
    );

    final selectedPath = result?.files.single.path;
    if (selectedPath == null || selectedPath.isEmpty) {
      return;
    }

    final decoded = await _pythonService.loadConfigFromFile(selectedPath);
    _applyImportedConfig(decoded);
    _analysisConfigPath = selectedPath;
    _syncRawDataConfigured();
    notifyListeners();
  }

  Future<void> saveCurrentConfigAsJson() async {
    final filePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Analysis JSON Config',
      fileName: 'analysis_config.json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );

    if (filePath == null || filePath.isEmpty) {
      return;
    }

    await _pythonService.saveConfigToFile(filePath, stagedAnalysisConfig);
    _analysisConfigPath = filePath;
    _syncRawDataConfigured();
    notifyListeners();
  }

  Future<void> runPythonAnalysis({bool? exportCsv}) async {
    if (_analysisRunning || _selectedFilePaths.isEmpty) {
      return;
    }

    final abfFile = _resolveAbfFileArgument();
    if (abfFile == null || abfFile.isEmpty) {
      return;
    }

    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Export Directory',
    );

    if (outputDir == null || outputDir.isEmpty) {
      return;
    }

    _analysisRunning = true;
    _clearAnalysisOutputs();
    _backendModel.updateStatus(BackendStatus.computing);
    notifyListeners();

    final shouldExportCsv = exportCsv ?? _analysisExportCsv;

    try {
      await _pythonService.runAnalyzeIvCommand(
        abfFilePattern: abfFile,
        outputDir: outputDir,
        clampChannel: _clampChannel,
        membraneChannel: _membraneChannel,
        stimuliChannel: _stimuliChannel,
        startTime: _startTimeSec,
        endTime: _endTimeSec,
        exportCsv: shouldExportCsv,
        exportFormat: _analysisExportFormat,
      );
      _analysisOutputDir = outputDir;
      _analysisPlotPaths
        ..clear()
        ..addAll(_buildAnalysisOutputPaths(
          outputDir: outputDir,
          abfFileArgument: abfFile,
          exportFormat: _analysisExportFormat,
          timeWindowSuffix: _analysisTimeWindowSuffix(),
          suffixes: const [
            '_predicted_current',
            '_slopes',
            '_iv_analysis',
            '_Gsyn_Ge_Gi_over_time',
            '_EI_ratio_over_time',
            '_E_and_I_fraction_over_time',
          ],
        ));
      if (shouldExportCsv) {
        _analysisCsvPaths
          ..clear()
          ..addAll(_buildAnalysisOutputPaths(
            outputDir: outputDir,
            abfFileArgument: abfFile,
            exportFormat: 'csv',
            timeWindowSuffix: _analysisTimeWindowSuffix(),
            suffixes: const [
              '_predicted_current',
              '_slopes',
              '_iv_analysis',
              '_Gsyn_Ge_Gi_over_time',
              '_EI_ratio_over_time',
              '_E_and_I_fraction_over_time',
            ],
          ));
      }
      await Future.wait(
        _analysisPlotPaths.map((filePath) => FileImage(File(filePath)).evict()),
      );
      _backendModel.updateStatus(BackendStatus.ready);
    } catch (_) {
      _backendModel.updateStatus(BackendStatus.error);
    } finally {
      _analysisRunning = false;
      notifyListeners();
    }
  }

  String? _resolveAbfFileArgument() {
    if (_selectedFilePaths.isEmpty) {
      return null;
    }

    if (_selectedFilePaths.length == 1) {
      return _selectedFilePaths.first;
    }

    final directories = _selectedFilePaths.map(path.dirname).toSet();
    if (directories.length == 1) {
      return path.join(directories.first, '*.abf');
    }

    return _selectedFilePaths.first;
  }

  String? rawPlotPathForChannel(int channel) => _rawPlotPathsByChannel[channel];

  String? analysisPlotPathForSuffix(String suffix) {
    for (final filePath in _analysisPlotPaths) {
      if (filePath.endsWith('$suffix.$analysisExportFormat')) {
        return filePath;
      }
    }
    return null;
  }

  String? _resolvePreviewFilePath(String? requestedFilePath) {
    if (requestedFilePath == null || requestedFilePath.isEmpty) {
      return _selectedFilePaths.isEmpty ? null : _selectedFilePaths.first;
    }

    if (_selectedFilePaths.contains(requestedFilePath)) {
      return requestedFilePath;
    }

    return _selectedFilePaths.isEmpty ? null : _selectedFilePaths.first;
  }

  void _syncRawDataConfigured() {
    if (!hasSelectedFiles || !hasCompletedRawFlow) {
      if (_rawDataConfigured) {
        _rawDataConfigured = false;
        _rawDataConfiguredNotifier.value = false;
      }
    }
  }

  void _clearAnalysisOutputs() {
    _analysisOutputDir = null;
    _analysisPlotPaths.clear();
    _analysisCsvPaths.clear();
  }

  List<String> _buildAnalysisOutputPaths({
    required String outputDir,
    required String abfFileArgument,
    required String exportFormat,
    required String timeWindowSuffix,
    required List<String> suffixes,
  }) {
    final filename = _analysisOutputFilename(abfFileArgument);
    return suffixes
      .map((suffix) => path.join(outputDir, '$filename$timeWindowSuffix$suffix.$exportFormat'))
        .toList();
  }

  String _analysisOutputFilename(String abfFileArgument) {
    final rawName = path.basename(abfFileArgument).replaceAll('"', '');
    return rawName.replaceAll('.abf', '').replaceAll('*', '%');
  }

  String _analysisTimeWindowSuffix() {
    if (_startTimeSec == null || _endTimeSec == null) {
      return '';
    }

    return '_t${_startTimeSec!}-${_endTimeSec!}';
  }

  void _applyImportedConfig(Map<String, dynamic> config) {
    final importedSweeps = <String>[];

    final selectedSweepsValue = config['selected_sweeps'];
    if (selectedSweepsValue is List) {
      importedSweeps.addAll(
        selectedSweepsValue.map((e) => e.toString().trim()).where((e) => e.isNotEmpty),
      );
    }

    final sweepNumber = config['sweep_number'];
    if (sweepNumber != null) {
      importedSweeps.add(sweepNumber.toString());
    }

    _selectedSweepTokens
      ..clear()
      ..addAll(importedSweeps.toSet().toList()..sort());

    final importedClamp = config['clamp_channel'] ?? config['channel'];
    if (importedClamp != null) {
      final parsed = int.tryParse(importedClamp.toString());
      if (parsed != null && parsed >= 0) {
        _clampChannel = parsed;
      }
    }

    final importedMembrane = config['membrane_channel'];
    if (importedMembrane != null) {
      final parsed = int.tryParse(importedMembrane.toString());
      if (parsed != null && parsed >= 0) {
        _membraneChannel = parsed;
      }
    }

    final importedStimuli = config['stimuli_channel'];
    if (importedStimuli != null) {
      final parsed = int.tryParse(importedStimuli.toString());
      if (parsed != null && parsed >= 0) {
        _stimuliChannel = parsed;
      }
    }

    _startTimeSec = _toDouble(config['start_time']) ?? _startTimeSec;
    _endTimeSec = _toDouble(config['end_time']) ?? _endTimeSec;

    _lineColor = _parseColor(config['plot_line_color']) ?? _lineColor;
    _backgroundColor = _parseColor(config['plot_background_color']) ?? _backgroundColor;
    _gridColor = _parseColor(config['plot_grid_color']) ?? _gridColor;

    _normalizeMappedChannels();
  }

  void _updateAvailableChannelsFromRawInfo() {
    var channelCount = 0;
    final pattern = RegExp(r'Channels:\s*(\d+)', caseSensitive: false);

    for (final info in _rawInfoByFilePath.values) {
      final match = pattern.firstMatch(info);
      final parsed = match == null ? null : int.tryParse(match.group(1) ?? '');
      if (parsed != null && parsed > channelCount) {
        channelCount = parsed;
      }
    }

    _availableChannelIndices
      ..clear()
      ..addAll(List<int>.generate(channelCount, (i) => i));

    _normalizeMappedChannels();
  }

  void _normalizeMappedChannels() {
    if (_availableChannelIndices.isEmpty) {
      return;
    }

    final minChannel = _availableChannelIndices.first;
    final maxChannel = _availableChannelIndices.last;

    int clamp(int value) {
      if (value < minChannel) {
        return minChannel;
      }
      if (value > maxChannel) {
        return maxChannel;
      }
      return value;
    }

    _clampChannel = clamp(_clampChannel);
    _membraneChannel = clamp(_membraneChannel);
    _stimuliChannel = clamp(_stimuliChannel);
  }

  void _updateAvailableSweepsFromRawInfo() {
    var sweepCount = 0;
    final pattern = RegExp(r'Number of Sweeps:\s*(\d+)', caseSensitive: false);

    for (final info in _rawInfoByFilePath.values) {
      final match = pattern.firstMatch(info);
      final parsed = match == null ? null : int.tryParse(match.group(1) ?? '');
      if (parsed != null && parsed > sweepCount) {
        sweepCount = parsed;
      }
    }

    _availableSweepIndices
      ..clear()
      ..addAll(List<int>.generate(sweepCount, (i) => i));

    if (_availableSweepIndices.isEmpty) {
      _selectedSweepTokens.clear();
      return;
    }

    if (_selectedSweepTokens.isEmpty) {
      _selectedSweepTokens
        ..clear()
        ..addAll(_availableSweepIndices.map((e) => e.toString()));
      return;
    }

    final validTokens = _availableSweepIndices.map((e) => e.toString()).toSet();
    _selectedSweepTokens.removeWhere((token) => !validTokens.contains(token));
    if (_selectedSweepTokens.isEmpty) {
      _selectedSweepTokens.addAll(_availableSweepIndices.map((e) => e.toString()));
    }
  }

  int? _parseSingleSweep() {
    if (_selectedSweepTokens.isEmpty) {
      return null;
    }
    return int.tryParse(_selectedSweepTokens.first);
  }

  List<double> previewTimesForChannel(int channel) {
    final values = _previewTimesByChannel[channel] ?? const <double>[];
    return List.unmodifiable(values);
  }

  List<double> previewValuesForChannel(int channel) {
    final values = _previewValuesByChannel[channel] ?? const <double>[];
    return List.unmodifiable(values);
  }

  Future<({List<double> times, List<double> values})> _parsePreviewCsv(String csvPath) async {
    final file = File(csvPath);
    if (!await file.exists()) {
      throw Exception('Preview CSV not found: $csvPath');
    }

    final lines = await file.readAsLines();
    if (lines.length < 2) {
      throw Exception('Preview CSV did not contain data rows.');
    }

    final header = lines.first.split(',');
    if (header.length < 2) {
      throw Exception('Preview CSV did not contain sweep columns.');
    }

    final parsedTimes = <double>[];
    final parsedValues = <double>[];

    for (final line in lines.skip(1)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final values = trimmed.split(',');
      if (values.length < 2) {
        continue;
      }

      final t = double.tryParse(values[0]);
      final y = double.tryParse(values[1]);
      if (t == null || y == null) {
        continue;
      }

      parsedTimes.add(t);
      parsedValues.add(y);
    }

    if (parsedTimes.isEmpty || parsedValues.isEmpty) {
      throw Exception('Preview CSV parsing produced no valid points.');
    }

    return (times: parsedTimes, values: parsedValues);
  }

  void _clearPreviewData() {
    _previewTimesSec.clear();
    _previewValues.clear();
    _previewTimesByChannel.clear();
    _previewValuesByChannel.clear();
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  Color? _parseColor(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    final normalized = text.startsWith('#') ? text.substring(1) : text;
    if (normalized.length != 6 && normalized.length != 8) {
      return null;
    }

    final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
    final intValue = int.tryParse(hex, radix: 16);
    if (intValue == null) {
      return null;
    }

    return Color(intValue);
  }

  String _colorToHex(Color color) {
    final value = color.toARGB32();
    final rgb = (value & 0x00FFFFFF).toRadixString(16).padLeft(6, '0');
    return '#${rgb.toUpperCase()}';
  }

  @override
  void dispose() {
    filesScrollController.dispose();
    _rawDataConfiguredNotifier.dispose();
    super.dispose();
  }
}