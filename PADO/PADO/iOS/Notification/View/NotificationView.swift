//
//  NotificationView.swift
//  PADO
//
//  Created by 강치우 on 1/16/24.
//

import SwiftUI
// TODO: 알림 없으면 noItemView
struct NotificationView: View {
    @ObservedObject var notiVM: NotificationViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                HStack {
                    Spacer()
                    
                    Button {
                        Task {
                            await notiVM.deleteAllNotifications()
                        }
                    } label: {
                        Text("알림 전체삭제")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(.systemGray))
                    }
                    .padding(.horizontal, 10)
                }
                .frame(width: UIScreen.main.bounds.width)
                // 나중에 ForEach로 만들어야함(?) -> 이뤄드림
                ForEach(notiVM.notifications) { notification in
                    NotificationCell(notification: notification)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                }
            }
        }
        .background(.main, ignoresSafeAreaEdges: .all)
        .navigationBarBackButtonHidden()
        .navigationTitle("알림")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                            .fontWeight(.medium)
                        
                        Text("뒤로")
                            .font(.system(size: 16))
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .toolbarBackground(Color(.main), for: .navigationBar)
        .onAppear {
            Task {
                await notiVM.fetchNotifications()
                await notiVM.markNotificationsAsRead()
            }
        }
    }
}

