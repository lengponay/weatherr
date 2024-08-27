import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'consts.dart';

class CityListPage extends StatefulWidget {
  const CityListPage({super.key});

  @override
  _CityListPageState createState() => _CityListPageState();
}

class _CityListPageState extends State<CityListPage> {
  List<Map<String, dynamic>> citiesWeatherData = [];
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchWeatherForCities();
  }

  Future<void> fetchWeatherForCities() async {
    List<String> cities = ['Seoul', 'Paris', 'Beijing', 'New York'];

    for (String city in cities) {
      final response = await http.get(Uri.parse('$apiUrl?q=$city&appid=$apiKey&units=metric'));
      if (response.statusCode == 200) {
        setState(() {
          citiesWeatherData.add(json.decode(response.body));
        });
      }
    }
  }

  void fetchWeather(String city) async {
    final response = await http.get(Uri.parse('$apiUrl?q=$city&appid=$apiKey&units=metric'));
    if (response.statusCode == 200) {
      setState(() {
        citiesWeatherData.add(json.decode(response.body));
      });
    }
  }

  // Mapping weather descriptions to icons
  IconData getWeatherIcon(String description) {
    switch (description) {
      case 'clear sky':
        return Icons.wb_sunny;
      case 'few clouds':
      case 'scattered clouds':
      case 'broken clouds':
        return Icons.cloud;
      case 'shower rain':
      case 'rain':
      case 'thunderstorm':
        return Icons.grain;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
        return Icons.blur_on;
      default:
        return Icons.wb_cloudy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0f2027), Color(0xFF2c5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 80),
            _buildCitySearch(),
            Expanded(
              child: citiesWeatherData.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: citiesWeatherData.length,
                      itemBuilder: (context, index) {
                        var cityWeather = citiesWeatherData[index];
                        var weatherDescription = cityWeather['weather'][0]['description'];
                        var weatherIcon = getWeatherIcon(weatherDescription);
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(30.0),
                            border: Border.all(color: Colors.white30, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cityWeather['name'],
                                    style: const TextStyle(
                                      color: Colors.white, 
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    '${cityWeather['main']['temp'].toStringAsFixed(1)}°C',
                                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                                  ),
                                  Text(
                                    weatherDescription,
                                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                                  ),
                                ],
                              ),
                              Icon(weatherIcon, color: Colors.white, size: 30.0),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitySearch() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
      child: TextField(
        controller: _cityController,
        decoration: InputDecoration(
          hintText: 'Enter city name',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _cityController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _cityController.clear();
                  },
                )
              : null,
          fillColor: Color.fromARGB(255, 247, 255, 252).withOpacity(0.8),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
        ),
        style: const TextStyle(color: Colors.black),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            fetchWeather(value);
          }
        },
      ),
    );
  }
}
