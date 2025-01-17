//
//  FollowMainView.swift
//  PADO
//
//  Created by 강치우 on 2/1/24.
//

import SwiftUI

struct FollowMainView: View {
    @State var currentType: String
    @Namespace var animation
    @Environment (\.dismiss) var dismiss
    
    @ObservedObject var followVM: FollowViewModel
    
    let user: User
    
    var body: some View {
        NavigationStack {
            VStack {
                pinnedHeaderView()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        LazyVStack(pinnedViews: [.sectionHeaders]) {
                            postList()
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden()
            .background(.main)
        }
    }
    
    @ViewBuilder
    func pinnedHeaderView() -> some View {
        let types: [String] = ["팔로워", "팔로잉"]
        
        HStack(spacing: 25) {
            ForEach(types, id: \.self) { type in
                VStack(spacing: 12) {
                    Text(type)
                        .foregroundStyle(currentType == type ? .white : .gray)
                        .font(.system(size: 14))
                        .fontWeight(.medium)
                    
                    ZStack {
                        if currentType == type {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(.white)
                                .matchedGeometryEffect(id: "TAB", in: animation)
                        } else {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(.clear)
                        }
                    }
                    .frame(height: 1)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .frame(width: UIScreen.main.bounds.width, height: 0.5)
                            .foregroundStyle(Color(.systemGray2))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        currentType = type
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 25)
        .padding(.bottom, 15)
    }
    
    @ViewBuilder
    func postList() -> some View {
        switch currentType {
        case "팔로워":
            FollowerView(followVM: followVM,
                         user: user)
        case "팔로잉":
            FollowingView(followVM: followVM)
        default:
            EmptyView()
        }
    }
}
