import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ladrilhos Cores da Roça',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const TileSelectionScreen(),
    );
  }
}

// models/tile_model.dart
class Tile {
  final String id;
  final String name;
  final String svgData; // Conteúdo SVG em string
  List<Color> currentColors; // Cores atuais das partes do ladrilho
  final List<String>
  colorablePartNames; // Nomes das partes coloríveis (ex: 'Fundo', 'Desenho')

  Tile({
    required this.id,
    required this.name,
    required this.svgData,
    required this.colorablePartNames,
    List<Color>? initialColors,
  }) : currentColors =
           initialColors ??
           List.generate(colorablePartNames.length, (index) => Colors.grey);

  // Criar uma cópia do ladrilho com novas cores
  Tile copyWith({List<Color>? currentColors}) {
    return Tile(
      id: id,
      name: name,
      svgData: svgData,
      colorablePartNames: colorablePartNames,
      initialColors: currentColors ?? this.currentColors,
    );
  }
}

class OrderItem {
  final Tile tile;
  final double widthCm;
  final double heightCm;
  final double quantityPerSqMeter; // Quantidade de ladrilhos por m²
  int orderQuantity; // Quantidade total a ser pedida

  OrderItem({
    required this.tile,
    required this.widthCm,
    required this.heightCm,
    required this.quantityPerSqMeter,
    this.orderQuantity = 1, // Default para 1
  });

  // Calcula a área do ladrilho em metros quadrados
  double get areaSqMeter => (widthCm / 100) * (heightCm / 100);

  // Calcula o custo (exemplo, você pode adicionar um preço base ao Tile)
  double get estimatedCost =>
      orderQuantity * 10.0; // Exemplo: R$10 por ladrilho
}

// Data simulada (Substitua por seus próprios SVGs e configurações de cores)
final List<Tile> availableTiles = [
  Tile(
    id: 'tile_001',
    name: 'Ladrilho Geométrico',
    svgData: '''
      <svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
        <rect id="background" x="0" y="0" width="200" height="200" fill="#E0E0E0"/>
        <circle id="center_circle" cx="100" cy="100" r="60" fill="#4CAF50"/>
        <rect id="corner_square" x="20" y="20" width="30" height="30" fill="#FFC107"/>
        <rect id="corner_square_2" x="150" y="150" width="30" height="30" fill="#2196F3"/>
      </svg>
    ''',
    colorablePartNames: [
      'Fundo',
      'Círculo Central',
      'Quadrado Superior Esquerdo',
      'Quadrado Inferior Direito',
    ],
    initialColors: [
      Colors.blueGrey[100]!,
      Colors.green,
      Colors.amber,
      Colors.blue,
    ],
  ),
  Tile(
    id: 'tile_002',
    name: 'Ladrilho Floral',
    svgData: '''
      <svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
        <rect id="background" x="0" y="0" width="200" height="200" fill="#F0F0F0"/>
        <path id="flower_petal" d="M100 20 L120 80 L180 100 L120 120 L100 180 L80 120 L20 100 L80 80 Z" fill="#9C27B0"/>
        <circle id="flower_center" cx="100" cy="100" r="20" fill="#FFEB3B"/>
      </svg>
    ''',
    colorablePartNames: ['Fundo', 'Pétala', 'Centro da Flor'],
    initialColors: [Colors.purple[50]!, Colors.deepPurple, Colors.yellow],
  ),
  Tile(
    id: 'tile_003',
    name: 'Ladrilho com Padrão',
    svgData: '''
      <svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
        <rect id="background" x="0" y="0" width="200" height="200" fill="#E8F5E9"/>
        <line id="line_1" x1="10" y1="10" x2="190" y2="190" stroke="#FF5722" stroke-width="5"/>
        <line id="line_2" x1="10" y1="190" x2="190" y2="10" stroke="#009688" stroke-width="5"/>
        <circle id="corner_dot_1" cx="10" cy="10" r="8" fill="#FFC107"/>
        <circle id="corner_dot_2" cx="190" cy="10" r="8" fill="#FFC107"/>
        <circle id="corner_dot_3" cx="10" cy="190" r="8" fill="#FFC107"/>
        <circle id="corner_dot_4" cx="190" cy="190" r="8" fill="#FFC107"/>
      </svg>
    ''',
    colorablePartNames: [
      'Fundo',
      'Linha Diagonal 1',
      'Linha Diagonal 2',
      'Pontos dos Cantos',
    ],
    initialColors: [
      Colors.green[50]!,
      Colors.deepOrange,
      Colors.teal,
      Colors.amber,
    ],
  ),
];

