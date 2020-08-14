//
//  ProductCard.swift
//  GravityXR
//
//  Created by Avinash Shetty on 4/25/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import SceneKit

public class ProductCard: SCNNode {
    
    enum ARScenes: CustomStringConvertible{
        case cardScn
        case buttonAnchorScn

        var description: String{
            switch self {
                case .cardScn:
                    return "Art.scnassets/product_card.scn"
                case .buttonAnchorScn:
                    return "Art.scnassets/hotspot.scn"
            }
        }
    }
    
    var cardData: Card!
    var prevCardData: Card?

    //hotspot
    var button: SCNNode!   { didSet { button.name = "hButton" } }
    var buttonImage: SCNNode!   { didSet { buttonImage.name = "hButtonImage" } }
    var toggleButtonParent:SCNNode!   { didSet {toggleButtonParent.name = "toggleButtonParent"}}

    //Card
    var cardPlane: SCNNode!   { didSet { cardPlane.name = "cardPlane" } }
    var UserImage: SCNNode!   { didSet { UserImage.name = "UserImage" } }
    var button1: SCNNode!   { didSet { button1.name = "button1" } }
    var button2: SCNNode!   { didSet { button2.name = "button2" } }
    var button3: SCNNode!   { didSet { button3.name = "button3" } }
    var button1text: SCNText!
    var button2text: SCNText!
    var button3text: SCNText!
    var titleText: SCNText!
    var favorite: SCNNode!
    var OpenButton: SCNNode!   { didSet { OpenButton.name = "OpenButton" } }
    var bShowExpanded:Bool = false

