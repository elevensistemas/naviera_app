import React, { useState, useEffect, useRef, useContext } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import { ArrowLeft, Send, Camera, Paperclip, Loader, Download, FileText, Image, AlertCircle, Check, CheckCheck, User as UserIcon } from 'lucide-react';
import { getApiEndpoint, API_BASE } from '../config';
import AuthContext from '../context/AuthContext';

const ChatDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const chatName = location.state?.name || "Chat";
  
  const { user } = useContext(AuthContext);
  const currentUser = user || JSON.parse(localStorage.getItem('ncsCurrentUser') || '{}');

  const [messages, setMessages] = useState([]);
  const [participant, setParticipant] = useState({});
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState(null);

  const messagesEndRef = useRef(null);
  const fileInputRef = useRef(null);
  const cameraInputRef = useRef(null);

  const resolveMediaUrl = (url) => {
    if (!url) return '';
    if (url.startsWith('http')) return url;
    const baseUrl = API_BASE ? API_BASE.replace(/\/$/, '') : 'https://navieracruzdelsur.dyndns.org:6570';
    return `${baseUrl}${url}`;
  };

  const isImageAttachment = (url) => {
    if (!url) return false;
    const lower = url.toLowerCase();
    return lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.gif') || lower.endsWith('.webp');
  };

  const formatMessageTime = (isoString) => {
    if (!isoString) return '';
    try {
      const date = new Date(isoString);
      const today = new Date();
      const isToday = date.getDate() === today.getDate() &&
                      date.getMonth() === today.getMonth() &&
                      date.getFullYear() === today.getFullYear();
      
      const timeStr = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false });
      if (isToday) {
        return timeStr;
      }
      const dateStr = date.toLocaleDateString([], { day: 'numeric', month: 'short' });
      return `${dateStr}, ${timeStr}`;
    } catch (e) {
      return '';
    }
  };

  const getStatusColor = (userObj) => {
    if (!userObj.online) return '#6b7280'; // offline - Gris
    switch (userObj.status) {
      case 'available': return '#22c55e'; // Disponible - Verde
      case 'busy': return '#ef4444'; // Ocupado - Rojo
      case 'away': return '#eab308'; // Ausente - Amarillo
      default: return '#22c55e';
    }
  };

  const getStatusText = (userObj) => {
    if (!userObj.online) return 'Desconectado';
    switch (userObj.status) {
      case 'available': return 'Disponible';
      case 'busy': return 'Ocupado';
      case 'away': return 'Ausente';
      default: return 'En línea';
    }
  };

  const fetchMessages = async (showLoading = false) => {
    try {
      if (showLoading) setLoading(true);
      const token = localStorage.getItem('ncsToken');
      const headers = {};
      if (token) {
        headers['Authorization'] = `Token ${token}`;
      }
      const res = await fetch(getApiEndpoint(`/api/v1/chat/messages/${id}/`), { headers });
      if (!res.ok) {
        throw new Error('Error al conectar con la API de chat.');
      }
      const data = await res.json();
      setParticipant(data.participant || {});
      setMessages(data.messages || []);
      setError(null);
    } catch (err) {
      console.error('Error fetching chat detail messages:', err);
      if (showLoading) setError(err.message || 'Error al conectar con el servidor.');
    } finally {
      if (showLoading) setLoading(false);
    }
  };

  useEffect(() => {
    fetchMessages(true);
    
    // Polling structure
    const interval = setInterval(() => {
      fetchMessages(false);
    }, 4000);

    return () => clearInterval(interval);
  }, [id]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: loading ? 'auto' : 'smooth' });
  }, [messages.length, loading]);

  const handleSend = async (file = null) => {
    if (!input.trim() && !file) return;

    setSending(true);
    try {
      const token = localStorage.getItem('ncsToken');
      const headers = {};
      if (token) {
        headers['Authorization'] = `Token ${token}`;
      }

      const formData = new FormData();
      if (input.trim()) {
        formData.append('content', input.trim());
      }
      if (file) {
        formData.append('attachment', file);
      }

      const res = await fetch(getApiEndpoint(`/api/v1/chat/messages/${id}/send/`), {
        method: 'POST',
        headers,
        body: formData
      });

      if (!res.ok) {
        throw new Error('No se pudo enviar el mensaje.');
      }

      setInput('');
      await fetchMessages(false);
    } catch (err) {
      console.error('Error sending message:', err);
      alert('Error: ' + err.message);
    } finally {
      setSending(false);
    }
  };

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      handleSend(file);
    }
    e.target.value = '';
  };

  const renderStatusTicks = (msg) => {
    if (msg.read) {
      return <CheckCheck size={14} color="var(--ncs-accent)" style={{ marginLeft: '4px' }} />;
    }
    if (msg.delivered) {
      return <CheckCheck size={14} color="var(--text-secondary)" style={{ marginLeft: '4px' }} />;
    }
    return <Check size={14} color="var(--text-secondary)" style={{ marginLeft: '4px' }} />;
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '80vh', gap: '16px', color: 'var(--text-secondary)' }}>
        <Loader size={36} className="animate-spin" color="var(--ncs-accent)" />
        <span>Cargando conversación...</span>
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
          onClick={() => fetchMessages(true)} 
          style={{ padding: '8px 16px', borderRadius: '8px', border: 'none', background: 'var(--ncs-primary)', color: '#fff', cursor: 'pointer', fontWeight: 'bold' }}
        >
          Reintentar
        </button>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', backgroundColor: 'var(--bg-secondary)', position: 'relative' }}>
      {/* Header */}
      <div className="glass" style={{ display: 'flex', alignItems: 'center', padding: 'calc(12px + var(--safe-area-top)) 16px 12px 16px', gap: '12px', position: 'sticky', top: 0, zIndex: 10, borderBottom: '1px solid var(--surface-border)' }}>
        <ArrowLeft size={24} onClick={() => navigate(-1)} style={{ cursor: 'pointer', color: 'var(--ncs-accent)' }} />
        
        {/* Participant Avatar */}
        <div style={{ position: 'relative', width: '40px', height: '40px', borderRadius: '20px', backgroundColor: 'var(--surface-border)', overflow: 'hidden', display: 'flex', justifyContent: 'center', alignItems: 'center', border: '1px solid var(--border-color)' }}>
          {participant.image_url ? (
            <img src={resolveMediaUrl(participant.image_url)} alt={participant.name || chatName} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          ) : (
            <UserIcon size={18} color="var(--text-secondary)" />
          )}
        </div>

        {/* Participant info */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
          <span style={{ fontSize: '16px', fontWeight: 'bold', color: 'var(--text-primary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {participant.name || participant.username || chatName}
          </span>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span style={{ 
              width: '8px', 
              height: '8px', 
              borderRadius: '4px', 
              backgroundColor: getStatusColor(participant) 
            }} />
            <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>
              {getStatusText(participant)}
            </span>
          </div>
        </div>
      </div>

      {/* Messages Scroll Area */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '16px', display: 'flex', flexDirection: 'column', gap: '12px', paddingBottom: '90px' }}>
        {messages.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-secondary)', fontSize: '14px' }}>
            No hay mensajes en esta conversación. Comienza enviando uno.
          </div>
        ) : (
          messages.map(msg => {
            const isMe = String(msg.sender_id) === String(currentUser.id);
            return (
              <div key={msg.id} style={{ display: 'flex', justifyContent: isMe ? 'flex-end' : 'flex-start' }}>
                <div style={{ 
                  maxWidth: '75%', 
                  padding: '10px 14px', 
                  borderRadius: '16px',
                  borderBottomRightRadius: isMe ? '4px' : '16px',
                  borderBottomLeftRadius: !isMe ? '4px' : '16px',
                  background: isMe 
                    ? 'linear-gradient(135deg, var(--ncs-accent) 0%, #0055ff 100%)' 
                    : 'rgba(255, 255, 255, 0.05)',
                  border: isMe 
                    ? '1px solid rgba(0, 240, 255, 0.2)' 
                    : '1px solid rgba(255, 255, 255, 0.08)',
                  color: isMe ? '#FFFFFF' : 'var(--text-primary)',
                  boxShadow: isMe ? '0 4px 12px rgba(0, 240, 255, 0.15)' : '0 2px 8px rgba(0,0,0,0.2)'
                }}>
                  {/* Sender Name if not me */}
                  {!isMe && (
                    <div style={{ fontSize: '11px', color: 'var(--ncs-accent)', fontWeight: 'bold', marginBottom: '4px' }}>
                      {msg.sender_name}
                    </div>
                  )}

                  {/* Deleted status */}
                  {msg.is_deleted ? (
                    <span style={{ fontSize: '14px', fontStyle: 'italic', color: isMe ? 'rgba(255,255,255,0.6)' : 'var(--text-secondary)' }}>
                      🚫 Mensaje eliminado
                    </span>
                  ) : (
                    <>
                      {/* Text content */}
                      {msg.content && (
                        <div style={{ fontSize: '14px', lineHeight: '1.4', wordBreak: 'break-word', whiteSpace: 'pre-wrap' }}>
                          {msg.content}
                        </div>
                      )}

                      {/* Attachment */}
                      {msg.attachment_url && (
                        <div style={{ marginTop: msg.content ? '8px' : '0px' }}>
                          {isImageAttachment(msg.attachment_url) ? (
                            <img 
                              src={resolveMediaUrl(msg.attachment_url)} 
                              alt={msg.attachment_name || "Imagen"} 
                              onClick={() => window.open(resolveMediaUrl(msg.attachment_url), '_blank')}
                              style={{ 
                                maxWidth: '100%', 
                                maxHeight: '200px', 
                                borderRadius: '8px', 
                                border: '1px solid rgba(255,255,255,0.1)', 
                                cursor: 'pointer',
                                transition: 'transform 0.2s'
                              }}
                              onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.02)'}
                              onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
                            />
                          ) : (
                            <div 
                              onClick={() => window.open(resolveMediaUrl(msg.attachment_url), '_blank')}
                              style={{ 
                                display: 'flex', 
                                alignItems: 'center', 
                                gap: '8px', 
                                padding: '8px 12px', 
                                borderRadius: '8px', 
                                backgroundColor: isMe ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.03)', 
                                border: '1px solid rgba(255,255,255,0.1)',
                                cursor: 'pointer',
                                transition: 'background-color 0.2s'
                              }}
                              onMouseEnter={(e) => e.currentTarget.style.backgroundColor = isMe ? 'rgba(255,255,255,0.15)' : 'rgba(255,255,255,0.08)'}
                              onMouseLeave={(e) => e.currentTarget.style.backgroundColor = isMe ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.03)'}
                            >
                              <FileText size={18} color={isMe ? '#fff' : 'var(--ncs-accent)'} />
                              <div style={{ flex: 1, minWidth: 0 }}>
                                <div style={{ fontSize: '12px', fontWeight: 'bold', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                  {msg.attachment_name || 'Documento'}
                                </div>
                                <span style={{ fontSize: '10px', color: isMe ? 'rgba(255,255,255,0.7)' : 'var(--text-secondary)' }}>
                                  Haga clic para descargar
                                </span>
                              </div>
                              <Download size={16} />
                            </div>
                          )}
                        </div>
                      )}
                    </>
                  )}

                  {/* Time and Ticks row */}
                  <div style={{ 
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'flex-end', 
                    fontSize: '9px', 
                    color: isMe ? 'rgba(255,255,255,0.7)' : 'var(--text-secondary)', 
                    textAlign: 'right', 
                    marginTop: '4px' 
                  }}>
                    {formatMessageTime(msg.created_at)}
                    {isMe && renderStatusTicks(msg)}
                  </div>
                </div>
              </div>
            );
          })
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Uploading progress indicator */}
      {sending && (
        <div style={{ 
          position: 'absolute', 
          bottom: '76px', 
          left: '16px', 
          right: '16px', 
          display: 'flex', 
          alignItems: 'center', 
          gap: '8px', 
          padding: '8px 12px', 
          borderRadius: '12px', 
          backgroundColor: 'rgba(10, 15, 30, 0.95)', 
          border: '1px solid var(--ncs-accent)', 
          fontSize: '12px',
          color: 'var(--text-primary)',
          boxShadow: '0 4px 15px rgba(0, 240, 255, 0.2)',
          zIndex: 20
        }}>
          <Loader size={14} className="animate-spin" color="var(--ncs-accent)" />
          <span>Enviando archivo...</span>
        </div>
      )}

      {/* Hidden File Inputs */}
      <input 
        type="file" 
        ref={fileInputRef} 
        style={{ display: 'none' }} 
        onChange={handleFileChange} 
      />
      <input 
        type="file" 
        ref={cameraInputRef} 
        accept="image/*" 
        style={{ display: 'none' }} 
        onChange={handleFileChange} 
      />

      {/* Input controls */}
      <div className="glass" style={{ 
        position: 'fixed', 
        bottom: 0, 
        left: 0, 
        right: 0, 
        padding: '12px 16px', 
        paddingBottom: 'calc(12px + var(--safe-area-bottom))', 
        display: 'flex', 
        gap: '12px', 
        alignItems: 'center',
        borderTop: '1px solid var(--surface-border)',
        zIndex: 10
      }}>
        <Paperclip 
          size={22} 
          color="var(--text-secondary)" 
          style={{ cursor: 'pointer', transition: 'color 0.2s' }} 
          onClick={() => fileInputRef.current.click()}
          onMouseEnter={(e) => e.target.style.color = 'var(--ncs-accent)'}
          onMouseLeave={(e) => e.target.style.color = 'var(--text-secondary)'}
        />
        <Camera 
          size={22} 
          color="var(--text-secondary)" 
          style={{ cursor: 'pointer', transition: 'color 0.2s' }} 
          onClick={() => cameraInputRef.current.click()}
          onMouseEnter={(e) => e.target.style.color = 'var(--ncs-accent)'}
          onMouseLeave={(e) => e.target.style.color = 'var(--text-secondary)'}
        />
        <input 
          type="text" 
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyPress={e => e.key === 'Enter' && handleSend()}
          placeholder="Escribir mensaje..."
          disabled={sending}
          style={{ 
            flex: 1, 
            padding: '10px 16px', 
            borderRadius: '20px', 
            border: '1px solid var(--border-color)', 
            backgroundColor: 'rgba(0,0,0,0.3)', 
            color: '#fff', 
            outline: 'none', 
            fontSize: '15px',
            transition: 'border-color 0.2s'
          }}
          onFocus={(e) => e.target.style.borderColor = 'var(--ncs-accent)'}
          onBlur={(e) => e.target.style.borderColor = 'var(--border-color)'}
        />
        <div 
          onClick={() => !sending && handleSend()}
          style={{ 
            width: '40px', 
            height: '40px', 
            borderRadius: '20px', 
            background: 'linear-gradient(135deg, var(--ncs-accent) 0%, #0055ff 100%)', 
            display: 'flex', 
            justifyContent: 'center', 
            alignItems: 'center', 
            cursor: sending ? 'not-allowed' : 'pointer',
            boxShadow: '0 4px 10px rgba(0, 240, 255, 0.3)',
            transition: 'transform 0.1s'
          }}
          onMouseDown={(e) => e.currentTarget.style.transform = 'scale(0.95)'}
          onMouseUp={(e) => e.currentTarget.style.transform = 'scale(1)'}
        >
          <Send size={18} color="white" style={{ marginLeft: '2px' }} />
        </div>
      </div>
    </div>
  );
};

export default ChatDetail;
