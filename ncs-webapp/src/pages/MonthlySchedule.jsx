import React, { useState, useEffect } from 'react';
import { Calendar, Ship, MapPin, TrendingUp, BarChart3, Clock, Layers, Activity, Loader, AlertCircle } from 'lucide-react';
import { getApiEndpoint } from '../config';

const MonthlySchedule = () => {
  const [activeTab, setActiveTab] = useState('dashboard'); // 'dashboard' or 'list'
  
  const [ships, setShips] = useState([]);
  const [voyages, setVoyages] = useState([]);
  const [aggregateLoads, setAggregateLoads] = useState([]);
  const [detailedLoads, setDetailedLoads] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [selectedMonthKey, setSelectedMonthKey] = useState('');
  const [selectedVessel, setSelectedVessel] = useState('Todos');
  const [wfsActiveVessel, setWfsActiveVessel] = useState('GUSTAVO U');

  // Responsividad dinámica en JS/React
  const [isDesktop, setIsDesktop] = useState(window.innerWidth >= 1200);
  const [isTablet, setIsTablet] = useState(window.innerWidth >= 768 && window.innerWidth < 1200);

  useEffect(() => {
    const handleResize = () => {
      setIsDesktop(window.innerWidth >= 1200);
      setIsTablet(window.innerWidth >= 768 && window.innerWidth < 1200);
    };
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  // Tooltips individuales para cada gráfico
  const [hoveredBar1, setHoveredBar1] = useState(null);
  const [hoveredPoint2, setHoveredPoint2] = useState(null);
  const [hoveredBar4, setHoveredBar4] = useState(null);
  const [hoveredBar5, setHoveredBar5] = useState(null);

  // Fetch API v1 endpoints
  useEffect(() => {
    const fetchScheduleData = async () => {
      try {
        setLoading(true);
        setError(null);

        const token = localStorage.getItem('ncsToken');
        const headers = {
          'Content-Type': 'application/json'
        };
        if (token) {
          headers['Authorization'] = `Token ${token}`;
        }

        const [shipsRes, voyagesRes, aggRes, detailedRes] = await Promise.all([
          fetch(getApiEndpoint('/api/v1/ships/'), { headers }),
          fetch(getApiEndpoint('/api/v1/voyages/'), { headers }),
          fetch(getApiEndpoint('/api/v1/operation-charges-chart/'), { headers }),
          fetch(getApiEndpoint('/api/v1/operation-charges-chart/?detailed=1'), { headers })
        ]);

        if (!shipsRes.ok || !voyagesRes.ok || !aggRes.ok || !detailedRes.ok) {
          throw new Error('Error al conectar con la API de operaciones y cargas.');
        }

        const shipsData = await shipsRes.json();
        const voyagesData = await voyagesRes.json();
        const aggData = await aggRes.json();
        const detailedData = await detailedRes.json();

        setShips(shipsData.filter(s => s.active));
        setVoyages(voyagesData);
        setAggregateLoads(aggData);
        setDetailedLoads(detailedData);

      } catch (err) {
        console.error('Error fetching schedule data:', err);
        setError(err.message || 'No se pudieron recuperar los datos de programación mensual.');
      } finally {
        setLoading(false);
      }
    };

    fetchScheduleData();
  }, []);

  const getShipTheme = (shipName) => {
    switch(shipName) {
      case 'ALFA C': return { border: '#0284c7', bg: 'rgba(2, 132, 199, 0.15)' }; // Azul
      case 'NANY': return { border: '#ea580c', bg: 'rgba(234, 88, 12, 0.15)' }; // Naranja
      case 'GUSTAVO U': return { border: '#64748B', bg: 'rgba(100, 116, 139, 0.15)' }; // Gris
      default: return { border: 'var(--ncs-accent)', bg: 'rgba(0, 240, 255, 0.1)' };
    }
  };

  // Helper to normalize sheet name and map to a sortable key and formatted label
  const normalizeSheetName = (sheetName) => {
    if (!sheetName) return null;
    const cleaned = sheetName.trim().toUpperCase().replace(/\s+/g, ' ');
    if (cleaned === 'ZC' || cleaned === 'LUCIANO' || cleaned === '') return null;
    
    // Extract year (2024, 2025, 2026, or 24, 25, 26)
    let year = null;
    const yearMatch = cleaned.match(/\b(202\d|2\d)\b/);
    if (yearMatch) {
      year = yearMatch[1];
      if (year.length === 2) year = '20' + year;
    } else {
      year = '2025';
    }
    
    const monthsArr = [
      { name: 'ENERO', num: '01', label: 'Enero' },
      { name: 'FEBRERO', num: '02', label: 'Febrero' },
      { name: 'MARZO', num: '03', label: 'Marzo' },
      { name: 'ABRIL', num: '04', label: 'Abril' },
      { name: 'MAYO', num: '05', label: 'Mayo' },
      { name: 'JUNIO', num: '06', label: 'Junio' },
      { name: 'JULIO', num: '07', label: 'Julio' },
      { name: 'AGOSTO', num: '08', label: 'Agosto' },
      { name: 'SEPTIEMBRE', num: '09', label: 'Septiembre' },
      { name: 'OCTUBRE', num: '10', label: 'Octubre' },
      { name: 'NOVIEMBRE', num: '11', label: 'Noviembre' },
      { name: 'DICIEMBRE', num: '12', label: 'Diciembre' }
    ];
    
    let monthObj = null;
    for (const m of monthsArr) {
      if (cleaned.includes(m.name)) {
        monthObj = m;
        break;
      }
    }
    
    if (!monthObj) return null;
    
    return {
      original: sheetName,
      label: `${monthObj.label} ${year}`,
      key: `${year}-${monthObj.num}`,
      year: parseInt(year),
      monthNum: monthObj.num
    };
  };

  // Populate dynamic month list from voyages
  const uniqueMonths = React.useMemo(() => {
    const monthsMap = {};
    voyages.forEach(v => {
      const norm = normalizeSheetName(v.sheet_name);
      if (norm) {
        monthsMap[norm.key] = norm;
      }
    });
    return Object.values(monthsMap).sort((a, b) => b.key.localeCompare(a.key));
  }, [voyages]);

  // Set default selected month to the latest month
  useEffect(() => {
    if (uniqueMonths.length > 0 && !selectedMonthKey) {
      setSelectedMonthKey(uniqueMonths[0].key);
    }
  }, [uniqueMonths, selectedMonthKey]);

  const selectedMonthLabel = React.useMemo(() => {
    const found = uniqueMonths.find(m => m.key === selectedMonthKey);
    return found ? found.label : 'Período';
  }, [uniqueMonths, selectedMonthKey]);

  // Vessels Filter options
  const vesselsList = React.useMemo(() => {
    return ['Todos', ...ships.map(s => s.description)];
  }, [ships]);

  // Parse voyages for the selected month
  const parsedSchedules = React.useMemo(() => {
    if (!selectedMonthKey) return [];
    
    const currentMonthVoyages = voyages.filter(v => {
      const norm = normalizeSheetName(v.sheet_name);
      return norm && norm.key === selectedMonthKey;
    });

    return currentMonthVoyages.map(voyage => {
      const records = voyage.records_detail || [];
      if (records.length === 0) return null;
      
      let minStart = null;
      let maxEnd = null;
      let stages = [];
      let totalLoad = 0;
      let cargoTypes = new Set();
      
      records.forEach(r => {
        if (r.start_date_time) {
          const d = new Date(r.start_date_time);
          if (!minStart || d < minStart) minStart = d;
        }
        if (r.end_date_time) {
          const d = new Date(r.end_date_time);
          if (!maxEnd || d > maxEnd) maxEnd = d;
        }
        if (r.stage) {
          stages.push(r.stage);
        }
        if (r.load) {
          totalLoad += r.load;
        }
        if (r.observations && r.observations.trim()) {
          cargoTypes.add(r.observations.trim());
        }
      });

      // Deduplicate consecutive stages
      const cleanStages = [];
      stages.forEach(st => {
        if (cleanStages.length === 0 || cleanStages[cleanStages.length - 1] !== st) {
          cleanStages.push(st);
        }
      });
      
      const route = cleanStages.join(' ➔ ') || 'Navegación / Puerto';
      
      const formatDate = (date) => {
        if (!date || isNaN(date.getTime())) return '';
        const day = date.getDate().toString().padStart(2, '0');
        const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
        const monthName = months[date.getMonth()];
        return `${day} ${monthName}`;
      };

      const dates = minStart && maxEnd 
        ? `${formatDate(minStart)} - ${formatDate(maxEnd)}` 
        : 'Fecha no especificada';

      const now = new Date();
      let status = 'Planificado';
      let progress = 0;
      if (maxEnd && maxEnd < now) {
        status = 'Completado';
        progress = 100;
      } else if (minStart && minStart > now) {
        status = 'Planificado';
        progress = 0;
      } else if (minStart && maxEnd) {
        status = 'En Tránsito';
        const totalDuration = maxEnd - minStart;
        const elapsed = now - minStart;
        progress = totalDuration > 0 ? Math.min(99, Math.max(1, Math.round((elapsed / totalDuration) * 100))) : 50;
      }

      const cargoObs = Array.from(cargoTypes).slice(0, 3).join(', ');
      const cargoSummary = totalLoad > 0 
        ? `${totalLoad.toLocaleString('es-AR', { maximumFractionDigits: 1 })} tons${cargoObs ? ` (${cargoObs})` : ''}`
        : cargoObs || 'Sin carga especificada';

      return {
        id: voyage.id,
        vessel: voyage.ship_detail?.description || `Ship #${voyage.ship}`,
        route,
        dates,
        status,
        progress,
        cargo: cargoSummary,
        crew: 'Cap. y Oficiales NCS'
      };
    }).filter(Boolean);
  }, [voyages, selectedMonthKey]);

  const filteredSchedules = parsedSchedules.filter(
    (item) => selectedVessel === 'Todos' || item.vessel === selectedVessel
  );

  // Chart 1: Raizen (Alfa C) Daily Loads
  const chart1Data = React.useMemo(() => {
    if (!selectedMonthKey) return [];
    
    const dailySums = {};
    detailedLoads.forEach(d => {
      if (!d.date_applied || d.ship !== 'ALFA C' || d.client !== 'Raizen') return;
      const dateStr = d.date_applied.substring(0, 10);
      const entryMonthKey = d.date_applied.substring(0, 7);
      if (entryMonthKey !== selectedMonthKey) return;
      
      const val = ((d.total_lsfo || 0) + (d.total_mgo || 0)) / 1000;
      dailySums[dateStr] = (dailySums[dateStr] || 0) + val;
    });
    
    return Object.keys(dailySums).sort().map(dateStr => {
      const [_, mm, dd] = dateStr.split('-');
      return {
        label: `${dd}/${mm}`,
        value: Math.round(dailySums[dateStr] * 100) / 100
      };
    });
  }, [detailedLoads, selectedMonthKey]);

  const getChart1Scale = React.useMemo(() => {
    const maxVal = Math.max(...chart1Data.map(d => d.value), 4.0);
    const limit = Math.ceil(maxVal);
    const ticks = [];
    for (let i = 0; i <= 4; i++) {
      ticks.push((limit / 4) * i);
    }
    return { limit, ticks };
  }, [chart1Data]);

  // Chart 4: WFS Daily Loads
  const chart4Data = React.useMemo(() => {
    if (!selectedMonthKey) return [];
    
    const dailySums = {};
    detailedLoads.forEach(d => {
      if (!d.date_applied || d.ship !== wfsActiveVessel || d.client !== 'WFS') return;
      const dateStr = d.date_applied.substring(0, 10);
      const entryMonthKey = d.date_applied.substring(0, 7);
      if (entryMonthKey !== selectedMonthKey) return;
      
      const val = ((d.total_lsfo || 0) + (d.total_mgo || 0)) / 1000;
      dailySums[dateStr] = (dailySums[dateStr] || 0) + val;
    });
    
    return Object.keys(dailySums).sort().map(dateStr => {
      const [_, mm, dd] = dateStr.split('-');
      return {
        label: `${dd}/${mm}`,
        value: Math.round(dailySums[dateStr] * 100) / 100
      };
    });
  }, [detailedLoads, selectedMonthKey, wfsActiveVessel]);

  const getChart4Scale = React.useMemo(() => {
    const maxVal = Math.max(...chart4Data.map(d => d.value), 3.0);
    const limit = Math.ceil(maxVal * 2) / 2;
    const ticks = [];
    for (let i = 0; i <= 4; i++) {
      ticks.push((limit / 4) * i);
    }
    return { limit, ticks };
  }, [chart4Data]);

  // Chart 2: Annual aggregated loads
  const chart2Data = React.useMemo(() => {
    const monthlySums = {};
    detailedLoads.forEach(d => {
      if (!d.date_applied) return;
      const month = d.date_applied.substring(0, 7);
      const totalVal = ((d.total_lsfo || 0) + (d.total_mgo || 0)) / 1000;
      monthlySums[month] = (monthlySums[month] || 0) + totalVal;
    });
    
    const sorted = Object.keys(monthlySums).sort().map(month => ({
      month,
      val: Math.round(monthlySums[month] * 10) / 10
    }));
    
    return sorted.slice(-15);
  }, [detailedLoads]);

  const getChart2Scale = React.useMemo(() => {
    if (chart2Data.length === 0) return { limit: 60, ticks: [0, 10, 20, 30, 40, 50, 60], stepX: 25 };
    const maxVal = Math.max(...chart2Data.map(d => d.val), 60);
    const limit = Math.ceil(maxVal / 10) * 10;
    const ticks = [];
    for (let i = 0; i <= 6; i++) {
      ticks.push((limit / 6) * i);
    }
    const stepX = (480 - 60) / Math.max(1, chart2Data.length - 1);
    return { limit, ticks, stepX };
  }, [chart2Data]);

  // Chart 5: Aggregate ship totals
  const chart5Data = React.useMemo(() => {
    return aggregateLoads.map(item => ({
      ship: item.ship,
      total_ships: item.total_ships || 0
    }));
  }, [aggregateLoads]);

  const getChart5Scale = React.useMemo(() => {
    if (chart5Data.length === 0) return { limit: 25, ticks: [0, 5, 10, 15, 20, 25] };
    const maxVal = Math.max(...chart5Data.map(d => d.total_ships), 25);
    const limit = Math.ceil(maxVal / 50) * 50;
    const ticks = [];
    for (let i = 0; i <= 5; i++) {
      ticks.push((limit / 5) * i);
    }
    return { limit, ticks };
  }, [chart5Data]);

  // Cargas Programadas (Card 3 totals)
  const cargasProgramadas = React.useMemo(() => {
    let raizenTotal = 0;
    let wfsTotal = 0;
    let raizenLimit = 17.5;
    let wfsLimit = 15.0;
    
    detailedLoads.forEach(d => {
      if (!d.date_applied) return;
      const entryMonthKey = d.date_applied.substring(0, 7);
      if (entryMonthKey !== selectedMonthKey) return;
      
      const val = ((d.total_lsfo || 0) + (d.total_mgo || 0)) / 1000;
      if (d.client === 'Raizen') {
        raizenTotal += val;
        if (d.limit) raizenLimit = d.limit / 1000;
      } else if (d.client === 'WFS') {
        wfsTotal += val;
      }
    });
    
    return {
      raizen: {
        total: Math.round(raizenTotal * 100) / 100,
        limit: raizenLimit,
        progress: raizenLimit > 0 ? Math.min(100, Math.round((raizenTotal / raizenLimit) * 100)) : 0
      },
      wfs: {
        total: Math.round(wfsTotal * 100) / 100,
        limit: wfsLimit,
        progress: wfsLimit > 0 ? Math.min(100, Math.round((wfsTotal / wfsLimit) * 100)) : 0
      }
    };
  }, [detailedLoads, selectedMonthKey]);

  const getStatusColor = (status) => {
    switch (status) {
      case 'Completado':
        return { text: '#00ff66', bg: 'rgba(0, 255, 102, 0.1)', border: 'rgba(0, 255, 102, 0.3)' };
      case 'En Tránsito':
        return { text: '#00f0ff', bg: 'rgba(0, 240, 255, 0.1)', border: 'rgba(0, 240, 255, 0.3)' };
      case 'Mantenimiento':
        return { text: '#ffcc00', bg: 'rgba(255, 204, 0, 0.1)', border: 'rgba(255, 204, 0, 0.3)' };
      default:
        return { text: '#94a3b8', bg: 'rgba(148, 163, 184, 0.1)', border: 'rgba(148, 163, 184, 0.2)' };
    }
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '80vh', gap: '16px', color: 'var(--text-secondary)' }}>
        <Loader size={36} className="animate-spin" color="var(--ncs-accent)" />
        <span>Cargando programación mensual...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '80vh', padding: '20px', textAlign: 'center', color: 'var(--text-secondary)' }}>
        <AlertCircle size={40} color="var(--ncs-danger)" style={{ marginBottom: '12px' }} />
        <h3 style={{ color: 'var(--text-primary)', marginBottom: '8px' }}>Error de conexión</h3>
        <p style={{ maxWidth: '400px', fontSize: '14px', marginBottom: '20px' }}>{error}</p>
        <button 
          onClick={() => window.location.reload()} 
          style={{ padding: '8px 16px', borderRadius: '8px', border: 'none', background: 'var(--ncs-primary)', color: '#fff', cursor: 'pointer', fontWeight: 'bold' }}
        >
          Reintentar
        </button>
      </div>
    );
  }

  return (
    <div style={{ paddingBottom: '30px' }}>
      
      {/* HEADER PREMIUM */}
      <div className="top-header glass" style={{ 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'center',
        padding: 'calc(12px + var(--safe-area-top)) 24px 12px'
      }}>
        <span>Programación Mensual</span>
        
        {/* Switcher de Vista */}
        <div style={{
          display: 'flex',
          gap: '4px',
          background: 'rgba(15, 23, 42, 0.6)',
          padding: '4px',
          borderRadius: '10px',
          border: '1px solid rgba(255,255,255,0.05)'
        }}>
          <button
            onClick={() => setActiveTab('dashboard')}
            style={{
              padding: '6px 14px',
              borderRadius: '7px',
              border: 'none',
              background: activeTab === 'dashboard' ? 'linear-gradient(135deg, #00f0ff 0%, #0072ff 100%)' : 'transparent',
              color: activeTab === 'dashboard' ? '#ffffff' : 'var(--text-secondary)',
              fontSize: '12px',
              fontWeight: 'bold',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              transition: 'all 0.2s ease'
            }}
          >
            <BarChart3 size={14} />
            Estadísticas
          </button>
          <button
            onClick={() => setActiveTab('list')}
            style={{
              padding: '6px 14px',
              borderRadius: '7px',
              border: 'none',
              background: activeTab === 'list' ? 'linear-gradient(135deg, #00f0ff 0%, #0072ff 100%)' : 'transparent',
              color: activeTab === 'list' ? '#ffffff' : 'var(--text-secondary)',
              fontSize: '12px',
              fontWeight: 'bold',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              transition: 'all 0.2s ease'
            }}
          >
            <Layers size={14} />
            Viajes Programados
          </button>
        </div>
      </div>

      <div style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '16px' }}>

        {/* Global Month Selector */}
        {uniqueMonths.length > 0 && (
          <div style={{ display: 'flex', gap: '8px', overflowX: 'auto', paddingBottom: '8px', scrollbarWidth: 'none' }}>
            {uniqueMonths.map((m) => (
              <button
                key={m.key}
                onClick={() => setSelectedMonthKey(m.key)}
                style={{
                  flex: '0 0 auto',
                  padding: '10px 18px',
                  borderRadius: '20px',
                  border: selectedMonthKey === m.key ? '1px solid var(--ncs-accent)' : '1px solid rgba(255,255,255,0.1)',
                  background: selectedMonthKey === m.key ? 'linear-gradient(135deg, rgba(0, 240, 255, 0.2), rgba(0, 136, 255, 0.2))' : 'rgba(16, 23, 42, 0.6)',
                  color: selectedMonthKey === m.key ? 'var(--ncs-accent)' : 'var(--text-secondary)',
                  fontWeight: '600',
                  fontSize: '14px',
                  cursor: 'pointer',
                  transition: 'all 0.3s ease',
                  boxShadow: selectedMonthKey === m.key ? '0 0 10px var(--ncs-accent-glow)' : 'none'
                }}
              >
                {m.label}
              </button>
            ))}
          </div>
        )}

        {/* ============================================== */}
        {/* VISTA 1: CONTROL DASHBOARD DE GRÁFICOS (Estadísticas) */}
        {/* ============================================== */}
        {activeTab === 'dashboard' && (
          <div>
            
            {/* SVG Definitions for global gradients/glows */}
            <svg style={{ height: 0, width: 0, position: 'absolute' }}>
              <defs>
                <linearGradient id="blueGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#00f0ff" stopOpacity="0.85" />
                  <stop offset="100%" stopColor="#0055ff" stopOpacity="0.15" />
                </linearGradient>
                <linearGradient id="goldGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#ffb700" stopOpacity="0.85" />
                  <stop offset="100%" stopColor="#ff6200" stopOpacity="0.15" />
                </linearGradient>
                <linearGradient id="slateGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#94a3b8" stopOpacity="0.8" />
                  <stop offset="100%" stopColor="#475569" stopOpacity="0.2" />
                </linearGradient>
                <linearGradient id="lineAreaGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#38bdf8" stopOpacity="0.25" />
                  <stop offset="100%" stopColor="#0284c7" stopOpacity="0.0" />
                </linearGradient>
                <filter id="neonGlowBlue">
                  <feGaussianBlur stdDeviation="3" result="coloredBlur"/>
                  <feMerge>
                    <feMergeNode in="coloredBlur"/>
                    <feMergeNode in="SourceGraphic"/>
                  </feMerge>
                </filter>
                <filter id="neonGlowGold">
                  <feGaussianBlur stdDeviation="3" result="coloredBlur"/>
                  <feMerge>
                    <feMergeNode in="coloredBlur"/>
                    <feMergeNode in="SourceGraphic"/>
                  </feMerge>
                </filter>
              </defs>
            </svg>

            {/* GRID PRINCIPAL RESPONSIVO */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: isDesktop 
                ? 'repeat(3, 1fr)' 
                : isTablet 
                  ? 'repeat(2, 1fr)' 
                  : '1fr',
              gap: '20px',
              width: '100%'
            }}>
              
              {/* COLUMNA 1 */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                
                {/* CARD 1: Cargas Diarias Raizen */}
                <div className="card" style={{ padding: '20px', margin: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                    <span style={{ fontSize: '15px', fontWeight: 'bold', color: '#ffffff' }}>Cargas diarias Raizen</span>
                    <span style={{ 
                      fontSize: '11px', 
                      backgroundColor: 'rgba(0, 85, 255, 0.25)', 
                      border: '1px solid #3b82f6',
                      color: '#60a5fa', 
                      padding: '3px 10px', 
                      borderRadius: '12px', 
                      fontWeight: 'bold' 
                    }}>Alfa C</span>
                  </div>

                  <div style={{ textAlign: 'center', fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '10px', fontWeight: '600' }}>
                    Cargas Diarias Raizen ({selectedMonthLabel})
                  </div>

                  {/* SVG Chart 1 */}
                  <div style={{ width: '100%', position: 'relative' }}>
                    {chart1Data.length === 0 ? (
                      <div style={{ display: 'flex', height: '220px', justifyContent: 'center', alignItems: 'center', color: 'var(--text-secondary)', fontSize: '14px', border: '1px dashed rgba(255,255,255,0.05)', borderRadius: '8px' }}>
                        Sin operaciones en este período
                      </div>
                    ) : (
                      <svg viewBox="0 0 500 300" style={{ width: '100%', height: 'auto', overflow: 'visible' }}>
                        {/* Grid Lines */}
                        {getChart1Scale.ticks.map((gridVal) => {
                          const yVal = 250 - (gridVal / getChart1Scale.limit) * 200;
                          return (
                            <g key={gridVal}>
                              <line x1="60" y1={yVal} x2="470" y2={yVal} stroke="rgba(255,255,255,0.06)" strokeDasharray="3,3" />
                              <text x="45" y={yVal + 4} fill="var(--text-secondary)" fontSize="11px" textAnchor="end">{gridVal.toFixed(1)}</text>
                            </g>
                          );
                        })}
                        <line x1="60" y1="250" x2="470" y2="250" stroke="rgba(255,255,255,0.15)" />

                        {/* Bar Data */}
                        {chart1Data.map((d, i) => {
                          if (d.value === 0) return null;
                          // Space elements evenly
                          const spacing = (410 / chart1Data.length);
                          const xVal = 70 + i * spacing;
                          const barHeight = (d.value / getChart1Scale.limit) * 200;
                          const yVal = 250 - barHeight;
                          const isHovered = hoveredBar1 === i;

                          return (
                            <rect
                              key={i}
                              x={xVal - Math.min(10, spacing / 2.5)}
                              y={yVal}
                              width={Math.max(4, Math.min(20, spacing / 1.5))}
                              height={barHeight}
                              rx="3"
                              fill="url(#blueGradient)"
                              filter={isHovered ? 'url(#neonGlowBlue)' : 'none'}
                              style={{ cursor: 'pointer', transition: 'all 0.3s' }}
                              onMouseEnter={() => setHoveredBar1(i)}
                              onMouseLeave={() => setHoveredBar1(null)}
                            />
                          );
                        })}

                        {/* X Labels */}
                        {chart1Data.map((d, i) => {
                          const spacing = (410 / chart1Data.length);
                          const xVal = 70 + i * spacing;
                          // Skip label if too crowded
                          if (chart1Data.length > 15 && i % 2 !== 0 && i !== chart1Data.length - 1) return null;
                          return (
                            <text 
                              key={i} 
                              x={xVal} 
                              y="275" 
                              fill="var(--text-secondary)" 
                              fontSize="9px" 
                              textAnchor="middle" 
                              transform={`rotate(-35, ${xVal}, 275)`}
                            >
                              {d.label}
                            </text>
                          );
                        })}

                        {/* SVG Tooltip */}
                        {hoveredBar1 !== null && chart1Data[hoveredBar1] && (
                          <g>
                            <rect
                              x={70 + hoveredBar1 * (410 / chart1Data.length) - 45}
                              y={250 - (chart1Data[hoveredBar1].value / getChart1Scale.limit) * 200 - 36}
                              width="90"
                              height="26"
                              rx="6"
                              fill="rgba(15, 23, 42, 0.95)"
                              stroke="#00f0ff"
                              strokeWidth="1"
                            />
                            <text
                              x={70 + hoveredBar1 * (410 / chart1Data.length)}
                              y={250 - (chart1Data[hoveredBar1].value / getChart1Scale.limit) * 200 - 19}
                              fill="#ffffff"
                              fontSize="11px"
                              fontWeight="bold"
                              textAnchor="middle"
                            >
                              {chart1Data[hoveredBar1].value} k Tons
                            </text>
                          </g>
                        )}
                      </svg>
                    )}
                  </div>
                </div>

                {/* CARD 4: Cargas Diarias WFS */}
                <div className="card" style={{ padding: '20px', margin: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                    <span style={{ fontSize: '15px', fontWeight: 'bold', color: '#ffffff' }}>Cargas diarias WFS</span>
                    
                    {/* Pills Interactivos */}
                    <div style={{ display: 'flex', gap: '6px' }}>
                      <button 
                        onClick={() => setWfsActiveVessel('GUSTAVO U')}
                        style={{
                          fontSize: '10px',
                          border: 'none',
                          backgroundColor: wfsActiveVessel === 'GUSTAVO U' ? 'rgba(100, 116, 139, 0.25)' : 'transparent',
                          color: wfsActiveVessel === 'GUSTAVO U' ? '#94a3b8' : 'var(--text-secondary)',
                          padding: '3px 8px',
                          borderRadius: '8px',
                          fontWeight: 'bold',
                          cursor: 'pointer',
                          border: wfsActiveVessel === 'GUSTAVO U' ? '1px solid #475569' : '1px solid transparent'
                        }}
                      >
                        Gustavo U
                      </button>
                      <button 
                        onClick={() => setWfsActiveVessel('NANY')}
                        style={{
                          fontSize: '10px',
                          border: 'none',
                          backgroundColor: wfsActiveVessel === 'NANY' ? 'rgba(245, 158, 11, 0.2)' : 'transparent',
                          color: wfsActiveVessel === 'NANY' ? '#f59e0b' : 'var(--text-secondary)',
                          padding: '3px 8px',
                          borderRadius: '8px',
                          fontWeight: 'bold',
                          cursor: 'pointer',
                          border: wfsActiveVessel === 'NANY' ? '1px solid #d97706' : '1px solid transparent'
                        }}
                      >
                        Nany
                      </button>
                    </div>
                  </div>

                  <div style={{ textAlign: 'center', fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '10px', fontWeight: '600' }}>
                    Cargas Diarias WFS ({wfsActiveVessel}) - {selectedMonthLabel}
                  </div>

                  {/* SVG Chart 4 */}
                  <div style={{ width: '100%', position: 'relative' }}>
                    {chart4Data.length === 0 ? (
                      <div style={{ display: 'flex', height: '220px', justifyContent: 'center', alignItems: 'center', color: 'var(--text-secondary)', fontSize: '14px', border: '1px dashed rgba(255,255,255,0.05)', borderRadius: '8px' }}>
                        Sin operaciones en este período
                      </div>
                    ) : (
                      <svg viewBox="0 0 500 300" style={{ width: '100%', height: 'auto', overflow: 'visible' }}>
                        {/* Grid Lines */}
                        {getChart4Scale.ticks.map((gridVal) => {
                          const yVal = 250 - (gridVal / getChart4Scale.limit) * 200;
                          return (
                            <g key={gridVal}>
                              <line x1="60" y1={yVal} x2="470" y2={yVal} stroke="rgba(255,255,255,0.06)" strokeDasharray="3,3" />
                              <text x="45" y={yVal + 4} fill="var(--text-secondary)" fontSize="11px" textAnchor="end">{gridVal.toFixed(1)}</text>
                            </g>
                          );
                        })}
                        <line x1="60" y1="250" x2="470" y2="250" stroke="rgba(255,255,255,0.15)" />

                        {/* Legend */}
                        <g transform="translate(190, 20)">
                          <rect x="0" y="0" width="12" height="12" rx="2" fill={wfsActiveVessel === 'GUSTAVO U' ? 'url(#slateGradient)' : 'url(#goldGradient)'} />
                          <text x="20" y="10" fill="var(--text-secondary)" fontSize="11px" fontWeight="bold">
                            {wfsActiveVessel}
                          </text>
                        </g>

                        {/* Bar Data */}
                        {chart4Data.map((d, i) => {
                          if (d.value === 0) return null;
                          const spacing = (410 / chart4Data.length);
                          const xVal = 70 + i * spacing;
                          const barHeight = (d.value / getChart4Scale.limit) * 200;
                          const yVal = 250 - barHeight;
                          const isHovered = hoveredBar4 === i;

                          return (
                            <rect
                              key={i}
                              x={xVal - Math.min(10, spacing / 2.5)}
                              y={yVal}
                              width={Math.max(4, Math.min(20, spacing / 1.5))}
                              height={barHeight}
                              rx="3"
                              fill={wfsActiveVessel === 'GUSTAVO U' ? 'url(#slateGradient)' : 'url(#goldGradient)'}
                              filter={isHovered ? (wfsActiveVessel === 'GUSTAVO U' ? 'none' : 'url(#neonGlowGold)') : 'none'}
                              style={{ cursor: 'pointer', transition: 'all 0.3s' }}
                              onMouseEnter={() => setHoveredBar4(i)}
                              onMouseLeave={() => setHoveredBar4(null)}
                            />
                          );
                        })}

                        {/* X Labels */}
                        {chart4Data.map((d, i) => {
                          const spacing = (410 / chart4Data.length);
                          const xVal = 70 + i * spacing;
                          if (chart4Data.length > 15 && i % 2 !== 0 && i !== chart4Data.length - 1) return null;
                          return (
                            <text 
                              key={i} 
                              x={xVal} 
                              y="275" 
                              fill="var(--text-secondary)" 
                              fontSize="9px" 
                              textAnchor="middle" 
                              transform={`rotate(-35, ${xVal}, 275)`}
                            >
                              {d.label}
                            </text>
                          );
                        })}

                        {/* Tooltip */}
                        {hoveredBar4 !== null && chart4Data[hoveredBar4] && (
                          <g>
                            <rect
                              x={70 + hoveredBar4 * (410 / chart4Data.length) - 45}
                              y={250 - (chart4Data[hoveredBar4].value / getChart4Scale.limit) * 200 - 36}
                              width="90"
                              height="26"
                              rx="6"
                              fill="rgba(15, 23, 42, 0.95)"
                              stroke={wfsActiveVessel === 'GUSTAVO U' ? '#94a3b8' : '#f59e0b'}
                              strokeWidth="1"
                            />
                            <text
                              x={70 + hoveredBar4 * (410 / chart4Data.length)}
                              y={250 - (chart4Data[hoveredBar4].value / getChart4Scale.limit) * 200 - 19}
                              fill="#ffffff"
                              fontSize="11px"
                              fontWeight="bold"
                              textAnchor="middle"
                            >
                              {chart4Data[hoveredBar4].value} k Tons
                            </text>
                          </g>
                        )}
                      </svg>
                    )}
                  </div>
                </div>

              </div>

              {/* COLUMNA 2 */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                
                {/* CARD 2: Cargas Anual */}
                <div className="card" style={{ padding: '20px', margin: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                    <span style={{ fontSize: '15px', fontWeight: 'bold', color: '#ffffff' }}>Cargas Anual</span>
                    <TrendingUp size={16} color="var(--ncs-accent)" />
                  </div>

                  <div style={{ textAlign: 'center', fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '10px', fontWeight: '600' }}>
                    Historial de Cargas Mensual (Últimos 15 meses)
                  </div>

                  {/* SVG Chart 2 (Line Chart) */}
                  <div style={{ width: '100%', position: 'relative' }}>
                    {chart2Data.length === 0 ? (
                      <div style={{ display: 'flex', height: '220px', justifyContent: 'center', alignItems: 'center', color: 'var(--text-secondary)', fontSize: '14px' }}>
                        Sin registros anuales
                      </div>
                    ) : (
                      <svg viewBox="0 0 500 300" style={{ width: '100%', height: 'auto', overflow: 'visible' }}>
                        {/* Grid Lines */}
                        {getChart2Scale.ticks.map((gridVal) => {
                          const yVal = 250 - (gridVal / getChart2Scale.limit) * 200;
                          return (
                            <g key={gridVal}>
                              <line x1="55" y1={yVal} x2="480" y2={yVal} stroke="rgba(255,255,255,0.06)" strokeDasharray="3,3" />
                              <text x="45" y={yVal + 4} fill="var(--text-secondary)" fontSize="11px" textAnchor="end">{Math.round(gridVal)}k</text>
                            </g>
                          );
                        })}
                        <line x1="55" y1="250" x2="480" y2="250" stroke="rgba(255,255,255,0.15)" />

                        {/* Area Under Line (Gradient) */}
                        <path
                          d={`M 60 250 ` + chart2Data.map((d, i) => {
                            const xVal = 60 + i * getChart2Scale.stepX;
                            const yVal = 250 - (d.val / getChart2Scale.limit) * 200;
                            return `L ${xVal} ${yVal}`;
                          }).join(' ') + ` L ${60 + (chart2Data.length - 1) * getChart2Scale.stepX} 250 Z`}
                          fill="url(#lineAreaGradient)"
                        />

                        {/* Stroke Line */}
                        <path
                          d={chart2Data.map((d, i) => {
                            const xVal = 60 + i * getChart2Scale.stepX;
                            const yVal = 250 - (d.val / getChart2Scale.limit) * 200;
                            return `${i === 0 ? 'M' : 'L'} ${xVal} ${yVal}`;
                          }).join(' ')}
                          fill="none"
                          stroke="#38bdf8"
                          strokeWidth="2.5"
                          filter="drop-shadow(0px 2px 5px rgba(56, 189, 248, 0.4))"
                        />

                        {/* Points / Circles */}
                        {chart2Data.map((d, i) => {
                          const xVal = 60 + i * getChart2Scale.stepX;
                          const yVal = 250 - (d.val / getChart2Scale.limit) * 200;
                          const isHovered = hoveredPoint2 === i;

                          return (
                            <circle
                              key={i}
                              cx={xVal}
                              cy={yVal}
                              r={isHovered ? 6 : 4}
                              fill={isHovered ? '#00ffff' : '#1e293b'}
                              stroke="#38bdf8"
                              strokeWidth={isHovered ? 2.5 : 1.5}
                              style={{ cursor: 'pointer', transition: 'all 0.2s' }}
                              onMouseEnter={() => setHoveredPoint2(i)}
                              onMouseLeave={() => setHoveredPoint2(null)}
                            />
                          );
                        })}

                        {/* X Labels */}
                        {chart2Data.map((d, i) => {
                          const xVal = 60 + i * getChart2Scale.stepX;
                          if (chart2Data.length > 8 && i % 2 !== 0 && i !== chart2Data.length - 1) return null;
                          return (
                            <text 
                              key={i} 
                              x={xVal} 
                              y="275" 
                              fill="var(--text-secondary)" 
                              fontSize="9px" 
                              textAnchor="end" 
                              transform={`rotate(-40, ${xVal}, 275)`}
                            >
                              {d.month}
                            </text>
                          );
                        })}

                        {/* Tooltip */}
                        {hoveredPoint2 !== null && chart2Data[hoveredPoint2] && (
                          <g>
                            <rect
                              x={60 + hoveredPoint2 * getChart2Scale.stepX - 40}
                              y={250 - (chart2Data[hoveredPoint2].val / getChart2Scale.limit) * 200 - 36}
                              width="80"
                              height="26"
                              rx="6"
                              fill="rgba(15, 23, 42, 0.95)"
                              stroke="#38bdf8"
                              strokeWidth="1"
                            />
                            <text
                              x={60 + hoveredPoint2 * getChart2Scale.stepX}
                              y={250 - (chart2Data[hoveredPoint2].val / getChart2Scale.limit) * 200 - 19}
                              fill="#ffffff"
                              fontSize="11px"
                              fontWeight="bold"
                              textAnchor="middle"
                            >
                              {chart2Data[hoveredPoint2].val}k
                            </text>
                          </g>
                        )}
                      </svg>
                    )}
                  </div>
                </div>

                {/* CARD 5: Buques cargados del período */}
                <div className="card" style={{ padding: '20px', margin: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                    <span style={{ fontSize: '15px', fontWeight: 'bold', color: '#ffffff' }}>Buques cargados del período</span>
                    <Ship size={16} color="var(--ncs-accent)" />
                  </div>

                  <div style={{ textAlign: 'center', fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '15px', fontWeight: '600' }}>
                    Total de Buques Operados (Histórico Acumulado)
                  </div>

                  {/* SVG Chart 5 (Dynamic vertical bars) */}
                  <div style={{ width: '100%', position: 'relative' }}>
                    {chart5Data.length === 0 ? (
                      <div style={{ display: 'flex', height: '220px', justifyContent: 'center', alignItems: 'center', color: 'var(--text-secondary)', fontSize: '14px' }}>
                        Sin datos de buques
                      </div>
                    ) : (
                      <svg viewBox="0 0 500 300" style={{ width: '100%', height: 'auto', overflow: 'visible' }}>
                        {/* Grid Lines */}
                        {getChart5Scale.ticks.map((gridVal) => {
                          const yVal = 250 - (gridVal / getChart5Scale.limit) * 200;
                          return (
                            <g key={gridVal}>
                              <line x1="60" y1={yVal} x2="440" y2={yVal} stroke="rgba(255,255,255,0.06)" strokeDasharray="3,3" />
                              <text x="45" y={yVal + 4} fill="var(--text-secondary)" fontSize="11px" textAnchor="end">{gridVal}</text>
                            </g>
                          );
                        })}
                        <line x1="60" y1="250" x2="440" y2="250" stroke="rgba(255,255,255,0.15)" />

                        {/* Dynamic Bars mapping aggregate ships */}
                        {chart5Data.map((v, i) => {
                          const barHeight = (v.total_ships / getChart5Scale.limit) * 200;
                          const yVal = 250 - barHeight;
                          const barWidth = 60;
                          // Distribute spacing evenly based on length
                          const spacing = (380 - (chart5Data.length * barWidth)) / (chart5Data.length + 1);
                          const xVal = 60 + spacing + i * (barWidth + spacing);
                          const isHovered = hoveredBar5 === v.ship;
                          const sTheme = getShipTheme(v.ship);

                          return (
                            <g 
                              key={v.ship}
                              onMouseEnter={() => setHoveredBar5(v.ship)}
                              onMouseLeave={() => setHoveredBar5(null)}
                              style={{ cursor: 'pointer' }}
                            >
                              <rect
                                x={xVal}
                                y={yVal}
                                width={barWidth}
                                height={barHeight}
                                rx="8"
                                fill={sTheme.border}
                                opacity={isHovered ? 1.0 : 0.8}
                                filter={isHovered ? 'url(#neonGlowBlue)' : 'none'}
                                style={{ transition: 'all 0.3s' }}
                              />
                              <text x={xVal + barWidth/2} y={yVal > 220 ? yVal - 10 : yVal + 25} fill="#ffffff" fontSize="14px" fontWeight="bold" textAnchor="middle">{v.total_ships}</text>
                              <text x={xVal + barWidth/2} y="272" fill="var(--text-primary)" fontSize="11px" fontWeight="bold" textAnchor="middle">BT {v.ship}</text>
                            </g>
                          );
                        })}
                      </svg>
                    )}
                  </div>
                </div>

              </div>

              {/* COLUMNA 3 (Spans both rows on desktop) */}
              <div style={{ 
                gridColumn: isDesktop ? '3' : 'auto', 
                gridRow: isDesktop ? 'span 2' : 'auto',
                display: 'flex',
                flexDirection: 'column',
                height: '100%'
              }}>
                
                {/* CARD 3: Cargas Programadas */}
                <div className="card" style={{ padding: '20px', margin: 0, height: '100%', display: 'flex', flexDirection: 'column', gap: '24px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: '15px', fontWeight: 'bold', color: '#ffffff' }}>Cargas del Período</span>
                    <Calendar size={16} color="var(--ncs-accent)" />
                  </div>

                  {/* SUB-SECCIÓN 1: RAIZEN */}
                  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '10px' }}>
                    <div style={{ textAlign: 'center', fontSize: '13px', color: 'var(--text-secondary)', fontWeight: '600' }}>
                      Cargas Raizen ({selectedMonthLabel})
                    </div>

                    {/* SVG Raizen Horizontal Progress */}
                    <div style={{ width: '100%' }}>
                      <svg viewBox="0 0 450 170" style={{ width: '100%', height: 'auto', overflow: 'visible' }}>
                        {/* Grid Lines */}
                        {(() => {
                          const limit = cargasProgramadas.raizen.limit || 16;
                          return [0, 2, 4, 6, 8, 10, 12, 14, 16].map((tick) => {
                            const tickVal = (limit / 16) * tick;
                            const xVal = 60 + (tick / 16) * 360;
                            return (
                              <g key={tick}>
                                <line x1={xVal} y1="30" x2={xVal} y2="110" stroke="rgba(255,255,255,0.05)" strokeDasharray="3,3" />
                                <text x={xVal} y="130" fill="var(--text-secondary)" fontSize="10px" textAnchor="middle">{Math.round(tickVal)}k</text>
                              </g>
                            );
                          });
                        })()}
                        <line x1="60" y1="110" x2="420" y2="110" stroke="rgba(255,255,255,0.15)" />

                        {/* Pill Legend inside SVG */}
                        <rect x="200" y="5" width="70" height="18" rx="4" fill="rgba(0, 85, 255, 0.2)" stroke="#3b82f6" strokeWidth="1" />
                        <text x="235" y="17" fill="#60a5fa" fontSize="9px" fontWeight="bold" textAnchor="middle">ALFA C</text>

                        {/* Bar */}
                        <rect
                          x="60"
                          y="40"
                          width={Math.min(360, (cargasProgramadas.raizen.total / cargasProgramadas.raizen.limit) * 360)}
                          height="55"
                          rx="10"
                          fill="url(#blueGradient)"
                          filter="url(#neonGlowBlue)"
                        />
                        <text x="60" y="73" fill="#ffffff" fontSize="13px" fontWeight="bold" textAnchor="middle" transform={`translate(${Math.max(40, Math.min(360, (cargasProgramadas.raizen.total / cargasProgramadas.raizen.limit) * 360) / 2)}, 0)`}>
                          {cargasProgramadas.raizen.total}k
                        </text>
                        <text x="45" y="72" fill="var(--text-primary)" fontSize="11px" fontWeight="bold" textAnchor="end">Raizen</text>
                        
                        <text x="240" y="155" fill="var(--text-secondary)" fontSize="11px" textAnchor="middle" fontWeight="500">
                          Total <strong style={{ color: 'var(--text-primary)' }}>{cargasProgramadas.raizen.total} / {cargasProgramadas.raizen.limit} (k tons)</strong>
                        </text>
                      </svg>
                    </div>
                  </div>

                  <hr style={{ border: 'none', borderTop: '1px solid rgba(255,255,255,0.05)', margin: '0' }} />

                  {/* SUB-SECCIÓN 2: WFS */}
                  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '10px' }}>
                    <div style={{ textAlign: 'center', fontSize: '13px', color: 'var(--text-secondary)', fontWeight: '600' }}>
                      Cargas WFS ({selectedMonthLabel})
                    </div>

                    {/* SVG WFS Horizontal Progress */}
                    <div style={{ width: '100%' }}>
                      <svg viewBox="0 0 450 170" style={{ width: '100%', height: 'auto', overflow: 'visible' }}>
                        {/* Grid Lines */}
                        {(() => {
                          const limit = cargasProgramadas.wfs.limit || 15;
                          return [0, 2, 4, 6, 8, 10, 12, 14, 16].map((tick) => {
                            const tickVal = (limit / 16) * tick;
                            const xVal = 60 + (tick / 16) * 360;
                            return (
                              <g key={tick}>
                                <line x1={xVal} y1="30" x2={xVal} y2="110" stroke="rgba(255,255,255,0.05)" strokeDasharray="3,3" />
                                <text x={xVal} y="130" fill="var(--text-secondary)" fontSize="10px" textAnchor="middle">{Math.round(tickVal)}k</text>
                              </g>
                            );
                          });
                        })()}
                        <line x1="60" y1="110" x2="420" y2="110" stroke="rgba(255,255,255,0.15)" />

                        {/* Pill Legend WFS */}
                        <rect x="190" y="5" width="95" height="18" rx="4" fill="rgba(100, 116, 139, 0.2)" stroke="#475569" strokeWidth="1" />
                        <text x="237" y="17" fill="#94a3b8" fontSize="9px" fontWeight="bold" textAnchor="middle">GUSTAVO / NANY</text>

                        {/* Bar */}
                        <rect
                          x="60"
                          y="40"
                          width={Math.min(360, (cargasProgramadas.wfs.total / cargasProgramadas.wfs.limit) * 360)}
                          height="55"
                          rx="10"
                          fill="url(#slateGradient)"
                        />
                        <text x="60" y="73" fill="#ffffff" fontSize="13px" fontWeight="bold" textAnchor="middle" transform={`translate(${Math.max(40, Math.min(360, (cargasProgramadas.wfs.total / cargasProgramadas.wfs.limit) * 360) / 2)}, 0)`}>
                          {cargasProgramadas.wfs.total}k
                        </text>
                        <text x="45" y="72" fill="var(--text-primary)" fontSize="11px" fontWeight="bold" textAnchor="end">WFS</text>

                        <text x="240" y="155" fill="var(--text-secondary)" fontSize="11px" textAnchor="middle" fontWeight="500">
                          Total <strong style={{ color: 'var(--text-primary)' }}>{cargasProgramadas.wfs.total} / {cargasProgramadas.wfs.limit} (k tons)</strong>
                        </text>
                      </svg>
                    </div>
                  </div>

                </div>

              </div>

            </div>

          </div>
        )}

        {/* ============================================== */}
        {/* VISTA 2: LISTA TRADICIONAL DE VIAJES Y DETALLES */}
        {/* ============================================== */}
        {activeTab === 'list' && (
          <div>
            {/* Vessel Filter Pills */}
            <div style={{ display: 'flex', gap: '8px', overflowX: 'auto', paddingBottom: '4px', scrollbarWidth: 'none', marginBottom: '16px' }}>
              {vesselsList.map((v) => (
                <button
                  key={v}
                  onClick={() => setSelectedVessel(v)}
                  style={{
                    flex: '0 0 auto',
                    padding: '8px 14px',
                    borderRadius: '12px',
                    border: 'none',
                    background: selectedVessel === v ? 'var(--ncs-primary)' : 'rgba(255,255,255,0.05)',
                    color: selectedVessel === v ? 'var(--ncs-accent)' : 'var(--text-secondary)',
                    border: selectedVessel === v ? '1px solid var(--ncs-accent)' : '1px solid transparent',
                    fontSize: '13px',
                    cursor: 'pointer',
                    transition: 'all 0.2s ease',
                  }}
                >
                  {v === 'Todos' ? 'Todos los Buques' : `BT ${v}`}
                </button>
              ))}
            </div>

            {/* Summary Card */}
            <div className="card" style={{ display: 'flex', gap: '16px', alignItems: 'center', padding: '16px', marginBottom: '16px' }}>
              <div style={{
                width: '45px', height: '45px', borderRadius: '10px', 
                background: 'rgba(0, 240, 255, 0.1)', border: '1px solid rgba(0, 240, 255, 0.2)',
                display: 'flex', justifyContent: 'center', alignItems: 'center', color: 'var(--ncs-accent)'
              }}>
                <Calendar size={22} />
              </div>
              <div>
                <h4 style={{ margin: 0, fontSize: '15px', color: 'var(--text-primary)' }}>Resumen del Mes</h4>
                <p style={{ margin: '4px 0 0 0', fontSize: '13px', color: 'var(--text-secondary)' }}>
                  {filteredSchedules.length} operaciones programadas para {selectedMonthLabel}
                </p>
              </div>
            </div>

            {/* Schedule List */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {filteredSchedules.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-secondary)' }}>
                  No hay viajes ni operaciones programadas para los filtros seleccionados.
                </div>
              ) : (
                filteredSchedules.map((item) => {
                  const statusStyle = getStatusColor(item.status);
                  return (
                    <div 
                      key={item.id} 
                      className="card"
                      style={{ 
                        padding: '20px', 
                        display: 'flex', 
                        flexDirection: 'column', 
                        gap: '12px',
                        borderColor: statusStyle.border,
                        boxShadow: item.status === 'En Tránsito' ? '0 10px 25px -10px var(--ncs-accent-glow)' : '0 10px 30px -10px rgba(0,0,0,0.5)'
                      }}
                    >
                      {/* Card Header */}
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                          <Ship size={18} color="var(--ncs-accent)" />
                          <span style={{ fontWeight: '700', fontSize: '16px', color: 'var(--text-primary)' }}>
                            BT {item.vessel}
                          </span>
                        </div>
                        <span style={{ 
                          fontSize: '11px', 
                          fontWeight: 'bold', 
                          textTransform: 'uppercase',
                          padding: '4px 10px', 
                          borderRadius: '8px', 
                          color: statusStyle.text, 
                          backgroundColor: statusStyle.bg,
                          border: `1px solid ${statusStyle.border}`
                        }}>
                          {item.status}
                        </span>
                      </div>

                      {/* Route */}
                      <div style={{ display: 'flex', alignItems: 'flex-start', gap: '8px', marginTop: '4px' }}>
                        <MapPin size={16} style={{ color: 'var(--text-secondary)', marginTop: '2px' }} />
                        <span style={{ fontSize: '14px', fontWeight: '500', color: 'var(--text-primary)', lineHeight: '1.4' }}>
                          {item.route}
                        </span>
                      </div>

                      {/* Progress Bar */}
                      {item.progress > 0 && (
                        <div style={{ marginTop: '4px' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', color: 'var(--text-secondary)', marginBottom: '4px' }}>
                            <span>Progreso de Navegación</span>
                            <span style={{ fontWeight: 'bold', color: 'var(--text-primary)' }}>{item.progress}%</span>
                          </div>
                          <div style={{ width: '100%', height: '6px', borderRadius: '3px', backgroundColor: 'rgba(255,255,255,0.05)', overflow: 'hidden' }}>
                            <div style={{ 
                              width: `${item.progress}%`, 
                              height: '100%', 
                              background: item.status === 'Completado' ? 'linear-gradient(90deg, #00ff66, #00b347)' : 'linear-gradient(90deg, var(--ncs-accent), #0055ff)',
                              borderRadius: '3px',
                              transition: 'width 1s ease-in-out'
                            }} />
                          </div>
                        </div>
                      )}

                      {/* Details Grid */}
                      <div style={{ 
                        display: 'grid', 
                        gridTemplateColumns: '1fr 1fr', 
                        gap: '12px', 
                        paddingTop: '12px', 
                        borderTop: '1px solid rgba(255,255,255,0.05)',
                        fontSize: '12px',
                        color: 'var(--text-secondary)'
                      }}>
                        <div>
                          <span style={{ display: 'block', marginBottom: '2px' }}>Fechas</span>
                          <strong style={{ color: 'var(--text-primary)' }}>{item.dates}</strong>
                        </div>
                        <div>
                          <span style={{ display: 'block', marginBottom: '2px' }}>Tripulación</span>
                          <strong style={{ color: 'var(--text-primary)' }}>{item.crew}</strong>
                        </div>
                        <div style={{ gridColumn: 'span 2' }}>
                          <span style={{ display: 'block', marginBottom: '2px' }}>Carga Programada</span>
                          <strong style={{ color: 'var(--text-primary)' }}>{item.cargo}</strong>
                        </div>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>
        )}

      </div>
    </div>
  );
};

export default MonthlySchedule;
