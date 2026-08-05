import React, { useState, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import AuthContext from '../context/AuthContext';
import { Ship } from 'lucide-react';

const Login = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  
  const { login } = useContext(AuthContext);
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    if (!username || !password) {
      setError('Complete todos los campos');
      return;
    }
    
    setLoading(true);
    setError('');
    try {
      await login(username, password);
      navigate('/');
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ 
      display: 'flex', 
      flexDirection: 'column', 
      minHeight: '100vh', 
      width: '100vw',
      position: 'absolute',
      top: 0,
      left: 0,
      padding: '20px', 
      justifyContent: 'center',
      background: 'linear-gradient(135deg, #0f172a 0%, #1e3a8a 100%)',
      zIndex: 9999
    }}>
      
      <div style={{ textAlign: 'center', marginBottom: '40px' }}>
        <img src="/logo.png" alt="Naviera Cruz Logo" className="logo-premium" style={{ height: '80px' }} />
      </div>

      <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        <input 
          type="text" 
          placeholder="Usuario (Ej. a.lopresti)" 
          className="input-field"
          value={username}
          onChange={e => setUsername(e.target.value)}
          autoCapitalize="none"
          style={{ backgroundColor: '#ffffff', color: '#000000', border: 'none', borderRadius: '10px', padding: '12px 16px' }}
        />
        
        <input 
          type="password" 
          placeholder="Contraseña" 
          className="input-field"
          value={password}
          onChange={e => setPassword(e.target.value)}
          style={{ backgroundColor: '#ffffff', color: '#000000', border: 'none', borderRadius: '10px', padding: '12px 16px' }}
        />
        
        {error && <p style={{ color: 'var(--ncs-danger)', fontSize: '14px', textAlign: 'center' }}>{error}</p>}
        
        <button type="submit" className="btn-primary" disabled={loading} style={{ marginTop: '10px' }}>
          {loading ? 'Ingresando...' : 'Ingresar'}
        </button>
      </form>

    </div>
  );
};

export default Login;
