// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

import ARKit
import AzureSpatialAnchors

class AnchorVisual {
    
    init() {
        node = nil
        cardNode = nil
        identifier = ""
        cloudAnchor = nil
        localAnchor = nil
        gravityCardId = nil
    }
    
    var node : SCNNode? = nil
    var cardNode : SCNNode? = nil
    var identifier : String
    var cloudAnchor : ASACloudSpatialAnchor? = nil
    var localAnchor : ARAnchor? = nil
    var gravityCardId : String? = nil
    
}
