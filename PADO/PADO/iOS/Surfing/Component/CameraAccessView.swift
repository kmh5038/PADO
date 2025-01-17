//
//  CameraAccessView.swift
//  PADO
//
//  Created by 최동호 on 1/25/24.
//

import SwiftUI

struct CameraAccessView: UIViewControllerRepresentable {
    @Binding var isShown: Bool
    @Binding var myimage: Image
    @Binding var myUIImage: UIImage
    @Binding var mysourceType: UIImagePickerController.SourceType
    @Binding var mycameraDevice: UIImagePickerController.CameraDevice
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<CameraAccessView>) {
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraAccessView>) -> UIImagePickerController {
        let obj = UIImagePickerController()
        obj.sourceType = mysourceType
        obj.cameraDevice = mycameraDevice
        obj.delegate = context.coordinator
        return obj
    }
    
    func makeCoordinator() -> CameraCoordinator {
        return CameraCoordinator(isShown: $isShown, myimage: $myimage, myUIImage: $myUIImage)
    }
}
