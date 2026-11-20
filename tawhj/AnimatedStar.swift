//
//  AnimatedStar.swift
//  tawhj
//
//  Created by ghala alshreef on 07/06/1448 AH.
//

import SwiftUI

struct AnimatedStar: View {
    let imageName: String
    var size: CGFloat = 183

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var glowing = false

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .background {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.yellow.opacity(glowing ? 0.25 : 0.10),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.65
                        )
                    )
                    .frame(width: size * 1.4, height: size * 1.4)
                    .scaleEffect(glowing ? 1.08 : 0.95)
            }
            .shadow(
                color: .yellow.opacity(glowing ? 0.45 : 0.15),
                radius: glowing ? 20 : 8
            )
            .scaleEffect(glowing ? 1.03 : 1)
            .offset(y: glowing ? -7 : 3)
            .animation(
                reduceMotion
                ? nil
                : .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true),
                value: glowing
            )
            .onAppear {
                glowing = !reduceMotion
            }
            .onChange(of: reduceMotion) { _, newValue in
                glowing = !newValue
            }
    }
}
