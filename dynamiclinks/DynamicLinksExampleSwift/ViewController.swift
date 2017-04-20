//
//  Copyright (c) 2015 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import Firebase

//
// MARK: - Section Data Structure
//
struct Section {
  var name: ParamTypes
  var items: [Params]
  var collapsed: Bool

  init(name: ParamTypes, items: [Params], collapsed: Bool = true) {
    self.name = name
    self.items = items
    self.collapsed = collapsed
  }
}

enum Params: String {
  case link = "Link Value"
  case domain = "App Domain"
  case source = "Source"
  case medium = "Medium"
  case campaign = "Campaign"
  case term = "Term"
  case content = "Content"
  case bundleID = "App Bundle ID"
  case fallbackURL = "Fallback URL"
  case minimumAppVersion = "Minimum App Version"
  case customScheme = "Custom Scheme"
  case iPadBundleID = "iPad Bundle ID"
  case iPadFallbackURL = "iPad Fallback URL"
  case appStoreID = "AppStore ID"
  case affiliateToken = "Affiliate Token"
  case campaignToken = "Campaign Token"
  case providerToken = "Provider Token"
  case packageName = "Package Name"
  case androidFallbackURL = "Android Fallback URL"
  case minimumVersion = "Minimum Version"
  case title = "Title"
  case descriptionText = "Description Text"
  case imageURL = "Image URL"
}

enum ParamTypes: String {
  case googleAnalytics = "Google Analytics"
  case iOS = "iOS"
  case iTunes = "iTunes Connect Analytics"
  case android = "Android"
  case social = "Social Meta Tag"
}

//
// MARK: - View Controller
//
@objc(ViewController)
class ViewController: UITableViewController {

  var sections = [Section]()
  var dictionary = [Params: UITextField]()
  var longLink: URL?
  var shortLink: URL?

  override func viewDidLoad() {
    super.viewDidLoad()

    // Initialize the sections array
    sections = [
      Section(name: .googleAnalytics, items: [.source, .medium, .campaign, .term, .content]),
      Section(name: .iOS, items: [.bundleID, .fallbackURL, .minimumAppVersion, .customScheme,
                                  .iPadBundleID, .iPadFallbackURL, .appStoreID]),
      Section(name: .iTunes, items: [.affiliateToken, .campaignToken, .providerToken]),
      Section(name: .android, items: [.packageName, .androidFallbackURL, .minimumVersion]),
      Section(name: .social, items: [.title, .descriptionText, .imageURL])
    ]
  }

  func buildFDLLink() {
    // [START buildFDLLink]
    guard let linkString = dictionary[.link]?.text else { return }
    guard let link = URL(string: linkString) else { return }
    guard let domain = dictionary[.domain]?.text else { return }
    let components = FIRDynamicLinkComponents(link: link, domain: domain)

    let analyticsParams = FIRDynamicLinkGoogleAnalyticsParameters(
        source: dictionary[.source]?.text ?? "", medium: dictionary[.medium]?.text ?? "",
        campaign: dictionary[.campaign]?.text ?? "")
    analyticsParams.term = dictionary[.term]?.text
    analyticsParams.content = dictionary[.content]?.text

    components.analyticsParameters = analyticsParams

    if let bundleID = dictionary[.bundleID]?.text {
      let iOSParams = FIRDynamicLinkIOSParameters(bundleID: bundleID)
      if let fallbackURL = dictionary[.fallbackURL]?.text {
        iOSParams.fallbackURL = URL(string: fallbackURL)
      }
      iOSParams.minimumAppVersion = dictionary[.minimumAppVersion]?.text
      iOSParams.customScheme = dictionary[.customScheme]?.text
      iOSParams.iPadBundleID = dictionary[.iPadBundleID]?.text
      if let iPadFallbackURL = dictionary[.iPadFallbackURL]?.text {
        iOSParams.iPadFallbackURL = URL(string: iPadFallbackURL)
      }
      iOSParams.appStoreID = dictionary[.appStoreID]?.text

      components.iOSParameters = iOSParams
    }

    let appStoreParams = FIRDynamicLinkItunesConnectAnalyticsParameters()
    appStoreParams.affiliateToken = dictionary[.affiliateToken]?.text
    appStoreParams.campaignToken = dictionary[.campaignToken]?.text
    appStoreParams.providerToken = dictionary[.providerToken]?.text

    components.iTunesConnectParameters = appStoreParams

    if let packageName = dictionary[.packageName]?.text {
      let androidParams = FIRDynamicLinkAndroidParameters(packageName: packageName)
      if let androidFallbackURL = dictionary[.androidFallbackURL]?.text {
        androidParams.fallbackURL = URL(string: androidFallbackURL)
      }
      if let minimumVersion = dictionary[.minimumVersion]?.text, let intVersion = Int(minimumVersion), intVersion > 0 {
        androidParams.minimumVersion = intVersion
      }

      components.androidParameters = androidParams
    }

    let socialParams = FIRDynamicLinkSocialMetaTagParameters()
    socialParams.title = dictionary[.title]?.text
    socialParams.descriptionText = dictionary[.descriptionText]?.text
    if let imageURL = dictionary[.imageURL]?.text {
      socialParams.imageURL = URL(string: imageURL)
    }

    components.socialMetaTagParameters = socialParams

    longLink = components.url
    print(longLink?.absoluteString ?? "")
    // [END buildFDLLink]

    // Handle longURL.
    tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)

    // [START shortLinkOptions]
    let options = FIRDynamicLinkComponentsOptions()
    options.pathLength = .unguessable
    components.options = options
    // [END shortLinkOptions]

