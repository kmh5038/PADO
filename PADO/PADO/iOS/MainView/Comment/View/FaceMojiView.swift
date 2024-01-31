//
//  FaceMoji.swift
//  PADO
//
//  Created by 최동호 on 1/16/24.
//

import SwiftUI

struct FaceMojiView: View {
    @ObservedObject var viewModel: SurfingViewModel
    
    let emotions: [Emotion] = Emotion.allCases
    let users: [String] = ["DogStar", "Hsunjin", "pinkSo"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Array(zip(emotions, users)), id: \.0.self) { (emotion, user) in
                        FaceMojiCell(emotion: emotion, faceMojiUser: user)
                            .padding(.horizontal, 6)
                }
                Button {
                    // 페이스모지 열기
                    viewModel.checkCameraPermission {
                        viewModel.isShownCamera.toggle()
                        viewModel.sourceType = .camera
                        viewModel.pickerResult = []
                        viewModel.selectedImage = nil
                        viewModel.selectedUIImage = Image(systemName: "photo")
                    }
                } label: {
                    VStack {
                        Image("face.dashed")
                            .resizable()
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                     
                        Text("")
                            
                    }
                }
                .padding(.horizontal)
                .sheet(isPresented: $viewModel.isShownCamera) {
                    CameraAccessView(isShown: $viewModel.isShownCamera, myimage: $viewModel.cameraImage, myUIImage: $viewModel.cameraUIImage, mysourceType: $viewModel.sourceType)
                }

            }
        }
    }
}
