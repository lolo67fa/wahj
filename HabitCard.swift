import SwiftUI

struct HabitCard: View {
    var title: String
    var icon: String
    var daysText: String
    var progress: Double
    var isCompleted = false
    
    @State private var isDone = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .foregroundStyle(isDone ? Theme.pink : Color.white)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(isDone ? Theme.pink : Color.clear, lineWidth: 1.5))
                    Text(title)
                }
                .font(.headline)
                .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 6) {
                    Capsule()
                        .fill(Theme.pink)
                        .frame(width: 150 * progress, height: 8)
                    Text(daysText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            Button {
                isDone.toggle()
            } label: {
                Image(systemName: isDone ? "star.fill" : "star")
                    .font(.title)
                    .foregroundStyle(isDone ? Color.yellow : Theme.pink)
            }
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.border, lineWidth: 1))
        .onAppear { isDone = isCompleted }
    }
}
