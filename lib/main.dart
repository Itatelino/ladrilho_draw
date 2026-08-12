import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:ui' as ui;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const TileShopApp());
}

/// widget raiz do aplicativo.
class TileShopApp extends StatelessWidget {
  const TileShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cores da Roça',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // fonte Inter para um visual moderno
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 0, 45, 245),
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          elevation: 4,
          shadowColor: Colors.black54,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 0, 26, 255),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      home: const TileShopHomePage(),
    );
  }
}

// --- Modelos de Dados ---

/// dados ladrilho.
class Tile {
  final String id;
  final String name;
  final String svgPath;

  Tile({required this.id, required this.name, required this.svgPath});
}

/// dados item carrinho de compras.
class CartItem {
  final Tile tile;
  final List<Color> layerColors;
  final Color selectedTileColor1;
  final Color selectedTileColor2;
  final Color selectedTileColor3;
  final Color selectedTileColor4;
  final Color selectedBackgroundColor;
  final double width;
  final double height;
  final double totalSqMeters;
  final int quantity;

  CartItem({
    required this.tile,
    required this.layerColors,
    required this.selectedTileColor1,
    required this.selectedTileColor2,
    required this.selectedTileColor3,
    required this.selectedTileColor4,
    required this.selectedBackgroundColor,
    required this.width,
    required this.height,
    required this.totalSqMeters,
    required this.quantity,
  });
}

class _LayerColorSelection {
  final int layerIndex;
  final Color color;

  const _LayerColorSelection({required this.layerIndex, required this.color});
}

class _SvgLayerColorMapper extends ColorMapper {
  final Map<int, Color> replacementBySourceColor;

  const _SvgLayerColorMapper(this.replacementBySourceColor);

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    return replacementBySourceColor[color.value] ?? color;
  }
}

List<Color> _extractColorsFromSvg(String svgContent) {
  final matches = RegExp(
    r'#[0-9a-fA-F]{6,8}',
  ).allMatches(svgContent).map((m) => m.group(0)!).toList();

  final unique = <int>{};
  final result = <Color>[];

  for (final raw in matches) {
    final hex = raw.substring(1);
    final normalized = hex.length == 6 ? 'FF$hex' : hex;
    if (normalized.length != 8) {
      continue;
    }

    final value = int.tryParse(normalized, radix: 16);
    if (value == null || unique.contains(value)) {
      continue;
    }

    unique.add(value);
    result.add(Color(value));
  }

  return result;
}

// --- Componente Visualização Ladrilho ---

/// repete ladrilho numa grade para simulação.
class TilePatternRepeater extends StatelessWidget {
  final Tile tile;
  final Color tileColor1;
  final Color tileColor2;
  final Color tileColor3;
  final Color tileColor4;
  final Color bgColor;
  final double tileDisplaySize;
  final bool isWall; // diferenciar rejunte parede/chão

