//
//  HomeView.swift
//  VT2NH Capstone Project
//
//  Created by Kevin Edwards on 04/11/25
//

import SwiftUI

/// Initial splash screen for the VT2NH app.
/// Shows the app icon, title, and tagline for 2.5 seconds before transitioning to the main interface.
struct HomeView: View {
    
    /// Controls whether the app should display the splash or main content
    @State private var showMain = false

    var body: some View {
        ZStack {
            if showMain {
                // 🎯 Navigate to the main app content after delay
                ContentView()
            } else {
                // ⏳ Splash Screen Display
                VStack(spacing: 30) {
                    Spacer()

                    // App Icon
                    Image("DiscoverIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)

                    // App Title
                    Text("VT2NH")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    // Tagline
                    Text("Find events by town across Vermont and New Hampshire")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)

                    Spacer()
                }
                .padding()
                .onAppear {
                    // Trigger transition to main view after 2.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            showMain = true
                        }
                    }
                }
            }
        }
    }
}

