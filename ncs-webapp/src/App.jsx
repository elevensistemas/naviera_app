import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import AuthContext, { AuthProvider } from './context/AuthContext';
import Login from './pages/Login';
import Home from './pages/Home';
import Fleet from './pages/Fleet';
import ChatList from './pages/ChatList';
import AIChat from './pages/AIChat';
import ChatDetail from './pages/ChatDetail';
import Profile from './pages/Profile';
import AdminPanel from './pages/AdminPanel';
import Crew from './pages/Crew';
import MonthlySchedule from './pages/MonthlySchedule';
import Security from './pages/Security';

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated } = React.useContext(AuthContext);
  return isAuthenticated ? children : <Navigate to="/login" replace />;
};

function App() {
  React.useEffect(() => {
    const savedTheme = localStorage.getItem('ncs-theme');
    if (savedTheme) {
      document.documentElement.setAttribute('data-theme', savedTheme);
    }
  }, []);

  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          
          <Route path="/" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
            <Route index element={<Navigate to="/home" replace />} />
            <Route path="home" element={<Home />} />
            <Route path="fleet" element={<Fleet />} />
            <Route path="crew" element={<Crew />} />
            <Route path="monthly" element={<MonthlySchedule />} />
            <Route path="security" element={<Security />} />
            <Route path="chat" element={<ChatList />} />
            <Route path="chat/:id" element={<ChatDetail />} />
            <Route path="ai" element={<AIChat />} />
            <Route path="profile" element={<Profile />} />
            <Route path="admin" element={
              <ProtectedRoute>
                <AdminPanel />
              </ProtectedRoute>
            } />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
