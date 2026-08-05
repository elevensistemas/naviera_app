import React, { useState, useEffect } from 'react';
import { Ship, Bell, Calendar, User as UserIcon, Loader, AlertCircle } from 'lucide-react';
import { getApiEndpoint, API_BASE } from '../config';

const Home = () => {
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const resolveMediaUrl = (url) => {
    if (!url) return '';
    if (url.startsWith('http')) return url;
    const baseUrl = API_BASE ? API_BASE.replace(/\/$/, '') : 'https://navieracruzdelsur.dyndns.org:6570';
    return `${baseUrl}${url}`;
  };

  const fetchAnnouncements = async () => {
    try {
      setLoading(true);
      setError(null);
      const token = localStorage.getItem('ncsToken');
      const headers = { 'Content-Type': 'application/json' };
      if (token) {
        headers['Authorization'] = `Token ${token}`;
      }

      // Fetch announcements from Swagger API
      const res = await fetch(getApiEndpoint('/api/v1/announcements/?active=true'), {
        headers
      });

      if (!res.ok) {
        throw new Error('No se pudieron recuperar las novedades de la intranet.');
      }

      const data = await res.json();
      setPosts(data || []);
    } catch (err) {
      console.error('Error fetching announcements:', err);
      setError(err.message || 'Error al conectar con la intranet.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAnnouncements();
  }, []);

  const formatAnnouncementDate = (isoString) => {
    if (!isoString) return '';
    try {
      const date = new Date(isoString);
      return date.toLocaleDateString([], { day: 'numeric', month: 'short', year: 'numeric' });
    } catch (e) {
      return '';
    }
  };

  const getImportancePill = (importance) => {
    switch (importance) {
      case 3:
        return { text: 'Urgente', bg: 'rgba(239, 68, 68, 0.2)', border: '1px solid var(--ncs-secondary)', color: '#ff4d4d' };
      case 2:
        return { text: 'Importante', bg: 'rgba(234, 88, 12, 0.2)', border: '1px solid var(--ncs-warning)', color: '#f97316' };
      case 1:
        return { text: 'Novedad', bg: 'rgba(0, 240, 255, 0.2)', border: '1px solid var(--ncs-accent)', color: 'var(--ncs-accent)' };
      default:
        return { text: 'Comunicado', bg: 'rgba(255, 255, 255, 0.05)', border: '1px solid var(--border-color)', color: 'var(--text-secondary)' };
    }
  };

  const getInitials = (userObj) => {
    if (!userObj) return 'NCS';
    const first = userObj.first_name || '';
    const last = userObj.last_name || '';
    if (first && last) {
      return `${first.charAt(0)}${last.charAt(0)}`.toUpperCase();
    }
    return (userObj.username || 'NCS').slice(0, 3).toUpperCase();
  };

  return (
    <div style={{ minHeight: '100vh', backgroundColor: 'var(--bg-secondary)', paddingBottom: '90px', position: 'relative' }}>
      {/* Background Watermark */}
      <div style={{ position: 'fixed', right: '-10%', bottom: '10%', opacity: 0.03, zIndex: 0, pointerEvents: 'none' }}>
        <Ship size={360} color="var(--ncs-accent)" strokeWidth={1} />
      </div>

      <div className="top-header glass" style={{ padding: 'calc(20px + var(--safe-area-top)) 20px 20px' }}>
        Portal Corporativo
      </div>

      <div style={{ position: 'relative', zIndex: 1, padding: '16px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {loading ? (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', marginTop: '100px', gap: '16px', color: 'var(--text-secondary)' }}>
            <Loader size={36} className="animate-spin" color="var(--ncs-accent)" />
            <span>Cargando comunicados...</span>
          </div>
        ) : error ? (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', marginTop: '100px', padding: '20px', textAlign: 'center', color: 'var(--text-secondary)' }}>
            <AlertCircle size={40} color="var(--ncs-danger)" style={{ marginBottom: '12px' }} />
            <h3 style={{ color: 'var(--text-primary)', marginBottom: '8px' }}>Error al cargar novedades</h3>
            <p style={{ maxWidth: '400px', fontSize: '14px', marginBottom: '20px' }}>{error}</p>
            <button 
              onClick={fetchAnnouncements} 
              style={{ padding: '8px 16px', borderRadius: '8px', border: 'none', background: 'var(--ncs-accent)', color: '#000', cursor: 'pointer', fontWeight: 'bold' }}
            >
              Reintentar
            </button>
          </div>
        ) : posts.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '80px 20px', color: 'var(--text-secondary)' }}>
            No hay comunicados ni novedades activas en este momento.
          </div>
        ) : (
          posts.map(post => {
            const pill = getImportancePill(post.importance);
            const authorName = post.user_detail 
              ? `${post.user_detail.first_name || ''} ${post.user_detail.last_name || ''}`.trim() || post.user_detail.username 
              : 'Administrador';

            return (
              <div 
                key={post.id} 
                className="card" 
                style={{ 
                  margin: '0', 
                  borderLeft: post.importance >= 2 ? `4px solid ${pill.color}` : '1px solid rgba(0, 240, 255, 0.15)',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '12px',
                  padding: '20px'
                }}
              >
                {/* Meta Header */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ 
                    fontSize: '11px', 
                    textTransform: 'uppercase', 
                    letterSpacing: '1px', 
                    fontWeight: 'bold', 
                    padding: '4px 10px', 
                    borderRadius: '8px', 
                    backgroundColor: pill.bg, 
                    border: pill.border,
                    color: pill.color 
                  }}>
                    {pill.text}
                  </span>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', color: 'var(--text-secondary)' }}>
                    <Calendar size={14} />
                    <span>{formatAnnouncementDate(post.starts_at)}</span>
                  </div>
                </div>

                {/* Announcement Title */}
                {post.title && (
                  <h3 style={{ fontSize: '18px', fontWeight: 'bold', color: 'var(--text-primary)', margin: '0' }}>
                    {post.title}
                  </h3>
                )}

                {/* Announcement Image if exists */}
                {post.image && (
                  <div style={{ width: '100%', borderRadius: '10px', overflow: 'hidden', border: '1px solid var(--border-color)', margin: '4px 0' }}>
                    <img 
                      src={resolveMediaUrl(post.image)} 
                      alt={post.title || "Novedad"} 
                      style={{ width: '100%', maxHeight: '250px', objectFit: 'cover', display: 'block' }} 
                    />
                  </div>
                )}

                {/* Description Content */}
                {post.description && (
                  <p style={{ 
                    fontSize: '14px', 
                    lineHeight: '1.6', 
                    color: 'var(--text-primary)', 
                    margin: '0',
                    whiteSpace: 'pre-wrap'
                  }}>
                    {post.description}
                  </p>
                )}

                {/* Footer Author info */}
                <div style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: '10px', 
                  marginTop: '6px', 
                  paddingTop: '12px', 
                  borderTop: '1px solid rgba(255,255,255,0.06)' 
                }}>
                  <div style={{ 
                    width: '32px', 
                    height: '32px', 
                    borderRadius: '16px', 
                    backgroundColor: 'rgba(0, 240, 255, 0.1)', 
                    border: '1px solid rgba(0, 240, 255, 0.2)',
                    display: 'flex', 
                    justifyContent: 'center', 
                    alignItems: 'center' 
                  }}>
                    <span style={{ fontSize: '11px', color: 'var(--ncs-accent)', fontWeight: 'bold' }}>
                      {getInitials(post.user_detail)}
                    </span>
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column' }}>
                    <span style={{ fontSize: '13px', color: 'var(--text-primary)', fontWeight: '600' }}>
                      {authorName}
                    </span>
                    <span style={{ fontSize: '10px', color: 'var(--text-secondary)' }}>
                      Emisor Autorizado
                    </span>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};

export default Home;
