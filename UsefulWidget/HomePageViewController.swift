//
//  HomePageViewController.swift
//  UsefulWidget
//
//  Created by chenxu on 2021/5/21.
//

import UIKit

class HomePageViewController: UITableViewController {
    
    var dataSource = [String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource.append("show loading")
        dataSource.append("menu")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath as IndexPath)
        cell.textLabel?.numberOfLines = 0
        let title = self.dataSource[indexPath.row]
        cell.textLabel?.text = title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch dataSource[indexPath.row] {
        case "show loading":
            break
        case "menu":
           let menu = MenuViewController()
            self.navigationController?.pushViewController(menu, animated: true)
        default:
            break
        }
    }

}
