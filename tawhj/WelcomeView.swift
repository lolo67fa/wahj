//
//  WelcomeView.swift
//  tawhj
//
//  Created by ghala alshreef on 07/06/1448 AH.
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("displayName") private var userName = ""

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var animateStar = false
    @State private var showNextMessage = false
    @State private var showHabitIntro = false

    private let pink = Color(
        red: 242.0 / 255,
        green: 179.0 / 255,
        blue: 230.0 / 255
    )

    private let secondary = Color(
        red: 227.0 / 255,
        green: 200.0 / 255,
        blue: 234.0 / 255
    )

    private var greeting: String {
        userName.isEmpty
        ? "أهلًا فيك في وهج"
        : "أهلًا \(userName) في وهج"
    }

    var body: some View {
        ZStack {
            SpaceBackground()

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    Button("تخطي") {
                        showHabitIntro = true                    }
                    .font(.subheadline)
                    .foregroundStyle(secondary)
                    .padding(10)
                }

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("هلا! أنا نُجيمة")
                                .font(.headline)

                            Text("بساعدك تلتزم بعاداتك كل يوم")
                                .font(.subheadline)
                        }
                        .foregroundStyle(secondary)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .padding(22)
                        .background(
                            Color(
                                red: 67.0 / 255,
                                green: 42.0 / 255,
                                blue: 82.0 / 255
                            ),
                            in: RoundedRectangle(cornerRadius: 26)
                        )

                        ZStack {
                            StarOrbit()

                            AnimatedStar(imageName: "starWink", size: 210)
                        }
                        
                        .frame(height: 300)
                        .accessibilityLabel("نُجيمة")

                        VStack(spacing: 12) {
                            Text(greeting)
                                .font(.title.bold())
                                .foregroundStyle(
                                    Color(
                                        red: 1,
                                        green: 244.0 / 255,
                                        blue: 253.0 / 255
                                    )
                                )

                            Text("كل يوم تلتزم فيه تقرب من نجمتك")
                                .font(.subheadline)
                                .foregroundStyle(secondary)
                        }
                        .multilineTextAlignment(.center)

                        HStack(spacing: 6) {
                            Capsule()
                                .fill(pink)
                                .frame(width: 22, height: 8)

                            Circle()
                                .fill(pink.opacity(0.25))
                                .frame(width: 8, height: 8)
                        }
                        .padding(.top, 12)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }

                Button {
                    showHabitIntro = true
                } label: {
                    Text("التالي")
                        .font(.headline)
                        .foregroundStyle(
                            Color(
                                red: 51.0 / 255,
                                green: 32.0 / 255,
                                blue: 63.0 / 255
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(pink, in: Capsule())
                        .shadow(
                            color: Color(
                                red: 0.35,
                                green: 0.07,
                                blue: 0.35
                            ),
                            radius: 0,
                            y: 5
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 20)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 55)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
        
        .fullScreenCover(isPresented: $showHabitIntro) {
            HabitIntroView()
        }
        .task(id: reduceMotion) {
            if reduceMotion {
                animateStar = false
            } else {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    animateStar = true
                }
            }
        }
        .alert("الصفحة التالية", isPresented: $showNextMessage) {
            Button("تمام", role: .cancel) {}
        } message: {
            Text("نربط شاشة المجموعة النجمية بعد تصميمها.")
        }
    }
}

#Preview {
    WelcomeView()
}
