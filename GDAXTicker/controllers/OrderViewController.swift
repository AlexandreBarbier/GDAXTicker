//
//  OrderViewController.swift
//  GDAXTicker
//
//  Created by Alexandre Barbier on 12/12/2017.
//  Copyright © 2017 Thomas Ricouard. All rights reserved.
//

import UIKit
import GDAX_Swift

class OrderTableViewCell: UITableViewCell {
    @IBOutlet var sideLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
}

class OrderViewController: UIViewController {

    @IBOutlet var tableView: UITableView!

    var account: Account!
    var euroAccount: String?
    var datasource: [String:[OrderResponse]] = [:]
    let sections = ["open", "pending", "done"]

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //open, pending, active, done
        GDAX.authenticate.getOrders(status: "all", product_id: "\(String(describing: account.currency!))-EUR") { (orders, error) in
            self.datasource.updateValue(orders!.filter({ $0.status! == "open" }), forKey: "open")
            self.datasource.updateValue(orders!.filter({ $0.status! == "pending" }), forKey: "pending")
            self.datasource.updateValue(orders!.filter({ $0.status! == "done" }), forKey: "done")
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "BuySellSegue" {
            let destVC = segue.destination as? BuySellViewController
            destVC?.account = account
            destVC?.euroAccountId = euroAccount
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension OrderViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      return sections[section]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let s = sections[section]
        return datasource[s]!.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OrderCell") as! OrderTableViewCell
        let sect = sections[indexPath.section]
        let order = datasource[sect]![indexPath.row]
        cell.sideLabel.text = "\(String(format:"%0.2f", Float(order.size!)!)) for \(String(format:"%0.2f", Float(order.price!)!)) €"
        cell.priceLabel.text = order.side
        return cell
    }
}
