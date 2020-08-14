//
//  CustomCard.swift
//  GravityXR
//
//  Created by Avinash Shetty on 4/25/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import SceneKit

public class IDNode: SCNNode{
    
    var id:String?
    
    init(id: Int, name: String) {
        super.init()
        
        //Used for uniquely identifying a card
        let sphereGeometry = SCNSphere(radius: 0.01)
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = UIColor.clear
        sphereGeometry.materials = [sphereMaterial]
        self.geometry = sphereGeometry
        
        self.name = name
        self.id = String(id)
        
    }

    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
}

public class CustomCard: SCNNode {
    
    enum ARScenes: CustomStringConvertible{
        case cardScn
        case buttonAnchorScn

        var description: String{
            switch self {
                case .cardScn:
                    return "Art.scnassets/custom_card_refined.scn"
                case .buttonAnchorScn:
                    return "Art.scnassets/hotspot_custom.scn"
            }
        }
    }
    
    var cardData: Card!
    
    var prevCardData: Card?
    
    //hotspot
    var hotspotButton: SCNNode!   { didSet { hotspotButton.name = "hotspotButton" } }
    var hotspotButtonImage: SCNNode!   { didSet { hotspotButtonImage.name = "hotspotButtonImage" } }
    var toggleButtonParent:SCNNode!   { didSet {toggleButtonParent.name = "toggleButtonParent"}}

    //Card
    var rootNode:SCNNode! { didSet { rootNode.name = "RootNode"}}
    var cardRectangleBG: SCNNode!   { didSet { cardRectangleBG.name = "rectangleBG" } }
    var cardSquareBG: SCNNode!   { didSet { cardSquareBG.name = "squareBG" } }
    var cardInfoBG: SCNNode!   { didSet { cardInfoBG.name = "infoBG" } }
    var image: SCNNode!   { didSet { image.name = "image" } }
    var button1: SCNNode!   { didSet { button1.name = "button" } }
    var textNode: SCNNode!   { didSet { textNode.name = "textNode" } }
    var openButton: SCNNode!   { didSet { openButton.name = "OpenButton" } }
    
    var bShowExpanded:Bool = false
    
