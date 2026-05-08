import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: true,
        title: Text('About', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withAlpha(180)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: cs.primary.withAlpha(60), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: const Icon(Icons.auto_graph_rounded, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text(
                'AutoLog',
                style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1, color: cs.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Track Every Mile. Locally.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withAlpha(150),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Version 1.0.3', style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary)),
              ),
              const SizedBox(height: 48),
              Text(
                'AutoLog is a premium, offline-first utility designed for automotive enthusiasts. We believe your vehicle data is personal, which is why everything stays on your device.',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.8, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 64),
              Text(
                '© 2026 AutoLog App',
                style: tt.labelSmall?.copyWith(color: cs.outline, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
