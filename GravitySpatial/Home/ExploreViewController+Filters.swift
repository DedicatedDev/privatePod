//
//  ExploreViewController+Filters.swift
//  GravityXR
//
//  Created by Avinash Shetty on 5/16/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import Alamofire


extension ExploreViewController: UIPopoverPresentationControllerDelegate, FilterPopoverControllerDelegate{
    
    func addFilterButton(){
        
        let result = UIButton(type: .custom)
        result.setTitleColor(.black, for: .normal)
        result.setTitleShadowColor(.white, for: .normal)
        result.setImage(UIImage(named:"filter_white"), for: .normal)

        self.filtersButton = result
        self.filtersButton.addTarget(self, action:#selector(filterButtonTap), for: .touchDown)

    }
    

    @objc func filterButtonTap(sender: UIButton) {
        
        //get the button frame
        let buttonFrame = sender.frame
        
        //Configure the presentation controller
        let filterPopoverController = self.storyboard?.instantiateViewController(withIdentifier: "FilterPopover") as? FilterPopoverController
        filterPopoverController?.modalPresentationStyle = .popover
        
        if let popoverPresentationController = filterPopoverController?.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .up
            popoverPresentationController.sourceView = self.controlsView
            popoverPresentationController.sourceRect = buttonFrame
            popoverPresentationController.delegate = self
            /*Set the delegate */
            filterPopoverController?.delegate = self
            filterPopoverController?.filters = self.filters
            
            if let popoverController = filterPopoverController {
                present(popoverController, animated: true, completion: nil)
            }
        }
    }
    
    func getFilters() {
        
        let getFiltersURL = Endpoint.industry.urlStr

        AF.request(getFiltersURL, method: .get, headers: Endpoint.industry.headers, interceptor: RequestInterceptor())
          .responseDecodable(of: [Industry].self){ response in
            
            let statusCode = response.response?.statusCode
            print("fetchProducts - \(statusCode)")

            switch response.result {
                case .success:
                    guard let responses:[Industry] = response.value else { return }
                    self.filters = responses
                    
                    DispatchQueue.main.async {
                        self.filtersButton.isHidden = false
                    }
                case let .failure(error):
                    print(error)
            }
            
            self.filters.insert(Industry(id: -1, name: "Clear Filters"), at: 0)
        }
    }
    
    
    func popoverContent(controller: FilterPopoverController, didselectItem filter: Industry) {

        //clear old list
        filteredAnchors.removeAll()
        
        //Redraw nodes with selected industry filters
        let filterPicked = filter.id
        
        for card in self.cards {
            
            if (card.domainList != nil) && (card.anchorId != nil) { //card has a domain filter and has an anchor
                if (card.domainList?.contains(filterPicked))! { //does it have the domain the user picked
                    
                    //add to the list of filteredAnchors
                    self.filteredAnchors.append(String(card.id))
                }
            }
        }
        
        self.refreshNodesForFilterUpdate()
    }
    
    func popoverContentResetFilter(controller:FilterPopoverController){
       
        //clear old list
        filteredAnchors.removeAll()
        
        self.refreshNodesForFilterUpdate()

    }



    func refreshNodesForFilterUpdate(){
    
        for visual in anchorVisuals.values {
                       
            if let _ = visual.node { //we have a hotspot shown in the World
                                
                if let _ = self.filteredAnchors.firstIndex(of: visual.identifier) {
                            
                    //change color of hotspot
                    if let buttonRoot = visual.node!.childNode(withName: "RootNode", recursively: false){ //ignore occlusion nodes
                        if let toggleButton = buttonRoot.childNode(withName: "toggleButtonParent", recursively: false){
                        
                            if let button = toggleButton.childNode(withName: "hButton", recursively: false){
                                button.geometry?.materials.first?.diffuse.contents = UIColor.blue.withAlphaComponent(0.9)

                                if let buttonImage = button.childNode(withName: "hButtonImage", recursively: false){
                                    buttonImage.geometry?.materials.first?.diffuse.contents = UIImage(named: "hotspot_filtered")
                                }
                            }else if let button = buttonRoot.childNode(withName: "hotspotButton", recursively: false){
                                button.geometry?.materials.first?.diffuse.contents = UIColor.blue.withAlphaComponent(0.9)

                                if let buttonImage = button.childNode(withName: "hotspotButtonImage", recursively: false){
                                    buttonImage.geometry?.materials.first?.diffuse.contents = UIImage(named: "hotspot_filtered")
                                }
                            }
                        }
                    }
                }else{
                    
                    //change color of hotspot
                    if let buttonRoot = visual.node!.childNode(withName: "RootNode", recursively: false) { //ignore occlusion nodes
                        if let toggleButton = buttonRoot.childNode(withName: "toggleButtonParent", recursively: false){
                        
                            if let button = toggleButton.childNode(withName: "hButton", recursively: false) {
                                button.geometry?.materials.first?.diffuse.contents = UIColor.white.withAlphaComponent(0.9)

                                if let buttonImage = button.childNode(withName: "hButtonImage", recursively: false){
                                    buttonImage.geometry?.materials.first?.diffuse.contents = UIImage(named: "hotspot_mapped")
                                }
                            }else if let button = buttonRoot.childNode(withName: "hotspotButton", recursively: false) {
                                button.geometry?.materials.first?.diffuse.contents = UIColor.white.withAlphaComponent(0.9)

                                if let buttonImage = button.childNode(withName: "hotspotButtonImage", recursively: false){
                                    buttonImage.geometry?.materials.first?.diffuse.contents = UIImage(named: "hotspot_mapped")
                                }
                            }
                        }
                    }

                }
            }
        }
    }
    
}

//Protocol Declaration
protocol FilterPopoverControllerDelegate:class {
    func popoverContent(controller:FilterPopoverController, didselectItem filter:Industry)
    func popoverContentResetFilter(controller:FilterPopoverController)
}
//End Protocol

class FilterPopoverController:UIViewController, UITableViewDelegate, UITableViewDataSource {

    var filters: [Industry] = []
    static let CELL_RESUE_ID = "POPOVER_CELL_REUSE_ID"
    
    var updateIndex:IndexPath? // this is the index path of the cell need to update in the viewcontroller
    
    var delegate:FilterPopoverControllerDelegate? //declare a delegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        var cell = tableView.dequeueReusableCell(withIdentifier: FilterPopoverController.CELL_RESUE_ID)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: FilterPopoverController.CELL_RESUE_ID)
        }
        
        cell?.textLabel?.text = filters[indexPath.row].name
        return cell ?? UITableViewCell()
    
    }
    
    //MARK: Tableview Delegate method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if(indexPath.row == 0){
            self.delegate?.popoverContentResetFilter(controller: self)
        }else{
            let selectedFilter = filters[indexPath.row]
            self.delegate?.popoverContent(controller: self, didselectItem: selectedFilter)
        }
        self.dismiss(animated: true, completion: nil)

    }
    
}

