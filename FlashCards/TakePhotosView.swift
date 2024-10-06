//
//  NewDeckView.swift
//  FlashCards
//
//  Created by Lucas Meijer on 06/10/2024.
//

import SwiftUI

struct TakePhotosView: View {
    @State private var images: [UIImage] = []
    @State private var showImagePicker = false
    
    var body: some View {
        VStack {
            Spacer()
            ScrollView(.horizontal) {
                HStack {
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300)
                            .padding()
                    }
                }
            }.frame(height: 500)
            
            Spacer()
            
            Button(action: {
                showImagePicker = true
            }) {
                HStack {
                    Image(systemName: "camera")
                        .font(.system(size: 20))
                    let l = images.isEmpty
                        ? "Take a photo of your learning material"
                        : "Take another photo"
                    Text(l)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, minHeight:60)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)

            NavigationLink(destination: UploadPhotosView(images:images))
            {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 20))
                    Text("Lets Go!")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, minHeight:60)
                .padding()
                .background(Color.blue)
                .opacity(images.isEmpty ? 0.4 : 1)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(images.isEmpty)
            
            Spacer()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(images: $images)
        }
    }
}

#Preview {
    TakePhotosView()
}



struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.showsCameraControls = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
    
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.images.append(image)
                print("Image added to the list. Total images: \(parent.images.count)")
        }
            picker.dismiss(animated: true)
        }
    }
}
