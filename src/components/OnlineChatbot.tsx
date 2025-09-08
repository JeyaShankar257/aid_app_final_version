import React, { useState, useRef, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Alert, AlertDescription } from '@/components/ui/alert';
import {
  MessageSquare,
  Send,
  Wifi,
  Bot,
  AlertTriangle,
  Heart,
  Shield,
  Settings,
  Key
} from 'lucide-react';

// --- Type Definitions for API Interaction ---

// Defines the structure of a single part of a message (e.g., text)
interface Part {
  text: string;
}

// Defines the structure of a message in the conversation history
interface HistoryItem {
  role: 'user' | 'model';
  parts: Part[];
}

// Defines a message object for the UI state
interface Message {
  id: string;
  text: string;
  sender: 'user' | 'bot';
  timestamp: Date;
  type?: 'emergency' | 'medical' | 'safety' | 'general';
}

const OnlineChatbot: React.FC = () => {
  // Stop speech synthesis
  const stopSpeaking = () => {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
      setIsSpeaking(false);
    }
  };
  const [messages, setMessages] = useState<Message[]>([{
      id: '1',
      text: "🌐 Online Emergency AI Assistant powered by Google Gemini. I can provide advanced emergency guidance, real-time information, and personalized assistance. Please configure your Gemini API key to get started.",
      sender: 'bot',
      timestamp: new Date(),
      type: 'general'
    }
  ]);
  const [isSpeaking, setIsSpeaking] = useState(false);
  // Auto-read (text-to-speech) function
  const speakLatestBotMessage = () => {
    const lastBotMsg = [...messages].reverse().find(m => m.sender === 'bot');
    if (lastBotMsg && 'speechSynthesis' in window) {
      const utter = new window.SpeechSynthesisUtterance(lastBotMsg.text);
      utter.onstart = () => setIsSpeaking(true);
      utter.onend = () => setIsSpeaking(false);
      window.speechSynthesis.cancel(); // Stop any ongoing speech
      window.speechSynthesis.speak(utter);
    }
  };
  const [history, setHistory] = useState<HistoryItem[]>([]);
  const [inputText, setInputText] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [apiKey, setApiKey] = useState(() => localStorage.getItem('gemini_api_key') || '');
  const [showApiKeySetup, setShowApiKeySetup] = useState(!apiKey);
  const [tempApiKey, setTempApiKey] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const saveApiKey = () => {
    if (tempApiKey.trim()) {
      localStorage.setItem('gemini_api_key', tempApiKey.trim());
      setApiKey(tempApiKey.trim());
      setShowApiKeySetup(false);
      setTempApiKey('');
      
      const confirmMessage: Message = {
        id: Date.now().toString(),
        text: "✅ API Key configured successfully! I'm now ready to provide advanced emergency guidance. How can I help you today?",
        sender: 'bot',
        timestamp: new Date(),
        type: 'general'
      };
      setMessages(prev => [...prev, confirmMessage]);
    }
  };

  const sendToGemini = async (message: string, currentHistory: HistoryItem[] = []): Promise<{ response: string; type: string }> => {
    if (!apiKey) throw new Error('API key not configured');

    // Use the Gemini 1.5 Flash model
    const API_ENDPOINT = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;

    // **FIX 2: System instruction defines the bot's persona separately and cleanly**
    const systemInstruction = {
      role: "user",
      parts: [{ text: `You are an expert emergency AI assistant. Provide helpful, accurate, and detailed emergency guidance. 
      - Always start by strongly advising users to call emergency services (like 911, 112, etc.) for any real, time-sensitive emergency. This is your most important instruction.
      - Be compassionate and clear. Use formatting like lists or bold text to make instructions easy to follow in a crisis.
      - Your goal is to provide supportive guidance, not to replace professional emergency services.
      
      When a user asks a question, provide:
      1. A clear reminder to call emergency services.
      2. Immediate actions to take while waiting for help.
      3. Step-by-step guidance.
      4. Key warning signs to watch for.
      `}]
    };

    // Send the request to the Gemini API
    const response = await fetch(API_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        // Include system instructions, conversation history, and the current message
        contents: [
            systemInstruction, 
            ...currentHistory, 
            { role: "user", parts: [{ text: message }] }
        ],
        safetySettings: [
            { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
            { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
            { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
            { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE" }
        ],
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024
        }
      })
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ error: { message: "An unknown API error occurred." } }));
      throw new Error(`API request failed: ${response.status} - ${errorData.error.message}`);
    }
    
    const data = await response.json();

    // Handle cases where the API returns no candidates
    if (!data.candidates || data.candidates.length === 0) {
      if (data.promptFeedback && data.promptFeedback.blockReason) {
        throw new Error(`Request was blocked by the API for safety reasons: ${data.promptFeedback.blockReason}`);
      } else {
        throw new Error("The API returned an empty response. The content may have been blocked.");
      }
    }
    
    const botResponse = data.candidates[0]?.content?.parts[0]?.text || "I'm sorry, I couldn't process that request. Please try again.";
    
    // Determine message type (this logic is fine)
    let type = 'general';
    const lowercaseResponse = botResponse.toLowerCase();
    if (lowercaseResponse.includes('emergency') || lowercaseResponse.includes('911') || lowercaseResponse.includes('urgent')) {
      type = 'emergency';
    } else if (lowercaseResponse.includes('medical') || lowercaseResponse.includes('hospital') || lowercaseResponse.includes('doctor')) {
      type = 'medical';
    } else if (lowercaseResponse.includes('safety') || lowercaseResponse.includes('secure') || lowercaseResponse.includes('protect')) {
      type = 'safety';
    }
    
    return { response: botResponse, type };
  };

  const handleSendMessage = async () => {
    if (!inputText.trim() || !apiKey) {
      if (!apiKey) setShowApiKeySetup(true);
      return;
    }

    const userMessageText = inputText.trim();
    const userMessage: Message = {
      id: Date.now().toString(),
      text: userMessageText,
      sender: 'user',
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInputText('');
    setIsLoading(true);

    try {
      const { response, type } = await sendToGemini(userMessageText, history);

      const botMessage: Message = {
        id: (Date.now() + 1).toString(),
        text: response,
        sender: 'bot',
        timestamp: new Date(),
        type: type as any
      };
      setMessages(prev => [...prev, botMessage]);

      // Update conversation history after a successful exchange
      setHistory(prevHistory => [
        ...prevHistory,
        { role: 'user', parts: [{ text: userMessageText }] },
        { role: 'model', parts: [{ text: response }] },
      ]);

    } catch (error) {
      console.error('Error details:', error);
      
      let errorText = "⚠️ I'm sorry, I encountered an error.\n\n";
      if (error instanceof Error) {
          errorText += error.message;
      } else {
          errorText += "An unknown error occurred.";
      }
      
      const errorMessage: Message = {
        id: (Date.now() + 1).toString(),
        text: errorText,
        sender: 'bot',
        timestamp: new Date(),
        type: 'emergency'
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  // Helper function to get the appropriate icon for each message type

  const getMessageIcon = (type?: string) => {
    switch (type) {
      case 'emergency': return <AlertTriangle className="w-3 h-3 text-red-500" />;
      case 'medical': return <Heart className="w-3 h-3 text-rose-500" />;
      case 'safety': return <Shield className="w-3 h-3 text-blue-500" />;
      default: return <Bot className="w-3 h-3 text-muted-foreground" />;
    }
  };

  const quickActions = [
    { text: "What are the signs of a heart attack and what should I do?", type: 'medical' },
    { text: "How do I help someone who is choking?", type: 'emergency' },
    { text: "Steps for earthquake emergency preparedness", type: 'safety' },
    { text: "How to treat a severe burn injury?", type: 'medical' },
    { text: "What to do during a house fire?", type: 'emergency' },
    { text: "Signs of stroke and immediate response", type: 'medical' }
  ];

  return (
    <div className="max-w-4xl mx-auto space-y-4">
      <div className="flex justify-end mb-2 gap-2">
        <Button
          variant="outline"
          size="icon"
          aria-label="Auto Read Bot Response"
          onClick={speakLatestBotMessage}
          disabled={isSpeaking || !messages.some(m => m.sender === 'bot')}
          className="shadow-sm"
        >
          {/* Speaker icon */}
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="none" viewBox="0 0 24 24"><path stroke="currentColor" strokeWidth="2" d="M5 9v6h4l5 5V4l-5 5H5zm13.54 2.46a5 5 0 0 0 0-7.07m0 14.14a9 9 0 0 0 0-12.73"/></svg>
        </Button>
        <Button
          variant="outline"
          size="icon"
          aria-label="Stop Auto Read"
          onClick={stopSpeaking}
          disabled={!isSpeaking}
          className="shadow-sm"
        >
          {/* Stop icon */}
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="none" viewBox="0 0 24 24"><rect x="6" y="6" width="12" height="12" rx="2" stroke="currentColor" strokeWidth="2"/></svg>
        </Button>
      </div>
      <Card className="border-0 shadow-sm bg-card/50 backdrop-blur-sm">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <MessageSquare className="w-5 h-5 text-blue-500" />
              Online Emergency AI Assistant
            </CardTitle>
            <div className="flex items-center gap-2">
              <Badge variant="default" className="text-xs bg-green-600 hover:bg-green-700">
                <Wifi className="w-3 h-3 mr-1" />
                Online Mode
              </Badge>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setShowApiKeySetup(!showApiKeySetup)}
                className="text-xs hover:bg-slate-200 dark:hover:bg-slate-800"
              >
                <Settings className="w-3 h-3 mr-1" />
                API Settings
              </Button>
            </div>
          </div>
        </CardHeader>
      </Card>

      {showApiKeySetup && (
        <Card className="border-0 shadow-md bg-card/50 backdrop-blur-sm border-l-4 border-l-blue-500 animate-in fade-in duration-300">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-sm">
              <Key className="w-4 h-4 text-blue-500" />
              Configure Gemini API Key
            </CardTitle>
          </CardHeader>
          <CardContent>
            <Alert className="mb-4 border-blue-200 bg-blue-50 dark:bg-blue-950/30">
              <AlertTriangle className="h-4 w-4 text-blue-500" />
              <AlertDescription>
                <strong>How to Get Your Gemini API Key:</strong><br/>
                1. Visit <a href="https://aistudio.google.com/app/apikey" target="_blank" rel="noopener noreferrer" className="text-blue-600 underline hover:text-blue-800 font-medium">Google AI Studio</a><br/>
                2. Sign in with your Google account and create an API Key<br/>
                3. Copy the key and paste it below<br/>
                <div className="mt-2 pt-2 border-t border-blue-100 dark:border-blue-800">
                  <strong>Security Note:</strong> Your API key is stored only in your browser's local storage.
                </div>
              </AlertDescription>
            </Alert>
            
            <div className="space-y-3">
              <div className="flex flex-col gap-3">
                <div className="flex gap-2">
                  <Input
                    type="password"
                    placeholder="Paste your Gemini API key here..."
                    value={tempApiKey}
                    onChange={(e) => setTempApiKey(e.target.value)}
                    className="flex-1 border-blue-200 focus-visible:ring-blue-500"
                    onKeyPress={(e) => e.key === 'Enter' && tempApiKey.trim() && saveApiKey()}
                  />
                  <Button 
                    onClick={saveApiKey} 
                    disabled={!tempApiKey.trim()}
                    className="bg-blue-600 hover:bg-blue-700 transition-all duration-200 hover:scale-105"
                  >
                    <Key className="w-3 h-3 mr-1" />
                    Save Key
                  </Button>
                </div>
              </div>
              {apiKey && (
                <div className="flex items-center gap-2 text-sm text-green-600 bg-green-50 dark:bg-green-950/30 p-2 rounded-md">
                  <div className="w-2 h-2 bg-green-500 rounded-full" />
                  API Key configured (ends with: ***{apiKey.slice(-4)})
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      <Card className="border-0 shadow-md bg-card/50 backdrop-blur-sm">
        <CardContent className="p-4">
          <div className="space-y-4 max-h-[400px] overflow-y-auto scrollbar-thin scrollbar-thumb-rounded scrollbar-thumb-slate-300 dark:scrollbar-thumb-slate-600 pr-2">
            {messages.map((message) => (
              <div key={message.id} className={`flex gap-3 ${message.sender === 'user' ? 'justify-end' : 'justify-start'} animate-in slide-in-from-${message.sender === 'user' ? 'right' : 'left'} duration-300`}>
                <div className={`max-w-xs lg:max-w-md px-4 py-2 rounded-2xl shadow-sm ${
                  message.sender === 'user' 
                    ? 'bg-blue-600 text-white' 
                    : 'bg-muted'
                }`}>
                  {message.sender === 'bot' && (
                    <div className="flex items-center gap-2 mb-1">
                      {getMessageIcon(message.type)}
                      <span className="text-xs text-muted-foreground font-medium">Gemini AI</span>
                    </div>
                  )}
                  <p className="text-sm whitespace-pre-wrap leading-relaxed">{message.text}</p>
                  <div className="text-xs opacity-70 mt-1 text-right">
                    {message.timestamp.toLocaleTimeString()}
                  </div>
                </div>
              </div>
            ))}
            {isLoading && (
              <div className="flex gap-3 justify-start animate-in fade-in duration-300">
                <div className="bg-muted px-4 py-2 rounded-2xl shadow-sm">
                  <div className="flex items-center gap-2">
                    <Bot className="w-3 h-3 text-blue-500" />
                    <div className="flex gap-1">
                      <div className="w-2 h-2 bg-blue-500 rounded-full animate-bounce" />
                      <div className="w-2 h-2 bg-blue-500 rounded-full animate-bounce" style={{ animationDelay: '0.1s' }} />
                      <div className="w-2 h-2 bg-blue-500 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }} />
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
                placeholder={apiKey ? "Ask about an emergency procedure..." : "Configure API key to start"}
                onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
                className="flex-1 border-blue-200 focus-visible:ring-blue-500 shadow-sm"
                disabled={!apiKey}
              />
              <Button 
                onClick={handleSendMessage} 
                disabled={!inputText.trim() || isLoading || !apiKey} 
                size="icon"
                className="bg-blue-600 hover:bg-blue-700 shadow-sm transition-all duration-200 hover:scale-105"
              >
                <Send className="w-4 h-4" />
              </Button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              {quickActions.map((action, index) => {
                const getIconByType = (type: string) => {
                  switch(type) {
                    case 'medical': return <Heart className="w-3 h-3 text-red-500" />;
                    case 'emergency': return <AlertTriangle className="w-3 h-3 text-orange-500" />;
                    case 'safety': return <Shield className="w-3 h-3 text-blue-500" />;
                    default: return <MessageSquare className="w-3 h-3 text-slate-500" />;
                  }
                };
                
                return (
                  <Button
                    key={index}
                    variant="outline"
                    size="sm"
                    className="text-left justify-start h-auto p-3 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors shadow-sm"
                    onClick={() => {
                        setInputText(action.text);
                        // Optional: Focus the input after clicking a quick action
                        document.getElementById('chat-input')?.focus();
                    }}
                    disabled={!apiKey}
                  >
                    <div className="flex items-center gap-2">
                      {getIconByType(action.type)}
                      <span className="text-xs">{action.text}</span>
                    </div>
                  </Button>
                );
              })}
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default OnlineChatbot;