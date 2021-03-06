//
//  CreateSharedWalletStep2ViewController.swift
//  platonWallet
//
//  Created by matrixelement on 2018/11/14.
//  Copyright © 2018 ju. All rights reserved.
//

import UIKit
import Localize_Swift
import BigInt

class CreateSharedWalletStep2ViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var numOfMembers: Int = 0 {
        didSet {
            for i in 0..<numOfMembers {
                dataSource[i] = ("","","")
            }
        }
    }
    
    var confirmPopUpView : PopUpViewController?
    
    var signRequired = 0
    
    var wallet : Wallet?
    
    var deoplyGas : BigUInt?
    
    var initWalletGas : BigUInt?
    
    var sharedWalletName : String = ""
    
    var dataSource = [Int:(address: String, remark: String, tips: String)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    func setupUI() {
        
        title = Localized("CreateSharedWalletVC_Create Shared Wallet")
        
        tableView.backgroundColor = UIViewController_backround
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "CreateSharedWalletMemberTableViewCell", bundle: nil), forCellReuseIdentifier: NSStringFromClass(CreateSharedWalletMemberTableViewCell.self))
        tableView.keyboardDismissMode = .interactive
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        tableView.addGestureRecognizer(tap)
        
        saveAddress((self.wallet?.key?.address)!, inRow: 0)
        saveRemark(Localized("MemberSignDetailVC_YOU"), inRow: 0)
    }
    
    @objc func onTap(){
        for cell in self.tableView.visibleCells{
            if let tcell = cell as? CreateSharedWalletMemberTableViewCell{
                tcell.remarkTF.resignFirstResponder()
                tcell.addressTF.resignFirstResponder()
            }
            
        }
    }
    
    //keyboard notification
    @objc func keyboardWillChangeFrame(_ notify:Notification) {
        
        let endFrame = notify.userInfo!["UIKeyboardFrameEndUserInfoKey"] as! CGRect
        if endFrame.origin.y - UIScreen.main.bounds.height < 0 {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: endFrame.size.height - 68, right: 0)
        }else {
            tableView.contentInset = .zero
        }
        
    }

    
    private func checkInputValueIsValid(index: Int, isEndEditFromAddress: Bool = true) -> Bool {
        
        guard var data = dataSource[index] else {
            return false
        }
        
        var res = true
        
        if data.remark.length > 12 {
            
            data.tips = Localized("CreateSharedWalletVC_memberRemark_illegal_tips")
            res = false
            
        }else {
            
            if data.address.length > 0 && !data.address.isValidAddress() {
                data.tips = Localized("CreateSharedWalletVC_address_illegal_tips")
                res = false
            }else if data.address.length == 0 && isEndEditFromAddress {
                data.tips = Localized("CreateSharedWalletVC_address_empty_tips")
                res = false
            }else {
                data.tips = ""
                res = true
            }
        }

        dataSource[index] = data
        
        return res
    }

    private func saveRemark(_ remark: String, inRow row: Int) {
        dataSource[row]?.remark = remark
    }
    
    private func saveAddress(_ address: String, inRow row: Int) {
        dataSource[row]?.address = address
    }
    
    private func checkDataSourceIsValid() -> (Bool, String) {
        
        for i in 0..<numOfMembers {
            if !checkInputValueIsValid(index: i) {
                return (false,Localized("Common_checkInput"))
            }
        }
        
        var dic : Dictionary<String,Any> = [:]
        
        for i in 0..<numOfMembers {
            let data = dataSource[i]
            dic[(data?.address)!] = i
        }
        if dic.values.count < dataSource.count{
            return (false,Localized("AddSharedWallet_address_duplicated"))
        }
        
        return (true,"")
        
    }

    @IBAction func create(_ sender: Any) {
        
        view.endEditing(true)
        
        let result = checkDataSourceIsValid()
        if !result.0 {
            showMessage(text: result.1)
        }else {
            
            var addresses : [String] = []
            for item in self.dataSource{
                addresses.append(item.value.address)
            }
            self.showLoading()
            SWalletService.sharedInstance.checkArrayisSharedWalletContract(addresses: addresses, completion: { (result, data) in
                switch result{
                case .success:
                    self.estimaGas()
                case .fail(let code, let errMsg):
                    self.hideLoading()
                    self.showMessageWithCodeAndMsg(code: code!, text: errMsg!, delay: 2.5)
                }
            })
        }
        tableView.reloadData()
    }
    
    
    func estimaGas(){
        var addresses : [String] = []
        for item in self.dataSource{
            addresses.append(item.value.address)
        }

        SWalletService.sharedInstance.estimateCreateWalletGas(sender: (wallet?.key?.address)!, addresses: addresses, require: UInt64(self.signRequired)) { (result, data) in
            self.hideLoading()
            switch result{
                
            case .success:
                if let estimated = data as? (BigUInt?,BigUInt?){
                    
                    self.deoplyGas = estimated.0
                    self.initWalletGas = estimated.1
                    
                    var totalGas = estimated.0
                    if UIDisplay_addInitWalletGas{
                        totalGas?.multiplyAndAdd(estimated.0 ?? BigUInt(0), 1)
                    }
                    
                    self.showCreateContractFee(gasPrice: TransactionService.service.ethGasPrice!, gas: totalGas!)
                }
                
            case .fail(let code, let errMsg):
                self.showMessageWithCodeAndMsg(code: code!, text: errMsg!, delay: 2.5)
            }
        }
    }
    
    func showCreateContractFee(gasPrice: BigUInt, gas: BigUInt){
        confirmPopUpView = PopUpViewController()
        let confirmView = UIView.viewFromXib(theClass: FeeConfirmView.self) as! FeeConfirmView
        confirmView.submitButton.addTarget(self, action: #selector(onSubmit), for: .touchUpInside)
        confirmPopUpView?.setUpContentView(view: confirmView, size: CGSize(width: kUIScreenWidth, height: 247.2))
        confirmPopUpView?.setCloseEvent(button: confirmView.closeButton)
        
        let fee = gasPrice.multiplied(by: gas)
        let feeDescription = fee.divide(by: ETHToWeiMultiplier, round: 8).balanceFixToDisplay(maxRound: 8).ATPSuffix()
        
        confirmView.feeLabel.text = feeDescription
        confirmPopUpView?.show(inViewController: self)
    }
    
    @objc func onSubmit() {
        
        if TransactionService.service.ethGasPrice == nil{
            TransactionService.service.getEthGasPrice(completion: nil)
            self.showMessage(text: Localized("transferVC_Insufficient_network_error"))
            return
        }
        
        self.showInputPswAlert()
        confirmPopUpView?.onDismissViewController()
    }
    
    func showInputPswAlert() {
        
        let alertC = PAlertController(title: Localized("alert_input_psw_title"), message: nil)
        alertC.addTextField(text: "", placeholder: "", isSecureTextEntry: true)
        
        alertC.addAction(title: Localized("alert_cancelBtn_title")) {
        }
        
        alertC.addAction(title: Localized("alert_confirmBtn_title")) { [weak self] in
            
            if !CommonService.isValidWalletPassword(alertC.textField?.text ?? "").0{
                return
            }
            alertC.dismiss(animated: true, completion: nil)
            
            guard self!.wallet != nil else{
                return
            }
            
            self!.showLoading()
            WalletService.sharedInstance.exportPrivateKey(wallet: self!.wallet!, password: (alertC.textField?.text)!, completion: { (pri, err) in
                if (err == nil && (pri?.length)! > 0) {
                    self?.doCreateSharedWallet(pri: pri!)
                }else{
                    self?.hideLoading()
                    self?.showMessage(text: (err?.errorDescription)!)
                }
            })
            
        }
        alertC.inputVerify = { input in
            return CommonService.isValidWalletPassword(input).0
        }
        alertC.addActionEnableStyle(title: Localized("alert_confirmBtn_title"))
        alertC.show(inViewController: self, animated: false)
        alertC.textField?.becomeFirstResponder()
        
    }
    
    func doCreateSharedWallet(pri: String){
        
        let sw = SWallet()
        sw.name = self.sharedWalletName
        sw.walletAddress = (self.wallet?.key?.address)!
        sw.required = self.signRequired
        
        var addresses : [String] = []
        
        for item in self.dataSource{
            let addressInfo = AddressInfo()
            addressInfo.createTime = Date().millisecondsSince1970
            addressInfo.updateTime = addressInfo.createTime
            addressInfo.walletAddress = item.value.address
            addressInfo.walletName = item.value.remark
            addressInfo.addressType = AddressType_SharedWallet
            sw.owners.append(addressInfo)
            addresses.append(item.value.address)
        }
        
        let require = NSNumber(value: (self.signRequired))
        
        let gasPrice = TransactionService.service.ethGasPrice
        
        SWalletService.sharedInstance.createWalletAsync(
        sharedWallet: sw,
        sender: sw.walletAddress,
        deployGasPrice: gasPrice!,
        deployGgas: (self.deoplyGas)!,
        initGasPrice: gasPrice!,
        initGgas: (self.initWalletGas)!,
        privateKey: pri,
        addresses: addresses,
        require: require.uint64Value
        ) { (ret, obj) in
            self.hideLoading()
            switch ret{
            case .success:
                UIApplication.rootViewController().showMessage(text: Localized("Shared wallet create success"))
                
                self.navigationController?.popToRootViewController(animated: true)
            case .fail( let code, let errMsg):
                if code == -111{
                    self.showMessage(text: Localized("SharedWallet_create_with_insufficient_balance"))
                }else{
                    self.showMessage(text: errMsg ?? "")
                }
                
            }
        }
        
    }
}





