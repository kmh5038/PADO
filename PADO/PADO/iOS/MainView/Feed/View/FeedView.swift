//
//  ReFeedView.swift
//  PADO
//
//  Created by 강치우 on 2/6/24.
//

import Lottie
import SwiftUI

struct FeedView: View {
    @State private var isLoading = true
    
    @EnvironmentObject var authenticationViewModel: AuthenticationViewModel
    
    @ObservedObject var feedVM: FeedViewModel
    @ObservedObject var surfingVM: SurfingViewModel
    @ObservedObject var profileVM: ProfileViewModel
    @ObservedObject var followVM: FollowViewModel
    @ObservedObject var notiVM: NotificationViewModel
    @StateObject var scrollDelegate: ScrollViewModel = .init()
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollViewReader { proxy in
                    CustomRefreshView(showsIndicator: false,
                                      lottieFileName: "Wave",
                                      scrollDelegate: scrollDelegate) {
                        if authenticationViewModel.selectedFilter == .following {
                            LazyVStack(spacing: 0) {
                                if feedVM.postFetchLoading {
                                    LottieView(animation: .named("Loading"))
                                        .looping()
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .containerRelativeFrame([.horizontal,.vertical])
                                } else if feedVM.followFetchLoading {
                                    EmptyView()
                                } else if feedVM.followingPosts.isEmpty {
                                    FeedGuideView(feedVM: feedVM)
                                        .containerRelativeFrame([.horizontal,.vertical])
                                } else {
                                    ForEach(feedVM.followingPosts.indices, id: \.self) { index in
                                        FeedCell(feedVM: feedVM,
                                                 surfingVM: surfingVM,
                                                 profileVM: profileVM,
                                                 feedCellType: FeedFilter.following,
                                                 post: $feedVM.followingPosts[index],
                                                 index: index)
                                        .id(index)
                                        .onAppear {
                                            if index == feedVM.followingPosts.indices.last {
                                                Task {
                                                    await feedVM.fetchFollowMorePosts()
                                                }
                                            }
                                        }
                                    }
                                    .scrollTargetLayout()
                                }
                            }
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(feedVM.todayPadoPosts.indices, id: \.self) { index in
                                    FeedCell(feedVM: feedVM,
                                             surfingVM: surfingVM,
                                             profileVM: profileVM,
                                             feedCellType: FeedFilter.today,
                                             post: $feedVM.todayPadoPosts[index],
                                             index: index)
                                }
                            }
                        }
                    } onRefresh: {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        if authenticationViewModel.selectedFilter == FeedFilter.following {
                            guard !userNameID.isEmpty else {
                                await feedVM.getPopularUser()
                                feedVM.followingPosts.removeAll()
                                return
                            }
                            await profileVM.fetchBlockUsers()
                            await followVM.initializeFollowFetch(id: userNameID)
                            feedVM.followFetchLoading = true
                            await feedVM.fetchFollowingPosts()
                            await profileVM.fetchPostID(id: userNameID)
                            await notiVM.fetchNotifications()
                            feedVM.followFetchLoading = false
                        } else {
                            Task{
                                await profileVM.fetchBlockUsers()
                                await feedVM.fetchTodayPadoPosts()
                                guard !userNameID.isEmpty else { return }
                                await notiVM.fetchNotifications()
                                await followVM.initializeFollowFetch(id: userNameID)
                                await profileVM.fetchPostID(id: userNameID)
                            }
                        }
                    }
                    .scrollDisabled(feedVM.isShowingPadoRide)
                    .onChange(of: authenticationViewModel.selectedFilter) {
                        withAnimation {
                            proxy.scrollTo(0, anchor: .top)
                        }
                    }
                }
                VStack {
                    if !feedVM.isShowingPadoRide {
                        if scrollDelegate.scrollOffset < 5 {
                            FeedHeaderCell(notiVM: notiVM,
                                           profileVM: profileVM,
                                           feedVM: feedVM)
                                .transition(.opacity.combined(with: .scale))
                        } else if !scrollDelegate.isEligible {
                            FeedRefreshHeaderCell()
                                .transition(.opacity.combined(with: .scale))
                        }
                        Spacer()
                    }
                }
                .padding(.top, 10)
                .animation(.easeInOut, value: scrollDelegate.scrollOffset)
            }
        }
    }
}
