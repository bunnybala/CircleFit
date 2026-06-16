import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import apiClient from '../../core/network/apiClient';

function Register() {
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const navigate = useNavigate();

  const handleRegister = async (e) => {
    e.preventDefault();
    if (!username || !email || !password) {
      setError('Please fill in all fields');
      return;
    }
    if (password.length < 6) {
      setError('Password must be at least 6 characters');
      return;
    }

    setLoading(true);
    setError('');

    try {
      // Register request
      await apiClient.post('/auth/register', {
        username,
        email,
        password,
      });

      // Auto login after successful registration
      const loginResponse = await apiClient.post('/auth/login', {
        email,
        password,
      });

      const token = loginResponse.data.token;
      localStorage.setItem('jwt_token', token);

      // Navigate to dashboard
      navigate('/');
    } catch (err) {
      console.error(err);
      const msg = err.response?.data?.message || 'Network error occurred during registration';
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
          <p className="auth-subtitle">Create your account to get started!</p>
        </div>

        {error && (
          <div className="error-banner">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
              <path d="M8.982 1.566a1.13 1.13 0 0 0-1.96 0L.165 13.233c-.457.778.091 1.767.98 1.767h13.713c.889 0 1.438-.99.98-1.767L8.982 1.566zM8 5c.535 0 .954.462.9.995l-.35 3.507a.552.552 0 0 1-1.1 0L7.1 5.995A.905.905 0 0 1 8 5zm.002 6a1 1 0 1 1 0 2 1 1 0 0 1 0-2z"/>
            </svg>
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleRegister} noValidate>
          <div className="form-group">
            <label className="form-label">Username</label>
            <input
              type="text"
              id="username"
              className="form-input"
              placeholder="e.g. fitwarrior"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
            />
          </div>

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
              placeholder="Min. 6 characters"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>

          <button type="submit" id="register-button" className="auth-btn" disabled={loading}>
            {loading ? 'Creating Account...' : 'Register'}
          </button>
        </form>

        <div className="auth-footer">
          Already have an account? 
          <Link to="/login" className="auth-link">Login</Link>
        </div>
      </div>
    </div>
  );
}

export default Register;
