//
//  ExploreViewController+Interactions.swift
//  GravityXR
//
//  Created by Avinash Shetty on 4/25/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit

extension ExploreViewController{
    
    //MARK: Touches begin
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let opts = [ SCNHitTestOption.searchMode:1, SCNHitTestOption.boundingBoxOnly:1 ]

        //1. Get The Current Touch Location & Perform An SCNHitTest To Detect Which Nodes We Have Touched
        guard let currentTouchLocation = touches.first?.location(in: self.sceneView),
            let hitArray:[SCNHitTestResult] = self.sceneView.hitTest(currentTouchLocation, options: opts) else { return }
        
        let hitTestResult = hitArray.first?.node.name
       
        if let hitTestResult = hitTestResult {
            
            if let selectedNode = hitArray.first?.node {

                self.playHotspotsTapped()
                
                //Perform The Neccessary Action Based On The Hit Node
                switch hitTestResult {
                    case "buttonText":buttonTapped(node: selectedNode.parent)
                    case "button":buttonTapped(node: selectedNode)
                    case "hButton":showHideCard(node: selectedNode) //product card back tap
                    case "hButtonImage":showHideCard(node: selectedNode) //product card front tap
                    case "hotspotButton":showHideCustomCard(node: selectedNode) //custom card back tap
                    case "hotspotButtonImage":showHideCustomCard(node: selectedNode) //custom card front tap
                    case "favorite":markAsFavorite(node: selectedNode)

                    default: buttonTapped(node: selectedNode)
                        break
                }
            }
        }else{
            showHideControlBar()
        }
    }
    
    func markAsFavorite(node:SCNNode?){
        guard let node = node else {return}

        var selectedCard:Card? = nil
        for cardObj in self.cards {
            if let _ = findParent(node: node, name: "\(cardObj.id)"){
                selectedCard = cardObj
            }
        }
        
        if let card = selectedCard {
            self.markCardAsFavorite(cardId: card.id)
        }
        node.geometry?.materials.first?.diffuse.contents = UIImage(named: "favorite_selected")

    }
        
    func buttonTapped(node:SCNNode?){
        
        guard let node = node else {return}
        
//        SCNTransaction.begin()
//        SCNTransaction.animationDuration = 3.0
//        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
//        SCNTransaction.commit()

        var selectedCard:Card? = nil
        for cardObj in self.cards {
            if let found = findParent(node: node, name: "\(cardObj.id)"){
                print("Tapped on Card - \(found.name)")
                selectedCard = cardObj
            }
        }

        if let idNode = node.childNode(withName: "ID", recursively: false){
            let newID = idNode as! IDNode
            let root = findRoot(node: node)
            executeAction(fromCard: selectedCard, withButtonId: newID.id, rootNode: root)
        }
                
    }
    
    func executeAction(fromCard card: Card?, withButtonId id: String?, rootNode node: SCNNode?){
        
        guard let card = card else {return}
        guard let id = id else {return}

        guard let cardLayout = card.cardConfig else {return}
        let cardElements = cardLayout.elements
                
        for element in cardElements {
            if element.cardElementType == "BUTTON" && (element.displayOrder == Int(id)) {
                
                //Action vs CTA Type
                switch element.ctaType {
                case "Browse":
                        launchCard(withId: element.url, fromCard: card, rootNode: node)
                case "Link":
                        if let url = URL(string:element.url){
                            launchBrowser(withUrl: url)
                        }
                default:
                        print("Undefined action")
                }
            }
        }
    }
    

    //MARK: - Show Hide
    
    func showHideCustomCard(node:SCNNode){
        
        //look for the card associated with the node
        var selectedCard:Card? = nil
        for cardObj in self.cards {
            if let _ = findParent(node: node, name: "\(cardObj.id)"){
                selectedCard = cardObj
            }
        }

        var filteredHotpsot = false
        if let selectedCard = selectedCard {
            if let _ = self.filteredAnchors.firstIndex(of: selectedCard.anchorId!) {
                filteredHotpsot = true
            }
        }
        
        var cardBG:SCNNode? = nil
        
        if let r = findParent(node: node,name: "rectangleBG"){
            cardBG = r
        }else if let s = findParent(node: node,name: "squareBG"){
            cardBG = s
        }else if let i = findParent(node: node,name: "infoBG"){
            cardBG = i
        }

        if let cardBG = cardBG
        {
            let yScale = cardBG.scale.y
            cardBG.scale.y = 0
            cardBG.isHidden = !cardBG.isHidden
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.1
            cardBG.scale.y = yScale
            SCNTransaction.commit()
        }
        
        if let idNode = findParent(node: node, name: "PrevID"){
            //go back to the previous card
            let prevIDNode = idNode as! IDNode
            let root = findRoot(node: node)
            launchCard(withId: prevIDNode.id!, fromCard: nil, rootNode: root)

        }else{
            //edit the node
            if let cardContent = findParent(node: node, name: "cardContentNode"){
               // SCNTransaction.animationDuration = 1
                cardContent.isHidden = !cardContent.isHidden
                
                if(filteredHotpsot){
                    //SCNTransaction.begin()
                    //SCNTransaction.animationDuration = 0.2
                    if(node.name == "hotspotButtonImage"){
                        node.geometry?.materials.first?.diffuse.contents = cardContent.isHidden ? UIImage(named: "hotspot_filtered") : UIImage(named: "hotspot_filtered_tapped")
                    }else{
                        let child = node.childNodes[0]
                        child.geometry?.materials.first?.diffuse.contents = cardContent.isHidden ? UIImage(named: "hotspot_filtered") : UIImage(named: "hotspot_filtered_tapped")
                    }
                    //SCNTransaction.commit()
                }else{
                    //SCNTransaction.begin()
                    //SCNTransaction.animationDuration = 0.2
                    if(node.name == "hotspotButtonImage"){
                        node.geometry?.materials.first?.diffuse.contents = cardContent.isHidden ? UIImage(named: "hotspot_mapped") : UIImage(named: "hotspot_tapped")
                    }else{
                        let child = node.childNodes[0]
                        child.geometry?.materials.first?.diffuse.contents = cardContent.isHidden ? UIImage(named: "hotspot_mapped") : UIImage(named: "hotspot_tapped")
                    }
                    //SCNTransaction.commit()
                }
            }
        }
    }

    
    func showHideCard(node:SCNNode){
        
        //look for the card associated with the node
        var selectedCard:Card? = nil
        for cardObj in self.cards {
            if let _ = findParent(node: node, name: "\(cardObj.id)"){
                selectedCard = cardObj
            }
        }

        var filteredHotpsot = false
        if let selectedCard = selectedCard {
            if let _ = self.filteredAnchors.firstIndex(of: selectedCard.anchorId!) {
                filteredHotpsot = true
            }
        }
        
        //edit the node
        if let card = findParent(node: node,name: "cardPlane"){
           
            if card.isHidden{
                // card.fadeInOut(opacity: 0,duration:0)
                let yScale = card.scale.y
//                card.scale.y = 0
                card.isHidden = !card.isHidden
//                SCNTransaction.begin()
//                SCNTransaction.animationDuration = 0.2
//                card.pivot = SCNMatrix4MakeTranslation(0, 0.2, 0)
//                card.scale.y = yScale
//                SCNTransaction.commit()
            }else{
                //card.scale.y = 0
                let yScale = card.scale.y
//                SCNTransaction.begin()
//                SCNTransaction.animationDuration = .2
//                card.scale.y = 0
                card.isHidden = !card.isHidden
//                SCNTransaction.commit()
//                card.scale.y = yScale
                //card.spinAnim()
            }
            
            if(filteredHotpsot){
                //                SCNTransaction.begin()
                //                SCNTransaction.animationDuration = 3.0
                if(node.name == "hButtonImage"){
                    node.geometry?.materials.first?.diffuse.contents = card.isHidden ? UIImage(named: "hotspot_filtered") : UIImage(named: "hotspot_filtered_tapped")
                }else{
                    let child = node.childNodes[0]
                    child.geometry?.materials.first?.diffuse.contents = card.isHidden ? UIImage(named: "hotspot_filtered") : UIImage(named: "hotspot_filtered_tapped")
                }
                //                SCNTransaction.commit()
            }else{
                //                SCNTransaction.begin()
                //                SCNTransaction.animationDuration = 3.0
                if(node.name == "hButtonImage"){
                    node.geometry?.materials.first?.diffuse.contents = card.isHidden ? UIImage(named: "hotspot_mapped") : UIImage(named: "hotspot_tapped")
                }else{
                    let child = node.childNodes[0]
                    child.geometry?.materials.first?.diffuse.contents = card.isHidden ? UIImage(named: "hotspot_mapped") : UIImage(named: "hotspot_tapped")
                }
                //                SCNTransaction.commit()
            }
        }
    }
    
    

    func findParent(node:SCNNode,name:String) -> SCNNode?{
        
        guard let parent = node.parent else { return nil }
        
        if(parent.name == "RootNode"){
            if let card = parent.childNode(withName: name, recursively: true){
                return card
            }
        }
        return findParent(node: parent,name: name)
    }
    
    func findRoot(node:SCNNode) -> SCNNode?{
        
        guard let parent = node.parent else { return nil }
        
        if(parent.name == "RootNode"){
            return parent
        }
        return findRoot(node: parent)
    }

    
    
    func launchBrowser(withUrl url:URL){
        
        setupCard(url: url)
        
    }
    
    func didCloseBrowser(){

        animateTransitionIfNeeded(state: .collapsed, duration: 0.1)

    }
    
    func showHideControlBar(){

        controlsBGView.isHidden = bShowingControlBar
        bShowingControlBar = !bShowingControlBar
        
    }
    
    func launchCard(withId cardID: String, fromCard source:Card?, rootNode node: SCNNode?){
                        
        guard let root = node else { return }
        
//        for child in root.childNodes {
//            child.removeFromParentNode()
//        }
                
        if let rootParent = root.parent {
            rootParent.isHidden = true
            for child in rootParent.childNodes {
                child.removeFromParentNode()
            }
            rootParent.isHidden = false
            for card in self.cards {
                if String(card.id) == cardID {
                    
                    switch(card.cardConfig!.type){
                        case "Product Card":
                            let newCard = ProductCard(data: card, prevCard: source, cardType:.cardScn, buttonType: .buttonAnchorScn, showExpanded:true)
                            rootParent.addChildNode(newCard)
                        case "Custom Card":
                            let newCard = CustomCard(data: card, prevCard: source, cardType:.cardScn, buttonType: .buttonAnchorScn, showExpanded:true)
                            rootParent.addChildNode(newCard)
                        default:
                            let newCard = ProductCard(data: card, prevCard: source, cardType:.cardScn, buttonType: .buttonAnchorScn, showExpanded:true)
                            rootParent.addChildNode(newCard)
                    }
                    break
                }
            }
        }
    }


}
