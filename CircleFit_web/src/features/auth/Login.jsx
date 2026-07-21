import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import apiClient from '../../core/network/apiClient';

function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    if (!email || !password) {
      setError('Please fill in all fields');
      return;
    }
    const emailRegex = /^[\w-\.]+@([\w-]+\.)+com$/;
    if (!emailRegex.test(email)) {
      setError('Please enter a valid email ending with .com');
      return;
    }
    
    setLoading(true);
    setError('');
    
    try {
      const response = await apiClient.post('/auth/login', {
        email,
        password,
      });
      
      const token = response.data.token;
      localStorage.setItem('jwt_token', token);
      
      // Navigate to dashboard
      navigate('/');
    } catch (err) {
      console.error(err);
      const msg = err.response?.data?.message || 'Network error occurred while trying to login.';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-card">
        <div className="auth-header">
          <div className="auth-logo">
            <span style={{ color: 'var(--primary)' }}>Circle</span>
            <span style={{ color: 'var(--secondary)' }}>Fit</span>
          </div>
          <p className="auth-subtitle">Welcome back to CircleFit! 👋</p>
        </div>

        {error && (
          <div className="error-banner">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
              <path d="M8.982 1.566a1.13 1.13 0 0 0-1.96 0L.165 13.233c-.457.778.091 1.767.98 1.767h13.713c.889 0 1.438-.99.98-1.767L8.982 1.566zM8 5c.535 0 .954.462.9.995l-.35 3.507a.552.552 0 0 1-1.1 0L7.1 5.995A.905.905 0 0 1 8 5zm.002 6a1 1 0 1 1 0 2 1 1 0 0 1 0-2z"/>
            </svg>
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleLogin} noValidate>
          <div className="form-group">
            <label className="form-label">Email Address</label>
            <input
              type="email"
              id="email"
              className="form-input"
              placeholder="e.g. name@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Password</label>
            <input
              type="password"
              id="password"
              className="form-input"
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>

          <button type="submit" id="login-button" className="auth-btn" disabled={loading}>
            {loading ? 'Logging in...' : 'Login'}
          </button>
        </form>

        <div className="auth-footer">
          Don't have an account? 
          <Link to="/register" className="auth-link">Register</Link>
        </div>
      </div>
    </div>
  );
}

export default Login;
