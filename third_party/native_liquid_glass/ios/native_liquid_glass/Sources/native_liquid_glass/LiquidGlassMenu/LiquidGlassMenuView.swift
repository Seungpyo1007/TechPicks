import Flutter
import UIKit

/// Platform-view bridge for native UIButton+UIMenu with Liquid Glass effects.
@available(iOS 14.0, *)
final class LiquidGlassMenuPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let button: UIButton
  private let methodChannel: FlutterMethodChannel
  private var suppressObserver: GlassSuppressObserver?

  init(
    frame: CGRect,
    viewId: Int64,
    arguments args: [String: Any]?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = UIView(frame: frame)
    containerView.backgroundColor = .clear

    button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.showsMenuAsPrimaryAction = true

    methodChannel = FlutterMethodChannel(
      name: "liquid-glass-menu-view/\(viewId)",
      binaryMessenger: messenger
    )

    super.init()
    suppressObserver = GlassSuppressObserver(view: containerView)

    configureMenu(args: args)
    setupMethodChannelHandler()
  }

  func view() -> UIView {
    containerView
  }

  private static func decodeColor(from value: Any?) -> UIColor? {
    guard let numericValue = value as? NSNumber else { return nil }
    let argb = UInt32(bitPattern: Int32(truncatingIfNeeded: numericValue.intValue))
    let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
    let red = CGFloat((argb >> 16) & 0xFF) / 255.0
    let green = CGFloat((argb >> 8) & 0xFF) / 255.0
    let blue = CGFloat(argb & 0xFF) / 255.0
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
  }

  private func buildMenuItems(from items: [[String: Any]]) -> [UIMenuElement] {
    return items.compactMap { item -> UIMenuElement? in
      guard let id = item["id"] as? String,
        let title = item["title"] as? String
      else { return nil }

      let isDestructive = (item["isDestructive"] as? Bool) ?? false
      let isDisabled = (item["isDisabled"] as? Bool) ?? false 
      let sfSymbol = item["sfSymbol"] as? String

      // Check for submenu
      if let children = item["children"] as? [[String: Any]], !children.isEmpty {
        let childElements = buildMenuItems(from: children)
        let image = sfSymbol != nil ? UIImage(systemName: sfSymbol!) : nil
        return UIMenu(title: title, image: image, children: childElements)
      }

      var attributes: UIMenuElement.Attributes = []
      if isDestructive { attributes.insert(.destructive) }
      if isDisabled { attributes.insert(.disabled) }

      let image = sfSymbol != nil ? UIImage(systemName: sfSymbol!) : nil
      let isChecked = (item["isChecked"] as? Bool) ?? false

      let action = UIAction(title: title, image: image, attributes: attributes) { [weak self] _ in
        self?.methodChannel.invokeMethod("itemSelected", arguments: id)
      }
      // TechPicks 패치: 고른 항목에 체크.
      action.state = isChecked ? .on : .off
      return action
    }
  }

  private func configureMenu(args: [String: Any]?) {
    let label = args?["label"] as? String
    let sfSymbol = args?["sfSymbol"] as? String
    let color = Self.decodeColor(from: args?["color"])
    let menuTitle = (args?["menuTitle"] as? String) ?? ""
    let iconSize = (args?["iconSize"] as? NSNumber)?.doubleValue
    let labelStyle = LiquidGlassMenuConfig.LabelStyle(arguments: args?["labelStyle"] as? [String: Any])
    let itemDicts = (args?["items"] as? [[String: Any]]) ?? []

    // Configure button appearance
    if let label {
      if let labelStyle, let labelFont = labelStyle.resolvedFont() {
        var attrs: [NSAttributedString.Key: Any] = [.font: labelFont]
        if let spacing = labelStyle.letterSpacing { attrs[.kern] = spacing }
        button.setAttributedTitle(
          NSAttributedString(string: label, attributes: attrs), for: .normal)
      } else {
        button.setTitle(label, for: .normal)
      }
    }
    // NOTE: The trigger icon is SF-Symbol-only by design. Flutter IconData
    // and asset PNGs are not supported here; only `sfSymbol` names resolve.
    if let sfSymbol {
      if let size = iconSize {
        let cfg = UIImage.SymbolConfiguration(pointSize: size, weight: .semibold)
        if let image = UIImage(systemName: sfSymbol, withConfiguration: cfg) {
          button.setImage(image, for: .normal)
        } else {
          button.setImage(UIImage(systemName: sfSymbol), for: .normal)
        }
      } else {
        button.setImage(UIImage(systemName: sfSymbol), for: .normal)
      }
    } else if label == nil {
      let fallbackCfg = iconSize.map {
        UIImage.SymbolConfiguration(pointSize: $0, weight: .semibold)
      }
      let fallback =
        fallbackCfg.flatMap { UIImage(systemName: "ellipsis.circle", withConfiguration: $0) }
        ?? UIImage(systemName: "ellipsis.circle")
      button.setImage(fallback, for: .normal)
    }
    if let color {
      button.tintColor = color
    }

    // Build menu
    let menuElements = buildMenuItems(from: itemDicts)
    button.menu = UIMenu(title: menuTitle, children: menuElements)

    // TechPicks 패치: iOS 26 은 유리 버튼(툴바 버튼과 같은 모양)으로, 칸을 꽉 채운다.
    if #available(iOS 26.0, *), args?["glass"] as? Bool == true {
      var config = UIButton.Configuration.glass()
      config.cornerStyle = .capsule
      config.image = button.image(for: .normal)
      if let label { config.title = label }
      config.baseForegroundColor = color ?? .label
      config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
      button.configuration = config
      if let label { button.accessibilityLabel = label }
      if let a11y = args?["accessibilityLabel"] as? String { button.accessibilityLabel = a11y }
      containerView.addSubview(button)
      NSLayoutConstraint.activate([
        button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
        button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        button.topAnchor.constraint(equalTo: containerView.topAnchor),
        button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
      ])
      return
    }

    containerView.addSubview(button)
    NSLayoutConstraint.activate([
      button.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      button.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
    ])
  }

  private func setupMethodChannelHandler() {
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch call.method {
      case "updateMenu":
        let args = call.arguments as? [String: Any]
        let itemDicts = (args?["items"] as? [[String: Any]]) ?? []
        let menuTitle = (args?["menuTitle"] as? String) ?? ""
        let color = Self.decodeColor(from: args?["color"])

        let menuElements = self.buildMenuItems(from: itemDicts)
        self.button.menu = UIMenu(title: menuTitle, children: menuElements)
        if let color {
          self.button.tintColor = color
          if #available(iOS 26.0, *), var config = self.button.configuration {
            config.baseForegroundColor = color
            self.button.configuration = config
          }
        }
        result(nil)

      case "getIntrinsicSize":
        self.button.sizeToFit()
        let size = self.button.intrinsicContentSize
        result(["width": Double(size.width), "height": Double(size.height)])

      case "setSuppressed":
        let suppressed = (call.arguments as? [String: Any])?["suppressed"] as? Bool ?? false
        self.suppressObserver?.setRouteSuppressed(suppressed)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
