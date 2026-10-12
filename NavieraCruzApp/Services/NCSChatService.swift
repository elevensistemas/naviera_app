import Foundation

protocol NCSChatServiceProtocol {
    func streamChatResponse(prompt: String) -> AsyncThrowingStream<NCSStreamEvent, Error>
    func getTTSAudioURL(for text: String) -> URL?
}

class NCSChatService: NCSChatServiceProtocol {
    static let shared = NCSChatService()
    
    private let baseURL = AppConfig.apiBaseURL
    
    /// Returns a URL for TTS streaming MP3 audio
    func getTTSAudioURL(for text: String) -> URL? {
        let trimmedText = text.prefix(500) // Keep text length optimized for audio generation
        guard let encodedText = String(trimmedText).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "\(baseURL)/api/chat/tts?text=\(encodedText)")
    }
    
    /// Streams NDJSON response from /api/chat/ via AsyncSequence (URLSession.shared.bytes)
    func streamChatResponse(prompt: String) -> AsyncThrowingStream<NCSStreamEvent, Error> {
        // If mock mode is active (App Store review or offline dev), return mock NDJSON stream
        if AppConfig.isMockActive {
            return mockStreamChatResponse(prompt: prompt)
        }
        
        return AsyncThrowingStream { continuation in
            let task = Task {
                guard let url = URL(string: "\(baseURL)/api/chat/") else {
                    continuation.finish(throwing: NetworkError.invalidURL)
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("application/x-ndjson", forHTTPHeaderField: "Accept")
                
                // Inject Bearer / Token authorization header if logged in
                if let tokenData = KeychainManager.shared.load(key: "com.navieracruz.authToken"),
                   let token = String(data: tokenData, encoding: .utf8) {
                    request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
                }
                
                let bodyDict: [String: Any] = ["message": prompt]
                guard let httpBody = try? JSONSerialization.data(withJSONObject: bodyDict) else {
                    continuation.finish(throwing: NetworkError.decodingError)
                    return
                }
                request.httpBody = httpBody
                
                do {
                    // Non-blocking streaming using URLSession.shared.bytes AsyncSequence
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: NetworkError.unknown)
                        return
                    }
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        if httpResponse.statusCode == 401 {
                            continuation.finish(throwing: NetworkError.unauthorized)
                        } else {
                            continuation.finish(throwing: NetworkError.serverError(httpResponse.statusCode))
                        }
                        return
                    }
                    
                    let decoder = JSONDecoder()
                    
                    for try await line in bytes.lines {
                        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedLine.isEmpty, let data = trimmedLine.data(using: .utf8) else {
                            continue
                        }
                        
                        do {
                            let event = try decoder.decode(NCSStreamEvent.self, from: data)
                            continuation.yield(event)
                        } catch {
                            print("⚠️ Error decodificando linea NDJSON: \(trimmedLine), error: \(error)")
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    print("❌ Error en conexión de streaming: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    // MARK: - Mock NDJSON Stream Generator for App Store Review & Dev Testing
    private func mockStreamChatResponse(prompt: String) -> AsyncThrowingStream<NCSStreamEvent, Error> {
        return AsyncThrowingStream { continuation in
            let task = Task {
                let lowerPrompt = prompt.lowercased()
                
                // Event 1: Initial Log
                try? await Task.sleep(nanoseconds: 400_000_000)
                continuation.yield(NCSStreamEvent(type: "log", logClass: "info", content: "Iniciando consulta a NCS Control Center...", structured: nil))
                
                // Event 2: Telemetry Check Log
                try? await Task.sleep(nanoseconds: 600_000_000)
                continuation.yield(NCSStreamEvent(type: "log", logClass: "info", content: "Verificando telemetría satelital GPS y sensores de motor...", structured: nil))
                
                // Event 3: Weather & Route Log
                try? await Task.sleep(nanoseconds: 500_000_000)
                continuation.yield(NCSStreamEvent(type: "log", logClass: "info", content: "Analizando condiciones meteorológicas en Canal Ancud...", structured: nil))
                
                try? await Task.sleep(nanoseconds: 700_000_000)
                
                // Construct realistic answer based on query
                let responseText: String
                let structuredData: NCSStructuredVesselData
                
                if lowerPrompt.contains("combustible") || lowerPrompt.contains("fuel") || lowerPrompt.contains("tanque") {
                    responseText = """
                    ### Reporte de Combustible y Eficiencia - **Naviera I**

                    El buque **Naviera I** registra un nivel óptimo de combustible para el trayecto actual.

                    - **Autonomía restante:** 34 horas de navegación continua.
                    - **Consumo promedio:** 142 L/h a velocidad de crucero (12.4 nudos).
                    - **Recomendación:** Mantener velocidad actual para asegurar llegada dentro del margen operativo.
                    """
                    structuredData = NCSStructuredVesselData(
                        vesselName: "Naviera I",
                        status: "Navegando (En Ruta)",
                        speed: "12.4 nudos",
                        coordinates: "41°48'S 73°45'W",
                        eta: "Hoy 18:30 hrs",
                        fuelLevel: "78%",
                        cargoWeight: "1,850 Ton"
                    )
                } else if lowerPrompt.contains("eta") || lowerPrompt.contains("puerto") || lowerPrompt.contains("llegada") {
                    responseText = """
                    ### Estado de Travesía y ETA - **Naviera I**

                    El buque se encuentra cumpliendo el itinerario previsto sin desviaciones meteorológicas.

                    * **Puerto de Destino:** Puerto Montt - Sitio 2.
                    * **ETA estimado:** hoy a las **18:30 hrs** (-03:00).
                    * **Condición de marea:** Marejada leve, viento NNO 12 nudos.
                    * **Práctico asignado:** Capitán Roberto Silva (Confirmado).
                    """
                    structuredData = NCSStructuredVesselData(
                        vesselName: "Naviera I",
                        status: "A tiempo",
                        speed: "12.8 nudos",
                        coordinates: "41°52'S 73°12'W",
                        eta: "18:30 hrs",
                        fuelLevel: "82%",
                        cargoWeight: "2,100 Ton"
                    )
                } else if lowerPrompt.contains("tripul") || lowerPrompt.contains("capitán") || lowerPrompt.contains("personal") {
                    responseText = """
                    ### Dotación y Tripulación Operativa

                    La tripulación activa en **Naviera I** cumple al 100% las normativas STCW y descanso reglamentario:

                    1. **Capitán:** Juan Pérez V.
                    2. **Primer Oficial:** Marcelo Soto.
                    3. **Jefe de Máquinas:** Andrés Morales.
                    4. **Personal de cubierta:** 6 marineros habilitados.

                    > Status HSE: **0 incidentes registrados** en los últimos 90 días.
                    """
                    structuredData = NCSStructuredVesselData(
                        vesselName: "Naviera I",
                        status: "Tripulación Completa",
                        speed: "11.5 nudos",
                        coordinates: "41°40'S 73°20'W",
                        eta: "Mañana 08:00",
                        fuelLevel: "91%",
                        cargoWeight: "1,400 Ton"
                    )
                } else {
                    responseText = """
                    ### NCS Control Center - Asistente Operativo IA

                    Procesamiento completado para: *\(prompt)*.

                    - **Estado General de Flota:** 2 Buques operativos en alta mar, 1 en mantenimiento programado.
                    - **Red de sensores:** Sensores IoT y telemetría funcionando normalmente.
                    - **Monitoreo en tiempo real:** Todos los sistemas operando dentro de parámetros nominales.

                    *Verifique las coordenadas y datos de manifiesto antes de la maniobra de atracado.*
                    """
                    structuredData = NCSStructuredVesselData(
                        vesselName: "Naviera I (Principal)",
                        status: "Operación Normal",
                        speed: "12.0 nudos",
                        coordinates: "41°45'S 73°30'W",
                        eta: "18:30 hrs",
                        fuelLevel: "85%",
                        cargoWeight: "1,850 Ton"
                    )
                }
                
                // Final Event: Result
                continuation.yield(NCSStreamEvent(
                    type: "result",
                    logClass: nil,
                    content: responseText,
                    structured: structuredData
                ))
                
                continuation.finish()
            }
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
