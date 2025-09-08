import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';

const ONLINE_TILE_URL = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
const OFFLINE_TILE_URL = '/tiles/{z}/{x}/{y}.png'; // Place offline tiles in public/tiles/

const MapComponent: React.FC = () => {
  const [isOnline, setIsOnline] = useState(navigator.onLine);

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

  return (
    <MapContainer center={[20.5937, 78.9629]} zoom={5} style={{ height: '400px', width: '100%' }}>
      <TileLayer
        url={isOnline ? ONLINE_TILE_URL : OFFLINE_TILE_URL}
        attribution={isOnline ? '&copy; OpenStreetMap contributors' : 'Offline Tiles'}
      />
    </MapContainer>
  );
};

export default MapComponent;
