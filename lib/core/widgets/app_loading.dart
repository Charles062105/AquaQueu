import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    this.message,
    this.isFullScreen = false,
    super.key,
  });

  const AppLoadingIndicator.fullScreen({this.message, super.key})
    : isFullScreen = true;

  final String? message;
  final bool isFullScreen;

  @override
  Widget build(BuildContext context) {
    final indicator = CircularProgressIndicator(
      color: Theme.of(context).colorScheme.primary,
    );

    final content = message == null
        ? indicator
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              indicator,
              const SizedBox(height: 16),
              Text(message!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          );
    if (!isFullScreen) {
      return content;
    }

    return Center(child: content);
  }
}

class AppLoading extends AppLoadingIndicator {
  const AppLoading({super.message, super.key});
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
