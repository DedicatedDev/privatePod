//
//  TableCell.swift
//  GravityXR
//
//  Created by Avinash Shetty on 4/25/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import UIKit

public class TableCell: UITableViewCell {

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var thumbnailImageView: UIImageView!

    public override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        thumbnailImageView.image = nil
    }

    // MARK: Cell Configuration
    public func configurateTheCell(_ product: Product) {
        titleLabel.text = product.name
        subtitleLabel.text = product.description
        if let imgURL = product.thumbnails {
            thumbnailImageView.image = UIImage(named: imgURL)
        }
    }

}
