## 2.2.0

**Breaking Changes**
* Controller initialization added `blockedDomains` parameter in `FilterConfig` instead of separate list
* Minimum Supported flutter version is 3.38.0
* Minimum Supported dart version is 3.10.1

### New Features
* **Whitelist/Allowlist Support**: Disable ad blocking for specific trusted domains
  * Configure via `FilterConfig.allowedDomains`
  * Runtime control with `addAllowedDomain()`, `removeAllowedDomain()`, `isAllowedDomain()`
  * Subdomain matching (e.g., `example.com` allows `sub.example.com`)

* **Blocking Statistics**: Track blocked resources and CSS rules
  * `statistics.blockedResourceCount` - total blocked resources
  * `statistics.cssRulesAppliedCount` - CSS rules applied
  * `statistics.blockedDomains` - per-domain breakdown
  * `resetStatistics()` to clear counters

### Performance Improvements

### Developer Experience
* Enhanced example app with:
  * Shield icon badge showing blocked count
  * Statistics bottom sheet with detailed breakdown
  * Top blocked domains list


## 2.1.0
* Added `stoploading` method to AdblockerWebviewController
* Disable automatic media playback

## 2.0.0-beta
* Added support for easylist and adguard filters
* Added support for resource rules parsing
* Removed third party package dependency and using official webview_flutter package

**Breaking Changes**
* Minimum Supported flutter version is 3.27.1
* Minimum Supported dart version is 3.7.0

## 1.1.2
* Removed redundant isolate uses
* Removed flutter version constraint in pubspec.yaml

## 1.1.1
* Added ability to pass additional urls to block

## 1.1.0
**Breaking Changes**
* Minimum Supported flutter version is 3.19.5
* Minimum Supported dart version is 3.0.0

**Other**
* Added more capabilities to AdblockerWebviewController
  * `getTitle`, `clearCache` and `loadUrl` methods added
  * Added caching for the blocked host list


## 1.0.2
* Added support for page reload
* Fixed some analysis issues

## 1.0.1
* Added support for webview backward and forward navigation
* Reduced third party package dependency
* Updated inAppWebview version to `^5.8.0`

## 1.0.0
** Breaking Changes**
* Removed Widget suffix from `AdBlockerWebview`

** Other **
* Fixed broken links in readme
## 0.1.4
* Updated Readme
## 0.1.3
* Replaced `webview_flutter` package with `flutter_InAppWebview`

## 0.1.2
* Fixed Unit tests
* Removed dependency from injectable library

## 0.1.1
* Fixed broken documentation links in readme

## 0.1.0
* Fixed broken documentation links in readme

* Initial release.
