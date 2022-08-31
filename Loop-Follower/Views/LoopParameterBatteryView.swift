//
//  LoopParameterBatteryView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 15.07.22.
//

import SwiftUI

struct LoopParameterBatteryView: View {
    
    var label : String
    
    var percentage : Int
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            HStack{
                Text(percentage.formatted(.percent))
                VStack {
                    GeometryReader { geo in
                        let radius : CGFloat = 4
                        let width : CGFloat = geo.size.width - 6
                        let start : CGFloat = width + 2
                        let length : CGFloat = 5
                        
                        Rectangle()
                            .fill(estimateColor(percentage))
                            .frame(
                                width: (width * CGFloat(min(max(percentage, 20), 100))) / 100,
                                height: geo.size.height)
                        RoundedRectangle(cornerRadius: radius)
                            .stroke(.background, lineWidth: 3)
                            .frame(width: width, height: geo.size.height)
                        RoundedRectangle(cornerRadius: radius)
                            .stroke(.gray, lineWidth: 1)
                            .frame(width: width, height: geo.size.height)

                        Path() { path in
                            path.move(to: CGPoint(x: start, y: (geo.size.height - length) / 2))
                            path.addRoundedRect(
                                in: CGRect(
                                    x: start,
                                    y: (geo.size.height - length) / 2,
                                    width: 1,
                                    height: length),
                                cornerSize: CGSize(width: radius, height: radius)
                            )
                        }
                        .stroke(.gray, lineWidth: 1)
                    }
                }
                .frame(width: 48, height: 16)
            }
        }
    }
}

private func estimateColor(_ percentage : Int) -> Color {
    if percentage <= 20 {
        return .red
    }
    if percentage <= 30 {
        return .yellow
    }
    
    return .green
}

struct LoopParameterBatteryView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            VStack {
                LoopParameterBatteryView(label: "Battery", percentage: -10)
                LoopParameterBatteryView(label: "Battery", percentage: 0)
                LoopParameterBatteryView(label: "Battery", percentage: 10)
                LoopParameterBatteryView(label: "Battery", percentage: 20)
                LoopParameterBatteryView(label: "Battery", percentage: 30)
                LoopParameterBatteryView(label: "Battery", percentage: 75)
                LoopParameterBatteryView(label: "Battery", percentage: 100)
                LoopParameterBatteryView(label: "Battery", percentage: 200)
            }
            .preferredColorScheme($0)
        }
        .previewLayout(.sizeThatFits)
    }
}
