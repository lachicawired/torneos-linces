import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

// --- 1. INICIALIZACIÓN ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBelDg7817n5Ac1g2qaDsyTpDW5Nl_JGY0",
          authDomain: "cecyte-ajedrez.firebaseapp.com",
          projectId: "cecyte-ajedrez",
          storageBucket: "cecyte-ajedrez.firebasestorage.app",
          messagingSenderId: "134933282038",
          appId: "1:134933282038:web:f874e24d305625239f00d7",
          measurementId: "G-TWFTTDLJ2X",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    print("Modo Offline: $e");
  }
  runApp(const LincesManagerApp());
}

// --- CLASE JUGADOR ---
class Jugador {
  String id;
  String nombre;
  int elo;
  double puntos;
  double desempate;

  Jugador({this.id = '', required this.nombre, required this.elo, this.puntos = 0.0, this.desempate = 0.0});
}

class LincesManagerApp extends StatelessWidget {
  const LincesManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Torneos Linces',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF262626),
        primaryColor: const Color(0xFFD4AF37),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF262626),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFF8B1D22),
        ),
      ),
      home: const PantallaBienvenida(),
    );
  }
}

// --- PANTALLA 1: BIENVENIDA ---
class PantallaBienvenida extends StatelessWidget {
  const PantallaBienvenida({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF262626),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.2), blurRadius: 30)]
                ),
                child: Image.asset('assets/images/lince_logo.png', height: 160),
              ),
              const SizedBox(height: 40),
              const Text("TORNEOS LINCES", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37), letterSpacing: 1.5)),
              const Text("MANAGER", style: TextStyle(fontSize: 14, color: Colors.white38, letterSpacing: 6.0)),
              const SizedBox(height: 60),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1D22),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 10,
                  shadowColor: Colors.black,
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaConfiguracion())),
                child: const Text("GESTIONAR TORNEO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- PANTALLA 2: CONFIGURACIÓN ---
class PantallaConfiguracion extends StatefulWidget {
  const PantallaConfiguracion({super.key});

  @override
  State<PantallaConfiguracion> createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _eloCtrl = TextEditingController();
  List<Jugador> jugadores = [];
  String _tipoTorneo = 'Suizo';

  // --- LÓGICA DE PERSISTENCIA (Sugerida por el Profe) ---
  // Esta función implementa el .set() con merge: true para evitar duplicados.
  // Usamos el nombre como ID para que el Manager identifique a los alumnos rápidamente.
  Future<void> _guardarOActualizarJugadorDB(Jugador j) async {
    await FirebaseFirestore.instance.collection('jugadores').doc(j.nombre).set({
      'nombre': j.nombre,
      'elo': j.elo,
      'ultima_partida': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Muestra un menú con los jugadores de la base de datos
  void _mostrarMenuJugadoresRecientes() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF262626),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jugadores')
                  .orderBy('ultima_partida', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No hay jugadores registrados"));

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Text("SELECCIONAR JUGADORES RECIENTES", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, i) {
                          var data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
                          bool yaEsta = jugadores.any((j) => j.nombre == data['nombre']);
                          return ListTile(
                            title: Text(data['nombre'], style: TextStyle(color: yaEsta ? Colors.grey : Colors.white)),
                            subtitle: Text("ELO: ${data['elo']}"),
                            trailing: yaEsta ? const Icon(Icons.check, color: Colors.green) : const Icon(Icons.add, color: Color(0xFFD4AF37)),
                            onTap: yaEsta ? null : () {
                              setState(() {
                                jugadores.add(Jugador(nombre: data['nombre'], elo: data['elo'] ?? 1200));
                              });
                              setModalState(() {}); // Esto refresca el menú interno
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          }
        );
      },
    );
  }

  void _agregarJugador() {
    if (_nombreCtrl.text.isNotEmpty) {
      final nuevoJugador = Jugador(
        nombre: _nombreCtrl.text,
        elo: int.tryParse(_eloCtrl.text) ?? 1200,
      );
      setState(() {
        jugadores.add(nuevoJugador);
      });
      _guardarOActualizarJugadorDB(nuevoJugador); // Persistencia sugerida
      _nombreCtrl.clear();
      _eloCtrl.clear();
    }
  }

  int _calcularRondasEstimadas() {
    int n = jugadores.length;
    if (n < 2) return 0;
    if (_tipoTorneo == 'Suizo') {
      int r = (log(n) / log(2)).ceil();
      return r < 3 ? 3 : r;
    } else if (_tipoTorneo == 'Round Robin') {
      return (n % 2 == 0) ? n - 1 : n;
    } else {
      return (log(n) / log(2)).ceil();
    }
  }

  void _validarEIniciar() {
    int n = jugadores.length;
    if (_tipoTorneo == 'Suizo' && n < 4) { _mostrarError("Suizo requiere mínimo 4 jugadores."); return; }
    if (_tipoTorneo == 'Round Robin' && n < 3) { _mostrarError("Round Robin requiere mínimo 3 jugadores."); return; }
    if (_tipoTorneo == 'Eliminatoria') {
      bool esPotencia = (n > 0) && ((n & (n - 1)) == 0);
      if (n < 4 || !esPotencia) { _mostrarError("Eliminatoria requiere 4, 8, 16, 32 jugadores."); return; }
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaTorneo(jugadoresInscritos: jugadores, tipoTorneo: _tipoTorneo)));
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  String _obtenerReglasTexto() {
    if (_tipoTorneo == 'Suizo') return "📌 Sistema Buchholz.\nIdeal para muchos jugadores. Mínimo 4 jugadores.";
    else if (_tipoTorneo == 'Round Robin') return "📌 Sistema Sonneborn-Berger.\nLiga: Todos contra todos. Mínimo 3 jugadores.";
    else return "📌 Muerte Súbita.\nEl que pierde queda fuera. Requiere 4, 8, 16, 32 jugadores.";
  }

  @override
  Widget build(BuildContext context) {
    int rondas = _calcularRondasEstimadas();

    return Scaffold(
      appBar: AppBar(
        title: const Text("CONFIGURAR TORNEO", style: TextStyle(letterSpacing: 1.5, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book, color: Colors.white),
            tooltip: "Ver Reglamento",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaReglas()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download, color: Colors.white),
            tooltip: "Cargar Jugadores Existentes",
            onPressed: _mostrarMenuJugadoresRecientes,
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: "Ver Historial de Torneos",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaHistorial()));
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF262626),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _tipoTorneo,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF262626),
                    items: <String>['Suizo', 'Round Robin', 'Eliminatoria'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)));
                    }).toList(),
                    onChanged: (val) => setState(() => _tipoTorneo = val!),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF262626).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(_obtenerReglasTexto(), style: const TextStyle(color: Colors.white54, fontSize: 12))),
                    Column(
                      children: [
                        const Text("RONDAS", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("$rondas", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(flex: 2, child: _input("Nombre", _nombreCtrl)),
                const SizedBox(width: 10),
                Expanded(flex: 1, child: _input("ELO", _eloCtrl, numero: true)),
                const SizedBox(width: 10),
                IconButton(onPressed: _agregarJugador, icon: const Icon(Icons.add_circle, color: Color(0xFFD4AF37), size: 45))
              ]),
              const SizedBox(height: 20),
              Expanded(
                child: jugadores.isEmpty
                ? const Center(child: Text("No hay jugadores inscritos", style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    itemCount: jugadores.length,
                    itemBuilder: (context, i) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(radius: 15, backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1), child: Text("${i+1}", style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold))),
                        title: Text(jugadores[i].nombre, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text("ELO: ${jugadores[i].elo}", style: const TextStyle(color: Colors.white24, fontSize: 11)),
                        trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF8B1D22), size: 20), onPressed: () => setState(() => jugadores.removeAt(i))),
                      ),
                    ),
                  ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1D22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 8,
                  ),
                  onPressed: _validarEIniciar,
                  child: const Text("INICIAR COMPETENCIA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(String hint, TextEditingController ctrl, {bool numero = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: numero ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF262626).withOpacity(0.8),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
    );
  }
}

