import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'sidebar_view.dart';
import 'raw_data_view.dart';
import 'linear_relationship_view.dart';
import 'ei_relationship_view.dart';
import '../shared/backend_status.dart';
import '../viewModel/import_view_model.dart';

class PlotDataView extends StatefulWidget {
  const PlotDataView({
    super.key,
    required this.backendStatusStream,
    required this.viewModel,
  });

  final Stream<BackendStatus> backendStatusStream;
  final ImportViewModel viewModel;

  @override
  State<PlotDataView> createState() => _PlotDataViewState();
}

class _PlotDataViewState extends State<PlotDataView> {
  String? _selectedPreviewFilePath;
  int? _selectedPreviewSweep;
  final TextEditingController _windowStartController = TextEditingController();
  final TextEditingController _windowEndController = TextEditingController();
  final FocusNode _windowStartFocus = FocusNode();
  final FocusNode _windowEndFocus = FocusNode();

  @override
  void dispose() {
    _windowStartController.dispose();
    _windowEndController.dispose();
    _windowStartFocus.dispose();
    _windowEndFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final fileOptions = viewModel.selectedFilePaths;
    final sweepOptions = viewModel.availableSweepIndices;
    final selectedFilePath = _resolveSelectedFilePath(fileOptions);
    final selectedSweep = _resolveSelectedSweep(sweepOptions, viewModel.selectedSweepTokens);

    _syncWindowControllers(viewModel);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          const baseWidth = 1440.0;
          const baseHeight = 1024.0;

          final scaleX = screenWidth / baseWidth;
          final scaleY = screenHeight / baseHeight;
          final scale = scaleX < scaleY ? scaleX : scaleY;

          return Container(
            width: screenWidth,
            height: screenHeight,
            color: Colors.white.withValues(alpha: 0.6),
            child: Stack(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: viewModel.rawDataConfiguredListenable,
                  builder: (context, configured, _) {
                    return AnimatedBuilder(
                      animation: viewModel,
                      builder: (context, _) {
                        return SideBar(
                          backendStatusStream: widget.backendStatusStream,
                          scale: scale,
                          uploadFilesActive: false,
                          onUploadFilesTap: () => Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                          ),
                          rawDataEnabled: true,
                          rawDataActive: false,
                          onRawDataTap: () => Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, _, _) => RawDataView(
                                backendStatusStream: widget.backendStatusStream,
                                viewModel: viewModel,
                              ),
                              transitionsBuilder: (_, _, _, child) => child,
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          ),
                          plotDataEnabled: viewModel.hasLoadedRawInfo,
                          plotDataActive: true,
                          linearRelationshipEnabled: viewModel.hasSelectedFiles && configured,
                          onLinearRelationshipTap: () => Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, _, _) => LinearRelationshipView(
                                backendStatusStream: widget.backendStatusStream,
                                viewModel: viewModel,
                              ),
                              transitionsBuilder: (_, _, _, child) => child,
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          ),
                          eiRelationshipEnabled: viewModel.hasSelectedFiles && configured,
                          onEiRelationshipTap: () => Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, _, _) => EiRelationshipView(
                                backendStatusStream: widget.backendStatusStream,
                                viewModel: viewModel,
                              ),
                              transitionsBuilder: (_, _, _, child) => child,
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: viewModel,
                  builder: (context, _) {
                    return Positioned(
                      left: 650 * scale,
                      top: 56 * scale,
                      right: 40 * scale,
                      bottom: 24 * scale,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plot Data Flow',
                              style: TextStyle(
                                color: const Color(0xFF222831),
                                fontSize: 42 * scale,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8 * scale),
                            Text(
                              '${viewModel.selectedFilePaths.length} file(s) selected',
                              style: TextStyle(
                                color: const Color(0xFF222831),
                                fontSize: 17 * scale,
                                fontFamily: 'Inter',
                              ),
                            ),
                            SizedBox(height: 14 * scale),
                            _card(
                              scale,
                              title: 'Choose File and Sweep',
                              subtitle: 'Pick the ABF file and sweep to generate preview plots for.',
                              child: Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue: selectedFilePath,
                                    dropdownColor: Colors.white,
                                    decoration: const InputDecoration(
                                      labelText: 'ABF File',
                                      labelStyle: TextStyle(color: Color(0xFF00ADB5)),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Color(0xFF00ADB5)),
                                      ),
                                    ),
                                    items: fileOptions
                                        .map(
                                          (filePath) => DropdownMenuItem<String>(
                                            value: filePath,
                                            child: Text(
                                              filePath.split('\\').last,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: fileOptions.isEmpty
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _selectedPreviewFilePath = value;
                                            });
                                          },
                                  ),
                                  SizedBox(height: 10 * scale),
                                  DropdownButtonFormField<int>(
                                    initialValue: selectedSweep,
                                    dropdownColor: Colors.white,
                                    decoration: const InputDecoration(
                                      labelText: 'Sweep',
                                      labelStyle: TextStyle(color: Color(0xFF00ADB5)),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Color(0xFF00ADB5)),
                                      ),
                                    ),
                                    items: sweepOptions
                                        .map(
                                          (sweep) => DropdownMenuItem<int>(
                                            value: sweep,
                                            child: Text('Sweep $sweep'),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: sweepOptions.isEmpty
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _selectedPreviewSweep = value;
                                            });
                                          },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12 * scale),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: selectedFilePath == null || selectedSweep == null
                                    ? null
                                    : () async {
                                        await viewModel.buildPreviewPlot(
                                          abfFilePath: selectedFilePath,
                                          sweepNumber: selectedSweep,
                                        );
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF00ADB5),
                                ),
                                child: Text(
                                  viewModel.isLoadingPreviewPlot
                                      ? 'Building plot...'
                                      : 'Build Preview Plot',
                                  style: TextStyle(
                                    color: const Color(0xFF222831),
                                    fontSize: 14 * scale,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            if (viewModel.previewError != null) ...[
                              SizedBox(height: 8 * scale),
                              Text(
                                viewModel.previewError!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12 * scale,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                            SizedBox(height: 12 * scale),
                            _card(
                              scale,
                              title: 'Time Window',
                              subtitle: 'Set the analysis window manually using the text fields.',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _windowStartController,
                                          focusNode: _windowStartFocus,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Window Start (s)',
                                            border: OutlineInputBorder(),
                                          ),
                                          onSubmitted: viewModel.setStartTimeFromText,
                                        ),
                                      ),
                                      SizedBox(width: 10 * scale),
                                      Expanded(
                                        child: TextField(
                                          controller: _windowEndController,
                                          focusNode: _windowEndFocus,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Window End (s)',
                                            border: OutlineInputBorder(),
                                          ),
                                          onSubmitted: viewModel.setEndTimeFromText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8 * scale),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            viewModel.setStartTimeFromText(_windowStartController.text);
                                          },
                                          child: Text('Apply Start',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14 * scale,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10 * scale),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            viewModel.setEndTimeFromText(_windowEndController.text);
                                          },
                                          child: Text('Apply End',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14 * scale,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10 * scale),
                                  if (!viewModel.hasPreviewPlot)
                                    Text(
                                      'Generate preview plot first.',
                                      style: TextStyle(
                                        fontSize: 12 * scale,
                                        color: const Color(0xFF555D67),
                                        fontFamily: 'Inter',
                                      ),
                                    )
                                  else
                                    Column(
                                      children: [
                                        _channelPreviewSection(
                                          scale,
                                          viewModel,
                                          label: 'Clamp Channel',
                                          channel: viewModel.clampChannel,
                                        ),
                                        SizedBox(height: 10 * scale),
                                        _channelPreviewSection(
                                          scale,
                                          viewModel,
                                          label: 'Membrane Channel',
                                          channel: viewModel.membraneChannel,
                                        ),
                                        SizedBox(height: 10 * scale),
                                        _channelPreviewSection(
                                          scale,
                                          viewModel,
                                          label: 'Stimuli Channel',
                                          channel: viewModel.stimuliChannel,
                                        ),
                                      ],
                                    ),
                                  SizedBox(height: 8 * scale),
                                  Text(
                                    'Window: ${_fmt(viewModel.startTimeSec)} s to ${_fmt(viewModel.endTimeSec)} s',
                                    style: TextStyle(
                                      fontSize: 12 * scale,
                                      color: const Color(0xFF222831),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 14 * scale),
                            ValueListenableBuilder<bool>(
                              valueListenable: viewModel.rawDataConfiguredListenable,
                              builder: (context, configured, _) {
                                return Container(
                                  padding: EdgeInsets.all(14 * scale),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: const Color(0xFF00ADB5)),
                                    borderRadius: BorderRadius.circular(14 * scale),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        viewModel.analysisConfigPath == null
                                            ? 'Current JSON: in-memory (not saved yet)'
                                            : 'Current JSON: ${viewModel.analysisConfigPath}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: const Color(0xFF222831),
                                          fontSize: 15 * scale,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      SizedBox(height: 10 * scale),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: viewModel.hasCompletedRawFlow
                                                  ? viewModel.saveCurrentConfigAsJson
                                                  : null,
                                              child: Text(
                                                'Save JSON (Optional)',
                                                style: TextStyle(
                                                  color: const Color(0xFF222831),
                                                  fontSize: 14 * scale,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10 * scale),
                                          Expanded(
                                            child: FilledButton(
                                              onPressed: viewModel.hasCompletedRawFlow
                                                  ? () async {
                                                      viewModel.setRawDataConfigured(true);
                                                    }
                                                  : null,
                                              style: FilledButton.styleFrom(
                                                backgroundColor: const Color(0xFF00ADB5),
                                              ),
                                              child: Text(
                                                configured ? 'Flow Complete' : 'Finish Flow',
                                                style: TextStyle(
                                                  color: const Color(0xFF222831),
                                                  fontSize: 14 * scale,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _resolveSelectedFilePath(List<String> fileOptions) {
    if (fileOptions.isEmpty) {
      return null;
    }

    final current = _selectedPreviewFilePath;
    if (current != null && fileOptions.contains(current)) {
      return current;
    }

    return fileOptions.first;
  }

  int? _resolveSelectedSweep(List<int> sweepOptions, List<String> selectedSweepTokens) {
    if (_selectedPreviewSweep != null && sweepOptions.contains(_selectedPreviewSweep)) {
      return _selectedPreviewSweep;
    }

    if (selectedSweepTokens.isNotEmpty) {
      final parsed = int.tryParse(selectedSweepTokens.first);
      if (parsed != null && sweepOptions.contains(parsed)) {
        return parsed;
      }
    }

    return sweepOptions.isEmpty ? null : sweepOptions.first;
  }

  void _syncWindowControllers(ImportViewModel viewModel) {
    final startText = _formatWindowValue(viewModel.startTimeSec);
    final endText = _formatWindowValue(viewModel.endTimeSec);

    if (!_windowStartFocus.hasFocus && _windowStartController.text != startText) {
      _windowStartController.text = startText;
    }
    if (!_windowEndFocus.hasFocus && _windowEndController.text != endText) {
      _windowEndController.text = endText;
    }
  }

  String _formatWindowValue(double? value) {
    if (value == null) {
      return '';
    }
    return value.toStringAsFixed(4);
  }

  Widget _channelPreviewSection(
    double scale,
    ImportViewModel viewModel, {
    required String label,
    required int channel,
  }) {
    final times = viewModel.previewTimesForChannel(channel);
    final values = viewModel.previewValuesForChannel(channel);

    if (times.isEmpty || values.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$label ($channel): no preview data available.',
          style: TextStyle(
            fontSize: 12 * scale,
            color: const Color(0xFF666E77),
            fontFamily: 'Inter',
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ($channel)',
          style: TextStyle(
            color: const Color(0xFF222831),
            fontSize: 13 * scale,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6 * scale),
        RepaintBoundary(
          child: _interactivePreviewPlot(
            scale,
            viewModel,
            times: times,
            values: values,
          ),
        ),
      ],
    );
  }

  Widget _interactivePreviewPlot(
    double scale,
    ImportViewModel viewModel, {
    required List<double> times,
    required List<double> values,
  }) {
    if (times.isEmpty || values.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 230 * scale,
      decoration: BoxDecoration(
        color: viewModel.backgroundColor,
        border: Border.all(color: const Color(0xFF00ADB5)),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: CustomPaint(
        painter: _PreviewPlotPainter(
          times: times,
          values: values,
          lineColor: viewModel.lineColor,
          gridColor: viewModel.gridColor,
          windowStart: viewModel.startTimeSec,
          windowEnd: viewModel.endTimeSec,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _card(
    double scale, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF00ADB5), width: 1.5),
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF222831),
              fontSize: 18 * scale,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            subtitle,
            style: TextStyle(
              color: const Color(0xFF444D56),
              fontSize: 12 * scale,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 10 * scale),
          child,
        ],
      ),
    );
  }

  String _fmt(double? value) {
    if (value == null) {
      return '-';
    }
    return value.toStringAsFixed(4);
  }
}

class _PreviewPlotPainter extends CustomPainter {
  _PreviewPlotPainter({
    required this.times,
    required this.values,
    required this.lineColor,
    required this.gridColor,
    required this.windowStart,
    required this.windowEnd,
  });

  final List<double> times;
  final List<double> values;
  final Color lineColor;
  final Color gridColor;
  final double? windowStart;
  final double? windowEnd;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 10.0;
    const rightPad = 10.0;
    const topPad = 10.0;
    const bottomPad = 24.0;

    final plotWidth = math.max(1.0, size.width - leftPad - rightPad);
    final plotHeight = math.max(1.0, size.height - topPad - bottomPad);

    final minTime = times.first;
    final maxTime = times.last;
    var minY = values.first;
    var maxY = values.first;

    for (final v in values) {
      if (v < minY) {
        minY = v;
      }
      if (v > maxY) {
        maxY = v;
      }
    }

    if (maxY == minY) {
      maxY = minY + 1;
    }

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.22)
      ..strokeWidth = 1;

    for (var i = 1; i <= 4; i++) {
      final y = topPad + plotHeight * i / 5;
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + plotWidth, y), gridPaint);
    }

    if (windowStart != null && windowEnd != null) {
      final ws = math.min(windowStart!, windowEnd!);
      final we = math.max(windowStart!, windowEnd!);
      final sx = leftPad + ((ws - minTime) / (maxTime - minTime)) * plotWidth;
      final ex = leftPad + ((we - minTime) / (maxTime - minTime)) * plotWidth;
      final rect = Rect.fromLTRB(sx, topPad, ex, topPad + plotHeight);
      canvas.drawRect(
        rect,
        Paint()..color = Colors.amber.withValues(alpha: 0.22),
      );
    }

    final tickPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    final tickTextPainter = TextPainter(textDirection: TextDirection.ltr);
    final tickTextStyle = TextStyle(
      color: gridColor.withValues(alpha: 0.85),
      fontSize: 10,
      fontFamily: 'Inter',
    );

    final startTick = minTime.ceil();
    final endTick = maxTime.floor();
    for (var tick = startTick; tick <= endTick; tick++) {
      final ratio = (tick - minTime) / (maxTime - minTime);
      final x = leftPad + ratio * plotWidth;
      canvas.drawLine(
        Offset(x, topPad + plotHeight),
        Offset(x, topPad + plotHeight + 5),
        tickPaint,
      );
      tickTextPainter.text = TextSpan(text: tick.toString(), style: tickTextStyle);
      tickTextPainter.layout();
      tickTextPainter.paint(canvas, Offset(x - tickTextPainter.width / 2, topPad + plotHeight + 6));
    }

    final axisPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: 'Time (s)',
        style: TextStyle(
          color: gridColor.withValues(alpha: 0.8),
          fontSize: 10,
          fontFamily: 'Inter',
        ),
      )
      ..layout();
    axisPainter.paint(canvas, Offset(size.width - rightPad - axisPainter.width, size.height - 11));

    final path = Path();
    for (var i = 0; i < times.length; i++) {
      final tx = leftPad + ((times[i] - minTime) / (maxTime - minTime)) * plotWidth;
      final ty = topPad + (1 - ((values[i] - minY) / (maxY - minY))) * plotHeight;
      if (i == 0) {
        path.moveTo(tx, ty);
      } else {
        path.lineTo(tx, ty);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _PreviewPlotPainter oldDelegate) {
    return oldDelegate.times != times ||
        oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.windowStart != windowStart ||
        oldDelegate.windowEnd != windowEnd;
  }
}
