import 'dart:io';
import 'package:flutter/cupertino.dart';

class FullScreenImage extends StatelessWidget {
  final String imagePath;
  const FullScreenImage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('图片预览'),
        trailing: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.xmark),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: InteractiveViewer(
            child: Image.file(File(imagePath)),
          ),
        ),
      ),
    );
  }
}
