//
//  NotificationCellView.swift
//  PADO
//
//  Created by 황민채 on 2/8/24.
//

import SwiftUI

struct NotificationCell: View {
    var notification: Noti
    
    var body: some View {
        switch notification.type { // 노티의 타입마다 분기처리
        case "comment":
            CommentNotificationCell(notification: notification)
        case "heart":
            HeartNotificationCell(notification: notification)
        case "facemoji":
            FacemojiNotificationCell(notification: notification)
        case "follow":
            FollowNotificationCell(notification: notification)
        case "requestSurfing":
            RequestSurfingNotificationCell(notification: notification)
        case "surfer":
            SurferNotificationCell(notification: notification)
        default:
            Text(notification.message ?? "") // 기본 전체 알람시 보여줄 셀
        }
    }
}

