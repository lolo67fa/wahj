import SwiftUI
import Playgrounds

struct LamisView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    Text("عاداتي")
                        .font(.largeTitle).bold()
                        .foregroundStyle(.white)
                    Spacer()
                    NavigationLink {
                        AddHabitView()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Theme.pink, in: Circle())
                            .shadow(color: Theme.pink.opacity(0.6), radius: 10)
                    }
                
                }
                
                HabitCard(title: "قراءة ١٠ صفحات", icon: "book", daysText: "٤ من ٢١ يوم", progress: 0.45)
                HabitCard(title: "شرب الماء", icon: "waterbottle.fill", daysText: "٥ من ١٤ يوم", progress: 0.85)
                HabitCard(title: "مشي ٢٠ دقيقة", icon: "figure.walk", daysText: "٣ من ٧ يوم", progress: 1.0, isCompleted: true)
                
                Spacer()
                BottomTabBar()
            }
            .padding()
            .background { StarryBackground() }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

#Preview {
    LamisView()
}

#Playground {
    _ = 1 + 2
}
