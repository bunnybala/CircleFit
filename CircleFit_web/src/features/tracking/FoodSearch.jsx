import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import apiClient from '../../core/network/apiClient';

function FoodSearch() {
  const navigate = useNavigate();
  const [query, setQuery] = useState('');
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [addLoading, setAddLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSearch = async (e) => {
    if (e) e.preventDefault();
    if (!query.trim()) return;

    setLoading(true);
    setError('');
    setProducts([]);

    try {
      const response = await fetch(
        `https://world.openfoodfacts.org/cgi/search.pl?search_terms=${encodeURIComponent(
          query
        )}&search_simple=1&action=process&json=1&page_size=24`
      );
      if (!response.ok) {
        throw new Error('Search failed. Check your internet connection.');
      }
      const data = await response.json();
      setProducts(data.products || []);
      if (!data.products || data.products.length === 0) {
        setError('No products found matching your search.');
      }
    } catch (err) {
      console.error(err);
      setError('Search request failed. Please check your connection.');
    } finally {
      setLoading(false);
    }
  };

  const handleAddCalories = async (kcal) => {
    setAddLoading(true);
    try {
      // Fetch profile to get current consumed calories
      const profRes = await apiClient.get('/profile');
      const current = profRes.data.caloriesConsumed || 0;
      const updatedTotal = current + kcal;

      // Update backend profile
      await apiClient.put('/profile', {
        caloriesConsumed: updatedTotal,
      });

      // Close details and show alert
      setSelectedProduct(null);
      alert(`Successfully added ${Math.round(kcal)} kcal to your logs!`);
    } catch (err) {
      console.error('Failed to update calories:', err);
      alert('Failed to log calories. Please try again.');
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
      {/* Header with back navigation */}
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
        <h2 style={{ fontSize: '22px', fontWeight: '800', fontFamily: 'var(--font-heading)' }}>Search Food</h2>
      </div>

      {/* Search Input Container */}
      <div className="fit-card" style={{ padding: '16px' }}>
        <form onSubmit={handleSearch} style={{ display: 'flex', gap: '10px' }}>
          <input
            type="text"
            className="form-input"
            placeholder="e.g. Chicken, Apple, Oats..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            style={{ flex: 1, margin: 0 }}
          />
          <button 
            type="submit" 
            className="auth-btn" 
            style={{ width: 'auto', padding: '0 24px', marginTop: 0 }}
            disabled={loading}
          >
            {loading ? 'Searching...' : 'Search'}
          </button>
        </form>
      </div>

      {loading && (
        <div style={{
          height: '4px',
          width: '100%',
          background: 'var(--primary-light)',
          position: 'relative',
          overflow: 'hidden',
          borderRadius: '2px',
          marginBottom: '20px'
        }}>
          <div style={{
            position: 'absolute',
            height: '100%',
            width: '40%',
            backgroundColor: 'var(--primary)',
            animation: 'searching-bar 1.2s infinite linear'
          }}></div>
        </div>
      )}

      {/* Style for linear loader */}
      <style>{`
        @keyframes searching-bar {
          0% { left: -40%; }
          100% { left: 100%; }
        }
      `}</style>

      {error && (
        <div style={{ textAlign: 'center', color: 'var(--grey-text)', marginTop: '40px' }}>
          <span style={{ fontSize: '40px', display: 'block', marginBottom: '10px' }}>🔍❌</span>
          <p>{error}</p>
        </div>
      )}

      {/* Product Search Results List */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '12px' }}>
        {products.map((p) => (
          <div 
            key={p._id || p.code}
            onClick={() => setSelectedProduct(p)}
            className="fit-card"
            style={{
              display: 'flex',
              alignItems: 'center',
              padding: '14px',
              gap: '14px',
              cursor: 'pointer',
              marginBottom: 0,
              textAlign: 'left',
              hover: { backgroundColor: 'var(--light-grey)' }
            }}
          >
            <div style={{
              width: '60px',
              height: '60px',
              borderRadius: '10px',
              background: '#f3f4f6',
              overflow: 'hidden',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}>
              {p.image_front_url ? (
                <img src={p.image_front_url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
              ) : (
                <span style={{ fontSize: '24px' }}>🍔</span>
              )}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <h4 style={{ fontWeight: '700', fontSize: '15px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {p.product_name || 'Unknown Product'}
              </h4>
              <span style={{ fontSize: '12px', color: 'var(--grey-text)' }}>
                {p.brands || 'No brand info'}
              </span>
            </div>
            <span style={{ color: 'var(--grey-text)' }}>➡️</span>
          </div>
        ))}
      </div>

      {/* Empty State */}
      {!loading && products.length === 0 && !error && (
        <div style={{ textAlign: 'center', color: '#cbd5e1', padding: '60px 0' }}>
          <span style={{ fontSize: '70px', display: 'block', marginBottom: '16px' }}>🍽️</span>
          <p style={{ color: 'var(--grey-text)', fontSize: '15px', fontWeight: '500' }}>
            Search for any food to track calories
          </p>
        </div>
      )}

      {/* Product Details Sheet Overlay */}
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

              {/* Calorie balance banner */}
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
                  {addLoading ? 'Logging...' : 'Add 100g to Daily Logs'}
                </button>
              ) : (
                <p style={{ color: 'var(--danger)', fontSize: '13px', fontWeight: 'bold' }}>
                  Calorie details not available for this item
                </p>
              )}

              <button 
                onClick={() => setSelectedProduct(null)}
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
    </div>
  );
}

export default FoodSearch;
