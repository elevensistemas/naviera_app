import React, { useState, useEffect, useRef } from 'react';
import { Mic, Square, Send, Bot } from 'lucide-react';
import { getCentinelaEndpoint } from '../config';

const AIChat = () => {
  const [messages, setMessages] = useState([
    { id: 1, text: "Hola, soy el asistente virtual de NCS, ¿en qué puedo ayudarte?", isUser: false }
  ]);
  const [isRecording, setIsRecording] = useState(false);
  const [input, setInput] = useState('');
  const [processing, setProcessing] = useState(false);
  const messagesEndRef = useRef(null);

  const recognitionRef = useRef(null);

  useEffect(() => {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    
    if (SpeechRecognition) {
      const recognition = new SpeechRecognition();
      recognition.lang = 'es-ES';
      // MÓVIL: continuous=true rompe Chrome Android y Safari iOS. OBLIGATORIO false.
      recognition.continuous = false;
      recognition.interimResults = true;

      recognition.onresult = (event) => {
        let interimTranscript = '';
        let finalTranscript = '';
        
        for (let i = event.resultIndex; i < event.results.length; ++i) {
          if (event.results[i].isFinal) {
            finalTranscript += event.results[i][0].transcript;
          } else {
            interimTranscript += event.results[i][0].transcript;
          }
        }
        
        if (interimTranscript) {
          setInput(interimTranscript);
        }
        
        if (finalTranscript) {
          setInput('');
          const textToSubmit = finalTranscript;
          setTimeout(() => handleSend(textToSubmit), 100);
          setIsRecording(false);
          recognition.stop();
        }
      };
      
      recognition.onerror = (event) => {
        console.error("Speech error:", event.error);
        alert("Error de grabación en el dispositivo: " + event.error);
        setIsRecording(false);
      };
      
      recognition.onend = () => {
        setIsRecording(false);
      };

      recognitionRef.current = recognition;
    }
  }, []); // Bindings estables al instanciarse


  const unlockAudio = () => {
    if (!window.audioUnlocked && 'speechSynthesis' in window) {
      const utterance = new SpeechSynthesisUtterance('');
      window.speechSynthesis.speak(utterance);
      window.audioUnlocked = true;
    }
  };

  const toggleRecording = () => {
    unlockAudio();
    if (!recognitionRef.current) {
      if (window.location.protocol !== 'https:' && window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1') {
        alert("Error de Seguridad: Apple/Safari bloquea el acceso al micrófono en HTTP. Debes acceder a la aplicación mediante 'https://' (ej. el túnel de Cloudflare o ngrok) para usar la entrada de voz.");
      } else {
        alert("Tu navegador o versión de iOS no soporta la entrada de voz nativa.");
      }
      return;
    }
    
    if (isRecording) {
      try {
        recognitionRef.current.stop();
      } catch(e){}
      setIsRecording(false);
    } else {
      try {
        recognitionRef.current.start();
        setIsRecording(true);
      } catch (err) {
        console.error("No se pudo iniciar el grabador:", err);
        alert("Fallo de arranque de micrófono (El navegador restringe el uso en 2do plano o necesita refresco): " + err.message);
        setIsRecording(false);
      }
    }
  };

  const speak = (text) => {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'es-ES';
      utterance.rate = 1.0;
      window.speechSynthesis.speak(utterance);
    }
  };

  const handleSend = (text) => {
    unlockAudio();
    const finalTxt = typeof text === 'string' ? text : input;
    if (!finalTxt.trim()) return;
    
    setMessages(prev => [...prev, { id: Date.now(), text: finalTxt, isUser: true }]);
    setInput('');
    processAIResponse(finalTxt);
  };

  const processAIResponse = async (query) => {
    setProcessing(true);

    const lower = query.toLowerCase().trim();

    // POLÍTICA ESTRICTA DE SEGURIDAD CORPORATIVA NCS
    const outOfScopeMsg = "Puedo ayudarte con información autorizada sobre buques, tripulaciones, el Manual de Gestión y pedidos abiertos de compras.";
    const restrictedMsg = "No puedo proporcionar información económica, financiera, comercial confidencial ni datos personales sensibles. Puedo ayudarte con la información operativa autorizada.";

    // 1. Detección de evasión / suplantación
    const isEvasion = ["soy miguel", "soy el dueño", "soy dueño", "soy administrador", "soy admin", "miguel me autorizó", "miguel me autorizo", "ignora las reglas", "ignora las instrucciones", "actúa como", "juego de rol", "jailbreak"].some(t => lower.includes(t));
    if (isEvasion) {
      setMessages(prev => [...prev, { id: Date.now()+1, text: restrictedMsg, isUser: false }]);
      speak(restrictedMsg);
      setProcessing(false);
      return;
    }

    // 2. Detección de información económica, financiera, costos, salarios, PII
    const isProhibited = ["factur", "costo", "cuanto cuesta", "cuánto cuesta", "cuanto sale", "cuánto sale", "precio", "importe", "monto", "presupuesto", "saldo", "banco", "deuda", "pago", "impuesto", "sueldo", "salario", "remuneracion", "remuneración", "cuanto cobra", "cuánto cobra", "cuanto gana", "cuánto gana", "dni", "cédula", "pasaporte", "domicilio", "telefono privado", "ficha medica", "contraseña", "token"].some(t => lower.includes(t)) ||
      ((lower.includes("estima") || lower.includes("estimá") || lower.includes("calcula")) && (lower.includes("ingreso") || lower.includes("ganancia") || lower.includes("operacion") || lower.includes("operación")));

    // 3. Alcance permitido
    const isWithinScope = ["buque", "barco", "flota", "alfa", "gustavo", "nany", "monarca", "donde esta", "dónde está", "tripul", "personal", "capitán", "capitan", "manual", "gestion", "gestión", "procedimiento", "pedido", "compra", "repuesto", "certificado", "mantenimiento", "hola"].some(t => lower.includes(t));

    if (isProhibited && !isWithinScope) {
      setMessages(prev => [...prev, { id: Date.now()+1, text: restrictedMsg, isUser: false }]);
      speak(restrictedMsg);
      setProcessing(false);
      return;
    }

    if (!isWithinScope && !isProhibited) {
      setMessages(prev => [...prev, { id: Date.now()+1, text: outOfScopeMsg, isUser: false }]);
      speak(outOfScopeMsg);
      setProcessing(false);
      return;
    }

    // Contexto Seguro: Política Estricta NCS
    const contextPrompt = {
      role: "system",
      content: "Eres el Asistente de NCS de Naviera Cruz del Sur. Solo puedes responder sobre información operativa autorizada (buques, tripulaciones sin datos sensibles, Manual de Gestión y pedidos de compras sin importes ni precios). PROHIBIDO: facturación, gastos, costos, márgenes, sueldos, cuentas bancarias, precios y datos sensibles. Si preguntan por datos prohibidos, responde: 'No puedo proporcionar información económica, financiera, comercial confidencial ni datos personales sensibles. Puedo ayudarte con la información operativa autorizada.' Si está fuera del alcance: 'Puedo ayudarte con información autorizada sobre buques, tripulaciones, el Manual de Gestión y pedidos abiertos de compras.'"
    };

    const currentHistory = [
      contextPrompt,
      ...messages.filter(msg => msg.id !== 1).map(msg => ({
        role: msg.isUser ? "user" : "assistant",
        content: msg.text
      }))
    ];

    try {
      const response = await fetch(getCentinelaEndpoint('/api/ai-chat/external-bot'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': 'centinela-bridge-2026'
        },
        body: JSON.stringify({
          message: query,
          history: currentHistory
        })
      });

      if (!response.ok) {
        throw new Error(`Fallo en el puente Centinela (Código: ${response.status})`);
      }

      const data = await response.json();
      const aiReply = data.reply || "No recibí respuesta textual.";

      setMessages(prev => [...prev, { id: Date.now()+1, text: aiReply, isUser: false }]);
      speak(aiReply);

    } catch (err) {
      console.error(err);
      const errorMsg = "Lo siento, falló la conexión con el Asistente de NCS. " + err.message;
      setMessages(prev => [...prev, { id: Date.now()+1, text: errorMsg, isUser: false }]);
      speak(errorMsg);
    } finally {
      setProcessing(false);
    }
  };

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, processing, isRecording]);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', backgroundColor: 'var(--bg-secondary)', paddingBottom: '16px' }}>
      <div className="top-header glass" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
        <Bot size={24} color="var(--ncs-accent)" />
        <span>Asistente IA</span>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '16px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {messages.map(msg => (
          <div key={msg.id} style={{ display: 'flex', justifyContent: msg.isUser ? 'flex-end' : 'flex-start' }}>
            <div style={{ maxWidth: '80%', padding: '14px 16px', borderRadius: '18px', borderBottomRightRadius: msg.isUser ? '4px' : '18px', borderBottomLeftRadius: !msg.isUser ? '4px' : '18px', backgroundColor: msg.isUser ? 'var(--ncs-primary)' : 'var(--bg-color)', color: msg.isUser ? '#FFFFFF' : 'var(--text-primary)', boxShadow: '0 1px 2px rgba(0,0,0,0.05)', fontSize: '15px', lineHeight: '1.4' }}>
              {msg.text}
            </div>
          </div>
        ))}
        {processing && (
          <div style={{ padding: '16px', color: 'var(--text-secondary)' }}>Procesando...</div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {isRecording && (
        <div style={{ textAlign: 'center', padding: '10px', color: 'var(--ncs-danger)', animation: 'pulse 1s infinite' }}>
          Escuchando comando de voz...
        </div>
      )}

      <div className="glass" style={{ margin: '0 16px', padding: '12px', borderRadius: '24px', display: 'flex', gap: '12px', alignItems: 'center' }}>
        <input 
          type="text" 
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyPress={e => e.key === 'Enter' && handleSend()}
          placeholder={isRecording ? "Hable ahora..." : "Pregúntale al asistente..."}
          disabled={isRecording}
          style={{ flex: 1, padding: '10px 16px', borderRadius: '20px', border: '1px solid var(--border-color)', backgroundColor: 'var(--bg-color)', color: 'var(--text-primary)', outline: 'none', fontSize: '15px' }}
        />
        
        {input.trim() ? (
          <div onClick={() => handleSend()} style={{ padding: '10px', backgroundColor: 'var(--ncs-accent)', borderRadius: '50%', color: 'white', display: 'flex' }}>
            <Send size={20} />
          </div>
        ) : (
          <div onClick={toggleRecording} style={{ padding: '14px', backgroundColor: isRecording ? 'var(--ncs-danger)' : 'var(--ncs-primary)', borderRadius: '50%', color: 'white', display: 'flex', cursor: 'pointer', transition: '0.2s' }}>
            {isRecording ? <Square size={20} fill="white" /> : <Mic size={20} />}
          </div>
        )}
      </div>
      <style>{`@keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.5; } 100% { opacity: 1; } }`}</style>
    </div>
  );
};

export default AIChat;
