import SwiftUI
struct StarryBackground: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.bg

            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: 342, height: 342)
                .offset(x: 188, y: -171)
            
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: 370, height: 370)
                .offset(x: 174, y: -185)

            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: 346, height: 346)
                .offset(x: -163, y: 652)
            
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: 380, height: 380)
                .offset(x: -180, y: 635)
            
            Circle() //dots
                .fill(Color(hex: "5A3F73"))
                .frame(width: 6, height: 6)
                .offset(x: 23, y: 713)
            
            Image(systemName: "sparkle") // tiny stars
                .font(.system(size: 22))
                .foregroundStyle(Color(hex: "5A3F73"))
                .offset(x: 40, y: 684)
        }
        .ignoresSafeArea()
    }
}
#Preview {
    StarryBackground()
}
