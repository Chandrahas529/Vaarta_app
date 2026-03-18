import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoMessageBubble extends StatefulWidget {
  final String url;

  const VideoMessageBubble({super.key, required this.url});

  @override
  State<VideoMessageBubble> createState() => _VideoMessageBubbleState();
}

class _VideoMessageBubbleState extends State<VideoMessageBubble> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();

    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.url));

    _videoController.initialize().then((_) {
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: false,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    if (_chewieController == null) {
      return const SizedBox(
        height: 280, // match parent container height
        width: 280,  // match parent container width
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRRect(
      child: Container(
        height: 280, // fixed height
        width: 280,  // fixed width
        color: Colors.black,
        child: Chewie(
          controller: _chewieController!,
        ),
      ),
    );
  }
}
