//
//  LoopParameterValue.swift
//  Loop-Follower
//
//  Created by Jörg Schömer on 13.07.22.
//

import SwiftUI

struct LoopParameterValue: View {
    
    var label : String
    var data : String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(data)
        }
    }
}

struct LoopParameterValue_Previews: PreviewProvider {
    static var previews: some View {
        LoopParameterValue(label: "IOB", data: "XYZ")
            .previewLayout(.sizeThatFits)
    }
}
