import React, { createContext, useState, useEffect } from 'react';
import { getApiEndpoint } from '../config';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [user, setUser] = useState(null);

  // Cargar usuarios de localStorage o inicializar por defecto
  const getStoredUsers = () => {
    const defaultUsers = [
      { id: 'alejandro', name: 'A. Lo Presti', role: 'Gerencia General', password: 'Trinitotolueno2015' },
      { id: 'a.lopresti', name: 'A. Lo Presti', role: 'Gerencia General', password: 'alguna1234' },
      { id: 'm.piccinini', name: 'M. Piccinini', role: 'Director de Operaciones', password: 'alguna1234' },
      { id: 'admin', name: 'Administrador', role: 'Sistemas', password: 'alguna1234', isSuperuser: true }
    ];
    const stored = localStorage.getItem('ncsUsers');
    if (stored) return JSON.parse(stored);
    localStorage.setItem('ncsUsers', JSON.stringify(defaultUsers));
    return defaultUsers;
  };

  useEffect(() => {
    const token = localStorage.getItem('ncsToken');
    if (token) {
      // Re-hydrate user strictly for demo purposes
      const fakeSessionUser = JSON.parse(localStorage.getItem('ncsCurrentUser'));
      if (fakeSessionUser) {
        setIsAuthenticated(true);
        setUser(fakeSessionUser);
      }
    }
  }, []);

  const login = async (username, password) => {
    try {
      const response = await fetch(getApiEndpoint('/api/v1/login/'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ username, password })
      });

      if (!response.ok) {
        let errMsg = 'Credenciales inválidas. Comprueba tu usuario y contraseña.';
        try {
          const errData = await response.json();
          errMsg = errData?.detail || errData?.non_field_errors?.[0] || errData?.error || errMsg;
        } catch (e) {
          // Response is not JSON or empty
        }
        throw new Error(errMsg);
      }

      const data = await response.json();
      const token = data.token;
      if (!token) {
        throw new Error('No se recibió el token de autenticación desde el servidor.');
      }

      localStorage.setItem('ncsToken', token);
      
      // Armamos la información del usuario a partir del backend
      const safeUser = { 
        id: data.id || username.toLowerCase(), 
        name: data.name || data.username || username, 
        role: data.role || (username.toLowerCase() === 'alejandro' || username.toLowerCase() === 'a.lopresti' ? 'Gerencia General' : 'Personal Naviera'), 
        isSuperuser: data.is_superuser || data.isSuperuser || (username.toLowerCase() === 'admin') 
      };
      
      localStorage.setItem('ncsCurrentUser', JSON.stringify(safeUser));
      setIsAuthenticated(true);
      setUser(safeUser);
    } catch (error) {
      console.error('Error durante el inicio de sesión:', error);
      if (error.message && error.message.includes('Failed to fetch')) {
        throw new Error('No se pudo conectar con el servidor de la intranet. Verifica tu conexión.');
      }
      throw error;
    }
  };

  const registerUser = (newUser) => {
    const users = getStoredUsers();
    if (users.find(u => u.id === newUser.id)) {
      throw new Error(`El usuario ${newUser.id} ya existe en el sistema.`);
    }
    const updatedUsers = [...users, newUser];
    localStorage.setItem('ncsUsers', JSON.stringify(updatedUsers));
  };

  const deleteUser = (userId) => {
    if (userId === 'admin') throw new Error("No se puede eliminar el Superusuario de base.");
    let users = getStoredUsers();
    users = users.filter(u => u.id !== userId);
    localStorage.setItem('ncsUsers', JSON.stringify(users));
  }

  const logout = () => {
    localStorage.removeItem('ncsToken');
    localStorage.removeItem('ncsCurrentUser');
    setIsAuthenticated(false);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ isAuthenticated, user, login, logout, registerUser, deleteUser, getStoredUsers }}>
      {children}
    </AuthContext.Provider>
  );
};

export default AuthContext;