extension CreateSharedWalletStep2ViewController: UITableViewDelegate, UITableViewDataSource, CreateSharedWalletMemberDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numOfMembers
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(CreateSharedWalletMemberTableViewCell.self), for: indexPath) as! CreateSharedWalletMemberTableViewCell
        //disable reuse
        //let cell = UIView.viewFromXib(theClass: CreateSharedWalletMemberTableViewCell.self) as! CreateSharedWalletMemberTableViewCell
        let data = dataSource[indexPath.row]!

        let title = Localized("CreateSharedWalletVC_member") + "\(indexPath.row + 1)"

        
        cell.setup(title: title, address: data.address, remark: data.remark, tips: data.tips, index: indexPath.row)
        cell.delegate = self
        
        
        if indexPath.row == 0{
            cell.setEnableMode(enable: false)
        }else{
            cell.setEnableMode(enable: true)
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (dataSource[indexPath.row]?.tips ?? "").length > 0 ? 150:125
    }
    
    //MARK: - CreateSharedWalletMemberDelegate
    func tableViewCellDidClickScan(_ cell: UITableViewCell) {
        
        view.endEditing(true)
        
        let scanVC = QRScannerViewController { [weak self](res) in
            
            guard let strongSelf = self else {
                return
            }

            
            guard let indexPath = strongSelf.tableView.indexPath(for: cell) else{
                return
            }
                
            if res.isValidAddress() {
                
                strongSelf.showMessage(text: Localized("QRScan_success_tips"))
                
                strongSelf.saveAddress(res, inRow: indexPath.row)
                
                let _ = strongSelf.checkInputValueIsValid(index: indexPath.row)
                strongSelf.tableView.reloadData()
                
            }else {
                strongSelf.showMessage(text: Localized("QRScan_failed_tips"))
            }
            strongSelf.navigationController?.popViewController(animated: true)
                
        }
        navigationController?.pushViewController(scanVC, animated: true)
    }
    
    func tableViewCellDidClickAddressBook(_ cell: UITableViewCell) {
        
        view.endEditing(true)
        
        let addressBookVC = AddressBookViewController()
        addressBookVC.selectionCompletion = { [weak self](_ addressInfo : AddressInfo?) -> () in
            
            guard let strongSelf = self else {
                return
            }
            
            guard let indexPath = strongSelf.tableView.indexPath(for: cell) else{
                return
            }
            strongSelf.saveAddress(addressInfo?.walletAddress ?? "", inRow: indexPath.row)
            
            let _ = strongSelf.checkInputValueIsValid(index: indexPath.row)
            strongSelf.tableView.reloadData()

        }
        navigationController?.pushViewController(addressBookVC, animated: true)
        
    }
    
    func tableViewCell(_ cell: UITableViewCell, didEndEditTextField content: (remark: String, address: String, isEditAddress: Bool)) {
        
        guard let indexPath = tableView.indexPath(for: cell) else{
            return
        }
        saveAddress(content.address, inRow: indexPath.row)
        saveRemark(content.remark, inRow: indexPath.row)
        
        let _ = checkInputValueIsValid(index: indexPath.row, isEndEditFromAddress: content.isEditAddress)

        tableView.reloadData()

    }
    
}
