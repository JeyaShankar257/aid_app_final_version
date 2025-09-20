import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Message {
  final String id;
  final String text;
  final String sender;
  final DateTime timestamp;
  final String? type;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.type,
  });
}

class EmergencyChatbotScreen extends StatefulWidget {
  const EmergencyChatbotScreen({super.key});

  @override
  State<EmergencyChatbotScreen> createState() => _EmergencyChatbotScreenState();
}

class _EmergencyChatbotScreenState extends State<EmergencyChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [
    Message(
      id: '1',
      text:
          "Hello! I'm your Emergency AI Assistant. I can help you with medical emergencies, safety guidance, and crisis situations. How can I help you today?",
      sender: 'bot',
      timestamp: DateTime.now(),
      type: 'general',
    ),
  ];
  bool _isOnline = true;
  bool _isLoading = false;

  final Map<String, List<String>> offlineResponses = {
    'emergency': [
      "If someone is unconscious but breathing, place them in the recovery position. Call emergency services immediately.",
      "For severe bleeding: Apply direct pressure with a clean cloth. Don't remove the cloth if it becomes soaked - add more layers.",
      "For choking: If conscious, encourage coughing. If not effective, perform back blows and abdominal thrusts.",
    ],
    'medical': [
      "For suspected heart attack: Call emergency services, give aspirin if not allergic, keep person calm and still.",
      "For burns: Cool with running water for 10-20 minutes. Don't use ice. Cover with clean, non-stick dressing.",
      "For fractures: Don't move the person unless in immediate danger. Support the injured area and call for help.",
    ],
    'safety': [
      "In case of fire: Get out, stay out, call fire department. If trapped, close doors, stay low, signal for help.",
      "For natural disasters: Drop, cover, hold on for earthquakes. For flooding, get to higher ground immediately.",
      "If being followed: Go to a public place, don't go home. Vary your route and trust your instincts.",
    ],
    'default': [
      "I'm here to help with emergency situations. Ask me about medical emergencies, safety procedures, or first aid.",
      "Remember: In a real emergency, always call your local emergency number first (911, 112, etc.).",
      "I can provide guidance on first aid, emergency procedures, and safety protocols.",
    ],
  };

  @override
  void initState() {
    super.initState();
    _isOnline = true; // You can use connectivity_plus for real online check
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, dynamic> getOfflineResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    if (message.contains('emergency') ||
        message.contains('urgent') ||
        message.contains('help')) {
      return {
        'response': (offlineResponses['emergency']!..shuffle()).first,
        'type': 'emergency',
      };
    } else if (message.contains('medical') ||
        message.contains('heart') ||
        message.contains('bleeding') ||
        message.contains('injury')) {
      return {
        'response': (offlineResponses['medical']!..shuffle()).first,
        'type': 'medical',
      };
    } else if (message.contains('safety') ||
        message.contains('fire') ||
        message.contains('earthquake') ||
        message.contains('danger')) {
      return {
        'response': (offlineResponses['safety']!..shuffle()).first,
        'type': 'safety',
      };
    } else {
      return {
        'response': (offlineResponses['default']!..shuffle()).first,
        'type': 'general',
      };
    }
  }

  Future<Map<String, dynamic>> sendToGemini(String message) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=AIzaSyD-kThkGoV8g6PMxsZc98xwQM2YmFXLQkk',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      "You are an emergency AI assistant. Respond to this query with helpful, accurate emergency guidance. Keep responses concise and actionable. Always remind users to call emergency services for real emergencies. Query: $message",
                },
              ],
            },
          ],
        }),
      );
      if (response.statusCode != 200) throw Exception('API request failed');
      final data = jsonDecode(response.body);
      final botResponse =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
          "I'm sorry, I couldn't process that request. Please try again.";
      return {'response': botResponse, 'type': 'general'};
    } catch (e) {
      return getOfflineResponse(message);
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: 'user',
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMessage);
      _controller.clear();
      _isLoading = true;
    });
    Map<String, dynamic> botReply;
    if (_isOnline) {
      botReply = await sendToGemini(text);
    } else {
      botReply = getOfflineResponse(text);
    }
    final botMessage = Message(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      text: botReply['response'],
      sender: 'bot',
      timestamp: DateTime.now(),
      type: botReply['type'],
    );
    setState(() {
      _messages.add(botMessage);
      _isLoading = false;
    });
    await Future.delayed(Duration(milliseconds: 100));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  List<Map<String, String>> quickActions = [
    {'text': "What should I do if someone is choking?", 'type': 'medical'},
    {'text': "How to help someone having a heart attack?", 'type': 'emergency'},
    {'text': "Fire safety procedures", 'type': 'safety'},
    {'text': "Basic first aid steps", 'type': 'medical'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency AI Assistant'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text(_isOnline ? 'Online Mode' : 'Offline Mode'),
              avatar: Icon(_isOnline ? Icons.wifi : Icons.wifi_off, size: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.sender == 'user';
                return Container(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (!isUser)
                        Row(
                          children: [
                            Icon(
                              msg.type == 'emergency'
                                  ? Icons.warning
                                  : msg.type == 'medical'
                                  ? Icons.favorite
                                  : msg.type == 'safety'
                                  ? Icons.shield
                                  : Icons.smart_toy,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'AI Assistant',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        TimeOfDay.fromDateTime(msg.timestamp).format(context),
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.smart_toy, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'AI Assistant is typing...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText:
                          'Ask about emergency procedures, first aid, or safety guidance...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Wrap(
              spacing: 8,
              children: quickActions
                  .map(
                    (action) => ElevatedButton(
                      onPressed: () {
                        _controller.text = action['text']!;
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: TextStyle(fontSize: 12),
                      ),
                      child: Text(action['text']!),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
