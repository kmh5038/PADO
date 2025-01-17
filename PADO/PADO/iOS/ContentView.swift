//
//  ContentView.swift
//  PADO
//
//  Created by 최동호 on 1/2/24.
//

import SwiftUI

struct ContentView: View {
    @State var width = UIScreen.main.bounds.width
    
    @EnvironmentObject var viewModel: AuthenticationViewModel
    
    @StateObject var surfingVM = SurfingViewModel()
    @StateObject var feedVM = FeedViewModel()
    @StateObject var followVM = FollowViewModel()
    @StateObject var profileVM = ProfileViewModel()
    @StateObject var notiVM = NotificationViewModel()
    @StateObject var postitVM = PostitViewModel()
    @StateObject var padorideVM = PadoRideViewModel()
    
    @State private var showPushProfile = false
    @State private var pushUser: User?
    
    @State private var showPushPost = false
    @State private var pushPost: Post?
    
    let updateHeartData = UpdateHeartData()
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $viewModel.showTab) {
            FeedView(feedVM: feedVM,
                     surfingVM: surfingVM,
                     profileVM: profileVM,
                     followVM: followVM,
                     notiVM: notiVM)
            .tabItem {
                Image(viewModel.showTab == 0 ? "home_light" : "home_gray")
                
                Text("홈")
            }
            .onAppear { viewModel.showTab = 0 }
            .tag(0)
            
            MainSearchView(profileVM: profileVM)
            .tabItem {
                Image(viewModel.showTab == 1 ? "search_light" : "search_gray")
                
                Text("검색")
            }
            .onAppear { viewModel.showTab = 1 }
            .tag(1)
            
            if let user = viewModel.currentUser {
                SurfingView(surfingVM: surfingVM,
                            feedVM: feedVM,
                            profileVM: profileVM,
                            followVM: followVM)
                .tabItem {
                    Text("")
                    
                    Image(viewModel.showTab == 2 ? "tab_added" : "tab_add")
                }
                .onAppear { viewModel.showTab = 2 }
                .tag(2)
                
                PadoRideView(feedVM: feedVM,
                             followVM: followVM,
                             padorideVM: padorideVM)
                .tabItem {
                    Image(viewModel.showTab == 3 ? "today_light" : "today_gray")
                    
                    Text("파도타기")
                }
                .onAppear { viewModel.showTab = 3 }
                .tag(3)
                
                
                ProfileView(profileVM: profileVM,
                            followVM: followVM,
                            feedVM: feedVM,
                            postitVM: postitVM,
                            user: user)
                .tabItem {
                    Image(viewModel.showTab == 4 ? "profile_light" : "profile_gray")
                    
                    Text("프로필")
                }
                .onAppear { viewModel.showTab = 4 }
                .tag(4)
            } else {
                LoginAlert()
                    .tabItem {
                        Text("")
                        
                        Image(viewModel.showTab == 2 ? "tab_added" : "tab_add")
                    }
                    .onAppear { viewModel.showTab = 2 }
                    .tag(2)
                
                LoginAlert()
                    .tabItem {
                        Image(viewModel.showTab == 3 ? "today_light" : "today_gray")
                        
                        Text("파도타기")
                    }
                    .onAppear { viewModel.showTab = 3 }
                    .tag(3)
                
                LoginAlert()
                    .tabItem {
                        Image(viewModel.showTab == 4 ? "profile_light" : "profile_gray")
                        
                        Text("프로필")
                    }
                    .onAppear { viewModel.showTab = 4 }
                    .tag(4)
            }
        }
        // 상대방 프로필로 전환 이벤트(팔로우, 서퍼지정, 방명록 글)
        .sheet(isPresented: $showPushProfile) {
            if let user = pushUser {
                NavigationStack {
                    OtherUserProfileView(buttonOnOff: .constant(true), user: user)
                        .presentationDragIndicator(.visible)
                }
            }
        }
        .sheet(isPresented: $showPushPost) {
            if let post = pushPost {
                OnePostModalView(feedVM: feedVM,
                                 profileVM: profileVM,
                                 post: post)
                .presentationDragIndicator(.visible)
            }
        }
        .tint(.white)
        .onAppear {
            fetchData()
        }
        .onChange(of: needsDataFetch) { _, _ in
            fetchData()
        }
    }
    
    func fetchData() {
        guard !userNameID.isEmpty else {
            Task {
                await feedVM.getPopularUser()
                await feedVM.fetchTodayPadoPosts()
            }
            return
        }
        
        Task {
            viewModel.selectedFilter = .following
            viewModel.showTab = 0
            feedVM.postFetchLoading = true
            await profileVM.fetchBlockUsers()
            await followVM.initializeFollowFetch(id: userNameID)
            await feedVM.fetchTodayPadoPosts()
            await feedVM.fetchFollowingPosts()
            await notiVM.fetchNotifications()
            await profileVM.fetchPostID(id: userNameID)
            await postitVM.getMessageDocument(ownerID: userNameID)
            feedVM.postFetchLoading = false
            
            NotificationCenter.default.addObserver(forName: Notification.Name("ProfileNotification"), object: nil, queue: .main) { notification in
                // 알림을 받았을 때 수행할 작업
                guard let userInfo = notification.object as? User else { return }
                Task {
                    await handleProfileNotification(userInfo: userInfo)
                }
            }
            NotificationCenter.default.addObserver(forName: Notification.Name("PostNotification"), object: nil, queue: .main) { notification in
                // 알림을 받았을 때 수행할 작업
                
                guard let postInfo = notification.object as? Post else { return }
                Task {
                    await handlePostNotification(postInfo: postInfo)
                }
            }
        }
    }
    @MainActor
    private func handleProfileNotification(userInfo: User) async {
        self.pushUser = userInfo
        self.showPushProfile = true
    }
    @MainActor
    private func handlePostNotification(postInfo: Post) async {
        viewModel.showTab = 4
        self.pushPost = postInfo
        self.showPushPost = true

    }
}
