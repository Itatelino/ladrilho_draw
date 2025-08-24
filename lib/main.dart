import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const TileShopApp());
}

/// O widget raiz do aplicativo.
class TileShopApp extends StatelessWidget {
  const TileShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ladrilhos Cores da Roça',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Usando a fonte Inter, se disponível no sistema, ou fallback para Roboto
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
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

/// Modelo de dados para um ladrilho.
class Tile {
  final String id;
  final String name;
  final String svgPath;

  Tile({required this.id, required this.name, required this.svgPath});
}

/// Modelo de dados para um item no carrinho de compras.
class CartItem {
  final Tile tile;
  final Color selectedTileColor; // Cor do SVG do ladrilho
  final Color selectedBackgroundColor; // Cor de fundo do ladrilho
  final double width; // Largura do ladrilho em metros
  final double height; // Altura do ladrilho em metros
  final double totalSqMeters; // Área total em metros quadrados
  final int quantity; // Quantidade de ladrilhos individuais

  CartItem({
    required this.tile,
    required this.selectedTileColor,
    required this.selectedBackgroundColor,
    required this.width,
    required this.height,
    required this.totalSqMeters,
    required this.quantity,
  });
}

/// A página principal do aplicativo onde o usuário seleciona e personaliza ladrilhos.
class TileShopHomePage extends StatefulWidget {
  const TileShopHomePage({super.key});

  @override
  State<TileShopHomePage> createState() => _TileShopHomePageState();
}

class _TileShopHomePageState extends State<TileShopHomePage> {
  // Lista de ladrilhos disponíveis. Certifique-se de que os arquivos SVG existam na pasta assets/tiles/.
  final List<Tile> _availableTiles = [
    Tile(id: '1', name: 'Mosaico Clássico', svgPath: 'assets/tiles/tile1.svg'),
    Tile(id: '2', name: 'Padrão Geométrico', svgPath: 'assets/tiles/tile2.svg'),
    //Tile(id: '3', name: 'Arabesco Elegante', svgPath: 'assets/tiles/tile3.svg'),
    //Tile(id: '4', name: 'Hexagonal Moderno', svgPath: 'assets/tiles/tile4.svg'),
    //Tile(id: '5', name: 'Diagonal Simples', svgPath: 'assets/tiles/tile5.svg'),
  ];

  Tile? _selectedTile; // Ladrilho atualmente selecionado

  // Cores para o SVG do ladrilho
  Color _selectedTileColor = Colors.blueGrey;
  final List<Color> _tileColorOptions = [
    Colors.red.shade700,
    Colors.green.shade700,
    Colors.blue.shade700,
    Colors.yellow.shade700,
    Colors.purple.shade700,
    Colors.orange.shade700,
    Colors.black,
    Colors.white,
    Colors.teal.shade700,
    Colors.pink.shade700,
    Colors.brown.shade700,
    Colors.indigo.shade700,
  ];

  // Cores de fundo do ladrilho
  Color _selectedBackgroundColor = Colors.white;
  final List<Color> _backgroundColorOptions = [
    Colors.white,
    Colors.grey.shade200,
    Colors.blue.shade100,
    Colors.green.shade100,
    Colors.red.shade100,
    Colors.yellow.shade100,
    Colors.purple.shade100,
    Colors.orange.shade100,
    Colors.black, // Dark background
    Colors.teal.shade100,
    Colors.pink.shade100,
    Colors.brown.shade100,
  ];

  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _totalSqMetersController =
      TextEditingController();

  int _calculatedQuantity = 0; // Quantidade de ladrilhos calculada

  final List<CartItem> _cartItems = []; // Lista de itens no carrinho

  @override
  void initState() {
    super.initState();
    _selectedTile =
        _availableTiles.first; // Seleciona o primeiro ladrilho por padrão
    // Adiciona listeners para atualizar a quantidade calculada dinamicamente
    _widthController.addListener(_updateCalculatedQuantity);
    _heightController.addListener(_updateCalculatedQuantity);
    _totalSqMetersController.addListener(_updateCalculatedQuantity);
  }

  @override
  void dispose() {
    _widthController.removeListener(_updateCalculatedQuantity);
    _heightController.removeListener(_updateCalculatedQuantity);
    _totalSqMetersController.removeListener(_updateCalculatedQuantity);
    _widthController.dispose();
    _heightController.dispose();
    _totalSqMetersController.dispose();
    super.dispose();
  }

