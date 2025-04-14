import SwiftUI

struct HomeView: View {
    @State private var showMain = false

    var body: some View {
        ZStack {
            if showMain {
                ContentView()
            } else {
                VStack(spacing: 30) {
                    Spacer()

                    Image("DiscoverIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)

                    Text("VT2NH")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Find events by town across Vermont and New Hampshire")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)

                    Spacer()
                }
                .padding()
                .onAppear {
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

