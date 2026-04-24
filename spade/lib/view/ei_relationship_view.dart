import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import 'sidebar_view.dart';
import 'raw_data_view.dart';
import 'plot_data_view.dart';
import 'linear_relationship_view.dart';
import '../shared/backend_status.dart';
import '../viewModel/import_view_model.dart';

class EiRelationshipView extends StatefulWidget {
  const EiRelationshipView({
    super.key,
    required this.backendStatusStream,
    required this.viewModel,
  });

  final Stream<BackendStatus> backendStatusStream;
  final ImportViewModel viewModel;

  @override
  State<EiRelationshipView> createState() => _EiRelationshipViewState();
}

class _EiRelationshipViewState extends State<EiRelationshipView> {
  Future<void> _exportPlots() async {
    await widget.viewModel.runPythonAnalysis(exportCsv: false);
  }

  Future<void> _exportCsv() async {
    await widget.viewModel.runPythonAnalysis(exportCsv: true);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

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

          return AnimatedBuilder(
            animation: viewModel,
            builder: (context, _) {
              final plotPaths = viewModel.analysisPlotPaths
                  .where((filePath) {
                    final basename = path.basename(filePath);
                    return basename.contains('_E_and_I_fraction_over_time.') ||
                        basename.contains('_EI_ratio_over_time.') ||
                        basename.contains('_Gsyn_Ge_Gi_over_time.');
                  })
                  .toList();

              return Container(
                width: screenWidth,
                height: screenHeight,
                color: Colors.white.withValues(alpha: 0.6),
                child: Stack(
                  children: [
                    SideBar(
                      backendStatusStream: widget.backendStatusStream,
                      scale: scale,
                      uploadFilesActive: false,
                      onUploadFilesTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      rawDataEnabled: true,
                      rawDataActive: false,
                      onRawDataTap: () => Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_,_, _) => RawDataView(
                            backendStatusStream: widget.backendStatusStream,
                            viewModel: viewModel,
                          ),
                          transitionsBuilder: (_, _, _, child) => child,
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      ),
                      plotDataEnabled: viewModel.hasLoadedRawInfo,
                      plotDataActive: false,
                      onPlotDataTap: () => Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, _, _) => PlotDataView(
                            backendStatusStream: widget.backendStatusStream,
                            viewModel: viewModel,
                          ),
                          transitionsBuilder: (_, _, _, child) => child,
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      ),
                      linearRelationshipEnabled: viewModel.hasConfiguredRawData,
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
                      eiRelationshipEnabled: viewModel.hasConfiguredRawData,
                      eiRelationshipActive: true,
                    ),
                    Positioned(
                      left: 650 * scale,
                      top: 80 * scale,
                      right: 36 * scale,
                      bottom: 28 * scale,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'E/I Relationship',
                            style: TextStyle(
                              color: const Color(0xFF222831),
                              fontSize: 48 * scale,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 10 * scale),
                          Text(
                            'Python-generated plots are shown below. Choose export options before generating them.',
                            style: TextStyle(
                              color: const Color(0xFF4B5563),
                              fontSize: 14 * scale,
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(height: 14 * scale),
                          _card(
                            scale,
                            title: 'Export Settings',
                            subtitle: 'Choose the file format for plots, then export CSV tables or plot images.',
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  initialValue: viewModel.analysisExportFormat,
                                  dropdownColor: Colors.white,
                                  decoration: const InputDecoration(
                                    labelText: 'Export Format',
                                    labelStyle: TextStyle(color: Color(0xFF00ADB5)),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.black12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFF00ADB5)),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'png', child: Text('PNG')),
                                    DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                                    DropdownMenuItem(value: 'svg', child: Text('SVG')),
                                    DropdownMenuItem(value: 'jpg', child: Text('JPG')),
                                    DropdownMenuItem(value: 'jpeg', child: Text('JPEG')),
                                    DropdownMenuItem(value: 'eps', child: Text('EPS')),
                                    DropdownMenuItem(value: 'pgf', child: Text('PGF')),
                                    DropdownMenuItem(value: 'ps', child: Text('PS')),
                                    DropdownMenuItem(value: 'raw', child: Text('RAW')),
                                    DropdownMenuItem(value: 'rgba', child: Text('RGBA')),
                                    DropdownMenuItem(value: 'svgz', child: Text('SVGZ')),
                                    DropdownMenuItem(value: 'tif', child: Text('TIF')),
                                    DropdownMenuItem(value: 'tiff', child: Text('TIFF')),
                                    DropdownMenuItem(value: 'webp', child: Text('WEBP')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      viewModel.setAnalysisExportFormat(value);
                                    }
                                  },
                                ),
                                SizedBox(height: 12 * scale),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: viewModel.hasCompletedRawFlow && !viewModel.isAnalysisRunning
                                            ? _exportCsv
                                            : null,
                                        child: Text(
                                          viewModel.isAnalysisRunning ? 'Working...' : 'Export CSV',
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
                                        onPressed: viewModel.hasCompletedRawFlow && !viewModel.isAnalysisRunning
                                            ? _exportPlots
                                            : null,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(0xFF00ADB5),
                                        ),
                                        child: Text(
                                          viewModel.isAnalysisRunning ? 'Working...' : 'Generate Plots',
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
                          ),
                          SizedBox(height: 12 * scale),
                          Expanded(
                            child: _PythonPlotGallery(
                              plotPaths: plotPaths,
                              scale: scale,
                              title: 'Generated Python Plots',
                              emptyMessage: 'Run export to generate the Python plots and display them here.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Widget _card(
  double scale, {
  required String title,
  required String subtitle,
  required Widget child,
}) {
  return Container(
    width: double.infinity,
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
        SizedBox(height: 12 * scale),
        child,
      ],
    ),
  );
}

class _PythonPlotGallery extends StatelessWidget {
  const _PythonPlotGallery({
    required this.scale,
    required this.plotPaths,
    required this.title,
    required this.emptyMessage,
  });

  final double scale;
  final List<String> plotPaths;
  final String title;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
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
            'These images are written by the Python analysis step and shown back in the app.',
            style: TextStyle(
              color: const Color(0xFF444D56),
              fontSize: 12 * scale,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 12 * scale),
          if (plotPaths.isEmpty)
            Text(
              emptyMessage,
              style: TextStyle(
                color: const Color(0xFF555D67),
                fontSize: 12 * scale,
                fontFamily: 'Inter',
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: plotPaths.length,
                separatorBuilder: (context, index) => SizedBox(height: 12 * scale),
                itemBuilder: (context, index) {
                  final plotPath = plotPaths[index];
                  return Container(
                    padding: EdgeInsets.all(10 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12 * scale),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          path.basename(plotPath),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF222831),
                            fontSize: 12 * scale,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        AspectRatio(
                          aspectRatio: 1.55,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10 * scale),
                            child: Image.file(
                              File(plotPath),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  alignment: Alignment.center,
                                  color: const Color(0xFFF3F4F6),
                                  child: Text(
                                    'Plot file not found',
                                    style: TextStyle(
                                      color: const Color(0xFF6B7280),
                                      fontSize: 12 * scale,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
