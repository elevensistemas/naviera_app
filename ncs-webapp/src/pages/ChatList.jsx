import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Users, User as UserIcon, MessageSquare, Search, AlertCircle, Loader } from 'lucide-react';
import { getApiEndpoint } from '../config';

const ChatList = () => {
  const [activeTab, setActiveTab] = useState('recent'); // 'recent' or 'contacts'
  const [conversations, setConversations] = useState([]);
  const [contacts, setContacts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  const [searchQuery, setSearchQuery] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    fetchChatList();
  }, []);

  const fetchChatList = async () => {
    try {
      setLoading(true);
      setError(null);

      const token = localStorage.getItem('ncsToken');
      const headers = { 'Content-Type': 'application/json' };
      if (token) {
        headers['Authorization'] = `Token ${token}`;
      }

      const [convRes, usersRes] = await Promise.all([
        fetch(getApiEndpoint('/api/v1/chat/conversations/'), { headers }),
        fetch(getApiEndpoint('/api/v1/chat/users/'), { headers })
      ]);

      if (!convRes.ok || !usersRes.ok) {
        throw new Error('No se pudieron recuperar las conversaciones de chat.');
      }

      const convData = await convRes.json();
      const usersData = await usersRes.json();

      setConversations(convData.results || []);
      setContacts(usersData.results || []);

    } catch (err) {
      console.error('Error fetching chat lists:', err);
      setError(err.message || 'Error al conectar con la API de chat.');
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (user) => {
    if (!user.online) return '#6b7280'; // offline - Gris
    switch (user.status) {
      case 'available': return '#22c55e'; // online - Verde
      case 'busy': return '#ef4444'; // busy - Rojo
      case 'away': return '#eab308'; // away - Amarillo
      default: return '#22c55e';
    }
  };

  const getAvatarUrl = (imgUrl) => {
    if (!imgUrl) return null;
    if (imgUrl.startsWith('http')) return imgUrl;
    return `https://navieracruzdelsur.dyndns.org:6570${imgUrl}`;
  };

  const formatTime = (isoString) => {
    if (!isoString) return '';
    try {
      const date = new Date(isoString);
      return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    } catch (e) {
      return '';
    }
  };

  // Filter conversations
  const filteredConversations = conversations.filter(c => {
    const name = c.participant?.name || c.participant?.username || '';
    const lastMsg = c.last_message?.content || '';
    return name.toLowerCase().includes(searchQuery.toLowerCase()) ||
           lastMsg.toLowerCase().includes(searchQuery.toLowerCase());
  });

  // Filter contacts
  const filteredContacts = contacts.filter(user => {
    const name = user.name || user.username || '';
    const email = user.email || '';
    return name.toLowerCase().includes(searchQuery.toLowerCase()) ||
           email.toLowerCase().includes(searchQuery.toLowerCase());
  });

  if (loading) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '80vh', gap: '16px', color: 'var(--text-secondary)' }}>
        <Loader size={36} className="animate-spin" color="var(--ncs-accent)" />
        <span>Cargando chats...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '80vh', padding: '20px', textAlign: 'center', color: 'var(--text-secondary)' }}>
        <AlertCircle size={40} color="var(--ncs-danger)" style={{ marginBottom: '12px' }} />
        <h3 style={{ color: 'var(--text-primary)', marginBottom: '8px' }}>Error de comunicaciones</h3>
        <p style={{ maxWidth: '400px', fontSize: '14px', marginBottom: '20px' }}>{error}</p>
        <button 
          onClick={fetchChatList} 
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
        <MessageSquare size={24} color="var(--ncs-accent)" />
        Comunicaciones
      </div>

      <div style={{ padding: '0 16px' }}>
        {/* Search */}
        <div style={{ display: 'flex', alignItems: 'center', backgroundColor: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '12px', marginBottom: '16px' }}>
          <Search size={20} color="var(--text-secondary)" style={{ marginRight: '12px' }} />
          <input 
            type="text" 
            placeholder={activeTab === 'recent' ? "Buscar conversación..." : "Buscar contacto..."}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            style={{ border: 'none', background: 'transparent', outline: 'none', color: 'var(--text-primary)', width: '100%', fontSize: '16px' }}
          />
        </div>

        {/* Tab Switcher */}
        <div style={{ display: 'flex', gap: '8px', padding: '4px', backgroundColor: 'rgba(15, 23, 42, 0.4)', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.05)', marginBottom: '16px' }}>
          <button
            onClick={() => { setActiveTab('recent'); setSearchQuery(''); }}
            style={{
              flex: 1, padding: '8px 14px', borderRadius: '8px', border: 'none',
              background: activeTab === 'recent' ? 'linear-gradient(135deg, var(--ncs-accent) 0%, #0055ff 100%)' : 'transparent',
              color: activeTab === 'recent' ? '#ffffff' : 'var(--text-secondary)',
              fontSize: '13px', fontWeight: 'bold', cursor: 'pointer', transition: 'all 0.2s'
            }}
          >
            Chats Recientes
          </button>
          <button
            onClick={() => { setActiveTab('contacts'); setSearchQuery(''); }}
            style={{
              flex: 1, padding: '8px 14px', borderRadius: '8px', border: 'none',
              background: activeTab === 'contacts' ? 'linear-gradient(135deg, var(--ncs-accent) 0%, #0055ff 100%)' : 'transparent',
              color: activeTab === 'contacts' ? '#ffffff' : 'var(--text-secondary)',
              fontSize: '13px', fontWeight: 'bold', cursor: 'pointer', transition: 'all 0.2s'
            }}
          >
            Todos los Contactos
          </button>
        </div>

        {/* Dynamic Lists */}
        {activeTab === 'recent' ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {filteredConversations.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-secondary)' }}>
                No hay conversaciones recientes que coincidan.
              </div>
            ) : (
              filteredConversations.map(conv => {
                const participant = conv.participant;
                const statusColor = getStatusColor(participant);
                const picUrl = getAvatarUrl(participant.image_url);
                const lastMsg = conv.last_message;

                return (
                  <div 
                    key={conv.thread_id} 
                    onClick={() => navigate(`/chat/${participant.id}`, { state: { name: participant.name || participant.username } })}
                    className="card"
                    style={{ 
                      display: 'flex', alignItems: 'center', gap: '16px', padding: '16px', margin: '0', cursor: 'pointer',
                      borderLeft: conv.unread_count > 0 ? '4px solid var(--ncs-accent)' : '1px solid var(--border-color)',
                      transition: 'background-color 0.2s'
                    }}
                    onMouseEnter={(e) => e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.02)'}
                    onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'var(--bg-color)'}
                  >
                    {/* Avatar with Status indicator */}
                    <div style={{ position: 'relative', flexShrink: 0 }}>
                      <div style={{ width: '48px', height: '48px', borderRadius: '24px', backgroundColor: 'var(--surface-border)', overflow: 'hidden', display: 'flex', justifyContent: 'center', alignItems: 'center', border: '1px solid var(--border-color)' }}>
                        {picUrl ? (
                          <img src={picUrl} alt={participant.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                        ) : (
                          <UserIcon size={20} color="var(--text-secondary)" />
                        )}
                      </div>
                      <div style={{ 
                        position: 'absolute', bottom: '0', right: '0', width: '12px', height: '12px', borderRadius: '6px', 
                        backgroundColor: statusColor, border: '2px solid var(--bg-color)' 
                      }} />
                    </div>

                    {/* Meta info */}
                    <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: '4px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span style={{ fontSize: '15px', fontWeight: 'bold', color: 'var(--text-primary)' }}>
                          {participant.name || participant.username}
                        </span>
                        <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>
                          {formatTime(conv.updated_at)}
                        </span>
                      </div>
                      
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '10px' }}>
                        <span style={{ 
                          fontSize: '13px', color: conv.unread_count > 0 ? 'var(--text-primary)' : 'var(--text-secondary)', 
                          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', flex: 1,
                          fontWeight: conv.unread_count > 0 ? 'bold' : 'normal'
                        }}>
                          {lastMsg ? (lastMsg.is_deleted ? '🚫 Mensaje eliminado' : (lastMsg.content || 'Archivo adjunto')) : 'Sin mensajes'}
                        </span>
                        {conv.unread_count > 0 && (
                          <span style={{ 
                            backgroundColor: 'var(--ncs-accent)', color: '#fff', fontSize: '10px', fontWeight: 'bold',
                            minWidth: '18px', height: '18px', borderRadius: '9px', display: 'flex', justifyContent: 'center', alignItems: 'center',
                            padding: '0 4px', flexShrink: 0
                          }}>
                            {conv.unread_count}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {filteredContacts.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-secondary)' }}>
                No se encontraron contactos.
              </div>
            ) : (
              filteredContacts.map(user => {
                const statusColor = getStatusColor(user);
                const picUrl = getAvatarUrl(user.image_url);

                return (
                  <div 
                    key={user.id} 
                    onClick={() => navigate(`/chat/${user.id}`, { state: { name: user.name || user.username } })}
                    className="card"
                    style={{ 
                      display: 'flex', alignItems: 'center', gap: '16px', padding: '12px 16px', margin: '0', cursor: 'pointer',
                      border: '1px solid var(--border-color)', transition: 'background-color 0.2s'
                    }}
                    onMouseEnter={(e) => e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.02)'}
                    onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'var(--bg-color)'}
                  >
                    {/* Avatar with Status indicator */}
                    <div style={{ position: 'relative', flexShrink: 0 }}>
                      <div style={{ width: '42px', height: '42px', borderRadius: '21px', backgroundColor: 'var(--surface-border)', overflow: 'hidden', display: 'flex', justifyContent: 'center', alignItems: 'center', border: '1px solid var(--border-color)' }}>
                        {picUrl ? (
                          <img src={picUrl} alt={user.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                        ) : (
                          <UserIcon size={18} color="var(--text-secondary)" />
                        )}
                      </div>
                      <div style={{ 
                        position: 'absolute', bottom: '0', right: '0', width: '10px', height: '10px', borderRadius: '5px', 
                        backgroundColor: statusColor, border: '2px solid var(--bg-color)' 
                      }} />
                    </div>

                    <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: '3px' }}>
                      <span style={{ fontSize: '14px', fontWeight: 'bold', color: 'var(--text-primary)' }}>
                        {user.name || user.username}
                      </span>
                      {user.email && (
                        <span style={{ fontSize: '11px', color: 'var(--text-secondary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                          {user.email}
                        </span>
                      )}
                    </div>
                  </div>
                );
              })
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default ChatList;
