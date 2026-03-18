import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class Videopreviewplaypause extends StatefulWidget {
  final String path; // Local file path

  const Videopreviewplaypause({super.key, required this.path});

  @override
  State<Videopreviewplaypause> createState() => _VideopreviewplaypauseState();
}

class _VideopreviewplaypauseState extends State<Videopreviewplaypause> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();

    // Initialize video controller with local file
    _videoController = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        // Seek to start frame
        _videoController.seekTo(Duration.zero);

        // Create Chewie controller
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: false, // NEVER auto play
          looping: false,
          showControls: true, // No controls
          allowFullScreen: false,
          allowMuting: false,
        );

        // Refresh UI
        setState(() {});
      });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController == null || !_videoController.value.isInitialized) {
      return const SizedBox(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Make sure video stays paused
    if (_videoController.value.isPlaying) {
      _videoController.pause();
    }

    return AspectRatio(
      aspectRatio: _videoController.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }
}
