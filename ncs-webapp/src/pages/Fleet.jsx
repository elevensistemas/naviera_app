import React, { useState, useEffect, useRef } from 'react';
import { Camera, Anchor, Video, ShieldAlert, Loader, AlertCircle } from 'lucide-react';
import Hls from 'hls.js';
import { getApiEndpoint } from '../config';

const HlsVideo = ({ url }) => {
  const videoRef = useRef(null);
  const [errorDetails, setErrorDetails] = useState('');

  useEffect(() => {
    let hls;
    setErrorDetails('');
    const video = videoRef.current;
    
    if (Hls.isSupported() && url) {
      hls = new Hls({
        debug: false,
        enableWorker: true
      });
      hls.loadSource(url);
      hls.attachMedia(video);
      
      hls.on(Hls.Events.MANIFEST_PARSED, () => {
        video.play().catch(e => {
          console.warn("Autoplay prevenido por el navegador", e);
        });
      });

      hls.on(Hls.Events.ERROR, (event, data) => {
        if (data.fatal) {
          switch (data.type) {
            case Hls.ErrorTypes.NETWORK_ERROR:
              setErrorDetails('Error de red al cargar el streaming. (Probable bloqueo CORS de Ezviz)');
              hls.startLoad();
              break;
            case Hls.ErrorTypes.MEDIA_ERROR:
              setErrorDetails('Error de formato multimedia.');
              hls.recoverMediaError();
              break;
            default:
              setErrorDetails('Error irreparable en Hls.js');
              hls.destroy();
              break;
          }
        }
      });
    } else if (video && video.canPlayType('application/vnd.apple.mpegurl')) {
      video.src = url;
      video.addEventListener('loadedmetadata', () => {
        video.play().catch(e => console.warn("Autoplay prevenido", e));
      });
    }

    return () => {
      if (hls) {
        hls.destroy();
      }
    };
  }, [url]);

  return (
    <>
      <video 
        ref={videoRef} 
        controls 
        muted 
        autoPlay 
        playsInline
        style={{ width: '100%', height: '100%', position: 'absolute', top: 0, left: 0, backgroundColor: '#000' }}
      />
      <img 
        src="/logo.png" 
        alt="NCS Logo" 
        style={{ position: 'absolute', top: '15%', left: '16px', width: '50px', zIndex: 10, opacity: 0.5, filter: 'drop-shadow(0px 1px 2px rgba(0,0,0,0.5))' }} 
      />
      {errorDetails && (
        <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', color: 'var(--ncs-secondary)', backgroundColor: 'rgba(0,0,0,0.8)', padding: '10px 20px', borderRadius: '8px', zIndex: 20, textAlign: 'center', fontSize: '13px' }}>
          {errorDetails}
        </div>
      )}
    </>
  );
};

