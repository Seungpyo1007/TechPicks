import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({Key? key}) : super(key: key);

  @override
  _PhoneScreenState createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  List<dynamic> phoneRankings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPhoneRankings();
  }

  Future<void> fetchPhoneRankings() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.example.com/phone-rankings'), // Replace with actual API URL
        headers: {
          'Authorization': 'Bearer YOUR_API_KEY', // Add API key if needed
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          phoneRankings = json.decode(response.body);
          isLoading = false;
        });
      } else {
        print('Failed to load phone rankings: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Rankings'),
      ),
      body: Container(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: phoneRankings.length,
          itemBuilder: (context, index) {
            final phone = phoneRankings[index];
            return ListTile(
              title: Text(phone['name'] ?? 'Unknown'),
              subtitle: Text('Rank: ${phone['rank'] ?? 'N/A'}'),
            );
          },
        ),
      ),
    );
  }
}
