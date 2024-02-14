//
//  DrawingView.swift
//  PADO
//
//  Created by 김명현 on 2/8/24.
//

import PhotosUI
import SwiftUI

struct DrawingView: View {
    @ObservedObject var padorideVM: PadoRideViewModel
    
    var body: some View {
        ZStack {
            GeometryReader { proxy -> AnyView in
                
                let size = proxy.frame(in: .global)
                
                DispatchQueue.main.async {
                    if padorideVM.rect == .zero {
                        padorideVM.rect = ImageRatioResize.shared.resizedImageRect(for: padorideVM.selectedUIImage ?? UIImage(), targetSize: CGSize(width: 300, height: 500))
                    }
                }
                
                return AnyView(
                    ZStack {
                        CanvasView(padorideVM: padorideVM,
                                   canvas: $padorideVM.canvas,
                                   toolPicker: $padorideVM.toolPicker,
                                   rect: size.size)
                        .onTapGesture {
                            Task {
                                padorideVM.toolPicker.setVisible(true, forFirstResponder: padorideVM.canvas)
                                padorideVM.canvas.becomeFirstResponder()
                            }
                        }
                        
                        ForEach(padorideVM.textBoxes) { box in
                            
                            Text(padorideVM.textBoxes[padorideVM.currentTextIndex].id == box.id && padorideVM.addNewBox ? "" : box.text)
                                .font(.system(size: 30))
                                .fontWeight(box.isBold ? .bold : .none)
                                .foregroundColor(box.textColor)
                                .offset(box.offset)
                                .rotationEffect(box.rotation)
                                .scaleEffect(box.scale)
                                .gesture(
                                    DragGesture()
                                        .onChanged({ value in
                                            let currentTranslation = value.translation
                                            // 크기 조정을 고려한 이동 값 조정
                                            let scale = padorideVM.textBoxes[getTextIndex(textBox: box)].scale // 현재 상자의 scale 값 가져오기
                                            let adjustedTranslation = CGSize(
                                                width: (currentTranslation.width + box.lastOffset.width) / scale, // scale에 따라 조정
                                                height: (currentTranslation.height + box.lastOffset.height) / scale // scale에 따라 조정
                                            )
                                            padorideVM.textBoxes[getTextIndex(textBox: box)].offset = adjustedTranslation
                                        })
                                        .simultaneously(with:
                                            MagnificationGesture()
                                                .onChanged({ value in
                                                    padorideVM.textBoxes[getTextIndex(textBox: box)].scale = box.lastScale * value
                                                })
                                                .onEnded({ value in
                                                    padorideVM.textBoxes[getTextIndex(textBox: box)].lastScale = padorideVM.textBoxes[getTextIndex(textBox: box)].scale
                                                })
                                                .simultaneously(with:
                                                    RotationGesture()
                                                        .onChanged({ value in
                                                            padorideVM.textBoxes[getTextIndex(textBox: box)].rotation = box.lastRotation + value
                                                        })
                                                        .onEnded({ value in
                                                            padorideVM.textBoxes[getTextIndex(textBox: box)].lastRotation = padorideVM.textBoxes[getTextIndex(textBox: box)].rotation
                                                        })
                                                )
                                        )
                                )
                                .onLongPressGesture {
                                    padorideVM.toolPicker.setVisible(false, forFirstResponder: padorideVM.canvas)
                                    padorideVM.canvas.resignFirstResponder()
                                    padorideVM.currentTextIndex = getTextIndex(textBox: box)
                                    withAnimation{
                                        padorideVM.addNewBox = true
                                    }
                                }
                        }
                        
                        ForEach(padorideVM.imageBoxes) { box in
                            
                            box.image
                                .resizable()
                                .frame(width: 100, height: 100)
                                .rotationEffect(box.rotation)
                                .scaleEffect(box.scale)
                                .offset(box.offset)
                                .gesture(
                                    DragGesture()
                                        .onChanged({ value in
                                            let current = value.translation
                                            let newTranslation = CGSize(width: box.lastOffset.width + current.width, height: box.lastOffset.height + current.height)
                                            padorideVM.imageBoxes[getImageIndex(imageBox: box)].offset = newTranslation
                                        })
                                        .onEnded({ value in
                                            padorideVM.imageBoxes[getImageIndex(imageBox: box)].lastOffset = padorideVM.imageBoxes[getImageIndex(imageBox: box)].offset
                                        })
                                        .simultaneously(with:
                                            MagnificationGesture()
                                                .onChanged({ value in
                                                    padorideVM.imageBoxes[getImageIndex(imageBox: box)].scale = box.lastScale * value
                                                })
                                                .onEnded({ value in
                                                    padorideVM.imageBoxes[getImageIndex(imageBox: box)].lastScale = padorideVM.imageBoxes[getImageIndex(imageBox: box)].scale
                                                })
                                                .simultaneously(with:
                                                    RotationGesture()
                                                        .onChanged({ value in
                                                            padorideVM.imageBoxes[getImageIndex(imageBox: box)].rotation = box.lastRotation + value
                                                        })
                                                        .onEnded({ value in
                                                            padorideVM.imageBoxes[getImageIndex(imageBox: box)].lastRotation = padorideVM.imageBoxes[getImageIndex(imageBox: box)].rotation
                                                        })
                                                )
                                        )
                                )
                                .onLongPressGesture {
                                    padorideVM.toolPicker.setVisible(false, forFirstResponder: padorideVM.canvas)
                                    padorideVM.canvas.resignFirstResponder()
                                    padorideVM.currentImageIndex = getImageIndex(imageBox: box)
                                }
                        }
                    }
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if padorideVM.toolPicker.isVisible {
                        padorideVM.toolPicker.setVisible(false, forFirstResponder: padorideVM.canvas)
                        padorideVM.canvas.resignFirstResponder()
                    } else {
                        Task {
                            padorideVM.toolPicker.setVisible(true, forFirstResponder: padorideVM.canvas)
                            padorideVM.canvas.becomeFirstResponder()
                        }
                    }
                } label: {
                    Image(systemName: "scribble")
                        .foregroundStyle(.white)
                }
                
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                PhotosPicker(selection: $padorideVM.pickerImageItem) {
                    Image(systemName: "photo")
                        .resizable()
                        .frame(width: 25, height: 20)
                }
                .onChange(of: padorideVM.pickerImageItem) { _, _ in
                    Task {
                        await padorideVM.loadImageFromPickerItem(padorideVM.pickerImageItem)
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button{
                    padorideVM.textBoxes.append(TextBox())
                    
                    padorideVM.currentTextIndex = padorideVM.textBoxes.count - 1
                    
                    withAnimation{
                        padorideVM.addNewBox.toggle()
                    }
                    padorideVM.toolPicker.setVisible(false, forFirstResponder: padorideVM.canvas)
                    padorideVM.canvas.resignFirstResponder()
                } label: {
                    Image(systemName: "t.square")
                        .foregroundStyle(.white)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button{
                    padorideVM.showingModal = true
                    padorideVM.saveImage()
                } label: {
                    Text("다음")
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $padorideVM.showingModal) {
            SendPadoView(padorideVM: padorideVM)
                .presentationDetents([.fraction(0.2)])
        }
    }
    
    func getTextIndex(textBox: TextBox) -> Int {
        
        let index = padorideVM.textBoxes.firstIndex { (box) -> Bool in
            return textBox.id == box.id
        } ?? 0
        
        return index
    }
    
    func getImageIndex(imageBox: ImageBox) -> Int {
        
        let index = padorideVM.imageBoxes.firstIndex { (box) -> Bool in
            return imageBox.id == box.id
        } ?? 0
        
        return index
    }
}
