import 'package:flutter/material.dart';

import '../shared/backend_status.dart';

Widget _buildStatusIndicator(BackendStatus status, double scale) {
  final statusMap = {
    BackendStatus.ready: (
      label: 'Python Backend Ready',
      color: const Color(0xFF0CFF00),
      opacity: 1.0,
    ),
    BackendStatus.error: (
      label: 'Python Backend Error',
      color: const Color(0xFFFF0000),
      opacity: 1.0,
    ),
    BackendStatus.computing: (
      label: 'Python Backend Computing',
      color: const Color(0xFF00D4FF),
      opacity: 0.3,
    ),
    BackendStatus.initializing: (
      label: 'Python Backend Initializing',
      color: const Color(0xFFFFFF00),
      opacity: 1.0,
    ),
  };

  final config = statusMap[status]!;

  return Container(
    margin: EdgeInsets.all(16 * scale),
    padding: EdgeInsets.all(12 * scale),
    decoration: BoxDecoration(
      color: const Color(0x1900ADB5),
      borderRadius: BorderRadius.circular(12 * scale),
    ),
    child: Row(
      children: [
        Container(
          width: 16 * scale,
          height: 16 * scale,
          decoration: BoxDecoration(
            color: config.color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 12 * scale),
        Opacity(
          opacity: config.opacity,
          child: Text(
            config.label,
            style: TextStyle(fontSize: 14 * scale),
          ),
        ),
      ],
    ),
  );
}

class SideBar extends StatelessWidget {
  const SideBar({
    Key? key,
    required this.backendStatusStream,
    required this.scale,
    this.uploadFilesActive = true,
    this.onUploadFilesTap,
    this.rawDataEnabled = false,
    this.rawDataActive = false,
    this.onRawDataTap,
    this.plotDataEnabled = false,
    this.plotDataActive = false,
    this.onPlotDataTap,
    this.linearRelationshipEnabled = false,
    this.linearRelationshipActive = false,
    this.onLinearRelationshipTap,
    this.eiRelationshipEnabled = false,
    this.eiRelationshipActive = false,
    this.onEiRelationshipTap,
  }) : super(key: key);

  final Stream<BackendStatus> backendStatusStream;
  final double scale;
  final bool uploadFilesActive;
  final VoidCallback? onUploadFilesTap;
  final bool rawDataEnabled;
  final bool rawDataActive;
  final VoidCallback? onRawDataTap;
  final bool plotDataEnabled;
  final bool plotDataActive;
  final VoidCallback? onPlotDataTap;
  final bool linearRelationshipEnabled;
  final bool linearRelationshipActive;
  final VoidCallback? onLinearRelationshipTap;
  final bool eiRelationshipEnabled;
  final bool eiRelationshipActive;
  final VoidCallback? onEiRelationshipTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500 * scale,
      color: Colors.white,
      child: Stack(
        children: [
          // Right border
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFF393E46)),
                ),
              ),
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200 * scale,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF393E46)),
                ),
              ),
            ),
          ),

          // Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 125 * scale,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF393E46)),
                ),
              ),
            ),
          ),

          // Logo
          Positioned(
            left: 25 * scale,
            top: 18 * scale,
            child: Image.asset(
              "assets/images/logo.png",
              width: 200 * scale,
              height: 164 * scale,
              fit: BoxFit.cover,
            ),
          ),

          // Title
          Positioned(
            left: 272 * scale,
            top: 71 * scale,
            child: Text(
              'S.P.A.D.E',
              style: TextStyle(
                color: const Color(0xFF222831),
                fontSize: 48 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Navigation
          _navItem(
            225,
            'Upload Files',
            scale,
            active: uploadFilesActive,
            onTap: onUploadFilesTap,
          ),
          _navItem(
            350,
            'Raw Data',
            scale,
            active: rawDataActive,
            enabled: rawDataEnabled,
            onTap: rawDataEnabled ? onRawDataTap : null,
          ),
          _navItem(
            465,
            'Plot Data',
            scale,
            active: plotDataActive,
            enabled: plotDataEnabled,
            onTap: plotDataEnabled ? onPlotDataTap : null,
          ),
          _navItem(
            580,
            'Linear Relationship',
            scale,
            active: linearRelationshipActive,
            enabled: linearRelationshipEnabled,
            onTap: linearRelationshipEnabled ? onLinearRelationshipTap : null,
          ),
          _navItem(
            695,
            'E/I Relationship',
            scale,
            active: eiRelationshipActive,
            enabled: eiRelationshipEnabled,
            onTap: eiRelationshipEnabled ? onEiRelationshipTap : null,
          ),

          // Status
          Positioned(
            left: 55 * scale,
            right: 55 * scale,
            bottom: 20 * scale,
            child: StreamBuilder<BackendStatus>(
              stream: backendStatusStream,
              initialData: BackendStatus.initializing,
              builder: (context, snapshot) {
                final status =
                    snapshot.data ?? BackendStatus.initializing;
                return _buildStatusIndicator(status, scale);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    double top,
    String text,
    double scale, {
    bool active = false,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return Positioned(
      left: 25 * scale,
      top: top * scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15 * scale),
          onTap: enabled ? onTap : null,
          child: Container(
            width: 450 * scale,
            height: 100 * scale,
            decoration: BoxDecoration(
              color: active ? const Color(0x3F00ADB5) : null,
              borderRadius: BorderRadius.circular(15 * scale),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                color: active
                    ? const Color(0xFF222831)
                    : enabled
                        ? const Color(0x7F222831)
                        : const Color(0x40222831),
                fontSize: 24 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}