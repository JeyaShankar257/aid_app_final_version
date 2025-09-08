import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { 
  FileText, 
  Download, 
  Eye, 
  Calendar, 
  MapPin, 
  Clock, 
  AlertTriangle,
  Shield,
  Heart,
  Phone,
  MessageSquare
} from 'lucide-react';

interface EmergencyLogEntry {
  id: string;
  timestamp: Date;
  type: 'sos_alert' | 'fall_detection' | 'panic_button' | 'medical_emergency' | 'safety_check';
  title: string;
  description: string;
  location?: {
    latitude: number;
    longitude: number;
    address?: string;
  };
  contacts_notified: string[];
  resolution: 'resolved' | 'pending' | 'false_alarm';
  notes?: string;
  evidence?: string[];
}

const EmergencyLog: React.FC = () => {
  const [selectedLog, setSelectedLog] = useState<EmergencyLogEntry | null>(null);
  const [filter, setFilter] = useState<'all' | 'sos_alert' | 'fall_detection' | 'panic_button' | 'medical_emergency'>('all');

  const logEntries: EmergencyLogEntry[] = [
    {
      id: '1',
      timestamp: new Date('2024-01-15T14:30:00'),
      type: 'fall_detection',
      title: 'Fall Detected',
      description: 'Automatic fall detection triggered during morning walk',
      location: {
        latitude: 40.7128,
        longitude: -74.0060,
        address: '123 Main St, New York, NY'
      },
      contacts_notified: ['Sarah Johnson', 'Emergency Services'],
      resolution: 'false_alarm',
      notes: 'User confirmed they dropped their phone, not an actual fall'
    },
    {
      id: '2',
      timestamp: new Date('2024-01-10T22:45:00'),
      type: 'sos_alert',
      title: 'SOS Emergency Alert',
      description: 'Manual SOS activation - feeling unwell at home',
      location: {
        latitude: 40.7589,
        longitude: -73.9851,
        address: '456 Home Ave, New York, NY'
      },
      contacts_notified: ['Sarah Johnson', 'Dr. Michael Chen', '911'],
      resolution: 'resolved',
      notes: 'Medical assistance provided, transported to hospital for observation'
    },
    {
      id: '3',
      timestamp: new Date('2024-01-05T18:20:00'),
      type: 'panic_button',
      title: 'Panic Button Activated',
      description: 'Felt unsafe walking alone in unfamiliar area',
      location: {
        latitude: 40.7409,
        longitude: -73.9883,
        address: 'Times Square, New York, NY'
      },
      contacts_notified: ['John Johnson', 'Sarah Johnson'],
      resolution: 'resolved',
      notes: 'Safely reached public area, contacts provided guidance'
    }
  ];

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'sos_alert': return AlertTriangle;
      case 'fall_detection': return AlertTriangle;
      case 'panic_button': return Shield;
      case 'medical_emergency': return Heart;
      case 'safety_check': return Shield;
      default: return FileText;
    }
  };

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'sos_alert': return 'bg-emergency text-emergency-foreground';
      case 'fall_detection': return 'bg-warning text-warning-foreground';
      case 'panic_button': return 'bg-safety text-safety-foreground';
      case 'medical_emergency': return 'bg-medical text-medical-foreground';
      case 'safety_check': return 'bg-primary text-primary-foreground';
      default: return 'bg-secondary text-secondary-foreground';
    }
  };

  const getResolutionColor = (resolution: string) => {
    switch (resolution) {
      case 'resolved': return 'bg-medical text-medical-foreground';
      case 'pending': return 'bg-warning text-warning-foreground';
      case 'false_alarm': return 'bg-muted text-muted-foreground';
      default: return 'bg-secondary text-secondary-foreground';
    }
  };

  const filteredLogs = filter === 'all' 
    ? logEntries 
    : logEntries.filter(log => log.type === filter);

  const exportLogs = () => {
    const csvContent = [
      ['Timestamp', 'Type', 'Title', 'Description', 'Location', 'Contacts Notified', 'Resolution', 'Notes'],
      ...filteredLogs.map(log => [
        log.timestamp.toISOString(),
        log.type,
        log.title,
        log.description,
        log.location?.address || '',
        log.contacts_notified.join('; '),
        log.resolution,
        log.notes || ''
      ])
    ].map(row => row.map(cell => `"${cell}"`).join(',')).join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `emergency_log_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      <Card className="border-0 shadow-sm bg-card/50 backdrop-blur-sm">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="flex items-center gap-2">
                <FileText className="w-5 h-5 text-safety" />
                Emergency Activity Log
              </CardTitle>
              <CardDescription>
                Complete record of all emergency alerts and safety events for legal evidence
              </CardDescription>
            </div>
            <Button onClick={exportLogs} className="bg-gradient-safety text-safety-foreground hover:opacity-90">
              <Download className="w-4 h-4 mr-2" />
              Export Log
            </Button>
          </div>
        </CardHeader>
      </Card>

      {/* Filter Tabs */}
      <Card className="border-0 shadow-sm bg-card/50 backdrop-blur-sm">
        <CardContent className="p-4">
          <div className="flex gap-2 flex-wrap">
            <Button 
              variant={filter === 'all' ? "default" : "outline"}
              size="sm"
              onClick={() => setFilter('all')}
            >
              All Events ({logEntries.length})
            </Button>
            <Button 
              variant={filter === 'sos_alert' ? "default" : "outline"}
              size="sm"
              onClick={() => setFilter('sos_alert')}
            >
              SOS Alerts ({logEntries.filter(l => l.type === 'sos_alert').length})
            </Button>
            <Button 
              variant={filter === 'fall_detection' ? "default" : "outline"}
              size="sm"
              onClick={() => setFilter('fall_detection')}
            >
              Fall Detection ({logEntries.filter(l => l.type === 'fall_detection').length})
            </Button>
            <Button 
              variant={filter === 'panic_button' ? "default" : "outline"}
              size="sm"
              onClick={() => setFilter('panic_button')}
            >
              Panic Button ({logEntries.filter(l => l.type === 'panic_button').length})
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Log Entries */}
      <div className="space-y-4">
        {filteredLogs.length === 0 ? (
          <Card className="border-0 shadow-sm bg-card/50 backdrop-blur-sm">
            <CardContent className="p-8 text-center">
              <FileText className="w-12 h-12 text-muted-foreground mx-auto mb-4" />
              <h3 className="text-lg font-medium mb-2">No log entries found</h3>
              <p className="text-muted-foreground">
                {filter === 'all' 
                  ? 'No emergency events have been recorded yet.' 
                  : `No ${filter.replace('_', ' ')} events found.`}
              </p>
            </CardContent>
          </Card>
        ) : (
          filteredLogs.map((log) => {
            const IconComponent = getTypeIcon(log.type);
            return (
              <Card 
                key={log.id} 
                className="border-0 shadow-sm bg-card/50 backdrop-blur-sm hover:shadow-md transition-all cursor-pointer"
                onClick={() => setSelectedLog(log)}
              >
                <CardContent className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-3">
                      <div className={`p-2 rounded-xl ${getTypeColor(log.type)}`}>
                        <IconComponent className="w-4 h-4" />
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <h4 className="font-medium">{log.title}</h4>
                          <Badge className={getResolutionColor(log.resolution)}>
                            {log.resolution.replace('_', ' ')}
                          </Badge>
                        </div>
                        <p className="text-sm text-muted-foreground mb-2">{log.description}</p>
                        <div className="flex items-center gap-4 text-xs text-muted-foreground">
                          <div className="flex items-center gap-1">
                            <Calendar className="w-3 h-3" />
                            {log.timestamp.toLocaleDateString()}
                          </div>
                          <div className="flex items-center gap-1">
                            <Clock className="w-3 h-3" />
                            {log.timestamp.toLocaleTimeString()}
                          </div>
                          {log.location && (
                            <div className="flex items-center gap-1">
                              <MapPin className="w-3 h-3" />
                              Location recorded
                            </div>
                          )}
                          <div className="flex items-center gap-1">
                            <MessageSquare className="w-3 h-3" />
                            {log.contacts_notified.length} contacts notified
                          </div>
                        </div>
                      </div>
                    </div>
                    <Button size="sm" variant="outline">
                      <Eye className="w-3 h-3 mr-1" />
                      View Details
                    </Button>
                  </div>
                </CardContent>
              </Card>
            );
          })
        )}
      </div>

      {/* Detailed View Modal */}
      {selectedLog && (
        <Dialog open={!!selectedLog} onOpenChange={() => setSelectedLog(null)}>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                {React.createElement(getTypeIcon(selectedLog.type), { className: "w-5 h-5" })}
                Emergency Event Details
              </DialogTitle>
              <DialogDescription>
                Complete information about this emergency event
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <h4 className="font-medium mb-1">Event Type</h4>
                  <Badge className={getTypeColor(selectedLog.type)}>
                    {selectedLog.type.replace('_', ' ').toUpperCase()}
                  </Badge>
                </div>
                <div>
                  <h4 className="font-medium mb-1">Status</h4>
                  <Badge className={getResolutionColor(selectedLog.resolution)}>
                    {selectedLog.resolution.replace('_', ' ')}
                  </Badge>
                </div>
              </div>

              <Separator />

              <div>
                <h4 className="font-medium mb-2">Event Details</h4>
                <p className="text-sm text-muted-foreground mb-2">{selectedLog.description}</p>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="font-medium">Date:</span> {selectedLog.timestamp.toLocaleDateString()}
                  </div>
                  <div>
                    <span className="font-medium">Time:</span> {selectedLog.timestamp.toLocaleTimeString()}
                  </div>
                </div>
              </div>

              {selectedLog.location && (
                <>
                  <Separator />
                  <div>
                    <h4 className="font-medium mb-2">Location Information</h4>
                    <div className="space-y-2 text-sm">
                      {selectedLog.location.address && (
                        <div>
                          <span className="font-medium">Address:</span> {selectedLog.location.address}
                        </div>
                      )}
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <span className="font-medium">Latitude:</span> {selectedLog.location.latitude.toFixed(6)}
                        </div>
                        <div>
                          <span className="font-medium">Longitude:</span> {selectedLog.location.longitude.toFixed(6)}
                        </div>
                      </div>
                    </div>
                  </div>
                </>
              )}

              <Separator />

              <div>
                <h4 className="font-medium mb-2">Contacts Notified</h4>
                <div className="flex flex-wrap gap-2">
                  {selectedLog.contacts_notified.map((contact, index) => (
                    <Badge key={index} variant="secondary">
                      {contact}
                    </Badge>
                  ))}
                </div>
              </div>

              {selectedLog.notes && (
                <>
                  <Separator />
                  <div>
                    <h4 className="font-medium mb-2">Additional Notes</h4>
                    <p className="text-sm text-muted-foreground">{selectedLog.notes}</p>
                  </div>
                </>
              )}

              <div className="flex justify-end gap-2 pt-4">
                <Button variant="outline" onClick={() => setSelectedLog(null)}>
                  Close
                </Button>
                <Button onClick={exportLogs}>
                  <Download className="w-4 h-4 mr-2" />
                  Export This Event
                </Button>
              </div>
            </div>
          </DialogContent>
        </Dialog>
      )}
    </div>
  );
};

export default EmergencyLog;