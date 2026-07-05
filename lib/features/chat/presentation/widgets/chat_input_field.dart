import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
// file_picker removed due to Android build compatibility issues
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/chat_provider.dart';
import '../../../../core/constants/app_colors.dart';

class ChatInputField extends ConsumerStatefulWidget {
  final String otherUserId;

  const ChatInputField({super.key, required this.otherUserId});

  @override
  ConsumerState<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends ConsumerState<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  
  // Audio Recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (value.isNotEmpty) {
      ref.read(chatControllerProvider).setTypingStatus(widget.otherUserId, true);
    }
    
    _debounce = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(chatControllerProvider).setTypingStatus(widget.otherUserId, false);
      }
    });
    setState(() {}); 
  }

  void _sendMessage({String messageType = 'text', File? mediaFile, String? fileName, int? duration, String? text}) {
    final finalText = text ?? _controller.text.trim();
    // Allow sending if there's a media file, even if text is empty
    if (finalText.isEmpty && mediaFile == null) return;
    
    ref.read(chatControllerProvider).sendMessage(
      otherUserId: widget.otherUserId,
      text: finalText.isNotEmpty ? finalText : (messageType == 'image' ? '📷 Photo' : messageType == 'audio' ? '🎤 Voice Message' : '📎 File'),
      messageType: messageType,
      mediaFile: mediaFile,
      fileName: fileName,
      duration: duration,
    );
    
    _controller.clear();
    ref.read(chatControllerProvider).setTypingStatus(widget.otherUserId, false);
    _debounce?.cancel();
    setState(() {});
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 278,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachmentIcon(Icons.insert_drive_file, Colors.indigo, 'Document', _pickDocument),
                _attachmentIcon(Icons.camera_alt, Colors.pink, 'Camera', () => _pickMedia(ImageSource.camera)),
                _attachmentIcon(Icons.image, Colors.purple, 'Gallery', () => _pickMedia(ImageSource.gallery)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachmentIcon(Icons.videocam, Colors.red, 'Video', _pickVideo),
                _attachmentIcon(Icons.headset, Colors.orange, 'Audio', () {}),
                _attachmentIcon(Icons.person, Colors.blue, 'Contact', () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentIcon(IconData icon, Color color, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 5),
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source) async {
    final picker = ImagePicker();
    // Show option to pick image or video
    final XFile? file = await picker.pickImage(
      source: source,
      imageQuality: 70, // Compress image to save bandwidth
    );
    if (file != null) {
      _sendMessage(messageType: 'image', mediaFile: File(file.path));
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
    if (file != null) {
      _sendMessage(messageType: 'video', mediaFile: File(file.path), text: '🎥 Video');
    }
  }

  Future<void> _pickDocument() async {
    // Using image_picker as fallback since file_picker has Android build issues
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      String fileName = file.name;
      _sendMessage(messageType: 'document', mediaFile: File(file.path), fileName: fileName, text: fileName);
    }
  }

  // Audio Recording Handlers
  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      _audioPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: _audioPath!);
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
    });
    if (path != null) {
      // In a real app, calculate actual duration using audioplayers
      _sendMessage(messageType: 'audio', mediaFile: File(path), duration: 0, text: 'Voice Message');
    }
  }

  @override
  Widget build(BuildContext context) {
    final replyingTo = ref.watch(replyingToMessageProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (replyingTo != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.reply, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Replying to message', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                      Text(replyingTo.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ref.read(replyingToMessageProvider.notifier).state = null;
                  },
                )
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: _onTextChanged,
                  decoration: InputDecoration(
                    hintText: _isRecording ? 'Recording...' : 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: _isRecording ? Colors.red.withOpacity(0.1) : AppColors.dividerLight.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.attach_file, color: AppColors.textSecondaryLight),
                          onPressed: _showAttachmentOptions,
                        ),
                        IconButton(
                          icon: Icon(Icons.camera_alt_rounded, color: AppColors.textSecondaryLight),
                          onPressed: () => _pickMedia(ImageSource.camera),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onLongPress: _controller.text.trim().isEmpty ? _startRecording : null,
                onLongPressUp: _controller.text.trim().isEmpty ? _stopRecording : null,
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryColor, AppColors.accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _controller.text.trim().isEmpty ? Icons.mic : Icons.send_rounded,
                      color: _isRecording ? Colors.red.shade100 : Colors.white,
                    ),
                    onPressed: _controller.text.trim().isEmpty ? () {} : () => _sendMessage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
