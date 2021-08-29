import UIKit

open class ListLayoutSeparatorView: UICollectionReusableView {

    open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        assert(layoutAttributes is ListLayoutSeparatorAttributes)
        guard let attrs = layoutAttributes as? ListLayoutSeparatorAttributes else { return }
        backgroundColor = attrs.color
        frame = attrs.frame.inset(by: attrs.insets)
    }
}

// MARK: - Configuration

public struct ListLayoutSeparatorConfiguration {
    public var insets: UIEdgeInsets
    public var color: UIColor
    public var height: CGFloat
    public init(insets: UIEdgeInsets = .zero,
                height: CGFloat = 1.0 / UIScreen.main.scale,
                color: UIColor = .cellSeparatorColor) {
        self.insets = insets
        self.color = color
        self.height = height
    }
}

extension ListLayoutSeparatorConfiguration {
    public func attributes(forDecorationViewOfKind: String, with indexPath: IndexPath) -> ListLayoutSeparatorAttributes {
        let attrs: ListLayoutSeparatorAttributes = .init(forDecorationViewOfKind: forDecorationViewOfKind, with: indexPath)
        attrs.insets = insets
        attrs.color = color
        attrs.frame.size.height = height
        return attrs
    }
}

// MARK: - ListLayoutSeparatorAttributes

open class ListLayoutSeparatorAttributes: ListLayoutAttributes {

    open var color: UIColor = .cellSeparatorColor

    open override func copy(with zone: NSZone? = nil) -> Any {
        guard let copy = super.copy(with: zone) as? ListLayoutSeparatorAttributes else {
            return NSObject()
        }
        copy.color = color
        return copy
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let attributes = object as? ListLayoutSeparatorAttributes else { return false }
        return super.isEqual(attributes) && color == attributes.color
    }
}

// MARK: - Extensions

public extension UIColor {
    static var cellSeparatorColor: UIColor {
        if #available(iOS 13, *) {
            return .separator
        } else {
            return .lightGray
        }
    }
}
