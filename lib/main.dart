import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

part 'asset_taxonomy.dart';
part 'asset_data.dart';
part 'asset_operations.dart';
part 'asset_assignment_models.dart';
part 'asset_employee_operations.dart';
part 'asset_assignment_operations.dart';
part 'asset_assignment_pdf.dart';
part 'asset_employee_ui.dart';
part 'asset_employee_forms.dart';
part 'asset_assigned_ui.dart';
part 'asset_assignment_form.dart';
part 'asset_assignment_detail.dart';
part 'asset_assignment_return.dart';
part 'asset_location_models.dart';
part 'asset_location_operations.dart';
part 'asset_location_ui.dart';
part 'asset_lifecycle_operations.dart';
part 'asset_lifecycle_ui.dart';
part 'asset_navigation.dart';
part 'asset_v4_catalog.dart';
part 'asset_v4_master.dart';
part 'asset_v4_history.dart';
part 'asset_v4_registration.dart';
part 'asset_v4_detail.dart';
part 'asset_v4_modal.dart';
part 'asset_v4_tables.dart';
part 'asset_v4_actions.dart';
part 'asset_ui.dart';
part 'asset_features_ui.dart';

void main() => runApp(const AssetApp());

const navy = Color(0xFF142D4E);
const bg = Color(0xFFF4F7FB);
const ink = Color(0xFF172C47);
const muted = Color(0xFF718199);
const border = Color(0xFFE3EAF2);
const blue = Color(0xFF2766A2);
const danger = Color(0xFFC04D53);
const amber = Color(0xFFB97813);

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
