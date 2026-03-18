import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

import 'package:vaarta_app/Config/Constants.dart';
import 'package:vaarta_app/Config/WebSocket.dart';
import 'package:vaarta_app/Data/AccessTokenGenerator.dart';
import 'package:vaarta_app/MediaChat/VideoPreview.dart';
import 'package:vaarta_app/MediaChat/VideoPreviewPlayPause.dart';
import 'package:vaarta_app/Providers/FriendProvider.dart';
import 'package:dio/dio.dart';

class Selectedmediapreviewpage extends StatefulWidget {
  final FilePickerResult selectedFiles;

  const Selectedmediapreviewpage({
    super.key,
    required this.selectedFiles,
  });

  @override
  State<Selectedmediapreviewpage> createState() =>
      _SelectedmediapreviewpageState();
}

class _SelectedmediapreviewpageState extends State<Selectedmediapreviewpage> {
  final ValueNotifier<int> showIndex = ValueNotifier(0);
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  bool isSending = false;
  double uploadProgress = 0.0; // from 0.0 to 1.0

  @override
  void dispose() {
    showIndex.dispose();
    super.dispose();
  }

  // Future<void> sendMediaMessage() async {
  //   final friend = Provider.of<FriendProvider>(context, listen: false).friend;
  //   if (friend?.id == null || widget.selectedFiles.files.isEmpty) return;
  //
  //   setState(() => isSending = true);
  //
  //   final uri = Uri.parse("${ApiConstant.baseUrl}/message/send-media");
  //   String? token = await storage.read(key: "access_token");
  //   if (token == null) return;
  //
  //   Future<http.StreamedResponse> _send(String token) async {
  //     final request = http.MultipartRequest("POST", uri);
  //
  //     request.headers["Authorization"] = "Bearer $token";
  //     request.headers["Accept"] = "application/json";
  //
  //     request.fields.addAll({
  //       "receiverId": friend!.id.toString(),
  //       "messageType": "media",
  //     });
  //
  //     for (final file in widget.selectedFiles.files) {
  //       if (file.path != null) {
  //         request.files.add(
  //           await http.MultipartFile.fromPath(
  //             "files",
  //             file.path!,
  //             filename: file.name,
  //           ),
  //         );
  //       }
  //     }
  //
  //     return await request.send();
  //   }
  //
  //   try {
  //     var response = await _send(token);
  //     // 🔁 Refresh token if needed
  //     if (response.statusCode == 401) {
  //       final refreshed = await accessTokenGenerator(context);
  //       if (!refreshed) return;
  //
  //       token = await storage.read(key: "access_token");
  //       if (token == null) return;
  //
  //       response = await _send(token);
  //     }
  //
  //     if (response.statusCode == 200) {
  //       final body = await response.stream.bytesToString();
  //       final decoded = jsonDecode(body);
  //       if (decoded["data"] != null) {
  //         for (var msg in decoded["data"]) {
  //           // 🔹 Send over WebSocket
  //           SocketService.instance.send({
  //             "type": "SEND_MEDIA",
  //             "from": msg["senderId"],
  //             "to": msg["receiverId"],
  //             "_id":msg["_id"],
  //             "receiverId": msg["receiverId"],
  //             "messageType": msg["messageType"],
  //             "messageText": msg["messageText"],
  //             "messageUrl": msg["messageUrl"],
  //             "data": msg,
  //           });
  //         }
  //       }
  //
  //       Navigator.pop(context);
  //     } else {
  //       final body = await response.stream.bytesToString();
  //       debugPrint("Upload failed: ${response.statusCode} $body");
  //     }
  //   } catch (e) {
  //     debugPrint("Media send error: $e");
  //   } finally {
  //     if (mounted) setState(() => isSending = false);
  //   }
  // }

  Future<void> sendMediaMessage() async {
    final friend = Provider.of<FriendProvider>(context, listen: false).friend;
    if (friend?.id == null || widget.selectedFiles.files.isEmpty) return;

    setState(() {
      isSending = true;
      uploadProgress = 0.0; // make sure you have this in your state
    });

    final dio = Dio();
    String? token = await storage.read(key: "access_token");
    if (token == null) return;

    // Internal function to send files
    Future<Response> _send(String token) async {
      FormData formData = FormData.fromMap({
        "receiverId": friend!.id.toString(),
        "messageType": "media",
        "files": await Future.wait(
          widget.selectedFiles.files.map((file) async {
            return await MultipartFile.fromFile(
              file.path!,
              filename: file.name,
            );
          }),
        ),
      });

      return dio.post(
        "${ApiConstant.baseUrl}/message/send-media",
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        ),
        onSendProgress: (sent, total) {
          if (total != -1) {
            double progress = sent / total;
            // Simulate extra processing time
            if (progress == 1.0) progress = 0.95; // hold at 95%
            if (mounted) {
              setState(() => uploadProgress = progress);
            }
          }
        },
      );
    }

    try {
      var response = await _send(token);

      // Refresh token if expired
      if (response.statusCode == 401) {
        final refreshed = await accessTokenGenerator(context);
        if (!refreshed) return;

        token = await storage.read(key: "access_token");
        if (token == null) return;

        response = await _send(token);
      }

      if (response.statusCode == 200) {
        final decoded = response.data;
        if (decoded["data"] != null) {
          for (var msg in decoded["data"]) {
            // Send over WebSocket
            SocketService.instance.send({
              "type": "SEND_MEDIA",
              "from": msg["senderId"],
              "to": msg["receiverId"],
              "_id": msg["_id"],
              "receiverId": msg["receiverId"],
              "messageType": msg["messageType"],
              "messageText": msg["messageText"],
              "messageUrl": msg["messageUrl"],
              "data": msg,
            });
          }
        }
        Navigator.pop(context);
      } else {
        debugPrint("Upload failed: ${response.statusCode} ${response.data}");
      }
    } catch (e) {
      debugPrint("Media send error: $e");
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  bool _isImage(String ext) =>
      ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);

  bool _isVideo(String ext) =>
      ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xff09090e),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Send media",
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              // 🔍 MAIN PREVIEW
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: showIndex,
                  builder: (context, index, _) {
                    final file = widget.selectedFiles.files[index];
                    final ext = file.extension?.toLowerCase() ?? '';

                    return Center(
                      child: _isImage(ext)
                          ? PhotoView(
                        imageProvider: FileImage(File(file.path!)),
                        backgroundDecoration:
                        const BoxDecoration(color: Colors.black),
                      )
                          : Videopreviewplaypause(path: file.path!),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // 🖼 THUMBNAILS
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.selectedFiles.files.length,
                  itemBuilder: (context, index) {
                    final file = widget.selectedFiles.files[index];
                    final ext = file.extension?.toLowerCase() ?? '';

                    return Padding(
                      padding: const EdgeInsets.all(6),
                      child: GestureDetector(
                        onTap: () => showIndex.value = index,
                        child: _isImage(ext)
                            ? Image.file(
                          File(file.path!),
                          width: 70,
                          fit: BoxFit.cover,
                        )
                            : Videopreview(path: file.path!),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 15),

              // 🚀 SEND BUTTON WITH PROGRESS
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: isSending ? null : sendMediaMessage,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: isSending
                      ? UploadProgressCircle(progress: uploadProgress)
                      : Text(
                    "Send ${widget.selectedFiles.files.length} files",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadProgressCircle extends StatelessWidget {
  final double progress;

  const UploadProgressCircle({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.black,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
          ),
          Text(
            "${(progress * 100).toInt()}%",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }
}