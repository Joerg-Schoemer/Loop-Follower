//
//  LoopParameterBatteryView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 15.07.22.
//

import SwiftUI

struct LoopParameterBatteryView: View {
    
    var label : String
    
    var uploader : Uploader
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            HStack {
                Text(uploader.battery.formatted(.percent))
                VStack {
                    GeometryReader { geo in
                        let radius : CGFloat = 4
                        let width : CGFloat = geo.size.width - 6
                        let start : CGFloat = width + 2
                        let length : CGFloat = 5
                        
                        Rectangle()
                            .fill(estimateColor(uploader.battery))
                            .frame(
                                width: (width * CGFloat(min(max(uploader.battery, 20), 100))) / 100,
                                height: geo.size.height
                            )
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

                        if uploader.isCharging == true {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: geo.size.height - 2, weight: .bold))
                                .foregroundColor(.gray)
                                .frame(width: width, height: geo.size.height)
                        }
                    }
                }
                .frame(width: 32, height: 12)
            }
        }
    }
}

private func estimateColor(_ percentage : Int) -> Color {
    if percentage <= 20 {
        return Color(.systemRed)
    }
    if percentage <= 30 {
        return Color(.systemYellow)
    }
    
    return Color(.systemGreen)
}

struct LoopParameterBatteryView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            VStack {
                LoopParameterBatteryView(label: "Battery", uploader: Uploader(battery: -10, isCharging: false))
                LoopParameterBatteryView(label: "Battery", uploader: Uploader(battery: 0, isCharging: false))
                LoopParameterBatteryView(label: "Battery", uploader: Uploader(battery: 10, isCharging: false))
                LoopParameterBatteryView(label: "Battery", uploader: Uploader(battery: 20, isCharging: true))
                LoopParameterBatteryView(label: "Battery", uploader: Uploader(battery: 30, isCharging: false))
                LoopParameterBatteryView(label: "Battery", uploader: Uploader(battery: 75, isCharging: false))
                LoopParameterBatteryView(label: "Battery", uploader: Uploader(battery: 100, isCharging: true))
                LoopParameterBatteryView(label: "Battery", uploader: Uploader(battery: 200, isCharging: false))
            }
            .preferredColorScheme($0)
        }
        .previewLayout(.sizeThatFits)
    }
}
