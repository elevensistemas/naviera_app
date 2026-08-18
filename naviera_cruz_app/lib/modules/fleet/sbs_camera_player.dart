import 'package:flutter/material.dart';
import 'sbs_camera_player_stub.dart'
    if (dart.library.html) 'sbs_camera_player_web.dart';

class SBSCameraPlayer extends StatelessWidget {
  final String url;
  const SBSCameraPlayer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: buildPlatformPlayer(context, url),
    );
  }
}
