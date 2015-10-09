//
//  CodeTokenCollectionViewCell.swift
//  ICD10
//
//  Created by Brandon S Roberts on 7/1/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class CodeTokenCollectionViewCell: UICollectionReusableView {
    
    @IBOutlet weak var visitCodeLabel: UILabel!
    @IBOutlet weak var deleteCodeButton: ICDDeleteButton!
    @IBOutlet weak var addICDCodeButton: ICDDeleteButton!
    @IBOutlet weak var shiftUpButton: ICDDeleteButton!
    @IBOutlet weak var shiftDownButton: ICDDeleteButton!
    @IBOutlet weak var visitCodeDetailButton: UIButton!
    @IBOutlet weak var modifierButton: ICDDeleteButton!
    
    var visitCodeText:String!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

}
