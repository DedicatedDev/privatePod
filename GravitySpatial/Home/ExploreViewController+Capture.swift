//
//  ExploreViewController+Capture.swift
//  GravityXR
//
//  Created by Avinash Shetty on 5/16/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import UIKit

extension ExploreViewController{
    
    func addCaptureButton(){
        
        let result = UIButton(type: .custom)
        result.setTitleColor(.black, for: .normal)
        result.setTitleShadowColor(.white, for: .normal)
        result.setImage(UIImage(named:"capture_white"), for: .normal)
        //self.controlsView.addArrangedSubview(result)

        self.captureButton = result
        self.captureButton.addTarget(self, action:#selector(captureButtonTap), for: .touchDown)

    }

    
    //MARK: - Add image to Library
    @objc func captureButtonTap(sender: UIButton) {
        
        let image = self.sceneView.snapshot()
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        
        if let error = error {
            // we got back an error!
            showAlertWith(title: "Error capturing the experience", message: error.localizedDescription)
        } else {
            showAlertWith(title: "Snapshot Saved", message: "Your snapshot has been saved to your photos.")
        }
    }
    
    func showAlertWith(title: String, message: String){
        
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        
    }

    
}
