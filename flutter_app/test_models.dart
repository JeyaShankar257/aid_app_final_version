import 'dart:convert';
import 'package:http/http.dart' as http;

// Test script to check available models for your API key
void main() async {
  // Replace with your actual API key
  const String apiKey = 'YOUR_API_KEY_HERE';

  await checkAvailableModels(apiKey);
}

Future<void> checkAvailableModels(String apiKey) async {
  // print('🔍 Checking available models for your API key...\n');

  // List of common Gemini models to test
  final List<String> modelsToTest = [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-1.0-pro',
    'gemini-1.5-flash-latest',
    'gemini-1.5-pro-latest',
    'gemini-pro-vision',
  ];

  for (String model in modelsToTest) {
    await testModel(model, apiKey);
    await Future.delayed(Duration(milliseconds: 500)); // Rate limiting
  }
}

Future<void> testModel(String model, String apiKey) async {
  try {
    final response = await http
        .post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': 'Hello'},
                ],
              },
            ],
          }),
        )
        .timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      // print('✅ $model - SUPPORTED');
    } else if (response.statusCode == 404) {
      // print('❌ $model - NOT FOUND');
    } else if (response.statusCode == 403) {
      // print('⚠️ $model - ACCESS DENIED (quota/permissions)');
    } else {
      // print('❓ $model - Status: ${response.statusCode}');
    }
  } catch (e) {
    // print('❌ $model - ERROR: $e');
  }
}
