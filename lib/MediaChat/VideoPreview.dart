import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class Videopreview extends StatefulWidget {
  final String path; // Local video file path

  const Videopreview({super.key, required this.path});

  @override
  State<Videopreview> createState() => _VideopreviewState();
}

class _VideopreviewState extends State<Videopreview> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Initialize video controller for local file
    _videoController = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        // Pause immediately to just show first frame
        _videoController.pause();
        setState(() {
          _isInitialized = true;
        });
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox(
        width: 80,
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Show first frame
        SizedBox(
          width: 80,
          height: 80,
          child: VideoPlayer(_videoController),
        ),
        // Play icon overlay
        const Icon(Icons.play_circle_fill, size: 30, color: Colors.white),
      ],
    );
  }
}