    init(data: Card, prevCard: Card?, cardType: ARScenes, buttonType:ARScenes, showExpanded:Bool = false) {
        
        super.init()
        
        self.cardData = data
        self.prevCardData = prevCard
        self.bShowExpanded = showExpanded
        
        
        guard let cardScene = SCNScene(named: cardType.description),

            let hotspotScene = SCNScene(named: buttonType.description),
            let hotspotButtonRoot = hotspotScene.rootNode.childNode(withName: "RootNode", recursively: false),
            let hotspotButton = hotspotButtonRoot.childNode(withName: "hotspotButton", recursively: false),
            let hotspotButtonImage = hotspotButton.childNode(withName: "hotspotButtonImage", recursively: false),
    
            let cardRoot = cardScene.rootNode.childNode(withName: "RootNode", recursively: false),
            let cardRectangleBG = cardRoot.childNode(withName: "rectangleBG", recursively: false),
            let cardSquareBG = cardRoot.childNode(withName: "squareBG", recursively: false),
            let cardInfoBG = cardRoot.childNode(withName: "infoBG", recursively: false),
            let image = cardRoot.childNode(withName: "image", recursively: false),
            let button1 = cardRoot.childNode(withName: "button", recursively: false),
            let textNode = cardRoot.childNode(withName: "textNode", recursively: false),
            let toggleButtonParent = cardRoot.childNode(withName: "toggleButtonParent", recursively: false),
            let openButton = toggleButtonParent.childNode(withName: "OpenButton", recursively: false)
            
            else { fatalError("Error Getting Card Node Data") }
        
        //Used for uniquely identifying a card
        cardRoot.addChildNode(IDNode(id: self.cardData.id, name: String(self.cardData.id)))
        if self.prevCardData != nil{
            cardRoot.addChildNode(IDNode(id: self.prevCardData!.id, name: "PrevID"))
        }

        self.rootNode = cardRoot
        self.cardRectangleBG = cardRectangleBG
        self.cardSquareBG = cardSquareBG
        self.cardInfoBG = cardInfoBG
        self.image = image
        self.button1 = button1
        self.textNode = textNode
        self.openButton = openButton
        
        self.hotspotButton = hotspotButton
        self.hotspotButtonImage = hotspotButtonImage
        
        openButton.removeFromParentNode()
        toggleButtonParent.addChildNode(hotspotButton)

        //Add to hierarchy
        self.addChildNode(cardRoot)

        setConfiguration()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit { flushFromMemory() }
    

    
    func glassEffect(color:UIColor) -> SCNMaterial{
         let glassMaterial = SCNMaterial()
         glassMaterial.lightingModel = .blinn
         glassMaterial.transparent.contents = UIColor.gray
         glassMaterial.transparencyMode = .dualLayer
         
         glassMaterial.fresnelExponent = 1.5
         glassMaterial.isDoubleSided = true
         glassMaterial.specular.contents = UIColor(white: 0.6, alpha: 1.0)
         glassMaterial.diffuse.contents = color
         glassMaterial.shininess = 50
         glassMaterial.reflective.contents = UIColor.gray.withAlphaComponent(0.7)
        //  glassMaterial.shaderModifiers = [SCNShaderModifierEntryPoint: shader]
         return glassMaterial
     }
    
    func setConfiguration(){
        
        //Configuration Starts here
        guard let layout:CardConfig = self.cardData.cardConfig else {return}
        guard let rootNode = rootNode else {return}
                
        let cardBackgroundColor = UIColor(hex:layout.background ?? "#FFFFFFEB") ?? UIColor(hex:"#FFFFFFEB")

        var cardElements = layout.elements
        cardElements.sort { $0.displayOrder < $1.displayOrder }
        
        print(cardElements)

        let length = ((rootNode.boundingBox.max.y - rootNode.boundingBox.min.y))
        rootNode.pivot = SCNMatrix4MakeTranslation(0, -0.4 * length, 0);
        
        var yOffset:Float = 0
       
        let kElementPadding:Float = 0.35
        
        //------Add toggle button--------------------------------------------
        if let toggleNode = hotspotButton{
            
            if self.prevCardData != nil {
                self.hotspotButtonImage.geometry?.materials.first?.diffuse.contents = UIImage(named: "hotspot_back")
            }

            let toggleNodeHeight = ((toggleNode.boundingBox.max.y-toggleNode.boundingBox.min.y) * (toggleNode.scale.y))
            toggleNode.position.y = 0
            
            self.rootNode.addChildNode(toggleNode)

            //Save maximum y position of current node so that can apply Y value on next node that will come below current node.
            yOffset = toggleNode.position.y - toggleNodeHeight 
        }

        //scale the card node as according to content size
        let cardHeight:Float = Float(layout.height ?? 120) / 352 //352 is the rectangle height sent from CMS

         if cardHeight > 0.67 {
            let cardLength = (cardRectangleBG.boundingBox.max.y - cardRectangleBG.boundingBox.min.y)
            let newCardScale = cardHeight

            //Pivot helps move the axis to top and helps when animating the card
            //cardRectangleBG.pivot = SCNMatrix4MakeTranslation(0, 0.5 * cardLength, 0);

            cardRectangleBG?.scale.y = (cardRectangleBG?.scale.y)! * newCardScale
            
            if let cardBackgroundColor = cardBackgroundColor{
                cardRectangleBG?.geometry?.materials = [glassEffect(color: cardBackgroundColor)]
            }
            //reset the Y position as according to content.
            cardRectangleBG?.position.y = yOffset - (cardLength * newCardScale) + kElementPadding

            cardSquareBG.removeFromParentNode()
            cardInfoBG.removeFromParentNode()
            cardRectangleBG.isHidden = bShowExpanded ? false : true

        } else if cardHeight >= 0.4 {
            let cardLength = (cardSquareBG.boundingBox.max.y - cardSquareBG.boundingBox.min.y)

            if let cardBackgroundColor = cardBackgroundColor{
                cardSquareBG?.geometry?.materials = [glassEffect(color: cardBackgroundColor)]
            }
            //reset the Y position as according to content.
            cardSquareBG?.position.y =  yOffset - (cardLength * (cardSquareBG?.scale.y)! * 0.5) + kElementPadding

            cardRectangleBG.removeFromParentNode()
            cardInfoBG.removeFromParentNode()
            cardSquareBG.isHidden = bShowExpanded ? false : true
            
        } else{
            
            let cardLength = (cardInfoBG.boundingBox.max.y - cardInfoBG.boundingBox.min.y)

            if let cardBackgroundColor = cardBackgroundColor{
                cardInfoBG?.geometry?.materials = [glassEffect(color: cardBackgroundColor)]
            }
            //reset the Y position as according to content.
            cardInfoBG?.position.y =  yOffset - (cardLength * (cardInfoBG?.scale.y)!) + kElementPadding//info background in .scn file, seems to have origin at the bottom of the object
 
            cardSquareBG.removeFromParentNode()
            cardRectangleBG.removeFromParentNode()
            cardInfoBG.isHidden = bShowExpanded ? false : true
        }
             
        let contentNode = SCNNode()
        contentNode.name = "cardContentNode"
        
        yOffset = yOffset - (kElementPadding * 0.5)

        for element in cardElements {
            
            if element.cardElementType == "IMAGE" {
                
                let newImageNode = self.deepCopyNode(node: image)
                newImageNode.addChildNode(IDNode(id: element.displayOrder, name: "ID"))
                
                let imgHeight = ((newImageNode.boundingBox.max.y) - (newImageNode.boundingBox.min.y) * (newImageNode.scale.y))
                newImageNode.position.y = yOffset - (imgHeight * 0.5)

                contentNode.addChildNode(newImageNode)
                
                if element.url.count > 0  {
                    downloadImage(from: URL(string: element.url)!, forNode: newImageNode)
                }
                
                //Save maximum y position of current node so that can apply Y value on next node that will come below current node.
                yOffset = (newImageNode.position.y) - imgHeight
                                                
            }else if element.cardElementType == "TEXT" {
                
                yOffset = yOffset + kElementPadding

                let newTextNode = self.deepCopyNode(node: textNode)
                newTextNode.addChildNode(IDNode(id: element.displayOrder, name: "ID"))

                let clonedText = newTextNode.childNode(withName: "text", recursively: false)!.geometry as? SCNText

                let labelColor = UIColor(hex:element.textColour ?? "#000000") ?? UIColor.black
                let fontsize = Float(element.fontSize ?? "24")!/2.5
                setTextOnLabel(textNode: clonedText!, text: element.text!, size:fontsize, align: element.textAlign ?? "center")
                
                let textHeight = (newTextNode.boundingBox.max.y - newTextNode.boundingBox.min.y) * (newTextNode.scale.y)
                let material = SCNMaterial()
                material.diffuse.contents = labelColor
                clonedText!.materials = [material]

                //clonedText!.materials.first?.diffuse.contents = labelColor
                newTextNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
                
                newTextNode.position.y = yOffset - textHeight //when there are multiple lines, increase in container size increases in the positive y direction
                
                contentNode.addChildNode(newTextNode)

                //Save maximum y position of current node so that can apply Y value on next node that will come below current node.
                yOffset = (newTextNode.position.y) - textHeight

            }else if element.cardElementType == "BUTTON" {
                
                let newButtonNode = self.deepCopyNode(node: button1)
                let buttonHeight = (newButtonNode.boundingBox.max.y - newButtonNode.boundingBox.min.y) * (newButtonNode.scale.y)

                newButtonNode.addChildNode(IDNode(id: element.displayOrder, name: "ID"))
                newButtonNode.position.y = yOffset - (buttonHeight * 0.5)
                contentNode.addChildNode(newButtonNode)
                
                let buttonLabelColor = UIColor(hex:element.textColour ?? "#000000") ?? UIColor.black
                let buttonBGColor = UIColor(hex:element.background ?? "#ffffff") ?? UIColor.white

                if let newButtonText:SCNText = newButtonNode.childNode(withName: "buttonText", recursively: false)!.geometry as? SCNText{
                    setTextOnButtons(textNode: newButtonText, parent: newButtonNode, text: element.text! )
                    let material = SCNMaterial()
                    material.diffuse.contents = buttonLabelColor
                    newButtonText.materials = [material]
                }
                newButtonNode.geometry?.firstMaterial?.diffuse.contents = buttonBGColor

                //Save maximum y position of current node so that can apply Y value on next node that will come below current node.
                yOffset = (newButtonNode.position.y) - buttonHeight - (kElementPadding*2)
            
            }

        }
        self.rootNode.addChildNode(contentNode)
        
        contentNode.isHidden = bShowExpanded ? false : true
                
        //        print("after adding hotspot \(yOffset), cardLength - \(cardLength), cardHeight - \(cardHeight), scale - \((cardHeight / 352) * newCardScale)")

                //Set the pivot point so that when we rotate the object it rotates around the right pivot point
                /*var minVec = SCNVector3Zero
                var maxVec = SCNVector3Zero
                (minVec, maxVec) =  self.rootNode.boundingBox
                self.rootNode.pivot = SCNMatrix4MakeTranslation(
                    minVec.x + (maxVec.x - minVec.x)/2,
                    maxVec.y,
                    minVec.z + (maxVec.z - minVec.z)/2
                )
                */

        //        print("After Processing Cardscale \(newCardScale)")
        //        print("cardPlane Y \(cardPlane?.position.y)")

    }
    
    
    private func deepCopyNode(node: SCNNode) -> SCNNode {
        
        let clone = node.clone()
        clone.isHidden = false
        clone.geometry = node.geometry
        clone.geometry = node.geometry?.copy() as? SCNGeometry
        if let g = node.geometry {
            clone.geometry?.materials = g.materials.map{ $0.copy() as! SCNMaterial }
        }

        if let childNode = node.childNode(withName: "buttonText", recursively: false){
            let cloneChild = clone.childNode(withName: "buttonText", recursively: false)
            cloneChild!.geometry = childNode.geometry?.copy() as? SCNGeometry
        }
        if let childNode1 = node.childNode(withName: "text", recursively: false){
            let cloneChild = clone.childNode(withName: "text", recursively: false)
            cloneChild!.geometry = childNode1.geometry?.copy() as? SCNGeometry
        }

        return clone
    }

    /*
    infoText.string = infoTitle
           infoText.containerFrame = CGRect(origin: .zero, size: CGSize(width: 65.0, height: 120))
           infoText.truncationMode = CATextLayerTruncationMode.none.rawValue
           infoText.isWrapped = true
           infoText.alignmentMode = CATextLayerAlignmentMode.center.rawValue
           infoText.font = UIFont.systemFont(ofSize: 6)
           self.InfoCardPlane.scale = SCNVector3Make(0.8, 0.7, 0.1)
    
    *///1line = 7.5
    
    func setTextOnLabel(textNode:SCNText, text:String, size: Float, align: String){
        textNode.string = text
        print("Before Set textNode.containerFrame - \(textNode.containerFrame)")

        let textCount = text.count
        let numberOflines = (Double(textCount)/15.0).rounded(.up)
        let lineHeight = Double(1.5*size)
        let textHeight = numberOflines >= 1 ? Double(numberOflines)*lineHeight : 10
        textNode.containerFrame = CGRect(origin: .zero, size: CGSize(width: 80.0, height: textHeight))
        print("Text Size - \(size), Text - \(text)")
        textNode.truncationMode = CATextLayerTruncationMode.none.rawValue
        textNode.isWrapped = true
        
        textNode.alignmentMode = alignTextNode(align: align).rawValue
        textNode.font = UIFont.systemFont(ofSize: CGFloat(size))
        print("After 2 textNode.containerFrame - \(textNode.containerFrame)")

//      text1.transform = SCNMatrix4MakeTranslation(0, 0.05 * Float(index), 0)
//      self.parent?.scale = SCNVector3Make(1.186, 1.879, 0.17)
    }
    
    func alignTextNode(align:String) -> CATextLayerAlignmentMode{
        switch align {
        case "center":return CATextLayerAlignmentMode.center
        case "left": return CATextLayerAlignmentMode.left
        case "right": return CATextLayerAlignmentMode.right
        default:
            return CATextLayerAlignmentMode.center
        }
    }
   
    func setTitle(textNode:SCNText,parent:SCNNode,text:String){
        textNode.string = text
        textNode.containerFrame = CGRect(origin: .zero, size: CGSize(width: 70, height: 15))
        textNode.truncationMode = CATextLayerTruncationMode.none.rawValue
        textNode.isWrapped = true
        textNode.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        textNode.font = UIFont.systemFont(ofSize: 12)
        //self.parent?.scale = SCNVector3Make(1.186, 1.879, 0.17)
    }
    
    func setTextOnButtons(textNode:SCNText,parent:SCNNode,text:String){
        textNode.string = text
        textNode.containerFrame = CGRect(origin: .zero, size: CGSize(width: 55.0, height: 11))
        textNode.truncationMode = CATextLayerTruncationMode.none.rawValue
        textNode.isWrapped = true
        textNode.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        textNode.font = UIFont.systemFont(ofSize: 8)
        
    }
    
    func updatePositionAndOrientationOf(_ node: SCNNode?, withPosition position: SCNVector3, relativeTo referenceNode: SCNNode?) {
        
        guard let node = node else {return}
        guard let referenceNode = referenceNode else {return}
        
        print("################ Change position for \(node) with \(position)")
        let referenceNodeTransform = matrix_float4x4(referenceNode.transform)

        // Setup a translation matrix with the desired position
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.x = position.x
        translationMatrix.columns.3.y = position.y
        translationMatrix.columns.3.z = position.z

        // Combine the configured translation matrix with the referenceNode's transform to get the desired position AND orientation
        let updatedTransform = matrix_multiply(referenceNodeTransform, translationMatrix)
        node.transform = SCNMatrix4(updatedTransform)
    }
    
    
    /// Removes All SCNMaterials & Geometries From An SCNNode
    func flushFromMemory(){
        
        print("Cleaning Card")
        
        if let parentNodes = self.parent?.childNodes{ parentNodes.forEach {
            $0.geometry?.materials.forEach({ (material) in material.diffuse.contents = nil })
            $0.geometry = nil
            $0.removeFromParentNode()
            }
        }
        
        for node in self.childNodes{
            node.geometry?.materials.forEach({ (material) in material.diffuse.contents = nil })
            node.geometry = nil
            node.removeFromParentNode()
        }
    }
    
    //MARK: - Image Handling
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
       URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func downloadImage(from url: URL, forNode image:SCNNode) {
       getData(from: url) {
          data, response, error in
          guard let data = data, error == nil else {
             return
          }
          DispatchQueue.main.async() {
              image.geometry?.firstMaterial?.diffuse.contents = UIImage(data: data)
         }
       }
    }

}
