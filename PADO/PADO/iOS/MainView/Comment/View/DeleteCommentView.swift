//
//  deleteCommentView.swift
//  PADO
//
//  Created by 황성진 on 2/4/24.
//

import SwiftUI

struct DeleteCommentView: View {
    @State var width = UIScreen.main.bounds.width
    @State var height = UIScreen.main.bounds.height
    @Environment(\.dismiss) var dismiss
    
    // MARK: - PROPERTY
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @ObservedObject var commentVM: CommentViewModel
    
    let postID: String
    
    var body: some View {
        VStack {
            VStack(alignment: .center) {
                VStack(spacing: 10) {
                    if let user = viewModel.currentUser {
                        CircularImageView(size: .medium, user: user)
                    }
                    
                    Text("댓글을 정말 삭제하시겠습니까?")
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(Color.white)
                .font(.system(size: 14))
                .fontWeight(.medium)
                .padding()
                
                Divider()
                
                Button {
                    if let selectComment = commentVM.selectedComment {
                        Task {
                            await commentVM.updateCommentData.deleteComment(documentID: postID,
                                                                            commentID: selectComment.userID+(selectComment.time.convertTimestampToString(timestamp: selectComment.time)))
                            if let fetchedComments = await commentVM.updateCommentData.getCommentsDocument(postID: postID) {
                                commentVM.comments = fetchedComments
                            }
                            
                            commentVM.showdeleteModal = false
                        }
                    }
                    
                    commentVM.showdeleteModal = false
                } label: {
                    Text("댓글 삭제")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.red)
                        .fontWeight(.semibold)
                        .frame(width: width * 0.9, height: 40)
                }
                .padding(.bottom, 5)
                
            }
            .frame(width: width * 0.9)
            .background(Color.modal)
            .clipShape(.rect(cornerRadius: 22))
            
            VStack {
                Button {
                    commentVM.showdeleteModal = false
                } label: {
                    Text("취소")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.white)
                        .fontWeight(.semibold)
                        .frame(width: width * 0.9, height: 40)
                }
            }
            .frame(width: width * 0.9, height: 50)
            .background(Color.modal)
            .clipShape(.rect(cornerRadius: 12))
        }
        .background(ClearBackground())
    }
}
