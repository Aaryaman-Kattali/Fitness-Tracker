package com.personal.fitness_tracker

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * FlutterFragmentActivity rather than FlutterActivity because the `health`
 * plugin requests Health Connect permissions through
 * `registerForActivityResult`, which needs a ComponentActivity. With a plain
 * FlutterActivity the permission sheet never opens and the request fails at
 * the cast.
 */
class MainActivity : FlutterFragmentActivity()