  const TilePatternRepeater({
    required this.tile,
    required this.tileColor1,
    required this.tileColor2,
    required this.tileColor3,
    required this.tileColor4,
    required this.bgColor,
    this.tileDisplaySize = 40.0,
    this.isWall = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Cor do rejunte
    final Color groutColor = isWall
        // ignore: deprecated_member_use
        ? Colors.black12.withOpacity(0.08)
        // ignore: deprecated_member_use
        : Colors.black12.withOpacity(0.2);

    return Container(
      color: bgColor,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 25,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1.0,
          mainAxisSpacing: isWall ? 0.5 : 1.0,
          crossAxisSpacing: isWall ? 0.5 : 1.0,
        ),
        itemBuilder: (context, index) {
          // P1: Cor principal
          // P3: cor fundo
          // P4: cor borda

          final useP4Border = index % 2 == 0;

          return Container(
            decoration: BoxDecoration(
              // Simula rejunte
              border: Border.all(color: groutColor, width: isWall ? 0.5 : 1.0),
              // Simula borda do ladrilho com P4
              color: tileColor3, // Fundo individual do ladrilho usa P3
            ),
            child: Container(
              margin: EdgeInsets.all(useP4Border ? 2 : 0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: useP4Border ? tileColor4 : tileColor3,
                  width: 1.0,
                ),
              ),
              child: Center(
                // O SVG só pode ter uma cor, usamos P1 para o centro do desenho
                child: SvgPicture.asset(
                  tile.svgPath,
                  width: tileDisplaySize,
                  height: tileDisplaySize,
                  colorFilter: ColorFilter.mode(tileColor1, BlendMode.srcIn),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Painel Inferior de Seleção de Cor ---

/// Lista de sugestões de cores.
final List<Color> _paletteSuggestions = [
  Colors.white,
  Colors.black,
  const Color(0xFFC70039), // Vermelho Bordô
  const Color(0xFF004488), // Azul Marinho
  const Color(0xFF008844), // Verde Floresta
  const Color(0xFFFFA500), // Laranja Cítrico
  const Color(0xFF808080), // Cinza Chumbo
  const Color(0xFFF9E79F), // Creme Claro
  const Color(0xFF5D4037), // Marrom Escuro
  const Color(0xFF6A1B9A), // Roxo
];

/// Painel inferior seleção de cor.
Future<Color?> showColorPickerSheet(
  BuildContext context,
  Color initialColor,
  String title,
) {
  Color tempColor = initialColor;

  return showModalBottomSheet<Color?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecionar $title',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 15),

                // Prévia da cor
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: tempColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      // ignore: deprecated_member_use
                      'HEX: #${tempColor.value.toRadixString(16).substring(2).toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Paletas Sugeridas
                const Text(
                  'Paletas Rápidas:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _paletteSuggestions.length,
                    itemBuilder: (context, index) {
                      final color = _paletteSuggestions[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            tempColor = color;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              // ignore: deprecated_member_use
                              color: tempColor.value == color.value
                                  ? Colors.blue.shade800
                                  : Colors.black12,
                              // ignore: deprecated_member_use
                              width: tempColor.value == color.value ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),

                // Sliders
                ..._buildColorSlider(
                  'Vermelho (R)',
                  // ignore: deprecated_member_use
                  tempColor.red.toDouble(),
                  255.0,
                  Colors.red,
                  (value) {
                    setState(() {
                      tempColor = tempColor.withRed(value.toInt());
                    });
                  },
                ),
                ..._buildColorSlider(
                  'Verde (G)',
                  // ignore: deprecated_member_use
                  tempColor.green.toDouble(),
                  255.0,
                  Colors.green,
                  (value) {
                    setState(() {
                      tempColor = tempColor.withGreen(value.toInt());
                    });
                  },
                ),
                ..._buildColorSlider(
                  'Azul (B)',
                  // ignore: deprecated_member_use
                  tempColor.blue.toDouble(),
                  255.0,
                  Colors.blue,
                  (value) {
                    setState(() {
                      tempColor = tempColor.withBlue(value.toInt());
                    });
                  },
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(tempColor),
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

/// auxiliar construir os sliders de cor.
List<Widget> _buildColorSlider(
  String label,
  double currentValue,
  double maxValue,
  Color activeColor,
  Function(double) onChanged,
) {
  return [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(
          currentValue.toInt().toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
    Slider(
      value: currentValue,
      min: 0,
      max: maxValue,
      divisions: maxValue.toInt(),
      activeColor: activeColor,
      // ignore: deprecated_member_use
      inactiveColor: activeColor.withOpacity(0.3),
      onChanged: onChanged,
    ),
  ];
}

Future<Map<String, List<Color>>?> showMultiColorPickerSheet(
  BuildContext context,
  Map<String, List<Color>> initialColors,
  String title,
) {
  // Faz cópia mutável dos dados iniciais para edição local.
  final Map<String, List<Color>> temp = {
    for (final e in initialColors.entries) e.key: List<Color>.from(e.value),
  };

  return showModalBottomSheet<Map<String, List<Color>>?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
    ),
    builder: (BuildContext ctx) {
      return Padding(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setState) {
            // Auxiliar para adicionar uma nova cor a um detalhe usando o
            // picker existente showColorPickerSheet.
            Future<void> addColor(String part) async {
              final newColor = await showColorPickerSheet(
                ctx,
                Colors.white,
                'Adicionar cor para $part',
              );
              if (newColor != null) {
                setState(() {
                  temp.putIfAbsent(part, () => []).add(newColor);
                });
              }
            }

            // Remove uma cor específica de um detalhe
            void removeColor(String part, int index) {
              setState(() {
                temp[part]?.removeAt(index);
                if (temp[part] != null && temp[part]!.isEmpty) {
                  // Mantemos a chave, mas poderia ser removida se preferir
                }
              });
            }

            // Adiciona um novo detalhe (part name) vazio
            void addDetail() {
              const defaultName = 'Detalhe';
              int i = 1;
              String candidate = defaultName;
              while (temp.containsKey(candidate)) {
                i++;
                candidate = '$defaultName $i';
              }
              setState(() {
                temp[candidate] = [];
              });
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Editar cores: $title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: addDetail,
                      icon: const Icon(Icons.playlist_add),
                      tooltip: 'Adicionar detalhe',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Lista de partes/detalhes
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: temp.entries.map((entry) {
                        final part = entry.key;
                        final colors = entry.value;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      part,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () => addColor(part),
                                          icon: const Icon(Icons.add),
                                          tooltip: 'Adicionar cor',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: List.generate(colors.length, (i) {
                                    final c = colors[i];
                                    // Chip com a cor e opção de remover
                                    return InputChip(
                                      backgroundColor: c,
                                      label: Text(
                                        // ignore: deprecated_member_use
                                        '#${c.value.toRadixString(16).substring(2).toUpperCase()}',
                                      ),
                                      labelStyle: TextStyle(
                                        color:
                                            ThemeData.estimateBrightnessForColor(
                                                  c,
                                                ) ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      onDeleted: () => removeColor(part, i),
                                      onPressed: () async {
                                        // Permitir editar a cor existente
                                        final edited =
                                            await showColorPickerSheet(
                                              ctx,
                                              c,
                                              'Editar cor $part',
                                            );
                                        if (edited != null) {
                                          setState(() {
                                            temp[part]![i] = edited;
                                          });
                                        }
                                      },
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(null),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(temp),
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            );
          },
        ),
      );
    },
  );
}

// --- Home Page (Seleção e Simulação) ---

class TileShopHomePage extends StatefulWidget {
  const TileShopHomePage({super.key});

  @override
  State<TileShopHomePage> createState() => _TileShopHomePageState();
}

class _TileShopHomePageState extends State<TileShopHomePage> {
  final List<Tile> _availableTiles = [
    Tile(id: '1', name: 'Mosaico 1', svgPath: 'assets/tiles/tile1.svg'),
    Tile(id: '2', name: 'Padrão 2', svgPath: 'assets/tiles/tile2.svg'),
    Tile(id: '3', name: 'Arabesco 3', svgPath: 'assets/tiles/tile3.svg'),
    Tile(id: '4', name: 'Hexagonal 4', svgPath: 'assets/tiles/tile4.svg'),
    Tile(id: '5', name: 'Diagonal 5', svgPath: 'assets/tiles/tile5.svg'),
    Tile(id: '6', name: 'Ladrilho 6', svgPath: 'assets/tiles/A1.svg'),
    Tile(id: '7', name: 'Ladrilho 7', svgPath: 'assets/tiles/A2.svg'),
    Tile(id: '8', name: 'Ladrilho 8', svgPath: 'assets/tiles/A3.svg'),
    Tile(id: '9', name: 'Ladrilho 9', svgPath: 'assets/tiles/A4.svg'),
    Tile(id: '10', name: 'Ladrilho 10', svgPath: 'assets/tiles/A5.svg'),
    Tile(id: '11', name: 'Ladrilho 11', svgPath: 'assets/tiles/A6.svg'),
    Tile(id: '12', name: 'Ladrilho 12', svgPath: 'assets/tiles/A7.svg'),
    Tile(id: '13', name: 'Ladrilho 13', svgPath: 'assets/tiles/A8.svg'),
    Tile(id: '14', name: 'Ladrilho 14', svgPath: 'assets/tiles/A9.svg'),
    Tile(id: '15', name: 'Ladrilho 15', svgPath: 'assets/tiles/A10.svg'),
    Tile(id: '16', name: 'Ladrilho 16', svgPath: 'assets/tiles/A11.svg'),
    Tile(id: '17', name: 'Ladrilho 17', svgPath: 'assets/tiles/A12.svg'),
    Tile(id: '18', name: 'Ladrilho 18', svgPath: 'assets/tiles/A13.svg'),
    Tile(id: '19', name: 'Ladrilho 19', svgPath: 'assets/tiles/A14.svg'),
    Tile(id: '20', name: 'Ladrilho 20', svgPath: 'assets/tiles/A15.svg'),
    Tile(id: '21', name: 'Ladrilho 21', svgPath: 'assets/tiles/B16.svg'),
    Tile(id: '22', name: 'Ladrilho 22', svgPath: 'assets/tiles/B17.svg'),
    Tile(id: '23', name: 'Ladrilho 23', svgPath: 'assets/tiles/B18.svg'),
    Tile(id: '24', name: 'Ladrilho 24', svgPath: 'assets/tiles/B19.svg'),
    Tile(id: '25', name: 'Ladrilho 25', svgPath: 'assets/tiles/B20.svg'),
    Tile(id: '26', name: 'Ladrilho 26', svgPath: 'assets/tiles/B21.svg'),
    Tile(id: '27', name: 'Ladrilho 27', svgPath: 'assets/tiles/B22.svg'),
    Tile(id: '28', name: 'Ladrilho 28', svgPath: 'assets/tiles/B23.svg'),
    Tile(id: '29', name: 'Ladrilho 29', svgPath: 'assets/tiles/B24.svg'),
    Tile(id: '30', name: 'Ladrilho 30', svgPath: 'assets/tiles/B25.svg'),
    Tile(id: '31', name: 'Ladrilho 31', svgPath: 'assets/tiles/B26.svg'),
    Tile(id: '32', name: 'Ladrilho 32', svgPath: 'assets/tiles/B27.svg'),
    Tile(id: '33', name: 'Ladrilho 33', svgPath: 'assets/tiles/B28.svg'),
    Tile(id: '34', name: 'Ladrilho 34', svgPath: 'assets/tiles/B29.svg'),
    Tile(id: '35', name: 'Ladrilho 35', svgPath: 'assets/tiles/B30.svg'),
    Tile(id: '36', name: 'Ladrilho 36', svgPath: 'assets/tiles/B31.svg'),
    Tile(id: '37', name: 'Ladrilho 37', svgPath: 'assets/tiles/B32.svg'),
    Tile(id: '38', name: 'Ladrilho 38', svgPath: 'assets/tiles/C33.svg'),
    Tile(id: '39', name: 'Ladrilho 39', svgPath: 'assets/tiles/C34.svg'),
    Tile(id: '40', name: 'Ladrilho 40', svgPath: 'assets/tiles/C35.svg'),
    Tile(id: '41', name: 'Ladrilho 41', svgPath: 'assets/tiles/C36.svg'),
    Tile(id: '42', name: 'Ladrilho 42', svgPath: 'assets/tiles/C37.svg'),
    Tile(id: '43', name: 'Ladrilho 43', svgPath: 'assets/tiles/C38.svg'),
    Tile(id: '44', name: 'Ladrilho 44', svgPath: 'assets/tiles/C39.svg'),
    Tile(id: '45', name: 'Ladrilho 45', svgPath: 'assets/tiles/C40.svg'),
    Tile(id: '46', name: 'Ladrilho 46', svgPath: 'assets/tiles/C41.svg'),
    Tile(id: '47', name: 'Ladrilho 47', svgPath: 'assets/tiles/C42.svg'),
    Tile(id: '48', name: 'Ladrilho 48', svgPath: 'assets/tiles/C43.svg'),
    Tile(id: '49', name: 'Ladrilho 49', svgPath: 'assets/tiles/C44.svg'),
    Tile(id: '50', name: 'Ladrilho 50', svgPath: 'assets/tiles/C45.svg'),
    Tile(id: '51', name: 'Ladrilho 51', svgPath: 'assets/tiles/C46.svg'),
    Tile(id: '52', name: 'Ladrilho 52', svgPath: 'assets/tiles/C47.svg'),
  ];

  Tile? _selectedTile;

  // personalização
  Color _selectedTileColor1 = const Color.fromARGB(
    255,
    238,
    85,
    38,
  ); // P1 - Nao aparece ainda
  Color _selectedTileColor2 = const Color.fromARGB(
    255,
    217,
    255,
    3,
  ); // P2 - Secundária
  Color _selectedTileColor3 = const Color.fromARGB(
    255,
    36,
    87,
    255,
  ); // P3 - Terciária
  Color _selectedTileColor4 = const Color.fromARGB(
    255,
    33,
    141,
    0,
  ); // P4 - Quaternária
  Color _selectedBackgroundColor = const Color.fromARGB(
    255,
    235,
    244,
    255,
  ); // BG - Cor de Fundo

  final TextEditingController _totalSqMetersController =
      TextEditingController();
  int _calculatedQuantity = 0;

  final List<CartItem> _cartItems = [];
  final List<double> _availableSizes = [15.0, 17.0, 20.0]; // cm
  double? _selectedTileSize;

  final Map<String, List<Color>> _detectedLayerColorsByTileId = {};
  final Map<String, List<Color>> _selectedLayerColorsByTileId = {};

  final PageController _tilePageController = PageController(
    viewportFraction: 0.35,
  );
  final GlobalKey _previewSvgPaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedTile = _availableTiles.first;
    _selectedTileSize = _availableSizes.first;
    _ensureTileLayersLoaded(_selectedTile!);
    _totalSqMetersController.addListener(_updateCalculatedQuantity);
    _updateCalculatedQuantity();
  }

  @override
  void dispose() {
    _totalSqMetersController.removeListener(_updateCalculatedQuantity);
    _totalSqMetersController.dispose();
    _tilePageController.dispose();
    super.dispose();
  }

  /// Avança ladrilho anterior no carrossel.
  void _goToPreviousTile() {
    if (!_tilePageController.hasClients || _availableTiles.isEmpty) {
      return;
    }

    final currentPage = (_tilePageController.page ?? 0).round();
    final targetPage = currentPage > 0
        ? currentPage - 1
        : _availableTiles.length - 1;

    _tilePageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Avança próximo ladrilho no carrossel.
  void _goToNextTile() {
    if (!_tilePageController.hasClients || _availableTiles.isEmpty) {
      return;
    }

    final currentPage = (_tilePageController.page ?? 0).round();
    final targetPage = currentPage < _availableTiles.length - 1
        ? currentPage + 1
        : 0;

    _tilePageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Atualiza quantidade d ladrilhos calculada c base nas entradas.
  void _updateCalculatedQuantity() {
    double? totalSqMeters = double.tryParse(
      _totalSqMetersController.text.replaceAll(',', '.'),
    );

    if (_selectedTileSize != null &&
        totalSqMeters != null &&
        totalSqMeters > 0) {
      double sizeMeters = _selectedTileSize! / 100.0;
      double tileAreaMeters = sizeMeters * sizeMeters;

      if (tileAreaMeters > 0) {
        int quantity = (totalSqMeters / tileAreaMeters).ceil();
        setState(() {
          _calculatedQuantity = quantity;
        });
      } else {
        setState(() => _calculatedQuantity = 0);
      }
    } else {
      setState(() => _calculatedQuantity = 0);
    }
  }

  /// Exibe mensagem na parte inferior.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  /// Adiciona ladrilho ao carrinho.
  void _addToCart() {
    if (_selectedTile == null) {
      _showMessage('Por favor, selecione um ladrilho.');
      return;
    }

    double? totalSqMeters = double.tryParse(
      _totalSqMetersController.text.replaceAll(',', '.'),
    );

    if (_selectedTileSize == null ||
        totalSqMeters == null ||
        totalSqMeters <= 0) {
      _showMessage(
        'Selecione uma dimensão e insira a área total em m² válida.',
      );
      return;
    }

    if (_calculatedQuantity <= 0) {
      _showMessage('A quantidade de ladrilhos deve ser maior que zero.');
      return;
    }

    final layerColors = List<Color>.from(
      _selectedLayerColorsByTileId[_selectedTile!.id] ?? <Color>[],
    );

    final newItem = CartItem(
      tile: _selectedTile!,
      layerColors: layerColors,
      selectedTileColor1: _selectedTileColor1,
      selectedTileColor2: _selectedTileColor2,
      selectedTileColor3: _selectedTileColor3,
      selectedTileColor4: _selectedTileColor4,
      selectedBackgroundColor: _selectedBackgroundColor,
      width: _selectedTileSize!,
      height: _selectedTileSize!,
      totalSqMeters: totalSqMeters,
      quantity: _calculatedQuantity,
    );

    setState(() {
      _cartItems.add(newItem);
    });

    _showMessage('Ladrilho "${_selectedTile!.name}" adicionado ao Pedido!');
    _totalSqMetersController.clear();
    _updateCalculatedQuantity();
  }

  Future<void> _ensureTileLayersLoaded(Tile tile) async {
    if (_detectedLayerColorsByTileId.containsKey(tile.id)) {
      return;
    }

    try {
      final content = await rootBundle.loadString(tile.svgPath);
      final extracted = _extractColorsFromSvg(content);
      if (!mounted) {
        return;
      }

      final defaults = [
        _selectedTileColor1,
        _selectedTileColor2,
        _selectedTileColor3,
        _selectedTileColor4,
      ];

      final selected = <Color>[];
      for (int i = 0; i < extracted.length; i++) {
        selected.add(i < defaults.length ? defaults[i] : extracted[i]);
      }

      setState(() {
        _detectedLayerColorsByTileId[tile.id] = extracted;
        _selectedLayerColorsByTileId[tile.id] = selected;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _detectedLayerColorsByTileId[tile.id] = [];
        _selectedLayerColorsByTileId[tile.id] = [_selectedTileColor1];
      });
    }
  }

  Map<int, Color>? _layerReplacementForTile(
    Tile tile, {
    bool useGrayFallback = false,
  }) {
    final sourceLayers =
        _detectedLayerColorsByTileId[tile.id] ?? const <Color>[];
    final selectedLayers =
        _selectedLayerColorsByTileId[tile.id] ?? const <Color>[];
    if (sourceLayers.isEmpty) {
      return null;
    }

    final map = <int, Color>{};
    for (int i = 0; i < sourceLayers.length; i++) {
      final source = sourceLayers[i];
      final replacement = useGrayFallback
          ? Colors.grey.shade600
          : (i < selectedLayers.length ? selectedLayers[i] : source);
      map[source.value] = replacement;
    }
    return map;
  }

  void _pickLayerColor(int index) async {
    if (_selectedTile == null) {
      return;
    }

    final tileId = _selectedTile!.id;
    final selectedLayers = _selectedLayerColorsByTileId[tileId];
    if (selectedLayers == null || index >= selectedLayers.length) {
      return;
    }

    final picked = await showColorPickerSheet(
      context,
      selectedLayers[index],
      'Cor da camada ${index + 1}',
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _selectedLayerColorsByTileId[tileId]![index] = picked;
      if (index == 0) {
        _selectedTileColor1 = picked;
      } else if (index == 1) {
        _selectedTileColor2 = picked;
      } else if (index == 2) {
        _selectedTileColor3 = picked;
      } else if (index == 3) {
        _selectedTileColor4 = picked;
      }
    });
  }

  Future<int?> _detectLayerIndexFromPreviewTap(
    Offset localPosition,
    Size widgetSize,
  ) async {
    final tileId = _selectedTile?.id;
    if (tileId == null) {
      return null;
    }

    final selectedLayers =
        _selectedLayerColorsByTileId[tileId] ?? const <Color>[];
    if (selectedLayers.isEmpty) {
      return null;
    }

    final boundary =
        _previewSvgPaintKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }

    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (byteData == null) {
      return null;
    }

    final Uint8List bytes = byteData.buffer.asUint8List();
    final int width = image.width;
    final int height = image.height;

    final int x = (localPosition.dx / widgetSize.width * width).floor().clamp(
      0,
      width - 1,
    );
    final int y = (localPosition.dy / widgetSize.height * height).floor().clamp(
      0,
      height - 1,
    );

    final int offset = (y * width + x) * 4;
    if (offset + 3 >= bytes.length) {
      return null;
    }

    final int r = bytes[offset];
    final int g = bytes[offset + 1];
    final int b = bytes[offset + 2];
    final int a = bytes[offset + 3];

    if (a < 10) {
      return null;
    }

    int bestIndex = 0;
    double bestDistance = double.infinity;

    for (int i = 0; i < selectedLayers.length; i++) {
      final Color color = selectedLayers[i];
      final int dr = color.red - r;
      final int dg = color.green - g;
      final int db = color.blue - b;
      final double distance = (dr * dr + dg * dg + db * db).toDouble();

      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }

    if (bestDistance > 9000) {
      return null;
    }

    return bestIndex;
  }

  Future<void> _onPreviewTapDown(TapDownDetails details) async {
    if (_selectedTile == null) {
      return;
    }

    final renderBox =
        _previewSvgPaintKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final tappedLayerIndex = await _detectLayerIndexFromPreviewTap(
      localPosition,
      renderBox.size,
    );

    if (!mounted) {
      return;
    }

    if (tappedLayerIndex == null) {
      _showMessage(
        'Toque em uma área colorida da imagem para editar a camada.',
      );
      return;
    }

    final tileId = _selectedTile!.id;
    final selectedLayers = _selectedLayerColorsByTileId[tileId];
    if (selectedLayers == null || tappedLayerIndex >= selectedLayers.length) {
      return;
    }

    final overlayAnchor = renderBox.localToGlobal(
      Offset(renderBox.size.width + 14, 8),
    );

    final picked = await _showFloatingPalette(
      overlayAnchor,
      layerColors: selectedLayers,
      initialLayerIndex: tappedLayerIndex,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedLayerColorsByTileId[tileId]![picked.layerIndex] = picked.color;
      if (picked.layerIndex == 0) {
        _selectedTileColor1 = picked.color;
      } else if (picked.layerIndex == 1) {
        _selectedTileColor2 = picked.color;
      } else if (picked.layerIndex == 2) {
        _selectedTileColor3 = picked.color;
      } else if (picked.layerIndex == 3) {
        _selectedTileColor4 = picked.color;
      }
    });
  }

  /// Navega p a tela do carrinho.
  void _viewCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          cartItems: _cartItems,
          onRemoveItem: (item) {
            setState(() {
              _cartItems.remove(item);
            });
            _showMessage('Item removido do carrinho.');
          },
        ),
      ),
    );
  }

  /// Abre painel seleção de cor para P1.
  void _pickTileColor1() async {
    final newColor = await showColorPickerSheet(
      context,
      _selectedTileColor1,
      'Cor Principal',
    );
    if (newColor != null) {
      setState(() {
        _selectedTileColor1 = newColor;
        final tileId = _selectedTile?.id;
        if (tileId != null &&
            _selectedLayerColorsByTileId.containsKey(tileId) &&
            _selectedLayerColorsByTileId[tileId]!.isNotEmpty) {
          _selectedLayerColorsByTileId[tileId]![0] = newColor;
        }
      });
    }
  }

  /// Abre painel seleção de cor para P2.
  void _pickTileColor2() async {
    final newColor = await showColorPickerSheet(
      context,
      _selectedTileColor2,
      'Cor Secundária',
    );
    if (newColor != null) {
      setState(() {
        _selectedTileColor2 = newColor;
        final tileId = _selectedTile?.id;
        if (tileId != null &&
            _selectedLayerColorsByTileId.containsKey(tileId) &&
            _selectedLayerColorsByTileId[tileId]!.length > 1) {
          _selectedLayerColorsByTileId[tileId]![1] = newColor;
        }
      });
    }
  }

  /// Abre painel seleção de cor para P3.
  void _pickTileColor3() async {
    final newColor = await showColorPickerSheet(
      context,
      _selectedTileColor3,
      'Cor Terciária',
    );
    if (newColor != null) {
      setState(() {
        _selectedTileColor3 = newColor;
        final tileId = _selectedTile?.id;
        if (tileId != null &&
            _selectedLayerColorsByTileId.containsKey(tileId) &&
            _selectedLayerColorsByTileId[tileId]!.length > 2) {
          _selectedLayerColorsByTileId[tileId]![2] = newColor;
        }
      });
    }
  }

  /// Abre painel seleção de cor para P4.
  void _pickTileColor4() async {
    final newColor = await showColorPickerSheet(
      context,
      _selectedTileColor4,
      'Cor Quaternária',
    );
    if (newColor != null) {
      setState(() {
        _selectedTileColor4 = newColor;
        final tileId = _selectedTile?.id;
        if (tileId != null &&
            _selectedLayerColorsByTileId.containsKey(tileId) &&
            _selectedLayerColorsByTileId[tileId]!.length > 3) {
          _selectedLayerColorsByTileId[tileId]![3] = newColor;
        }
      });
    }
  }

  /// Abre painel seleção de cor.
  void _pickBackgroundColor() async {
    final newColor = await showColorPickerSheet(
      context,
      _selectedBackgroundColor,
      'Cor de Fundo',
    );
    if (newColor != null) {
      setState(() {
        _selectedBackgroundColor = newColor;
      });
    }
  }

  // Ao tocar na prévia do ladrilho selecionado, abre apenas a seleção de cores.
  void _onPreviewTap() async {
    if (_selectedTile == null) {
      return;
    }

    final tile = _selectedTile!;
    final tileId = tile.id;
    final selectedLayers = List<Color>.from(
      _selectedLayerColorsByTileId[tileId] ?? <Color>[_selectedTileColor1],
    );

    final initialData = <String, List<Color>>{
      for (int i = 0; i < selectedLayers.length; i++)
        'Camada ${i + 1}': [selectedLayers[i]],
      'Fundo': [_selectedBackgroundColor],
    };

    final updated = await showMultiColorPickerSheet(
      context,
      initialData,
      tile.name,
    );

    if (updated == null) {
      return;
    }

    setState(() {
      final orderedKeys = updated.keys.where((k) => k.startsWith('Camada '));
      final nextLayers = <Color>[];
      for (final key in orderedKeys) {
        final colors = updated[key];
        if (colors != null && colors.isNotEmpty) {
          nextLayers.add(colors.first);
        }
      }

      if (nextLayers.isNotEmpty) {
        _selectedLayerColorsByTileId[tileId] = nextLayers;
        _selectedTileColor1 = nextLayers[0];
        if (nextLayers.length > 1) _selectedTileColor2 = nextLayers[1];
        if (nextLayers.length > 2) _selectedTileColor3 = nextLayers[2];
        if (nextLayers.length > 3) _selectedTileColor4 = nextLayers[3];
      }

      final bg = updated['Fundo'];
      if (bg != null && bg.isNotEmpty) {
        _selectedBackgroundColor = bg.first;
      }
    });
  }

  // Retorna a cor atual associada à parte escolhida.
  Color _getCurrentColorForPart(String part) {
    switch (part) {
      case 'P1':
        return _selectedTileColor1;
      case 'P2':
        return _selectedTileColor2;
      case 'P3':
        return _selectedTileColor3;
      case 'P4':
        return _selectedTileColor4;
      case 'BG':
      default:
        return _selectedBackgroundColor;
    }
  }

  void _setColorForPart(String part, Color color) {
    switch (part) {
      case 'P1':
        _selectedTileColor1 = color;
        break;
      case 'P2':
        _selectedTileColor2 = color;
        break;
      case 'P3':
        _selectedTileColor3 = color;
        break;
      case 'P4':
        _selectedTileColor4 = color;
        break;
      case 'BG':
      default:
        _selectedBackgroundColor = color;
        break;
    }
  }

  // Mostra um painel lateral compacto próximo à prévia com seleção
  // de camada e cor. Retorna camada+cor selecionadas ou null.
  Future<_LayerColorSelection?> _showFloatingPalette(
    Offset globalPosition, {
    required List<Color> layerColors,
    required int initialLayerIndex,
  }) {
    final completer = Completer<_LayerColorSelection?>();
    final overlay = Overlay.of(context);

    const double paletteWidth = 188;
    const double paletteHeight = 170;
    const double customWidth = 176;
    const double customHeight = 248;

    // Ajusta posição para não sair da tela
    final mq = MediaQuery.of(context).size;
    double left = globalPosition.dx;
    double top = globalPosition.dy;
    if (left + paletteWidth > mq.width) left = mq.width - paletteWidth - 8;
    if (top + paletteHeight > mq.height) top = mq.height - paletteHeight - 8;

    // Variáveis fora do builder para sobreviver a rebuilds do overlay
    int activeLayer = initialLayerIndex.clamp(0, layerColors.length - 1);
    bool showCustomBox = false;
    Color draftCustomColor = layerColors[activeLayer];

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setOverlayState) {
            final currentColor = layerColors[activeLayer];
            double customLeft = left + paletteWidth + 6;
            if (customLeft + customWidth > mq.width) {
              customLeft = left - customWidth - 6;
            }
            if (customLeft < 8) {
              customLeft = 8;
            }

            double customTop = top;
            if (customTop + customHeight > mq.height) {
              customTop = mq.height - customHeight - 8;
            }
            if (customTop < 8) {
              customTop = 8;
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      if (!completer.isCompleted) completer.complete(null);
                      entry.remove();
                    },
                    behavior: HitTestBehavior.translucent,
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  left: left,
                  top: top,
                  width: paletteWidth,
                  child: GestureDetector(
                    onTap: () {},
                    behavior: HitTestBehavior.opaque,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Camadas',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(layerColors.length, (
                                  index,
                                ) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text('C${index + 1}'),
                                      selected: activeLayer == index,
                                      onSelected: (_) {
                                        setOverlayState(() {
                                          activeLayer = index;
                                          draftCustomColor =
                                              layerColors[activeLayer];
                                        });
                                      },
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _paletteSuggestions.map((c) {
                                final selected = currentColor.value == c.value;
                                return GestureDetector(
                                  onTap: () {
                                    if (!completer.isCompleted) {
                                      completer.complete(
                                        _LayerColorSelection(
                                          layerIndex: activeLayer,
                                          color: c,
                                        ),
                                      );
                                    }
                                    entry.remove();
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selected
                                            ? Colors.blue.shade700
                                            : Colors.black12,
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    if (!completer.isCompleted) {
                                      completer.complete(null);
                                    }
                                    entry.remove();
                                  },
                                  child: const Text('Fechar'),
                                ),
                                const SizedBox(width: 4),
                                ElevatedButton(
                                  onPressed: () {
                                    setOverlayState(() {
                                      showCustomBox = !showCustomBox;
                                      draftCustomColor = currentColor;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text('Custom'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (showCustomBox)
                  Positioned(
                    left: customLeft,
                    top: customTop,
                    width: customWidth,
                    child: GestureDetector(
                      onTap: () {},
                      behavior: HitTestBehavior.opaque,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Custom C${activeLayer + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: draftCustomColor,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.black12),
                                ),
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Slider(
                                      value: draftCustomColor.red.toDouble(),
                                      min: 0,
                                      max: 255,
                                      activeColor: Colors.red,
                                      onChanged: (v) {
                                        setOverlayState(() {
                                          draftCustomColor = draftCustomColor
                                              .withRed(v.toInt());
                                        });
                                      },
                                    ),
                                    Slider(
                                      value: draftCustomColor.green.toDouble(),
                                      min: 0,
                                      max: 255,
                                      activeColor: Colors.green,
                                      onChanged: (v) {
                                        setOverlayState(() {
                                          draftCustomColor = draftCustomColor
                                              .withGreen(v.toInt());
                                        });
                                      },
                                    ),
                                    Slider(
                                      value: draftCustomColor.blue.toDouble(),
                                      min: 0,
                                      max: 255,
                                      activeColor: Colors.blue,
                                      onChanged: (v) {
                                        setOverlayState(() {
                                          draftCustomColor = draftCustomColor
                                              .withBlue(v.toInt());
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setOverlayState(() {
                                        showCustomBox = false;
                                      });
                                    },
                                    child: const Text('Cancelar'),
                                  ),
                                  const SizedBox(width: 4),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (!completer.isCompleted) {
                                        completer.complete(
                                          _LayerColorSelection(
                                            layerIndex: activeLayer,
                                            color: draftCustomColor,
                                          ),
                                        );
                                      }
                                      entry.remove();
                                    },
                                    child: const Text('Aplicar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );

    overlay.insert(entry);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cores da Roça'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart, size: 28),
                if (_cartItems.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${_cartItems.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _viewCart,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Selecionar Ladrilho'),
            const SizedBox(height: 15),
            _buildTileCarousel(), // Carrossel com botões
            _buildDivider(),

            _buildSectionTitle('Definir Cores'),
            const SizedBox(height: 15),
            _buildColorPreview(),
            _buildDivider(),

            _buildSectionTitle('Detalhes do Pedido'),
            const SizedBox(height: 15),
            _buildDimensionsSelector(),
            const SizedBox(height: 20),
            _buildAreaInput(),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Quantidade Necessária: $_calculatedQuantity unidades',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.add_shopping_cart, size: 28),
                label: const Text('Adicionar ao Pedido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 4, 255),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 25.0),
      child: Divider(height: 1, thickness: 1, color: Colors.black12),
    );
  }

  Widget _buildTileCarousel() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _tilePageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _selectedTile = _availableTiles[index];
              });
              _ensureTileLayersLoaded(_availableTiles[index]);
            },
            itemCount: _availableTiles.length,
            itemBuilder: (context, index) {
              final tile = _availableTiles[index];
              bool isSelected = _selectedTile?.id == tile.id;

              return GestureDetector(
                // centraliza e seleciona
                onTap: () {
                  if (!isSelected) {
                    setState(() {
                      _selectedTile = tile;
                    });
                    _ensureTileLayersLoaded(tile);
                  }
                  _tilePageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedScale(
                  scale: isSelected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: Card(
                    elevation: isSelected ? 12 : 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isSelected
                          ? BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 4,
                            )
                          : BorderSide.none,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Builder(
                            builder: (context) {
                              final replacement = _layerReplacementForTile(
                                tile,
                                useGrayFallback: !isSelected,
                              );

                              if (replacement == null || replacement.isEmpty) {
                                return SvgPicture.asset(
                                  tile.svgPath,
                                  width: 70,
                                  height: 70,
                                  colorFilter: ColorFilter.mode(
                                    isSelected
                                        ? _selectedTileColor1
                                        : Colors.grey.shade600,
                                    BlendMode.srcIn,
                                  ),
                                );
                              }

                              return SvgPicture.asset(
                                tile.svgPath,
                                width: 70,
                                height: 70,
                                colorMapper: _SvgLayerColorMapper(replacement),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tile.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey.shade800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Botão Esquerdo (Anterior)
        Positioned(
          left: 0,
          child: _NavigationButton(
            icon: Icons.arrow_back_ios_new,
            onPressed: _goToPreviousTile,
          ),
        ),

        // Botão Direito (Próximo)
        Positioned(
          right: 0,
          child: _NavigationButton(
            icon: Icons.arrow_forward_ios,
            onPressed: _goToNextTile,
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelectors() {
    final tile = _selectedTile;
    final layerColors = tile == null
        ? const <Color>[]
        : (_selectedLayerColorsByTileId[tile.id] ?? const <Color>[]);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ...List.generate(layerColors.length, (index) {
            return Row(
              children: [
                _ColorPickerButton(
                  title: 'Camada ${index + 1}',
                  color: layerColors[index],
                  onTap: () => _pickLayerColor(index),
                ),
                const SizedBox(width: 20),
              ],
            );
          }),
          if (layerColors.isEmpty)
            _ColorPickerButton(
              title: 'Principal',
              color: _selectedTileColor1,
              onTap: _pickTileColor1,
            ),
          if (layerColors.isEmpty) const SizedBox(width: 20),
          _ColorPickerButton(
            title: 'Fundo',
            color: _selectedBackgroundColor,
            onTap: _pickBackgroundColor,
          ),
        ],
      ),
    );
  }

  // Widget prévia individual
  Widget _buildColorPreview() {
    if (_selectedTile == null) {
      return const Center(
        child: Text('Selecione um ladrilho para ver a prévia.'),
      );
    }
    return Center(
      child: Column(
        children: [
          const Text(
            'Prévia do Ladrilho',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                // prévia usa P3 p simulação
                color: _selectedTileColor3,
                borderRadius: BorderRadius.circular(16),
                // prévia usa P4 p simulação
                border: Border.all(color: _selectedTileColor4, width: 3),
              ),
              child: RepaintBoundary(
                key: _previewSvgPaintKey,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: _onPreviewTapDown,
                  child: SvgPicture.asset(
                    _selectedTile!.svgPath,
                    colorFilter:
                        _layerReplacementForTile(_selectedTile!) == null
                        ? ColorFilter.mode(_selectedTileColor1, BlendMode.srcIn)
                        : null,
                    colorMapper:
                        _layerReplacementForTile(_selectedTile!) == null
                        ? null
                        : _SvgLayerColorMapper(
                            _layerReplacementForTile(_selectedTile!)!,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Toque na área da imagem para alterar a cor da camada correspondente.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dimensões do Ladrilho:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Center(
          child: ToggleButtons(
            isSelected: _availableSizes
                .map((size) => size == _selectedTileSize)
                .toList(),
            onPressed: (int index) {
              setState(() {
                _selectedTileSize = _availableSizes[index];
                _updateCalculatedQuantity();
              });
            },
            borderRadius: BorderRadius.circular(12),
            borderWidth: 2,
            selectedBorderColor: Theme.of(context).primaryColor,
            selectedColor: Colors.white,
            fillColor: Theme.of(context).primaryColor,
            color: Theme.of(context).primaryColor,
            // ignore: deprecated_member_use
            splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
            children: _availableSizes.map((size) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  '${size.toInt()} cm',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAreaInput() {
    return TextField(
      controller: _totalSqMetersController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
      ],
      decoration: const InputDecoration(
        labelText: 'Área Total Necessária (em m²)',
        hintText: 'Ex: 10.5',
      ),
    );
  }
}

/// auxiliar p o botão d navegação do carrossel.
class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _NavigationButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.85),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF333333)),
        onPressed: onPressed,
      ),
    );
  }
}

/// auxiliar p o botão de seleção de cor.
class _ColorPickerButton extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ColorPickerButton({
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    String hexColor = color.value.toRadixString(16).substring(2).toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black38, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          Text(
            '#$hexColor',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// --- (Pedido) ---

class CartScreen extends StatelessWidget {
  final List<CartItem> cartItems;
  final Function(CartItem) onRemoveItem;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.onRemoveItem,
  });

  final Map<int, String> _commonColorNames = const {
    // Valores baseados nas cores definidas em _paletteSuggestions
    0xFFFFFFFF: 'Branco',
    0xFF000000: 'Preto',
    0xFFC70039: 'Vermelho Bordô',
    0xFF004488: 'Azul Marinho',
    0xFF008844: 'Verde Floresta',
    0xFFFFA500: 'Laranja Cítrico',
    0xFF808080: 'Cinza Chumbo',
    0xFFF9E79F: 'Creme Claro',
    0xFF5D4037: 'Marrom Escuro',
    0xFF6A1B9A: 'Roxo',
  };

  String _getColorDisplay(Color color) {
    // ignore: deprecated_member_use
    final hexCode = color.value.toRadixString(16).substring(2).toUpperCase();
    // ignore: deprecated_member_use
    final colorName = _commonColorNames[color.value];

    if (colorName != null) {
      return colorName;
    } else {
      return 'Personalizada (#$hexCode)';
    }
  }

  /// Retorna nome da cor ou o código HEX pra mensagem do whats.
  String _getWhatsAppColorName(Color color) {
    // ignore: deprecated_member_use
    final hexCode = color.value.toRadixString(16).substring(2).toUpperCase();
    // ignore: deprecated_member_use
    final colorName = _commonColorNames[color.value];

    if (colorName != null) {
      return colorName;
    } else {
      // personalizada retorna apenas o código HEX como identificador
      return '#$hexCode';
    }
  }

  /// Exibe diálogo confirmação remover um item.
  void _showConfirmationDialog(BuildContext context, CartItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Confirmar Remoção'),
          content: const Text(
            'Tem certeza de que deseja remover este item do pedido?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                onRemoveItem(item);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Remover',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Envia detalhes pedido via WhatsApp.
  Future<void> _sendOrderViaWhatsApp(BuildContext context) async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seu pedido está vazio. Adicione itens para enviar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String message =
        'Olá! Gostaria de formalizar o seguinte pedido de ladrilhos da Cores da Roça:\n\n';
    double totalArea = 0;

    for (int i = 0; i < cartItems.length; i++) {
      final item = cartItems[i];

      // Obtém nome da cor SIMPLIFICADO
      String color1Name = _getWhatsAppColorName(item.selectedTileColor1);
      String color2Name = _getWhatsAppColorName(item.selectedTileColor2);
      String color3Name = _getWhatsAppColorName(item.selectedTileColor3);
      String color4Name = _getWhatsAppColorName(item.selectedTileColor4);
      String bgColorName = _getWhatsAppColorName(item.selectedBackgroundColor);

      message += '--- Item ${i + 1} ---\n';
      message += 'Ladrilho: ${item.tile.name}\n';
      // Saídas simplificadas (ex: P1 (Principal): Branco)
      // ignore: unnecessary_brace_in_string_interps
      message += 'P1 (Principal): ${color1Name}\n';
      // ignore: unnecessary_brace_in_string_interps
      message += 'P2 (Secundária): ${color2Name}\n';
      // ignore: unnecessary_brace_in_string_interps
      message += 'P3 (Terciária): ${color3Name}\n';
      // ignore: unnecessary_brace_in_string_interps
      message += 'P4 (Quaternária): ${color4Name}\n';
      // ignore: unnecessary_brace_in_string_interps
      message += 'BG (Fundo): ${bgColorName}\n';
      message += 'Dimensões: ${item.width}cm x ${item.height}cm\n';
      message +=
          'Área Requerida: ${item.totalSqMeters.toStringAsFixed(2)} m²\n';
      message += 'Quantidade Estimada: ${item.quantity} unidades\n\n';
      totalArea += item.totalSqMeters;
    }
    message += '------------------------------------\n';
    message +=
        'Área Total Estimada do Pedido: ${totalArea.toStringAsFixed(2)} m²\n';
    message +=
        'Aguardamos a confirmação dos detalhes e do orçamento final. Obrigado!';

    final Uri url = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o WhatsApp. Por favor, verifique se o aplicativo está instalado.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Itens do Pedido')),
      body: cartItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.remove_shopping_cart,
                    size: 80,
                    color: Colors.black26,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Seu pedido está vazio!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Adicione ladrilhos para simular e formalizar seu pedido.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      // ignore: deprecated_member_use
                      String color1Hex = item.selectedTileColor1.value
                          .toRadixString(16)
                          .substring(2)
                          .toUpperCase();
                      // ignore: deprecated_member_use
                      String color2Hex = item.selectedTileColor2.value
                          .toRadixString(16)
                          .substring(2)
                          .toUpperCase();
                      // ignore: deprecated_member_use
                      String color3Hex = item.selectedTileColor3.value
                          .toRadixString(16)
                          .substring(2)
                          .toUpperCase();
                      // ignore: deprecated_member_use
                      String color4Hex = item.selectedTileColor4.value
                          .toRadixString(16)
                          .substring(2)
                          .toUpperCase();
                      // ignore: deprecated_member_use
                      String bgColorHex = item.selectedBackgroundColor.value
                          .toRadixString(16)
                          .substring(2)
                          .toUpperCase();

                      // Para a exibição na tela (MANTÉM o formato detalhado)
                      String color1Display =
                          '${_getColorDisplay(item.selectedTileColor1)} (#$color1Hex)';
                      String color2Display =
                          '${_getColorDisplay(item.selectedTileColor2)} (#$color2Hex)';
                      String color3Display =
                          '${_getColorDisplay(item.selectedTileColor3)} (#$color3Hex)';
                      String color4Display =
                          '${_getColorDisplay(item.selectedTileColor4)} (#$color4Hex)';
                      String bgColorDisplay =
                          '${_getColorDisplay(item.selectedBackgroundColor)} (#$bgColorHex)';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Miniatura do Ladrilho
                              Container(
                                decoration: BoxDecoration(
                                  color: item.selectedBackgroundColor
                                      // ignore: deprecated_member_use
                                      .withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.black12),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: SvgPicture.asset(
                                  item.tile.svgPath,
                                  width: 70,
                                  height: 70,
                                  colorFilter: ColorFilter.mode(
                                    item.selectedTileColor1,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              // Detalhes do Item
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.tile.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (item.layerColors.isNotEmpty)
                                      Text(
                                        'Camadas: ${item.layerColors.length} cores selecionadas',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    // Detalhes de todas as 4 cores + fundo
                                    Text(
                                      'P1: $color1Display',
                                      style: TextStyle(
                                        color: item.selectedTileColor1,
                                      ),
                                    ),
                                    Text(
                                      'P2: $color2Display',
                                      style: TextStyle(
                                        color: item.selectedTileColor2,
                                      ),
                                    ),
                                    Text(
                                      'P3: $color3Display',
                                      style: TextStyle(
                                        color: item.selectedTileColor3,
                                      ),
                                    ),
                                    Text(
                                      'P4: $color4Display',
                                      style: TextStyle(
                                        color: item.selectedTileColor4,
                                      ),
                                    ),
                                    Text(
                                      'BG: $bgColorDisplay',
                                      style: TextStyle(
                                        color: item.selectedBackgroundColor,
                                      ),
                                    ),
                                    if (item.layerColors.isNotEmpty)
                                      Wrap(
                                        spacing: 6,
                                        children: item.layerColors
                                            .asMap()
                                            .entries
                                            .map(
                                              (entry) => Chip(
                                                label: Text(
                                                  'C${entry.key + 1}',
                                                ),
                                                backgroundColor: entry.value,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Dimensão: ${item.width.toInt()}cm x ${item.height.toInt()}cm',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Área: ${item.totalSqMeters.toStringAsFixed(2)} m²',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Qtd. Estimada: ${item.quantity} un.',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Botão Remover
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                  size: 28,
                                ),
                                onPressed: () =>
                                    _showConfirmationDialog(context, item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Botão de Enviar Pedido por WhatsApp
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _sendOrderViaWhatsApp(context),
                    //icon: const Icon(Icons.whatsapp, size: 30),
                    label: const Text('Enviar Pedido Completo por WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      minimumSize: const Size(double.infinity, 60),
                      elevation: 8,
                      shadowColor: Colors.green.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
    );
  }
}