// --- PANTALLA: REGLAMENTO ---
class PantallaReglas extends StatelessWidget {
  const PantallaReglas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("REGLAMENTO", style: TextStyle(letterSpacing: 1.5, fontSize: 16)),
      ),
      body: Container(
        color: const Color(0xFF262626),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildReglaCard(
              "A. SISTEMA SUIZO",
              "Es el formato estándar para torneos con muchos participantes. No elimina a nadie; todos juegan todas las rondas previstas.",
              "Funcionamiento: Los jugadores con puntuaciones similares se enfrentan entre sí. Los ganadores juegan contra ganadores y los perdedores contra perdedores. Evita que los mejores se eliminen al principio.",
              "Desempate (Buchholz): Suma los puntos finales de todos los oponentes contra los que jugaste. Si enfrentaste a rivales más fuertes, tu desempate será mayor."
            ),
            _buildReglaCard(
              "B. ROUND ROBIN (TODOS CONTRA TODOS)",
              "Considerado el sistema más justo, utilizado en ligas o grupos pequeños.",
              "Funcionamiento: Cada participante juega contra todos los demás exactamente una vez. Se utiliza el algoritmo de Berger para asegurar que las rotaciones de colores (blancas/negras) sean equitativas.",
              "Desempate (Sonneborn-Berger): Suma los puntos totales de los oponentes a los que venciste, más la mitad de los puntos de los oponentes con los que empataste."
            ),
            _buildReglaCard(
              "C. ELIMINATORIA DIRECTA",
              "El formato más rápido y emocionante, ideal para finales de copa (Muerte Súbita).",
              "Funcionamiento: Los jugadores se emparejan en llaves. El ganador avanza a la siguiente fase (Cuartos, Semifinal, Final) y el perdedor queda fuera del torneo.",
              "Requisito: Funciona óptimamente con potencias de 2 (4, 8, 16 o 32 jugadores)."
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReglaCard(String titulo, String desc, String func, String desempate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF262626).withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.1)),
          const SizedBox(height: 12),
          Text(desc, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          Text(func, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          Text(desempate, style: const TextStyle(color: Color(0xFF8B1D22), fontSize: 12, fontWeight: FontWeight.w600, height: 1.4)),
        ],
      ),
    );
  }
}

