import 'package:flutter/material.dart';
import 'training_course_images_data.dart';

class TrainingThumbnailWidget extends StatelessWidget {
  final int courseId;
  final double width;
  final double height;

  const TrainingThumbnailWidget({
    super.key,
    required this.courseId,
    this.width = 110,
    this.height = 65,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = getCourseImageBytes(courseId);

    Widget imageContent;
    if (bytes != null && bytes.isNotEmpty) {
      imageContent = Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (ctx, err, st) {
          return Image.asset(
            'assets/images/courses/ncs_course_icon.png',
            width: width,
            height: height,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (c, e, s) => Container(
              color: Colors.white,
              child: const Icon(Icons.school, size: 36, color: Color(0xFF0055B8)),
            ),
          );
        },
      );
    } else {
      imageContent = Image.asset(
        'assets/images/courses/ncs_course_icon.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (c, e, s) => Container(
          color: Colors.white,
          child: const Icon(Icons.school, size: 36, color: Color(0xFF0055B8)),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
          child: imageContent,
        ),
      ),
    );
  }
}
