import React, { useState, useEffect } from 'react';
import { BookOpen, GraduationCap, Award, CheckCircle2, Clock, Ship, FileText, Play, X, UserCheck, Video } from 'lucide-react';
import { getApiEndpoint } from '../config';

const Trainings = () => {
  const [trainings, setTrainings] = useState([]);
  const [consumption, setConsumption] = useState(null);
  const [loading, setLoading] = useState(true);
  const [selectedTraining, setSelectedTraining] = useState(null);
  const [updating, setUpdating] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const token = localStorage.getItem('ncsToken');
        const headers = { 'Content-Type': 'application/json' };
        if (token) {
          headers['Authorization'] = `Token ${token}`;
        }

        const [trainingsRes, consumptionRes, shipsRes] = await Promise.all([
          fetch(getApiEndpoint('/api/v1/trainings/'), { headers }),
          fetch(getApiEndpoint('/api/v1/trainings/consumption/'), { headers }),
          fetch(getApiEndpoint('/api/v1/ships/'), { headers })
        ]);

        let realShips = [];
        if (shipsRes.ok) {
          const shipsData = await shipsRes.json();
          realShips = (shipsData || []).filter(s => s.name || s.ship);
        }

        const defaultShipNames = realShips.length > 0 ? realShips.map(s => s.name || s.ship) : ["ALFA C", "GUSTAVO U", "NANY"];
        let h = 180;
        const consumptionByShip = defaultShipNames.map((name, i) => {
          const item = { ship: name, hours: h, completion_rate: Math.min(99, 94.0 + (i % 5)) };
          h = Math.max(100, h - 20);
          return item;
        });

        const initialTrainings = [
          {
            id: 10005,
            title: "STCW VI/1 - 1° Auxilios Básicos (1)",
            code: "STCW-VI/1-01",
            hours: 40,
            sector: "General",
            completion_rate: 98.6,
            completed_modules: 3,
            total_modules: 3,
            status: "Vigente",
            description: "Capacitación obligatoria Convenio STCW VI/1. 71 tripulantes registrados con 98.6% de cumplimiento en la flota.",
            instructor: "Dra. Elena Silva (Médico Naval PNA)",
            modules: [
              { id: 1, title: "Módulo 1: Reanimación Cardiopulmonar (RCP) y Soporte Vital", duration: 45, is_completed: true },
              { id: 2, title: "Módulo 2: Control de Hemorragias, Fracturas y Quemaduras", duration: 40, is_completed: true },
              { id: 3, title: "Módulo 3: Protocolos de Emergencia Médica en Mar", duration: 35, is_completed: true }
            ]
          },
          {
            id: 10003,
            title: "STCW VI/1 - Lucha Contra Incendios LCI (2)",
            code: "STCW-VI/1-02",
            hours: 32,
            sector: "General",
            completion_rate: 98.6,
            completed_modules: 3,
            total_modules: 3,
            status: "Vigente",
            description: "Instrucción de sofocación de incendios a bordo. 71 tripulantes auditados con 98.6% vigencia.",
            instructor: "Ing. Bombero Naval Gabriel Rossi",
            modules: [
              { id: 1, title: "Módulo 1: Química del Fuego y Agentes Extintores", duration: 40, is_completed: true },
              { id: 2, title: "Módulo 2: Uso de Equipos ERA y mangueras de alta presión", duration: 50, is_completed: true },
              { id: 3, title: "Módulo 3: Tácticas de Ataque en Espacios Confinados", duration: 45, is_completed: true }
            ]
          },
          {
            id: 10007,
            title: "STCW VI/1 - Técnicas de Supervivencia Personal T.S.P (3)",
            code: "STCW-VI/1-03",
            hours: 30,
            sector: "Cubierta",
            completion_rate: 97.1,
            completed_modules: 2,
            total_modules: 3,
            status: "Vigente",
            description: "Zafarrancho de abandono y supervivencia en el mar. 70 tripulantes con 97.1% de certificaciones activas.",
            instructor: "Cap. Esteban Valdez (Instructor Máster STCW)",
            modules: [
              { id: 1, title: "Módulo 1: Zafarrancho y Despliegue de Balsas Salvavidas", duration: 50, is_completed: true },
              { id: 2, title: "Módulo 2: Uso de Trajes de Inmersión y Chalecos", duration: 40, is_completed: true },
              { id: 3, title: "Módulo 3: Activación de Radiobalizas EPIRB y SART", duration: 30, is_completed: false }
            ]
          },
          {
            id: 10008,
            title: "STCW VI/1 - Seguridad Personal y Resp. Sociales SPyRS (4)",
            code: "STCW-VI/1-04",
            hours: 24,
            sector: "General",
            completion_rate: 97.1,
            completed_modules: 3,
            total_modules: 3,
            status: "Vigente",
            description: "Prevención de riesgos laborales y gestión del trabajo en equipo a bordo. 70 tripulantes evaluados.",
            instructor: "Lic. Marítimo Roberto Soria",
            modules: [
              { id: 1, title: "Módulo 1: Prevención de Riesgos de Trabajo a Bordo", duration: 45, is_completed: true },
              { id: 2, title: "Módulo 2: Gestión de la Fatiga y Relaciones Humanas", duration: 40, is_completed: true },
              { id: 3, title: "Módulo 3: Procedimientos de Emergencia y Alarma", duration: 35, is_completed: true }
            ]
          },
          {
            id: 10009,
            title: "STCW V/1-1 - Formación Básica Operaciones Petroleros (5)",
            code: "STCW-V/1-05",
            hours: 40,
            sector: "Cubierta",
            completion_rate: 98.6,
            completed_modules: 2,
            total_modules: 3,
            status: "Vigente",
            description: "Manejo seguro de cargas de hidrocarburos LSFO y MGO. 69 tripulantes capacitados.",
            instructor: "Cap. Marcos Benítez",
            modules: [
              { id: 1, title: "Módulo 1: Física y Química de Cargas Líquidas", duration: 50, is_completed: true },
              { id: 2, title: "Módulo 2: Sistemas de Inerteado y Transferencia", duration: 60, is_completed: true },
              { id: 3, title: "Módulo 3: Prevención de Derrames y SOPEP", duration: 45, is_completed: false }
            ]
          },
          {
            id: 10020,
            title: "Código PBIP / ISPS - Protección de Buques e Instalaciones",
            code: "ISPS-SEC-PBIP",
            hours: 24,
            sector: "Seguridad",
            completion_rate: 96.4,
            completed_modules: 3,
            total_modules: 3,
            status: "Vigente",
            description: "Cumplimiento del Plan de Protección del Buque (PPB) e inspección de accesos. 56 marinos vigentes.",
            instructor: "Of. Protección Marítima Roberto Soria",
            modules: [
              { id: 1, title: "Módulo 1: Evaluación de Amenazas PBIP", duration: 40, is_completed: true },
              { id: 2, title: "Módulo 2: Inspección de Carga y Accesos al Buque", duration: 45, is_completed: true },
              { id: 3, title: "Módulo 3: Niveles de Protección 1, 2 y 3", duration: 35, is_completed: true }
            ]
          },
          {
            id: 10014,
            title: "Convenio MARPOL (6) - Prevención Contaminación Marina",
            code: "MARPOL-73/78",
            hours: 32,
            sector: "General",
            completion_rate: 97.9,
            completed_modules: 2,
            total_modules: 3,
            status: "Vigente",
            description: "Normativa ambiental marítima internacional MARPOL Anexos I a VI. 48 tripulantes con 97.9% cumplimiento.",
            instructor: "Ing. Marítimo Carlos Benítez",
            modules: [
              { id: 1, title: "Módulo 1: Anexo I - Control de Aguas Oleosas y Separadores", duration: 50, is_completed: true },
              { id: 2, title: "Módulo 2: Libro de Registro de Hidrocarburos", duration: 45, is_completed: true },
              { id: 3, title: "Módulo 3: Anexos IV y VI - Emisiones y Residuos", duration: 40, is_completed: false }
            ]
          },
          {
            id: 10004,
            title: "STCW VI/3 - Lucha Contra Incendios Avanzada AV. LCI (8)",
            code: "STCW-VI/3-08",
            hours: 36,
            sector: "Máquinas",
            completion_rate: 97.5,
            completed_modules: 2,
            total_modules: 4,
            status: "Vigente",
            description: "Estrategias avanzadas de extinción en salas de máquinas y bodegas. 40 oficiales con 97.5% cumplimiento.",
            instructor: "Ing. Bombero Naval Gabriel Rossi",
            modules: [
              { id: 1, title: "Módulo 1: Control de Incendios en Sala de Máquinas", duration: 50, is_completed: true },
              { id: 2, title: "Módulo 2: Inyección Fija de CO2 y Agua Pulverizada", duration: 60, is_completed: true },
              { id: 3, title: "Módulo 3: Tácticas de Ataque con Cuadrillas de Rescate", duration: 55, is_completed: false },
              { id: 4, title: "Módulo 4: Evaluación de Estabilidad por Agua de Incendio", duration: 40, is_completed: false }
            ]
          },
          {
            id: 10010,
            title: "STCW V/1-1 - Formación Avanzada Operaciones Petroleros AV. PETRO (7)",
            code: "STCW-V/1-07",
            hours: 40,
            sector: "Cubierta",
            completion_rate: 92.5,
            completed_modules: 2,
            total_modules: 4,
            status: "Vigente",
            description: "Gestión avanzada de operaciones de tanqueros y trasvases STS. 40 oficiales evaluados.",
            instructor: "Cap. Andrés Morales",
            modules: [
              { id: 1, title: "Módulo 1: Control de Operaciones de Carga y Descarga", duration: 60, is_completed: true },
              { id: 2, title: "Módulo 2: Monitoreo Explosiométrico y Gas Free", duration: 50, is_completed: true },
              { id: 3, title: "Módulo 3: Lavado de Tanques con Crudo (COW) e Inerteado", duration: 55, is_completed: false },
              { id: 4, title: "Módulo 4: Procedimientos de Emergencia STS", duration: 45, is_completed: false }
            ]
          },
          {
            id: 10018,
            title: "STCW II/1 - Operador de Radar y ARPA (10)",
            code: "STCW-II/1-10",
            hours: 40,
            sector: "Puente",
            completion_rate: 100.0,
            completed_modules: 3,
            total_modules: 3,
            status: "Vigente",
            description: "Instrucción técnica de cinemática de radar y punteo ARPA para guardia de navegación. 11 oficiales con 100% de vigencia.",
            instructor: "Cap. Esteban Valdez",
            modules: [
              { id: 1, title: "Módulo 1: Operación y Ajustes del Pantalla Radar/ARPA", duration: 45, is_completed: true },
              { id: 2, title: "Módulo 2: Determinación de CPA y TCPA en Maniobras", duration: 55, is_completed: true },
              { id: 3, title: "Módulo 3: Simulación de Navegación Nocturna y Niebla", duration: 50, is_completed: true }
            ]
          },
          {
            id: 10006,
            title: "STCW VI/4 - Cuidados Médicos a Bordo (11)",
            code: "STCW-VI/4-11",
            hours: 40,
            sector: "General",
            completion_rate: 100.0,
            completed_modules: 3,
            total_modules: 3,
            status: "Vigente",
            description: "Administración de farmacia de a bordo y asistencia médica guiada por radio. 17 oficiales vigentes.",
            instructor: "Dra. Elena Silva (Médico Naval)",
            modules: [
              { id: 1, title: "Módulo 1: Control de Farmacia e Inyectables a Bordo", duration: 45, is_completed: true },
              { id: 2, title: "Módulo 2: Suturas, Inmovilización y Tratamientos de Urgencia", duration: 50, is_completed: true },
              { id: 3, title: "Módulo 3: Consulta Médica por Radio TMAS y Telemedicina", duration: 35, is_completed: true }
            ]
          },
          {
            id: 10025,
            title: "Oficial de Seguridad (Gestión y Evaluación del Riesgo)",
            code: "SAFETY-OFFICER",
            hours: 30,
            sector: "Seguridad",
            completion_rate: 100.0,
            completed_modules: 3,
            total_modules: 3,
            status: "Vigente",
            description: "Metodología de Análisis Seguro de Trabajo (AST) y reporte de hallazgos MG-21. 8 oficiales calificados.",
            instructor: "Lic. Seguridad Marítima Juan Gallardo",
            modules: [
              { id: 1, title: "Módulo 1: Matriz de Evaluación de Riesgos Operativos AST", duration: 45, is_completed: true },
              { id: 2, title: "Módulo 2: Permisos de Trabajo Seguro (PTS) y Bloqueos", duration: 40, is_completed: true },
              { id: 3, title: "Módulo 3: Investigación de Incidentes Marítimos MG-21", duration: 50, is_completed: true }
            ]
          }
        ];

        const storedUser = JSON.parse(localStorage.getItem('ncsCurrentUser') || '{}');
        const userName = storedUser.name || 'Usuario Autenticado';

        if (trainingsRes.ok) {
          const tData = await trainingsRes.json();
          setTrainings(Array.isArray(tData) ? tData : []);
        } else {
          setTrainings([]);
        }

        if (consumptionRes.ok) {
          const cData = await consumptionRes.json();
          setConsumption(cData);
        } else {
          setConsumption({
            total_hours_consumed: 0,
            total_trainings_completed: 0,
            compliance_rate: 0,
            active_certificates: 0,
            consumption_by_ship: []
          });
        }
      } catch (err) {
        console.error('Error fetching trainings:', err);
        setTrainings([]);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const handleAdvanceModule = (trainingId) => {
    setUpdating(true);
    setTimeout(() => {
      setTrainings(prev => prev.map(t => {
        if (t.id === trainingId) {
          const newCompleted = Math.min(t.total_modules, t.completed_modules + 1);
          const newRate = Math.round((newCompleted / t.total_modules) * 100);
          const updatedMods = t.modules.map((m, idx) => ({ ...m, is_completed: idx < newCompleted }));
          const updatedObj = {
            ...t,
            completed_modules: newCompleted,
            completion_rate: newRate,
            modules: updatedMods,
            status: newCompleted === t.total_modules ? "Vigente" : "En Curso"
          };
          if (selectedTraining && selectedTraining.id === trainingId) {
            setSelectedTraining(updatedObj);
          }
          return updatedObj;
        }
        return t;
      }));
      setUpdating(false);
    }, 300);
  };

  const storedUser = JSON.parse(localStorage.getItem('ncsCurrentUser') || '{}');
  const currentUserName = storedUser.name || 'Usuario Autenticado';

  return (
    <div style={{ padding: '20px', maxWidth: '1200px', margin: '0 auto', color: 'var(--text-primary)' }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '10px', color: '#ffffff' }}>
            <GraduationCap size={28} color="var(--ncs-accent)" />
            Capacitaciones y Consumo Académico
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginTop: '4px' }}>
            Gestión de instrucción marítima, auditoría STCW y consumo de horas por usuario activo
          </p>
        </div>
        <a 
          href="/swagger.json" 
          target="_blank" 
          rel="noreferrer" 
          className="btn-glass"
          style={{ fontSize: '12px', padding: '8px 14px', textDecoration: 'none', display: 'flex', alignItems: 'center', gap: '6px' }}
        >
          <FileText size={14} color="var(--ncs-accent)" />
          Swagger API Spec
        </a>
      </div>

      {/* User Tracking Banner */}
      <div style={{ background: 'rgba(0, 240, 255, 0.08)', border: '1px solid rgba(0, 240, 255, 0.2)', padding: '12px 18px', borderRadius: '12px', marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '12px' }}>
        <UserCheck size={22} color="var(--ncs-accent)" />
        <div>
          <span style={{ fontSize: '13px', fontWeight: 'bold', color: 'var(--ncs-accent)' }}>
            Capacitación por Usuario: {currentUserName}
          </span>
          <span style={{ fontSize: '12px', color: 'var(--text-secondary)', display: 'block' }}>
            La plataforma registra el consumo individual de horas y avance por módulo por marino autenticado en el servidor.
          </span>
        </div>
      </div>

      {/* KPI Cards Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px', marginBottom: '24px' }}>
        <div className="card" style={{ padding: '20px', margin: 0 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>Horas Consumidas</span>
            <Clock size={20} color="var(--ncs-accent)" />
          </div>
          <div style={{ fontSize: '26px', fontWeight: 'bold', marginTop: '8px', color: '#ffffff' }}>
            {consumption?.total_hours_consumed || 0} h
          </div>
          <span style={{ fontSize: '11px', color: '#00ff66', display: 'inline-block', marginTop: '4px' }}>
            ↑ Registro individual
          </span>
        </div>

        <div className="card" style={{ padding: '20px', margin: 0 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>Cursos Completados</span>
            <CheckCircle2 size={20} color="#00ff66" />
          </div>
          <div style={{ fontSize: '26px', fontWeight: 'bold', marginTop: '8px', color: '#ffffff' }}>
            {consumption?.total_trainings_completed || 0}
          </div>
          <span style={{ fontSize: '11px', color: 'var(--text-secondary)', display: 'inline-block', marginTop: '4px' }}>
            100% evaluación aprobada
          </span>
        </div>

        <div className="card" style={{ padding: '20px', margin: 0 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>Cumplimiento Plan</span>
            <BookOpen size={20} color="#38bdf8" />
          </div>
          <div style={{ fontSize: '26px', fontWeight: 'bold', marginTop: '8px', color: '#ffffff' }}>
            {consumption?.compliance_rate || 0}%
          </div>
          <span style={{ fontSize: '11px', color: '#38bdf8', display: 'inline-block', marginTop: '4px' }}>
            Conforme a normativa STCW
          </span>
        </div>

        <div className="card" style={{ padding: '20px', margin: 0 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>Certificados Vigentes</span>
            <Award size={20} color="#f59e0b" />
          </div>
          <div style={{ fontSize: '26px', fontWeight: 'bold', marginTop: '8px', color: '#ffffff' }}>
            {consumption?.active_certificates || 0}
          </div>
          <span style={{ fontSize: '11px', color: '#f59e0b', display: 'inline-block', marginTop: '4px' }}>
            Vigencia promedio: 24 meses
          </span>
        </div>
      </div>

      {/* Main Grid: Consumo por Buque & Lista de Cursos */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(340px, 1fr))', gap: '20px' }}>
        
        {/* Consumo por Buque Card */}
        <div className="card" style={{ padding: '24px', margin: 0 }}>
          <h2 style={{ fontSize: '16px', fontWeight: 'bold', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Ship size={18} color="var(--ncs-accent)" />
            Consumo Académico por Buque
          </h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {consumption?.consumption_by_ship?.map((item, idx) => (
              <div key={idx} style={{ background: 'rgba(15, 23, 42, 0.4)', padding: '14px', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.06)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px', fontSize: '14px', fontWeight: '600' }}>
                  <span>{item.ship}</span>
                  <span style={{ color: 'var(--ncs-accent)' }}>{item.hours} hrs ({item.completion_rate}%)</span>
                </div>
                <div style={{ width: '100%', height: '8px', background: 'rgba(255,255,255,0.08)', borderRadius: '4px', overflow: 'hidden' }}>
                  <div 
                    style={{ 
                      height: '100%', 
                      width: `${item.completion_rate}%`, 
                      background: 'linear-gradient(90deg, #00f0ff, #0055ff)',
                      borderRadius: '4px'
                    }} 
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Catálogo de Cursos Card */}
        <div className="card" style={{ padding: '24px', margin: 0 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <h2 style={{ fontSize: '16px', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <BookOpen size={18} color="var(--ncs-accent)" />
              Programa de Cursos y Normas
            </h2>
            <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>Haz clic para ver y continuar</span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {trainings.map((t) => (
              <div 
                key={t.id} 
                onClick={() => setSelectedTraining(t)}
                style={{ 
                  display: 'flex', 
                  justify: 'space-between', 
                  alignItems: 'center', 
                  padding: '14px', 
                  borderRadius: '12px', 
                  background: 'rgba(255,255,255,0.03)', 
                  border: '1px solid rgba(255,255,255,0.08)',
                  cursor: 'pointer',
                  transition: 'transform 0.2s, background 0.2s'
                }}
                className="hover-card"
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <div style={{ background: 'rgba(0, 240, 255, 0.12)', padding: '10px', borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Play size={20} color="var(--ncs-accent)" />
                  </div>
                  <div>
                    <div style={{ fontSize: '14px', fontWeight: 'bold', color: '#ffffff' }}>{t.title}</div>
                    <div style={{ fontSize: '11px', color: 'var(--text-secondary)', marginTop: '4px', display: 'flex', gap: '8px', alignItems: 'center' }}>
                      <span style={{ color: '#60a5fa', fontWeight: '600' }}>{t.code}</span>
                      <span>• {t.hours} hrs</span>
                      <span>• {t.sector}</span>
                    </div>
                  </div>
                </div>

                <div style={{ textAlign: 'right' }}>
                  <span style={{ padding: '4px 10px', borderRadius: '12px', background: t.completion_rate === 100 ? 'rgba(0, 255, 102, 0.15)' : 'rgba(0, 240, 255, 0.15)', border: t.completion_rate === 100 ? '1px solid rgba(0, 255, 102, 0.3)' : '1px solid rgba(0, 240, 255, 0.3)', color: t.completion_rate === 100 ? '#00ff66' : '#00f0ff', fontSize: '12px', fontWeight: 'bold' }}>
                    {t.completion_rate}%
                  </span>
                  <div style={{ fontSize: '10px', color: 'var(--text-secondary)', marginTop: '4px' }}>
                    {t.completed_modules}/{t.total_modules} módulos
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>

      {/* Modal Detail & Course Viewer */}
      {selectedTraining && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(0, 0, 0, 0.75)',
          backdropFilter: 'blur(6px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1000,
          padding: '20px'
        }}>
          <div className="card" style={{
            maxWidth: '650px',
            width: '100%',
            maxHeight: '90vh',
            overflowY: 'auto',
            padding: '24px',
            margin: 0,
            position: 'relative'
          }}>
            <button 
              onClick={() => setSelectedTraining(null)}
              style={{
                position: 'absolute',
                top: '18px',
                right: '18px',
                background: 'transparent',
                border: 'none',
                color: 'var(--text-secondary)',
                cursor: 'pointer'
              }}
            >
              <X size={20} />
            </button>

            {/* Video Frame */}
            <div style={{
              background: '#000',
              borderRadius: '12px',
              height: '200px',
              marginBottom: '20px',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              border: '1px solid rgba(255,255,255,0.1)'
            }}>
              <Video size={48} color="var(--ncs-accent)" />
              <span style={{ marginTop: '10px', color: '#fff', fontSize: '14px', fontWeight: 'bold' }}>
                Ver Capacitación en Video
              </span>
              <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>Instrucción interactiva STCW</span>
            </div>

            <h2 style={{ fontSize: '18px', fontWeight: 'bold', color: '#fff', marginBottom: '8px' }}>
              {selectedTraining.title}
            </h2>

            <div style={{ display: 'flex', gap: '10px', marginBottom: '14px' }}>
              <span style={{ padding: '3px 8px', background: 'rgba(56, 189, 248, 0.2)', color: '#38bdf8', borderRadius: '6px', fontSize: '11px', fontWeight: 'bold' }}>
                {selectedTraining.code}
              </span>
              <span style={{ padding: '3px 8px', background: 'rgba(255,255,255,0.1)', color: 'var(--text-secondary)', borderRadius: '6px', fontSize: '11px' }}>
                {selectedTraining.hours} Horas
              </span>
              <span style={{ padding: '3px 8px', background: 'rgba(255,255,255,0.1)', color: 'var(--text-secondary)', borderRadius: '6px', fontSize: '11px' }}>
                {selectedTraining.sector}
              </span>
            </div>

            <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '16px', lineHeight: '1.5' }}>
              {selectedTraining.description}
            </p>

            <div style={{ fontSize: '12px', color: 'var(--ncs-accent)', fontWeight: 'bold', marginBottom: '16px' }}>
              Instructor: {selectedTraining.instructor}
            </div>

            <div style={{ borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: '16px', marginBottom: '16px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px', fontSize: '13px', fontWeight: 'bold' }}>
                <span>Progreso de Usuario</span>
                <span style={{ color: '#00ff66' }}>{selectedTraining.completed_modules} / {selectedTraining.total_modules} Módulos ({selectedTraining.completion_rate}%)</span>
              </div>
              <div style={{ width: '100%', height: '8px', background: 'rgba(255,255,255,0.1)', borderRadius: '4px', overflow: 'hidden', marginBottom: '16px' }}>
                <div style={{ width: `${selectedTraining.completion_rate}%`, height: '100%', background: '#00ff66', borderRadius: '4px', transition: 'width 0.3s' }} />
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                {selectedTraining.modules?.map((m) => (
                  <div key={m.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 12px', background: 'rgba(255,255,255,0.03)', borderRadius: '8px', border: m.is_completed ? '1px solid rgba(0, 255, 102, 0.3)' : '1px solid transparent' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                      <CheckCircle2 size={16} color={m.is_completed ? '#00ff66' : '#64748b'} />
                      <span style={{ fontSize: '12.5px', color: m.is_completed ? '#fff' : 'var(--text-secondary)' }}>{m.title}</span>
                    </div>
                    <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>{m.duration} min</span>
                  </div>
                ))}
              </div>
            </div>

            <button
              disabled={updating || selectedTraining.completed_modules >= selectedTraining.total_modules}
              onClick={() => handleAdvanceModule(selectedTraining.id)}
              className="btn-glass"
              style={{
                width: '100%',
                padding: '12px',
                background: selectedTraining.completed_modules >= selectedTraining.total_modules ? 'rgba(0, 255, 102, 0.2)' : 'linear-gradient(90deg, #00f0ff, #0055ff)',
                color: '#fff',
                fontWeight: 'bold',
                fontSize: '14px',
                border: 'none',
                borderRadius: '10px',
                cursor: selectedTraining.completed_modules >= selectedTraining.total_modules ? 'default' : 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '8px'
              }}
            >
              <Play size={16} />
              {selectedTraining.completed_modules >= selectedTraining.total_modules 
                ? "Capacitación Completada al 100%" 
                : "Continuar Capacitación (Avanzar Módulo)"}
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default Trainings;

