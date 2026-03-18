import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioMessage extends StatefulWidget {
  final String url;

  const AudioMessage({super.key, required this.url});

  @override
  State<AudioMessage> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _player.setUrl(widget.url);

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) =>
      d.toString().split('.').first.padLeft(8, '0');

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// Play / Pause
        StreamBuilder<bool>(
          stream: _player.playingStream,
          builder: (context, snapshot) {
            final playing = snapshot.data ?? false;
            return IconButton(
              icon: Icon(
                playing ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                playing ? _player.pause() : _player.play();
              },
            );
          },
        ),

        /// Progress bar
        StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final duration = _player.duration ?? Duration.zero;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 150,
                  child: Slider(
                    value: position.inMilliseconds.toDouble(),
                    max: duration.inMilliseconds.toDouble() == 0
                        ? 1
                        : duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      _player.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                Text(
                  "${_format(position)} / ${_format(duration)}",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
