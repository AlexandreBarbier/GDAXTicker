//
//  AccountViewController.swift
//  GDAXTicker
//
//  Created by Alexandre Barbier on 08/12/2017.
//  Copyright © 2017 Thomas Ricouard. All rights reserved.
//

import UIKit
import GDAX_Swift
import UserNotifications

class AccountViewController: UIViewController {

    @IBOutlet var moneyLabel: UILabel!
    @IBOutlet var balanceLabel: UILabel!
    @IBOutlet var gainLabel: UILabel!
    @IBOutlet var statsLabel: UILabel!

    var accountSubscription: Subscription?
    var accountsEmbbedController: AccountEmbedViewController!
    var accounts:[String: Account] = [:]
    var isConnected = false

    var lastStats: [String:StatResponse] = [:]

    var gain: String = "" {
        didSet {
            moneyLabel.text = gain
        }
    }
    var capitalGain:[String: Float] = [:]
    var orders:[String: [OrderResponse]] = [:] {
        didSet {
            for (key, value) in orders {
                var total:Float = 0
                for order in value {
                    let val = Float(order.price!)! * Float(order.size!)!
                    total += order.side == "buy" ? -val : val
                }
                capitalGain[key] = total
            }
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "account"

        GDAX.market.product(productId: "LTC-EUR").get24hStats { (stat, error) in
            DispatchQueue.main.async {
                if stat?.open != nil {
                self.lastStats["LTC-EUR"] = stat
                self.statsLabel.text = "\topen : \(String(format: "%0.2f", Float(stat!.open!)!))\thigh : \(String(format: "%0.2f", Float(stat!.high!)!))\tlow : \(String(format: "%0.2f", Float(stat!.low!)!))"
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AccountEmbedSegue" {
            let nav = segue.destination as! UINavigationController
            accountsEmbbedController = nav.viewControllers.first as! AccountEmbedViewController
            accountsEmbbedController.delegate = self
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard GDAX.isAuthenticated else {
            GDAX.askForAuthentication(inVC: self) { $0 ? self.connect() : () }
            return
        }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.badge, .sound, .alert]) {(_,_) in }
        connect()
    }

    func connect() {
        !self.isConnected ?
            GDAX.authenticate.getAccounts { (accounts, error) in
                guard let accounts = accounts, error == nil else { return }
                self.isConnected = true

                for account in accounts {
                    self.accounts.updateValue(account, forKey: account.currency!)
                    GDAX.authenticate.getOrders(status: "done",
                                                product_id: "\(account.currency!)-EUR")
                    { (orders, error) in
                        self.orders.updateValue(orders ?? [], forKey: "\(account.currency!)-EUR")
                    }
                }
                self.accountsEmbbedController.datasource = accounts
                DispatchQueue.main.async {
                    self.accountsEmbbedController.tableview.reloadData()
                    self.updateHeader()
                }
            } : ()
    }

    func updateHeader() {
        let products: [gdax_value] = accounts.map { source in
            return gdax_value(from: gdax_products(rawValue: source.value.currency!)!, to: .EUR)
        }

        accountSubscription = GDAX.feed.subscribeTicker(for: products) { (tick) in
            var currency = "LTC"
            if let index = self.accountsEmbbedController.tableview.indexPathForSelectedRow {
                currency = self.accountsEmbbedController.datasource[index.row].currency!
            }
            if tick.product_id == "\(currency)-EUR" {
                DispatchQueue.main.async {
                    if let stat = self.lastStats[tick.product_id!] {
                        if tick.floatPrice! > Float(stat.high!)! {
                            stat.high = tick.price
                        }
                        if tick.floatPrice! < Float(stat.low!)! {
                            stat.low = tick.price
                        }
                        let dailyVar = ((tick.floatPrice! - Float(stat.open!)!) / Float(stat.open!)!) * 100

                        self.statsLabel.text = "\topen : \(String(format: "%0.2f", Float(stat.open!)!))\thigh : \(String(format: "%0.2f", Float(stat.high!)!))\tlow : \(String(format: "%0.2f", Float(stat.low!)!))\tVar : \(String(format: "%0.2f%", dailyVar))\t"
                    }
                    let p = tick.floatPrice! * Float(self.accounts[currency]!.balance!)!
                    self.gain = "\(String(format:"%0.2f", Float(p))) €"
                    self.gainLabel.text = "\((self.capitalGain[tick.product_id!] ?? -p) + p) €"
                    self.balanceLabel.text = "for \(String(format:"%0.6f", Float(self.accounts[currency]!.hold!)!)) \(currency)"
                }
            }
        }
    }
}

extension AccountViewController: AccountEmbedViewControllerProtocol {
    func selectAccount(account: Account) {
        let currency = account.currency!
        if currency != "EUR" {
            let productId = "\(currency)-EUR"
            GDAX.market.product(productId: productId).get24hStats { (stat, error) in
                DispatchQueue.main.async {
                    self.lastStats[productId] = stat
                    self.statsLabel.text = "\topen : \(String(format: "%0.2f", Float(stat!.open!)!))\thigh : \(String(format: "%0.2f", Float(stat!.high!)!))\tlow : \(String(format: "%0.2f", Float(stat!.low!)!))"
                }
            }
            GDAX.market.product(productId: productId).getLastTick { (tick, error) in
                DispatchQueue.main.async {
                    if tick?.price != nil {
                        let p = Float(tick!.price!)! * Float(account.balance!)!
                        self.gain = "\(String(format:"%0.2f", Float(p))) €"
                        self.gainLabel.text = "\((self.capitalGain[productId] ?? -p) + p) €"
                        self.balanceLabel.text = "for \(String(format:"%0.6f", Float(account.hold!)!)) \(currency)"
                    }
                }
            }
        }
    }
}