  /// Atualiza a quantidade de ladrilhos calculada com base nas entradas.
  void _updateCalculatedQuantity() {
    double? width = double.tryParse(_widthController.text);
    double? height = double.tryParse(_heightController.text);
    double? totalSqMeters = double.tryParse(_totalSqMetersController.text);

    if (width != null &&
        height != null &&
        totalSqMeters != null &&
        width > 0 &&
        height > 0 &&
        totalSqMeters > 0) {
      double tileArea = width * height; // Área de um único ladrilho
      setState(() {
        _calculatedQuantity = (totalSqMeters / tileArea).ceil();
      });
    } else {
      setState(() {
        _calculatedQuantity = 0; // Reseta se as entradas são inválidas
      });
    }
  }

  /// Exibe uma mensagem na parte inferior da tela (SnackBar).
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blueGrey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  /// Adiciona o ladrilho configurado ao carrinho.
  void _addToCart() {
    if (_selectedTile == null) {
      _showMessage(
        'Por favor, selecione um ladrilho antes de adicionar ao carrinho.',
      );
      return;
    }

    double? width = double.tryParse(_widthController.text);
    double? height = double.tryParse(_heightController.text);
    double? totalSqMeters = double.tryParse(_totalSqMetersController.text);

    if (width == null ||
        height == null ||
        totalSqMeters == null ||
        width <= 0 ||
        height <= 0 ||
        totalSqMeters <= 0) {
      _showMessage('Por favor, insira dimensões e a área total em m² válidas.');
      return;
    }

    if (_calculatedQuantity <= 0) {
      _showMessage(
        'A quantidade calculada de ladrilhos deve ser maior que zero. Verifique as dimensões e a área total.',
      );
      return;
    }

    final newItem = CartItem(
      tile: _selectedTile!,
      selectedTileColor: _selectedTileColor,
      selectedBackgroundColor: _selectedBackgroundColor,
      width: width,
      height: height,
      totalSqMeters: totalSqMeters,
      quantity: _calculatedQuantity, // Usar a quantidade já calculada
    );

    setState(() {
      _cartItems.add(newItem);
    });

    _showMessage('Ladrilho "${_selectedTile!.name}" adicionado ao carrinho!');
    // Limpa os campos de entrada após adicionar ao carrinho
    _widthController.clear();
    _heightController.clear();
    _totalSqMetersController.clear();
    _updateCalculatedQuantity(); // Garante que a quantidade calculada seja resetada
  }

