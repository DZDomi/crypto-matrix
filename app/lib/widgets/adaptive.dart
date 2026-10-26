import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Small set of widgets that render with Cupertino widgets on iOS and with
/// Material widgets on every other platform.
///
/// Flutter already ships adaptive variants for some widgets, which are used
/// directly instead: [AlertDialog.adaptive], [showAdaptiveDialog],
/// [Slider.adaptive] and [CircularProgressIndicator.adaptive].

bool get isCupertino =>
    defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

class AdaptiveAppBar {
  final Widget? title;
  final List<Widget>? trailingActions;
  final bool automaticallyImplyLeading;

  const AdaptiveAppBar({this.title, this.trailingActions, this.automaticallyImplyLeading = true});

  PreferredSizeWidget _buildMaterial() {
    return AppBar(
      title: title,
      actions: trailingActions,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  ObstructingPreferredSizeWidget _buildCupertino() {
    final actions = trailingActions;
    return CupertinoNavigationBar(
      middle: title,
      automaticallyImplyLeading: automaticallyImplyLeading,
      trailing: actions == null || actions.isEmpty
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: actions,
            ),
    );
  }
}

class AdaptiveScaffold extends StatelessWidget {
  final AdaptiveAppBar? appBar;
  final Widget body;
  final Color? backgroundColor;

  const AdaptiveScaffold({super.key, this.appBar, required this.body, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoPageScaffold(
        navigationBar: appBar?._buildCupertino(),
        backgroundColor: backgroundColor,
        child: body,
      );
    }
    return Scaffold(
      appBar: appBar?._buildMaterial(),
      backgroundColor: backgroundColor,
      body: body,
    );
  }
}

class AdaptiveIconButton extends StatelessWidget {
  final Widget materialIcon;
  final Widget cupertinoIcon;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;

  const AdaptiveIconButton({
    super.key,
    required this.materialIcon,
    required this.cupertinoIcon,
    this.onPressed,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoButton(padding: padding, onPressed: onPressed, child: cupertinoIcon);
    }
    return IconButton(padding: padding, onPressed: onPressed, icon: materialIcon);
  }
}

class AdaptiveTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const AdaptiveTextButton({super.key, required this.child, this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoButton(onPressed: onPressed, child: child);
    }
    return TextButton(onPressed: onPressed, child: child);
  }
}

/// Action button for [AlertDialog.adaptive]
class AdaptiveDialogAction extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const AdaptiveDialogAction({super.key, required this.child, this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoDialogAction(onPressed: onPressed, child: child);
    }
    return TextButton(onPressed: onPressed, child: child);
  }
}

class AdaptiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final bool obscureText;

  const AdaptiveTextField({super.key, this.controller, this.obscureText = false});

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoTextField(controller: controller, obscureText: obscureText);
    }
    return TextField(controller: controller, obscureText: obscureText);
  }
}

PageRoute<T> adaptivePageRoute<T>({required WidgetBuilder builder}) {
  if (isCupertino) {
    return CupertinoPageRoute<T>(builder: builder);
  }
  return MaterialPageRoute<T>(builder: builder);
}

class AdaptiveIcons {
  static IconData get brightness => isCupertino ? CupertinoIcons.brightness : Icons.brightness_low;

  static IconData get brightnessSolid => isCupertino ? CupertinoIcons.brightness_solid : Icons.brightness_high;
}