// --- PANTALLA NUEVA: HISTORIAL DE TORNEOS ---
class PantallaHistorial extends StatelessWidget {
  const PantallaHistorial({super.key});

  Color _getPosColor(int index) {
    if (index == 0) return const Color(0xFFD4AF37); // Oro
    if (index == 1) return const Color(0xFFC0C0C0); // Plata
    if (index == 2) return const Color(0xFFCD7F32); // Bronce
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("HISTORIAL DE TORNEOS", style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w300)),
        backgroundColor: const Color(0xFF262626),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFF262626),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('torneos_resultados')
              .orderBy('fecha', descending: true)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return _errorWidget(snapshot.error.toString());
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No hay registros aún.", style: TextStyle(color: Colors.grey)));

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                var data = doc.data() as Map<String, dynamic>;
                DateTime fecha = (data['fecha'] as Timestamp).toDate();
                String fechaStr = "${fecha.day}/${fecha.month}/${fecha.year}";
                String ganador = data['ganador'] ?? "N/A";
                List ranking = data['clasificacion'] ?? [];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262626).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 8))
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      iconColor: const Color(0xFFD4AF37),
                      collapsedIconColor: Colors.white54,
                      leading: _buildTrophy(0), // Icono principal
                      title: Text(
                        ganador.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.5),
                      ),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF8B1D22).withOpacity(0.8), borderRadius: BorderRadius.circular(4)),
                            child: Text(data['tipo'].toString().toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              fechaStr,
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          Text("${ranking.length} JUG.", style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          alignment: Alignment.centerLeft,
                          child: const Text("RANKING FINAL", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        ),
                        if (ranking.isNotEmpty)
                          ...ranking.asMap().entries.map((entry) {
                            int idx = entry.key;
                            var j = entry.value;
                            Color posColor = _getPosColor(idx);
                            return ListTile(
                              visualDensity: VisualDensity.compact,
                              dense: true,
                              leading: Container(
                                width: 30,
                                alignment: Alignment.center,
                                child: Text("${idx + 1}º", style: TextStyle(color: posColor, fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(
                                j['nombre'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: idx < 3 ? Colors.white : Colors.white60, fontSize: 14),
                              ),
                              subtitle: Text("BUCHHOLZ: ${j['desempate']}", style: const TextStyle(fontSize: 9, color: Colors.white24)),
                              trailing: Text("${j['puntos']} PTS", style: TextStyle(color: posColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            );
                          }),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrophy(int index) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getPosColor(index).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.emoji_events_outlined, color: _getPosColor(index), size: 22),
    );
  }

  Widget _errorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_fix_off, color: Color(0xFF8B1D22), size: 50),
          Text("Error de sincronización: $error", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatoResultado(dynamic res) {
    if (res == 1.0) return "1 - 0";
    if (res == 0.0) return "0 - 1";
    if (res == 0.5) return "½ - ½";
    return "? - ?";
  }
}

// --- PANTALLA 3: MANAGER ---
class PantallaTorneo extends StatefulWidget {
  final List<Jugador> jugadoresInscritos;
  final String tipoTorneo;
  const PantallaTorneo({required this.jugadoresInscritos, required this.tipoTorneo, super.key});

  @override
  State<PantallaTorneo> createState() => _PantallaTorneoState();
}

class _PantallaTorneoState extends State<PantallaTorneo> {
  int rondaActual = 1;
  int totalRondas = 0;
  List<Map<String, dynamic>> emparejamientos = [];
  List<Map<String, dynamic>> historialCompleto = [];
  List<Jugador> _copiaRR = [];

  @override
  void initState() {
    super.initState();
    _calcularTotalRondas();
    if (widget.tipoTorneo == 'Round Robin') _inicializarRoundRobin();
    _generarRonda();
  }

  void _calcularTotalRondas() {
    int n = widget.jugadoresInscritos.length;
    if (widget.tipoTorneo == 'Suizo' || widget.tipoTorneo == 'Eliminatoria') {
      totalRondas = (log(n) / log(2)).ceil();
      if (widget.tipoTorneo == 'Suizo' && totalRondas < 3) totalRondas = 3;
    } else {
      totalRondas = (n % 2 == 0) ? n - 1 : n;
    }
  }

  void _inicializarRoundRobin() {
    _copiaRR = List.from(widget.jugadoresInscritos);
    if (_copiaRR.length % 2 != 0) _copiaRR.add(Jugador(nombre: "BYE", elo: 0));
  }

  void _generarRonda() {
    emparejamientos.clear();
    if (widget.tipoTorneo == 'Suizo') _logicSuizo();
    else if (widget.tipoTorneo == 'Round Robin') _logicRoundRobinBerger();
    else _logicEliminatoria();
    setState(() {});
  }

  void _logicSuizo() {
    widget.jugadoresInscritos.sort((a, b) {
      int cmp = b.puntos.compareTo(a.puntos);
      if (cmp != 0) return cmp;
      return b.elo.compareTo(a.elo);
    });
    List<Jugador> disp = List.from(widget.jugadoresInscritos);
    while (disp.isNotEmpty) {
      if (disp.length == 1) { disp[0].puntos += 1.0; disp.removeAt(0); }
      else {
        emparejamientos.add({'blancas': disp[0], 'negras': disp[1], 'resultado': null});
        disp.removeRange(0, 2);
      }
    }
  }

  void _logicRoundRobinBerger() {
    int n = _copiaRR.length;
    int mitad = n ~/ 2;
    for (int i = 0; i < mitad; i++) {
      Jugador p1 = _copiaRR[i];
      Jugador p2 = _copiaRR[n - 1 - i];
      if (p1.nombre != "BYE" && p2.nombre != "BYE") {
        emparejamientos.add({'blancas': (rondaActual % 2 != 0) ? p1 : p2, 'negras': (rondaActual % 2 != 0) ? p2 : p1, 'resultado': null});
      } else {
        if (p1.nombre != "BYE") p1.puntos += 1.0;
        if (p2.nombre != "BYE") p2.puntos += 1.0;
      }
    }
  }

  void _rotarRoundRobin() {
    Jugador ultimo = _copiaRR.removeLast();
    _copiaRR.insert(1, ultimo);
  }

  void _logicEliminatoria() {
    widget.jugadoresInscritos.sort((a, b) => b.puntos.compareTo(a.puntos));
    int vivos = widget.jugadoresInscritos.length ~/ pow(2, rondaActual - 1);
    for (int i = 0; i < vivos; i += 2) {
      emparejamientos.add({'blancas': widget.jugadoresInscritos[i], 'negras': widget.jugadoresInscritos[i+1], 'resultado': null});
    }
  }

  void _setResultado(int index, double pB, double pN) {
    setState(() {
      var match = emparejamientos[index];
      if (match['resultado'] != null) {
        double resAnt = match['resultado'];
        (match['blancas'] as Jugador).puntos -= resAnt;
        (match['negras'] as Jugador).puntos -= (1.0 - resAnt);
      }
      match['resultado'] = pB;
      (match['blancas'] as Jugador).puntos += pB;
      (match['negras'] as Jugador).puntos += pN;
    });
  }

  void _calcularDesempatesFinales() {
    for (var jugador in widget.jugadoresInscritos) {
      jugador.desempate = 0.0;
    }
    for (var match in historialCompleto) {
      Jugador blancas = match['blancas'];
      Jugador negras = match['negras'];
      double resBlancas = match['resultado'];

      if (widget.tipoTorneo == 'Suizo') {
        blancas.desempate += negras.puntos;
        negras.desempate += blancas.puntos;
      } else if (widget.tipoTorneo == 'Round Robin') {
        if (resBlancas == 1.0) blancas.desempate += negras.puntos;
        else if (resBlancas == 0.5) blancas.desempate += (negras.puntos * 0.5);

        if (resBlancas == 0.0) negras.desempate += blancas.puntos;
        else if (resBlancas == 0.5) negras.desempate += (blancas.puntos * 0.5);
      }
    }
  }

  // --- FÓRMULA DE ELO OFICIAL (Reglas de Ajedrez) ---
  int _calcularNuevoElo(int eloPropio, int eloOponente, double resultado) {
    // Ea = 1 / (1 + 10^((Rb - Ra) / 400))
    double esperado = 1 / (1 + pow(10, (eloOponente - eloPropio) / 400));
    const int k = 32; // Factor K estándar para clubes/estudiantes
    return (eloPropio + k * (resultado - esperado)).round();
  }

  void _avanzar() async {
    bool completo = emparejamientos.every((m) => m['resultado'] != null);
    if (!completo) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Faltan resultados")));
      return;
    }

    // ACTUALIZAR ELO DE TODOS LOS JUGADORES SEGÚN LOS RESULTADOS DE ESTA RONDA
    for (var match in emparejamientos) {
      Jugador b = match['blancas'];
      Jugador n = match['negras'];
      if (b.nombre == "BYE" || n.nombre == "BYE") continue;

      double resB = match['resultado'];
      double resN = 1.0 - resB;

      int nuevoEloB = _calcularNuevoElo(b.elo, n.elo, resB);
      int nuevoEloN = _calcularNuevoElo(n.elo, b.elo, resN);

      b.elo = nuevoEloB;
      n.elo = nuevoEloN;

      // Guardar inmediatamente en Firestore
      _actualizarEloJugadorDB(b);
      _actualizarEloJugadorDB(n);
    }

    historialCompleto.addAll(emparejamientos);

    if (rondaActual >= totalRondas) {
      _calcularDesempatesFinales();
      
      // --- GUARDAR RESUMEN FINAL DEL TORNEO ---
      List<Jugador> ranking = List.from(widget.jugadoresInscritos);
      ranking.sort((a, b) {
        int cmp = b.puntos.compareTo(a.puntos);
        if (cmp != 0) return cmp;
        return b.desempate.compareTo(a.desempate);
      });

      try {
        await FirebaseFirestore.instance.collection('torneos_resultados').add({
          'tipo': widget.tipoTorneo,
          'fecha': DateTime.now(),
          'ganador': ranking.first.nombre,
          'clasificacion': ranking.map((j) => {
            'nombre': j.nombre,
            'puntos': j.puntos,
            'desempate': j.desempate,
            'eloFinal': j.elo
          }).toList(),
          // Opcional: puedes guardar las partidas si aún las quieres como detalle
        });
      } catch (e) {
        print("Error al guardar historial: $e");
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PantallaVictoria(jugadores: widget.jugadoresInscritos, tipo: widget.tipoTorneo))
      );
    } else {
      if (widget.tipoTorneo == 'Round Robin') _rotarRoundRobin();
      setState(() {
        rondaActual++;
        _generarRonda();
      });
    }
  }

  Future<void> _actualizarEloJugadorDB(Jugador j) async {
    await FirebaseFirestore.instance.collection('jugadores').doc(j.nombre).set({
      'nombre': j.nombre,
      'elo': j.elo,
      'ultima_partida': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    bool esUltima = rondaActual >= totalRondas;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final bool abandonar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF262626),
            title: const Text("¿ABANDONAR TORNEO?", style: TextStyle(color: Color(0xFF8B1D22), fontWeight: FontWeight.bold)),
            content: const Text("Si sales ahora, se perderá el progreso de la ronda actual y deberás configurar el torneo nuevamente.", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("CONTINUAR", style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("SALIR", style: TextStyle(color: Color(0xFF8B1D22), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ?? false;

        if (abandonar && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("RONDA $rondaActual DE $totalRondas", style: const TextStyle(letterSpacing: 1.2, fontSize: 16)),
          actions: [IconButton(icon: const Icon(Icons.list_alt, color: Color(0xFFD4AF37)), onPressed: _verTabla)],
        ),
        body: Container(
          color: const Color(0xFF262626),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: emparejamientos.length,
                  itemBuilder: (context, index) {
                    var match = emparejamientos[index];
                    double? res = match['resultado'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262626).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(child: Text("⚪ ${(match['blancas'] as Jugador).nombre} [${(match['blancas'] as Jugador).puntos}]", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text("VS", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Expanded(child: Text("[${(match['negras'] as Jugador).puntos}] ${(match['negras'] as Jugador).nombre} ⚫", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _btnRes("1-0", index, 1.0, res == 1.0),
                                _btnRes("½-½", index, 0.5, res == 0.5),
                                _btnRes("0-1", index, 0.0, res == 0.0 && res != null),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1D22),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 8,
                    ),
                    onPressed: _avanzar,
                    child: Text(
                      esUltima ? "🏆 FINALIZAR TORNEO" : "SIGUIENTE RONDA >>",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _btnRes(String txt, int index, double valor, bool sel) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: sel ? const Color(0xFFD4AF37) : Colors.transparent,
        foregroundColor: sel ? Colors.black : Colors.white60,
        elevation: 0,
        side: BorderSide(color: sel ? const Color(0xFFD4AF37) : Colors.white10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => _setResultado(index, valor, 1.0 - valor),
      child: Text(txt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _verTabla() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF262626),
      builder: (c) {
        var sorted = List<Jugador>.from(widget.jugadoresInscritos)..sort((a,b) => b.puntos.compareTo(a.puntos));
        return ListView.builder(
          itemCount: sorted.length,
          itemBuilder: (c, i) => ListTile(
            leading: Text("#${i+1}", style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
            title: Text(sorted[i].nombre, style: const TextStyle(color: Colors.white)),
            trailing: Text("${sorted[i].puntos} PTS", style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          )
        );
      }
    );
  }
}

// --- PANTALLA 4: VICTORIA ---
class PantallaVictoria extends StatelessWidget {
  final List<Jugador> jugadores;
  final String tipo;
  const PantallaVictoria({required this.jugadores, required this.tipo, super.key});

  @override
  Widget build(BuildContext context) {
    jugadores.sort((a, b) {
      int cmp = b.puntos.compareTo(a.puntos);
      if (cmp != 0) return cmp;
      int cmp2 = b.desempate.compareTo(a.desempate);
      if (cmp2 != 0) return cmp2;
      return b.elo.compareTo(a.elo);
    });

    Jugador ganador = jugadores.first;

    // --- ACTUALIZACIÓN MASIVA DE ELO (Sugerencia del Profe) ---
    // Al finalizar el torneo, actualizamos la base de datos global de jugadores.
    for (var j in jugadores) {
      FirebaseFirestore.instance.collection('jugadores').doc(j.nombre).set({
        'nombre': j.nombre,
        'elo': j.elo,
        'ultima_partida': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("PODIO FINAL"), automaticallyImplyLeading: false),
      body: Container(
        color: const Color(0xFF262626),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.emoji_events, size: 80, color: Color(0xFFD4AF37)),
            const Text("CAMPEÓN", style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 4, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(ganador.nombre.toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: jugadores.length,
                itemBuilder: (context, index) {
                  var j = jugadores[index];
                  bool isTop = index < 3;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isTop ? Colors.white.withOpacity(0.05) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Text("${index + 1}º", style: TextStyle(color: isTop ? const Color(0xFFD4AF37) : const Color(0xFFD4AF37).withOpacity(0.3), fontWeight: FontWeight.bold)),
                      title: Text(j.nombre, style: TextStyle(color: isTop ? Colors.white : Colors.white60, fontWeight: isTop ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text("DESEMPATE: ${j.desempate.toStringAsFixed(1)}", style: const TextStyle(fontSize: 10, color: Colors.white24)),
                      trailing: Text("${j.puntos} PTS", style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B1D22), minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("FINALIZAR Y VOLVER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            )
          ],
        ),
      ),
    );
  }
}