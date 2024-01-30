//
//  FollowerUserCellView.swift
//  PADO
//
//  Created by 황성진 on 1/16/24.
//

import Kingfisher
import SwiftUI

struct FollowerUserCellView: View {
    // MARK: - PROPERTY
    @State var followerUsername: String = ""
    @State var followerProfileUrl: String = ""
    
    let cellUserId: String
    
    enum SufferSet: String {
        case removesuffer = "서퍼 해제"
        case setsuffer = "서퍼 등록"
    }
    
    @State private var buttonActive: Bool = false
    @State var transitions: Bool = false
    
    let sufferset: SufferSet
    
    // MARK: - BODY
    var body: some View {
        HStack {
            HStack(spacing: 0) {
                KFImage.url(URL(string: followerProfileUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .cornerRadius(70)
                    .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text(cellUserId)
                        .font(.system(size: 14, weight: .semibold))
                    if !followerUsername.isEmpty {
                        Text(followerUsername)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color(.systemGray))
                    }
                } //: VSTACK
            }
            
            Spacer()
            
            if transitions {
                Button {
                    withAnimation(.easeIn(duration: 0.5)) {
                        transitions = false
                    }
                } label: {
                    Text(sufferset.rawValue)
                        .padding()
                        .foregroundStyle(.black)
                        .background(.white)
                        .frame(height: 30)
                }
                .offset(x: 8)
                
                Button {
                    withAnimation(.easeIn(duration: 0.5)) {
                        transitions = false
                    }
                } label: {
                    Text("삭제")
                        .padding()
                        .foregroundColor(.white)
                        .background(.red)
                        .frame(height: 30)
                }
            }
            
        } //: HSTACK
        .onAppear {
            Task {
                let updateUserData = UpdateUserData()
                if let userProfile = await updateUserData.getOthersProfileDatas(id: cellUserId) {
                    self.followerUsername = userProfile.username
                    self.followerProfileUrl = userProfile.profileImageUrl ?? ""
                }
            }
        }
        // contentShape 를 사용해서 H스택 전체적인 부분에 대해 패딩을 줌
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged({ value in
                    if value.translation.width < 0 { // 왼쪽으로 스와이프하는 경우에만
                        withAnimation(.easeIn(duration: 0.5)) {
                            transitions = true
                        }
                    }
                })
        )
        .onTapGesture {
            withAnimation(.easeIn(duration: 0.5)) {
                transitions = false
            }
        }
    }
}