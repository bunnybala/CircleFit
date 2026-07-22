import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import apiClient from '../../core/network/apiClient';

function Dashboard() {
  const navigate = useNavigate();
  const [profile, setProfile] = useState(null);
  const [weeklyData, setWeeklyData] = useState([]);
  const [selectedBar, setSelectedBar] = useState(null);
  

  
  // Water tracker states
  const [waterMl, setWaterMl] = useState(0);
  const [waterGoal, setWaterGoal] = useState(2000);
  const [showWaterReset, setShowWaterReset] = useState(false);
  const [toastMessage, setToastMessage] = useState('');

  // Fetch all initial data
  const fetchData = async () => {
    try {
      // Get profile
      const profRes = await apiClient.get('/profile');
      setProfile(profRes.data);
      
      // Get weekly steps
      const weeklyRes = await apiClient.get('/steps/weekly');
      setWeeklyData(weeklyRes.data || []);

      // Get water intake log for today
      const waterRes = await apiClient.get('/water');
      if (waterRes.data) {
        setWaterMl(waterRes.data.amountMl || 0);
        if (waterRes.data.goalMl) {
          setWaterGoal(waterRes.data.goalMl);
        }
      }
    } catch (err) {
      console.error('Failed to load dashboard data:', err);
    }
  };

  useEffect(() => {
    fetchData();
    
    // Auto-refresh stats from the database every 10 seconds to sync mobile steps & water
    const interval = setInterval(fetchData, 10000);
    
    return () => clearInterval(interval);
  }, []);

  const getTodayDateKey = () => {
    const now = new Date();
    const y = now.getFullYear();
    const m = String(now.getMonth() + 1).padStart(2, '0');
    const d = String(now.getDate()).padStart(2, '0');
    return `${y}_${m}_${d}`;
  };

  const getTodayDateDash = () => {
    const now = new Date();
    const y = now.getFullYear();
    const m = String(now.getMonth() + 1).padStart(2, '0');
    const d = String(now.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  };

  const getTodaySteps = () => {
    const todayDash = getTodayDateDash();
    const todayEntry = weeklyData.find((d) => d.date.substring(0, 10) === todayDash);
    return todayEntry ? todayEntry.steps : 0;
  };

  const showToast = (msg) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(''), 3000);
  };

  const handleAddWater = async (ml) => {
    const todayStr = getTodayDateKey();
    const newVal = Math.min(waterMl + ml, 10000); // capped at 10L
    localStorage.setItem(`water_intake_${todayStr}`, newVal);
    setWaterMl(newVal);
    showToast(`Added ${ml}ml! 💧`);
    
    try {
      await apiClient.post('/water/log', { amountMl: newVal, goalMl: waterGoal });
    } catch (err) {
      console.error('Failed to log water:', err);
    }
  };

  const handleResetWater = async () => {
    const todayStr = getTodayDateKey();
    localStorage.setItem(`water_intake_${todayStr}`, 0);
    setWaterMl(0);
    setShowWaterReset(false);
    showToast('Water logs reset.');

    try {
      await apiClient.post('/water/reset');
    } catch (err) {
      console.error('Failed to reset water:', err);
    }
  };

  // Helper to get weekday name from date string or Date object
  const getWeekdayName = (dateInput) => {
    const date = new Date(dateInput);
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // getDay() is 0 for Sun, 1 for Mon, etc.
    let index = date.getDay() - 1;
    if (index < 0) index = 6;
    return weekdays[index];
  };

  // Compile weekly steps data to show exactly last 7 days
  const getCompletedWeeklyData = () => {
    const today = new Date();
    const map = {};
    weeklyData.forEach((d) => {
      const key = d.date.substring(0, 10);
      map[key] = d;
    });

    const completed = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      const key = date.toISOString().substring(0, 10);
      if (map[key]) {
        completed.push({
          date: key,
          steps: map[key].steps,
          calories: map[key].calories,
          distance: map[key].distance,
        });
      } else {
        completed.push({
          date: key,
          steps: 0,
          calories: 0,
          distance: 0,
        });
      }
    }
    return completed;
  };

  const formattedWeeklyData = getCompletedWeeklyData();
  const stepGoal = 10000;
  
  // Calculate average weekly steps
  const totalSteps = formattedWeeklyData.reduce((acc, cur) => acc + cur.steps, 0);
  const avgSteps = formattedWeeklyData.length ? Math.round(totalSteps / formattedWeeklyData.length) : 0;
  
  // Max scale to align graph heights
  const maxStepsInWeek = formattedWeeklyData.reduce((max, cur) => Math.max(max, cur.steps), 0);
  const maxScale = Math.max(maxStepsInWeek, stepGoal);

  // Time of day greeting
  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  };

  // BMR & Energy Calculations
  const calculateBMR = () => {
    if (!profile) return 1800;
    const { age, height, weight, gender } = profile;
    if (!age || !height || !weight) return 1800;
    
    // MSJ Equation
    if (gender && (gender.toLowerCase().startsWith('f') || gender.toLowerCase().startsWith('w'))) {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    } else {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    }
  };

  const bmr = calculateBMR();
  const todaySteps = getTodaySteps();
  const activeCalories = todaySteps * 0.04;
  const burned = bmr + activeCalories;
  const eaten = profile ? (profile.caloriesConsumed || 0) : 0;
  const netBalance = eaten - burned;
  const calorieGoal = profile ? (profile.dailyCalorieGoal || 2000) : 2000;

  // Macros (45% Carbs, 25% Protein, 30% Fats)
  const carbsGrams = (eaten * 0.45) / 4;
  const proteinGrams = (eaten * 0.25) / 4;
  const fatsGrams = (eaten * 0.30) / 9;

  const targetCarbs = (calorieGoal * 0.45) / 4;
  const targetProtein = (calorieGoal * 0.25) / 4;
  const targetFats = (calorieGoal * 0.30) / 9;

  // Gauge pointer: maps netBalance [-1000, 1000] to [-100%, 100%]
  const pointerPercent = Math.min(Math.max((netBalance / 1000) * 50, -50), 50);

  const stepProgress = Math.min(Math.max(todaySteps / stepGoal, 0), 1);
  const waterProgress = Math.min(Math.max(waterMl / waterGoal, 0), 1);

  if (!profile) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '80vh', fontWeight: 'bold' }}>
        Loading dashboard...
      </div>
    );
  }

  return (
    <div>
      {/* Toast Feedback */}
      {toastMessage && (
        <div style={{
          position: 'fixed',
          bottom: '80px',
          left: '50%',
          transform: 'translateX(-50%)',
          backgroundColor: 'var(--secondary)',
          color: 'white',
          padding: '12px 24px',
          borderRadius: '12px',
          fontWeight: 'bold',
          boxShadow: '0 4px 12px rgba(72,207,173,0.3)',
          zIndex: '999',
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
        }}>
          <svg width="18" height="18" fill="currentColor" viewBox="0 0 16 16">
            <path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0zm-3.97-3.03a.75.75 0 0 0-1.08.022L7.477 9.417 5.384 7.323a.75.75 0 0 0-1.06 1.06L6.97 11.03a.75.75 0 0 0 1.079-.02l3.992-4.99a.75.75 0 0 0-.01-1.05z"/>
          </svg>
          {toastMessage}
        </div>
      )}

      {/* Greeting Banner */}
      <div style={{ marginBottom: '28px' }}>
        <h2 style={{ fontSize: '24px', fontWeight: '800', fontFamily: 'var(--font-heading)' }}>
          Good {getGreeting()}, {profile.name || profile.username}! 👋
        </h2>
        <p style={{ color: 'var(--grey-text)', fontSize: '14px', marginTop: '4px' }}>
          Keep pushing your limits!
        </p>
      </div>

      {/* Main Dashboard Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '24px', maxWidth: '100%' }}>
        
        {/* Step progress banner */}
        <div className="fit-card" style={{
          background: 'linear-gradient(135deg, var(--primary), var(--secondary))',
          color: 'white',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          padding: '30px',
          textAlign: 'center',
          boxShadow: '0 10px 24px rgba(108, 99, 255, 0.25)'
        }}>
          <span style={{ fontSize: '15px', color: 'rgba(255,255,255,0.7)', fontWeight: '600' }}>Today's Steps</span>
          
          {/* Circular SVG progress */}
          <div style={{ position: 'relative', margin: '20px 0', width: '160px', height: '160px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="160" height="160" viewBox="0 0 100 100" style={{ transform: 'rotate(-90deg)' }}>
              <circle cx="50" cy="50" r="42" stroke="rgba(255,255,255,0.18)" strokeWidth="6" fill="transparent" />
              <circle cx="50" cy="50" r="42" stroke="white" strokeWidth="6" fill="transparent"
                strokeDasharray={2 * Math.PI * 42}
                strokeDashoffset={(1 - stepProgress) * (2 * Math.PI * 42)}
                strokeLinecap="round"
                style={{ transition: 'stroke-dashoffset 0.8s ease-in-out' }}
              />
            </svg>
            <div style={{ position: 'absolute', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
              <span style={{ fontSize: '38px', fontWeight: '800', fontFamily: 'var(--font-heading)' }}>{todaySteps}</span>
              <span style={{ fontSize: '12px', color: 'rgba(255,255,255,0.7)', fontWeight: '600' }}>of {stepGoal}</span>
            </div>
          </div>

          <div style={{ width: '100%', maxWidth: '300px', display: 'flex', flexDirection: 'column', gap: '6px' }}>
            <div style={{ height: '6px', background: 'rgba(255,255,255,0.2)', borderRadius: '10px', overflow: 'hidden' }}>
              <div style={{ width: `${stepProgress * 100}%`, height: '100%', background: 'white', borderRadius: '10px', transition: 'width 0.8s ease' }}></div>
            </div>
            <span style={{ fontSize: '12px', color: 'rgba(255,255,255,0.8)', fontWeight: '600' }}>
              {Math.round(stepProgress * 100)}% of daily goal
            </span>
          </div>
        </div>

        {/* Weekly activity card */}
        <div className="fit-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <svg width="24" height="24" fill="var(--primary)" viewBox="0 0 16 16">
                <path d="M4 11H2v3h2v-3zm5-4H7v7h2V7zm5-5v12h-2V2h2zm-2-1a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h2a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1h-2zM6 7a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v7a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V7zm-5 4a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1H2a1 1 0 0 1-1-1v-3z"/>
              </svg>
              <h3 style={{ fontSize: '16px', fontWeight: 'bold' }}>Weekly Activity</h3>
            </div>
            <span style={{ color: 'var(--secondary)', fontWeight: 'bold', fontSize: '12px' }}>
              Daily Avg: {avgSteps} steps
            </span>
          </div>

          {/* Interactive display bar selection details */}
          <div style={{
            background: 'var(--light-bg)',
            padding: '10px',
            borderRadius: '12px',
            textAlign: 'center',
            fontSize: '13px',
            fontWeight: '600',
            color: selectedBar !== null ? 'var(--primary)' : 'var(--grey-text)',
            marginBottom: '20px'
          }}>
            {selectedBar !== null ? (
              <span>
                {getWeekdayName(formattedWeeklyData[selectedBar].date)}: {formattedWeeklyData[selectedBar].steps} steps
              </span>
            ) : (
              <span>Click on any bar to see daily steps</span>
            )}
          </div>

          {/* Bar chart graphics */}
          <div style={{ display: 'flex', justifyContent: 'space-between', height: '140px', alignItems: 'flex-end', gap: '10px' }}>
            {formattedWeeklyData.map((d, index) => {
              const heightFactor = Math.max(d.steps / maxScale, 0.04);
              const isSelected = selectedBar === index;
              const reachedGoal = d.steps >= stepGoal;
              
              // Gradient styling mapping from mobile
              let background = 'linear-gradient(to top, #8B85FF, var(--primary))';
              if (isSelected) {
                background = 'linear-gradient(to top, var(--danger), var(--warning))';
              } else if (reachedGoal) {
                background = 'linear-gradient(to top, var(--secondary), var(--primary))';
              }

              return (
                <div 
                  key={index} 
                  style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', flex: 1, height: '100%', justifyContent: 'flex-end', cursor: 'pointer' }}
                  onClick={() => setSelectedBar(selectedBar === index ? null : index)}
                >
                  <div style={{
                    width: '100%',
                    height: '100%',
                    background: '#F0EFFF',
                    borderRadius: '8px',
                    position: 'relative',
                    overflow: 'hidden',
                    display: 'flex',
                    alignItems: 'flex-end'
                  }}>
                    <div style={{
                      width: '100%',
                      height: `${heightFactor * 100}%`,
                      background: background,
                      borderRadius: '8px',
                      boxShadow: isSelected ? '0 2px 8px rgba(255,133,133,0.4)' : 'none',
                      transition: 'height 0.5s cubic-bezier(0.25, 1, 0.5, 1)'
                    }}></div>
                  </div>
                  <span style={{
                    fontSize: '11px',
                    color: isSelected ? 'var(--primary)' : 'var(--grey-text)',
                    fontWeight: isSelected ? '700' : '500',
                    marginTop: '8px'
                  }}>
                    {getWeekdayName(d.date)}
                  </span>
                </div>
              );
            })}
          </div>
        </div>

        {/* Water Tracker Card */}
        <div className="fit-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <svg width="22" height="22" fill="var(--secondary)" viewBox="0 0 16 16">
                <path d="M8 16a6 6 0 0 0 6-6c0-1.667-1-3-1.5-4-.5-.667-1.25-1.5-1.5-2-.25-.5-.5-1-.75-1.5-.25.5-.5 1-.75 1.5-.25.5-1 1.333-1.5 2C7.5 7 6.5 8.333 6.5 10a6 6 0 0 0 6 6zM8 1a7 7 0 0 1 7 7c0 2.5-2 4.5-4.5 4.5S6 10.5 6 8a7 7 0 0 1 7-7z"/>
              </svg>
              <h3 style={{ fontSize: '16px', fontWeight: 'bold' }}>Hydration Tracker</h3>
            </div>
            <button 
              onClick={() => setShowWaterReset(true)}
              style={{ background: 'transparent', border: 'none', color: 'var(--grey-text)', cursor: 'pointer' }}
              title="Reset daily logs"
            >
              <svg width="18" height="18" fill="currentColor" viewBox="0 0 16 16">
                <path fillRule="evenodd" d="M8 3a5 5 0 1 0 4.546 2.914.5.5 0 0 1 .908-.417A6 6 0 1 1 8 2v1z"/>
                <path d="M8 4.466V.534a.25.25 0 0 1 .41-.192l2.36 1.966c.12.1.12.284 0 .384L8.41 4.658a.25.25 0 0 1-.41-.192z"/>
              </svg>
            </button>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '24px', flexWrap: 'wrap' }}>
            {/* Bubble layout with wave animation classes */}
            <div className="bubble-container">
              <div 
                className="bubble-waves" 
                style={{ 
                  '--wave-height': `${waterProgress * 100}%`,
                  height: `${waterProgress * 100}%` 
                }}
              ></div>
              <span 
                className="bubble-percent" 
                style={{ 
                  color: waterProgress > 0.45 ? 'white' : 'var(--primary)',
                }}
              >
                {Math.round(waterProgress * 100)}%
              </span>
            </div>

            {/* Actions & ML display */}
            <div style={{ flex: 1, textAlign: 'left' }}>
              <span style={{ fontSize: '28px', fontWeight: '800', fontFamily: 'var(--font-heading)' }}>{waterMl} ml</span>
              <span style={{ display: 'block', fontSize: '13px', color: 'var(--grey-text)', fontWeight: '500', marginTop: '2px' }}>
                Daily Goal: {waterGoal} ml
              </span>
              
              <div style={{ display: 'flex', gap: '10px', marginTop: '16px', maxWidth: '300px' }}>
                <button 
                  onClick={() => handleAddWater(250)}
                  style={{
                    flex: 1,
                    background: 'var(--primary-light)',
                    border: '1px solid rgba(108, 99, 255, 0.1)',
                    color: 'var(--primary)',
                    padding: '10px',
                    borderRadius: '12px',
                    fontWeight: 'bold',
                    fontSize: '12px',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '4px'
                  }}
                >
                  ☕ +250ml
                </button>
                <button 
                  onClick={() => handleAddWater(500)}
                  style={{
                    flex: 1,
                    background: 'var(--primary-light)',
                    border: '1px solid rgba(108, 99, 255, 0.1)',
                    color: 'var(--primary)',
                    padding: '10px',
                    borderRadius: '12px',
                    fontWeight: 'bold',
                    fontSize: '12px',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '4px'
                  }}
                >
                  🍼 +500ml
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Energy & Macronutrients */}
        <div className="fit-card" style={{ textAlign: 'left' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '20px' }}>
            <svg width="22" height="22" fill="var(--primary)" viewBox="0 0 16 16">
              <path d="M12 1a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1h8zM4 0a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2H4z"/>
              <path d="M8 4a.5.5 0 0 1 .5.5v3h3a.5.5 0 0 1 0 1h-3v3a.5.5 0 0 1-1 0v-3h-3a.5.5 0 0 1 0-1h3v-3A.5.5 0 0 1 8 4z"/>
            </svg>
            <h3 style={{ fontSize: '16px', fontWeight: 'bold' }}>Energy & Macronutrients</h3>
          </div>

          <span style={{ fontSize: '13px', fontWeight: '700', color: 'var(--grey-text)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
            Energy Balance
          </span>
          
          {/* Custom Drawn Slider scale matching CSS rules */}
          <div style={{ position: 'relative', marginTop: '16px', marginBottom: '10px' }}>
            <div style={{
              height: '14px',
              width: '100%',
              borderRadius: '7px',
              background: 'linear-gradient(90deg, var(--secondary) 10%, #FFF 50%, var(--danger) 90%)',
              border: '1px solid var(--border-color)',
            }}></div>
            
            {/* Center mark */}
            <div style={{
              position: 'absolute',
              top: '-3px',
              left: '50%',
              width: '3px',
              height: '20px',
              background: '#94a3b8',
              transform: 'translateX(-50%)'
            }}></div>

            {/* Float pointer needle */}
            <div style={{
              position: 'absolute',
              top: '-5px',
              left: `calc(50% + ${pointerPercent}%)`,
              width: '6px',
              height: '24px',
              background: 'var(--dark)',
              borderRadius: '3px',
              boxShadow: '0 2px 4px rgba(0,0,0,0.3)',
              transform: 'translateX(-50%)',
              transition: 'left 0.5s cubic-bezier(0.25, 1, 0.5, 1)'
            }}></div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
            <span style={{ color: 'var(--secondary)', fontSize: '11px', fontWeight: '700' }}>Deficit</span>
            <span style={{
              fontSize: '13px',
              fontWeight: '700',
              color: netBalance < 0 ? 'var(--secondary)' : netBalance > 0 ? 'var(--danger)' : 'var(--grey-text)'
            }}>
              {netBalance < 0 
                ? `${Math.round(Math.abs(netBalance))} kcal deficit` 
                : netBalance > 0 
                  ? `${Math.round(netBalance)} kcal surplus` 
                  : 'Perfectly balanced'}
            </span>
            <span style={{ color: 'var(--danger)', fontSize: '11px', fontWeight: '700' }}>Surplus</span>
          </div>

          <hr style={{ border: 'none', borderBottom: '1px solid var(--border-color)', marginBottom: '18px' }} />

          <span style={{ fontSize: '13px', fontWeight: '700', color: 'var(--grey-text)', textTransform: 'uppercase', letterSpacing: '0.5px', display: 'block', marginBottom: '16px' }}>
            Daily Macro Estimates
          </span>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            {/* Protein slider */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', marginBottom: '6px' }}>
                <span>Protein (25%)</span>
                <span style={{ color: 'var(--grey-text)' }}>{Math.round(proteinGrams)}g / {Math.round(targetProtein)}g</span>
              </div>
              <div style={{ height: '8px', background: 'var(--light-bg)', borderRadius: '4px', position: 'relative', overflow: 'hidden' }}>
                <div style={{
                  width: `${Math.min(Math.max((proteinGrams / targetProtein) * 100, 0), 100)}%`,
                  height: '100%',
                  background: 'var(--danger)',
                  borderRadius: '4px',
                  boxShadow: '0 1px 4px rgba(255,107,107,0.3)',
                  transition: 'width 0.5s ease'
                }}></div>
              </div>
            </div>

            {/* Carbs slider */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', marginBottom: '6px' }}>
                <span>Carbohydrates (45%)</span>
                <span style={{ color: 'var(--grey-text)' }}>{Math.round(carbsGrams)}g / {Math.round(targetCarbs)}g</span>
              </div>
              <div style={{ height: '8px', background: 'var(--light-bg)', borderRadius: '4px', position: 'relative', overflow: 'hidden' }}>
                <div style={{
                  width: `${Math.min(Math.max((carbsGrams / targetCarbs) * 100, 0), 100)}%`,
                  height: '100%',
                  background: 'var(--primary)',
                  borderRadius: '4px',
                  boxShadow: '0 1px 4px rgba(108,99,255,0.3)',
                  transition: 'width 0.5s ease'
                }}></div>
              </div>
            </div>

            {/* Fats slider */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: '600', marginBottom: '6px' }}>
                <span>Fats (30%)</span>
                <span style={{ color: 'var(--grey-text)' }}>{Math.round(fatsGrams)}g / {Math.round(targetFats)}g</span>
              </div>
              <div style={{ height: '8px', background: 'var(--light-bg)', borderRadius: '4px', position: 'relative', overflow: 'hidden' }}>
                <div style={{
                  width: `${Math.min(Math.max((fatsGrams / targetFats) * 100, 0), 100)}%`,
                  height: '100%',
                  background: 'var(--warning)',
                  borderRadius: '4px',
                  boxShadow: '0 1px 4px rgba(255,217,61,0.3)',
                  transition: 'width 0.5s ease'
                }}></div>
              </div>
            </div>
          </div>
        </div>

        {/* Dynamic Metric card grid */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', gap: '14px' }}>
          <div className="fit-card" style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', padding: '14px', marginBottom: 0 }}>
            <span style={{ color: 'var(--danger)', fontSize: '24px' }}>🔥</span>
            <span style={{ fontSize: '20px', fontWeight: '800', fontFamily: 'var(--font-heading)', marginTop: '10px' }}>
              {Math.round(activeCalories)}
            </span>
            <span style={{ fontSize: '11px', color: 'var(--grey-text)' }}>kcal</span>
            <span style={{ fontSize: '12px', color: 'var(--dark)', fontWeight: '600', marginTop: '4px' }}>Burned</span>
          </div>

          <div className="fit-card" style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', padding: '14px', marginBottom: 0 }}>
            <span style={{ color: 'var(--orange)', fontSize: '24px' }}>🍴</span>
            <span style={{ fontSize: '20px', fontWeight: '800', fontFamily: 'var(--font-heading)', marginTop: '10px' }}>
              {Math.round(eaten)}
            </span>
            <span style={{ fontSize: '11px', color: 'var(--grey-text)' }}>kcal</span>
            <span style={{ fontSize: '12px', color: 'var(--dark)', fontWeight: '600', marginTop: '4px' }}>Eaten</span>
          </div>

          <div className="fit-card" style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', padding: '14px', marginBottom: 0 }}>
            <span style={{ color: 'var(--secondary)', fontSize: '24px' }}>📍</span>
            <span style={{ fontSize: '20px', fontWeight: '800', fontFamily: 'var(--font-heading)', marginTop: '10px' }}>
              {(todaySteps * 0.000762).toFixed(2)}
            </span>
            <span style={{ fontSize: '11px', color: 'var(--grey-text)' }}>km</span>
            <span style={{ fontSize: '12px', color: 'var(--dark)', fontWeight: '600', marginTop: '4px' }}>Distance</span>
          </div>

          <div className="fit-card" style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', padding: '14px', marginBottom: 0 }}>
            <span style={{ color: 'var(--warning)', fontSize: '24px' }}>⚡</span>
            <span style={{ fontSize: '20px', fontWeight: '800', fontFamily: 'var(--font-heading)', marginTop: '10px' }}>
              {profile.streakCount || 0}
            </span>
            <span style={{ fontSize: '11px', color: 'var(--grey-text)' }}>days</span>
            <span style={{ fontSize: '12px', color: 'var(--dark)', fontWeight: '600', marginTop: '4px' }}>Streak</span>
          </div>
        </div>

        {/* Sync active banner */}
        <div style={{
          padding: '12px 16px',
          background: 'var(--success-light)',
          border: '1px solid rgba(52, 188, 157, 0.2)',
          borderRadius: '12px',
          display: 'flex',
          alignItems: 'center',
          gap: '10px',
          color: 'var(--success)',
          fontWeight: '600',
          fontSize: '13px'
        }}>
          <span>📶</span>
          <span>Step tracking is active · Syncs every 1 minute while open</span>
        </div>
      </div>

      {/* Floating Buttons in lower right */}
      <div style={{
        position: 'fixed',
        bottom: '24px',
        right: '24px',
        display: 'flex',
        flexDirection: 'column',
        gap: '12px',
        zIndex: '150'
      }}>
        <button 
          onClick={() => navigate('/food-search')}
          style={{
            background: 'var(--secondary)',
            color: 'white',
            border: 'none',
            padding: '12px 20px',
            borderRadius: '24px',
            fontWeight: 'bold',
            fontSize: '14px',
            boxShadow: '0 4px 12px rgba(72,207,173,0.3)',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '8px'
          }}
        >
          <span>🔍</span> Search Food
        </button>
        <button 
          onClick={() => navigate('/scanner')}
          style={{
            background: 'var(--primary)',
            color: 'white',
            border: 'none',
            padding: '12px 20px',
            borderRadius: '24px',
            fontWeight: 'bold',
            fontSize: '14px',
            boxShadow: '0 4px 12px rgba(108,99,255,0.3)',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '8px'
          }}
        >
          <span>📷</span> Scan Food
        </button>
      </div>

      {/* Water Reset Modal */}
      {showWaterReset && (
        <div className="modal-overlay">
          <div className="modal-content">
            <h3 className="modal-header">Reset Tracker?</h3>
            <p className="modal-body">
              Do you want to reset your daily water logs back to 0 ml?
            </p>
            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setShowWaterReset(false)}>Cancel</button>
              <button className="btn-danger" onClick={handleResetWater}>Reset</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Dashboard;
