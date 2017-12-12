//
//  BuySellViewController.swift
//  GDAXTicker
//
//  Created by Alexandre Barbier on 12/12/2017.
//  Copyright © 2017 Thomas Ricouard. All rights reserved.
//

import UIKit
import GDAX_Swift

class BuySellViewController: UIViewController {
    @IBOutlet var priceTF: UITextField!
    @IBOutlet var volumeTF: UITextField!
    @IBOutlet var moneyAvailableLabel: UILabel!

    var account:Account?
    var euroAccountId: String?
    var euroAccount: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let euroId = euroAccountId {
            GDAX.authenticate.getAccount(accountId: euroId) { (account, error) in
                DispatchQueue.main.async {
                    self.moneyAvailableLabel.text = "\(String(format:"%0.2f",Float(account!.available!)!)) € available"
                }
                GDAX.market.product(productId: "\(self.account!.currency!)-EUR").getLastTick { (last, error) in
                    DispatchQueue.main.async {
                        self.priceTF.text = last?.price
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
