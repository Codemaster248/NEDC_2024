import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class InputLocationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextEditingController latController = TextEditingController();
    final TextEditingController lonController = TextEditingController();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/drawing.png', height: 200, width: 300,),
              SizedBox(height: 20),
              TextField(
                controller: latController,
                decoration: InputDecoration(labelText: 'Enter Latitude'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              TextField(
                controller: lonController,
                decoration: InputDecoration(labelText: 'Enter Longitude'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  print(double.parse(latController.text));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WildfirePredictionScreen(
                        latitude: double.parse(latController.text),
                        longitude: double.parse(lonController.text),
                      ),
                    ),
                  );
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MaterialApp(home: MyApp()));
}

String findPredictedDirection(String direction) {
  print("DIRECTION: $direction");
  var directionl = direction.split(', ');
  print(directionl);
  var roundedDirection =
      '${double.parse(directionl[0]).toStringAsFixed(0)}, ${double.parse(directionl[1]).toStringAsFixed(0)}';
  print(roundedDirection);
  final directionMap = {
    '1, 1': 'North-west',
    '2, 1': 'North',
    '3, 1': 'North-east',
    '1, 2': 'West',
    '2, 2': 'Center',
    '3, 2': 'East',
    '1, 3': 'South-west',
    '2, 3': 'South',
    '3, 3': 'South-east',
  };
  print(directionMap[roundedDirection]);
  return directionMap[roundedDirection] ?? 'Unknown';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PyroPredict',
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFF3F6FB),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFF121212),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: InputLocationPage(),
    );
  }
}

class SensorDetailsPage extends StatelessWidget {
  final int gridX;
  final int gridY;
  final double probability;
  final Map<String, dynamic> data;

  const SensorDetailsPage({
    required this.gridX,
    required this.gridY,
    required this.probability,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Sensor Location',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              Text('($gridX, $gridY)',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey[600])),
              SizedBox(height: 50),
              Text('Sensor Probability',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              Text('${(probability * 100).toStringAsFixed(2)}%',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey[600])),
              SizedBox(height: 50),
              Text('Temperature',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              Text('${data['temperature']}°C',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey[600])),
              SizedBox(height: 50),
              Text('Humidity',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              Text('${data['humidity']}%',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey[600])),
                      SizedBox(height: 50),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Back to map', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  backgroundColor: Colors.deepOrangeAccent,
                  foregroundColor: Colors.white,
                  // primary: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WildfirePredictionScreen extends StatefulWidget {

  double? latitude = 1;
   double? longitude = 1;

   WildfirePredictionScreen({super.key, this.latitude, this.longitude});
  

  @override
  _WildfirePredictionScreenState createState() =>
      _WildfirePredictionScreenState();
}

class _WildfirePredictionScreenState extends State<WildfirePredictionScreen>
    with SingleTickerProviderStateMixin {
  double overallProbability = 0.0;
  String predictedDirection = "-";
  List<List<double>> gridProbabilities =
      List.generate(3, (_) => List.filled(3, 0.0));
  bool isLoading = true; // Start with loading state
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Automatically fetch prediction when the app launches
    fetchPrediction();
  }

  Future<void> fetchPrediction() async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/predict-wildfire/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        overallProbability = data['overall_probability_of_wildfire'];
        predictedDirection = data['predicted_direction'].join(', ');
        gridProbabilities = List.generate(
            3,
            (x) => List.generate(3, (y) {
                  for (var sensor in data['sensor_probabilities']) {
                    if (sensor['X'] == x + 1 && sensor['Y'] == y + 1) {
                      return sensor['probability'].toDouble();
                    }
                  }
                  return 0.0;
                }));
        isLoading = false;
      });
      _controller.forward(from: 0.0);
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load prediction');
    }
  }

  Future<void> fetchSensorDetails(
      int gridX, int gridY, double probability) async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/sensor-data/$gridX/$gridY'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                SensorDetailsPage(
              gridX: gridX,
              gridY: gridY,
              probability: probability,
              data: data,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      } else {
        throw Exception('Failed to fetch sensor details');
      }
    } catch (error) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Unable to fetch sensor details: $error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pass your access token to MapboxOptions so you can load a map
    MapboxOptions.setAccessToken(
        "pk.eyJ1IjoiZ3VyamFuLWsiLCJhIjoiY202MzIzb3RwMTF3dDJscTNoOG54dnRqNyJ9.VixE8cBSqp5y15U0lBLk_g");

    // Define options for your camera
    CameraOptions camera = CameraOptions(
        center: Point(coordinates: Position(-116.947937, 34.056728)),
        zoom: 12,
        bearing: 30,
        pitch: 0);

    var mw = MapWidget(
      cameraOptions: camera,
    );
    // var map = mw.getMapboxMap()!;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // var directionl = predictedDirection.split(', ');
    // var roundedDirection = '${double.parse(directionl[0]).toStringAsFixed(1)}, ${double.parse(directionl[1]).toStringAsFixed(1)}';

    return Scaffold(
        appBar: AppBar(
          title: Text('PyroPredict',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900)),
          backgroundColor: const Color.fromARGB(255, 171, 43, 18),
          elevation: 0,
          centerTitle: true,
        ),
        body: Stack(
          children: [
            mw,
            ClipRect(
                child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                    child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.2), // Semi-transparent overlay
                          // borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(children: [
                          Text(
                            'Overall probability: ${(overallProbability * 100).toStringAsFixed(2)}%',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red, // Ensure readability
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Text(
                                'Future Direction: ${findPredictedDirection(predictedDirection)}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green, // Ensure readability
                                ),
                              ))
                        ])))),
            Padding(
                padding: const EdgeInsets.only(top: 150),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    int x = index % 3;
                    int y = index ~/ 3;
                    double probability = gridProbabilities[x][y];
                    bool isPredictedDirection = predictedDirection != '-' &&
                        (x + 1 ==
                                double.parse(
                                    predictedDirection.split(', ')[0]) &&
                            y + 1 ==
                                double.parse(
                                    predictedDirection.split(', ')[1]));
                    Color color = isPredictedDirection
                        ? Colors.red
                        : (probability > 0.6
                            ? Colors.orange.withOpacity(0.5)
                            : Colors.green.withOpacity(0.5));

                    return GestureDetector(
                      onTap: () =>
                          fetchSensorDetails(x + 1, y + 1, probability),
                      child: ScaleTransition(
                        scale: _animation,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            // borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(2, 4),
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${(probability * 100).toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ))
          ],
        ));
  }
}
