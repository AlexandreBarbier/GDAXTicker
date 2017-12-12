//
//  AccountEmbedViewController.swift
//  GDAXTicker
//
//  Created by Alexandre Barbier on 11/12/2017.
//  Copyright © 2017 Thomas Ricouard. All rights reserved.
//

import UIKit
import GDAX_Swift

class AccountTableVIewCell: UITableViewCell {

    @IBOutlet var accountNameLabel: UILabel!
    @IBOutlet var currentPriceLabel: UILabel!

    var sub:Subscription?
    var account: Account! {
        didSet {
            accountNameLabel.text = account.currency
            sub?.unsubscribe()
            let product = [gdax_value(from: gdax_products(rawValue: account.currency!)!, to: .EUR)]

            sub = GDAX.feed.subscribeTicker(for: product) { (tick) in
                DispatchQueue.main.async {
                    self.currentPriceLabel.text = "\(String(format: "%0.2f", Float(tick.price!)!))"
                    UIView.animate(withDuration: 0.1, animations: {
                        self.backgroundColor = tick.side == "buy" ? UIColor.green.withAlphaComponent(0.5) : UIColor.red.withAlphaComponent(0.5)
                    }, completion: { (finish) in
                        finish ? UIView.animate(withDuration: 0.1, animations: { self.backgroundColor = .white }) : ()
                    })
                }
            }
        }
    }
}

public protocol AccountEmbedViewControllerProtocol {
    func selectAccount(account: Account) -> Void
}

class AccountEmbedViewController: UIViewController {
    @IBOutlet var tableview: UITableView!

    var lastStats: [String:StatResponse] = [:]
    var delegate:AccountEmbedViewControllerProtocol?

    var datasource:[Account] = []
    var selectedIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "OrderSegue" {
            let vc = segue.destination as? OrderViewController
            vc?.account = self.datasource[selectedIndex]
            vc?.euroAccount = self.datasource.filter({ $0.currency == "EUR" }).first?.id
        }
    }
}

extension AccountEmbedViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "AccountCellIdentifier") as? AccountTableVIewCell
        cell?.account = datasource[indexPath.row]
        return cell!
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        selectedIndex = indexPath.row
        return indexPath
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        self.delegate?.selectAccount(account: self.datasource[indexPath.row])
    }
}
