import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

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

/// dados para um ladrilho.
class Tile {
  final String id;
  final String name;
  final String svgPath;

  Tile({required this.id, required this.name, required this.svgPath});
}

/// dados para um item no carrinho de compras.
class CartItem {
  final Tile tile;
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

/// dados para um ambiente de simulação.
class Environment {
  final String name;
  final IconData icon;
  final Color color;
  final String imageUrl;

  Environment({
    required this.name,
    required this.icon,
    required this.color,
    required this.imageUrl,
  });
}

// --- Componente de Visualização do Ladrilho ---

/// repete um ladrilho em uma grade para simulação.
class TilePatternRepeater extends StatelessWidget {
  final Tile tile;
  final Color tileColor1;
  final Color tileColor2;
  final Color tileColor3;
  final Color tileColor4;
  final Color bgColor;
  final double tileDisplaySize;
  final bool isWall; // diferenciar rejunte em parede/chão

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
    // Cor do rejunte (mais escuro no chão, mais claro na parede)
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
          // P1: Cor principal do SVG
          // P3: cor de fundo de cada ladrilho individual na grade
          // P4: cor de borda de cada ladrilho individual na grade

          final useP4Border = index % 2 == 0;

          return Container(
            decoration: BoxDecoration(
              // Simula o rejunte
              border: Border.all(color: groutColor, width: isWall ? 0.5 : 1.0),
              // Simula a borda do ladrilho com P4
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

// --- Painel Inferior de Seleção de Cor RGB (Não-Bloqueante) ---

/// Lista de sugestões de cores para a paleta rápida.
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

/// Painel inferior para seleção de cor usando sliders RGB e paletas.
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

                // Prévia da cor selecionada e código HEX
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

                // Sliders RGB
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

/// auxiliar para construir os sliders de cor.
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

// --- Home Page (Seleção e Simulação) ---

class TileShopHomePage extends StatefulWidget {
  const TileShopHomePage({super.key});

  @override
  State<TileShopHomePage> createState() => _TileShopHomePageState();
}

class _TileShopHomePageState extends State<TileShopHomePage> {
  final List<Tile> _availableTiles = [
    Tile(id: '1', name: 'Mosaico Clássico', svgPath: 'assets/tiles/tile1.svg'),
    Tile(id: '2', name: 'Padrão Geométrico', svgPath: 'assets/tiles/tile2.svg'),
    Tile(id: '3', name: 'Arabesco Elegante', svgPath: 'assets/tiles/tile3.svg'),
    Tile(id: '4', name: 'Hexagonal Moderno', svgPath: 'assets/tiles/tile4.svg'),
    Tile(id: '5', name: 'Diagonal Simples', svgPath: 'assets/tiles/tile5.svg'),
  ];

  final List<Environment> _availableEnvironments = [
    Environment(
      name: 'Cozinha',
      icon: Icons.kitchen,
      color: Colors.brown.shade400,
      imageUrl: 'assets/cozinha.jpg',
    ),
    Environment(
      name: 'Banheiro',
      icon: Icons.bathtub,
      color: Colors.blue.shade400,
      imageUrl: 'assets/banheiro.jpg',
    ),
    Environment(
      name: 'Varanda',
      icon: Icons.deck,
      color: Colors.green.shade400,
      imageUrl: 'assets/varanda.jpg',
    ),
    Environment(
      name: 'Piscina',
      icon: Icons.pool,
      color: Colors.cyan.shade400,
      imageUrl: 'assets/piscina.jpg',
    ),
  ];

  Tile? _selectedTile;
  Environment? _selectedEnvironment;

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

  final PageController _tilePageController = PageController(
    viewportFraction: 0.35,
  );

  @override
  void initState() {
    super.initState();
    _selectedTile = _availableTiles.first;
    _selectedTileSize = _availableSizes.first;
    _selectedEnvironment = _availableEnvironments.first;
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

  /// Avança para o ladrilho anterior no carrossel.
  void _goToPreviousTile() {
    if (_tilePageController.page! > 0) {
      _tilePageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Avança para o próximo ladrilho no carrossel.
  void _goToNextTile() {
    if (_tilePageController.page! < _availableTiles.length - 1) {
      _tilePageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Atualiza a quantidade de ladrilhos calculada com base nas entradas.
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

  /// Exibe uma mensagem na parte inferior da tela (SnackBar).
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

  /// Adiciona o ladrilho configurado ao carrinho.
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

    final newItem = CartItem(
      tile: _selectedTile!,
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

  /// Navega para a tela do carrinho.
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

  /// Abre o painel de seleção de cor para P1.
  void _pickTileColor1() async {
    final newColor = await showColorPickerSheet(
      context,
      _selectedTileColor1,
      'Cor Principal',
    );
    if (newColor != null) {
      setState(() {
        _selectedTileColor1 = newColor;
      });
    }
  }

  /// Abre o painel de seleção de cor para P2.
  void _pickTileColor2() async {
    final newColor = await showColorPickerSheet(
      context,
      _selectedTileColor2,
      'Cor Secundária',
    );
    if (newColor != null) {
      setState(() {
        _selectedTileColor2 = newColor;
      });
    }
  }

  /// Abre o painel de seleção de cor para P3.
  void _pickTileColor3() async {
    final newColor = await showColorPickerSheet(
      context,
      _selectedTileColor3,
      'Cor Terciária',
    );
    if (newColor != null) {
      setState(() {
        _selectedTileColor3 = newColor;
      });
    }
  }

  /// Abre o painel de seleção de cor para P4.
  void _pickTileColor4() async {
    final newColor = await showColorPickerSheet(
      context,
      _selectedTileColor4,
      'Cor Quaternária',
    );
    if (newColor != null) {
      setState(() {
        _selectedTileColor4 = newColor;
      });
    }
  }

  /// Abre o painel de seleção de cor para BG.
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
            _buildColorSelectors(),
            const SizedBox(height: 20),
            _buildColorPreview(),
            _buildDivider(),

            _buildSectionTitle('Visualização em 3D'),
            const SizedBox(height: 15),
            _build3DPreview(), // Visualização 3D aprimorada com 4 cores simuladas
            _buildDivider(),

            _buildSectionTitle('Simulação de Ambiente'),
            const SizedBox(height: 15),
            _buildEnvironmentSelector(),
            const SizedBox(height: 20),
            _buildEnvironmentPreview(), // Simulação com imagem de fundo 3D
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
            },
            itemCount: _availableTiles.length,
            itemBuilder: (context, index) {
              final tile = _availableTiles[index];
              bool isSelected = _selectedTile?.id == tile.id;

              return GestureDetector(
                // Ao tocar, centraliza e seleciona
                onTap: () {
                  if (!isSelected) {
                    setState(() {
                      _selectedTile = tile;
                    });
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
                        color: isSelected
                            // ignore: deprecated_member_use
                            ? _selectedBackgroundColor.withOpacity(0.9)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            tile.svgPath,
                            width: 70,
                            height: 70,
                            colorFilter: ColorFilter.mode(
                              isSelected
                                  ? _selectedTileColor1
                                  : Colors.grey.shade600,
                              BlendMode.srcIn,
                            ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _ColorPickerButton(
            title: 'Principal',
            color: _selectedTileColor1,
            onTap: _pickTileColor1,
          ),
          const SizedBox(width: 20),
          _ColorPickerButton(
            title: 'Secundária',
            color: _selectedTileColor2,
            onTap: _pickTileColor2,
          ),
          const SizedBox(width: 20),
          _ColorPickerButton(
            title: 'Terciária',
            color: _selectedTileColor3,
            onTap: _pickTileColor3,
          ),
          const SizedBox(width: 20),
          _ColorPickerButton(
            title: 'Quaternária',
            color: _selectedTileColor4,
            onTap: _pickTileColor4,
          ),
          const SizedBox(width: 20),
          _ColorPickerButton(
            title: 'Fundo',
            color: _selectedBackgroundColor,
            onTap: _pickBackgroundColor,
          ),
        ],
      ),
    );
  }

  // Widget para prévia individual
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
                // prévia usa P3 para simulação
                color: _selectedTileColor3,
                borderRadius: BorderRadius.circular(16),
                // prévia usa P4 para simulação
                border: Border.all(color: _selectedTileColor4, width: 3),
              ),
              child: SvgPicture.asset(
                _selectedTile!.svgPath,
                // SVG usa P1 para o centro do desenho
                colorFilter: ColorFilter.mode(
                  _selectedTileColor1,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Ladrilho individual.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _build3DPreview() {
    if (_selectedTile == null) {
      return const Center(
        child: Text('Selecione um ladrilho para ver a prévia 3D.'),
      );
    }

    return Center(
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade100,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 15,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // PAREDE
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 150,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(0.0), // Simula a parede
                  child: TilePatternRepeater(
                    tile: _selectedTile!,
                    tileColor1: _selectedTileColor1,
                    tileColor2: _selectedTileColor2,
                    tileColor3: _selectedTileColor3,
                    tileColor4: _selectedTileColor4,
                    bgColor: _selectedBackgroundColor,
                    tileDisplaySize: 50.0,
                    isWall: true,
                  ),
                ),
              ),
            ),
            // Linha do canto (simula o rodapé/junta)
            Positioned(
              top: 148,
              left: 0,
              right: 0,
              child: Container(height: 4, color: Colors.black38),
            ),
            // CHÃO
            Positioned(
              top: 150,
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: Transform(
                  alignment: Alignment.topCenter, // Inclina a partir do canto
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002) // Aplica perspectiva
                    ..rotateX(1.1), // Inclinação forte para simular o chão
                  child: TilePatternRepeater(
                    tile: _selectedTile!,
                    tileColor1: _selectedTileColor1,
                    tileColor2: _selectedTileColor2,
                    tileColor3: _selectedTileColor3,
                    tileColor4: _selectedTileColor4,
                    bgColor: _selectedBackgroundColor,
                    tileDisplaySize: 50.0,
                    isWall: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentSelector() {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ToggleButtons(
          isSelected: _availableEnvironments
              .map((env) => env.name == _selectedEnvironment?.name)
              .toList(),
          onPressed: (index) {
            setState(() {
              _selectedEnvironment = _availableEnvironments[index];
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
          children: _availableEnvironments.map((env) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(env.icon, size: 24),
                  const SizedBox(height: 4),
                  Text(env.name, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEnvironmentPreview() {
    if (_selectedTile == null || _selectedEnvironment == null) {
      return const Center(
        child: Text('Selecione um ladrilho e um ambiente para a simulação 3D.'),
      );
    }

    // Container pra simulação
    return Center(
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Stack(
            children: [
              // 1. fundo 3D do Ambiente
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    _selectedEnvironment!.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(
                        'Erro ao carregar a imagem local: ${_selectedEnvironment!.imageUrl}. Verifique seu pubspec.yaml.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Tiling de Parede (Simulação de perspectiva na parte superior)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.85,
                  child: ClipPath(
                    clipper: _WallPerspectiveClipper(),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0005)
                        ..rotateX(-0.1),
                      child: TilePatternRepeater(
                        tile: _selectedTile!,
                        tileColor1: _selectedTileColor1,
                        tileColor2: _selectedTileColor2,
                        tileColor3: _selectedTileColor3,
                        tileColor4: _selectedTileColor4,
                        bgColor: _selectedBackgroundColor,
                        tileDisplaySize: 30.0,
                        isWall: true,
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Tiling de Chão (Simulação de perspectiva na parte inferior)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.85,
                  child: ClipPath(
                    clipper: _FloorPerspectiveClipper(),
                    child: Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX(1.1),
                      child: TilePatternRepeater(
                        tile: _selectedTile!,
                        tileColor1: _selectedTileColor1,
                        tileColor2: _selectedTileColor2,
                        tileColor3: _selectedTileColor3,
                        tileColor4: _selectedTileColor4,
                        bgColor: _selectedBackgroundColor,
                        tileDisplaySize: 30.0,
                        isWall: false,
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Overlay de Texto (para identificação)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: _selectedEnvironment!.color.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedEnvironment!.icon,
                        size: 24,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedEnvironment!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

/// auxiliar para o botão de navegação do carrossel.
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

/// auxiliar para o botão de seleção de cor.
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

/// criar a forma de chão em perspectiva (trapézio inferior).
class _FloorPerspectiveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Ponto 1: Canto inferior esquerdo
    path.moveTo(0, size.height);
    // Ponto 2: Canto inferior direito
    path.lineTo(size.width, size.height);
    // Ponto 3: Ponto de perspectiva superior direito (80% da largura, 35% da altura)
    path.lineTo(size.width * 0.85, size.height * 0.35);
    // Ponto 4: Ponto de perspectiva superior esquerdo (15% da largura, 35% da altura)
    path.lineTo(size.width * 0.15, size.height * 0.35);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// criar a forma de parede em perspectiva (trapézio superior).
class _WallPerspectiveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Ponto 1: Canto superior esquerdo
    path.moveTo(0, 0);
    // Ponto 2: Canto superior direito
    path.lineTo(size.width, 0);
    // Ponto 3: Ponto de perspectiva inferior direito (85% da largura, 35% da altura)
    path.lineTo(size.width * 0.85, size.height * 0.35);
    // Ponto 4: Ponto de perspectiva inferior esquerdo (15% da largura, 35% da altura)
    path.lineTo(size.width * 0.15, size.height * 0.35);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// --- Cart Screen (Pedido) ---

class CartScreen extends StatelessWidget {
  final List<CartItem> cartItems;
  final Function(CartItem) onRemoveItem;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.onRemoveItem,
  });

  /// Mapeamento de cores comuns para nomes amigáveis em português (para o WhatsApp).
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

  /// Retorna apenas o nome da cor ou o código HEX para a mensagem do WhatsApp.
  String _getWhatsAppColorName(Color color) {
    // ignore: deprecated_member_use
    final hexCode = color.value.toRadixString(16).substring(2).toUpperCase();
    // ignore: deprecated_member_use
    final colorName = _commonColorNames[color.value];

    if (colorName != null) {
      return colorName; // Ex: "Branco"
    } else {
      // Se for personalizada, retorna apenas o código HEX como identificador
      return '#$hexCode';
    }
  }

  /// Exibe um diálogo de confirmação para remover um item.
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

  /// Envia os detalhes do pedido via WhatsApp.
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

      // Obtém o nome da cor SIMPLIFICADO para a mensagem do WhatsApp
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
                                    // Detalhes de todas as 4 cores + Fundo
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
                              // Botão de Remover
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
