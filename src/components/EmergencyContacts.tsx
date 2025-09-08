import React, { useState, useRef } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

interface LocationEntry {
  time: string;
  lat: number;
  lng: number;
}

const EmergencyContacts: React.FC = () => {
  // Load from localStorage if available
  const [senderEmail, setSenderEmail] = useState(() => localStorage.getItem('sosSenderEmail') || '');
  const [appPassword, setAppPassword] = useState(() => localStorage.getItem('sosAppPassword') || '');
  const [recipients, setRecipients] = useState(() => {
    const saved = localStorage.getItem('sosRecipients');
    return saved ? JSON.parse(saved) : ['', ''];
  });
  const [extraRecipients, setExtraRecipients] = useState(() => {
    const saved = localStorage.getItem('sosExtraRecipients');
    return saved ? JSON.parse(saved) : [];
  });
  const [sending, setSending] = useState(false);
  const [status, setStatus] = useState<string | null>(null);
  const [locationTimeline, setLocationTimeline] = useState<LocationEntry[]>([]);
  const locationIntervalRef = useRef<NodeJS.Timeout | null>(null);

  // Track location every 3 minutes, keep last 30 min
  React.useEffect(() => {
    function addLocation() {
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition((pos) => {
          const entry = {
            time: new Date().toLocaleTimeString(),
            lat: pos.coords.latitude,
            lng: pos.coords.longitude,
          };
          setLocationTimeline((prev) => {
            const updated = [...prev, entry].filter(e => {
              // Only keep last 30 min
              const now = Date.now();
              return now - new Date().getTime() < 30 * 60 * 1000;
            });
            return updated;
          });
        });
      }
    }
    addLocation();
    locationIntervalRef.current = setInterval(addLocation, 3 * 60 * 1000);
    return () => {
      if (locationIntervalRef.current) clearInterval(locationIntervalRef.current);
    };
  }, []);

  // Persist senderEmail, appPassword, recipients, extraRecipients to localStorage
  React.useEffect(() => {
    localStorage.setItem('sosSenderEmail', senderEmail);
  }, [senderEmail]);
  React.useEffect(() => {
    localStorage.setItem('sosAppPassword', appPassword);
  }, [appPassword]);
  React.useEffect(() => {
    localStorage.setItem('sosRecipients', JSON.stringify(recipients));
  }, [recipients]);
  React.useEffect(() => {
    localStorage.setItem('sosExtraRecipients', JSON.stringify(extraRecipients));
  }, [extraRecipients]);

  const handleRecipientChange = (idx: number, value: string) => {
  setRecipients((prev) => prev.map((r, i) => (i === idx ? value : r)));
  };

  const handleAddRecipient = () => {
  setExtraRecipients((prev) => [...prev, '']);
  };

  const handleExtraRecipientChange = (idx: number, value: string) => {
  setExtraRecipients((prev) => prev.map((r, i) => (i === idx ? value : r)));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus(null);
    setSending(true);
    const allRecipients = [...recipients, ...extraRecipients].filter(r => r.trim());
    if (recipients[0].trim() === '' || recipients[1].trim() === '') {
      setStatus('At least 2 recipient emails are required.');
      setSending(false);
      return;
    }
    if (!senderEmail || !appPassword) {
      setStatus('Sender email and app password are required.');
      setSending(false);
      return;
    }
    // Get current location
    if (!navigator.geolocation) {
      setStatus('Geolocation not supported.');
      setSending(false);
      return;
    }
    navigator.geolocation.getCurrentPosition(async (pos) => {
      const lat = pos.coords.latitude;
      const lng = pos.coords.longitude;
      const now = new Date();
      const locationUrl = `https://maps.google.com/?q=${lat},${lng}`;
      // Format timeline
      const timeline = [
        ...locationTimeline,
        { time: now.toLocaleTimeString(), lat, lng }
      ];
      let timelineStr = '';
      timeline.forEach((entry, idx) => {
        timelineStr += `${idx + 1}. ${entry.time} - https://maps.google.com/?q=${entry.lat},${entry.lng}\n`;
      });
      const message = `🚨 SOS Alert - Emergency Location Update\n\nCurrent Time: ${now.toLocaleString()}\nCurrent Location: ${locationUrl}\n\nLast 30 min timeline:\n${timelineStr}`;
      // Send to backend
      try {
        const res = await fetch('http://localhost:5000/api/send-sos-email', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            senderEmail,
            appPassword,
            recipients: allRecipients,
            message,
          })
        });
        if (res.ok) {
          setStatus('SOS email sent successfully!');
        } else {
          setStatus('Failed to send SOS email.');
        }
      } catch (err) {
        setStatus('Error sending SOS email.');
      }
      setSending(false);
    }, (err) => {
      setStatus('Unable to get location.');
      setSending(false);
    });
  };

  return (
    <div className="max-w-xl mx-auto mt-8">
      <Card>
        <CardHeader>
          <CardTitle>🚨 SOS Email Form</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <Label>Sender Gmail</Label>
              <Input type="email" value={senderEmail} onChange={e => setSenderEmail(e.target.value)} required />
            </div>
            <div>
              <Label>Sender App Password</Label>
              <Input type="password" value={appPassword} onChange={e => setAppPassword(e.target.value)} required />
              <small className="text-muted-foreground">Get app password from Gmail security settings.</small>
            </div>
            <div>
              <Label>Recipient Email 1</Label>
              <Input type="email" value={recipients[0]} onChange={e => handleRecipientChange(0, e.target.value)} required />
            </div>
            <div>
              <Label>Recipient Email 2</Label>
              <Input type="email" value={recipients[1]} onChange={e => handleRecipientChange(1, e.target.value)} required />
            </div>
            {extraRecipients.map((r, idx) => (
              <div key={idx}>
                <Label>Recipient Email {idx + 3} (optional)</Label>
                <Input type="email" value={r} onChange={e => handleExtraRecipientChange(idx, e.target.value)} />
              </div>
            ))}
            <Button type="button" onClick={handleAddRecipient} variant="outline">Add More Recipient</Button>
            <Button type="submit" className="bg-red-600 text-white w-full" disabled={sending}>
              {sending ? 'Sending SOS...' : 'Send SOS Email'}
            </Button>
            {status && <div className="text-center text-red-700 mt-2">{status}</div>}
          </form>
          {/* Display all recipient emails below the form */}
          <div className="mt-6">
            <h4 className="font-semibold mb-2">Saved Recipient Emails</h4>
            <ul className="list-disc pl-5 text-sm">
              {[...recipients, ...extraRecipients].filter(r => r.trim()).length === 0 ? (
                <li className="text-gray-500">No recipient emails added yet.</li>
              ) : (
                [...recipients, ...extraRecipients].filter(r => r.trim()).map((email, idx) => (
                  <li key={idx} className="mb-1">{email}</li>
                ))
              )}
            </ul>
          </div>
        </CardContent>
      </Card>
      <Card className="mt-6">
        <CardHeader>
          <CardTitle>Location Timeline (last 30 min)</CardTitle>
        </CardHeader>
        <CardContent>
          <ul className="text-sm">
            {locationTimeline.map((entry, idx) => (
              <li key={idx}>
                {entry.time}: <a href={`https://maps.google.com/?q=${entry.lat},${entry.lng}`} target="_blank" rel="noopener noreferrer">{entry.lat}, {entry.lng}</a>
              </li>
            ))}
          </ul>
        </CardContent>
      </Card>
    </div>
  );
};

export default EmergencyContacts;