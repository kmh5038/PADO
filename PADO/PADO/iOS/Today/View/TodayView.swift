//
//  Today.swift
//  PADO
//
//  Created by 강치우 on 1/25/24.
//

import SwiftUI

struct TodayView: View {
    @State private var isShowingReportView = false
    @State private var isShowingCommentView = false
    
    @State private var isCellVisible = true
    @State private var isCommentVisible = false
    
    @StateObject private var commentVM = CommentViewModel()
    @StateObject private var mainCommentVM = MainCommentViewModel()
    
    @State private var textPosition = CGPoint(x: 300, y: 300)
    @State private var dragStart: CGPoint?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(sampleReels, id: \.id) { reel in
                        ZStack {
                            Image(reel.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .containerRelativeFrame(.vertical)
                            
                            LinearGradient(colors: [.clear, .clear, .clear, .clear, .clear, .clear, .clear, .clear, .clear, .clear, .clear, .black.opacity(0.35), .black.opacity(0.4), .black.opacity(0.4), .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                            
                            VStack {
                                Spacer()
                                if isCellVisible {
                                    HStack {
                                        //MARK: - TodayCell
                                        TodayCell()
                                            .padding(.top, 80)
                                        
                                        Spacer()
                                        
                                        //MARK: - HeartComment
                                        // 하트를 누른 상태에서 longpress제스쳐를 하고 난 후 하트가 off 돼있음 수정해야함
                                        HeartCommentCell(isShowingReportView: $isShowingReportView, isShowingCommentView: $isShowingCommentView)
                                            .padding(.trailing, 12)
                                    }
                                    .frame(width: UIScreen.main.bounds.width)
                                }
                            }
                            .padding(.bottom, 82)
                        }
                        // isCellVisible이 false이면 화면에 댓글을 띄워줌
                        .overlay {
                            if isCellVisible {
                                VStack {
                                    ForEach(mainCommentVM.mainComments) { comment in
                                        MainCommentCell(mainComment: comment)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .ignoresSafeArea()
            
        }
    }
}

#Preview {
    TodayView()
}
