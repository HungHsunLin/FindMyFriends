//
//  FriendTableViewCell.swift
//  FindMyFriends
//
//  Created by HUNG-HSUN LIN on 2018/11/3.
//  Copyright © 2018 Hung Hsun Lin. All rights reserved.
//

import UIKit
import MapKit

class FriendTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locatilyLabel: UILabel!
    @IBOutlet weak var lastUpdateTimeLabel: UILabel!
    @IBOutlet weak var distance: UILabel!
    
    
    var friend: Friend? {
        didSet {
            nameLabel.text = friend?.friendName
            lastUpdateTimeLabel.text = friend?.lastUpdateDateTime
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
