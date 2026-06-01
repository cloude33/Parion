import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../models/family/family_export.dart';

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.member,
    this.size = 40,
    this.showBorder = false,
  });

  final FamilyMember member;
  final double size;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final color = Color(member.colorValue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: Colors.white, width: 2)
            : null,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        member.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

class MemberStack extends StatelessWidget {
  const MemberStack({
    super.key,
    required this.members,
    this.maxVisible = 3,
    this.size = 32,
  });

  final List<FamilyMember> members;
  final int maxVisible;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }
    final visible = members.take(maxVisible).toList();
    final extra = members.length - visible.length;
    return SizedBox(
      width: (visible.length + (extra > 0 ? 1 : 0)) * (size * 0.7) +
          (size * 0.3),
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * (size * 0.7),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: MemberAvatar(
                  member: visible[i],
                  size: size - 4,
                  showBorder: true,
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: visible.length * (size * 0.7),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.onSurface.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extra',
                  style: TextStyle(
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