// Global list para o carrinho
List<OrderItem> cart = [];

// screens/tile_selection_screen.dart
class TileSelectionScreen extends StatelessWidget {
  const TileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecione seu Ladrilho'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.8, // Ajuste para melhor visualização
        ),
        itemCount: availableTiles.length,
        itemBuilder: (context, index) {
          final tile = availableTiles[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TileCustomizationScreen(tile: tile),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SvgPicture.string(
                        _replaceSvgColors(
                          tile.svgData,
                          tile.currentColors,
                          tile.colorablePartNames,
                        ),
                        width: 120,
                        height: 120,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tile.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Função auxiliar para substituir cores no SVG
  String _replaceSvgColors(
    String svgData,
    List<Color> colors,
    List<String> partNames,
  ) {
    String newSvgData = svgData;
    for (int i = 0; i < partNames.length && i < colors.length; i++) {
      // ignore: unused_local_variable
      String hexColor =
          // ignore: deprecated_member_use
          '#${colors[i].value.toRadixString(16).substring(2).toUpperCase()}';
      // Este é um método simplificado. Em um SVG real, você procuraria por IDs.
      // Aqui, estamos substituindo as cores iniciais no SVG de exemplo.
      // Para um uso mais robusto, você precisaria de parsing de SVG.

      // Exemplo de como você poderia tentar substituir uma cor se soubesse o valor hex original
      // do SVG. Isso é muito frágil e depende do SVG ser bem consistente.
      // Uma abordagem melhor seria ter um mapa de ID para cor e renderizar o SVG programaticamente.
      // Para o exemplo, vamos apenas "simular" que as cores são aplicadas ao renderizar.
      // O SvgPicture.string já está usando o SVG original, o que precisamos é que
      // o SVG _contenha_ as cores corretas para as partes.
      // A biblioteca flutter_svg permite usar um `colorFilter` ou um `theme`.
      // Para este exemplo, a mudança de cor será mais visualizada na tela de customização.
      // Para a pré-visualização, teríamos que injetar as cores no próprio SVG.

      // Por enquanto, a pré-visualização no GridView só mostra o SVG original com suas cores.
      // A customização real acontece na próxima tela.
    }
    return newSvgData;
  }
}

// screens/tile_customization_screen.dart
class TileCustomizationScreen extends StatefulWidget {
  final Tile tile;

  const TileCustomizationScreen({super.key, required this.tile});

  @override
  State<TileCustomizationScreen> createState() =>
      _TileCustomizationScreenState();
}

class _TileCustomizationScreenState extends State<TileCustomizationScreen> {
  late Tile _currentTile;
  final TextEditingController _widthController = TextEditingController(
    text: '20',
  );
  final TextEditingController _heightController = TextEditingController(
    text: '20',
  );
  double _quantityPerSqMeter = 0.0;
  int _orderQuantity = 1;

  @override
  void initState() {
    super.initState();
    _currentTile = widget.tile
        .copyWith(); // Criar uma cópia para evitar modificar o original
    _calculateQuantityPerSqMeter();
    _widthController.addListener(_calculateQuantityPerSqMeter);
    _heightController.addListener(_calculateQuantityPerSqMeter);
  }

  @override
  void dispose() {
    _widthController.removeListener(_calculateQuantityPerSqMeter);
    _heightController.removeListener(_calculateQuantityPerSqMeter);
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // Função para calcular ladrilhos por m²
  void _calculateQuantityPerSqMeter() {
    final double? width = double.tryParse(_widthController.text);
    final double? height = double.tryParse(_heightController.text);

    if (width != null && height != null && width > 0 && height > 0) {
      final double areaCm2 = width * height;
      final double areaM2 = areaCm2 / 10000; // Converter cm² para m²
      setState(() {
        _quantityPerSqMeter = 1.0 / areaM2;
      });
    } else {
      setState(() {
        _quantityPerSqMeter = 0.0;
      });
    }
  }

  // Função para abrir o seletor de cores
  Future<void> _pickColor(int partIndex) async {
    Color? pickedColor = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return ColorPickerDialog(
          initialColor: _currentTile.currentColors[partIndex],
        );
      },
    );

    if (pickedColor != null) {
      setState(() {
        _currentTile.currentColors[partIndex] = pickedColor;
      });
    }
  }

  // Função para renderizar o SVG com as cores personalizadas
  // Nota: Esta função é uma simulação. Para colorir partes específicas de um SVG
  // com base em IDs ou classes, você precisaria de um parser de SVG mais avançado
  // ou SVGs preparados com atributos que permitam substituição fácil.
  // Para este exemplo, estamos substituindo as cores "iniciais" ou padrão do SVG.
  Widget _buildCustomizedSvg(Tile tile) {
    // ignore: unused_local_variable
    String modifiedSvgData = tile.svgData;
    // Substituições de exemplo baseadas em IDs ou padrões simples no SVG
    // Isso é um hack e depende do SVG ter IDs específicos e cores iniciais previsíveis.
    // Para um sistema robusto, considere:
    // 1. Usar SvgPicture.asset e um SVG que tenha variáveis de estilo ou que possa ser re-gerado.
    // 2. Ter um parser de SVG que altere os atributos 'fill' ou 'stroke' de elementos por ID.
    // 3. Usar `colorFilter` ou `theme` do `flutter_svg` se seu SVG for simples o suficiente.

    // Para este exemplo, vamos supor que as partes coloríveis no SVG têm cores iniciais
    // que podemos encontrar e substituir. Este é um método MUITO FRÁGIL.
    // A melhor prática seria ter os SVGs como componentes ou ter uma lógica de parsing real.

    // As cores são mapeadas para as "partes" abstratas.
    // O SvgPicture.string renderizará o SVG como está.
    // Para realmente mudar as cores das partes, teríamos que injetar CSS ou
    // manipular os fills/strokes do SVG antes de passá-lo para SvgPicture.string.
    // Para o propósito deste app, vamos mostrar as cores selecionadas no UI
    // e o SVG permanecerá com suas cores originais, indicando uma limitação
    // desta abordagem simplificada.

    // Para demonstrar a aplicação das cores no SVG, teríamos que modificar o 'fill' ou 'stroke'
    // dos elementos dentro da string SVG. Exemplo:
    // Suponha que o SVG tenha `<rect id="background" fill="#E0E0E0"/>`
    // Você poderia fazer:
    // modifiedSvgData = modifiedSvgData.replaceAll('fill="#E0E0E0"', 'fill="#${tile.currentColors[0].value.toRadixString(16).substring(2).toUpperCase()}"');
    // ... e assim por diante para cada parte.
    // Isso é tedioso e propenso a erros.

    // Simplificando para a demonstração: o `SvgPicture.string` apenas exibe o SVG base.
    // As cores escolhidas são mostradas abaixo do SVG para fins de feedback.

    // Para realmente ver a mudança, vamos aplicar um `ColorFilter` ao SVG.
    // Isso não é para partes individuais, mas para o SVG como um todo ou para uma parte.
    // Se você tem um SVG com IDs, pode usar um custom `SvgTheme` ou `colorFilter`.

    // Para simular a mudança de cor por partes, precisaríamos de um parser de SVG que pudesse
    // encontrar e modificar os atributos `fill` ou `stroke` por ID.
    // Exemplo muito simplificado e manual para demonstrar:
    String svgToDisplay = tile.svgData;
    // Substitui as cores de cada parte colorível no SVG, assumindo que as cores originais
    // estão presentes nos IDs correspondentes no SVG. Isso é uma suposição perigosa.
    // Para os SVGs de exemplo, usei cores hex específicas que podemos tentar substituir.
    // 'tile_001': Fundo (#E0E0E0), Círculo Central (#4CAF50), Quadrado Superior Esquerdo (#FFC107), Quadrado Inferior Direito (#2196F3)
    // 'tile_002': Fundo (#F0F0F0), Pétala (#9C27B0), Centro da Flor (#FFEB3B)
    // 'tile_003': Fundo (#E8F5E9), Linha Diagonal 1 (#FF5722), Linha Diagonal 2 (#009688), Pontos dos Cantos (#FFC107)

    if (tile.id == 'tile_001') {
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#E0E0E0"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[0].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#4CAF50"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[1].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#FFC107"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[2].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#2196F3"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[3].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
    } else if (tile.id == 'tile_002') {
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#F0F0F0"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[0].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#9C27B0"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[1].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#FFEB3B"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[2].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
    } else if (tile.id == 'tile_003') {
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#E8F5E9"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[0].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      // Para linhas, também pode ser `stroke`
      svgToDisplay = svgToDisplay.replaceAll(
        'stroke="#FF5722"',
        // ignore: deprecated_member_use
        'stroke="#${tile.currentColors[1].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      svgToDisplay = svgToDisplay.replaceAll(
        'stroke="#009688"',
        // ignore: deprecated_member_use
        'stroke="#${tile.currentColors[2].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      // Pontos podem ser preenchimento
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#FFC107"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[3].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
    }

    return SvgPicture.string(
      svgToDisplay,
      width: 200,
      height: 200,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personalizar ${_currentTile.name}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildCustomizedSvg(_currentTile),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Cores do Ladrilho:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: List.generate(_currentTile.colorablePartNames.length, (
                index,
              ) {
                return GestureDetector(
                  onTap: () => _pickColor(index),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _currentTile.currentColors[index],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        _currentTile.colorablePartNames[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              _currentTile.currentColors[index]
                                      .computeLuminance() >
                                  0.5
                              ? Colors.black
                              : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Text(
              'Dimensões do Ladrilho (cm):',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _widthController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Largura (cm)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixText: 'cm',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Altura (cm)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixText: 'cm',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Ladrilhos por m²: ${_quantityPerSqMeter.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Quantidade para Pedido:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_orderQuantity > 1) {
                      setState(() {
                        _orderQuantity--;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    _orderQuantity.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _orderQuantity++;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                final double? width = double.tryParse(_widthController.text);
                final double? height = double.tryParse(_heightController.text);

                if (width == null ||
                    height == null ||
                    width <= 0 ||
                    height <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Por favor, insira dimensões válidas para o ladrilho.',
                      ),
                    ),
                  );
                  return;
                }

                final orderItem = OrderItem(
                  tile: _currentTile
                      .copyWith(), // Adiciona uma cópia profunda para o carrinho
                  widthCm: width,
                  heightCm: height,
                  quantityPerSqMeter: _quantityPerSqMeter,
                  orderQuantity: _orderQuantity,
                );
                cart.add(orderItem);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${orderItem.tile.name} adicionado ao carrinho!',
                    ),
                  ),
                );
                Navigator.pop(context); // Volta para a tela de seleção
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Adicionar ao Carrinho'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// widgets/color_picker_dialog.dart
class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const ColorPickerDialog({super.key, required this.initialColor});

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecione uma Cor'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // Exemplo de algumas cores predefinidas
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _buildColorOption(Colors.red),
                _buildColorOption(Colors.pink),
                _buildColorOption(Colors.purple),
                _buildColorOption(Colors.deepPurple),
                _buildColorOption(Colors.indigo),
                _buildColorOption(Colors.blue),
                _buildColorOption(Colors.lightBlue),
                _buildColorOption(Colors.cyan),
                _buildColorOption(Colors.teal),
                _buildColorOption(Colors.green),
                _buildColorOption(Colors.lightGreen),
                _buildColorOption(Colors.lime),
                _buildColorOption(Colors.yellow),
                _buildColorOption(Colors.amber),
                _buildColorOption(Colors.orange),
                _buildColorOption(Colors.deepOrange),
                _buildColorOption(Colors.brown),
                _buildColorOption(Colors.grey),
                _buildColorOption(Colors.blueGrey),
                _buildColorOption(Colors.black),
                _buildColorOption(Colors.white),
              ],
            ),
            const SizedBox(height: 20),
            // Indicador da cor atual
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _currentColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black),
              ),
              child: Center(
                child: Text(
                  'Cor Atual',
                  style: TextStyle(
                    color: _currentColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null); // Cancela
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop(_currentColor); // Retorna a cor selecionada
          },
          child: const Text('Selecionar'),
        ),
      ],
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentColor = color;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _currentColor == color ? Colors.teal : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}

// screens/cart_screen.dart
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  void _removeItem(int index) {
    setState(() {
      cart.removeAt(index);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item removido do carrinho.')));
  }

  void _sendOrderViaWhatsApp() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seu carrinho está vazio!')));
      return;
    }

    String message =
        'Olá! Gostaria de fazer o seguinte pedido de ladrilhos:\n\n';
    double totalEstimatedCost = 0.0;

    for (int i = 0; i < cart.length; i++) {
      final item = cart[i];
      message += '--- Item ${i + 1} ---\n';
      message += 'Ladrilho: ${item.tile.name}\n';
      message +=
          'Dimensões: ${item.widthCm.toStringAsFixed(1)}cm x ${item.heightCm.toStringAsFixed(1)}cm\n';
      message +=
          'Quantidade por m²: ${item.quantityPerSqMeter.toStringAsFixed(2)}\n';
      message += 'Quantidade Total: ${item.orderQuantity} unidades\n';
      message += 'Cores Personalizadas: ';
      for (int j = 0; j < item.tile.colorablePartNames.length; j++) {
        message +=
            // ignore: deprecated_member_use
            '${item.tile.colorablePartNames[j]}: #${item.tile.currentColors[j].value.toRadixString(16).substring(2).toUpperCase()} ';
      }
      message += '\n';
      totalEstimatedCost += item.estimatedCost;
      message +=
          'Custo Estimado deste item: R\$${item.estimatedCost.toStringAsFixed(2)}\n\n';
    }

    message +=
        'Custo Total Estimado do Pedido: R\$${totalEstimatedCost.toStringAsFixed(2)}\n';
    message +=
        'Aguardamos seu contato para finalizar os detalhes e o pagamento.';

    // Número de telefone para WhatsApp (com código do país, sem '+' ou '00')
    const String whatsappNumber = '5547992680847'; // Substitua pelo seu número

    final Uri whatsappUrl = Uri.parse(
      'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o WhatsApp. Verifique se o aplicativo está instalado.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seu Carrinho'), centerTitle: true),
      body: cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Seu carrinho está vazio!',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              SvgPicture.string(
                                // Note: Aqui estamos usando a string SVG original para evitar complexidade
                                // de re-renderizar o SVG com as cores atualizadas para a pré-visualização no carrinho.
                                // Para um app real, você pode querer renderizar o SVG com as cores personalizadas.
                                _replaceSvgColorsForDisplay(item.tile),
                                width: 80,
                                height: 80,
                              ),
                              const SizedBox(width: 16),
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
                                    Text(
                                      'Dimensões: ${item.widthCm.toStringAsFixed(1)}cm x ${item.heightCm.toStringAsFixed(1)}cm',
                                    ),
                                    Text(
                                      'Qtd. por m²: ${item.quantityPerSqMeter.toStringAsFixed(2)}',
                                    ),
                                    Text(
                                      'Quantidade Total: ${item.orderQuantity}',
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      // ignore: deprecated_member_use
                                      'Cores: ${item.tile.currentColors.map((c) => '#${c.value.toRadixString(16).substring(2).toUpperCase()}').join(', ')}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Custo Estimado: R\$${item.estimatedCost.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeItem(index),
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
                    onPressed: _sendOrderViaWhatsApp,
                    //icon: const Icon(Icons.whatsapp),
                    label: const Text('Enviar Pedido via WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(
                        double.infinity,
                        50,
                      ), // Botão de largura total
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Função auxiliar para substituir cores no SVG para exibição no carrinho
  String _replaceSvgColorsForDisplay(Tile tile) {
    String svgToDisplay = tile.svgData;
    // Repete a lógica de substituição de cores aqui para garantir que o SVG exibido
    // no carrinho reflita as cores personalizadas.
    if (tile.id == 'tile_001') {
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#E0E0E0"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[0].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#4CAF50"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[1].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#FFC107"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[2].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#2196F3"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[3].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
    } else if (tile.id == 'tile_002') {
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#F0F0F0"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[0].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#9C27B0"',
        'fill="#${tile.currentColors[1].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#FFEB3B"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[2].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
    } else if (tile.id == 'tile_003') {
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#E8F5E9"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[0].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      svgToDisplay = svgToDisplay.replaceAll(
        'stroke="#FF5722"',
        // ignore: deprecated_member_use
        'stroke="#${tile.currentColors[1].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      svgToDisplay = svgToDisplay.replaceAll(
        'stroke="#009688"',
        // ignore: deprecated_member_use
        'stroke="#${tile.currentColors[2].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
      svgToDisplay = svgToDisplay.replaceAll(
        'fill="#FFC107"',
        // ignore: deprecated_member_use
        'fill="#${tile.currentColors[3].value.toRadixString(16).substring(2).toUpperCase()}"',
      );
    }
    return svgToDisplay;
  }
}
