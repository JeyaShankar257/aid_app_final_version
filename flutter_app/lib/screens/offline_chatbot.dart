import 'package:flutter/material.dart';

class OfflineChatbotScreen extends StatefulWidget {
  const OfflineChatbotScreen({super.key});

  @override
  State<OfflineChatbotScreen> createState() => _OfflineChatbotScreenState();
}

class _OfflineChatbotScreenState extends State<OfflineChatbotScreen> {
  final List<_Message> messages = [
    _Message(
      text:
          '🔒 Offline Emergency Assistant activated. I can provide immediate guidance for medical emergencies, safety procedures, and first aid using my built-in knowledge base. No internet required!',
      sender: Sender.bot,
      type: MessageType.general,
      timestamp: DateTime.now(),
    ),
  ];
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;

  // Rule-based knowledge base
  final Map<String, Map<String, String>> offlineKnowledgeBase = {
    'emergency': {
      'unconscious':
          'If someone is unconscious but breathing: 1) Place them in recovery position 2) Call emergency services 3) Monitor breathing continuously 4) Don\'t leave them alone',
      'bleeding':
          'For severe bleeding: 1) Apply direct pressure with clean cloth 2) Don\'t remove cloth if soaked - add more layers 3) Elevate injured area above heart if possible 4) Call emergency services',
      'choking':
          'For choking adult: 1) Encourage coughing 2) If ineffective: 5 back blows between shoulder blades 3) 5 abdominal thrusts (Heimlich) 4) Alternate until object clears 5) Call emergency if continues',
      'cpr':
          'CPR Steps: 1) Check responsiveness 2) Call emergency services 3) Place heel of hand on center of chest 4) Push hard & fast at least 2 inches deep 5) 30 compressions then 2 rescue breaths 6) Continue until help arrives',
      'night':
          'Night-time safety: Stay in well-lit areas, avoid walking alone, keep your phone charged, share your location with trusted contacts, and be aware of surroundings. If you feel unsafe, call emergency services immediately.',
      'women':
          'Women\'s safety: Trust your instincts, avoid isolated places, keep emergency contacts handy, use safety apps, and don\'t hesitate to seek help. If threatened, make noise and move to a safe area.',
    },
    'medical': {
      'heartattack':
          'Heart Attack Signs: Chest pain, shortness of breath, nausea. Actions: 1) Call emergency services 2) Give aspirin if not allergic 3) Keep person calm and still 4) Loosen tight clothing 5) Be ready to perform CPR',
      'burns':
          'For burns: 1) Cool with running water 10-20 minutes 2) Don\'t use ice 3) Remove jewelry before swelling 4) Cover with clean, non-stick dressing 5) Don\'t break blisters 6) Seek medical attention for severe burns',
      'fractures':
          'For suspected fractures: 1) Don\'t move person unless in danger 2) Support injured area 3) Apply ice wrapped in cloth 4) Call for medical help 5) Watch for shock symptoms',
      'stroke':
          'FAST for stroke: F-Face drooping A-Arm weakness S-Speech difficulty T-Time to call emergency. Keep person calm, note time of symptoms, don\'t give food/water',
    },
    'safety': {
      'fire':
          'Fire Safety: 1) Get out immediately 2) Stay out 3) Call fire department 4) If trapped: close doors, stay low, signal for help 5) Feel doors before opening 6) Have escape plan',
      'earthquake':
          'Earthquake: DROP, COVER, HOLD ON. Get under sturdy table or against interior wall. Stay away from windows, mirrors, heavy objects. If outdoors, move away from buildings',
      'flood':
          'Flood Safety: 1) Get to higher ground immediately 2) Don\'t walk/drive through moving water 3) 6 inches of water can knock you down 4) 12 inches can carry away vehicle 5) Stay informed via radio',
      'tornado':
          'Tornado: Go to lowest floor, interior room, away from windows. Get under heavy table. Mobile homes: leave immediately, go to sturdy building. If outdoors: lie flat in low area',
    },
    'firstaid': {
      'cuts':
          'For cuts: 1) Clean hands 2) Stop bleeding with pressure 3) Clean wound gently 4) Apply antibiotic ointment 5) Cover with bandage 6) Change bandage daily 7) Watch for infection signs',
      'sprains':
          'RICE for sprains: R-Rest the injury I-Ice for 15-20 min every 2-3 hours C-Compression with elastic bandage E-Elevation above heart level. Seek medical attention if severe',
      'poisoning':
          'Poisoning: 1) Call Poison Control: 1-800-222-1222 2) Don\'t induce vomiting unless told 3) If on skin: remove contaminated clothing, rinse 15+ minutes 4) If inhaled: get fresh air',
      'allergic':
          'Allergic reaction: Mild: antihistamine, cool compress. SEVERE (anaphylaxis): 1) Call 911 2) Use EpiPen if available 3) Position person lying down 4) Monitor breathing 5) Be ready for CPR',
    },
  };

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      messages.add(
        _Message(
          text: text.trim(),
          sender: Sender.user,
          timestamp: DateTime.now(),
        ),
      );
      isLoading = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      final response = _getOfflineResponse(text.trim().toLowerCase());
      setState(() {
        messages.add(
          _Message(
            text: response.response,
            sender: Sender.bot,
            type: response.type,
            timestamp: DateTime.now(),
          ),
        );
        isLoading = false;
      });
    });
    _controller.clear();
  }

  _OfflineResponse _getOfflineResponse(String message) {
    // Emergency
    if (message.contains('unconscious') || message.contains('unresponsive')) {
      return _OfflineResponse(
        offlineKnowledgeBase['emergency']!['unconscious']!,
        MessageType.emergency,
      );
    }
    if (message.contains('bleeding') || message.contains('blood')) {
      return _OfflineResponse(
        offlineKnowledgeBase['emergency']!['bleeding']!,
        MessageType.emergency,
      );
    }
    if (message.contains('choking') || message.contains("can't breathe")) {
      return _OfflineResponse(
        offlineKnowledgeBase['emergency']!['choking']!,
        MessageType.emergency,
      );
    }
    if (message.contains('cpr') || message.contains('not breathing')) {
      return _OfflineResponse(
        offlineKnowledgeBase['emergency']!['cpr']!,
        MessageType.emergency,
      );
    }
    if (message.contains('night') ||
        message.contains('night time') ||
        message.contains('dark')) {
      return _OfflineResponse(
        offlineKnowledgeBase['emergency']!['night']!,
        MessageType.safety,
      );
    }
    if (message.contains('women') ||
        message.contains('woman') ||
        message.contains('female') ||
        message.contains('girl')) {
      return _OfflineResponse(
        offlineKnowledgeBase['emergency']!['women']!,
        MessageType.safety,
      );
    }
    // Medical
    if (message.contains('heart attack') || message.contains('chest pain')) {
      return _OfflineResponse(
        offlineKnowledgeBase['medical']!['heartattack']!,
        MessageType.medical,
      );
    }
    if (message.contains('burn') || message.contains('burned')) {
      return _OfflineResponse(
        offlineKnowledgeBase['medical']!['burns']!,
        MessageType.medical,
      );
    }
    if (message.contains('fracture') ||
        message.contains('broken bone') ||
        message.contains('broken arm') ||
        message.contains('broken leg')) {
      return _OfflineResponse(
        offlineKnowledgeBase['medical']!['fractures']!,
        MessageType.medical,
      );
    }
    if (message.contains('stroke') || message.contains('face drooping')) {
      return _OfflineResponse(
        offlineKnowledgeBase['medical']!['stroke']!,
        MessageType.medical,
      );
    }
    // Safety
    if (message.contains('fire') || message.contains('burning building')) {
      return _OfflineResponse(
        offlineKnowledgeBase['safety']!['fire']!,
        MessageType.safety,
      );
    }
    if (message.contains('earthquake') || message.contains('shaking')) {
      return _OfflineResponse(
        offlineKnowledgeBase['safety']!['earthquake']!,
        MessageType.safety,
      );
    }
    if (message.contains('flood') || message.contains('flooding')) {
      return _OfflineResponse(
        offlineKnowledgeBase['safety']!['flood']!,
        MessageType.safety,
      );
    }
    if (message.contains('tornado') || message.contains('twister')) {
      return _OfflineResponse(
        offlineKnowledgeBase['safety']!['tornado']!,
        MessageType.safety,
      );
    }
    // First aid
    if (message.contains('cut') || message.contains('wound')) {
      return _OfflineResponse(
        offlineKnowledgeBase['firstaid']!['cuts']!,
        MessageType.medical,
      );
    }
    if (message.contains('sprain') || message.contains('twisted ankle')) {
      return _OfflineResponse(
        offlineKnowledgeBase['firstaid']!['sprains']!,
        MessageType.medical,
      );
    }
    if (message.contains('poison') || message.contains('toxic')) {
      return _OfflineResponse(
        offlineKnowledgeBase['firstaid']!['poisoning']!,
        MessageType.emergency,
      );
    }
    if (message.contains('allergic') ||
        message.contains('allergy') ||
        message.contains('epipen')) {
      return _OfflineResponse(
        offlineKnowledgeBase['firstaid']!['allergic']!,
        MessageType.emergency,
      );
    }
    // Default
    return _OfflineResponse(
      'I have extensive offline knowledge about: Emergency CPR, Choking, Bleeding, Heart attacks, Burns, Fractures, Strokes, Fire safety, Earthquake procedures, Flood safety, Tornado response, Cuts & wounds, Sprains, Poisoning, and Allergic reactions. Ask me about any of these topics for detailed guidance. Remember: Call emergency services immediately for life-threatening situations!',
      MessageType.general,
    );
  }

  List<_QuickAction> quickActions = [
    _QuickAction('Someone is choking, what do I do?'),
    _QuickAction('How to perform CPR?'),
    _QuickAction('Heart attack symptoms and response'),
    _QuickAction('How to treat severe burns?'),
    _QuickAction('Earthquake safety procedures'),
    _QuickAction('How to stop severe bleeding?'),
    _QuickAction('Night-time safety tips'),
    _QuickAction('Women\'s safety advice'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Emergency Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
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
          if (isLoading)
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
          Wrap(
            spacing: 8,
            children: quickActions
                .map(
                  (action) => ElevatedButton(
                    onPressed: () {
                      _controller.text = action.text;
                    },
                    child: Text(
                      action.text,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getTypeLabel(MessageType type) {
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

enum MessageType { emergency, medical, safety, general }

class _Message {
  final String text;
  final Sender sender;
  final DateTime timestamp;
  final MessageType? type;
  _Message({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.type,
  });
}

class _OfflineResponse {
  final String response;
  final MessageType type;
  _OfflineResponse(this.response, this.type);
}

class _QuickAction {
  final String text;
  _QuickAction(this.text);
}
