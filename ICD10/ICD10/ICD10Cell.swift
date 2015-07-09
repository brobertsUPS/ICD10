//
//  ICD10Cell.swift
//  ICD10
//
//  Created by Brandon S Roberts on 7/2/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class ICD10Cell: UICollectionViewCell {
    
    @IBOutlet weak var ICDLabel: UILabel!
    @IBOutlet weak var extensionLabel: UILabel!
    @IBOutlet weak var deleteICDButton: ICDDeleteButton!
    @IBOutlet weak var importanceLabel: UILabel!
}