const Fleet = () => {
  // Cameras
  const [cameras, setCameras] = useState([]);
  const [selectedCamera, setSelectedCamera] = useState(null);
  const [videoLoading, setVideoLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  // Ships
  const [ships, setShips] = useState([]);
  const [shipsLoading, setShipsLoading] = useState(false);
  const [shipsError, setShipsError] = useState('');

  useEffect(() => {
    fetchFleetData();
  }, []);

  const fetchFleetData = async () => {
    try {
      setShipsLoading(true);
      setVideoLoading(true);
      setShipsError('');
      setErrorMsg('');
      
      const token = localStorage.getItem('ncsToken');
      const headers = { 'Content-Type': 'application/json' };
      if (token) {
        headers['Authorization'] = `Token ${token}`;
      }
      
      // Fetch /fleet-combo/
      const res = await fetch(getApiEndpoint('/api/v1/fleet-combo/'), {
        method: 'GET',
        headers
      });

      if (!res.ok) {
        if (res.status === 401 || res.status === 403) {
          throw new Error('No autorizado para ver la lista de barcos. Inicia sesión de nuevo.');
        }
        throw new Error(`Error del servidor (HTTP ${res.status})`);
      }

      const shipsData = await res.json();
      setShips(shipsData);

      // Get Ezviz Token
      const tokenRes = await fetch('/ezviz-api/api/lapp/token/get', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          appKey: import.meta.env.VITE_EZVIZ_APP_KEY || '',
          appSecret: import.meta.env.VITE_EZVIZ_APP_SECRET || ''
        })
      });
      
      const tokenData = await tokenRes.json();
      if (tokenData.code !== '200') throw new Error(tokenData.msg || 'Error obteniendo token de cámaras');
      const accessToken = tokenData.data.accessToken;
      
      // Extract authorized cameras from active ships
      const authorizedCams = [];
      shipsData.forEach(ship => {
        if (ship.cameras) {
          ship.cameras.forEach(cam => {
            if (cam.is_active && cam.serial_number) {
              authorizedCams.push({
                deviceSerial: cam.serial_number,
                channelName: cam.name,
                shipCode: ship.code,
                shipDesc: ship.description
              });
            }
          });
        }
      });

      if (authorizedCams.length === 0) {
        throw new Error('No se encontraron cámaras autorizadas en el sistema.');
      }

      // Fetch dynamic HLS streams
      const camsWithHls = await Promise.all(authorizedCams.map(async (cam) => {
        try {
          const addrRes = await fetch('/ezviz-api/api/lapp/v2/live/address/get', {
             method: 'POST',
             headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
             body: new URLSearchParams({ 
               accessToken, 
               deviceSerial: cam.deviceSerial, 
               channelNo: '1', 
               protocol: '2', 
               quality: '1' 
             })
          });
          const addrData = await addrRes.json();
          const hlsUrl = addrData.data?.url || (typeof addrData.data === 'string' ? addrData.data : '');
          
          return {
             deviceSerial: cam.deviceSerial,
             channelName: cam.channelName,
             hls: hlsUrl
          };
        } catch (e) {
          console.warn(`Error resolviendo cámara ${cam.deviceSerial}:`, e);
          return null;
        }
      }));

      const validCams = camsWithHls.filter(c => c && c.hls);
      setCameras(validCams);
      
      if (validCams.length > 0) {
        setSelectedCamera(validCams[0]);
      } else {
        throw new Error('Se detectaron las cámaras de la flota pero sus enlaces HLS no están activos.');
      }
      
    } catch (err) {
      console.error("Error cargando flota combo:", err);
      setShipsError(err.message || 'Error al conectar con la API de la Flota.');
      setErrorMsg(err.message || 'Error al inicializar las cámaras en vivo.');
    } finally {
      setShipsLoading(false);
      setVideoLoading(false);
    }
  };

  const findCameraForShip = (ship) => {
    return cameras.find(cam => {
      return ship.cameras?.some(c => c.serial_number === cam.deviceSerial);
    });
  };

  return (
    <div style={{ paddingBottom: '20px' }}>
      <div className="top-header glass">Flota y Operaciones</div>
      <div style={{ padding: '16px' }}>
        
        {/* Monitoreo en Vivo */}
        <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: '12px', padding: '0', overflow: 'hidden' }}>
          
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '16px 16px 0 16px' }}>
            <Video size={20} color="var(--ncs-accent)" />
            <span style={{ fontSize: '18px', fontWeight: 'bold' }}>Monitoreo Flota</span>
          </div>

          <div style={{ padding: '0 16px' }}>
            <select 
              className="input-field camera-select" 
              style={{ padding: '10px', fontSize: '14px', marginBottom: '10px' }}
              value={selectedCamera?.deviceSerial || ''}
              onChange={(e) => {
                const cam = cameras.find(c => c.deviceSerial === e.target.value);
                if (cam) setSelectedCamera(cam);
              }}
              disabled={videoLoading || cameras.length === 0}
            >
              {cameras.length === 0 && !errorMsg && <option value="">Buscando cámaras...</option>}
              {errorMsg && <option value="">Error de cámaras</option>}
              {cameras.map(cam => (
                <option key={cam.deviceSerial} value={cam.deviceSerial}>
                  {cam.channelName || `Cámara ${cam.deviceSerial}`}
                </option>
              ))}
            </select>
          </div>

          <div className="video-wrapper" style={{ width: '100%', minHeight: '300px', display: 'flex', flexDirection: 'column', position: 'relative' }}>
            {videoLoading ? (
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '40px 20px', gap: '10px' }}>
                <Loader className="animate-spin" size={24} color="var(--ncs-accent)" />
                <div style={{ color: 'var(--ncs-accent)', textShadow: '0 0 8px var(--ncs-accent-glow)', fontSize: '13px' }}>Conectando con Servidores Ezviz...</div>
              </div>
            ) : errorMsg ? (
              <div style={{ padding: '20px', color: 'var(--ncs-secondary)', textShadow: '0 0 8px var(--ncs-secondary-glow)', fontSize: '13px', textAlign: 'center' }}>
                <AlertCircle size={28} style={{ margin: '0 auto 8px auto', display: 'block' }} />
                {errorMsg}
              </div>
            ) : selectedCamera ? (
              <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column' }}>
                <div style={{ flex: 1, position: 'relative', minHeight: '250px' }}>
                  <HlsVideo url={selectedCamera.hls} />
                </div>
              </div>
            ) : (
              <div style={{ padding: '20px', color: '#FFF', fontSize: '12px', textAlign: 'center' }}>Cámaras no disponibles</div>
            )}
          </div>
        </div>

        {/* Ships grid layout */}
        <div style={{ marginTop: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px' }}>
            <Anchor size={20} color="var(--ncs-accent)" />
            <span style={{ fontSize: '18px', fontWeight: 'bold', color: 'var(--text-primary)' }}>Embarcaciones de la Intranet</span>
          </div>

          {shipsLoading ? (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '40px 20px', gap: '10px', color: 'var(--text-secondary)' }}>
              <Loader className="animate-spin" size={24} color="var(--ncs-accent)" />
              <span>Cargando barcos de la intranet...</span>
            </div>
          ) : shipsError ? (
            <div style={{ padding: '16px', borderRadius: '12px', backgroundColor: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.2)', color: 'var(--ncs-danger)', fontSize: '14px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
              <span>{shipsError}</span>
              <button className="btn-primary" onClick={fetchFleetData} style={{ padding: '8px 12px', fontSize: '12px', alignSelf: 'flex-start' }}>Reintentar</button>
            </div>
          ) : ships.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '20px', color: 'var(--text-secondary)' }}>No se encontraron barcos cargados en la intranet.</div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '16px' }}>
              {ships.map(ship => {
                const matchedCam = findCameraForShip(ship);
                return (
                  <div key={ship.id} className="card" style={{ padding: '0', overflow: 'hidden', display: 'flex', flexDirection: 'column', position: 'relative', border: '1px solid var(--border-color)' }}>
                    <div style={{ height: '6px', backgroundColor: ship.color || '#0284c7' }} />
                    
                    <div style={{ padding: '16px', flex: 1, display: 'flex', flexDirection: 'column', gap: '12px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                        <div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                            <span style={{ fontSize: '16px', fontWeight: 'bold', color: 'var(--text-primary)' }}>{ship.description}</span>
                          </div>
                          <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Cód: {ship.code}</span>
                        </div>
                        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '4px' }}>
                          <span style={{ 
                            fontSize: '11px', 
                            padding: '2px 8px', 
                            borderRadius: '12px', 
                            fontWeight: 'bold',
                            backgroundColor: ship.active ? 'rgba(34, 197, 94, 0.2)' : 'rgba(107, 114, 128, 0.2)',
                            color: ship.active ? '#4ade80' : '#9ca3af'
                          }}>
                            {ship.active ? 'Activo' : 'Inactivo'}
                          </span>
                          
                          <span style={{ 
                            fontSize: '11px', 
                            padding: '2px 8px', 
                            borderRadius: '12px', 
                            fontWeight: 'bold',
                            backgroundColor: ship.min_manning_ok ? 'rgba(34, 197, 94, 0.2)' : 'rgba(239, 68, 68, 0.2)',
                            color: ship.min_manning_ok ? '#4ade80' : '#f87171'
                          }}>
                            {ship.min_manning_ok ? 'Tripulación OK' : 'Falta Tripulación'}
                          </span>
                        </div>
                      </div>

                      <div style={{ fontSize: '13px', color: 'var(--text-primary)', display: 'flex', flexDirection: 'column', gap: '4px', backgroundColor: 'rgba(128, 128, 128, 0.05)', padding: '10px', borderRadius: '8px' }}>
                        <div><strong>IMO:</strong> {ship.imo || 'N/D'}</div>
                        <div><strong>Teléfono:</strong> {ship.phone || 'N/D'}</div>
                      </div>

                      {/* Nivel de Recursos */}
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginTop: '4px' }}>
                        <div style={{ fontSize: '12px', fontWeight: '600', color: 'var(--text-secondary)' }}>Nivel de Recursos:</div>
                        
                        <div>
                          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', color: 'var(--text-secondary)', marginBottom: '2px' }}>
                            <span>💧 Agua Dulce</span>
                            <span>{ship.total_water !== null && ship.total_water !== undefined ? `${ship.total_water} tn` : 'N/D'}</span>
                          </div>
                          <div style={{ width: '100%', height: '6px', backgroundColor: 'rgba(128, 128, 128, 0.1)', borderRadius: '3px', overflow: 'hidden' }}>
                            <div style={{ width: ship.total_water !== null && ship.total_water !== undefined ? `${Math.min(ship.total_water, 100)}%` : '0%', height: '100%', backgroundColor: '#38bdf8', borderRadius: '3px' }} />
                          </div>
                        </div>

                        <div>
                          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', color: 'var(--text-secondary)', marginBottom: '2px' }}>
                            <span>🪨 Carbón / Combustible</span>
                            <span>{ship.total_carbon !== null && ship.total_carbon !== undefined ? `${ship.total_carbon} tn` : 'N/D'}</span>
                          </div>
                          <div style={{ width: '100%', height: '6px', backgroundColor: 'rgba(128, 128, 128, 0.1)', borderRadius: '3px', overflow: 'hidden' }}>
                            <div style={{ width: ship.total_carbon !== null && ship.total_carbon !== undefined ? `${Math.min(ship.total_carbon, 100)}%` : '0%', height: '100%', backgroundColor: '#facc15', borderRadius: '3px' }} />
                          </div>
                        </div>

                        <div>
                          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', color: 'var(--text-secondary)', marginBottom: '2px' }}>
                            <span>🛢️ Slop / Residuos</span>
                            <span>{ship.total_slop !== null && ship.total_slop !== undefined ? `${ship.total_slop} tn` : 'N/D'}</span>
                          </div>
                          <div style={{ width: '100%', height: '6px', backgroundColor: 'rgba(128, 128, 128, 0.1)', borderRadius: '3px', overflow: 'hidden' }}>
                            <div style={{ width: ship.total_slop !== null && ship.total_slop !== undefined ? `${Math.min(ship.total_slop, 100)}%` : '0%', height: '100%', backgroundColor: '#f87171', borderRadius: '3px' }} />
                          </div>
                        </div>
                      </div>

                      {/* Inspecciones del Día */}
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', marginTop: '10px', backgroundColor: 'rgba(255,255,255,0.02)', padding: '10px', borderRadius: '8px', border: '1px solid rgba(255,255,255,0.05)' }}>
                        <div style={{ fontSize: '12px', fontWeight: 'bold', color: 'var(--text-secondary)', marginBottom: '4px' }}>Inspecciones del Día:</div>
                        {ship.inspections && ship.inspections.length > 0 ? (
                          ship.inspections.map((insp, idx) => (
                            <div key={idx} style={{ fontSize: '12px', color: 'var(--ncs-accent)', display: 'flex', justifyContent: 'space-between', gap: '10px' }}>
                              <span>📋 {insp.name || 'Inspección'}</span>
                              <span style={{ fontWeight: 'bold' }}>{insp.time || 'Hoy'}</span>
                            </div>
                          ))
                        ) : (
                          <div style={{ fontSize: '11px', color: 'var(--text-secondary)', fontStyle: 'italic' }}>No hay inspecciones programadas para hoy.</div>
                        )}
                      </div>

                      {matchedCam && (
                        <button 
                          onClick={() => {
                            setSelectedCamera(matchedCam);
                            window.scrollTo({ top: 0, behavior: 'smooth' });
                          }}
                          style={{
                            marginTop: '8px',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            gap: '6px',
                            padding: '10px 14px',
                            backgroundColor: 'rgba(2, 132, 199, 0.2)',
                            border: '1px solid rgba(2, 132, 199, 0.4)',
                            borderRadius: '10px',
                            color: '#38bdf8',
                            fontSize: '13px',
                            fontWeight: 'bold',
                            cursor: 'pointer',
                            transition: 'all 0.2s ease',
                            outline: 'none'
                          }}
                          onMouseEnter={(e) => {
                            e.currentTarget.style.backgroundColor = 'rgba(2, 132, 199, 0.4)';
                            e.currentTarget.style.borderColor = '#38bdf8';
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.backgroundColor = 'rgba(2, 132, 199, 0.2)';
                            e.currentTarget.style.borderColor = 'rgba(2, 132, 199, 0.4)';
                          }}
                        >
                          <Video size={16} />
                          Ver Cámara en Vivo
                        </button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

      </div>
    </div>
  );
};

export default Fleet;