    init(data: Card? = nil, prevCard: Card?, cardType: ARScenes, buttonType:ARScenes, showExpanded:Bool = false) {
        
        super.init()
        
        self.cardData = data
        self.prevCardData = prevCard
        self.bShowExpanded = showExpanded
        
        guard let cardScene = SCNScene(named: cardType.description),

            let hotspotScene = SCNScene(named: buttonType.description),
            let buttonRoot = hotspotScene.rootNode.childNode(withName: "RootNode", recursively: false),
            let button = buttonRoot.childNode(withName: "hButton", recursively: false),
            let buttonImage = button.childNode(withName: "hButtonImage", recursively: false),

            let cardRoot = cardScene.rootNode.childNode(withName: "RootNode", recursively: false),
            let cardPlane = cardRoot.childNode(withName: "cardPlane", recursively: false),
            let UserImage = cardPlane.childNode(withName: "UserImage", recursively: false),
            let button1 = cardPlane.childNode(withName: "button1", recursively: false),
            let button2 = cardPlane.childNode(withName: "button2", recursively: false),
            let button3 = cardPlane.childNode(withName: "button3", recursively: false),
            let button1text = button1.childNode(withName: "buttonText", recursively: false)?.geometry as? SCNText,
            let button2text = button2.childNode(withName: "buttonText", recursively: false)?.geometry as? SCNText,
            let button3text = button3.childNode(withName: "buttonText", recursively: false)?.geometry as? SCNText,
            let titleText = cardPlane.childNode(withName: "titleText", recursively: false)?.geometry as? SCNText,
            let favorite = cardPlane.childNode(withName: "favorite", recursively: false),

            let toggleButtonParent = cardRoot.childNode(withName: "toggleButtonParent", recursively: false),
            let OpenButton = toggleButtonParent.childNode(withName: "OpenButton", recursively: false)
            
            else { fatalError("Error Getting Card Node Data") }
        
        
        //Used for uniquely identifying a card
        cardRoot.addChildNode(IDNode(id: self.cardData.id, name: String(self.cardData.id)))
        if self.prevCardData != nil{
            cardRoot.addChildNode(IDNode(id: self.prevCardData!.id, name: "PrevID"))
        }

        self.cardPlane = cardPlane
        self.UserImage = UserImage
        self.button1 = button1
        self.button2 = button2
        self.button3 = button3
        self.button1text = button1text
        self.button2text = button2text
        self.button3text = button3text
        self.titleText = titleText
        self.OpenButton = OpenButton
        
        self.button = button
        self.buttonImage = buttonImage
        self.favorite = favorite
        
        OpenButton.removeFromParentNode()
        toggleButtonParent.addChildNode(button)

        //5. Add It To The Hieracy
        self.addChildNode(cardRoot)
        self.cardPlane.isHidden = !bShowExpanded
        
        setConfiguration()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit { flushFromMemory() }
    
    
    func setConfiguration(){
        
        //Configuration Starts here
        guard let layout:CardConfig = self.cardData.cardConfig else {return}

        let cardBackgroundColor = UIColor(hex:layout.background ?? "#FFFFFF")
        let cardTitle = layout.title ?? "NA"
        let cardLabelColor = UIColor(hex:layout.labelColor ?? "#FFFFFF")
        let buttonBGColor = UIColor(hex:layout.buttonBgColor ?? "#FFFFFF")
        _ = UIColor(hex:layout.buttonHighlightColor ?? "#64BBE3")
        let buttonLabelColor = UIColor(hex:layout.labelColor ?? "#000000")
        
        cardPlane.geometry?.firstMaterial?.diffuse.contents = cardBackgroundColor
        setCardTitle(textNode: titleText, parent: cardPlane, text: cardTitle)
        titleText.materials.first?.diffuse.contents = cardLabelColor

        if self.prevCardData != nil {
            self.buttonImage.geometry?.materials.first?.diffuse.contents = UIImage(named: "hotspot_back")
        }
        
        let cardElements = layout.elements

        for element in cardElements {
            if element.cardElementType == "IMAGE" {
                if element.url.count > 0  {
                    UserImage.isHidden = false
                    if let downloadURL = URL(string: element.url){
                        downloadImage(from: downloadURL)
                    }
                }
            }else if element.cardElementType == "BUTTON" {
                
                let idNode = IDNode(id: element.displayOrder, name: "ID")
                
                switch element.displayOrder {
                case 2:
                    button1.addChildNode(idNode)
                    setTextOnButtons(textNode: button1text, parent: button1, text: element.text! )
                    button1text.materials.first?.diffuse.contents = buttonLabelColor
                    button1.geometry?.firstMaterial?.diffuse.contents = buttonBGColor
                    button1.isHidden = false
                case 3:
                    button2.addChildNode(idNode)
                    setTextOnButtons(textNode: button2text, parent: button2, text: element.text!)
                    button2text.materials.first?.diffuse.contents = buttonLabelColor
                    button2.geometry?.firstMaterial?.diffuse.contents = buttonBGColor
                    button2.isHidden = false
                case 4:
                    button3.addChildNode(idNode)
                    setTextOnButtons(textNode: button3text, parent: button3, text: element.text!)
                    button3text.materials.first?.diffuse.contents = buttonLabelColor
                    button3.geometry?.firstMaterial?.diffuse.contents = buttonBGColor
                    button3.isHidden = false

                default:
                    print("More than 3 buttons..not sure what to do")
                }
            }
        }
        
        if self.cardData.productId == 0 {
            self.favorite.removeFromParentNode()
        }
        
    }
    
    func setCardTitle(textNode:SCNText,parent:SCNNode,text:String){
        textNode.string = text
        textNode.containerFrame = CGRect(origin: .zero, size: CGSize(width: 70, height: 15))
        textNode.truncationMode = CATextLayerTruncationMode.none.rawValue
        textNode.isWrapped = true
        textNode.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        textNode.font = UIFont.systemFont(ofSize: 12)
        self.parent?.scale = SCNVector3Make(1.186, 1.879, 0.17)
    }
    
    func setTextOnButtons(textNode:SCNText,parent:SCNNode,text:String){
        textNode.string = text
        textNode.containerFrame = CGRect(origin: .zero, size: CGSize(width: 55.0, height: 11))
        textNode.truncationMode = CATextLayerTruncationMode.none.rawValue
        textNode.isWrapped = true
        textNode.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        textNode.font = UIFont.systemFont(ofSize: 8)
        self.parent?.scale = SCNVector3Make(0.8, 0.1, 5.0)
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
    
    func downloadImage(from url: URL) {
       getData(from: url) {
          data, response, error in
          guard let data = data, error == nil else {
             return
          }
          DispatchQueue.main.async() {
              self.UserImage.geometry?.firstMaterial?.diffuse.contents = UIImage(data: data)
         }
       }
    }
    
}

extension SCNNode{
    
    func faceCamera() {
        
        guard constraints?.isEmpty ?? true else {
            return
        }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 5
        SCNTransaction.completionBlock = { [weak self] in
            self?.constraints = []
        }
        
        let billboardConstraint: SCNBillboardConstraint = {
            let constraint = SCNBillboardConstraint()
            constraint.freeAxes = [.Y]
            return constraint
        }()
        constraints = [billboardConstraint]
        SCNTransaction.commit()
    }

}
