import React, { useState, useEffect } from 'react';
import { MessageSquare, Heart, Phone, PlusCircle, MinusCircle } from 'lucide-react';
import OfflineChatbot from './OfflineChatbot';
import OnlineChatbot from './OnlineChatbot';
import FirstAidTraining from './FirstAidTraining';
import EmergencyContacts from './EmergencyContacts';
import LocationMap from './LocationMap';

interface EmergencyDashboardProps {}

const EmergencyDashboard: React.FC<EmergencyDashboardProps> = () => {
  const [activeTab, setActiveTab] = useState<'dashboard' | 'offline-chatbot' | 'online-chatbot' | 'training' | 'contacts'>('dashboard');
  const [email, setEmail] = useState<string>('');
  const [password, setPassword] = useState<string>('');
  const [showEmailForm, setShowEmailForm] = useState<boolean>(false);
  const [savedEmails, setSavedEmails] = useState<{email: string, password: string}[]>([]);

  // Load saved emails from localStorage on component mount
  useEffect(() => {
    const savedData = localStorage.getItem('sosContacts');
    if (savedData) {
      setSavedEmails(JSON.parse(savedData));
    }
  }, []);

  // Save emails to localStorage whenever the savedEmails state changes
  useEffect(() => {
    localStorage.setItem('sosContacts', JSON.stringify(savedEmails));
  }, [savedEmails]);

  const handleSendSOS = () => {
    // Get sender email, app password, and recipients from localStorage
    const senderEmail = localStorage.getItem('sosSenderEmail') || '';
    const appPassword = localStorage.getItem('sosAppPassword') || '';
    const recipients = (() => {
      const r = localStorage.getItem('sosRecipients');
      return r ? JSON.parse(r) : [];
    })();
    const extraRecipients = (() => {
      const r = localStorage.getItem('sosExtraRecipients');
      return r ? JSON.parse(r) : [];
    })();
    const allRecipients = [...recipients, ...extraRecipients].filter(r => r.trim());
    if (!senderEmail || !appPassword || allRecipients.length < 2) {
      alert('Please add sender email, app password, and at least two recipient emails in Emergency Contacts.');
      setShowEmailForm(true);
      return;
    }
    // Get current location
    if (!navigator.geolocation) {
      alert('Geolocation not supported.');
      return;
    }
    navigator.geolocation.getCurrentPosition(async (pos) => {
      const lat = pos.coords.latitude;
      const lng = pos.coords.longitude;
      const now = new Date();
      const locationUrl = `https://maps.google.com/?q=${lat},${lng}`;
      const message = `🚨 SOS Alert - Emergency Location Update\n\nCurrent Time: ${now.toLocaleString()}\nCurrent Location: ${locationUrl}`;
      try {
        const res = await fetch('http://localhost:5000/api/send-sos-email', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ senderEmail, appPassword, recipients: allRecipients, message })
        });
        if (res.ok) {
          alert('SOS email sent successfully!');
        } else {
          alert('Failed to send SOS email.');
        }
      } catch (err) {
        alert('Error sending SOS email.');
      }
    }, (err) => {
      alert('Unable to get location.');
    });
  };

  const handleAddEmail = () => {
    if (!email || !password) {
      alert('Please enter both email and password');
      return;
    }
    
    setSavedEmails([...savedEmails, {email, password}]);
    setEmail('');
    setPassword('');
    setShowEmailForm(false);
  };

  const handleRemoveEmail = (emailToRemove: string) => {
    setSavedEmails(savedEmails.filter(item => item.email !== emailToRemove));
  };

  if (activeTab !== 'dashboard') {
    // Feature view layout for navigation destinations
    return (
      <div className="min-h-screen bg-gray-100 flex flex-col items-center p-4">
        <div className="w-full max-w-4xl bg-white rounded-xl shadow-lg p-6">
          <button 
            className="mb-4 text-blue-500 flex items-center gap-2" 
            onClick={() => setActiveTab('dashboard')}
          >
            ← Back to Dashboard
          </button>
          <div className="w-full">
            {activeTab === 'offline-chatbot' && <OfflineChatbot />}
            {activeTab === 'online-chatbot' && <OnlineChatbot />}
            {activeTab === 'training' && <FirstAidTraining />}
            {activeTab === 'contacts' && <EmergencyContacts />}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100 flex flex-col items-center p-4 relative">
      {/* Fixed Header with App Title */}
      <div className="w-full max-w-6xl flex justify-between items-center mb-6 sticky top-0 z-10 bg-gray-100 py-2">
        <h1 className="text-3xl font-bold text-navy-800">Safety Guardian</h1>
      </div>
      
      {/* Fixed SOS Button */}
      <div className="fixed top-4 right-4 z-20">
        <button
          className="bg-red-500 text-white font-bold text-2xl w-20 h-20 rounded-full shadow-lg hover:bg-red-600 transition-all flex items-center justify-center"
          onClick={handleSendSOS}
        >
          SOS
        </button>
      </div>

      {/* Main Content Container - Full Width */}
      <div className="w-full max-w-6xl flex flex-col items-center">
        {/* Email Registration Form */}
        {showEmailForm && (
          <div className="w-full bg-white rounded-xl shadow-md p-4 mb-4">
            <h3 className="font-semibold mb-2">Add Emergency Contact Email</h3>
            <div className="flex flex-col gap-2">
              <input 
                type="email" 
                placeholder="Email" 
                className="border rounded p-2" 
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
              <input 
                type="password" 
                placeholder="Password" 
                className="border rounded p-2" 
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
              <button 
                className="bg-blue-500 text-white py-2 rounded hover:bg-blue-600"
                onClick={handleAddEmail}
              >
                Save Contact
              </button>
            </div>
          </div>
        )}

        {/* Saved Emails List */}
        {savedEmails.length > 0 && (
          <div className="w-full bg-white rounded-xl shadow-md p-4 mb-4">
            <h3 className="font-semibold mb-2">Emergency Contacts</h3>
            <ul className="divide-y">
              {savedEmails.map((item, index) => (
                <li key={index} className="py-2 flex justify-between items-center">
                  <span>{item.email}</span>
                  <button 
                    className="text-red-500" 
                    onClick={() => handleRemoveEmail(item.email)}
                  >
                    <MinusCircle size={18} />
                  </button>
                </li>
              ))}
            </ul>
          </div>
        )}

        <div className="flex justify-end w-full mb-4">
          {/* Removed Add Contact Email button */}
        </div>

        {/* Map Component - 50% of viewport height and full width */}
        <div className="w-full mb-6">
          <div className="w-full h-[50vh] rounded-xl overflow-hidden shadow-md">
            <LocationMap className="h-full" />
          </div>
        </div>

        {/* Navigation Cards - 2x2 Grid with Full Width */}
        <div className="w-full grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
          {/* Offline Chatbot Card */}
          <button
            onClick={() => setActiveTab('offline-chatbot')}
            className="bg-purple-500 text-white rounded-xl p-6 shadow-md hover:shadow-lg transition-all flex flex-col items-center justify-center h-36"
          >
            <MessageSquare className="mb-3" size={40} />
            <span className="font-semibold text-lg">Offline Chatbot</span>
          </button>

          {/* Online Chatbot Card */}
          <button
            onClick={() => setActiveTab('online-chatbot')}
            className="bg-blue-500 text-white rounded-xl p-6 shadow-md hover:shadow-lg transition-all flex flex-col items-center justify-center h-36"
          >
            <MessageSquare className="mb-3" size={40} />
            <span className="font-semibold text-lg">Online Chatbot</span>
          </button>

          {/* First Aid Training Card */}
          <button
            onClick={() => setActiveTab('training')}
            className="bg-orange-500 text-white rounded-xl p-6 shadow-md hover:shadow-lg transition-all flex flex-col items-center justify-center h-36"
          >
            <Heart className="mb-3" size={40} />
            <span className="font-semibold text-lg">First Aid Training</span>
          </button>

          {/* Emergency Contacts Card */}
          <button
            onClick={() => setActiveTab('contacts')}
            className="bg-green-500 text-white rounded-xl p-6 shadow-md hover:shadow-lg transition-all flex flex-col items-center justify-center h-36"
          >
            <Phone className="mb-3" size={40} />
            <span className="font-semibold text-lg">Emergency Contacts</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default EmergencyDashboard;