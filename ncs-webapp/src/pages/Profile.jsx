import React, { useContext, useState, useEffect } from 'react';
import AuthContext from '../context/AuthContext';
import { User, LogOut, Sun, Moon, Briefcase, Mail, Shield, ShieldCheck, Loader, AlertCircle } from 'lucide-react';
import { getApiEndpoint } from '../config';

const Profile = () => {
  const { logout } = useContext(AuthContext);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [theme, setTheme] = useState('dark');

  useEffect(() => {
    const savedTheme = localStorage.getItem('ncs-theme') || 'dark';
    setTheme(savedTheme);
    fetchProfileData();
  }, []);

  const fetchProfileData = async () => {
    try {
      setLoading(true);
      setError(null);
      const token = localStorage.getItem('ncsToken');
      const headers = { 'Content-Type': 'application/json' };
      if (token) {
        headers['Authorization'] = `Token ${token}`;
      }

      const res = await fetch(getApiEndpoint('/api/v1/profile/'), {
        method: 'GET',
        headers
      });

      if (!res.ok) {
        throw new Error(`Error al cargar el perfil (HTTP ${res.status})`);
      }

      const data = await res.json();
      setProfile(data);
    } catch (err) {
      console.error('Error fetching profile:', err);
      setError(err.message || 'Error al conectar con la API de perfil.');
    } finally {
      setLoading(false);
    }
  };

  const toggleTheme = () => {
    const newTheme = theme === 'dark' ? 'light' : 'dark';
    setTheme(newTheme);
    localStorage.setItem('ncs-theme', newTheme);
    document.documentElement.setAttribute('data-theme', newTheme);
  };

  const getAvatarUrl = (profileImg) => {
    if (!profileImg) return null;
    if (profileImg.startsWith('http')) return profileImg;
    return `https://navieracruzdelsur.dyndns.org:6570${profileImg}`;
  };

  const getSindicatoText = (num) => {
    const sindicatos = {
      0: 'Sin afiliar',
      1: 'SOMU (Marineros)',
      2: 'Centro de Jefes y Oficiales de Maquinarias',
      3: 'Sindicato de Conductores Navales',
      4: 'Centro de Patrones y Oficiales Fluviales'
    };
    return sindicatos[num] || 'S/D';
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '80vh', gap: '16px', color: 'var(--text-secondary)' }}>
        <Loader size={36} className="animate-spin" color="var(--ncs-accent)" />
        <span>Cargando perfil...</span>
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
          onClick={fetchProfileData} 
          style={{ padding: '8px 16px', borderRadius: '8px', border: 'none', background: 'var(--ncs-primary)', color: '#fff', cursor: 'pointer', fontWeight: 'bold' }}
        >
          Reintentar
        </button>
      </div>
    );
  }

  const name = profile ? `${profile.first_name || ''} ${profile.last_name || ''}`.trim() || profile.username : '';
  const avatarUrl = profile ? getAvatarUrl(profile.profile_image) : null;
  const isSuper = profile?.is_superuser || profile?.is_staff;

  return (
    <div style={{ minHeight: '100%', backgroundColor: 'var(--bg-secondary)', paddingBottom: '90px' }}>
      <div className="top-header glass">Mi Perfil</div>
      
      {/* Targeta de usuario */}
      <div style={{ padding: '24px 16px', display: 'flex', alignItems: 'center', gap: '20px', backgroundColor: 'var(--bg-color)', borderBottom: '1px solid var(--border-color)', marginBottom: '20px' }}>
        <div style={{ 
          width: '74px', 
          height: '74px', 
          borderRadius: '37px', 
          backgroundColor: 'var(--ncs-primary)', 
          display: 'flex', 
          justifyContent: 'center', 
          alignItems: 'center', 
          color: 'white',
          border: '2px solid var(--ncs-accent)',
          overflow: 'hidden'
        }}>
          {avatarUrl ? (
            <img 
              src={avatarUrl} 
              alt={name} 
              onError={(e) => { e.target.style.display = 'none'; }}
              style={{ width: '100%', height: '100%', objectFit: 'cover' }} 
            />
          ) : (
            <User size={38} />
          )}
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', flex: 1 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '20px', fontWeight: 'bold', color: 'var(--text-primary)' }}>{name}</span>
            {isSuper && <ShieldCheck size={18} color="var(--ncs-accent)" />}
          </div>
          <span style={{ fontSize: '13px', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '4px' }}>
            <Mail size={12} /> {profile?.email || 'Sin correo registrado'}
          </span>
          <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
            <strong>Usuario:</strong> {profile?.username}
          </span>
        </div>
      </div>

      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: '20px' }}>
        
        {/* Grupos y Roles */}
        {profile?.groups && profile.groups.length > 0 && (
          <div className="card" style={{ padding: '16px', margin: '0' }}>
            <h4 style={{ margin: '0 0 12px 0', fontSize: '14px', color: 'var(--text-secondary)', fontWeight: 'bold', letterSpacing: '0.5px' }}>GRUPOS / SECTORES AUTORIZADOS</h4>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
              {profile.groups.map((g, idx) => (
                <span key={idx} style={{ 
                  fontSize: '11px', 
                  backgroundColor: 'rgba(0, 240, 255, 0.08)', 
                  border: '1px solid rgba(0, 240, 255, 0.2)',
                  color: 'var(--ncs-accent)', 
                  padding: '4px 10px', 
                  borderRadius: '12px', 
                  fontWeight: 'bold',
                  textTransform: 'uppercase'
                }}>
                  {g}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Linked Crew Member Details */}
        {profile?.crew_member && (
          <div className="card" style={{ padding: '16px', margin: '0', display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <h4 style={{ margin: '0', fontSize: '14px', color: 'var(--text-secondary)', fontWeight: 'bold', letterSpacing: '0.5px' }}>INFORMACIÓN DE ENROLAMIENTO</h4>
            
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', fontSize: '13px', color: 'var(--text-primary)' }}>
              <div>
                <span style={{ display: 'block', color: 'var(--text-secondary)', fontSize: '11px', marginBottom: '2px' }}>Puesto / Rango</span>
                <strong>{profile.crew_member.position_detail?.name || 'S/D'}</strong>
              </div>
              <div>
                <span style={{ display: 'block', color: 'var(--text-secondary)', fontSize: '11px', marginBottom: '2px' }}>CUIL</span>
                <strong>{profile.crew_member.cuil || 'S/D'}</strong>
              </div>
              <div>
                <span style={{ display: 'block', color: 'var(--text-secondary)', fontSize: '11px', marginBottom: '2px' }}>DNI</span>
                <strong>{profile.crew_member.dni || 'S/D'}</strong>
              </div>
              <div>
                <span style={{ display: 'block', color: 'var(--text-secondary)', fontSize: '11px', marginBottom: '2px' }}>Nacionalidad</span>
                <strong>{profile.crew_member.nationality || 'S/D'}</strong>
              </div>
              <div style={{ gridColumn: 'span 2' }}>
                <span style={{ display: 'block', color: 'var(--text-secondary)', fontSize: '11px', marginBottom: '2px' }}>Domicilio</span>
                <strong>{profile.crew_member.living_place || 'S/D'}</strong>
              </div>
              <div>
                <span style={{ display: 'block', color: 'var(--text-secondary)', fontSize: '11px', marginBottom: '2px' }}>Talle Uniforme</span>
                <strong>Talle {profile.crew_member.clothes_size || 'S/D'}</strong>
              </div>
              <div>
                <span style={{ display: 'block', color: 'var(--text-secondary)', fontSize: '11px', marginBottom: '2px' }}>Calzado</span>
                <strong>Nro {profile.crew_member.shoes_size || 'S/D'}</strong>
              </div>
              <div style={{ gridColumn: 'span 2' }}>
                <span style={{ display: 'block', color: 'var(--text-secondary)', fontSize: '11px', marginBottom: '2px' }}>Sindicato / Afiliación</span>
                <strong>{getSindicatoText(profile.crew_member.sindicato)}</strong>
              </div>
              {profile.crew_member.comments && (
                <div style={{ gridColumn: 'span 2' }}>
                  <span style={{ display: 'block', color: 'var(--text-secondary)', fontSize: '11px', marginBottom: '2px' }}>Observaciones</span>
                  <p style={{ margin: '0', fontSize: '12px', color: 'var(--text-secondary)', lineHeight: '1.4' }}>{profile.crew_member.comments}</p>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Menu opciones */}
        <div style={{ display: 'flex', flexDirection: 'column', borderRadius: '12px', overflow: 'hidden', border: '1px solid var(--border-color)' }}>
          
          <div 
            onClick={toggleTheme}
            style={{ display: 'flex', alignItems: 'center', gap: '16px', padding: '16px', backgroundColor: 'var(--bg-color)', borderBottom: '1px solid var(--border-color)', cursor: 'pointer', transition: 'background-color 0.2s' }}
            onMouseEnter={(e) => e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.02)'}
            onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'var(--bg-color)'}
          >
            {theme === 'dark' ? <Sun size={18} color="var(--text-primary)" /> : <Moon size={18} color="var(--text-primary)" />}
            <span style={{ fontSize: '15px', color: 'var(--text-primary)', flex: 1, fontWeight: 'bold' }}>
              {theme === 'dark' ? 'Cambiar a Modo Claro' : 'Cambiar a Modo Oscuro'}
            </span>
            <span style={{ color: 'var(--text-secondary)' }}>›</span>
          </div>

          <div 
            onClick={logout}
            style={{ display: 'flex', alignItems: 'center', gap: '16px', padding: '16px', backgroundColor: 'var(--bg-color)', cursor: 'pointer', transition: 'background-color 0.2s' }}
            onMouseEnter={(e) => e.currentTarget.style.backgroundColor = 'rgba(239, 68, 68, 0.05)'}
            onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'var(--bg-color)'}
          >
            <LogOut size={18} color="var(--ncs-danger)" />
            <span style={{ fontSize: '15px', color: 'var(--ncs-danger)', flex: 1, fontWeight: 'bold' }}>Cerrar Sesión</span>
            <span style={{ color: 'var(--ncs-danger)' }}>›</span>
          </div>

        </div>

      </div>
    </div>
  );
};

export default Profile;
