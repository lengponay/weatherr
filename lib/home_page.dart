import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:weatherr/listCities.dart';
import 'dart:convert';
import 'consts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _weatherData;
  bool _loading = true;
  List<String> searchedCities = [];
  int _currentCityIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchWeather('Sihanoukville');
  }

  Future<void> fetchWeather(String city) async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await http.get(Uri.parse('$apiUrl?q=$city&appid=$apiKey&units=metric'));

      if (response.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(response.body);
          _loading = false;
          if (!searchedCities.contains(city)) {
            searchedCities.add(city);
            _currentCityIndex = searchedCities.length - 1;
          }
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Could not fetch weather data. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> fetchWeatherForCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final response = await http.get(Uri.parse(
        '$apiUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric',
      ));

      if (response.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(response.body);
          _loading = false;
          String city = _weatherData['name'];
          if (!searchedCities.contains(city)) {
            searchedCities.add(city);
            _currentCityIndex = searchedCities.length - 1; // Update index
          }
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Could not fetch weather data. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _onMenuButtonPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CityListPage()), // Navigate to ListCities
    );
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0f2027), Color(0xFF2c5364)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: ListView(
              children: [
                SizedBox(height: kToolbarHeight + 20),
                _weatherData != null ? _buildCurrentWeather() : Container(),
                _buildHourlyForecast(),
                _buildRainChance(),
              ],
            ),
          ),
    floatingActionButton: FloatingActionButton(
      onPressed: _onMenuButtonPressed, // Call the method for navigation
      backgroundColor: Colors.blue,
      child: const Icon(Icons.menu, color: Colors.white),
    ),
  );
}


  Widget _buildCurrentWeather() {
    String iconCode = _weatherData['weather'][0]['icon'];
    String iconUrl = 'http://openweathermap.org/img/wn/$iconCode@2x.png';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Today',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Image.network(iconUrl, width: 150, height: 100),
        const SizedBox(height: 5),
        Text(
          '${_weatherData['main']['temp'].toStringAsFixed(1)}°C',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _weatherData['name'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _weatherData['weather'][0]['description'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          'Feels like ${_weatherData['main']['feels_like'].toStringAsFixed(1)}°C',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18),
        ),
        const SizedBox(height: 20),
        
        // Card for additional weather details
        Card(
          color: Colors.white.withOpacity(0.2),
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildWeatherDetailRow(Icons.air, 'Wind', '${_weatherData['wind']['speed']} m/s, ${_weatherData['wind']['deg']}°'),
                _buildWeatherDetailRow(Icons.compress, 'Pressure', '${_weatherData['main']['pressure']} hPa'),
                _buildWeatherDetailRow(Icons.opacity, 'Humidity', '${_weatherData['main']['humidity']}%'),
                _buildWeatherDetailRow(Icons.remove_red_eye, 'Visibility', '${_weatherData['visibility'] / 1000} km'),
                _buildWeatherDetailRow(Icons.wb_sunny, 'UV Index', 'Low/Medium/High'), // You can replace with actual UV index if available
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast() {
  List<Map<String, String>> hourlyData = [
    {'time': '12PM', 'temp': '26°C', 'condition': 'Clear'},
    {'time': '1PM', 'temp': '27°C', 'condition': 'Rain'},
    {'time': '2PM', 'temp': '28°C', 'condition': 'Clouds'},
    {'time': '3PM', 'temp': '29°C', 'condition': 'Clear'},
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: hourlyData.map((data) {
          return Container(
            width: 100, // Adjust width as needed
            child: _buildHourlyForecastTile(
              data['time']!,
              data['temp']!,
              data['condition']!,
            ),
          );
        }).toList(),
      ),
    ),
  );
}


  Widget _buildHourlyForecastTile(String time, String temp, String weatherCondition) {
    IconData weatherIcon = _getWeatherIcon(weatherCondition);

    return Container(
    width: 80, // Adjust width as needed
    child: Column(
      children: [
        Text(
          time,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Icon(weatherIcon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          temp,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ],
    ),
  );
}

  Widget _buildRainChance() {
  List<Map<String, dynamic>> rainChanceData = [
    {'time': '10AM', 'chance': 20},
    {'time': '12PM', 'chance': 40},
    {'time': '2PM', 'chance': 60},
    {'time': '4PM', 'chance': 80},
  ];

  return Padding(
    padding: EdgeInsets.only(top : 16.0, left : 16.0, right : 16.0),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chance of Rain',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...rainChanceData.map((data) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      data['time'],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      value: data['chance'] / 100,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${data['chance']}%',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ),
  );
}

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'rain':
        return Icons.beach_access;
      case 'clouds':
        return Icons.cloud;
      default:
        return Icons.help;
    }
  }
}
