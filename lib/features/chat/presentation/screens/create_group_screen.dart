import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../providers/group_provider.dart';
import '../providers/search_provider.dart';
import '../../../../core/constants/app_colors.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  File? _groupImage;
  final List<String> _selectedUserIds = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _groupImage = File(file.path);
      });
    }
  }

  void _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a group name')));
      return;
    }
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least 1 member')));
      return;
    }

    await ref.read(groupControllerProvider.notifier).createGroup(
      _nameController.text.trim(),
      _groupImage,
      _selectedUserIds,
    );

    if (mounted && !ref.read(groupControllerProvider).hasError) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchUsersProvider);
    final groupState = ref.watch(groupControllerProvider);
    final isLoading = groupState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
        actions: [
          if (isLoading)
            const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Colors.white))
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _createGroup),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.dividerLight,
                    backgroundImage: _groupImage != null ? FileImage(_groupImage!) : null,
                    child: _groupImage == null ? const Icon(Icons.camera_alt, color: Colors.grey) : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Group Subject',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(color: AppColors.dividerLight, height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
              ),
              onChanged: (val) {
                ref.read(searchQueryProvider.notifier).state = val;
              },
            ),
          ),
          Expanded(
            child: searchResults.when(
              data: (users) {
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isSelected = _selectedUserIds.contains(user.id);

                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage: user.profilePicUrl.isNotEmpty ? NetworkImage(user.profilePicUrl) : null,
                            child: user.profilePicUrl.isEmpty ? const Icon(Icons.person) : null,
                          ),
                          if (isSelected)
                            const Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(radius: 10, backgroundColor: AppColors.accentColor, child: Icon(Icons.check, size: 12, color: Colors.white)),
                            )
                        ],
                      ),
                      title: Text(user.name),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedUserIds.remove(user.id);
                          } else {
                            _selectedUserIds.add(user.id);
                          }
                        });
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
