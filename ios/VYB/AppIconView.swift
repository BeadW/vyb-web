import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // VYB text
                HStack(spacing: 2) {
                    Text("V")
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("Y")
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                    Text("B")
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                // Subtitle
                Text("Visual Builder")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(1)
            }
            
            // Decorative elements
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 40, height: 40)
                .offset(x: -60, y: -80)
            
            Circle()
                .fill(Color.yellow.opacity(0.2))
                .frame(width: 25, height: 25)
                .offset(x: 70, y: -60)
            
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 30, height: 30)
                .offset(x: 50, y: 70)
        }
        .frame(width: 180, height: 180)
        .cornerRadius(40)
        .overlay(
            RoundedRectangle(cornerRadius: 40)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    AppIconView()
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.gray.opacity(0.3))
}