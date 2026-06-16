import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import apiClient from '../../core/network/apiClient';

function Profile() {
  const navigate = useNavigate();
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [isEditMode, setIsEditMode] = useState(false);
  const [saving, setSaving] = useState(false);
  
  // Form states (for edit mode)
  const [name, setName] = useState('');
  const [age, setAge] = useState('');
  const [height, setHeight] = useState('');
  const [weight, setWeight] = useState('');
  const [gender, setGender] = useState('Male');
  const [fitnessGoal, setFitnessGoal] = useState('Lose Weight');
  const [dailyCalorieGoal, setDailyCalorieGoal] = useState(2000);
  
  // Preference states (mocked)
  const [reminders, setReminders] = useState(true);
  const [metricUnits, setMetricUnits] = useState(true);
  
  // Logged stats (to display progress)
  const [todaySteps, setTodaySteps] = useState(0);
  const [waterMl, setWaterMl] = useState(0);

  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  const fetchProfileAndStats = async () => {
    try {
      const response = await apiClient.get('/profile');
      const data = response.data;
      if (data) {
        setProfile(data);
        setName(data.name || '');
        setAge(data.age || '');
        setHeight(data.height || '');
        setWeight(data.weight || '');
        setGender(data.gender || 'Male');
        setFitnessGoal(data.fitnessGoal || 'Lose Weight');
        setDailyCalorieGoal(data.dailyCalorieGoal || 2000);
      }

      // Fetch weekly steps to get today's actual steps from database
      try {
        const weeklyRes = await apiClient.get('/steps/weekly');
        const weeklyData = weeklyRes.data || [];
        const now = new Date();
        const y = now.getFullYear();
        const m = String(now.getMonth() + 1).padStart(2, '0');
        const d = String(now.getDate()).padStart(2, '0');
        const todayDash = `${y}-${m}-${d}`;
        const todayEntry = weeklyData.find((item) => item.date.substring(0, 10) === todayDash);
        setTodaySteps(todayEntry ? todayEntry.steps : 0);
      } catch (stepsErr) {
        console.error('Failed to load steps from database:', stepsErr);
        setTodaySteps(0);
      }

      const now = new Date();
      const todayStr = `${now.getFullYear()}_${String(now.getMonth() + 1).padStart(2, '0')}_${String(now.getDate()).padStart(2, '0')}`;
      const savedWater = localStorage.getItem(`water_intake_${todayStr}`);
      if (savedWater) setWaterMl(parseInt(savedWater, 10));
    } catch (err) {
      console.error(err);
      setError('Failed to fetch profile details.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProfileAndStats();
  }, []);

  const handleUpdate = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError('');
    setSuccessMsg('');

    try {
      const payload = {
        name: name.trim(),
        age: age ? parseInt(age, 10) : null,
        height: height ? parseFloat(height) : null,
        weight: weight ? parseFloat(weight) : null,
        gender,
        fitnessGoal,
        dailyCalorieGoal: dailyCalorieGoal ? parseInt(dailyCalorieGoal, 10) : null
      };

      const res = await apiClient.put('/profile', payload);
      setProfile(res.data);
      
      // Update water_goal in local storage
      if (dailyCalorieGoal) {
        localStorage.setItem('water_goal', dailyCalorieGoal);
      }

      setSuccessMsg('Profile updated successfully! ✨');
      setIsEditMode(false);
      window.scrollTo(0, 0);
      setTimeout(() => setSuccessMsg(''), 4000);
    } catch (err) {
      console.error(err);
      setError('Failed to update profile details.');
    } finally {
      setSaving(false);
    }
  };

  const handleLogout = () => {
    if (window.confirm('Are you sure you want to logout?')) {
      localStorage.removeItem('jwt_token');
      navigate('/login');
    }
  };

  // Mock Photo click helper
  const handleMockPhotoUpload = () => {
    alert('Mock Photo uploaded successfully! 📸');
  };

  // BMI calculator matching mobile logic
  const calculateBMI = () => {
    if (!profile || !profile.height || !profile.weight || profile.height <= 0 || profile.weight <= 0) return null;
    const bmiVal = profile.weight / ((profile.height / 100) * (profile.height / 100));
    
    let category = 'Normal';
    let color = 'var(--success)';
    let desc = 'Great job! You are in a healthy weight range. Maintain your active lifestyle!';
    
    if (bmiVal < 18.5) {
      category = 'Underweight';
      color = '#3b82f6'; // Blue
      desc = 'You should consider eating nutrient-rich foods to reach a healthy weight.';
    } else if (bmiVal >= 25 && bmiVal < 30) {
      category = 'Overweight';
      color = 'var(--orange)';
      desc = 'Adopting a balanced diet and regular cardio/strength sessions will help.';
    } else if (bmiVal >= 30) {
      category = 'Obese';
      color = 'var(--danger)';
      desc = 'Focus on portion control, tracking calorie limits, and consistent steps.';
    }
    
    return { value: bmiVal.toFixed(1), category, color, desc };
  };

  const bmi = calculateBMI();
  const streak = profile?.streakCount || 0;
  
  // Progress calculations
  const stepGoal = 10000;
  const stepProgress = Math.min(todaySteps / stepGoal, 1);
  const calProgress = profile ? Math.min((profile.caloriesConsumed || 0) / (profile.dailyCalorieGoal || 2000), 1) : 0;
  const waterProgress = Math.min(waterMl / (profile?.dailyCalorieGoal || 2000), 1);

  // Achievements Badges configuration
  const totalAccumulatedSteps = todaySteps;
  const achievements = [
    { title: 'Hydration Hero', desc: 'Logged water today', icon: '💧', unlocked: waterMl > 0, color: '#06b6d4' },
    { title: 'Step Pioneer', desc: 'Walked over 5,000 steps', icon: '🏃', unlocked: totalAccumulatedSteps >= 5000, color: '#3b82f6' },
    { title: 'Consistent Fit', desc: 'Active daily streak', icon: '⚡', unlocked: streak > 0, color: 'var(--danger)' },
    { title: 'Nutri-Tracker', desc: 'Logged calorie intake', icon: '🍽️', unlocked: (profile?.caloriesConsumed || 0) > 0, color: 'var(--orange)' }
  ];

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', padding: '60px 0', fontWeight: 'bold' }}>
        Loading profile configuration...
      </div>
    );
  }

  return (
    <div style={{ maxWidth: '640px', margin: '0 auto', textAlign: 'left' }}>
      
      {/* Toast Success Alert */}
      {successMsg && (
        <div style={{
          padding: '12px 16px',
          background: 'var(--success-light)',
          border: '1px solid rgba(52, 188, 157, 0.2)',
          borderRadius: '12px',
          color: 'var(--success)',
          fontWeight: 'bold',
          fontSize: '13px',
          marginBottom: '20px'
        }}>
          {successMsg}
        </div>
      )}

      {error && (
        <div className="error-banner">
          <span>{error}</span>
        </div>
      )}

      {/* Profile Header Block */}
      <div className="fit-card" style={{
        background: 'linear-gradient(135deg, var(--primary), #8B85FF)',
        color: 'white',
        padding: '30px',
        borderRadius: '24px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: '20px',
        marginBottom: '24px',
        boxShadow: '0 10px 24px rgba(108, 99, 255, 0.15)'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
          <div style={{ position: 'relative' }}>
            <div style={{
              width: '80px',
              height: '80px',
              borderRadius: '50%',
              backgroundColor: 'rgba(255, 255, 255, 0.2)',
              border: '3px solid white',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: '900',
              fontSize: '32px',
              fontFamily: 'var(--font-heading)'
            }}>
              {profile.name ? profile.name[0].toUpperCase() : profile.username[0]?.toUpperCase()}
            </div>
            <button 
              type="button"
              onClick={handleMockPhotoUpload}
              style={{
                position: 'absolute',
                bottom: 0,
                right: 0,
                background: 'var(--danger)',
                border: 'none',
                width: '24px',
                height: '24px',
                borderRadius: '50%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
                fontSize: '12px'
              }}
            >
              📷
            </button>
          </div>

          <div>
            <h3 style={{ fontSize: '20px', fontWeight: '800', fontFamily: 'var(--font-heading)' }}>
              {profile.name || profile.username}
            </h3>
            <span style={{ fontSize: '13px', color: 'rgba(255,255,255,0.85)' }}>{profile.email}</span>
          </div>
        </div>

        {!isEditMode && (
          <button 
            onClick={() => setIsEditMode(true)}
            style={{
              background: 'white',
              color: 'var(--primary)',
              border: 'none',
              padding: '10px 18px',
              borderRadius: '12px',
              fontWeight: '700',
              cursor: 'pointer',
              boxShadow: '0 4px 10px rgba(0,0,0,0.05)',
              display: 'flex',
              alignItems: 'center',
              gap: '6px'
            }}
          >
            ✏️ Edit Profile
          </button>
        )}
      </div>

      {/* DUAL MODE LOGIC RENDER */}
      {!isEditMode ? (
        /* ==================== READ ONLY VIEW MODE ==================== */
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          
          {/* Streak Banner */}
          <div className="fit-card" style={{
            background: streak > 0 ? 'var(--danger-light)' : 'white',
            border: streak > 0 ? '1px solid rgba(255, 133, 133, 0.3)' : '1px solid var(--border-color)',
            display: 'flex',
            alignItems: 'center',
            padding: '18px',
            gap: '16px',
            marginBottom: 0
          }}>
            <span style={{
              fontSize: '32px',
              background: streak > 0 ? 'rgba(255, 122, 122, 0.15)' : 'var(--light-grey)',
              width: '52px',
              height: '52px',
              borderRadius: '50%',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}>
              🔥
            </span>
            <div>
              <h4 style={{
                fontWeight: '800',
                color: streak > 0 ? '#D32F2F' : 'var(--dark)',
                fontSize: '15px'
              }}>
                {streak > 0 ? `${streak} Day Streak!` : 'No Active Streak'}
              </h4>
              <p style={{
                fontSize: '12px',
                color: streak > 0 ? 'rgba(229, 57, 53, 0.8)' : 'var(--grey-text)',
                marginTop: '2px'
              }}>
                {streak > 0 
                  ? 'You are doing great! Keep logging details daily.' 
                  : 'Track steps, food, and water to build a daily streak!'}
              </p>
            </div>
          </div>

          {/* Today's Progress details */}
          <div className="fit-card" style={{ padding: '20px', marginBottom: 0 }}>
            <h4 style={{ fontWeight: '800', fontSize: '15px', marginBottom: '16px' }}>Today's Progress</h4>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              {/* Steps */}
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', marginBottom: '6px' }}>
                  <span>🚶 Steps</span>
                  <span style={{ color: 'var(--grey-text)' }}>{todaySteps} / 10,000 steps</span>
                </div>
                <div style={{ height: '8px', background: 'var(--light-bg)', borderRadius: '4px', overflow: 'hidden' }}>
                  <div style={{ width: `${stepProgress * 100}%`, height: '100%', background: '#3b82f6', borderRadius: '4px' }}></div>
                </div>
              </div>

              {/* Calories */}
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', marginBottom: '6px' }}>
                  <span>🍴 Calories Eaten</span>
                  <span style={{ color: 'var(--grey-text)' }}>{Math.round(profile.caloriesConsumed || 0)} / {profile.dailyCalorieGoal || 2000} kcal</span>
                </div>
                <div style={{ height: '8px', background: 'var(--light-bg)', borderRadius: '4px', overflow: 'hidden' }}>
                  <div style={{ width: `${calProgress * 100}%`, height: '100%', background: 'var(--orange)', borderRadius: '4px' }}></div>
                </div>
              </div>

              {/* Water */}
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', marginBottom: '6px' }}>
                  <span>💧 Water Hydration</span>
                  <span style={{ color: 'var(--grey-text)' }}>{waterMl} / {profile.dailyCalorieGoal || 2000} ml</span>
                </div>
                <div style={{ height: '8px', background: 'var(--light-bg)', borderRadius: '4px', overflow: 'hidden' }}>
                  <div style={{ width: `${waterProgress * 100}%`, height: '100%', background: 'var(--secondary)', borderRadius: '4px' }}></div>
                </div>
              </div>
            </div>
          </div>

          {/* BMI Card */}
          {bmi && (
            <div className="fit-card" style={{ padding: '20px', marginBottom: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '14px' }}>
                <span style={{ fontSize: '18px' }}>⚖️</span>
                <strong style={{ fontSize: '15px' }}>Body Mass Index (BMI)</strong>
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: '10px', marginBottom: '6px' }}>
                <span style={{ fontSize: '32px', fontWeight: '900', fontFamily: 'var(--font-heading)' }}>{bmi.value}</span>
                <span style={{
                  padding: '2px 10px',
                  borderRadius: '10px',
                  backgroundColor: `${bmi.color}20`,
                  color: bmi.color,
                  fontWeight: 'bold',
                  fontSize: '13px'
                }}>
                  {bmi.category}
                </span>
              </div>
              <p style={{ fontSize: '12px', color: 'var(--grey-text)', lineHeight: '1.4' }}>{bmi.desc}</p>
            </div>
          )}

          {/* Achievements & Badges */}
          <div className="fit-card" style={{ padding: '20px', marginBottom: 0 }}>
            <h4 style={{ fontWeight: '800', fontSize: '15px', marginBottom: '16px' }}>Achievements & Badges</h4>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px', textAlign: 'center' }}>
              {achievements.map((ach) => (
                <div key={ach.title} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }} title={ach.desc}>
                  <div style={{
                    width: '48px',
                    height: '48px',
                    borderRadius: '50%',
                    backgroundColor: ach.unlocked ? `${ach.color}15` : 'var(--light-grey)',
                    border: `1.5px solid ${ach.unlocked ? ach.color : 'transparent'}`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '22px',
                    marginBottom: '6px'
                  }}>
                    {ach.unlocked ? ach.icon : '🔒'}
                  </div>
                  <span style={{
                    fontSize: '10px',
                    fontWeight: ach.unlocked ? '700' : '500',
                    color: ach.unlocked ? 'var(--dark)' : '#cbd5e1'
                  }}>
                    {ach.title}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Detail card list */}
          <div className="fit-card" style={{ padding: 0, overflow: 'hidden', marginBottom: 0 }}>
            {[
              { label: 'Age', value: `${profile.age || '--'} years` },
              { label: 'Height', value: `${profile.height || '--'} cm` },
              { label: 'Weight', value: `${profile.weight || '--'} kg` },
              { label: 'Gender', value: `${profile.gender || '--'}` }
            ].map((detail, index) => (
              <div 
                key={detail.label} 
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  padding: '16px 20px',
                  borderBottom: index < 3 ? '1px solid var(--border-color)' : 'none',
                  fontSize: '14px'
                }}
              >
                <span style={{ color: 'var(--grey-text)' }}>{detail.label}</span>
                <strong style={{ color: 'var(--dark)' }}>{detail.value}</strong>
              </div>
            ))}
          </div>

          {/* Fitness Goal display */}
          <div>
            <h4 style={{ fontWeight: '800', fontSize: '15px', marginBottom: '10px' }}>Fitness Goal</h4>
            <div style={{
              background: 'linear-gradient(90deg, var(--primary), #8B85FF)',
              color: 'white',
              padding: '16px 20px',
              borderRadius: '20px',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <span style={{ fontSize: '20px' }}>⭐</span>
                <strong style={{ fontSize: '16px' }}>{profile.fitnessGoal || 'Not Set'}</strong>
              </div>
              <span>➡️</span>
            </div>
          </div>

          {/* Settings preference card */}
          <div className="fit-card" style={{ padding: 0, overflow: 'hidden', marginBottom: 0 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 20px', borderBottom: '1px solid var(--border-color)', alignItems: 'center' }}>
              <div>
                <strong style={{ fontSize: '14px', display: 'block' }}>Daily Reminders</strong>
                <span style={{ fontSize: '11px', color: 'var(--grey-text)' }}>Get reminded to log steps, meals, & water</span>
              </div>
              <input 
                type="checkbox" 
                checked={reminders} 
                onChange={(e) => setReminders(e.target.checked)} 
                style={{ width: '40px', height: '20px', accentColor: 'var(--primary)', cursor: 'pointer' }}
              />
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 20px', alignItems: 'center' }}>
              <div>
                <strong style={{ fontSize: '14px', display: 'block' }}>Metric Units</strong>
                <span style={{ fontSize: '11px', color: 'var(--grey-text)' }}>Toggle kg/cm vs ft/lbs units</span>
              </div>
              <input 
                type="checkbox" 
                checked={metricUnits} 
                onChange={(e) => setMetricUnits(e.target.checked)} 
                style={{ width: '40px', height: '20px', accentColor: 'var(--primary)', cursor: 'pointer' }}
              />
            </div>
          </div>

          {/* Logout button */}
          <button 
            type="button" 
            onClick={handleLogout} 
            className="btn-danger" 
            style={{ width: '100%', padding: '14px', fontSize: '15px' }}
          >
            Logout session
          </button>
        </div>
      ) : (
        /* ==================== EDIT FORM VIEW MODE ==================== */
        <div className="fit-card" style={{ padding: '28px' }}>
          <h3 style={{ fontFamily: 'var(--font-heading)', fontSize: '18px', fontWeight: '800', marginBottom: '20px' }}>
            Edit Profile Settings
          </h3>
          <form onSubmit={handleUpdate}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
              <div className="form-group" style={{ gridColumn: 'span 2' }}>
                <label className="form-label">Full Name</label>
                <input
                  type="text"
                  className="form-input"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g. Bala Narasimhulu"
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Age</label>
                <input
                  type="number"
                  className="form-input"
                  value={age}
                  onChange={(e) => setAge(e.target.value)}
                  placeholder="Years"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Gender</label>
                <select 
                  className="form-input" 
                  value={gender}
                  onChange={(e) => setGender(e.target.value)}
                >
                  <option value="Male">Male</option>
                  <option value="Female">Female</option>
                  <option value="Other">Other</option>
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">Height (cm)</label>
                <input
                  type="number"
                  step="0.1"
                  className="form-input"
                  value={height}
                  onChange={(e) => setHeight(e.target.value)}
                  placeholder="cm"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Weight (kg)</label>
                <input
                  type="number"
                  step="0.1"
                  className="form-input"
                  value={weight}
                  onChange={(e) => setWeight(e.target.value)}
                  placeholder="kg"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Fitness Goal</label>
                <select 
                  className="form-input"
                  value={fitnessGoal}
                  onChange={(e) => setFitnessGoal(e.target.value)}
                >
                  <option value="Lose Weight">Lose Weight</option>
                  <option value="Build Muscle">Build Muscle</option>
                  <option value="Maintain Fitness">Maintain Fitness</option>
                  <option value="General Health">General Health</option>
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">Daily Calorie Goal (kcal)</label>
                <input
                  type="number"
                  className="form-input"
                  value={dailyCalorieGoal}
                  onChange={(e) => setDailyCalorieGoal(e.target.value)}
                  placeholder="kcal"
                />
              </div>
            </div>

            <div style={{ display: 'flex', gap: '12px', marginTop: '20px' }}>
              <button
                type="submit"
                className="auth-btn"
                disabled={saving}
                style={{ flex: 1, marginTop: 0 }}
              >
                {saving ? 'Saving changes...' : 'Save Settings'}
              </button>
              <button
                type="button"
                onClick={() => { setIsEditMode(false); setError(''); }}
                className="btn-secondary"
                style={{ padding: '0 24px' }}
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}

    </div>
  );
}

export default Profile;
