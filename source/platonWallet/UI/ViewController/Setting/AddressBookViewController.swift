//
//  AddressBookViewController.swift
//  platonWallet
//
//  Created by matrixelement on 29/10/2018.
//  Copyright © 2018 ju. All rights reserved.
//

import UIKit
import Localize_Swift
import SwipeCellKit

typealias SelectionCompletion = (_ addressInfo : AddressInfo?) -> ()

class AddressBookViewController: BaseViewController {

    var selectionCompletion : SelectionCompletion?
    
    var dataSource : [AddressInfo]? = []
    
    var tableView : UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSubViews()
        initNavigationItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        initData()
    }
    
    func initData(){
        dataSource?.removeAll()
        let data = AddressBookService.service.getAll()
        if data.count == 0{
            tableView.showEmptyView(description: Localized("AddresssBookVC_empty_tip"))
        }else{
            dataSource?.append(contentsOf: data)
            tableView.removeEmptyView()
        }
        tableView!.reloadData()
    }
    
    
    func initSubViews() {
        
        view.backgroundColor = UIViewController_backround
        tableView = UITableView()
        tableView.backgroundColor = UIViewController_backround
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = .zero
        tableView.separatorColor = UIColor(rgb: 0x32394E)
        tableView.tableFooterView = UIView()
        view.addSubview(tableView!)
        tableView!.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
        tableView.registerCell(cellTypes: [AddressBookTableViewCell.self])
    }
    
    func initNavigationItem(){
        
        navigationItem.localizedText = "AddressBookVC_nav_title"
        
        let addButton = UIButton(type: .custom)
        addButton.setImage(UIImage(named: "navAdd"), for: .normal)
        addButton.addTarget(self, action: #selector(onNavRight), for: .touchUpInside)
        addButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        let rightBarButtonItem = UIBarButtonItem(customView: addButton)
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    @objc func onNavRight() {
        let newAddrInfo = NewAddressInfoViewController()
        navigationController?.pushViewController(newAddrInfo, animated: true)
    }

}


extension AddressBookViewController:UITableViewDataSource,UITableViewDelegate,SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AddressBookTableViewCell.self)) as! AddressBookTableViewCell
        cell.delegate = self 
        cell.setUpdCell(addressInfo: dataSource![indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (dataSource?.count)!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (selectionCompletion != nil) {
            let info = dataSource![indexPath.row]
            selectionCompletion!(info)
            navigationController?.popViewController(animated: true)
        }else {
            UIPasteboard.general.string = dataSource![indexPath.row].walletAddress ?? ""
            showMessage(text: Localized("ExportVC_copy_success"))
        }
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }

        let deleteAction = SwipeAction(style: .default, title: Localized("AddressBookVC_cell_delete_title")) { action, indexPath in
            
            AddressBookService.service.delete(addressInfo: self.dataSource![indexPath.row])
            self.dataSource?.remove(at: indexPath.row)
            action.fulfill(with: .delete)
            
        }
        deleteAction.backgroundColor = UIColor(rgb: 0xDC5151)
        deleteAction.textColor = UIColor.white   
        deleteAction.font = UIFont.systemFont(ofSize: 13)
        deleteAction.hidesWhenSelected = true
        
        let editAction = SwipeAction(style: .default, title: Localized("AddressBookVC_cell_edit_title")) { (action, indexPath) in
            
            let vc = NewAddressInfoViewController()
            vc.fromScene = .edit
            vc.addressInfo = self.dataSource![indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
        }
        editAction.backgroundColor = UIColor(rgb: 0xEFF0F5)
        editAction.textColor = UIColor(rgb: 0x1B2137)   
        editAction.font = UIFont.systemFont(ofSize: 13)
        editAction.hidesWhenSelected = true
        return [deleteAction, editAction]
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.maximumButtonWidth = 60
        options.expansionStyle = .destructive
        options.transitionStyle = .border
        return options
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //bug fix for below ios10 tableView cannot response separatorInset
        if #available(iOS 10, *) {
            
        }else {
            cell.layoutMargins = .zero
        }
    }
    
}
