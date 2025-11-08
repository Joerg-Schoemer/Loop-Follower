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
    @State var prevOrientation = UIDevice.current.orientation
    @State var tabSelection : String = "BG"

    let criticalMax : Int = 260
    let criticalMin : Int = 55
    
    let rangeMin : Int = 70
    let rangeMax : Int = 180

    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    var body: some View {
        Group {
            if orientation.isLandscape || prevOrientation.isLandscape && orientation.isFlat {
                ChartsView(
                    criticalMin: criticalMin,
                    criticalMax: criticalMax,
                    rangeMin: rangeMin,
                    rangeMax: rangeMax,
                    selection: $tabSelection
                )
            } else {
                VStack(spacing: 0) {
                    ZStack {
                        LoopParameterView(
                            loopData: modelData.currentLoopData,
                            cn: modelData.cn,
                            siteChanged: modelData.siteChanged,
                            sensorChanged: modelData.sensorChanged,
                            timeInRange: modelData.timeInRange
                        )
                        CurrentValueView(
                            currentDate: $modelData.currentDate,
                            currentEntry: $modelData.lastEntry,
                            delta: calcDelta(modelData.entries),
                            criticalMin: criticalMin,
                            criticalMax: criticalMax,
                            rangeMin: rangeMin,
                            rangeMax: rangeMax
                        )
                        .scaleEffect(0.707)
                    }

                    ChartsView(
                        criticalMin: criticalMin,
                        criticalMax: criticalMax,
                        rangeMin: rangeMin,
                        rangeMax: rangeMax,
                        selection: $tabSelection
                    )
                }
                .padding([.leading, .trailing])
            }
        }
        .onReceive(orientationChanged) { _ in
            self.prevOrientation = self.orientation
            self.orientation = UIDevice.current.orientation
        }
    }
    
    func calcDelta(_ entries : [Entry]) -> Int? {
        if entries.count > 1 {
            return entries[0].sgv - entries[1].sgv
        }

        return nil
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