    // [START shortenLink]
    components.shorten { (shortURL, warnings, error) in
      // Handle shortURL.
      if let error = error {
        print(error.localizedDescription)
        return
      }
      self.shortLink = shortURL
      print(self.shortLink?.absoluteString ?? "")
      // [START_EXCLUDE]
      self.tableView.reloadRows(at: [IndexPath(row: 1, section: 2)], with: .none)
      // [END_EXCLUDE]
    }
    // [END shortenLink]
  }
}

//
// MARK: - View Controller DataSource and Delegate
//
extension ViewController : UIGestureRecognizerDelegate {

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 3
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case 0: return "Components"
    case 1: return "Optional Parameters"
    case 2: return "Click to Generate Links"
    default: return ""
    }
  }

  override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    if section == 2 {
      view.subviews[0].backgroundColor = .yellow
      let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(buildFDLLink))
      tapRecognizer.delegate = self
      tapRecognizer.numberOfTapsRequired = 1
      tapRecognizer.numberOfTouchesRequired = 1
      view.addGestureRecognizer(tapRecognizer)
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 1 {
      // For section 1, the total count is items count plus the number of headers
      var count = sections.count
      for section in sections {
        count += section.items.count
      }
      return count
    }
    return 2
  }

  // Cell
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch indexPath.section {
    case 0:
      let cell = tableView.dequeueReusableCell(withIdentifier: "param", for: indexPath) as! ParamTableViewCell
      if indexPath.row == 0 {
        cell.paramLabel.text = Params.link.rawValue
        cell.paramTextField.text = "https://www.google.com?q=jump"
      } else {
        cell.paramLabel.text = Params.domain.rawValue
        cell.paramTextField.text = "test3p.app.goo.gl"
      }
      dictionary[Params(rawValue: cell.paramLabel.text!)!] = cell.paramTextField
      return cell
    case 2:
      let cell = tableView.dequeueReusableCell(withIdentifier: "generate", for: indexPath)
      if indexPath.row == 0 {
        cell.textLabel?.text = "Long Link"
        cell.detailTextLabel?.text = longLink?.absoluteString
      } else {
        cell.textLabel?.text = "Short Link"
        cell.detailTextLabel?.text = shortLink?.absoluteString
      }
      return cell
    default:
      // Calculate the real section index and row index
      let section = getSectionIndex(indexPath.row)
      let row = getRowIndex(indexPath.row)

      if row == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! HeaderCell
        cell.titleLabel.text = sections[section].name.rawValue
        cell.toggleButton.tag = section
        cell.toggleButton.setTitle(sections[section].collapsed ? "+" : "-", for: .normal)
        cell.toggleButton.addTarget(self, action: #selector(ViewController.toggleCollapse), for: .touchUpInside)
        return cell
      } else {
        let cell = tableView.dequeueReusableCell(withIdentifier: "param", for: indexPath) as! ParamTableViewCell
        cell.paramLabel.text = sections[section].items[row - 1].rawValue
        if cell.paramLabel.text! == Params.bundleID.rawValue {
          cell.paramTextField.text = Bundle.main.bundleIdentifier
        } else if cell.paramLabel.text! == Params.minimumAppVersion.rawValue {
          cell.paramTextField.text = "1.0"
        }

        dictionary[Params(rawValue: cell.paramLabel.text!)!] = cell.paramTextField
        return cell
      }
    }
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    switch indexPath.section {
    case 0: return 80.0
    case 2: return 44.0
    default:
      if getRowIndex(indexPath.row) == 0 {
        // Header has fixed height
        return 44.0
      } else {
        // Calculate the real section index
        let section = getSectionIndex(indexPath.row)
        return sections[section].collapsed ? 0 : 80.0
      }
    }
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 2 {
      if indexPath.row == 0 {
        // copy long link
        if let longLink = longLink {
          UIPasteboard.general.string = longLink.absoluteString
          print("Long Link copied to Clipboard")
        } else {
          print("Long Link is empty")
        }
      } else {
        // copy short link
        if let shortLink = shortLink {
          UIPasteboard.general.string = shortLink.absoluteString
          print("Short Link copied to Clipboard")
        } else {
          print("Short Link is empty")
        }
      }
    }
  }

  //
  // MARK: - Event Handlers
  //
  func toggleCollapse(sender: UIButton) {
    let section = sender.tag
    let collapsed = sections[section].collapsed

    // Toggle collapse
    sections[section].collapsed = !collapsed

    let indices = getHeaderIndices()

    let start = indices[section]
    let end = start + sections[section].items.count

    tableView.beginUpdates()
    for i in start ... end {
      tableView.reloadRows(at: [IndexPath(row: i, section: 1)], with: .automatic)
    }
    tableView.endUpdates()
  }

  //
  // MARK: - Helper Functions
  //
  func getSectionIndex(_ row: NSInteger) -> Int {
    let indices = getHeaderIndices()

    for i in 0..<indices.count {
      if i == indices.count - 1 || row < indices[i + 1] {
        return i
      }
    }

    return -1
  }

  func getRowIndex(_ row: NSInteger) -> Int {
    var index = row
    let indices = getHeaderIndices()

    for i in 0..<indices.count {
      if i == indices.count - 1 || row < indices[i + 1] {
        index -= indices[i]
        break
      }
    }

    return index
  }

  func getHeaderIndices() -> [Int] {
    var index = 0
    var indices: [Int] = []

    for section in sections {
      indices.append(index)
      index += section.items.count + 1
    }

    return indices
  }

}
