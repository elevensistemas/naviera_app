import 'package:flutter/material.dart';
import 'sbs_camera_player_stub.dart'
    if (dart.library.html) 'sbs_camera_player_web.dart';

enum CameraPlayerStatus {
  loading,
  playing,
  error,
}

class SBSCameraPlayer extends StatelessWidget {
  final String url;
  final VoidCallback? onRetry;
  final ValueChanged<CameraPlayerStatus>? onStatusChanged;
  final String? vesselName;

  const SBSCameraPlayer({
    super.key,
    required this.url,
    this.onRetry,
    this.onStatusChanged,
    this.vesselName,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B1120),
            borderRadius: BorderRadius.circular(12),
          ),
          child: buildPlatformPlayer(
            context,
            url,
            onRetry: onRetry,
            onStatusChanged: onStatusChanged,
            vesselName: vesselName,
          ),
        ),
      ),
    );
  }
}