  /// Navega para a tela do carrinho.
  void _viewCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(cartItems: _cartItems),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loja de Ladrilhos'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (_cartItems.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_cartItems.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _viewCart,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha seu Ladrilho:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height:
                  130, // Altura ajustada para caber os cartões dos ladrilhos
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _availableTiles.length,
                itemBuilder: (context, index) {
                  final tile = _availableTiles[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTile = tile;
                      });
                    },
                    child: Card(
                      elevation: _selectedTile?.id == tile.id ? 10 : 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: _selectedTile?.id == tile.id
                            ? BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 4,
                              )
                            : BorderSide.none,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        width: 100, // Largura fixa para cada ladrilho na lista
                        padding: const EdgeInsets.all(8.0),
                        color: _selectedTile?.id == tile.id
                            ? _selectedBackgroundColor // Prévia com a cor de fundo selecionada
                            : Colors.transparent, // Ou uma cor padrão
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              tile.svgPath,
                              width: 60,
                              height: 60,
                              // Aplica a cor selecionada como um filtro,
                              // colorindo todas as partes não transparentes do SVG.
                              colorFilter: _selectedTile?.id == tile.id
                                  ? ColorFilter.mode(
                                      _selectedTileColor,
                                      BlendMode.srcIn,
                                    )
                                  : null, // Apenas o ladrilho selecionado mostra a prévia da cor
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tile.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Divider(),
            ),
            const Text(
              'Escolha a Cor Principal (SVG):',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tileColorOptions.length,
                itemBuilder: (context, index) {
                  final color = _tileColorOptions[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTileColor = color;
                      });
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _selectedTileColor == color
                            ? Border.all(color: Colors.black, width: 4)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Divider(),
            ),
            const Text(
              'Escolha a Cor de Fundo:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _backgroundColorOptions.length,
                itemBuilder: (context, index) {
                  final color = _backgroundColorOptions[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBackgroundColor = color;
                      });
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _selectedBackgroundColor == color
                            ? Border.all(color: Colors.black, width: 4)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Divider(),
            ),
            const Text(
              'Prévia do Ladrilho Selecionado:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Center(
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  color: _selectedBackgroundColor, // Aplica a cor de fundo aqui
                  padding: const EdgeInsets.all(20.0),
                  child: _selectedTile != null
                      ? SvgPicture.asset(
                          _selectedTile!.svgPath,
                          width: 180,
                          height: 180,
                          colorFilter: ColorFilter.mode(
                            _selectedTileColor,
                            BlendMode.srcIn,
                          ),
                        )
                      : const Text(
                          'Nenhum ladrilho selecionado para prévia.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Divider(),
            ),
            const Text(
              'Dimensões do Ladrilho (em metros):',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _widthController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Largura (ex: 0.3)',
                      hintText: '0.00',
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Altura (ex: 0.3)',
                      hintText: '0.00',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Text(
              'Área Total Necessária (em m²):',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _totalSqMetersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total de m² (ex: 10.5)',
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 20),
            // Exibição da quantidade calculada
            Center(
              child: Text(
                'Ladrilhos Necessários: $_calculatedQuantity unidades',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.add_shopping_cart, size: 28),
                label: const Text('Adicionar ao Carrinho'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(
                    double.infinity,
                    50,
                  ), // Botão de largura total
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}

/// A tela do carrinho, mostrando os itens adicionados e a opção de enviar o pedido.
class CartScreen extends StatelessWidget {
  final List<CartItem> cartItems;

  const CartScreen({super.key, required this.cartItems});

  /// Envia os detalhes do pedido via WhatsApp.
  Future<void> _sendOrderViaWhatsApp(BuildContext context) async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seu carrinho está vazio. Adicione itens para fazer um pedido.',
          ),
        ),
      );
      return;
    }

    String message =
        'Olá! Gostaria de fazer um pedido da sua loja de ladrilhos:\n\n';
    for (int i = 0; i < cartItems.length; i++) {
      final item = cartItems[i];
      // Converte as cores para formato hexadecimal (sem o canal alfa, que é o substring(2))
      // ignore: deprecated_member_use
      String tileColorHex = item.selectedTileColor.value
          .toRadixString(16)
          .substring(2)
          .toUpperCase();
      // ignore: deprecated_member_use
      String bgColorHex = item.selectedBackgroundColor.value
          .toRadixString(16)
          .substring(2)
          .toUpperCase();
      message += 'Item ${i + 1}:\n';
      message += '  Ladrilho: ${item.tile.name}\n';
      message += '  Cor Principal (SVG): #$tileColorHex\n';
      message += '  Cor de Fundo: #$bgColorHex\n';
      message += '  Dimensões do Ladrilho: ${item.width}m x ${item.height}m\n';
      message += '  Área Total Requerida: ${item.totalSqMeters} m²\n';
      message += '  Quantidade Estimada: ${item.quantity} unidades\n';
      message += '------------------------------------\n';
    }
    message += '\nObrigado!';

    // Codifica a mensagem para ser segura em uma URL.
    final Uri url = Uri.parse(
      'https://wa.me/47992680847${Uri.encodeComponent(message)}',
    );

    // Tenta abrir o WhatsApp com a mensagem pré-preenchida.
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
      appBar: AppBar(title: const Text('Meu Carrinho')),
      body: cartItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.remove_shopping_cart,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Seu carrinho está vazio!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Adicione alguns ladrilhos na tela inicial.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
                      // Converte as cores para formato hexadecimal
                      // ignore: deprecated_member_use
                      String tileColorHex = item.selectedTileColor.value
                          .toRadixString(16)
                          .substring(2)
                          .toUpperCase();
                      // ignore: deprecated_member_use
                      String bgColorHex = item.selectedBackgroundColor.value
                          .toRadixString(16)
                          .substring(2)
                          .toUpperCase();
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: item
                                      .selectedBackgroundColor, // Usa a cor de fundo selecionada
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: SvgPicture.asset(
                                  item.tile.svgPath,
                                  width: 80,
                                  height: 80,
                                  colorFilter: ColorFilter.mode(
                                    item.selectedTileColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.tile.name,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Cor Principal (SVG): #$tileColorHex',
                                      style: TextStyle(
                                        color: item.selectedTileColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Cor de Fundo: #$bgColorHex',
                                      style: TextStyle(
                                        color: item.selectedBackgroundColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Dimensões: ${item.width}m x ${item.height}m',
                                    ),
                                    Text(
                                      'Área Total: ${item.totalSqMeters} m²',
                                    ),
                                    Text(
                                      'Quantidade Estimada: ${item.quantity} unidades',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _sendOrderViaWhatsApp(context),
                    icon: const Icon(Icons.send, size: 28),
                    label: const Text('Enviar Pedido por WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF25D366,
                      ), // Cor verde do WhatsApp
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(
                        double.infinity,
                        55,
                      ), // Botão de largura total
                      elevation: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
    );
  }
}
