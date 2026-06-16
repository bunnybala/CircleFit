import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import apiClient from '../../core/network/apiClient';

const SCAN_PRESETS = [
  { name: 'Oat Milk Barista Edition (Oatly)', barcode: '7394376616226', icon: '🥛' },
  { name: 'Coca Cola Original Taste', barcode: '5449000000996', icon: '🥤' },
  { name: 'Classic Nutella Hazelnut Spread', barcode: '3017620422003', icon: '🍫' },
];

function FoodScanner() {
  const navigate = useNavigate();
  const [barcode, setBarcode] = useState('');
  const [loading, setLoading] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [addLoading, setAddLoading] = useState(false);
  const [error, setError] = useState('');

  const fetchProduct = async (code) => {
    if (!code.trim()) return;

    setLoading(true);
    setError('');
    setSelectedProduct(null);

    try {
      const response = await fetch(`https://world.openfoodfacts.org/api/v2/product/${code}.json`);
      if (!response.ok) {
        throw new Error('Product not found in OpenFoodFacts.');
      }
      const data = await response.json();
      
      if (data.status === 1 && data.product) {
        setSelectedProduct(data.product);
      } else {
        setError('Product not found in OpenFoodFacts database.');
      }
    } catch (err) {
      console.error(err);
      setError('Failed to fetch product data. Check connection.');
    } finally {
      setLoading(false);
    }
  };

  const handleSearchSubmit = (e) => {
    e.preventDefault();
    fetchProduct(barcode);
  };

  const handlePresetClick = (code) => {
    setBarcode(code);
    fetchProduct(code);
  };

  const handleAddCalories = async (kcal) => {
    setAddLoading(true);
    try {
      const profRes = await apiClient.get('/profile');
      const current = profRes.data.caloriesConsumed || 0;
      const updatedTotal = current + kcal;

      await apiClient.put('/profile', {
        caloriesConsumed: updatedTotal,
      });

      setSelectedProduct(null);
      setBarcode('');
      alert(`Logged ${Math.round(kcal)} kcal successfully!`);
    } catch (err) {
      console.error(err);
      alert('Failed to log calories.');
    } finally {
      setAddLoading(false);
    }
  };

  const getProductKcal = (p) => {
    if (!p || !p.nutriments) return null;
    return p.nutriments['energy-kcal_100g'] || p.nutriments['energy-kcal'] || null;
  };

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '14px', marginBottom: '24px', textAlign: 'left' }}>
        <button 
          onClick={() => navigate('/')}
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
        <h2 style={{ fontSize: '22px', fontWeight: '800', fontFamily: 'var(--font-heading)' }}>Scan or Search Barcode</h2>
      </div>

      {/* Barcode Search Form */}
      <div className="fit-card" style={{ padding: '20px', textAlign: 'left' }}>
        <form onSubmit={handleSearchSubmit} style={{ display: 'flex', gap: '10px' }}>
          <input
            type="text"
            className="form-input"
            placeholder="Type barcode number manually (e.g. 7394376616226)"
            value={barcode}
            onChange={(e) => setBarcode(e.target.value)}
            style={{ flex: 1, margin: 0 }}
          />
          <button 
            type="submit" 
            className="auth-btn" 
            style={{ width: 'auto', padding: '0 24px', marginTop: 0 }}
            disabled={loading}
          >
            {loading ? 'Fetching...' : 'Fetch'}
          </button>
        </form>
      </div>

      {loading && (
        <div style={{ textAlign: 'center', margin: '20px 0' }}>
          <div style={{
            width: '32px',
            height: '32px',
            border: '3px solid var(--primary-light)',
            borderTop: '3px solid var(--primary)',
            borderRadius: '50%',
            animation: 'spin-scanner 0.8s infinite linear',
            margin: '0 auto'
          }}></div>
          <span style={{ fontSize: '12px', color: 'var(--grey-text)', display: 'block', marginTop: '10px' }}>
            Fetching product by barcode...
          </span>
        </div>
      )}

      <style>{`
        @keyframes spin-scanner {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      `}</style>

      {error && (
        <div style={{
          padding: '12px 16px',
          background: 'var(--danger-light)',
          border: '1px solid rgba(255,133,133,0.3)',
          color: 'var(--danger)',
          borderRadius: '12px',
          fontSize: '13px',
          fontWeight: '600',
          marginBottom: '20px',
          textAlign: 'left'
        }}>
          ⚠️ {error}
        </div>
      )}

      {/* Scanner Visualizer Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '24px' }}>
        
        {/* Mock Live Camera Frame */}
        <div className="fit-card" style={{
          background: '#0f172a',
          color: 'white',
          height: '300px',
          borderRadius: '24px',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          position: 'relative',
          overflow: 'hidden'
        }}>
          {/* Glowing Green Scanning frame overlay */}
          <div style={{
            width: '220px',
            height: '160px',
            border: '3px solid var(--secondary)',
            borderRadius: '16px',
            position: 'relative',
            boxShadow: '0 0 15px rgba(72,207,173,0.3)'
          }}>
            {/* Animated Laser beam */}
            <div style={{
              position: 'absolute',
              left: 0,
              width: '100%',
              height: '3px',
              backgroundColor: 'var(--secondary)',
              boxShadow: '0 0 10px var(--secondary)',
              top: '50%',
              animation: 'scanner-laser 2.5s infinite ease-in-out'
            }}></div>
          </div>

          <span style={{
            position: 'absolute',
            bottom: '24px',
            fontSize: '13px',
            fontWeight: 'bold',
            color: 'rgba(255,255,255,0.7)',
            textShadow: '0 1px 2px black'
          }}>
            Center Barcode inside the frame overlay
          </span>
        </div>

        {/* Quick presets for barcode templates */}
        <div className="fit-card" style={{ textAlign: 'left' }}>
          <h3 style={{ fontSize: '15px', fontWeight: 'bold', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span>⚡</span> Quick Barcode Simulator
          </h3>
          <p style={{ color: 'var(--grey-text)', fontSize: '13px', marginBottom: '16px' }}>
            Select a preset item below to simulate pointing the camera at a real product barcode.
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {SCAN_PRESETS.map((item, idx) => (
              <div 
                key={idx}
                onClick={() => handlePresetClick(item.barcode)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  padding: '12px 16px',
                  borderRadius: '12px',
                  background: 'var(--light-bg)',
                  border: '1px solid var(--border-color)',
                  cursor: 'pointer',
                  justifyContent: 'space-between'
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <span style={{ fontSize: '20px' }}>{item.icon}</span>
                  <div>
                    <strong style={{ fontSize: '14px', display: 'block' }}>{item.name}</strong>
                    <code style={{ fontSize: '11px', background: 'transparent', padding: 0 }}>{item.barcode}</code>
                  </div>
                </div>
                <span style={{ fontSize: '12px', color: 'var(--primary)', fontWeight: 'bold' }}>Simulate ➡️</span>
              </div>
            ))}
          </div>
        </div>

      </div>

      {/* Product Details Sheet */}
      {selectedProduct && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '440px', padding: '24px' }}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
              <div style={{
                width: '100%',
                height: '180px',
                borderRadius: '16px',
                background: '#f9fafb',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                overflow: 'hidden',
                marginBottom: '20px'
              }}>
                {selectedProduct.image_front_url ? (
                  <img src={selectedProduct.image_front_url} alt="" style={{ height: '100%', maxWidth: '100%', objectFit: 'contain' }} />
                ) : (
                  <span style={{ fontSize: '60px' }}>🍔</span>
                )}
              </div>
              
              <h3 style={{ fontFamily: 'var(--font-heading)', fontSize: '20px', fontWeight: '800' }}>
                {selectedProduct.product_name || 'Unknown Product'}
              </h3>
              <span style={{ color: 'var(--grey-text)', fontSize: '13px', margin: '4px 0 20px 0' }}>
                {selectedProduct.brands || 'Unknown Brand'}
              </span>

              <div style={{
                background: 'var(--primary-light)',
                padding: '16px',
                borderRadius: '16px',
                width: '100%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '8px',
                color: 'var(--primary)',
                fontWeight: 'bold',
                fontSize: '17px',
                marginBottom: '28px'
              }}>
                <span>🔥</span>
                <span>
                  {getProductKcal(selectedProduct) !== null
                    ? `${getProductKcal(selectedProduct).toFixed(1)} kcal / 100g`
                    : 'Calories unknown'}
                </span>
              </div>

              {getProductKcal(selectedProduct) !== null ? (
                <button
                  onClick={() => handleAddCalories(getProductKcal(selectedProduct))}
                  className="auth-btn"
                  style={{ width: '100%', marginTop: 0 }}
                  disabled={addLoading}
                >
                  {addLoading ? 'Logging...' : 'Add 100g to Daily Calories'}
                </button>
              ) : (
                <p style={{ color: 'var(--danger)', fontSize: '13px', fontWeight: 'bold' }}>
                  Calorie details not available for this item
                </p>
              )}

              <button 
                onClick={() => { setSelectedProduct(null); setBarcode(''); }}
                style={{
                  background: 'transparent',
                  border: 'none',
                  color: 'var(--grey-text)',
                  fontSize: '14px',
                  fontWeight: '600',
                  marginTop: '16px',
                  cursor: 'pointer'
                }}
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Laser line animation keyframes */}
      <style>{`
        @keyframes scanner-laser {
          0% { top: 5%; }
          50% { top: 90%; }
          100% { top: 5%; }
        }
      `}</style>
    </div>
  );
}

export default FoodScanner;
