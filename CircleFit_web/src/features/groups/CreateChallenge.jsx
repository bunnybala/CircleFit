import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import apiClient from '../../core/network/apiClient';

const PRESETS = [
  {
    title: '10K Steps Daily',
    description: 'Maintain an active routine by hitting 70,000 steps over a week!',
    type: 'STEPS',
    targetValue: 70000,
    durationDays: 7,
    icon: '🚶'
  },
  {
    title: 'Calorie Crusher',
    description: 'Burn 3,000 kcal through active tracking and workouts.',
    type: 'CALORIES',
    targetValue: 3000,
    durationDays: 5,
    icon: '🔥'
  },
  {
    title: 'Weekend Warrior',
    description: 'Push your limits over the weekend with a 25,000 step challenge.',
    type: 'STEPS',
    targetValue: 25000,
    durationDays: 2,
    icon: '⚡'
  }
];

function CreateChallenge() {
  const { id } = useParams();
  const groupId = parseInt(id, 10);
  const navigate = useNavigate();

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [type, setType] = useState('STEPS');
  const [targetValue, setTargetValue] = useState(70000);
  
  const formatDate = (date) => {
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  };

  const [startDate, setStartDate] = useState(() => formatDate(new Date()));
  const [endDate, setEndDate] = useState(() => {
    const end = new Date();
    end.setDate(end.getDate() + 7);
    return formatDate(end);
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleApplyTemplate = (tpl) => {
    setTitle(tpl.title);
    setDescription(tpl.description);
    setType(tpl.type);
    setTargetValue(tpl.targetValue);
    
    const start = new Date();
    const end = new Date();
    end.setDate(start.getDate() + tpl.durationDays);
    
    setStartDate(formatDate(start));
    setEndDate(formatDate(end));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!title.trim() || !targetValue || !startDate || !endDate) {
      setError('Please fill in all required fields');
      return;
    }

    if (new Date(endDate) < new Date(startDate)) {
      setError('End Date cannot be before Start Date');
      return;
    }

    setLoading(true);
    setError('');

    try {
      await apiClient.post('/challenges', {
        groupId,
        title: title.trim(),
        description: description.trim(),
        type,
        targetValue: parseInt(targetValue, 10),
        startDate,
        endDate
      });
      
      // Navigate back to group details
      navigate(`/groups/${groupId}`);
    } catch (err) {
      console.error(err);
      const msg = err.response?.data?.message || 'Failed to create challenge.';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const daysDifference = () => {
    try {
      const diff = new Date(endDate) - new Date(startDate);
      const days = Math.round(diff / (1000 * 60 * 60 * 24));
      return days < 0 ? 0 : days;
    } catch (e) {
      return 0;
    }
  };

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '14px', marginBottom: '24px', textAlign: 'left' }}>
        <button 
          onClick={() => navigate(`/groups/${groupId}`)}
          style={{
            background: 'transparent',
            border: 'none',
            fontSize: '20px',
            cursor: 'pointer',
            padding: '4px'
          }}
        >
          ⬅️
        </button>
        <h2 style={{ fontSize: '22px', fontWeight: '800', fontFamily: 'var(--font-heading)' }}>Create Challenge</h2>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '24px', textAlign: 'left' }}>
        
        {/* Live Preview Card */}
        <div style={{
          background: type === 'STEPS' 
            ? 'linear-gradient(135deg, rgba(108, 99, 255, 0.08) 0%, rgba(142, 135, 255, 0.02) 100%)'
            : 'linear-gradient(135deg, rgba(255, 159, 41, 0.08) 0%, rgba(255, 69, 0, 0.02) 100%)',
          borderRadius: '20px',
          border: `1.5px solid ${type === 'STEPS' ? 'rgba(108, 99, 255, 0.2)' : 'rgba(255, 159, 41, 0.2)'}`,
          padding: '20px',
          boxShadow: '0 4px 12px rgba(0,0,0,0.01)'
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <span style={{
                width: '36px',
                height: '36px',
                borderRadius: '50%',
                backgroundColor: type === 'STEPS' ? 'var(--primary-light)' : 'rgba(255,159,41,0.15)',
                color: type === 'STEPS' ? 'var(--primary)' : 'var(--orange)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '18px'
              }}>
                {type === 'STEPS' ? '🚶' : '🔥'}
              </span>
              <div>
                <h4 style={{ fontWeight: '800', fontSize: '15px' }}>{title || 'Your Challenge Title'}</h4>
                <span style={{ fontSize: '11px', color: 'var(--orange)', fontWeight: 'bold' }}>
                  ⏱️ {daysDifference()} days duration
                </span>
              </div>
            </div>
            <span style={{
              padding: '4px 10px',
              borderRadius: '20px',
              backgroundColor: '#E6F7FF',
              color: '#1890FF',
              fontSize: '10px',
              fontWeight: 'bold',
              letterSpacing: '0.5px',
              border: '1px solid rgba(24,144,255,0.2)'
            }}>
              LIVE PREVIEW
            </span>
          </div>

          <p style={{ color: 'var(--grey-text)', fontSize: '13px', margin: '10px 0' }}>
            {description || 'Short description of your fitness goals...'}
          </p>

          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', color: 'var(--grey-text)' }}>
            <span>🚩 Goal: {targetValue || 0} {type === 'STEPS' ? 'steps' : 'kcal'}</span>
            <span>👥 1 joined</span>
          </div>
        </div>

        {/* Template Quick Selection */}
        <div className="fit-card" style={{ padding: '20px', marginBottom: 0 }}>
          <h3 style={{ fontSize: '14px', fontWeight: 'bold', marginBottom: '12px' }}>✨ Select a Preset Template</h3>
          
          <div style={{ display: 'flex', overflowX: 'auto', gap: '12px', paddingBottom: '10px' }}>
            {PRESETS.map((tpl, idx) => (
              <div 
                key={idx}
                onClick={() => handleApplyTemplate(tpl)}
                style={{
                  minWidth: '170px',
                  background: 'var(--white)',
                  border: `2px solid ${title === tpl.title && type === tpl.type ? 'var(--primary)' : 'var(--border-color)'}`,
                  padding: '12px',
                  borderRadius: '16px',
                  cursor: 'pointer',
                  boxShadow: '0 2px 6px rgba(0,0,0,0.02)'
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '6px' }}>
                  <span style={{ fontSize: '18px' }}>{tpl.icon}</span>
                  <strong style={{ fontSize: '13px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {tpl.title}
                  </strong>
                </div>
                <span style={{ fontSize: '11px', color: 'var(--grey-text)' }}>
                  {tpl.targetValue} {tpl.type === 'STEPS' ? 'steps' : 'kcal'} • {tpl.durationDays}d
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Configure Form */}
        <div className="fit-card" style={{ padding: '24px' }}>
          {error && (
            <div className="error-banner">
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label className="form-label">Challenge Title</label>
              <input
                type="text"
                className="form-input"
                placeholder="e.g. 10K Steps Daily"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Description (optional)</label>
              <textarea
                className="form-input"
                placeholder="Short description of the challenge"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                rows="2"
                style={{ resize: 'none' }}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Type</label>
              <div style={{ display: 'flex', gap: '10px' }}>
                <button
                  type="button"
                  onClick={() => { setType('STEPS'); setTargetValue(70000); }}
                  style={{
                    flex: 1,
                    padding: '12px',
                    borderRadius: '12px',
                    border: 'none',
                    fontWeight: 'bold',
                    cursor: 'pointer',
                    backgroundColor: type === 'STEPS' ? 'var(--primary)' : 'var(--light-grey)',
                    color: type === 'STEPS' ? 'white' : 'var(--dark)'
                  }}
                >
                  🚶 Steps
                </button>
                <button
                  type="button"
                  onClick={() => { setType('CALORIES'); setTargetValue(3000); }}
                  style={{
                    flex: 1,
                    padding: '12px',
                    borderRadius: '12px',
                    border: 'none',
                    fontWeight: 'bold',
                    cursor: 'pointer',
                    backgroundColor: type === 'CALORIES' ? 'var(--orange)' : 'var(--light-grey)',
                    color: type === 'CALORIES' ? 'white' : 'var(--dark)'
                  }}
                >
                  🔥 Calories
                </button>
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Target Goal ({type === 'STEPS' ? 'steps' : 'kcal'})</label>
              <input
                type="number"
                className="form-input"
                placeholder={type === 'STEPS' ? 'e.g. 70000' : 'e.g. 3000'}
                value={targetValue}
                onChange={(e) => setTargetValue(parseInt(e.target.value, 10) || 0)}
                required
              />
            </div>

            <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
              <div className="form-group" style={{ flex: 1, minWidth: '150px' }}>
                <label className="form-label">Start Date</label>
                <input
                  type="date"
                  className="form-input"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  required
                />
              </div>
              <div className="form-group" style={{ flex: 1, minWidth: '150px' }}>
                <label className="form-label">End Date</label>
                <input
                  type="date"
                  className="form-input"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  required
                />
              </div>
            </div>

            <button 
              type="submit" 
              className="auth-btn"
              disabled={loading}
              style={{
                backgroundColor: type === 'STEPS' ? 'var(--primary)' : 'var(--orange)',
                boxShadow: `0 4px 12px ${type === 'STEPS' ? 'rgba(108,99,255,0.2)' : 'rgba(255,159,41,0.2)'}`
              }}
            >
              {loading ? 'Creating Challenge...' : 'Create Challenge'}
            </button>
          </form>
        </div>

      </div>
    </div>
  );
}

export default CreateChallenge;
