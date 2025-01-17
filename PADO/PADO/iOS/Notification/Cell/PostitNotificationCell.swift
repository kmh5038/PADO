//
//  PostitNotificationCell.swift
//  PADO
//
//  Created by 황민채 on 2/12/24.
//

import Kingfisher
import SwiftUI

struct PostitNotificationCell: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var sendUserProfileUrl: String = ""
    @State private var sendPostUrl: String = ""
    
    var notification: Noti
    
    // TODO: 포스트잇 네비게이션 링크
    var body: some View {
        Button {
            dismiss()
            viewModel.showTab = 4
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
                        Text("\(notification.sendUser)님이 회원님의 방명록에 글을 남겼습니다. ")
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
                        .frame(width: 40, height: 50)
                }
            }
        }
        .onAppear {
            Task {
                if let sendUserProfile = await UpdateUserData.shared.getOthersProfileDatas(id: notification.sendUser) {
                    self.sendUserProfileUrl = sendUserProfile.profileImageUrl ?? ""
                }
            }
        }
    }
}
