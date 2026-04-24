import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'sidebar_view.dart';
import 'plot_data_view.dart';
import 'linear_relationship_view.dart';
import 'ei_relationship_view.dart';
import '../shared/backend_status.dart';
import '../viewModel/import_view_model.dart';

class RawDataView extends StatefulWidget {
  const RawDataView({
    super.key,
    required this.backendStatusStream,
    required this.viewModel,
  });

  final Stream<BackendStatus> backendStatusStream;
  final ImportViewModel viewModel;

  @override
  State<RawDataView> createState() => _RawDataViewState();
}

class _RawDataViewState extends State<RawDataView> {
  String? _selectedRawPlotFilePath;

  Future<void> _loadExistingJson() async {
    await widget.viewModel.pickAnalysisConfigFile();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _buildRawPlots() async {
    await widget.viewModel.buildRawChannelPlots(
      abfFilePath: _selectedRawPlotFilePath,
    );
    if (mounted) {
      setState(() {});
    }
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
              final selectedRawPlotFilePath = _resolveSelectedRawPlotFilePath(viewModel.selectedFilePaths);
              final channelOptions = viewModel.availableChannelIndices;
              final hasChannelOptions = channelOptions.isNotEmpty;

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
                      onUploadFilesTap: () => Navigator.of(context).popUntil(
                        (route) => route.isFirst,
                      ),
                      rawDataEnabled: true,
                      rawDataActive: true,
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
                      linearRelationshipEnabled: viewModel.hasEnabledDownstreamTabs,
                      eiRelationshipEnabled: viewModel.hasEnabledDownstreamTabs,
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
                    ),
                    Positioned(
                      left: 650 * scale,
                      top: 56 * scale,
                      right: 40 * scale,
                      bottom: 24 * scale,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Raw Data Flow',
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
                            SizedBox(height: 12 * scale),
                            _card(
                              scale,
                              title: 'Load JSON Configuration (Optional)',
                              subtitle:
                                  'Optional: load JSON first to prefill channel, sweeps, window, and colors.',
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _loadExistingJson,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          width: 5 * scale,
                                          color: const Color(0xFFEEEEEE),
                                        ),
                                      ),
                                      child: Text(
                                        'Load JSON',
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
                                    child: Text(
                                      viewModel.analysisConfigPath == null
                                          ? 'No JSON file loaded'
                                          : p.basename(viewModel.analysisConfigPath!),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13 * scale,
                                        color: const Color(0xFF222831),
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12 * scale),
                            _card(
                              scale,
                              title: 'ABF Header info',
                              subtitle: 'Output the header infomation of the ABF files.',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: viewModel.hasSelectedFiles
                                          ? viewModel.loadRawInfoForSelectedFiles
                                          : null,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF00ADB5),
                                      ),
                                      child: Text(
                                        viewModel.isLoadingRawInfo
                                            ? 'Loading ABF info...'
                                            : 'Refresh ABF Info',
                                        style: TextStyle(
                                          color: const Color(0xFF222831),
                                          fontSize: 14 * scale,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (viewModel.rawInfoError != null) ...[
                                    SizedBox(height: 8 * scale),
                                    Text(
                                      viewModel.rawInfoError!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 12 * scale,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                  if (viewModel.isLoadingRawInfo) ...[
                                    SizedBox(height: 8 * scale),
                                    const LinearProgressIndicator(),
                                  ],
                                  if (viewModel.rawInfoByFilePath.isNotEmpty) ...[
                                    SizedBox(height: 8 * scale),
                                    SizedBox(
                                      height: 230 * scale,
                                      child: ListView(
                                        children: viewModel.rawInfoByFilePath.entries.map((entry) {
                                          return Container(
                                            margin: EdgeInsets.only(bottom: 8 * scale),
                                            padding: EdgeInsets.all(9 * scale),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF4FBFC),
                                              border: Border.all(color: const Color(0xFFBDEBED)),
                                              borderRadius: BorderRadius.circular(10 * scale),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p.basename(entry.key),
                                                  style: TextStyle(
                                                    color: const Color(0xFF222831),
                                                    fontSize: 12 * scale,
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                SizedBox(height: 6 * scale),
                                                SelectableText(
                                                  entry.value,
                                                  style: TextStyle(
                                                    color: const Color(0xFF222831),
                                                    fontSize: 11 * scale,
                                                    fontFamily: 'Inter',
                                                    height: 1.24,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: 12 * scale),
                            _card(
                              scale,
                              title: 'Channel + Sweeps -> New Plot',
                              subtitle:
                                  'Map channels to clamp/membrane/stimuli and uncheck sweeps you do not want to use.',
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _channelDropdown(
                                          key: ValueKey('clamp-${channelOptions.join(',')}-${viewModel.clampChannel}'),
                                          labelText: 'Clamp Channel',
                                          value: hasChannelOptions ? viewModel.clampChannel : null,
                                          channelOptions: channelOptions,
                                          enabled: hasChannelOptions,
                                          onChanged: viewModel.setClampChannel,
                                        ),
                                      ),
                                      SizedBox(width: 10 * scale),
                                      Expanded(
                                        child: _channelDropdown(
                                          key: ValueKey('membrane-${channelOptions.join(',')}-${viewModel.membraneChannel}'),
                                          labelText: 'Membrane Channel',
                                          value: hasChannelOptions ? viewModel.membraneChannel : null,
                                          channelOptions: channelOptions,
                                          enabled: hasChannelOptions,
                                          onChanged: viewModel.setMembraneChannel,
                                        ),
                                      ),
                                      SizedBox(width: 10 * scale),
                                      Expanded(
                                        child: _channelDropdown(
                                          key: ValueKey('stimuli-${channelOptions.join(',')}-${viewModel.stimuliChannel}'),
                                          labelText: 'Stimuli Channel',
                                          value: hasChannelOptions ? viewModel.stimuliChannel : null,
                                          channelOptions: channelOptions,
                                          enabled: hasChannelOptions,
                                          onChanged: viewModel.setStimuliChannel,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!hasChannelOptions) ...[
                                    SizedBox(height: 8 * scale),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Load ABF info first to detect available channels.',
                                        style: TextStyle(
                                          fontSize: 12 * scale,
                                          color: const Color(0xFF666E77),
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 10 * scale),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(10 * scale),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sweeps (uncheck to exclude)',
                                          style: TextStyle(
                                            fontSize: 13 * scale,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 8 * scale),
                                        if (viewModel.availableSweepIndices.isEmpty)
                                          Text(
                                            'Load ABF info first to list sweeps.',
                                            style: TextStyle(
                                              fontSize: 12 * scale,
                                              color: const Color(0xFF666E77),
                                              fontFamily: 'Inter',
                                            ),
                                          )
                                        else
                                          SizedBox(
                                            height: 140 * scale,
                                            child: ListView(
                                              children: viewModel.availableSweepIndices.map((sweep) {
                                                final checked = viewModel.selectedSweepTokens
                                                    .contains(sweep.toString());
                                                return CheckboxListTile(
                                                  contentPadding: EdgeInsets.zero,
                                                  dense: true,
                                                  title: Text('Sweep $sweep'),
                                                  value: checked,
                                                  onChanged: (value) {
                                                    viewModel.toggleSweepSelection(
                                                      sweep,
                                                      value ?? false,
                                                    );
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12 * scale),
                            _card(
                              scale,
                              title: 'Choose File for Test Plotting',
                              subtitle: 'Select which ABF file to use when generating the raw plots below.',
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedRawPlotFilePath,
                                dropdownColor: Colors.white,
                                decoration: const InputDecoration(
                                  labelText: 'ABF File',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF00ADB5)),
                                  ),
                                ),
                                items: viewModel.selectedFilePaths
                                    .map(
                                      (filePath) => DropdownMenuItem<String>(
                                        value: filePath,
                                        child: Text(
                                          p.basename(filePath),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: viewModel.selectedFilePaths.isEmpty
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _selectedRawPlotFilePath = value;
                                        });
                                      },
                              ),
                            ),
                            SizedBox(height: 14 * scale),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: viewModel.hasSelectedFiles && viewModel.selectedSweepTokens.isNotEmpty
                                    ? _buildRawPlots
                                    : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF00ADB5),
                                ),
                                child: Text(
                                  viewModel.isLoadingRawPlots ? 'Plotting raw data...' : 'Plot Raw Data',
                                  style: TextStyle(
                                    color: const Color(0xFF222831),
                                    fontSize: 14 * scale,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            if (viewModel.rawPlotError != null) ...[
                              SizedBox(height: 8 * scale),
                              Text(
                                viewModel.rawPlotError!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12 * scale,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                            if (viewModel.isLoadingRawPlots) ...[
                              SizedBox(height: 8 * scale),
                              const LinearProgressIndicator(),
                            ],
                            if (viewModel.hasRawPlots) ...[
                              SizedBox(height: 12 * scale),
                              _rawPlotSection(
                                scale,
                                title: 'Clamp Channel Plot',
                                channel: viewModel.clampChannel,
                                plotPath: viewModel.rawPlotPathForChannel(viewModel.clampChannel),
                              ),
                              SizedBox(height: 10 * scale),
                              _rawPlotSection(
                                scale,
                                title: 'Membrane Channel Plot',
                                channel: viewModel.membraneChannel,
                                plotPath: viewModel.rawPlotPathForChannel(viewModel.membraneChannel),
                              ),
                              SizedBox(height: 10 * scale),
                              _rawPlotSection(
                                scale,
                                title: 'Stimuli Channel Plot',
                                channel: viewModel.stimuliChannel,
                                plotPath: viewModel.rawPlotPathForChannel(viewModel.stimuliChannel),
                              ),
                            ],
                            SizedBox(height: 12 * scale),
                            _card(
                              scale,
                              title: 'Next Step',
                              subtitle:
                                  'After channels and sweeps are set, continue to Plot Data for preview and plot settings.',
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: viewModel.hasLoadedRawInfo
                                      ? () => Navigator.of(context).push(
                                            PageRouteBuilder(
                                              pageBuilder: (_, _, _) => PlotDataView(
                                                backendStatusStream: widget.backendStatusStream,
                                                viewModel: viewModel,
                                              ),
                                              transitionsBuilder: (_, _, _, child) => child,
                                              transitionDuration: Duration.zero,
                                              reverseTransitionDuration: Duration.zero,
                                            ),
                                          )
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF00ADB5),
                                  ),
                                  child: Text(
                                    'Go To Plot Data',
                                    style: TextStyle(
                                      color: const Color(0xFF222831),
                                      fontSize: 14 * scale,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _channelDropdown({
    required Key key,
    required String labelText,
    required int? value,
    required List<int> channelOptions,
    required bool enabled,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      key: key,
      initialValue: value,
      dropdownColor: Colors.white,
      focusColor: const Color(0xFF00ADB5),
      decoration: InputDecoration(
        labelText: labelText,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF00ADB5)),
        ),
      ),
      items: channelOptions
          .map(
            (channel) => DropdownMenuItem<int>(
              value: channel,
              child: Text('Channel $channel'),
            ),
          )
          .toList(),
      onChanged: !enabled
          ? null
          : (selected) {
              if (selected == null) {
                return;
              }
              onChanged(selected);
            },
    );
  }

  String? _resolveSelectedRawPlotFilePath(List<String> fileOptions) {
    if (fileOptions.isEmpty) {
      return null;
    }

    final current = _selectedRawPlotFilePath;
    if (current != null && fileOptions.contains(current)) {
      return current;
    }

    return fileOptions.first;
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

  Widget _rawPlotSection(
    double scale, {
    required String title,
    required int channel,
    required String? plotPath,
  }) {
    if (plotPath == null || plotPath.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF00ADB5)),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (Channel $channel)',
            style: TextStyle(
              color: const Color(0xFF222831),
              fontSize: 14 * scale,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8 * scale),
          Image.file(
            File(plotPath),
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
