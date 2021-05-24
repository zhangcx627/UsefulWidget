//
//  DragDotTableViewController.swift
//  UsefulWidget
//
//  Created by chenxu on 2021/5/24.
//

import UIKit

class DragDotTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(DragDotTableViewCell.self, forCellReuseIdentifier: "DragDotTableViewCell")

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "DragDotTableViewCell", for: indexPath) as? DragDotTableViewCell {
            return cell
        } else {
            let cell = DragDotTableViewCell(style: .default, reuseIdentifier: "DragDotTableViewCell")
            return cell
        }
    }
}
