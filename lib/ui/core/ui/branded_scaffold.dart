import 'package:flutter/material.dart';

import '../themes/dimens.dart';
import 'branded_app_bar.dart';

class BrandedScaffold extends StatelessWidget {
  const BrandedScaffold({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: const BrandedAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Dimens.of(context).edgeInsetsScreenSymetric,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Dimens.maxContentWidth,
              ),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}
