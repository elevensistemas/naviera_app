import SwiftUI
import PhotosUI

struct ReportIncidentView: View {
    @ObservedObject var viewModel: IncidentViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var description: String = ""
    @State private var shipId: String = "" // Placeholder for dropdown
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalles del Incidente")) {
                    TextField("Identificador de Barco (Ej. s1)", text: $shipId)
                        .autocapitalization(.none)
                    
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                Section(header: Text("Evidencia")) {
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text(selectedImage == nil ? "Adjuntar Fotografía" : "Cambiar Fotografía")
                            }
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    selectedImage = uiImage
                                }
                            }
                        }
                    
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .cornerRadius(8)
                            .padding(.vertical, 4)
                    }
                }
                
                Section {
                    Button(action: {
                        guard !description.isEmpty, !shipId.isEmpty else { return }
                        var photos: [Data] = []
                        if let img = selectedImage, let data = img.jpegData(compressionQuality: 0.8) {
                            photos.append(data)
                        }
                        viewModel.reportIncident(description: description, shipId: shipId, photos: photos)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text("Enviar Reporte HSE")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                    .disabled(description.isEmpty || shipId.isEmpty || viewModel.isLoading)
                    .foregroundColor(description.isEmpty || shipId.isEmpty ? .gray : .white)
                    .listRowBackground(description.isEmpty || shipId.isEmpty ? ColorTheme.secondaryBackground : ColorTheme.danger)
                }
            }
            .navigationTitle("Nuevo Incidente")
            .navigationBarItems(leading: Button("Cancelar") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
