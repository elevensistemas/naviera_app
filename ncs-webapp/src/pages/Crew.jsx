import React, { useState, useEffect } from 'react';
import { Users, Search, Ship, AlertCircle, Loader } from 'lucide-react';
import { getApiEndpoint } from '../config';

const Crew = () => {
  const [ships, setShips] = useState([]);
  const [crewMembers, setCrewMembers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  const [activeTab, setActiveTab] = useState('');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    const fetchCrewAndShips = async () => {
      try {
        setLoading(true);
        setError(null);
        
        const token = localStorage.getItem('ncsToken');
        const headers = {
          'Content-Type': 'application/json'
        };
        if (token) {
          headers['Authorization'] = `Token ${token}`;
        }

        const [shipsRes, crewRes] = await Promise.all([
          fetch(getApiEndpoint('/api/v1/ships/'), { headers }),
          fetch(getApiEndpoint('/api/v1/crew-members/'), { headers })
        ]);

        if (!shipsRes.ok || !crewRes.ok) {
          throw new Error('Error al conectar con la API. Verifica tu sesión o conexión.');
        }

        const shipsData = await shipsRes.json();
        const crewData = await crewRes.json();

        // Filter active ships in database
        const activeShips = shipsData.filter(s => s.active);
        setShips(activeShips);
        setCrewMembers(crewData);

        // Select default tab
        if (activeShips.length > 0) {
          setActiveTab(activeShips[0].description);
        } else {
          setActiveTab('Sin Embarcar');
        }
      } catch (err) {
        console.error('Error fetching crew and ships:', err);
        setError(err.message || 'Error al cargar los datos de la tripulación.');
      } finally {
        setLoading(false);
      }
    };

    fetchCrewAndShips();
  }, []);

  const getShipTheme = (shipName) => {
    switch(shipName) {
      case 'ALFA C': return { border: '#0284c7', bg: 'rgba(2, 132, 199, 0.15)' }; // Azul
      case 'NANY': return { border: '#ea580c', bg: 'rgba(234, 88, 12, 0.15)' }; // Naranja
      case 'GUSTAVO U': return { border: '#64748B', bg: 'rgba(100, 116, 139, 0.15)' }; // Gris
      default: return { border: 'var(--ncs-accent)', bg: 'rgba(0, 240, 255, 0.1)' };
    }
  };

  // Group crew members dynamically by current ship description
  const groupedCrew = {};
  ships.forEach(s => {
    groupedCrew[s.description] = [];
  });
  groupedCrew['Sin Embarcar'] = [];

  crewMembers.forEach(member => {
    if (!member.is_active) return; // Skip inactive crew
    const shipDesc = member.current_ship_detail?.description;
    if (shipDesc && groupedCrew[shipDesc] !== undefined) {
      groupedCrew[shipDesc].push(member);
    } else {
      groupedCrew['Sin Embarcar'].push(member);
    }
  });

  // Sort crew members inside each group by order_index ascending
  Object.keys(groupedCrew).forEach(key => {
    groupedCrew[key].sort((a, b) => {
      const indexA = a.position_detail?.order_index ?? 999;
      const indexB = b.position_detail?.order_index ?? 999;
      return indexA - indexB;
    });
  });

  const getDaysOnBoard = (member) => {
    const sit = member.current_situation_detail;
    if (sit?.situation_type_detail?.is_on_board && sit.start_date) {
      const start = new Date(sit.start_date);
      const now = new Date();
      start.setHours(0, 0, 0, 0);
      now.setHours(0, 0, 0, 0);
      const diffTime = Math.max(0, now - start);
      return Math.floor(diffTime / (1000 * 60 * 60 * 24));
    }
    return null;
  };

  const tabs = [...ships.map(s => s.description), 'Sin Embarcar'];
  const theme = getShipTheme(activeTab);

  const currentCrew = groupedCrew[activeTab] || [];
  const filteredCrew = currentCrew.filter(member => {
    const nameMatch = member.name?.toLowerCase().includes(searchTerm.toLowerCase());
    const roleMatch = (member.position_detail?.short_name || member.position_detail?.name || '')
      .toLowerCase()
      .includes(searchTerm.toLowerCase());
    return nameMatch || roleMatch;
  });

  // Get picture URL using dynDNS host
  const getPictureUrl = (picPath) => {
    if (!picPath) return null;
    return `https://navieracruzdelsur.dyndns.org:6570/${picPath}`;
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '80vh', gap: '16px', color: 'var(--text-secondary)' }}>
        <Loader size={36} className="animate-spin" color="var(--ncs-accent)" />
        <span>Cargando tripulación...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '80vh', padding: '20px', textAlign: 'center', color: 'var(--text-secondary)' }}>
        <AlertCircle size={40} color="var(--ncs-danger)" style={{ marginBottom: '12px' }} />
        <h3 style={{ color: 'var(--text-primary)', marginBottom: '8px' }}>Error de conexión</h3>
        <p style={{ maxWidth: '400px', fontSize: '14px', marginBottom: '20px' }}>{error}</p>
        <button 
          onClick={() => window.location.reload()} 
          style={{ padding: '8px 16px', borderRadius: '8px', border: 'none', background: 'var(--ncs-primary)', color: '#fff', cursor: 'pointer', fontWeight: 'bold' }}
        >
          Reintentar
        </button>
      </div>
    );
  }

  return (
    <div style={{ minHeight: '100%', backgroundColor: 'var(--bg-secondary)', paddingBottom: '90px' }}>
      <div className="top-header glass" style={{ marginBottom: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
        <Users size={24} color="var(--ncs-accent)" />
        Tripulación
      </div>
      
      <div style={{ padding: '0 16px' }}>
        {/* Search Bar */}
        <div style={{ display: 'flex', alignItems: 'center', backgroundColor: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '12px', marginBottom: '20px' }}>
          <Search size={20} color="var(--text-secondary)" style={{ marginRight: '12px' }} />
          <input 
            type="text" 
            placeholder="Buscar marino o rango..." 
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            style={{ border: 'none', background: 'transparent', outline: 'none', color: 'var(--text-primary)', width: '100%', fontSize: '16px' }}
          />
        </div>

        {/* SHIP TABS */}
        <div style={{ display: 'flex', gap: '8px', overflowX: 'auto', marginBottom: '20px', paddingBottom: '8px', scrollbarWidth: 'none' }}>
          {tabs.map(ship => {
            const sTheme = getShipTheme(ship);
            return (
              <div 
                key={ship}
                onClick={() => { setActiveTab(ship); setSearchTerm(''); }}
                style={{
                  flex: '0 0 auto',
                  padding: '10px 20px',
                  borderRadius: '20px',
                  backgroundColor: activeTab === ship ? sTheme.border : 'rgba(255,255,255,0.05)',
                  color: activeTab === ship ? '#fff' : 'var(--text-secondary)',
                  fontWeight: activeTab === ship ? 'bold' : 'normal',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  transition: 'all 0.3s ease',
                  border: activeTab === ship ? 'none' : '1px solid var(--border-color)'
                }}
              >
                <Ship size={16} />
                {ship}
              </div>
            );
          })}
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px', padding: '0 4px' }}>
          <span style={{ fontSize: '14px', color: 'var(--text-secondary)', fontWeight: 'bold' }}>
            {activeTab === 'Sin Embarcar' ? 'FRANCOS Y LICENCIAS' : 'A BORDO'}
          </span>
          {activeTab !== 'Sin Embarcar' && (
            <span style={{ fontSize: '12px', color: 'var(--ncs-success)', backgroundColor: 'var(--ncs-success-glow)', padding: '4px 8px', borderRadius: '4px', fontWeight: 'bold' }}>
              Dotación mínima completa
            </span>
          )}
        </div>

        {/* Crew Cards List */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {filteredCrew.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-secondary)' }}>
              No se encontraron marineros para el filtro de búsqueda.
            </div>
          ) : (
            filteredCrew.map((member) => {
              const role = member.position_detail?.short_name?.trim() || member.position_detail?.name || 'S/D';
              const situation = member.current_situation_detail?.situation_type_detail?.name;
              const isOnBoard = member.current_situation_detail?.situation_type_detail?.is_on_board;
              const days = getDaysOnBoard(member);
              const picUrl = getPictureUrl(member.picture);

              return (
                <div key={member.id} className="card" style={{ 
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px', margin: '0',
                  borderLeft: `4px solid ${theme.border}`,
                  gap: '12px'
                }}>
                  
                  <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flex: '1 1 auto' }}>
                    {/* Profile Picture or Default Icon */}
                    <div style={{ 
                      width: '54px', 
                      height: '54px', 
                      borderRadius: '27px', 
                      backgroundColor: theme.bg, 
                      display: 'flex', 
                      justifyContent: 'center', 
                      alignItems: 'center', 
                      border: `1px solid ${theme.border}`,
                      overflow: 'hidden',
                      flexShrink: 0
                    }}>
                      {picUrl ? (
                        <img 
                          src={picUrl} 
                          alt={member.name} 
                          onError={(e) => { e.target.style.display = 'none'; }}
                          style={{ width: '100%', height: '100%', objectFit: 'cover' }} 
                        />
                      ) : (
                        <Users size={22} color={theme.border} />
                      )}
                    </div>
                    
                    <div>
                      <h4 style={{ margin: '0 0 6px 0', fontSize: '16px', color: 'var(--text-primary)', fontWeight: 'bold' }}>
                        {member.name}
                      </h4>
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', alignItems: 'center', marginBottom: '6px' }}>
                        <span style={{ fontSize: '11px', color: 'var(--text-primary)', backgroundColor: 'var(--surface-border)', padding: '2px 8px', borderRadius: '12px', fontWeight: 'bold', letterSpacing: '0.5px' }}>
                          {role}
                        </span>
                        {situation && (
                          <span style={{ 
                            fontSize: '11px', 
                            color: isOnBoard ? 'var(--ncs-success)' : 'var(--text-secondary)', 
                            backgroundColor: isOnBoard ? 'var(--ncs-success-glow)' : 'var(--surface-border)', 
                            padding: '2px 8px', 
                            borderRadius: '12px', 
                            fontWeight: 'bold',
                            border: isOnBoard ? '1px solid rgba(0, 255, 102, 0.2)' : 'none'
                          }}>
                            {situation}
                          </span>
                        )}
                      </div>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '2px', fontSize: '12px', color: 'var(--text-secondary)' }}>
                        {member.cuil ? <span><strong>CUIL:</strong> {member.cuil}</span> : null}
                        {member.email ? <span><strong>Email:</strong> {member.email}</span> : null}
                        {member.phone ? <span><strong>Teléfono:</strong> {member.phone}</span> : null}
                      </div>
                    </div>
                  </div>

                  {/* Days Circle if embarked */}
                  {isOnBoard && days !== null && (
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '4px', flexShrink: 0 }}>
                      <span style={{ fontSize: '10px', color: 'var(--text-secondary)' }}>DÍAS</span>
                      <div style={{ 
                        backgroundColor: days > 30 ? 'var(--ncs-danger)' : 'var(--surface-border)', 
                        color: days > 30 ? '#fff' : 'var(--text-primary)',
                        width: '36px', height: '36px', borderRadius: '18px', display: 'flex', justifyContent: 'center', alignItems: 'center',
                        fontWeight: 'bold', fontSize: '14px',
                        boxShadow: days > 30 ? '0 0 8px rgba(220,53,69,0.6)' : 'none',
                        transition: 'all 0.3s'
                      }}>
                        {days}
                      </div>
                    </div>
                  )}

                </div>
              );
            })
          )}
        </div>

      </div>
    </div>
  );
};

export default Crew;
