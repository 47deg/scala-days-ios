/*
* Copyright (C) 2015 47 Degrees, LLC http://47deg.com hello@47deg.com
*
* Licensed under the Apache License, Version 2.0 (the "License"); you may
* not use this file except in compliance with the License. You may obtain
* a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/


import UIKit

class SDSlideMenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SDSliderMenuBar {
    
    @IBOutlet weak var tblMenu: UITableView!
    @IBOutlet weak var titleConference: UILabel!
    @IBOutlet weak var heigthTable: NSLayoutConstraint!
    @IBOutlet weak var heightConferenceTable: NSLayoutConstraint!
    @IBOutlet weak var heigthHeader: NSLayoutConstraint!
    @IBOutlet weak var imgHeader: UIImageView!
    @IBOutlet weak var tblConferences: UITableView!
    
    let kConferenceReuseIdentifier = "ConferencesListCell"
    var controllers : [UIViewController]!
    private let notificationManager = NotificationManager()
    
    enum Menu: Int {
        case schedule = 0
        case notification
        case social
        case contact
        case tickets
        case sponsors
        case places
        case speakers
        case about
    }
    
    var menus = [NSLocalizedString("schedule", comment: "Schedule"),
                 SDNotificationViewController.i18n.title,
                 NSLocalizedString("social", comment: "Social"),
                 NSLocalizedString("contacts", comment: "Contacts"),
                 NSLocalizedString("tickets", comment: "Tickets"),
                 NSLocalizedString("sponsors", comment: "Sponsors"),
                 NSLocalizedString("places", comment: "Places"),
                 NSLocalizedString("speakers", comment: "Speakers"),
                 NSLocalizedString("about", comment: "About")]
    
    var menusImage = [icon_menu_schedule,
                      SDNotificationViewController.Image.iconNamed,
                      icon_menu_social,
                      icon_menu_contact,
                      icon_menu_ticket,
                      icon_menu_sponsors,
                      icon_menu_places,
                      icon_menu_speakers,
                      icon_menu_about]
    
    var scheduleViewController: UINavigationController!
    var notificationNavigationController: UINavigationController!
    var socialViewController: UIViewController!
    var contactViewController: UIViewController!
    var sponsorsViewController: UIViewController!
    var placesViewController: UIViewController!
    var aboutViewController: UIViewController!
    var speakersViewController: UIViewController!
    
    var infoSelected: Information?
    var currentConferences: Conferences?
    private var pendingNotification: Conference?
    private let analytics: Analytics
    
    init(analytics: Analytics) {
        self.analytics = analytics
        super.init(nibName: String(describing: SDSlideMenuViewController.self), bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (IS_IPHONE5) {
            heigthHeader.constant = Height_Header_Menu
        }
        
        // Conferences aparence table
        self.tblConferences.isScrollEnabled = false
        self.tblConferences.separatorColor = UIColor(white: 1, alpha: 0.1)
        self.tblConferences.register(UINib(nibName: "SDConferenceTableViewCell", bundle: nil), forCellReuseIdentifier: kConferenceReuseIdentifier)
        self.tblConferences.alpha = 0
        
        // Init aparence table
        self.heigthTable.constant = CGFloat(menus.count * Int(Height_Row_Menu))
        self.tblMenu.isScrollEnabled = IS_IPHONE5
        self.tblMenu.separatorColor = UIColor(white: 1, alpha: 0.1)
        
        self.tblMenu.scrollsToTop = false
        self.tblConferences.scrollsToTop = false
        
        self.titleConference.setCustomFont(UIFont.fontHelveticaNeue(15), colorFont: UIColor.white)
        
        let notificationViewController = SDNotificationViewController(analytics: analytics, notificationManager: notificationManager)
        self.notificationNavigationController = UINavigationController(rootViewController: notificationViewController)
        
        let socialViewController = SDSocialViewController(analytics: analytics)
        self.socialViewController = UINavigationController(rootViewController: socialViewController)
        
        let contactViewController = SDContactViewController(analytics: analytics)
        self.contactViewController = UINavigationController(rootViewController: contactViewController)
        
        let sponsorsViewController = SDSponsorViewController(analytics: analytics)
        self.sponsorsViewController = UINavigationController(rootViewController: sponsorsViewController)
        
        let placesViewController = SDPlacesViewController(analytics: analytics)
        self.placesViewController = UINavigationController(rootViewController: placesViewController)
        
        let aboutViewController = SDAboutViewController(analytics: analytics)
        self.aboutViewController = UINavigationController(rootViewController: aboutViewController)
        
        let speakersViewController = SDSpeakersListViewController(analytics: analytics)
        self.speakersViewController = UINavigationController(rootViewController: speakersViewController)
        
        controllers = [scheduleViewController.visibleViewController!, notificationViewController, socialViewController, contactViewController, sponsorsViewController, placesViewController, aboutViewController, speakersViewController]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        componeConferenceTable()
        drawSelectedConference()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showPendingNotifications()
        analytics.logScreenName(.slideMenu, class: SDSlideMenuViewController.self)
    }
    
    func componeConferenceTable(){
        if let conferences = DataManager.sharedInstance.conferences {
            self.currentConferences = conferences
            self.tblConferences.reloadData()
        }
    }
    
    func drawSelectedConference() {
        guard let info = DataManager.sharedInstance.currentlySelectedConference?.info else { return }
        self.infoSelected = info
        self.titleConference.text = info.longName
        
        if let image = info.pictures[safe: 2],
           let infoImageUrl = URL(string: image.url) {
            self.imgHeader.sd_setImage(with: infoImageUrl, placeholderImage: UIImage(named: "placeholder_menu"))
        }
    }
    
    // MARK: -  Router
    func showNotifications(conferenceId: String = "") {
        guard isViewLoaded else {
            pendingNotification = getConference(id: conferenceId); return
        }
        guard let notificationViewController = notificationNavigationController?.topViewController as? SDNotificationViewController else { return }
        
        selectConference(id: conferenceId)
        slideMenuController()?.changeMainViewController(notificationNavigationController, close: true)
        notificationViewController.receivedNotifications()
    }
    
    func showPendingNotifications() {
        guard let conference = self.pendingNotification else { return }
        self.pendingNotification = nil
        showNotifications(conferenceId: "\(conference.info.id)")
    }
    
    func getConference(id conferenceId: String) -> Conference? {
        guard let conferences = DataManager.sharedInstance.conferences?.conferences,
              let conference = conferences.first(where: {"\($0.info.id)" == conferenceId}) else { return nil }
        
        return conference
    }
    
    func selectConference(id conferenceId: String) {
        guard let conferences = DataManager.sharedInstance.conferences?.conferences,
            let (index, _) = conferences.enumerated().first(where: {"\($1.info.id)" == conferenceId}) else { return }
        
        selectConference(at: index)
    }
    
    func selectConference(at index: Int) {
        guard let conferences = DataManager.sharedInstance.conferences?.conferences,
              index >= 0, index < conferences.count else { return }
        
        DataManager.sharedInstance.selectConference(at: index)
        drawSelectedConference()
        showTblConferenceDetails()
        askControllersToReload()
        slideMenuController()?.closeLeft()

        if let selectedConference = DataManager.sharedInstance.conferences?.conferences[index] {
            analytics.logEvent(screenName: .slideMenu, category: .navigate, action: .menuChangeConference, label: selectedConference.info.name)
        }
    }
    
    // MARK: - UITableViewDataSource implementation
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (tableView, self.currentConferences) {
        case (self.tblConferences, .some(let x)):
            if IS_IPHONE5 {
                self.heightConferenceTable.constant = CGFloat(screenBounds.height - Height_Header_Menu)
                return x.conferences.count
            } else {
                self.heightConferenceTable.constant = CGFloat(x.conferences.count * Int(Height_Row_Menu))
                return x.conferences.count
            }
        case (self.tblConferences, .none): return 0
        default:
            if IS_IPHONE5 {
                self.heigthTable.constant = CGFloat(screenBounds.height - Height_Header_Menu)
            } else {
                self.heigthTable.constant = CGFloat(menus.count * Int(Height_Row_Menu))
            }
            return menus.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (tableView, self.currentConferences) {
        case (self.tblConferences, .some(_)):
            let cell : SDConferenceTableViewCell? = tableView.dequeueReusableCell(withIdentifier: kConferenceReuseIdentifier) as? SDConferenceTableViewCell
            
            switch cell {
            case let(.some(cell)): return configureConferenceCell(cell, indexPath: indexPath)
            default:
                let cell = SDConferenceTableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: kConferenceReuseIdentifier)
                return configureConferenceCell(cell, indexPath: indexPath)
            }
        default :
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "CellMenu")
            cell.textLabel?.setCustomFont(UIFont.fontHelveticaNeue(15), colorFont: UIColor(white: 1, alpha: 0.9))
            cell.backgroundColor = UIColor.appColor()
            let bgColorView = UIView()
            bgColorView.backgroundColor = UIColor.selectedCellMenu()
            cell.selectedBackgroundView = bgColorView
            cell.textLabel?.text = menus[indexPath.row]
            cell.imageView?.image = UIImage(named: menusImage[indexPath.row] as String)
            cell.imageView?.contentMode = .scaleAspectFit
            cell.layoutIfNeeded()
            return cell
        }
        
    }
    
    func configureConferenceCell(_ cell: SDConferenceTableViewCell, indexPath: IndexPath) -> SDConferenceTableViewCell {
        if let listOfConferences = self.currentConferences {
            if(listOfConferences.conferences.count > indexPath.row) {
                let conferenceCell = cell as SDConferenceTableViewCell
                conferenceCell.drawConferenceData(listOfConferences.conferences[indexPath.row])
                conferenceCell.layoutSubviews()
            }
        }
        cell.frame = CGRect(x: 0, y: 0, width: tblConferences.bounds.size.width, height: cell.frame.size.height);
        cell.layoutIfNeeded()
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Height_Row_Menu
    }
    
    // MARK: - UITableViewDelegate implementation
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (tableView, Menu(rawValue: indexPath.item)) {
        case (self.tblConferences, _) : self.selectConference(at: indexPath.row)
        case (self.tblMenu, .some(.schedule)): self.slideMenuController()?.changeMainViewController(self.scheduleViewController, close: true)
        case (self.tblMenu, .some(.notification)): self.showNotifications()
        case (self.tblMenu, .some(.social)): self.slideMenuController()?.changeMainViewController(self.socialViewController, close: true)
        case (self.tblMenu, .some(.contact)): self.slideMenuController()?.changeMainViewController(self.contactViewController, close: true)
        case (self.tblMenu, .some(.sponsors)): self.slideMenuController()?.changeMainViewController(self.sponsorsViewController, close: true)
        case (self.tblMenu, .some(.places)): self.slideMenuController()?.changeMainViewController(self.placesViewController, close: true)
        case (self.tblMenu, .some(.about)): self.slideMenuController()?.changeMainViewController(self.aboutViewController, close: true)
        case (self.tblMenu, .some(.speakers)): self.slideMenuController()?.changeMainViewController(self.speakersViewController, close: true)
        case (self.tblMenu, .some(.tickets)):
            if let registration = self.infoSelected?.registrationSite, let url = URL(string: registration) {
                analytics.logEvent(screenName: .slideMenu, category: .navigate, action: .goToTicket)
                launchSafariToUrl(url)
            }
        default: break
        }
    }
    
    @IBAction func selectedConference(_ sender: AnyObject) {
        toggleTblConference()
    }
    
    func toggleTblConference() {
        tblMenu.alpha > 0 ? hideTblConferenceDetails() : showTblConferenceDetails()
    }
    
    func showTblConferenceDetails() {
        guard tblConferences.alpha > 0 else { return }
        
        UIView.animate(withDuration: 0.5) {
            self.tblConferences.alpha = 0.0
            self.tblMenu.alpha = 1.0
        }
    }
    
    func hideTblConferenceDetails() {
        guard tblConferences.alpha == 0 else { return }
        
        UIView.animate(withDuration: 0.5) {
            self.tblConferences.alpha = 1.0
            self.tblMenu.alpha = 0.0
        }
    }
    
    // MARK: - Notify controllers of conference swapping
    
    func currentVisibleController() -> SDMenuControllerItem? {
        if let mainNavController = self.slideMenuController()?.mainViewController as? UINavigationController {
            if let currentController = mainNavController.visibleViewController as? SDMenuControllerItem {
                return currentController
            }
        }
        return nil
    }
    
    func askControllersToReload() {
        guard isViewLoaded else { return }
        
        // We need to notify our main controllers that their data need to be updated, also our visible controller needs to reload ASAP:
        for controller in controllers {
            if controller is SDMenuControllerItem {
                let controllerItem = controller as! SDMenuControllerItem
                controllerItem.isDataLoaded = false
            }
        }
        
        if let currentController = currentVisibleController() {
            currentController.loadData()
        }
        
        // Reload scaladay viewcontrollers
        if let conference = DataManager.sharedInstance.currentlySelectedConference {
            DispatchQueue.main.async {
                self.controllers.compactMap { $0 as? ScalaDayViewController }.forEach { $0.updateConference(conference) }
            }
        }
    }
    
    // MARK: - SDSliderMenuBar protocol implementation
    func didCloseMenu() {
        showTblConferenceDetails()
    }
}
