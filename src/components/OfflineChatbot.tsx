import React, { useState, useRef, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { 
  MessageSquare, 
  Send, 
  WifiOff, 
  Bot,
  AlertTriangle,
  Heart,
  Shield,
  Database
} from 'lucide-react';

interface Message {
  id: string;
  text: string;
  sender: 'user' | 'bot';
  timestamp: Date;
  type?: 'emergency' | 'medical' | 'safety' | 'general';
}

const OfflineChatbot: React.FC = () => {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      text: "🔒 Offline Emergency Assistant activated. I can provide immediate guidance for medical emergencies, safety procedures, and first aid using my built-in knowledge base. No internet required!",
      sender: 'bot',
      timestamp: new Date(),
      type: 'general'
    }
  ]);
  const [inputText, setInputText] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const offlineKnowledgeBase = {
    emergency: {
      unconscious: "If someone is unconscious but breathing: 1) Place them in recovery position 2) Call emergency services 3) Monitor breathing continuously 4) Don't leave them alone",
      bleeding: "For severe bleeding: 1) Apply direct pressure with clean cloth 2) Don't remove cloth if soaked - add more layers 3) Elevate injured area above heart if possible 4) Call emergency services",
      choking: "For choking adult: 1) Encourage coughing 2) If ineffective: 5 back blows between shoulder blades 3) 5 abdominal thrusts (Heimlich) 4) Alternate until object clears 5) Call emergency if continues",
      cpr: "CPR Steps: 1) Check responsiveness 2) Call emergency services 3) Place heel of hand on center of chest 4) Push hard & fast at least 2 inches deep 5) 30 compressions then 2 rescue breaths 6) Continue until help arrives"
    },
    medical: {
      heartattack: "Heart Attack Signs: Chest pain, shortness of breath, nausea. Actions: 1) Call emergency services 2) Give aspirin if not allergic 3) Keep person calm and still 4) Loosen tight clothing 5) Be ready to perform CPR",
      burns: "For burns: 1) Cool with running water 10-20 minutes 2) Don't use ice 3) Remove jewelry before swelling 4) Cover with clean, non-stick dressing 5) Don't break blisters 6) Seek medical attention for severe burns",
      fractures: "For suspected fractures: 1) Don't move person unless in danger 2) Support injured area 3) Apply ice wrapped in cloth 4) Call for medical help 5) Watch for shock symptoms",
      stroke: "FAST for stroke: F-Face drooping A-Arm weakness S-Speech difficulty T-Time to call emergency. Keep person calm, note time of symptoms, don't give food/water"
    },
    safety: {
      fire: "Fire Safety: 1) Get out immediately 2) Stay out 3) Call fire department 4) If trapped: close doors, stay low, signal for help 5) Feel doors before opening 6) Have escape plan",
      earthquake: "Earthquake: DROP, COVER, HOLD ON. Get under sturdy table or against interior wall. Stay away from windows, mirrors, heavy objects. If outdoors, move away from buildings",
      flood: "Flood Safety: 1) Get to higher ground immediately 2) Don't walk/drive through moving water 3) 6 inches of water can knock you down 4) 12 inches can carry away vehicle 5) Stay informed via radio",
      tornado: "Tornado: Go to lowest floor, interior room, away from windows. Get under heavy table. Mobile homes: leave immediately, go to sturdy building. If outdoors: lie flat in low area"
    },
    firstaid: {
      cuts: "For cuts: 1) Clean hands 2) Stop bleeding with pressure 3) Clean wound gently 4) Apply antibiotic ointment 5) Cover with bandage 6) Change bandage daily 7) Watch for infection signs",
      sprains: "RICE for sprains: R-Rest the injury I-Ice for 15-20 min every 2-3 hours C-Compression with elastic bandage E-Elevation above heart level. Seek medical attention if severe",
      poisoning: "Poisoning: 1) Call Poison Control: 1-800-222-1222 2) Don't induce vomiting unless told 3) If on skin: remove contaminated clothing, rinse 15+ minutes 4) If inhaled: get fresh air",
      allergic: "Allergic reaction: Mild: antihistamine, cool compress. SEVERE (anaphylaxis): 1) Call 911 2) Use EpiPen if available 3) Position person lying down 4) Monitor breathing 5) Be ready for CPR"
    }
  };

  const getOfflineResponse = (userMessage: string): { response: string; type: string } => {
    const message = userMessage.toLowerCase();
    
    // Emergency responses
    if (message.includes('unconscious') || message.includes('unresponsive')) {
      return { response: offlineKnowledgeBase.emergency.unconscious, type: 'emergency' };
    }
    if (message.includes('bleeding') || message.includes('blood')) {
      return { response: offlineKnowledgeBase.emergency.bleeding, type: 'emergency' };
    }
    if (message.includes('choking') || message.includes('can\'t breathe')) {
      return { response: offlineKnowledgeBase.emergency.choking, type: 'emergency' };
    }
    if (message.includes('cpr') || message.includes('not breathing')) {
      return { response: offlineKnowledgeBase.emergency.cpr, type: 'emergency' };
    }

    // Medical responses
    if (message.includes('heart attack') || message.includes('chest pain')) {
      return { response: offlineKnowledgeBase.medical.heartattack, type: 'medical' };
    }
    if (message.includes('burn') || message.includes('burned')) {
      return { response: offlineKnowledgeBase.medical.burns, type: 'medical' };
    }
    if (message.includes('fracture') || message.includes('broken bone') || message.includes('broken arm') || message.includes('broken leg')) {
      return { response: offlineKnowledgeBase.medical.fractures, type: 'medical' };
    }
    if (message.includes('stroke') || message.includes('face drooping')) {
      return { response: offlineKnowledgeBase.medical.stroke, type: 'medical' };
    }

    // Safety responses
    if (message.includes('fire') || message.includes('burning building')) {
      return { response: offlineKnowledgeBase.safety.fire, type: 'safety' };
    }
    if (message.includes('earthquake') || message.includes('shaking')) {
      return { response: offlineKnowledgeBase.safety.earthquake, type: 'safety' };
    }
    if (message.includes('flood') || message.includes('flooding')) {
      return { response: offlineKnowledgeBase.safety.flood, type: 'safety' };
    }
    if (message.includes('tornado') || message.includes('twister')) {
      return { response: offlineKnowledgeBase.safety.tornado, type: 'safety' };
    }

    // First aid responses
    if (message.includes('cut') || message.includes('wound')) {
      return { response: offlineKnowledgeBase.firstaid.cuts, type: 'medical' };
    }
    if (message.includes('sprain') || message.includes('twisted ankle')) {
      return { response: offlineKnowledgeBase.firstaid.sprains, type: 'medical' };
    }
    if (message.includes('poison') || message.includes('toxic')) {
      return { response: offlineKnowledgeBase.firstaid.poisoning, type: 'emergency' };
    }
    if (message.includes('allergic') || message.includes('allergy') || message.includes('epipen')) {
      return { response: offlineKnowledgeBase.firstaid.allergic, type: 'emergency' };
    }

    // Default response
    return {
      response: "I have extensive offline knowledge about: Emergency CPR, Choking, Bleeding, Heart attacks, Burns, Fractures, Strokes, Fire safety, Earthquake procedures, Flood safety, Tornado response, Cuts & wounds, Sprains, Poisoning, and Allergic reactions. Ask me about any of these topics for detailed guidance. Remember: Call emergency services immediately for life-threatening situations!",
      type: 'general'
    };
  };

  const handleSendMessage = async () => {
    if (!inputText.trim()) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      text: inputText.trim(),
      sender: 'user',
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInputText('');
    setIsLoading(true);

    // Simulate processing time for realism
    setTimeout(() => {
      const { response, type } = getOfflineResponse(userMessage.text);

      const botMessage: Message = {
        id: (Date.now() + 1).toString(),
        text: response,
        sender: 'bot',
        timestamp: new Date(),
        type: type as any
      };

      setMessages(prev => [...prev, botMessage]);
      setIsLoading(false);
    }, 500);
  };

  const getMessageIcon = (type?: string) => {
    switch (type) {
      case 'emergency': return <AlertTriangle className="w-3 h-3 text-emergency" />;
      case 'medical': return <Heart className="w-3 h-3 text-medical" />;
      case 'safety': return <Shield className="w-3 h-3 text-safety" />;
      default: return <Database className="w-3 h-3 text-muted-foreground" />;
    }
  };

  const quickActions = [
    { text: "Someone is choking, what do I do?", type: 'emergency' },
    { text: "How to perform CPR?", type: 'emergency' },
    { text: "Heart attack symptoms and response", type: 'medical' },
    { text: "How to treat severe burns?", type: 'medical' },
    { text: "Earthquake safety procedures", type: 'safety' },
    { text: "How to stop severe bleeding?", type: 'emergency' }
  ];

  return (
    <div className="max-w-4xl mx-auto space-y-4">
      <Card className="border-0 shadow-sm bg-card/50 backdrop-blur-sm">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <MessageSquare className="w-5 h-5 text-safety" />
              Offline Emergency Assistant
            </CardTitle>
            <Badge variant="secondary" className="text-xs">
              <WifiOff className="w-3 h-3 mr-1" />
              Offline Mode
            </Badge>
          </div>
        </CardHeader>
      </Card>

      <Card className="border-0 shadow-sm bg-card/50 backdrop-blur-sm">
        <CardContent className="p-4">
          <div className="space-y-4 max-h-96 overflow-y-auto">
            {messages.map((message) => (
              <div key={message.id} className={`flex gap-3 ${message.sender === 'user' ? 'justify-end' : 'justify-start'}`}>
                <div className={`max-w-xs lg:max-w-md px-4 py-2 rounded-2xl ${
                  message.sender === 'user' 
                    ? 'bg-primary text-primary-foreground' 
                    : 'bg-muted'
                }`}>
                  {message.sender === 'bot' && (
                    <div className="flex items-center gap-2 mb-1">
                      {getMessageIcon(message.type)}
                      <span className="text-xs text-muted-foreground">Offline Assistant</span>
                    </div>
                  )}
                  <p className="text-sm whitespace-pre-wrap">{message.text}</p>
                  <div className="text-xs opacity-70 mt-1">
                    {message.timestamp.toLocaleTimeString()}
                  </div>
                </div>
              </div>
            ))}
            {isLoading && (
              <div className="flex gap-3 justify-start">
                <div className="bg-muted px-4 py-2 rounded-2xl">
                  <div className="flex items-center gap-2">
                    <Database className="w-3 h-3 text-muted-foreground" />
                    <div className="flex gap-1">
                      <div className="w-2 h-2 bg-muted-foreground/50 rounded-full animate-bounce" />
                      <div className="w-2 h-2 bg-muted-foreground/50 rounded-full animate-bounce" style={{ animationDelay: '0.1s' }} />
                      <div className="w-2 h-2 bg-muted-foreground/50 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }} />
                    </div>
                  </div>
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>

          <Separator className="my-4" />

          <div className="space-y-4">
            <div className="flex gap-2">
              <Input
                value={inputText}
                onChange={(e) => setInputText(e.target.value)}
                placeholder="Ask about emergencies, first aid, or safety procedures..."
                onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
                className="flex-1"
              />
              <Button onClick={handleSendMessage} disabled={!inputText.trim() || isLoading} size="icon">
                <Send className="w-4 h-4" />
              </Button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              {quickActions.map((action, index) => (
                <Button
                  key={index}
                  variant="outline"
                  size="sm"
                  className="text-left justify-start h-auto p-3"
                  onClick={() => setInputText(action.text)}
                >
                  <span className="text-xs">{action.text}</span>
                </Button>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default OfflineChatbot;