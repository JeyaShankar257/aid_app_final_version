import React, { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Navigation, AlertTriangle, Zap } from 'lucide-react';

interface LocationMapProps {
  className?: string;
}

const ONLINE_TILE_URL = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
const OFFLINE_TILE_URL = '/tiles/{z}/{x}/{y}.png'; // Place offline tiles in public/tiles/

const LocationMap: React.FC<LocationMapProps> = ({ className = '' }) => {
  const mapContainer = useRef<HTMLDivElement>(null);
  const map = useRef<L.Map | null>(null);
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number } | null>(null);
  const [locationError, setLocationError] = useState<string | null>(null);
  const [isMapLoaded, setIsMapLoaded] = useState(false);
  const [isOnline, setIsOnline] = useState<boolean>(navigator.onLine);

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
    if (!mapContainer.current) return;
    if (map.current) {
      map.current.remove();
      map.current = null;
    }
    delete (L.Icon.Default.prototype as any)._getIconUrl;
    L.Icon.Default.mergeOptions({
      iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
      iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
      shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
    });
    map.current = L.map(mapContainer.current).setView([40.7128, -74.0060], 15);
    L.tileLayer(isOnline ? ONLINE_TILE_URL : OFFLINE_TILE_URL, {
      attribution: isOnline
        ? '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        : 'Offline Tiles',
      maxZoom: 19,
    }).addTo(map.current);
    setIsMapLoaded(true);
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude } = position.coords;
          const newLocation = { lat: latitude, lng: longitude };
          setUserLocation(newLocation);
          setLocationError(null);
          if (map.current) {
            map.current.setView([latitude, longitude], 16);
            const userIcon = L.divIcon({
              className: 'custom-div-icon',
              html: '<div class="w-4 h-4 bg-red-500 rounded-full border-2 border-white shadow-lg"></div>',
              iconSize: [16, 16],
              iconAnchor: [8, 8]
            });
            L.marker([latitude, longitude], { icon: userIcon })
              .addTo(map.current)
              .bindPopup('<div class="text-center"><strong>Your Location</strong><br/>Emergency services will be directed here</div>');
            const emergencyServices = [
              { name: 'General Hospital', coords: [latitude + 0.01, longitude + 0.005], type: 'hospital' },
              { name: 'Police Station', coords: [latitude - 0.008, longitude - 0.003], type: 'police' },
              { name: 'Fire Department', coords: [latitude + 0.005, longitude - 0.008], type: 'fire' }
            ];
            emergencyServices.forEach(service => {
              const color = service.type === 'hospital' ? 'green' : service.type === 'police' ? 'blue' : 'orange';
              const serviceIcon = L.divIcon({
                className: 'custom-div-icon',
                html: `<div class="w-3 h-3 bg-${color}-500 rounded-full border border-white shadow-md"></div>`,
                iconSize: [12, 12],
                iconAnchor: [6, 6]
              });
              L.marker([service.coords[0], service.coords[1]], { icon: serviceIcon })
                .addTo(map.current!)
                .bindPopup(`<div class="text-center"><strong>${service.name}</strong></div>`);
            });
          }
        },
        (error) => {
          console.error('Error getting location:', error);
          setLocationError('Unable to get your location. Please enable location services.');
        }
      );
    } else {
      setLocationError('Geolocation is not supported by your browser.');
    }
    return () => {
      if (map.current) {
        map.current.remove();
        map.current = null;
      }
    };
  }, [isOnline]);

  return (
    <Card className={`border-0 shadow-sm bg-card/50 backdrop-blur-sm h-full ${className}`}>
      <CardHeader className="pb-2">
        <CardTitle className="flex items-center gap-2">
          <Navigation className="w-5 h-5 text-emergency" />
          Emergency Location & Services
          <div className="flex items-center gap-1 text-xs bg-green-100 text-green-700 px-2 py-1 rounded-full">
            <Zap className="w-3 h-3" />
            Open Source Map
          </div>
        </CardTitle>
        <div className="mt-1 text-xs">
          <strong>Status:</strong> {isOnline ? 'Online' : 'Offline'}
        </div>
        {userLocation && (
          <CardDescription>
            Current Location: {userLocation.lat.toFixed(6)}, {userLocation.lng.toFixed(6)}
          </CardDescription>
        )}
        {locationError && (
          <div className="flex items-center gap-2 text-emergency text-sm">
            <AlertTriangle className="w-4 h-4" />
            {locationError}
          </div>
        )}
      </CardHeader>
      <CardContent className="h-[calc(100%-5rem)]">
        <div className="relative h-full">
          <div ref={mapContainer} className="h-full w-full rounded-lg shadow-md" />
          {/* Legend for safe places - moved outside map container */}
          <div className="absolute bottom-2 left-2 bg-black/80 text-white text-xs px-3 py-2 rounded flex flex-col gap-1 shadow-lg pointer-events-none">
            <div className="flex items-center gap-2">
              <span className="inline-block w-3 h-3 rounded-full bg-red-500 border border-white"></span>
              <span>Your Location</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="inline-block w-3 h-3 rounded-full bg-green-500 border border-white"></span>
              <span>Hospital</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="inline-block w-3 h-3 rounded-full bg-blue-500 border border-white"></span>
              <span>Police Station</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="inline-block w-3 h-3 rounded-full bg-orange-500 border border-white"></span>
              <span>Fire Department</span>
            </div>
          </div>
          <div className="absolute bottom-2 right-2 bg-black/80 text-white text-xs px-2 py-1 rounded">
            Powered by {isOnline ? 'OpenStreetMap' : 'Offline Tiles'}
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default LocationMap;
