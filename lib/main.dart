import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(CryptoApp());
}

class CryptoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crypto & Forex Tracker',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.montserratTextTheme(),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _cryptoData = [];
  String _selectedCurrency = 'usd';
  final TextEditingController _searchController = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchCryptoData();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchCryptoData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCryptoData() async {
    try {
      List<Future<http.Response>> requests = [];
      for (int page = 1; page <= 3; page++) {
        requests.add(http.get(Uri.parse(
            'https://api.coingecko.com/api/v3/coins/markets?vs_currency=$_selectedCurrency&order=market_cap_desc&per_page=250&page=$page&sparkline=true')));
      }

      List<http.Response> responses = await Future.wait(requests);
      List<dynamic> allCoins = [];

      for (var response in responses) {
        if (response.statusCode == 200) {
          allCoins.addAll(json.decode(response.body));
        }
      }

      if (mounted) {
        setState(() {
          _cryptoData = allCoins.take(700).toList();
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  List<dynamic> _filterCryptoData(String query) {
    return _cryptoData
        .where((crypto) =>
            crypto['name'].toLowerCase().contains(query.toLowerCase()) ||
            crypto['symbol'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crypto Tracker',
            style: GoogleFonts.montserrat(
                fontSize: 26, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          DropdownButton<String>(
            dropdownColor: Colors.black,
            value: _selectedCurrency,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedCurrency = newValue;
                });
                _fetchCryptoData();
              }
            },
            items: ['usd', 'eur', 'ngn'].map((currency) {
              return DropdownMenuItem(
                value: currency,
                child: Text(currency.toUpperCase(),
                    style: TextStyle(color: Colors.white)),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[900],
                hintText: 'Search for a cryptocurrency... made by Kelly',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filterCryptoData(_searchController.text).length,
              itemBuilder: (context, index) {
                final crypto = _filterCryptoData(_searchController.text)[index];
                final priceChange24h =
                    crypto['price_change_percentage_24h'] ?? 0.0;
                final priceChangeColor =
                    priceChange24h >= 0 ? Colors.green : Colors.red;
                return Card(
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(crypto['image']),
                    ),
                    title: Text(crypto['name'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(crypto['symbol'].toUpperCase(),
                            style: TextStyle(color: Colors.grey)),
                        Text(
                            'Market Cap: ${_selectedCurrency.toUpperCase()} ${crypto['market_cap']}',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(
                            '24h High: ${crypto['high_24h']} ${_selectedCurrency.toUpperCase()}',
                            style:
                                TextStyle(color: Colors.green, fontSize: 12)),
                        Text(
                            '24h Low: ${crypto['low_24h']} ${_selectedCurrency.toUpperCase()}',
                            style: TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                            '${_selectedCurrency.toUpperCase()} ${crypto['current_price']}',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                        Text('${priceChange24h.toStringAsFixed(2)}%',
                            style: TextStyle(
                                color: priceChangeColor, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
//crypto-prices-2025   ....my firebase unique id
