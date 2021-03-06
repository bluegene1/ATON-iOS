//
//  MemberOperTableViewCell.swift
//  platonWallet
//
//  Created by matrixelement on 15/11/2018.
//  Copyright © 2018 ju. All rights reserved.
//

import UIKit

class MemberOperTableViewCell: UITableViewCell {

    @IBOutlet weak var walletName: UILabel!
    
    @IBOutlet weak var operationIcon: UIImageView!
    
    @IBOutlet weak var walletAddress: UILabel!
    
    @IBOutlet weak var copyButton: CopyButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        copyButton.attachTextView = walletAddress
    }

    func updateCell(result: DeterminedResult, swallet: SWallet) {
        
        let copyResult = DeterminedResult(value: result as Any)
        
        for item in (swallet.owners){
            if item.walletAddress == copyResult.walletAddress{
                copyResult.walletName = item.walletName
            }
        }
        
        walletName.text = copyResult.walletName
        walletAddress.text = copyResult.walletAddress
        
        if result.operation == OperationAction.approval.rawValue{
            operationIcon.image = UIImage(named: "iconApprove")
        }else if result.operation == OperationAction.revoke.rawValue{
            operationIcon.image = UIImage(named: "iconRevoke")
        }
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
