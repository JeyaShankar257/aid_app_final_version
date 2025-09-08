import React, { useState, useRef, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { 
  MessageSquare, 
  Send, 
  Wifi, 
  WifiOff, 
  Bot, 
  User,
  AlertTriangle,
  Heart,
  Shield
} from 'lucide-react';

interface Message {
  id: string;
  text: string;
  sender: 'user' | 'bot';
  timestamp: Date;
  type?: 'emergency' | 'medical' | 'safety' | 'general';
}

const EmergencyChatbot: React.FC = () => {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      text: "Hello! I'm your Emergency AI Assistant. I can help you with medical emergencies, safety guidance, and crisis situations. How can I help you today?",
      sender: 'bot',
      timestamp: new Date(),
      type: 'general'
    }
  ]);
  const [inputText, setInputText] = useState('');
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const offlineResponses = {
    emergency: [
      "If someone is unconscious but breathing, place them in the recovery position. Call emergency services immediately.",
      "For severe bleeding: Apply direct pressure with a clean cloth. Don't remove the cloth if it becomes soaked - add more layers.",
      "For choking: If conscious, encourage coughing. If not effective, perform back blows and abdominal thrusts."
    ],
    medical: [
      "For suspected heart attack: Call emergency services, give aspirin if not allergic, keep person calm and still.",
      "For burns: Cool with running water for 10-20 minutes. Don't use ice. Cover with clean, non-stick dressing.",
      "For fractures: Don't move the person unless in immediate danger. Support the injured area and call for help."
    ],
    safety: [
      "In case of fire: Get out, stay out, call fire department. If trapped, close doors, stay low, signal for help.",
      "For natural disasters: Drop, cover, hold on for earthquakes. For flooding, get to higher ground immediately.",
      "If being followed: Go to a public place, don't go home. Vary your route and trust your instincts."
    ],
    default: [
      "I'm here to help with emergency situations. Ask me about medical emergencies, safety procedures, or first aid.",
      "Remember: In a real emergency, always call your local emergency number first (911, 112, etc.).",
      "I can provide guidance on first aid, emergency procedures, and safety protocols."
    ]
  };

  const getOfflineResponse = (userMessage: string): { response: string; type: string } => {
    const message = userMessage.toLowerCase();
    
    if (message.includes('emergency') || message.includes('urgent') || message.includes('help')) {
      return {
        response: offlineResponses.emergency[Math.floor(Math.random() * offlineResponses.emergency.length)],
        type: 'emergency'
      };
    } else if (message.includes('medical') || message.includes('heart') || message.includes('bleeding') || message.includes('injury')) {
      return {
        response: offlineResponses.medical[Math.floor(Math.random() * offlineResponses.medical.length)],
        type: 'medical'
      };
    } else if (message.includes('safety') || message.includes('fire') || message.includes('earthquake') || message.includes('danger')) {
      return {
        response: offlineResponses.safety[Math.floor(Math.random() * offlineResponses.safety.length)],
        type: 'safety'
      };
    } else {
      return {
        response: offlineResponses.default[Math.floor(Math.random() * offlineResponses.default.length)],
        type: 'general'
      };
    }
  };

  const sendToGemini = async (message: string): Promise<{ response: string; type: string }> => {
    try {
      const response = await fetch('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=AIzaSyD-kThkGoV8g6PMxsZc98xwQM2YmFXLQkk', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: `You are an emergency AI assistant. Respond to this query with helpful, accurate emergency guidance. Keep responses concise and actionable. Always remind users to call emergency services for real emergencies. Query: ${message}`
            }]
          }]
        })
      });

      if (!response.ok) throw new Error('API request failed');
      
      const data = await response.json();
      const botResponse = data.candidates?.[0]?.content?.parts?.[0]?.text || "I'm sorry, I couldn't process that request. Please try again.";
      
      return {
        response: botResponse,
        type: 'general'
      };
    } catch (error) {
      console.error('Gemini API error:', error);
      return getOfflineResponse(message);
    }
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

    try {
      const { response, type } = isOnline 
        ? await sendToGemini(userMessage.text)
        : getOfflineResponse(userMessage.text);

      const botMessage: Message = {
        id: (Date.now() + 1).toString(),
        text: response,
        sender: 'bot',
        timestamp: new Date(),
        type: type as any
      };

      setMessages(prev => [...prev, botMessage]);
    } catch (error) {
      const errorMessage: Message = {
        id: (Date.now() + 1).toString(),
        text: "I'm experiencing technical difficulties. Here's some general emergency guidance: Always call emergency services first in a real emergency.",
        sender: 'bot',
        timestamp: new Date(),
        type: 'general'
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const getMessageIcon = (type?: string) => {
    switch (type) {
      case 'emergency': return <AlertTriangle className="w-3 h-3 text-emergency" />;
      case 'medical': return <Heart className="w-3 h-3 text-medical" />;
      case 'safety': return <Shield className="w-3 h-3 text-safety" />;
      default: return <Bot className="w-3 h-3 text-muted-foreground" />;
    }
  };

  const quickActions = [
    { text: "What should I do if someone is choking?", type: 'medical' },
    { text: "How to help someone having a heart attack?", type: 'emergency' },
    { text: "Fire safety procedures", type: 'safety' },
    { text: "Basic first aid steps", type: 'medical' }
  ];

  return (
    <div className="max-w-4xl mx-auto space-y-4">
      <Card className="border-0 shadow-sm bg-card/50 backdrop-blur-sm">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <MessageSquare className="w-5 h-5 text-safety" />
              Emergency AI Assistant
            </CardTitle>
            <Badge variant={isOnline ? "default" : "secondary"} className="text-xs">
              {isOnline ? <Wifi className="w-3 h-3 mr-1" /> : <WifiOff className="w-3 h-3 mr-1" />}
              {isOnline ? 'Online Mode' : 'Offline Mode'}
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
                      <span className="text-xs text-muted-foreground">AI Assistant</span>
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
                    <Bot className="w-3 h-3 text-muted-foreground" />
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
                placeholder="Ask about emergency procedures, first aid, or safety guidance..."
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

export default EmergencyChatbot;