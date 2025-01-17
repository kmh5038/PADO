//
//  MainView.swift
//  PADO
//
//  Created by 강치우 on 1/3/24.
//

import Firebase
import FirebaseFirestore
import SwiftUI


struct MainView: View {
    @State private var showLaunchScreen = true
    @EnvironmentObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        Group {
            if showLaunchScreen {
                LaunchSTA()
                    .onAppear {
                        Task {
                            viewModel.nameID = userNameID
                            try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                            
                            if viewModel.nameID.isEmpty {
                                showLaunchScreen = false
                            } else {
                                await viewModel.initializeUser()
                                showLaunchScreen = false
                            }
                        }
                    }
            } else {
                ContentView()
            }
        }
    }
}

// #Preview {
//    MainView()
// }
