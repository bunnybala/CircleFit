import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import apiClient from '../../core/network/apiClient';

function Groups() {
  const navigate = useNavigate();
  const [groups, setGroups] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showJoinModal, setShowJoinModal] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);
  
  // Form states
  const [inviteCode, setInviteCode] = useState('');
  const [groupName, setGroupName] = useState('');
  const [groupDesc, setGroupDesc] = useState('');
  
  const [joinError, setJoinError] = useState('');
  const [createError, setCreateError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const fetchGroups = async () => {
    setLoading(true);
    try {
      const response = await apiClient.get('/groups/my');
      setGroups(response.data || []);
    } catch (err) {
      console.error('Failed to load groups:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchGroups();
  }, []);

  const handleJoinGroup = async (e) => {
    e.preventDefault();
    if (!inviteCode.trim()) return;
    
    setSubmitting(true);
    setJoinError('');
    
    try {
      await apiClient.post('/groups/join', { inviteCode: inviteCode.trim() });
      setShowJoinModal(false);
      setInviteCode('');
      fetchGroups();
    } catch (err) {
      console.error(err);
      const msg = err.response?.data?.message || 'Failed to join group. Check the invite code.';
      setJoinError(msg);
    } finally {
      setSubmitting(false);
    }
  };

  const handleCreateGroup = async (e) => {
    e.preventDefault();
    if (!groupName.trim()) return;

    setSubmitting(true);
    setCreateError('');

    try {
      await apiClient.post('/groups', {
        name: groupName.trim(),
        description: groupDesc.trim()
      });
      setShowCreateModal(false);
      setGroupName('');
      setGroupDesc('');
      fetchGroups();
    } catch (err) {
      console.error(err);
      const msg = err.response?.data?.message || 'Failed to create group.';
      setCreateError(msg);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div>
      {/* Header bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '28px' }}>
        <h2 style={{ fontSize: '24px', fontWeight: '800', fontFamily: 'var(--font-heading)' }}>My Groups</h2>
        
        <div style={{ display: 'flex', gap: '10px' }}>
          <button 
            onClick={() => setShowJoinModal(true)}
            className="btn-secondary"
            style={{
              background: 'white',
              border: '1px solid var(--border-color)',
              color: 'var(--primary)',
              padding: '10px 18px',
              borderRadius: '12px',
              fontWeight: '700',
              cursor: 'pointer'
            }}
          >
            Join Group
          </button>
          <button 
            onClick={() => setShowCreateModal(true)}
            className="auth-btn"
            style={{
              padding: '10px 18px',
              borderRadius: '12px',
              fontWeight: '700',
              marginTop: 0,
              width: 'auto'
            }}
          >
            + Create Group
          </button>
        </div>
      </div>

      {loading ? (
        <div style={{ display: 'flex', justifyContent: 'center', padding: '60px 0', fontWeight: 'bold' }}>
          Loading groups...
        </div>
      ) : groups.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '80px 0', color: 'var(--grey-text)' }}>
          <span style={{ fontSize: '80px', display: 'block', marginBottom: '20px' }}>👥</span>
          <h3 style={{ fontSize: '18px', fontWeight: 'bold', color: 'var(--dark)', marginBottom: '8px' }}>No groups yet</h3>
          <p style={{ fontSize: '14px', color: 'var(--grey-text)' }}>
            Create a fitness group or join an existing one using an invite code!
          </p>
        </div>
      ) : (
        /* Groups grid matching custom mobile design */
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '20px' }}>
          {groups.map((g) => (
            <div 
              key={g.id}
              onClick={() => navigate(`/groups/${g.id}`)}
              className="fit-card"
              style={{
                display: 'flex',
                padding: '20px',
                cursor: 'pointer',
                marginBottom: 0,
                textAlign: 'left',
                border: '1px solid rgba(0,0,0,0.03)',
                alignItems: 'center',
                gap: '16px'
              }}
            >
              <div style={{
                width: '56px',
                height: '56px',
                borderRadius: '50%',
                backgroundColor: 'var(--primary-light)',
                color: 'var(--primary)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontWeight: '900',
                fontSize: '22px',
                fontFamily: 'var(--font-heading)'
              }}>
                {g.name[0].toUpperCase()}
              </div>

              <div style={{ flex: 1, minWidth: 0 }}>
                <h4 style={{ fontWeight: '700', fontSize: '16px', color: 'var(--dark)', marginBottom: '4px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {g.name}
                </h4>
                <p style={{ fontSize: '13px', color: 'var(--grey-text)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', marginBottom: '8px' }}>
                  {g.description || 'No description provided.'}
                </p>
                
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <span style={{ fontSize: '12px', color: 'var(--grey-text)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                    👥 {g.memberCount}/{g.maxMembers}
                  </span>
                  
                  <span style={{
                    padding: '2px 8px',
                    borderRadius: '20px',
                    backgroundColor: 'var(--primary-light)',
                    color: 'var(--primary)',
                    fontSize: '11px',
                    fontWeight: 'bold',
                    letterSpacing: '0.5px'
                  }}>
                    {g.inviteCode}
                  </span>
                </div>
              </div>
              <span style={{ fontSize: '18px', color: '#cbd5e1' }}>➡️</span>
            </div>
          ))}
        </div>
      )}

      {/* Join Group Modal Overlay */}
      {showJoinModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <h3 className="modal-header">Join a Group</h3>
            {joinError && (
              <div className="error-banner" style={{ padding: '8px 12px', marginBottom: '14px' }}>
                <span>{joinError}</span>
              </div>
            )}
            <form onSubmit={handleJoinGroup}>
              <div className="form-group">
                <label className="form-label">Invite Code</label>
                <input
                  type="text"
                  maxLength="6"
                  className="form-input"
                  placeholder="Enter 6-character code"
                  value={inviteCode}
                  onChange={(e) => setInviteCode(e.target.value.toUpperCase())}
                  required
                  style={{ textTransform: 'uppercase', textAlign: 'center', letterSpacing: '2px', fontWeight: 'bold' }}
                />
              </div>
              <div className="modal-footer">
                <button type="button" className="btn-secondary" onClick={() => { setShowJoinModal(false); setJoinError(''); }}>
                  Cancel
                </button>
                <button type="submit" className="auth-btn" style={{ width: 'auto', marginTop: 0 }} disabled={submitting}>
                  {submitting ? 'Joining...' : 'Join Group'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Create Group Modal Overlay */}
      {showCreateModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <h3 className="modal-header">Create Group</h3>
            {createError && (
              <div className="error-banner" style={{ padding: '8px 12px', marginBottom: '14px' }}>
                <span>{createError}</span>
              </div>
            )}
            <form onSubmit={handleCreateGroup}>
              <div className="form-group">
                <label className="form-label">Group Name</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="e.g. Morning Warriors"
                  value={groupName}
                  onChange={(e) => setGroupName(e.target.value)}
                  required
                />
              </div>
              <div className="form-group">
                <label className="form-label">Description (optional)</label>
                <textarea
                  className="form-input"
                  placeholder="What is this group about?"
                  value={groupDesc}
                  onChange={(e) => setGroupDesc(e.target.value)}
                  rows="3"
                  style={{ resize: 'none' }}
                />
              </div>
              <div className="modal-footer">
                <button type="button" className="btn-secondary" onClick={() => { setShowCreateModal(false); setCreateError(''); }}>
                  Cancel
                </button>
                <button type="submit" className="auth-btn" style={{ width: 'auto', marginTop: 0 }} disabled={submitting}>
                  {submitting ? 'Creating...' : 'Create Group'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default Groups;
