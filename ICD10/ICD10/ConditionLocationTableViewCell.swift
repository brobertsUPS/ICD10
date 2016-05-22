//
//  ConditionLocationTableViewCell.swift
//  ICD10
//
//  Created by Brandon S Roberts on 7/24/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class ConditionLocationTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addFavoritesButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.titleLabel.frame = CGRect(x: 15,y: 0,width: self.titleLabel.frame.width - 50, height: self.titleLabel.frame.height)
        self.titleLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        
        self.titleLabel.bounds = self.titleLabel.frame
    }

}
