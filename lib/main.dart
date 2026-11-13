import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';

part 'asset_taxonomy.dart';
part 'asset_data.dart';
part 'asset_ui.dart';
part 'asset_features_ui.dart';

void main() => runApp(const AssetApp());

const navy = Color(0xFF142D4E);
const bg = Color(0xFFF4F7FB);
const uuid = Uuid();

class AssetApp extends StatefulWidget {
  const AssetApp({super.key});
  @override State<AssetApp> createState() => _AssetAppState();
}
class _AssetAppState extends State<AssetApp> {
  final store = AssetStore();
  @override void initState() { super.initState(); store.initialize(); }
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Manajemen Aset UD. LUTHFI', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1464A4)),
      cardTheme: CardThemeData(elevation: 0, color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E9F0)))),
      inputDecorationTheme: InputDecorationTheme(isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
    home: AnimatedBuilder(animation: store, builder: (context, child) =>
      store.loaded ? AssetScreen(store: store) : const Scaffold(body: Center(child: CircularProgressIndicator()))),
  );
}
class AssetScreen extends StatefulWidget {
  final AssetStore store;
  const AssetScreen({super.key, required this.store});
  @override State<AssetScreen> createState() => _AssetScreenState();
}
