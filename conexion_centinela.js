// =========================================================================
// MÓDULO PUENTE: BOT -> CENTINELA
// Archivo para copiar y ejecutar en tu segundo servidor (192.168.2.9)
// =========================================================================

// PASO 1: Especificar la IP real de la computadora donde está Centinela.
// Si Centinela está en 192.168.2.14, pon esa IP aquí:
const CENTINELA_IP = '192.168.2.121';
const CENTINELA_PORT = 3001; 
const API_KEY = 'centinela-bridge-2026';

/**
 * Función central pura para comunicarte con Centinela.
 * Requisito: Node.js versión 18 o superior (para usar fetch nativo).
 * 
 * Puedes llamar a esta función desde las tripas de tu bot de WhatsApp o App 2.
 */
async function consultarACentinela(mensajeDeTexto, historialConversacion = []) {
    try {
        console.log(`\n[Bot 2.9] -> Interrogando a Centinela: "${mensajeDeTexto}"`);
        
        const response = await fetch(`http://${CENTINELA_IP}:${CENTINELA_PORT}/api/ai-chat/external-bot`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'x-api-key': API_KEY
            },
            body: JSON.stringify({
                message: mensajeDeTexto,
                history: historialConversacion
            })
        });

        if (!response.ok) {
            const errorObj = await response.json().catch(() => ({}));
            throw new Error(errorObj.error || `Fallo en el servidor Centinela (HTTP ${response.status})`);
        }

        const data = await response.json();
        console.log(`\n🤖 [Centinela - La Bombonera Responde]:\n${data.reply}\n`);
        return data.reply;
        
    } catch (error) {
        console.error('❌ [Alerta] No se pudo cruzar el puente de IA:', error.message);
        return "Alerta de sistema: El enlace de red con Centinela se encuentra inactivo.";
    }
}

// =========================================================================
// ZONA DE PRUEBA RÁPIDA
// Si abres la consola en tu servidor 192.168.2.9 y escribes:
// node conexion_centinela.js
// Se ejecutará automáticamente esta prueba:
// =========================================================================
if (require.main === module) {
    const preguntaDePrueba = "Hola colega, necesito que me informes qué barco está descargando actualmente y el clima general.";
    consultarACentinela(preguntaDePrueba)
        .then(() => console.log("\n-> Prueba de cruce entre servidores finalizada."))
        .catch(err => console.log("Error en prueba", err));
}

// Exportamos la función para que tu app o bot en la 2.9 pueda integrarla
module.exports = { consultarACentinela };
