import React, { useState, useEffect, useContext } from 'react';
import { Outlet, NavLink, useLocation } from 'react-router-dom';
import { Home, Anchor, MessageSquare, User, Bell, Settings, Users, Calendar, Shield, Trash2, CheckSquare } from 'lucide-react';
import AuthContext from '../context/AuthContext';
import { getApiEndpoint } from '../config';

const Layout = () => {
  const location = useLocation();
  const { user } = useContext(AuthContext);
  const isDetailScreen = location.pathname.match(/\/chat\/.+/);

  const [notifications, setNotifications] = useState([]);
  const [showPanel, setShowPanel] = useState(false);

  const fetchNotifications = async () => {
    try {
      const token = localStorage.getItem('ncsToken');
      if (!token) return;
      const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Token ${token}`
      };
      const res = await fetch(getApiEndpoint('/api/v1/notifications/'), { headers });
      if (res.ok) {
        const data = await res.json();
        setNotifications(data.items || []);
      }
    } catch (err) {
      console.error('Error fetching notifications:', err);
    }
  };

  useEffect(() => {
    fetchNotifications();
    
    // Short polling for live intranet system notifications
    const interval = setInterval(fetchNotifications, 10000);
    return () => clearInterval(interval);
  }, []);

  const unreadNotifications = notifications.filter(n => !n.read);
  const unreadCount = unreadNotifications.length;

  const markAsRead = async (notificationId) => {
    try {
      const token = localStorage.getItem('ncsToken');
      if (!token) return;
      const headers = {
        'Authorization': `Token ${token}`
      };
      await fetch(getApiEndpoint(`/api/v1/notifications/${notificationId}/read/`), {
        method: 'POST',
        headers
      });
      
      // Update local state immediately
      setNotifications(prev => prev.map(n => n.id === notificationId ? { ...n, read: true } : n));
    } catch (err) {
      console.error('Error marking notification as read:', err);
    }
  };

  const markAllRead = async () => {
    try {
      const token = localStorage.getItem('ncsToken');
      if (!token) return;
      const headers = {
        'Authorization': `Token ${token}`
      };
      await fetch(getApiEndpoint('/api/v1/notifications/mark-all-read/'), {
        method: 'POST',
        headers
      });
      
      // Update local state
      setNotifications(prev => prev.map(n => ({ ...n, read: true })));
    } catch (err) {
      console.error('Error marking all notifications as read:', err);
    }
  };

  const clearAll = async () => {
    try {
      const token = localStorage.getItem('ncsToken');
      if (!token) return;
      const headers = {
        'Authorization': `Token ${token}`
      };
      await fetch(getApiEndpoint('/api/v1/notifications/clear/'), {
        method: 'POST',
        headers
      });
      
      // Clear state
      setNotifications([]);
    } catch (err) {
      console.error('Error clearing notifications:', err);
    }
  };

  const formatTimeAgo = (isoString) => {
    if (!isoString) return '';
    try {
      const date = new Date(isoString);
      const now = new Date();
      const diffMs = now - date;
      const diffMins = Math.floor(diffMs / 60000);
      if (diffMins < 1) return 'Hace instantes';
      if (diffMins < 60) return `Hace ${diffMins} min`;
      const diffHours = Math.floor(diffMins / 60);
      if (diffHours < 24) return `Hace ${diffHours} hr`;
      return date.toLocaleDateString([], { day: 'numeric', month: 'short' });
    } catch (e) {
      return '';
    }
  };

  return (
    <div className="app-container">
      {/* Floating Notification Button */}
      <div 
        onClick={() => setShowPanel(!showPanel)}
        className="floating-notification"
        style={{
          border: unreadCount > 0 ? '1px solid var(--ncs-secondary)' : '1px solid var(--ncs-accent)',
          boxShadow: unreadCount > 0 ? '0 4px 15px rgba(255, 0, 85, 0.4)' : '0 4px 15px rgba(0, 240, 255, 0.4)'
        }}
      >
        <Bell size={24} className="notification-icon" style={{ color: unreadCount > 0 ? 'var(--ncs-secondary)' : 'var(--ncs-accent)' }} />
        {unreadCount > 0 && (
          <div className="notification-badge">
            {unreadCount}
          </div>
        )}
      </div>

      {/* Floating Notifications Panel */}
      {showPanel && (
        <div 
          className="glass" 
          style={{
            position: 'fixed',
            top: 'calc(75px + var(--safe-area-top))',
            right: '20px',
            width: '320px',
            maxHeight: '400px',
            borderRadius: '16px',
            border: '1px solid var(--surface-border)',
            boxShadow: '0 10px 30px rgba(0,0,0,0.5)',
            zIndex: 10000,
            display: 'flex',
            flexDirection: 'column',
            overflow: 'hidden',
            backgroundColor: 'rgba(10, 15, 30, 0.95)'
          }}
        >
          {/* Header */}
          <div style={{ padding: '12px 16px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '14px', fontWeight: 'bold', color: 'var(--text-primary)' }}>
              Notificaciones
            </span>
            <div style={{ display: 'flex', gap: '8px' }}>
              {unreadCount > 0 && (
                <button 
                  onClick={markAllRead} 
                  title="Marcar todo como leído"
                  style={{ background: 'transparent', border: 'none', color: 'var(--ncs-accent)', cursor: 'pointer', display: 'flex', alignItems: 'center' }}
                >
                  <CheckSquare size={16} />
                </button>
              )}
              {notifications.length > 0 && (
                <button 
                  onClick={clearAll} 
                  title="Limpiar todo"
                  style={{ background: 'transparent', border: 'none', color: 'var(--ncs-secondary)', cursor: 'pointer', display: 'flex', alignItems: 'center' }}
                >
                  <Trash2 size={16} />
                </button>
              )}
            </div>
          </div>

          {/* List content */}
          <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column' }}>
            {notifications.length === 0 ? (
              <div style={{ padding: '40px 20px', textAlign: 'center', color: 'var(--text-secondary)', fontSize: '13px' }}>
                Sin notificaciones
              </div>
            ) : (
              notifications.map(noti => (
                <div 
                  key={noti.id}
                  onClick={() => !noti.read && markAsRead(noti.id)}
                  style={{
                    padding: '12px 16px',
                    borderBottom: '1px solid rgba(255,255,255,0.03)',
                    cursor: noti.read ? 'default' : 'pointer',
                    backgroundColor: noti.read ? 'transparent' : 'rgba(0, 240, 255, 0.03)',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '4px',
                    transition: 'background-color 0.2s'
                  }}
                  onMouseEnter={(e) => {
                    if (!noti.read) e.currentTarget.style.backgroundColor = 'rgba(0, 240, 255, 0.06)';
                  }}
                  onMouseLeave={(e) => {
                    if (!noti.read) e.currentTarget.style.backgroundColor = 'rgba(0, 240, 255, 0.03)';
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '8px' }}>
                    <span style={{ 
                      fontSize: '12.5px', 
                      fontWeight: 'bold', 
                      color: noti.read ? 'var(--text-primary)' : 'var(--ncs-accent)',
                      opacity: noti.read ? 0.8 : 1
                    }}>
                      {noti.titulo}
                    </span>
                    <span style={{ fontSize: '10px', color: 'var(--text-secondary)', whiteSpace: 'nowrap' }}>
                      {formatTimeAgo(noti.ts)}
                    </span>
                  </div>
                  <span style={{ fontSize: '12px', color: 'var(--text-secondary)', lineHeight: '1.4' }}>
                    {noti.mensaje}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>
      )}

      <div className="content-area">
        <Outlet />
      </div>
      
      {!isDetailScreen && (
        <nav className="bottom-nav glass">
          <NavLink to="/home" className={({isActive}) => `nav-item ${isActive ? 'active' : ''}`}>
            <Home size={24} />
            <span>Inicio</span>
          </NavLink>
          
          <NavLink to="/fleet" className={({isActive}) => `nav-item ${isActive ? 'active' : ''}`}>
            <Anchor size={24} />
            <span>Flota</span>
          </NavLink>

          <NavLink to="/monthly" className={({isActive}) => `nav-item ${isActive ? 'active' : ''}`}>
            <Calendar size={24} />
            <span>Programado</span>
          </NavLink>

          <NavLink to="/security" className={({isActive}) => `nav-item ${isActive ? 'active' : ''}`}>
            <Shield size={24} />
            <span>Seguridad</span>
          </NavLink>
          
          <NavLink to="/chat" className={({isActive}) => `nav-item ${isActive ? 'active' : ''}`}>
            <MessageSquare size={24} />
            <span>Chat</span>
          </NavLink>

          <NavLink to="/crew" className={({isActive}) => `nav-item ${isActive ? 'active' : ''}`}>
            <Users size={24} />
            <span>Tripulación</span>
          </NavLink>

          {/* 
          <NavLink to="/ai" className={({isActive}) => `nav-item ${isActive ? 'active' : ''}`}>
            <BotMessageSquare size={24} />
            <span>Asistente</span>
          </NavLink>
          */}
          
          <NavLink to="/profile" className={({isActive}) => `nav-item ${isActive ? 'active' : ''}`}>
            <User size={24} />
            <span>Perfil</span>
          </NavLink>

          {user?.isSuperuser && (
            <NavLink to="/admin" className={({isActive}) => `nav-item ${isActive ? 'active' : ''}`}>
              <Settings size={28} style={{ color: "var(--ncs-accent)" }} />
              <span style={{ color: "var(--ncs-accent)", fontWeight: "bold" }}>Panel Admin</span>
            </NavLink>
          )}
        </nav>
      )}
    </div>
  );
};

export default Layout;
