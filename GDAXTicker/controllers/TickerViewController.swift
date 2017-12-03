//
//  TickerViewController.swift
//  GDAXTicker
//
//  Created by Thomas Ricouard on 02/12/2017.
//  Copyright © 2017 Thomas Ricouard. All rights reserved.
//

import UIKit
import UI

class TickerViewController: UIViewController {
    let networkSocket = NetworkSocket()
    var datasource: [Tick] = []

    @IBOutlet var tableView: UITableView!
    @IBOutlet var statusBadge: StatusBadge!

    var currentCurrency = "LTC-EUR" {
        didSet {
            networkSocket.onDisconnect = {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self.reconnect()
                })
            }
            networkSocket.stop()
        }
    }

    let currencies = ["LTC-USD", "LTC-EUR", "BTC-USD", "BTC-EUR"]

    override func viewDidLoad() {
        super.viewDidLoad()

        UIApplication.shared.statusBarStyle = .lightContent
        title = currentCurrency

        statusBadge.backgroundColor = .gd_redColor
        statusBadge.title = "Loading..."

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onStatusView))
        statusBadge.isUserInteractionEnabled = true
        statusBadge.addGestureRecognizer(tapGesture)

        let nib = UINib(nibName: TickTableViewCell.id, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: TickTableViewCell.id)

        reconnect()
    }

    func reconnect() {
        datasource = []
        tableView.reloadData()

        networkSocket.onTick = {tick in
            self.refreshTitle(tick: tick)
            self.datasource.insert(tick, at: 0)
            self.tableView.insertRows(at: [IndexPath(item: 0, section: 0)], with: .automatic)
        }

        networkSocket.onConnectionChange = {isConnected in
            if !isConnected {
                self.statusBadge.backgroundColor = .gd_redColor
                self.statusBadge.title = "Disconnected"
            } else {
                self.statusBadge.backgroundColor = .gd_greenColor
                self.statusBadge.title = "Connected"
            }
        }

        networkSocket.start()
        let channel = Channel(name: "ticker", products: [currentCurrency])
        let subscription = Subscribe(channels: [channel])
        networkSocket.subscribe(subscription: subscription)
    }

    func refreshTitle(tick: Tick) {
        if let vault = UserDefaults.standard.vaults,
            let current = vault[self.currentCurrency],
            let floatPrice = tick.floatPrice {
            self.title = """
                        \(self.currentCurrency): \(tick.formattedPrice), HOLD: \(tick.currentPriceFormatter.string(from: NSNumber(value: floatPrice * current))!)
                        """
        } else {
            self.title = "\(self.currentCurrency): \(tick.formattedPrice)"
        }
    }

    @objc func onStatusView() {
        networkSocket.isConnected ? networkSocket.stop() : reconnect()
    }
    
    @IBAction func onCurrencyButton(_ sender: Any) {
        let sheet = UIAlertController(title: "Choose network", message: nil, preferredStyle: .actionSheet)
        for currency in currencies {
            sheet.addAction(UIAlertAction(title: currency, style: .default, handler: { (_) in
                self.currentCurrency = currency
            }))
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(sheet, animated: true, completion: nil)
    }

    @IBAction func onHoldButton(_ sender: Any) {
        let alert = UIAlertController(title: "How much \(currentCurrency) do you hold?", message: nil, preferredStyle: .alert)
        alert.addTextField { (field) in
            field.keyboardType = UIKeyboardType.numberPad
        }
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
            if let value = alert.textFields?.first?.text, let floatValue = Float(value) {
                if var currentVault = UserDefaults.standard.vaults {
                    currentVault[self.currentCurrency] = floatValue
                    UserDefaults.standard.vaults = currentVault
                } else {
                    UserDefaults.standard.vaults = [self.currentCurrency: floatValue]
                }
                self.refreshTitle(tick: self.datasource.first!)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete HOLD", style: .destructive, handler: { (_) in
            if var currentVault = UserDefaults.standard.vaults {
                currentVault[self.currentCurrency] = nil
                UserDefaults.standard.vaults = currentVault
                self.refreshTitle(tick: self.datasource.first!)
            }
        }))
        present(alert, animated: true, completion: nil)
    }
}

extension TickerViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TickTableViewCell.id, for: indexPath) as! TickTableViewCell
        cell.tick = datasource[indexPath.row]
        return cell
    }
}
