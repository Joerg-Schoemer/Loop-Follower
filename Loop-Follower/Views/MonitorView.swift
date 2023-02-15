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

    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    var body: some View {
        Group {
            
            if orientation.isLandscape || prevOrientation.isLandscape && orientation.isFlat {
                ChartsView()
            } else {
                VStack(spacing: 0) {
                    ZStack {
                        if let loopData = modelData.currentLoopData {
                            LoopParameterView(
                                loopData: loopData,
                                cn: modelData.cn,
                                siteChanged: modelData.siteChanged,
                                sensorChanged: modelData.sensorChanged
                            )
                        }
                        if let lastEntry = modelData.lastEntry {
                            CurrentValueView(
                                currentEntry: lastEntry,
                                delta: calcDelta(modelData.entries)
                            )
                            .scaleEffect(0.707)
                        }
                    }

                    ChartsView()
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
