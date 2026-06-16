import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import apiClient from '../../core/network/apiClient';

function ChallengeDetails() {
  const { id } = useParams();
  const challengeId = parseInt(id, 10);
  const navigate = useNavigate();

  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchProgress = async () => {
    setLoading(true);
    try {
      const response = await apiClient.get(`/challenges/${challengeId}/progress`);
      // Sort entries descending by percentComplete
      const data = response.data || [];
      data.sort((a, b) => b.percentComplete - a.percentComplete);
      setEntries(data);
    } catch (err) {
      console.error(err);
      setError('Failed to load participant progress.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProgress();
  }, [challengeId]);

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', padding: '60px 0', fontWeight: 'bold' }}>
        Loading challenge progress...
      </div>
    );
  }

  const medals = ['🥇', '🥈', '🥉'];

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '14px', marginBottom: '24px', textAlign: 'left' }}>
        <button 
          onClick={() => navigate(-1)}
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
        <h2 style={{ fontSize: '22px', fontWeight: '800', fontFamily: 'var(--font-heading)' }}>Challenge Progress</h2>
      </div>

      {error && (
        <div className="error-banner">
          <span>{error}</span>
        </div>
      )}

      {entries.length === 0 ? (
        <div className="fit-card" style={{ textAlign: 'center', padding: '48px 0', color: 'var(--grey-text)' }}>
          <span style={{ fontSize: '60px', display: 'block', marginBottom: '16px' }}>👥</span>
          <h3 style={{ fontSize: '16px', color: 'var(--dark)', fontWeight: 'bold' }}>No participants yet</h3>
          <p style={{ fontSize: '13px', marginTop: '4px' }}>Join the challenge to appear on the progress board!</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', textAlign: 'left' }}>
          {entries.map((entry, index) => {
            const rank = index + 1;
            const isTop3 = rank <= 3;
            const unit = entry.type === 'STEPS' ? 'steps' : 'kcal';
            const progressPercentage = Math.min(entry.percentComplete, 100);

            return (
              <div 
                key={entry.username}
                className="fit-card"
                style={{ padding: '20px', marginBottom: 0 }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '14px' }}>
                  <span style={{ width: '32px', textAlign: 'center', fontSize: isTop3 ? '20px' : '14px', fontWeight: 'bold', color: 'var(--grey-text)' }}>
                    {isTop3 ? medals[rank - 1] : `#${rank}`}
                  </span>
                  
                  <div style={{
                    width: '40px',
                    height: '40px',
                    borderRadius: '50%',
                    backgroundColor: 'var(--primary-light)',
                    color: 'var(--primary)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontWeight: 'bold',
                    fontSize: '15px'
                  }}>
                    {entry.name[0].toUpperCase()}
                  </div>

                  <div style={{ flex: 1, minWidth: 0 }}>
                    <strong style={{ display: 'block', fontSize: '14px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                      {entry.name}
                    </strong>
                    <span style={{ fontSize: '12px', color: 'var(--grey-text)' }}>@{entry.username}</span>
                  </div>

                  <div style={{ textAlign: 'right' }}>
                    <strong style={{ fontSize: '15px' }}>{entry.currentProgress} / {entry.targetValue}</strong>
                    <span style={{ display: 'block', fontSize: '10px', color: 'var(--grey-text)' }}>{unit}</span>
                  </div>
                </div>

                {/* Progress bar and complete percent */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                  <div style={{ height: '8px', backgroundColor: 'var(--light-bg)', borderRadius: '4px', overflow: 'hidden' }}>
                    <div style={{
                      width: `${progressPercentage}%`,
                      height: '100%',
                      backgroundColor: progressPercentage >= 100 ? 'var(--success)' : 'var(--primary)',
                      borderRadius: '4px',
                      transition: 'width 0.8s ease'
                    }}></div>
                  </div>
                  
                  <div style={{ display: 'flex', justifyContent: 'flex-end', fontSize: '11px', fontWeight: '700', color: progressPercentage >= 100 ? 'var(--success)' : 'var(--primary)' }}>
                    <span>{Math.round(entry.percentComplete)}% complete</span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

export default ChallengeDetails;
