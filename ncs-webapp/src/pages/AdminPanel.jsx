import React, { useState, useContext, useEffect } from 'react';
import { ShieldCheck, UserPlus, Trash2, Eye } from 'lucide-react';
import AuthContext from '../context/AuthContext';
import { Navigate } from 'react-router-dom';

const AdminPanel = () => {
  const { user, registerUser, deleteUser, getStoredUsers } = useContext(AuthContext);
  const [usersList, setUsersList] = useState([]);
  
  // Forms State
  const [newUserId, setNewUserId] = useState('');
  const [newUserName, setNewUserName] = useState('');
  const [newUserPass, setNewUserPass] = useState('');
  const [newUserRole, setNewUserRole] = useState('Tripulante');
  const [newUserSuper, setNewUserSuper] = useState(false);
  
  const [errorObj, setErrorObj] = useState('');
  const [successObj, setSuccessObj] = useState('');

  // Protect route strictly explicitly again
  if (!user || (!user.isSuperuser && user.id !== 'admin')) {
    return <Navigate to="/home" replace />;
  }

  const loadUsers = () => {
    try {
      setUsersList(getStoredUsers());
    } catch(e) {}
  };

  useEffect(() => {
    loadUsers();
  }, []);

  const handleCreateUser = (e) => {
    e.preventDefault();
    try {
      if(!newUserId || !newUserName || !newUserPass) throw new Error("Llena todos los campos.");
      
      const payload = {
        id: newUserId.toLowerCase(),
        name: newUserName,
        role: newUserRole,
        password: newUserPass,
        isSuperuser: newUserSuper
      };
      
      registerUser(payload);
      setSuccessObj(`Usuario ${newUserId} creado con éxito.`);
      setErrorObj('');
      
      // Clear forms
      setNewUserId('');
      setNewUserName('');
      setNewUserPass('');
      setNewUserSuper(false);
      
      loadUsers();
    } catch (err) {
      setErrorObj(err.message);
      setSuccessObj('');
    }
  };

  const handleDeleteUser = (id) => {
    try {
      if(window.confirm(`¿Seguro que quieres borrar a ${id}?`)) {
        deleteUser(id);
        loadUsers();
      }
    } catch(err) {
      alert(err.message);
    }
  }

  return (
    <div style={{ padding: '16px', minHeight: '100%', paddingBottom: '70px' }}>
      <div className="top-header glass" style={{ marginBottom: '20px', borderRadius: '16px' }}>
        <ShieldCheck size={32} color="var(--ncs-accent)" style={{ marginBottom: '8px' }} />
        <br/>
        Panel Superusuario
      </div>

      <div className="card">
        <h3 style={{ color: 'var(--ncs-accent)', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <UserPlus size={20} /> Crear Usuario
        </h3>
        
        {errorObj && <div style={{ color: 'var(--ncs-secondary)', marginBottom: '10px', fontSize: '14px' }}>{errorObj}</div>}
        {successObj && <div style={{ color: 'var(--ncs-success)', marginBottom: '10px', fontSize: '14px' }}>{successObj}</div>}

        <form onSubmit={handleCreateUser} style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          <input 
            type="text" 
            placeholder="ID de Acceso (ej: m.lopez)" 
            className="input-field"
            value={newUserId}
            onChange={(e) => setNewUserId(e.target.value)}
          />
          <input 
            type="text" 
            placeholder="Nombre Completo" 
            className="input-field"
            value={newUserName}
            onChange={(e) => setNewUserName(e.target.value)}
          />
          <input 
            type="password" 
            placeholder="Contraseña" 
            className="input-field"
            value={newUserPass}
            onChange={(e) => setNewUserPass(e.target.value)}
          />
          
          <select 
            className="input-field" 
            value={newUserRole} 
            onChange={(e) => setNewUserRole(e.target.value)}
            style={{ backgroundColor: '#0a0f1d', color: '#fff' }}
          >
            <option value="Tripulante">Tripulante</option>
            <option value="Gerencia General">Gerencia General</option>
            <option value="Director de Operaciones">Director de Operaciones</option>
            <option value="Sistemas">Sistemas</option>
          </select>
          
          <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '14px', margin: '8px 0' }}>
            <input 
              type="checkbox" 
              checked={newUserSuper} 
              onChange={(e) => setNewUserSuper(e.target.checked)} 
              style={{ width: '18px', height: '18px' }}
            />
            {newUserSuper ? <span style={{ color: 'var(--ncs-secondary)', fontWeight: 'bold' }}>Súper Privilegios de Admin Activados</span> : <span>Otorgar privilegios de Súper Admin</span>}
          </label>

          <button type="submit" className="btn-primary" style={{ marginTop: '8px' }}>Registrar</button>
        </form>
      </div>

      <div className="card">
        <h3 style={{ color: 'var(--text-primary)', marginBottom: '16px' }}>Usuarios Guardados</h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
          {usersList.map(u => (
            <div key={u.id} style={{ display: 'flex', justifyContent: 'space-between', padding: '12px', background: 'rgba(255,255,255,0.05)', borderRadius: '8px' }}>
              <div>
                <strong>{u.name}</strong> <span style={{ color: 'var(--text-secondary)', fontSize: '12px' }}>({u.id})</span>
                <br/>
                <span style={{ fontSize: '12px', color: u.isSuperuser ? 'var(--ncs-secondary)' : 'var(--ncs-accent)' }}>{u.role}</span>
              </div>
              {u.id !== 'admin' && (
                <button onClick={() => handleDeleteUser(u.id)} style={{ background: 'none', border: 'none', color: 'var(--ncs-danger)', cursor: 'pointer' }}>
                  <Trash2 size={20} />
                </button>
              )}
            </div>
          ))}
        </div>
      </div>

      <div className="card">
        <h3 style={{ color: 'var(--ncs-warning)', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Eye size={20} /> Vistas Activas
        </h3>
        <p style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>Las siguientes vistas y permisos están configurados para la flota:</p>
        <ul style={{ marginTop: '12px', listStyle: 'none', paddingLeft: '0', display: 'flex', flexDirection: 'column', gap: '8px' }}>
          <li style={{ padding: '8px', background: 'rgba(255,204,0,0.1)', borderRadius: '4px', borderLeft: '4px solid var(--ncs-warning)' }}>Vista "Gustavo U": Autorizada (HLS Nativo)</li>
          <li style={{ padding: '8px', background: 'rgba(255,204,0,0.1)', borderRadius: '4px', borderLeft: '4px solid var(--ncs-warning)' }}>Vista "Alfa C": Autorizada (HLS Nativo)</li>
          <li style={{ padding: '8px', background: 'rgba(255,204,0,0.1)', borderRadius: '4px', borderLeft: '4px solid var(--ncs-warning)' }}>Vista "Nany": Autorizada (HLS Nativo)</li>
        </ul>
      </div>
    </div>
  );
};

export default AdminPanel;
