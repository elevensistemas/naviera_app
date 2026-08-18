import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

Widget buildPlatformPlayer(BuildContext context, String url) {
  return SBSMobileCameraPlayer(url: url);
}

class SBSMobileCameraPlayer extends StatefulWidget {
  final String url;
  const SBSMobileCameraPlayer({super.key, required this.url});

  @override
  State<SBSMobileCameraPlayer> createState() => _SBSMobileCameraPlayerState();
}

class _SBSMobileCameraPlayerState extends State<SBSMobileCameraPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoPlayerController.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: false,
        placeholder: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 40),
                  SizedBox(height: 8),
                  Text(
                    "Error al cargar stream SBS",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      );
      setState(() {});
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            "Error: $_errorMessage",
            style: const TextStyle(color: Colors.grey, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_chewieController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Chewie(controller: _chewieController!);
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
