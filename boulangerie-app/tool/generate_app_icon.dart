// Dessine l'icône de l'appli à partir du pictogramme Material « bakery_dining » (croissant),
// blanc sur la couleur croûte de pain du thème. À relancer seulement si l'icône change :
//
//   flutter test tool/generate_app_icon.dart
//   dart run flutter_launcher_icons
//
// Produit assets/icon/icon.png (icône complète : iOS et anciens Android) et
// assets/icon/icon_foreground.png (premier plan transparent de l'icône adaptative Android).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:boulangerie_app/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 1024;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('génère les images de l\'icône', () async {
    await _loadMaterialIcons();
    await _render('assets/icon/icon.png', withBackground: true, glyphSize: 780);
    // flutter_launcher_icons ajoute une marge de 16 % autour du premier plan adaptatif :
    // pictogramme plus grand ici pour la compenser (il reste dans le cercle visible, ~66 %).
    await _render('assets/icon/icon_foreground.png', withBackground: false, glyphSize: 820);
  });
}

/// Les tests n'ont pas de police d'icônes chargée : on lit celle du SDK Flutter.
Future<void> _loadMaterialIcons() async {
  final engineDir = File(Platform.resolvedExecutable).parent; // <flutter>/bin/cache/artifacts/engine/<plateforme>
  final candidates = [
    if (Platform.environment['FLUTTER_ROOT'] case final root?)
      '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    '${engineDir.parent.parent.path}/material_fonts/materialicons-regular.otf',
  ];
  final path = candidates.firstWhere(
    (candidate) => File(candidate).existsSync(),
    orElse: () => throw StateError('Police MaterialIcons introuvable : $candidates'),
  );

  final bytes = File(path).readAsBytesSync();
  await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

Future<void> _render(String path, {required bool withBackground, required double glyphSize}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  if (withBackground) {
    canvas.drawRect(Rect.fromLTWH(0, 0, _size.toDouble(), _size.toDouble()), Paint()..color = AppColors.crust);
  }

  const icon = Icons.bakery_dining_rounded;
  final glyph = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(fontFamily: icon.fontFamily, fontSize: glyphSize, color: Colors.white),
    ),
  )..layout();
  glyph.paint(canvas, Offset((_size - glyph.width) / 2, (_size - glyph.height) / 2));

  final image = await recorder.endRecording().toImage(_size, _size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}
