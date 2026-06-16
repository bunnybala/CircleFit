import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate, Link, useLocation } from 'react-router-dom';
import apiClient from './core/network/apiClient';

// Screens
import Login from './features/auth/Login';
import Register from './features/auth/Register';
import Dashboard from './features/dashboard/Dashboard';
import FoodSearch from './features/tracking/FoodSearch';
import FoodScanner from './features/tracking/FoodScanner';
import Groups from './features/groups/Groups';
import GroupDetails from './features/groups/GroupDetails';
import CreateChallenge from './features/groups/CreateChallenge';
import ChallengeDetails from './features/groups/ChallengeDetails';
import Profile from './features/profile/Profile';

// Guard for protected routes
function ProtectedRoute({ children }) {
  const token = localStorage.getItem('jwt_token');
  if (!token) {
    return <Navigate to="/login" replace />;
  }
  return <AppLayout>{children}</AppLayout>;
}

// Global responsive layout wrapper with sidebar & header
function AppLayout({ children }) {
  const location = useLocation();
  const [profile, setProfile] = useState(null);

  useEffect(() => {
    const fetchHeaderProfile = async () => {
      try {
        const response = await apiClient.get('/profile');
        setProfile(response.data);
      } catch (err) {
        console.error('Layout profile fetch failed:', err);
      }
    };
    fetchHeaderProfile();
  }, [location.pathname]); // Refresh on navigation changes

  // Determine current page title
  const getHeaderTitle = () => {
    const path = location.pathname;
    if (path === '/' || path === '/dashboard') return 'CircleFit Dashboard';
    if (path === '/food-search') return 'Search Nutrition';
    if (path === '/scanner') return 'Scan Food';
    if (path === '/groups') return 'Fitness Groups';
    if (path.startsWith('/groups/')) {
      if (path.endsWith('/challenge')) return 'Configure Challenge';
      return 'Group Detail';
    }
    if (path.startsWith('/challenges/')) return 'Challenge leaderboard';
    if (path === '/profile') return 'Profile Settings';
    return 'CircleFit';
  };

  return (
    <div className="app-shell">
      {/* Sidebar Navigation */}
      <aside className="app-sidebar">
        <div className="sidebar-logo">
          <span style={{ fontSize: '26px' }}>⭕</span>
          <span>
            <strong style={{ color: 'var(--primary)' }}>Circle</strong>
            <strong style={{ color: 'var(--secondary)' }}>Fit</strong>
          </span>
        </div>
        
        <nav className="sidebar-menu">
          <Link to="/" className={`sidebar-link ${location.pathname === '/' ? 'active' : ''}`}>
            <svg fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
            </svg>
            <span>Dashboard</span>
          </Link>
          
          <Link to="/groups" className={`sidebar-link ${location.pathname.startsWith('/groups') || location.pathname.startsWith('/challenges') ? 'active' : ''}`}>
            <svg fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
            </svg>
            <span>Groups</span>
          </Link>

          <Link to="/profile" className={`sidebar-link ${location.pathname === '/profile' ? 'active' : ''}`}>
            <svg fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
            </svg>
            <span>Profile</span>
          </Link>
        </nav>

        {profile && (
          <div className="sidebar-user">
            <Link to="/profile" style={{ display: 'flex', alignItems: 'center', gap: '10px', textDecoration: 'none', color: 'inherit' }}>
              <div style={{
                width: '32px',
                height: '32px',
                borderRadius: '50%',
                backgroundColor: 'var(--primary-light)',
                color: 'var(--primary)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontWeight: 'bold',
                fontSize: '13px'
              }}>
                {profile.name ? profile.name[0].toUpperCase() : profile.username[0]?.toUpperCase()}
              </div>
              <div style={{ textAlign: 'left', minWidth: 0 }}>
                <span style={{ fontSize: '13px', fontWeight: 'bold', display: 'block', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {profile.name || profile.username}
                </span>
                <span style={{ fontSize: '10px', color: 'var(--grey-text)', display: 'block' }}>
                  @{profile.username}
                </span>
              </div>
            </Link>
          </div>
        )}
      </aside>

      {/* Main content container */}
      <div className="app-main">
        <header className="app-header">
          <span className="header-title">{getHeaderTitle()}</span>
          {profile && (
            <Link to="/profile" className="header-profile">
              <span style={{ fontSize: '13px', fontWeight: 'bold' }}>{profile.name || profile.username}</span>
              <div className="header-avatar">
                {profile.name ? profile.name[0].toUpperCase() : profile.username[0]?.toUpperCase()}
              </div>
            </Link>
          )}
        </header>
        
        <main className="app-content">
          {children}
        </main>
      </div>
    </div>
  );
}

function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Public Routes */}
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        
        {/* Protected Routes */}
        <Route path="/" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
        <Route path="/food-search" element={<ProtectedRoute><FoodSearch /></ProtectedRoute>} />
        <Route path="/scanner" element={<ProtectedRoute><FoodScanner /></ProtectedRoute>} />
        <Route path="/groups" element={<ProtectedRoute><Groups /></ProtectedRoute>} />
        <Route path="/groups/:id" element={<ProtectedRoute><GroupDetails /></ProtectedRoute>} />
        <Route path="/groups/:id/challenge" element={<ProtectedRoute><CreateChallenge /></ProtectedRoute>} />
        <Route path="/challenges/:id" element={<ProtectedRoute><ChallengeDetails /></ProtectedRoute>} />
        <Route path="/profile" element={<ProtectedRoute><Profile /></ProtectedRoute>} />
        
        {/* Catch-all redirect */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
