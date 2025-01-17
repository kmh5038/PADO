//
//  PadoRideNotificationCell.swift
//  PADO
//
//  Created by 황민채 on 2/17/24.
//

import Kingfisher
import SwiftUI

struct PadoRideNotificationCell: View {
    @ObservedObject var profileVM: ProfileViewModel
    @ObservedObject var feedVM: FeedViewModel
    
    @State var sendUserProfileUrl: String = ""
    @State var sendPostUrl: String = ""
    @State var sendPost: Post? = nil
    
    @State private var showPost = false
    
    var notification: Noti
    
    var body: some View {
        Button {
            if sendPost != nil {
                showPost = true
            }
        } label: {
            HStack(spacing: 0) {
                if let image = URL(string: sendUserProfileUrl) {
                    KFImage(image)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(40)
                        .padding(.trailing)
                } else {
                    Image("defaultProfile")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(40)
                        .padding(.trailing)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(notification.sendUser)님에게 새로운 파도타기가 도착했어요 ")
                            .font(.system(size: 14))
                            .fontWeight(.medium)
                        +
                        Text(notification.createdAt.formatDate(notification.createdAt))
                            .font(.system(size: 12))
                            .foregroundStyle(Color(.systemGray))
                    }
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                }
                
                Spacer()
                
                if let image = URL(string: sendPostUrl) {
                    KFImage(image)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
        }
        .sheet(isPresented: $showPost) {
            if let post = sendPost {
                OnePostModalView(feedVM: feedVM,
                                 profileVM: profileVM,
                                 post: post)
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            Task {
                if let sendUserProfile = await UpdateUserData.shared.getOthersProfileDatas(id: notification.sendUser) {
                    self.sendUserProfileUrl = sendUserProfile.profileImageUrl ?? ""
                }
                
                if let sendPost = await
                    UpdatePostData.shared.fetchPostById(postId: notification.postID ?? "") {
                    self.sendPostUrl = sendPost.imageUrl
                    self.sendPost = sendPost
                }
            }
        }
    }
}
