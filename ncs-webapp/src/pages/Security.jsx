import React, { useState, useEffect } from 'react';
import { ShieldAlert, Plus, X, CheckCircle, FileText, Calendar, Anchor, User } from 'lucide-react';
import { getApiEndpoint } from '../config';

const Security = () => {
  const [showModal, setShowModal] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  // Form Fields
  const [newVessel, setNewVessel] = useState('');
  const [newType, setNewType] = useState('unsafe_act');
  const [newCode, setNewCode] = useState('MG-21');
  const [newTitle, setNewTitle] = useState('');
  const [newDesc, setNewDesc] = useState('');

  // Lists from API
  const [ships, setShips] = useState([]);
  const [loadingShips, setLoadingShips] = useState(false);
  const [incidents, setIncidents] = useState([]);
  const [loadingIncidents, setLoadingIncidents] = useState(false);
  const [errorIncidents, setErrorIncidents] = useState('');

  // Fetch data
  const fetchShips = async () => {
    try {
      setLoadingShips(true);
      const token = localStorage.getItem('ncsToken');
      const headers = { 'Content-Type': 'application/json' };
      if (token) {
        headers['Authorization'] = `Token ${token}`;
      }
      const res = await fetch(getApiEndpoint('/api/v1/ships/'), { headers });
      if (res.ok) {
        const data = await res.json();
        setShips(data);
        if (data.length > 0) {
          setNewVessel(data[0].id.toString());
        }
      }
    } catch (err) {
      console.error('Error fetching ships:', err);
    } finally {
      setLoadingShips(false);
    }
  };

  const fetchIncidents = async () => {
    try {
      setLoadingIncidents(true);
      setErrorIncidents('');
      const token = localStorage.getItem('ncsToken');
      const headers = { 'Content-Type': 'application/json' };
      if (token) {
        headers['Authorization'] = `Token ${token}`;
      }
      const res = await fetch(getApiEndpoint('/api/v1/incidents/'), { headers });
      if (!res.ok) {
        throw new Error(`Error al cargar incidentes (HTTP ${res.status})`);
      }
      const data = await res.json();
      setIncidents(data);
    } catch (err) {
      console.error('Error fetching incidents:', err);
      setErrorIncidents(err.message || 'Error al conectar con la API de incidentes');
    } finally {
      setLoadingIncidents(false);
    }
  };

  useEffect(() => {
    fetchShips();
    fetchIncidents();
  }, []);

  const handleAddIncident = async (e) => {
    e.preventDefault();
    if (!newTitle || !newDesc || !newVessel) return;

    try {
      setSubmitting(true);
      const token = localStorage.getItem('ncsToken');
      const headers = { 
        'Content-Type': 'application/json'
      };
      if (token) {
        headers['Authorization'] = `Token ${token}`;
      }

      const payload = {
        code: newCode,
        vessel: parseInt(newVessel, 10),
        type: newType,
        title: newTitle,
        description: newDesc,
        date_time: new Date().toISOString()
      };

      const res = await fetch(getApiEndpoint('/api/v1/incidents/'), {
        method: 'POST',
        headers,
        body: JSON.stringify(payload)
      });

      if (!res.ok) {
        const errData = await res.json().catch(() => null);
        throw new Error(errData?.detail || 'Error al registrar el incidente en la API.');
      }

      setNewDesc('');
      setNewTitle('');
      setShowModal(false);
      setShowSuccess(true);
      
      // Reload incidents from server
      fetchIncidents();

      // Hide success banner after 4 seconds
      setTimeout(() => {
        setShowSuccess(false);
      }, 4000);
    } catch (err) {
      console.error(err);
      alert(err.message || 'Error de red al registrar el incidente.');
    } finally {
      setSubmitting(false);
    }
  };

  const getTypeName = (type) => {
    const types = {
      unsafe_act: 'Acto Inseguro',
      unsafe_condition: 'Condición Insegura',
      near_miss: 'Casi Accidente (Near Miss)',
      personal_accident: 'Accidente Personal',
      nautical_incident: 'Incidente Náutico'
    };
    return types[type] || type;
  };

  const getStateName = (state) => {
    const states = {
      process: 'En Proceso',
      review_captain: 'Revisión Capitán',
      review_ship: 'Revisión Barco',
      review_land: 'Revisión Tierra',
      closed: 'Cerrado'
    };
    return states[state] || state;
  };

  const getStateStyle = (state) => {
    const styles = {
      process: { bg: 'rgba(249, 115, 22, 0.2)', color: '#fdba74', border: 'rgba(249, 115, 22, 0.4)' },
      review_captain: { bg: 'rgba(59, 130, 246, 0.2)', color: '#93c5fd', border: 'rgba(59, 130, 246, 0.4)' },
      review_ship: { bg: 'rgba(168, 85, 247, 0.2)', color: '#d8b4fe', border: 'rgba(168, 85, 247, 0.4)' },
      review_land: { bg: 'rgba(6, 182, 212, 0.2)', color: '#67e8f9', border: 'rgba(6, 182, 212, 0.4)' },
      closed: { bg: 'rgba(34, 197, 94, 0.2)', color: '#4ade80', border: 'rgba(34, 197, 94, 0.4)' }
    };
    return styles[state] || { bg: 'rgba(255,255,255,0.1)', color: '#fff', border: 'rgba(255,255,255,0.2)' };
  };

  return (
    <div style={{ paddingBottom: '50px', minHeight: '100%' }}>
      <div className="top-header glass">Seguridad y Salvamento</div>

      {/* Success Toast */}
      {showSuccess && (
        <div style={{
          position: 'fixed',
          top: '80px',
          left: '50%',
          transform: 'translateX(-50%)',
          backgroundColor: 'rgba(34, 197, 94, 0.15)',
          border: '1px solid #22c55e',
          borderRadius: '12px',
          padding: '12px 24px',
          display: 'flex',
          alignItems: 'center',
          gap: '12px',
          color: '#4ade80',
          fontSize: '14px',
          fontWeight: '600',
          boxShadow: '0 10px 25px -5px rgba(34, 197, 94, 0.25)',
          backdropFilter: 'blur(8px)',
          zIndex: 10000
        }}>
          <CheckCircle size={18} />
          ¡Incidente reportado con éxito!
        </div>
      )}

      <div style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '24px' }}>
        
        {/* Banner principal */}
        <div className="card" style={{
          display: 'flex',
          flexDirection: 'row',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: '20px',
          background: 'linear-gradient(135deg, rgba(15, 23, 42, 0.8) 0%, rgba(30, 41, 59, 0.6) 100%)',
          border: '1px solid rgba(239, 68, 68, 0.2)'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flex: '1', minWidth: '280px' }}>
            <div style={{
              width: '56px',
              height: '56px',
              borderRadius: '50%',
              backgroundColor: 'rgba(239, 68, 68, 0.1)',
              border: '1px solid rgb(239, 68, 68)',
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              color: 'rgb(239, 68, 68)'
            }}>
              <ShieldAlert size={28} />
            </div>
            <div>
              <h2 style={{ fontSize: '18px', fontWeight: 'bold', color: 'var(--text-primary)', margin: '0 0 4px 0' }}>
                Control de Incidentes de Intranet
              </h2>
              <p style={{ color: 'var(--text-secondary)', fontSize: '13px', margin: 0 }}>
                Si detecta alguna novedad de seguridad o situación de riesgo, regístrela para revisión de superintendencia y capitanía.
              </p>
            </div>
          </div>
          
          <button 
            onClick={() => setShowModal(true)}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px',
              padding: '12px 24px',
              borderRadius: '10px',
              border: 'none',
              background: 'linear-gradient(135deg, #ef4444 0%, #b91c1c 100%)',
              color: '#ffffff',
              fontSize: '14px',
              fontWeight: 'bold',
              cursor: 'pointer',
              boxShadow: '0 4px 15px -3px rgba(239, 68, 68, 0.4)'
            }}
          >
            <Plus size={18} /> Reportar Incidente
          </button>
        </div>

        {/* Listado de Incidentes */}
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px' }}>
            <FileText size={20} color="var(--ncs-accent)" />
            <span style={{ fontSize: '18px', fontWeight: 'bold', color: 'var(--text-primary)' }}>Historial de Incidentes</span>
          </div>

          {loadingIncidents ? (
            <div style={{ textAlign: 'center', padding: '40px', color: 'var(--text-secondary)' }}>Cargando reportes de incidentes...</div>
          ) : errorIncidents ? (
            <div style={{ padding: '16px', borderRadius: '12px', backgroundColor: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.2)', color: 'var(--ncs-danger)', fontSize: '14px' }}>
              {errorIncidents}
            </div>
          ) : incidents.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '40px', color: 'var(--text-secondary)', border: '1px dashed rgba(255,255,255,0.1)', borderRadius: '12px' }}>
              No se han registrado reportes de seguridad en el sistema.
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {incidents.map(inc => {
                const stateStyle = getStateStyle(inc.state);
                return (
                  <div key={inc.id} className="card" style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '12px', borderLeft: `4px solid ${stateStyle.color}` }}>
                    
                    {/* Header: ID, Estado, Fecha */}
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '10px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ fontSize: '12px', color: 'var(--text-secondary)', fontWeight: 'bold' }}>
                          #{inc.incident_number || inc.id}
                        </span>
                        <span style={{ fontSize: '11px', color: 'var(--ncs-accent)', backgroundColor: 'rgba(0, 240, 255, 0.1)', padding: '2px 8px', borderRadius: '4px', fontWeight: 'bold' }}>
                          {inc.code}
                        </span>
                        <span style={{ 
                          fontSize: '11px', 
                          padding: '2px 8px', 
                          borderRadius: '4px', 
                          fontWeight: 'bold',
                          backgroundColor: stateStyle.bg,
                          color: stateStyle.color,
                          border: `1px solid ${stateStyle.border}`
                        }}>
                          {getStateName(inc.state)}
                        </span>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px', color: 'var(--text-secondary)' }}>
                        <Calendar size={14} />
                        {inc.created_at ? new Date(inc.created_at).toLocaleDateString('es-ES', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : 'N/D'}
                      </div>
                    </div>

                    {/* Title */}
                    <h3 style={{ fontSize: '16px', fontWeight: 'bold', color: 'var(--text-primary)', margin: '0' }}>
                      {inc.title}
                    </h3>

                    {/* Description */}
                    <p style={{ fontSize: '13.5px', color: 'var(--text-primary)', margin: '0', lineHeight: '1.5', opacity: 0.9 }}>
                      {inc.description}
                    </p>

                    {/* Footer: Vessel, Creator */}
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid rgba(255,255,255,0.05)', paddingTop: '10px', marginTop: '4px', fontSize: '12px', color: 'var(--text-secondary)' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <Anchor size={14} color="var(--ncs-accent)" />
                        <span>Barco: <strong>{inc.vessel_detail?.description || `Embarcación #${inc.vessel}`}</strong></span>
                      </div>

                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <User size={14} />
                        <span>Reportó: <strong>{inc.created_by_detail?.first_name ? `${inc.created_by_detail.first_name} ${inc.created_by_detail.last_name || ''}` : (inc.created_by_detail?.username || 'Sistema')}</strong></span>
                      </div>
                    </div>

                  </div>
                );
              })}
            </div>
          )}
        </div>

      </div>

      {/* Incident Reporting Modal */}
      {showModal && (
        <div style={{
          position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh',
          backgroundColor: 'rgba(0,0,0,0.85)', backdropFilter: 'blur(8px)', zIndex: 9999,
          display: 'flex', justifyContent: 'center', alignItems: 'center', padding: '16px'
        }}>
          <div className="card" style={{
            width: '100%', maxWidth: '420px', padding: '24px', backgroundColor: 'var(--bg-secondary)',
            border: '1px solid rgba(0, 240, 255, 0.2)', position: 'relative', margin: 0
          }}>
            <button 
              onClick={() => setShowModal(false)}
              style={{
                position: 'absolute', top: '16px', right: '16px', border: 'none',
                background: 'transparent', color: 'var(--text-secondary)', cursor: 'pointer',
                outline: 'none'
              }}
            >
              <X size={20} />
            </button>

            <h3 style={{ fontSize: '18px', fontWeight: 'bold', marginBottom: '18px', fontFamily: 'Space Grotesk', color: 'var(--ncs-accent)' }}>
              Reportar Novedad de Seguridad
            </h3>

            <form onSubmit={handleAddIncident} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '6px' }}>Embarcación</label>
                <select 
                  className="input-field" 
                  style={{ padding: '10px' }}
                  value={newVessel}
                  onChange={(e) => setNewVessel(e.target.value)}
                  disabled={loadingShips}
                  required
                >
                  {loadingShips && <option value="">Cargando barcos...</option>}
                  {!loadingShips && ships.length === 0 && (
                    <>
                      <option value="">No hay barcos disponibles</option>
                    </>
                  )}
                  {ships.map(ship => (
                    <option key={ship.id} value={ship.id.toString()}>
                      {ship.description}
                    </option>
                  ))}
                </select>
              </div>

              <div style={{ display: 'flex', gap: '12px' }}>
                <div style={{ flex: 1 }}>
                  <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '6px' }}>Código Reporte</label>
                  <select 
                    className="input-field" 
                    style={{ padding: '10px' }}
                    value={newCode}
                    onChange={(e) => setNewCode(e.target.value)}
                  >
                    <option value="MG-21">MG-21</option>
                    <option value="MG-06">MG-06</option>
                    <option value="MG-07">MG-07</option>
                  </select>
                </div>

                <div style={{ flex: 1.5 }}>
                  <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '6px' }}>Tipo de Incidente</label>
                  <select 
                    className="input-field" 
                    style={{ padding: '10px' }}
                    value={newType}
                    onChange={(e) => setNewType(e.target.value)}
                  >
                    <option value="unsafe_act">Acto Inseguro</option>
                    <option value="unsafe_condition">Condición Insegura</option>
                    <option value="near_miss">Casi Accidente</option>
                    <option value="personal_accident">Accidente Personal</option>
                    <option value="nautical_incident">Incidente Náutico</option>
                  </select>
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '6px' }}>Título Breve</label>
                <input 
                  type="text" 
                  className="input-field" 
                  style={{ padding: '10px' }}
                  placeholder="Ej: Falla en equipo de extinción"
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  required
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '6px' }}>Descripción de los Hechos</label>
                <textarea 
                  className="input-field" 
                  rows="3"
                  style={{ padding: '10px', resize: 'none', fontFamily: 'inherit' }}
                  placeholder="Detalle los hechos o novedades del incidente..."
                  value={newDesc}
                  onChange={(e) => setNewDesc(e.target.value)}
                  required
                />
              </div>

              <button 
                type="submit" 
                className="btn-primary" 
                style={{ marginTop: '8px', padding: '12px' }}
                disabled={submitting}
              >
                {submitting ? 'Enviando...' : 'Enviar Reporte'}
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Security;
