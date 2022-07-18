//
//  MonitorView.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import SwiftUI

struct MonitorView: View {
    
    @EnvironmentObject var modelData : ModelData
    @State var orientation = UIDevice.current.orientation

    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    var body: some View {
        Group {
            if orientation.isLandscape {
                ChartView()
            } else {
                ScrollView {
                    if let lastEntry = modelData.lastEntry {
                        CurrentValueView(
                            currentEntry: lastEntry,
                            delta: calcDelta(modelData.entries))
                    }

                    if let loopData = modelData.currentLoopData {
                        LoopParameterView(loopData: loopData)
                    }
                    
                    ChartView()
                        .frame(height: 200)
                }
            }
        }.onReceive(orientationChanged) { _ in
            self.orientation = UIDevice.current.orientation
        }
    }
    
    func calcDelta(_ entries : [Entry]) -> Int {
        if entries.count > 1 {
            return entries[0].sgv - entries[1].sgv
        }

        return 0
    }
}

struct MonitorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 50) {
            MonitorView()
                .environmentObject(ModelData(test: true))
        }
    }
}
