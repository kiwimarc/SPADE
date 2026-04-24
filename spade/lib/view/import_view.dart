import 'package:flutter/material.dart';

import 'sidebar_view.dart';
import 'raw_data_view.dart';
import 'plot_data_view.dart';
import 'linear_relationship_view.dart';
import 'ei_relationship_view.dart';

import '../shared/backend_status.dart';
import '../viewModel/import_view_model.dart';

class ImportView extends StatefulWidget {
  const ImportView({
    Key? key,
    required this.title,
    required this.description,
    required this.backendStatusStream,
  }) : super(key: key);

  final String title;
  final String description;
  final Stream<BackendStatus> backendStatusStream;

  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  late final ImportViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ImportViewModel();
    _viewModel.initializePythonBackend().catchError((_) {});
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                // Sidebar
                AnimatedBuilder(
                  animation: _viewModel,
                  builder: (context, _) => SideBar(
                    backendStatusStream: widget.backendStatusStream,
                    scale: scale,
                    uploadFilesActive: true,
                    rawDataEnabled: _viewModel.hasSelectedFiles,
                    rawDataActive: false,
                    plotDataEnabled: _viewModel.hasLoadedRawInfo,
                    plotDataActive: false,
                    linearRelationshipEnabled:
                      _viewModel.hasEnabledDownstreamTabs,
                    eiRelationshipEnabled:
                      _viewModel.hasEnabledDownstreamTabs,
                    onRawDataTap: () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, _, _) => RawDataView(
                          backendStatusStream: widget.backendStatusStream,
                          viewModel: _viewModel,
                        ),
                        transitionsBuilder: (_, _, _, child) => child,
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    ),
                    onPlotDataTap: () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, _, _) => PlotDataView(
                          backendStatusStream: widget.backendStatusStream,
                          viewModel: _viewModel,
                        ),
                        transitionsBuilder: (_, _, _, child) => child,
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    ),
                    onLinearRelationshipTap: () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, _, _) => LinearRelationshipView(
                          backendStatusStream: widget.backendStatusStream,
                          viewModel: _viewModel,
                        ),
                        transitionsBuilder: (_, _, _, child) => child,
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    ),
                    onEiRelationshipTap: () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, _, _) => EiRelationshipView(
                          backendStatusStream: widget.backendStatusStream,
                          viewModel: _viewModel,
                        ),
                        transitionsBuilder: (_, _, _, child) => child,
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    ),
                  ),
                ),

                _pos(650, 50, scale, _mainTitle(scale)),
                _pos(650, 180, scale, _mainDescription(scale)),
                _pos(
                  730,
                  320,
                  scale,
                  AnimatedBuilder(
                    animation: _viewModel,
                    builder: (context, _) => _fileUploadPanel(scale),
                  ),
                  w: 663,
                  h: 539,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _pos(
    double left,
    double top,
    double scale,
    Widget child, {
    double? w,
    double? h,
  }) {
    return Positioned(
      left: left * scale,
      top: top * scale,
      child: (w != null && h != null)
          ? SizedBox(width: w * scale, height: h * scale, child: child)
          : child,
    );
  }

  Widget _mainTitle(double scale) => SizedBox(
    width: 850 * scale,
    child: RichText(
      text: TextSpan(
        style: TextStyle(
          color: const Color(0xFF222831),
          fontSize: 48 * scale,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
        children: _buildAcronymSpans(widget.title, scale),
      ),
    ),
  );

  Widget _mainDescription(double scale) =>
      Text(widget.description, style: TextStyle(fontSize: 24 * scale));

  Widget _fileUploadPanel(double scale) {
    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 5 * scale,
            strokeAlign: BorderSide.strokeAlignCenter,
            color: const Color(0xFF00ADB5),
          ),
          borderRadius: BorderRadius.circular(50 * scale),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 132 * scale,
            top: 50 * scale,
            child: SizedBox(
              width: 400 * scale,
              height: 290 * scale,
              child: _viewModel.selectedFilePaths.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "assets/images/upload-icon.png",
                            width: 205 * scale,
                            height: 172 * scale,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(height: 16 * scale),
                          Text(
                            'Upload ABF File',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24 * scale,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Scrollbar(
                      controller: _viewModel.filesScrollController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: _viewModel.filesScrollController,
                        padding: EdgeInsets.zero,
                        itemCount: _viewModel.selectedFilePaths.length,
                        separatorBuilder: (_, _) =>
                            SizedBox(height: 10 * scale),
                        itemBuilder: (context, index) =>
                            _buildFileRow(
                              scale,
                              _viewModel.selectedFilePaths[index],
                            ),
                      ),
                    ),
            ),
          ),

          Positioned(
            left: 132 * scale,
            top: 370 * scale,
            child: SizedBox(
              width: 400 * scale,
              height: 60 * scale,
              child: OutlinedButton(
                onPressed: _viewModel.pickAbfFiles,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    width: 5 * scale,
                    color: const Color(0xFFEEEEEE),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15 * scale),
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  _viewModel.selectedFilePaths.isEmpty
                      ? 'Browse Files'
                      : 'Add More Files',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24 * scale,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileRow(double scale, String filePath) {
    return Container(
      width: 400 * scale,
      height: 39 * scale,
      decoration: ShapeDecoration(
        color: const Color(0x3F00ADB5),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1 * scale, color: const Color(0xFF222831)),
          borderRadius: BorderRadius.circular(5 * scale),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 10 * scale),
          Icon(
            Icons.insert_drive_file_rounded,
            size: 24 * scale,
            color: const Color(0xFF222831),
          ),
          SizedBox(width: 8 * scale),
          Expanded(
            child: Text(
              filePath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16 * scale,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove file',
            onPressed: () => _viewModel.removeFile(filePath),
            icon: Icon(
              Icons.close,
              size: 20 * scale,
              color: const Color(0xFF222831),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildAcronymSpans(String text, double scale) {
    final acronymChars = {'S', 'P', 'A', 'D', 'E'};
    final spans = <TextSpan>[];
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final isAcronymChar =
          acronymChars.contains(char) && (i == 0 || text[i - 1] == ' ');

      spans.add(
        TextSpan(
          text: char,
          style: TextStyle(
            decoration: isAcronymChar ? TextDecoration.underline : null,
            decorationThickness: 1,
          ),
        ),
      );
    }
    return spans;
  }
}
