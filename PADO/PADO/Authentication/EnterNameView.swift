//
//  EnterNameView.swift
//  BeReal
//
//  Created by 강치우 on 1/2/24.
//

import SwiftUI

struct EnterNameView: View {
    
    @Binding var name: String
    @State var buttonActive = false
    
    @Binding var nameButtonClicked: Bool
    
    @EnvironmentObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        VStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    HStack {
                        Spacer()
                        
                        Text("PADO.")
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                            .font(.system(size: 22))
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                
                VStack {
                    VStack(alignment: .center, spacing: 8) {
                        Text("파도에 오신걸 환영합니다. 이름을 입력해주세요")
                            .fontWeight(.heavy)
                            .font(.system(size: 16))
                        
                        Text(name.isEmpty ? "NAME" : "s")
                            .foregroundStyle(name.isEmpty ? Color(red: 70/255, green: 70/255, blue: 73/255) : Color.black)
                            .fontWeight(.heavy)
                            .font(.system(size: 40))
                            .frame(width: 210)
                            .overlay {
                                TextField("", text: $name)
                                    .font(.system(size: 40))
                                    .fontWeight(.heavy)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.white)
                            }
                    }
                    .foregroundStyle(.white)
                    
                    Spacer()
                }
                .padding(.top, 50)
                
                VStack {
                    Spacer()
                    
                    Button {
                        if buttonActive {
                            self.nameButtonClicked = true
                        } else {
                            self.buttonActive = false
                        }
                    } label: {
                        WhiteButtonView(buttonActive: $buttonActive, text: "계속하기")
                            .onChange(of: name) { oldValue, newValue in
                                if !newValue.isEmpty {
                                    buttonActive = true
                                } else if newValue.isEmpty {
                                    buttonActive = false
                                }
                            }
                    }
                }
            }
        }
        .onAppear() {
            name = ""
        }
    }
}

//#Preview {
//    EnterNameView()
//}
