import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OnlineChatbotScreen extends StatefulWidget {
  const OnlineChatbotScreen({super.key});

  @override
  State<OnlineChatbotScreen> createState() => _OnlineChatbotScreenState();
}

class _OnlineChatbotScreenState extends State<OnlineChatbotScreen> {
  Future<void> _listAvailableModels() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _messages.add(
        _Message(
          text: '⚠️ Please configure your Gemini API key first.',
          sender: Sender.bot,
          timestamp: DateTime.now(),
          type: MessageType.general,
        ),
      );
      setState(() {});
      return;
    }
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models =
            (data['models'] as List?)?.map((m) => m['name']).toList() ?? [];
        _messages.add(
          _Message(
            text: 'Available Gemini models:\n${models.join('\n')}',
            sender: Sender.bot,
            timestamp: DateTime.now(),
            type: MessageType.general,
          ),
        );
      } else {
        _messages.add(
          _Message(
            text: 'API error: ${response.statusCode}\n${response.body}',
            sender: Sender.bot,
            timestamp: DateTime.now(),
            type: MessageType.general,
          ),
        );
      }
      setState(() {});
    } catch (e) {
      _messages.add(
        _Message(
          text: 'Error listing models: ${e.toString()}',
          sender: Sender.bot,
          timestamp: DateTime.now(),
          type: MessageType.general,
        ),
      );
      setState(() {});
    }
  }

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = [
    _Message(
      text:
          '🌐 Online Emergency AI Assistant powered by Google Gemini. Please configure your Gemini API key to get started.',
      sender: Sender.bot,
      timestamp: DateTime.now(),
      type: MessageType.general,
    ),
  ];
  String? _apiKey = 'AIzaSyDOGV8G2MI8fADNNYow1klKCiPNzQvuEA4';
  bool _showApiKeyInput = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final storedKey = prefs.getString('gemini_api_key');
    setState(() {
      _apiKey = (storedKey == null || storedKey.isEmpty)
          ? 'AIzaSyDOGV8G2MI8fADNNYow1klKCiPNzQvuEA4'
          : storedKey;
      _showApiKeyInput = false;
    });
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gemini_api_key', key);
      setState(() {
        _apiKey = key;
        _showApiKeyInput = false;
      });
      _messages.add(
        _Message(
          text:
              '✅ API Key configured successfully! I\'m now ready to provide advanced emergency guidance. How can I help you today?',
          sender: Sender.bot,
          timestamp: DateTime.now(),
          type: MessageType.general,
        ),
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) {
      return;
    }
    final userMsg = _Message(
      text: text.trim(),
      sender: Sender.user,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _controller.clear();
    try {
      final botResponse = await _sendToGemini(text.trim());
      setState(() {
        _messages.add(
          _Message(
            text: botResponse.response,
            sender: Sender.bot,
            timestamp: DateTime.now(),
            type: botResponse.type,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.add(
          _Message(
            text: '⚠️ Error: ${e.toString()}',
            sender: Sender.bot,
            timestamp: DateTime.now(),
            type: MessageType.emergency,
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<_BotResponse> _sendToGemini(String message) async {
    final endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey';
    final systemInstruction = {
      "role": "user",
      "parts": [
        {
          "text":
              "You are an expert emergency AI assistant for users in India. Always advise users to call Indian emergency services for real emergencies. Mention these helpline numbers in your advice: 112 (general emergency), 100 (police), 101 (fire), 102 (ambulance). Be compassionate and clear. Use lists and formatting for instructions.",
        },
      ],
    };
    final body = jsonEncode({
      "contents": [
        systemInstruction,
        {
          "role": "user",
          "parts": [
            {"text": message},
          ],
        },
      ],
      "safetySettings": [
        {
          "category": "HARM_CATEGORY_HARASSMENT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE",
        },
        {
          "category": "HARM_CATEGORY_HATE_SPEECH",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE",
        },
        {
          "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE",
        },
        {
          "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE",
        },
      ],
      "generationConfig": {
        "temperature": 0.7,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 1024,
      },
    });
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data["candidates"] == null || data["candidates"].isEmpty) {
      throw Exception('No response from Gemini API');
    }
    final botText =
        data["candidates"][0]["content"]["parts"][0]["text"] ??
        "Sorry, I couldn't process that request.";
    // Simple type detection
    String type = MessageType.general;
    final lower = botText.toLowerCase();
    if (lower.contains('emergency') ||
        lower.contains('urgent') ||
        lower.contains('911')) {
      type = MessageType.emergency;
    } else if (lower.contains('medical') ||
        lower.contains('doctor') ||
        lower.contains('hospital')) {
      type = MessageType.medical;
    } else if (lower.contains('safety') ||
        lower.contains('secure') ||
        lower.contains('protect')) {
      type = MessageType.safety;
    }
    return _BotResponse(botText, type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Emergency Chatbot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'API Key Settings',
            onPressed: () {
              setState(() {
                _showApiKeyInput = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'List Available Models',
            onPressed: _listAvailableModels,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showApiKeyInput)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configure Gemini API Key',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _apiKeyController,
                        decoration: const InputDecoration(
                          labelText: 'Paste your Gemini API key here',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        onSubmitted: (_) => _saveApiKey(),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _saveApiKey,
                        child: const Text('Save Key'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Get your API key from Google AI Studio: https://aistudio.google.com/app/apikey',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.sender == Sender.user
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.sender == Sender.user
                          ? Colors.blue.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msg.sender == Sender.bot && msg.type != null)
                          Text(
                            _getTypeLabel(msg.type!),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Text(msg.text),
                        Text(
                          _formatTime(msg.timestamp),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText:
                          'Ask about emergencies, first aid, or safety procedures...',
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case MessageType.emergency:
        return 'Emergency';
      case MessageType.medical:
        return 'Medical';
      case MessageType.safety:
        return 'Safety';
      default:
        return 'General';
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

enum Sender { user, bot }

class MessageType {
  static const emergency = 'emergency';
  static const medical = 'medical';
  static const safety = 'safety';
  static const general = 'general';
}

class _Message {
  final String text;
  final Sender sender;
  final DateTime timestamp;
  final String? type;
  _Message({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.type,
  });
}

class _BotResponse {
  final String response;
  final String type;
  _BotResponse(this.response, this.type);
}
