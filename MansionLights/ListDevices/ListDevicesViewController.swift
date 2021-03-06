//
//  ListDevicesViewController.swift
//  MansionLights
//
//  Created by Fábio Nogueira de Almeida on 21/10/17.
//  Copyright © 2017 Fábio Nogueira de Almeida. All rights reserved.
//

import UIKit
import CoreBluetooth

// MARK: Protocols

protocol ListDeviceTableViewDataSourceProtocol {
    func verifyNumberOfSections() -> Int
}

protocol ListDeviceTableViewDelegateProtocol {
    func didSelectedRow(at indexPath: IndexPath)
}

protocol ListDeviceTableViewLayoutProtocol {
    func tableViewLayout()
    func applyLayout(on cell: UITableViewCell)
    func presentEmptyMessage(message: String, on tableView: UITableView)
}

protocol ListDeviceLayoutProtocol {
    func viewLayout()
}

protocol ListDeviceCoordinatorProtocol {
    func presentDeviceViewController(peripherical: CBPeripheral)
}

protocol ListDevicesActionsProtocol {
    func refreshButtonTouched()
}

final class ListDevicesViewController: UIViewController {
    
     enum State {
        case search
        case searched(NSArray)
        case connecting(String)
        case error
    }
    
    // MARK: - IBOutlets

    @IBOutlet weak var tableView: UITableView!

    // MARK: - Properties

    let bluetoothManager = BluetoothManager()
    var model: NSArray?

    // MARK: - Properties Lazy

    private lazy var refreshBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .refresh,
                               target: self,
                               action: #selector(self.refreshButtonTouched))
    }

    private lazy var refreshIndicatorView = { () -> UIActivityIndicatorView in
        let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
        indicatorView.startAnimating()
        return indicatorView
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        addProtocols()
        tableViewLayout()
        viewLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        bluetoothManager.desconnect()
        changeState(for: .search)
    }

    // MARK: - Private
    
    private func addProtocols() {
        bluetoothManager.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func addRefreshBarButtonItem() {
        navigationItem.setRightBarButton(refreshBarButtonItem(),
                                              animated: true)
    }
    
    // MARK: Public
    
    func changeState(for state: State) {
        switch state {
        case .search:
            bluetoothManager.startSearchDevices()
            navigationItem.rightBarButtonItem?.customView = refreshIndicatorView()
            tableView.isHidden = true
            
        case .searched(let devicesNames):
            model = devicesNames
            addRefreshBarButtonItem()
            tableView.reloadData()
            tableView.isHidden = false
            
        case .connecting(let peripheralName):
            let peripherical = bluetoothManager.connect(peripheralName)
            presentDeviceViewController(peripherical: peripherical)
            
        case .error:
            presentEmptyMessage(message: .errorMessage,
                                on: tableView)
        }
    }
}

// MARK: ListDeviceLayoutProtocol

extension ListDevicesViewController: ListDeviceLayoutProtocol {
    internal func viewLayout() {
        title = .title
        view.backgroundColor = UIColor(named: .dark)
        addRefreshBarButtonItem()
    }
}

// MARK: ListDeviceNavigatorProtocol

extension ListDevicesViewController: ListDeviceCoordinatorProtocol {
    internal func presentDeviceViewController(peripherical: CBPeripheral) {
        let viewController = DeviceViewController()
        viewController.setup(peripherical: peripherical)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: ListDevicesActionsProtocol

extension ListDevicesViewController: ListDevicesActionsProtocol {
    @objc internal func refreshButtonTouched() {
        changeState(for: .search)
    }
}

// MARK: Strings Extesions

fileprivate extension String {
    static let title = "Lampadas 💡"
    static let errorMessage = "deu bug\ne a culpa é do desenvolvedor \n\n 😭"
}
