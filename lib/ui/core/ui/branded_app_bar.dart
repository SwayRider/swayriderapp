import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../themes/colors.dart';

class BrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandedAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.black,
      centerTitle: true,
      title: SvgPicture.asset(
        'assets/branding/swayrider-banner-dark.svg',
        height: 32,
      ),
    );
  }
}
