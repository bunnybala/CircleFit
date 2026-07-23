import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Client } from '@stomp/stompjs';
import apiClient from '../../core/network/apiClient';

function GroupDetails() {
  const { id } = useParams();
  const groupId = parseInt(id, 10);
  const navigate = useNavigate();

  const [activeTab, setActiveTab] = useState('chat');
  const [group, setGroup] = useState(null);
  const [currentUser, setCurrentUser] = useState(null);
  const [loading, setLoading] = useState(true);

  // Chat States
  const [messages, setMessages] = useState([]);
  const [chatPage, setChatPage] = useState(0);
  const [hasMoreChat, setHasMoreChat] = useState(true);
  const [chatLoading, setChatLoading] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [msgInput, setMsgInput] = useState('');
  const [vulgarAlert, setVulgarAlert] = useState(null);
  const stompClientRef = useRef(null);
  const chatScrollRef = useRef(null);

  // Leaderboard States
  const [sortBy, setSortBy] = useState('total');
  const [leaderboard, setLeaderboard] = useState([]);
  const [leaderboardLoading, setLeaderboardLoading] = useState(false);

  // Challenges States
  const [challenges, setChallenges] = useState([]);
  const [challengesLoading, setChallengesLoading] = useState(false);

  // Initial group fetch
  useEffect(() => {
    const fetchGroupAndUser = async () => {
      try {
        const userRes = await apiClient.get('/profile');
        setCurrentUser(userRes.data);

        const groupRes = await apiClient.get('/groups/my');
        const found = groupRes.data.find((g) => g.id === groupId);
        setGroup(found || null);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    fetchGroupAndUser();
  }, [groupId]);

  // STOMP WebSocket Connection for Chat
  useEffect(() => {
    if (activeTab !== 'chat') return;

    const token = localStorage.getItem('jwt_token');
    const hostname = window.location.hostname;
    const wsHost = (hostname === 'localhost' || hostname === '127.0.0.1') ? 'localhost' : hostname;
    const wsUrl = `ws://${wsHost}:8081/ws-chat/websocket`;

    const client = new Client({
      brokerURL: wsUrl,
      connectHeaders: {
        Authorization: `Bearer ${token}`
      },
      onConnect: () => {
        setIsConnected(true);
        client.subscribe(`/topic/group/${groupId}`, (message) => {
          if (message.body) {
            const msg = JSON.parse(message.body);
            setMessages((prev) => [msg, ...prev]);
          }
        });
        client.subscribe('/user/queue/errors', (message) => {
          if (message.body) {
            setVulgarAlert(message.body);
          }
        });
      },
      onWebSocketError: (err) => {
        console.error('WS Connection error:', err);
      },
      onStompError: (err) => {
        console.error('STOMP broker error:', err);
      }
    });

    stompClientRef.current = client;
    client.activate();

    // Fetch initial chat history
    fetchChatHistory(0, true);

    return () => {
      if (stompClientRef.current) {
        stompClientRef.current.deactivate();
      }
      setIsConnected(false);
    };
  }, [groupId, activeTab]);

  // Leaderboard Fetch
  useEffect(() => {
    if (activeTab !== 'leaderboard') return;
    fetchLeaderboard();
  }, [groupId, sortBy, activeTab]);

  // Challenges Fetch
  useEffect(() => {
    if (activeTab !== 'challenges') return;
    fetchChallenges();
  }, [groupId, activeTab]);

  const fetchChatHistory = async (page, clear = false) => {
    if (chatLoading) return;
    setChatLoading(true);
    try {
      const response = await apiClient.get(`/groups/${groupId}/chat/history`, {
        params: { page, size: 50 }
      });
      const data = response.data || [];
      if (clear) {
        setMessages(data);
      } else {
        setMessages((prev) => [...prev, ...data]);
      }
      setHasMoreChat(data.length === 50);
      setChatPage(page + 1);
    } catch (err) {
      console.error(err);
    } finally {
      setChatLoading(false);
    }
  };

  const fetchLeaderboard = async () => {
    setLeaderboardLoading(true);
    try {
      const res = await apiClient.get(`/groups/${groupId}/leaderboard`, {
        params: { sortBy }
      });
      setLeaderboard(res.data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLeaderboardLoading(false);
    }
  };

  const fetchChallenges = async () => {
    setChallengesLoading(true);
    try {
      // Get all challenges for group
      const res = await apiClient.get(`/challenges/group/${groupId}`);
      const challengesList = res.data || [];

      // For each challenge, fetch progress lists to see user joined state
      const updated = await Promise.all(challengesList.map(async (c) => {
        try {
          const progRes = await apiClient.get(`/challenges/${c.id}/progress`);
          const userProgress = progRes.data?.find((p) => p.username === currentUser?.username);
          return {
            ...c,
            progress: userProgress || null,
            isJoined: !!userProgress
          };
        } catch (err) {
          console.error(err);
          return { ...c, progress: null, isJoined: false };
        }
      }));

      setChallenges(updated);
    } catch (err) {
      console.error(err);
    } finally {
      setChallengesLoading(false);
    }
  };

  const handleSendMessage = (e) => {
    if (e) e.preventDefault();
    if (!msgInput.trim() || !stompClientRef.current || !isConnected) return;

    stompClientRef.current.publish({
      destination: `/app/chat/${groupId}/sendMessage`,
      body: JSON.stringify({ content: msgInput.trim() })
    });
    setMsgInput('');
  };

  const handleJoinChallenge = async (challengeId) => {
    try {
      await apiClient.post(`/challenges/${challengeId}/join`);
      alert('Joined Challenge successfully!');
      fetchChallenges();
    } catch (err) {
      console.error(err);
      alert('Failed to join challenge.');
    }
  };

  const handleLeaveGroup = async () => {
    if (!window.confirm('Do you really want to leave this group?')) return;
    try {
      await apiClient.delete(`/groups/${groupId}/leave`);
      navigate('/groups');
    } catch (err) {
      console.error(err);
      alert('Failed to leave group.');
    }
  };

  const handleScroll = () => {
    if (!chatScrollRef.current || chatLoading || !hasMoreChat) return;
    const { scrollTop, scrollHeight, clientHeight } = chatScrollRef.current;
    
    // Reverse scrolling check: fetching history when scrolling to top (scrollTop is negative or small)
    if (scrollHeight - clientHeight + scrollTop <= 50) {
      fetchChatHistory(chatPage);
    }
  };

  const getRemainingTime = (endDateStr) => {
    try {
      const difference = new Date(endDateStr) - new Date();
      if (difference < 0) return 'Ended';
      const days = Math.floor(difference / (1000 * 60 * 60 * 24));
      if (days > 0) return `${days}d left`;
      const hours = Math.floor(difference / (1000 * 60 * 60));
      if (hours > 0) return `${hours}h left`;
      return 'Ends soon';
    } catch (e) {
      return '';
    }
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', padding: '60px 0', fontWeight: 'bold' }}>
        Loading group details...
      </div>
    );
  }

  if (!group) {
    return (
      <div style={{ textAlign: 'center', padding: '60px 0' }}>
        <h3>Group not found</h3>
        <button onClick={() => navigate('/groups')} className="btn-secondary" style={{ marginTop: '16px' }}>Back to groups</button>
      </div>
    );
  }

  // Podium layout variables
  const podium1st = leaderboard.length >= 1 ? leaderboard[0] : null;
  const podium2nd = leaderboard.length >= 2 ? leaderboard[1] : null;
  const podium3rd = leaderboard.length >= 3 ? leaderboard[2] : null;
  const listMembers = leaderboard.slice(3);

  return (
    <div>
      {/* Title & Actions Bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', textAlign: 'left' }}>
        <div>
          <h2 style={{ fontSize: '24px', fontWeight: '800', fontFamily: 'var(--font-heading)' }}>
            {group.name}
          </h2>
          <p style={{ color: 'var(--grey-text)', fontSize: '13px', marginTop: '4px' }}>
            {group.description}
          </p>
        </div>

        <div style={{ display: 'flex', gap: '8px' }}>
          <button 
            onClick={() => navigate(`/groups/${groupId}/challenge`)}
            className="btn-secondary"
            style={{ display: 'flex', alignItems: 'center', gap: '4px', background: 'var(--primary-light)', color: 'var(--primary)', fontWeight: 'bold' }}
          >
            📊 Create Challenge
          </button>
          <button onClick={handleLeaveGroup} className="btn-danger" style={{ fontWeight: 'bold' }}>
            Leave Group
          </button>
        </div>
      </div>

      {/* Tabs Menu navigation */}
      <div style={{
        display: 'flex',
        background: 'white',
        borderBottom: '1px solid var(--border-color)',
        marginBottom: '24px',
        gap: '24px'
      }}>
        {['chat', 'leaderboard', 'challenges'].map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            style={{
              background: 'transparent',
              border: 'none',
              borderBottom: activeTab === tab ? '3px solid var(--primary)' : '3px solid transparent',
              color: activeTab === tab ? 'var(--primary)' : 'var(--grey-text)',
              padding: '12px 6px',
              fontSize: '14px',
              fontWeight: '700',
              cursor: 'pointer',
              textTransform: 'capitalize',
              display: 'flex',
              alignItems: 'center',
              gap: '6px'
            }}
          >
            {tab === 'chat' && '💬 Chat'}
            {tab === 'leaderboard' && '🏆 Leaderboard'}
            {tab === 'challenges' && '🏁 Challenges'}
          </button>
        ))}
      </div>

      {/* Active Tab render */}
      {activeTab === 'chat' && (
        <div style={{ display: 'flex', flexDirection: 'column', height: '60vh', background: 'white', borderRadius: '24px', border: '1px solid var(--border-color)', overflow: 'hidden' }}>
          
          {!isConnected && (
            <div style={{ background: 'var(--warning)', color: 'var(--dark)', textAlign: 'center', padding: '6px', fontSize: '12px', fontWeight: 'bold' }}>
              Connecting to chat...
            </div>
          )}

          {/* Messages list - scrollable, reverse */}
          <div 
            ref={chatScrollRef}
            onScroll={handleScroll}
            style={{ flex: 1, overflowY: 'auto', padding: '20px', display: 'flex', flexDirection: 'column-reverse', gap: '14px', background: '#fafafc' }}
          >
            {messages.map((msg, idx) => {
              const isMe = msg.senderId === currentUser?.id;
              return (
                <div 
                  key={msg.id || idx}
                  style={{
                    alignSelf: isMe ? 'flex-end' : 'flex-start',
                    maxWidth: '70%',
                    textAlign: 'left'
                  }}
                >
                  <div style={{
                    backgroundColor: isMe ? '#E4FFC1' : 'white',
                    padding: '12px 16px',
                    borderRadius: isMe ? '20px 20px 0px 20px' : '20px 20px 20px 0px',
                    boxShadow: '0 2px 8px rgba(0,0,0,0.03)',
                    border: isMe ? 'none' : '1px solid var(--border-color)'
                  }}>
                    {!isMe && (
                      <strong style={{ fontSize: '11px', color: '#475569', display: 'block', marginBottom: '4px' }}>
                        {msg.senderName}
                      </strong>
                    )}
                    <p style={{ fontSize: '14px', color: 'var(--dark)' }}>{msg.content}</p>
                    <span style={{ fontSize: '9px', color: 'var(--grey-text)', display: 'block', textAlign: 'right', marginTop: '4px' }}>
                      {new Date(msg.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </span>
                  </div>
                </div>
              );
            })}

            {chatLoading && (
              <div style={{ textAlign: 'center', padding: '10px', fontSize: '12px', color: 'var(--grey-text)' }}>
                Loading chat history...
              </div>
            )}
          </div>

          {/* Send Area */}
          <form onSubmit={handleSendMessage} style={{ display: 'flex', padding: '16px', borderTop: '1px solid var(--border-color)', gap: '10px', alignItems: 'center' }}>
            <input
              type="text"
              className="form-input"
              placeholder="Type a message..."
              value={msgInput}
              onChange={(e) => setMsgInput(e.target.value)}
              style={{ flex: 1, margin: 0 }}
            />
            <button 
              type="submit" 
              className="auth-btn" 
              style={{ width: 'auto', marginTop: 0, padding: '12px 20px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
              disabled={!isConnected}
            >
              Send
            </button>
          </form>
        </div>
      )}

      {activeTab === 'leaderboard' && (
        <div>
          {/* Daily / All-time sort select toggle */}
          <div style={{ display: 'flex', justifyContent: 'center', gap: '8px', marginBottom: '24px' }}>
            {['total', 'today'].map((mode) => (
              <button
                key={mode}
                onClick={() => setSortBy(mode)}
                style={{
                  padding: '8px 18px',
                  borderRadius: '20px',
                  border: 'none',
                  backgroundColor: sortBy === mode ? 'var(--primary)' : 'white',
                  color: sortBy === mode ? 'white' : 'var(--dark)',
                  fontWeight: 'bold',
                  cursor: 'pointer',
                  fontSize: '12px',
                  boxShadow: '0 2px 6px rgba(0,0,0,0.03)'
                }}
              >
                {mode === 'total' ? '🏆 All-Time' : '📅 Today'}
              </button>
            ))}
          </div>

          {leaderboardLoading ? (
            <div style={{ textAlign: 'center', padding: '40px 0' }}>Loading leaderboard...</div>
          ) : leaderboard.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '40px 0', color: 'var(--grey-text)' }}>No scores logged yet.</div>
          ) : (
            <div>
              {/* Podium graphic display */}
              <div className="fit-card" style={{
                display: 'flex',
                alignItems: 'flex-end',
                justifyContent: 'space-evenly',
                padding: '30px 10px',
                textAlign: 'center',
                boxShadow: 'none',
                border: '1px solid var(--border-color)',
                marginBottom: '24px',
              }}>
                {/* 2nd Place Silver */}
                {podium2nd ? (
                  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                    <div style={{
                      width: '44px',
                      height: '44px',
                      borderRadius: '50%',
                      border: '2px solid #B5B5B5',
                      backgroundColor: 'var(--primary-light)',
                      color: 'var(--primary)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontWeight: 'bold',
                      boxShadow: '0 4px 10px rgba(0,0,0,0.05)',
                      marginBottom: '8px'
                    }}>
                      {podium2nd.name[0].toUpperCase()}
                    </div>
                    <strong style={{ fontSize: '13px', display: 'block', maxWidth: '80px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {podium2nd.name}
                    </strong>
                    <span style={{ fontSize: '11px', color: 'var(--primary)', fontWeight: 'bold' }}>
                      {sortBy === 'today' ? podium2nd.todaySteps : podium2nd.totalSteps} steps
                    </span>
                    <div style={{
                      marginTop: '10px',
                      width: '100%',
                      maxWidth: '90px',
                      height: '75px',
                      background: 'linear-gradient(to bottom, #E2E2E2, #B5B5B5)',
                      borderRadius: '16px 16px 0 0',
                      color: 'white',
                      fontWeight: '900',
                      fontSize: '20px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center'
                    }}>
                      #2
                    </div>
                  </div>
                ) : <div style={{ flex: 1 }}></div>}

                {/* 1st Place Gold with crown */}
                {podium1st ? (
                  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                    <span style={{ fontSize: '20px', display: 'block', height: '20px', marginBottom: '2px' }}>👑</span>
                    <div style={{
                      width: '52px',
                      height: '52px',
                      borderRadius: '50%',
                      border: '3px solid #FF9F29',
                      backgroundColor: 'var(--primary-light)',
                      color: 'var(--primary)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontWeight: 'bold',
                      boxShadow: '0 4px 12px rgba(255,159,41,0.2)',
                      marginBottom: '8px'
                    }}>
                      {podium1st.name[0].toUpperCase()}
                    </div>
                    <strong style={{ fontSize: '13px', display: 'block', maxWidth: '80px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {podium1st.name}
                    </strong>
                    <span style={{ fontSize: '11px', color: 'var(--primary)', fontWeight: 'bold' }}>
                      {sortBy === 'today' ? podium1st.todaySteps : podium1st.totalSteps} steps
                    </span>
                    <div style={{
                      marginTop: '10px',
                      width: '100%',
                      maxWidth: '90px',
                      height: '105px',
                      background: 'linear-gradient(to bottom, #FFD93D, #FF9F29)',
                      borderRadius: '16px 16px 0 0',
                      color: 'white',
                      fontWeight: '900',
                      fontSize: '24px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center'
                    }}>
                      #1
                    </div>
                  </div>
                ) : <div style={{ flex: 1 }}></div>}

                {/* 3rd Place Bronze */}
                {podium3rd ? (
                  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                    <div style={{
                      width: '44px',
                      height: '44px',
                      borderRadius: '50%',
                      border: '2px solid #D67229',
                      backgroundColor: 'var(--primary-light)',
                      color: 'var(--primary)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontWeight: 'bold',
                      boxShadow: '0 4px 10px rgba(0,0,0,0.05)',
                      marginBottom: '8px'
                    }}>
                      {podium3rd.name[0].toUpperCase()}
                    </div>
                    <strong style={{ fontSize: '13px', display: 'block', maxWidth: '80px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {podium3rd.name}
                    </strong>
                    <span style={{ fontSize: '11px', color: 'var(--primary)', fontWeight: 'bold' }}>
                      {sortBy === 'today' ? podium3rd.todaySteps : podium3rd.totalSteps} steps
                    </span>
                    <div style={{
                      marginTop: '10px',
                      width: '100%',
                      maxWidth: '90px',
                      height: '60px',
                      background: 'linear-gradient(to bottom, #FFB37C, #D67229)',
                      borderRadius: '16px 16px 0 0',
                      color: 'white',
                      fontWeight: '900',
                      fontSize: '18px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center'
                    }}>
                      #3
                    </div>
                  </div>
                ) : <div style={{ flex: 1 }}></div>}
              </div>

              {/* Leaderboard user list */}
              {listMembers.length > 0 && (
                <div style={{ textAlign: 'left' }}>
                  <h4 style={{ fontWeight: '700', fontSize: '15px', marginBottom: '14px' }}>All Rankings</h4>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                    {listMembers.map((member) => (
                      <div 
                        key={member.username}
                        className="fit-card" 
                        style={{ display: 'flex', alignItems: 'center', padding: '14px', marginBottom: 0, gap: '12px' }}
                      >
                        <span style={{ width: '30px', fontWeight: 'bold', color: 'var(--grey-text)', fontSize: '14px', textAlign: 'center' }}>
                          #{member.rank}
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
                          fontWeight: 'bold'
                        }}>
                          {member.name[0].toUpperCase()}
                        </div>
                        <div style={{ flex: 1 }}>
                          <strong style={{ display: 'block', fontSize: '14px' }}>{member.name}</strong>
                          <span style={{ fontSize: '12px', color: 'var(--grey-text)' }}>@{member.username}</span>
                        </div>
                        <div style={{ textAlign: 'right' }}>
                          <strong style={{ color: 'var(--primary)', fontSize: '16px' }}>
                            {sortBy === 'today' ? member.todaySteps : member.totalSteps}
                          </strong>
                          <span style={{ display: 'block', fontSize: '10px', color: 'var(--grey-text)' }}>steps</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {activeTab === 'challenges' && (
        <div>
          {challengesLoading ? (
            <div style={{ textAlign: 'center', padding: '40px 0' }}>Loading challenges...</div>
          ) : challenges.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '50px 0', color: 'var(--grey-text)' }}>
              <span style={{ fontSize: '60px', display: 'block', marginBottom: '16px' }}>🏁</span>
              <p style={{ marginBottom: '16px' }}>No challenges configured yet.</p>
              <button 
                onClick={() => navigate(`/groups/${groupId}/challenge`)}
                className="auth-btn"
                style={{ width: 'auto', padding: '10px 24px', marginTop: 0 }}
              >
                Create First Challenge
              </button>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', textAlign: 'left' }}>
              {challenges.map((c) => (
                <div 
                  key={c.id}
                  onClick={() => navigate(`/challenges/${c.id}`)}
                  className="fit-card"
                  style={{ marginBottom: 0, padding: '20px', cursor: 'pointer' }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                      <span style={{
                        width: '36px',
                        height: '36px',
                        borderRadius: '50%',
                        backgroundColor: c.type === 'STEPS' ? 'var(--primary-light)' : 'rgba(255,159,41,0.1)',
                        color: c.type === 'STEPS' ? 'var(--primary)' : 'var(--orange)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '18px'
                      }}>
                        {c.type === 'STEPS' ? '🚶' : '🔥'}
                      </span>
                      <div>
                        <h4 style={{ fontWeight: '800', fontSize: '15px' }}>{c.title}</h4>
                        {c.status === 'ACTIVE' && (
                          <span style={{ fontSize: '11px', color: 'var(--orange)', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '3px' }}>
                            ⏱️ {getRemainingTime(c.endDate)}
                          </span>
                        )}
                      </div>
                    </div>
                    <span style={{
                      padding: '4px 10px',
                      borderRadius: '20px',
                      backgroundColor: c.status === 'ACTIVE' ? 'var(--success-light)' : 'var(--light-grey)',
                      color: c.status === 'ACTIVE' ? 'var(--success)' : 'var(--grey-text)',
                      fontSize: '11px',
                      fontWeight: 'bold'
                    }}>
                      {c.status}
                    </span>
                  </div>

                  <p style={{ color: 'var(--grey-text)', fontSize: '13px', margin: '10px 0' }}>{c.description}</p>
                  
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', color: 'var(--grey-text)', marginBottom: '14px' }}>
                    <span>🚩 Goal: {c.targetValue} {c.type === 'STEPS' ? 'steps' : 'kcal'}</span>
                    <span>👥 {c.participantCount} joined</span>
                  </div>

                  {/* Joined metrics display */}
                  {c.isJoined && c.progress && (
                    <div style={{ margin: '14px 0', borderTop: '1px solid var(--border-color)', paddingTop: '14px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', fontWeight: 'bold', color: 'var(--primary)', marginBottom: '6px' }}>
                        <span>Your Progress: {c.progress.currentProgress} / {c.progress.targetValue}</span>
                        <span>{Math.round(c.progress.percentComplete)}%</span>
                      </div>
                      <div style={{ height: '6px', backgroundColor: 'var(--light-bg)', borderRadius: '4px', overflow: 'hidden' }}>
                        <div style={{
                          width: `${Math.min(c.progress.percentComplete, 100)}%`,
                          height: '100%',
                          backgroundColor: c.progress.percentComplete >= 100 ? 'var(--success)' : 'var(--primary)',
                          borderRadius: '4px',
                          transition: 'width 0.5s ease'
                        }}></div>
                      </div>
                    </div>
                  )}

                  <hr style={{ border: 'none', borderBottom: '1px solid var(--border-color)', margin: '12px 0 8px 0' }} />

                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: '11px', color: 'var(--grey-text)' }}>
                      📅 {c.startDate} → {c.endDate}
                    </span>
                    
                    {c.isJoined ? (
                      <div style={{
                        padding: '6px 12px',
                        background: 'var(--success-light)',
                        border: '1px solid rgba(52, 188, 157, 0.2)',
                        borderRadius: '12px',
                        color: 'var(--success)',
                        fontWeight: 'bold',
                        fontSize: '11px',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '4px'
                      }}>
                        ✓ Joined
                      </div>
                    ) : (
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          handleJoinChallenge(c.id);
                        }}
                        style={{
                          background: 'var(--primary-light)',
                          color: 'var(--primary)',
                          border: 'none',
                          padding: '6px 16px',
                          borderRadius: '12px',
                          fontSize: '12px',
                          fontWeight: 'bold',
                          cursor: 'pointer'
                        }}
                      >
                        Join
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
      {/* Vulgar Content Modal Overlay */}
      {vulgarAlert && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          width: '100%',
          height: '100%',
          backgroundColor: 'rgba(0,0,0,0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 9999,
          backdropFilter: 'blur(4px)'
        }}>
          <div style={{
            backgroundColor: '#ffffff',
            padding: '24px 32px',
            borderRadius: '20px',
            boxShadow: '0 10px 25px rgba(0,0,0,0.15)',
            textAlign: 'center',
            maxWidth: '400px',
            width: '90%'
          }}>
            <div style={{ fontSize: '48px', marginBottom: '16px' }}>⚠️</div>
            <h3 style={{ margin: '0 0 10px 0', color: '#ff4d4f', fontWeight: 'bold' }}>Message Blocked</h3>
            <p style={{ margin: '0 0 20px 0', color: '#595959', fontSize: '14px', lineHeight: '1.5' }}>
              {vulgarAlert}
            </p>
            <button
              onClick={() => setVulgarAlert(null)}
              style={{
                backgroundColor: '#ff4d4f',
                color: '#ffffff',
                border: 'none',
                padding: '10px 24px',
                borderRadius: '12px',
                fontSize: '14px',
                fontWeight: 'bold',
                cursor: 'pointer',
                transition: 'background-color 0.2s'
              }}
              onMouseOver={(e) => e.target.style.backgroundColor = '#d9363e'}
              onMouseOut={(e) => e.target.style.backgroundColor = '#ff4d4f'}
            >
              OK
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default GroupDetails;
