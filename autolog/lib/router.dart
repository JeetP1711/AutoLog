// TODO: This is a temporary placeholder router. It will be replaced in task 10
// with the full GoRouter configuration including all app routes.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder [GoRouter] configuration.
///
/// Routes `/` to a minimal scaffold so the app compiles and runs.
/// This will be replaced with the full route tree in task 10.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text('AutoLog'),
        ),
      ),
    ),
  ],
);
