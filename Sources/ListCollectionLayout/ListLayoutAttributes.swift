import UIKit

open class ListLayoutAttributes: UICollectionViewLayoutAttributes {

    internal var insets: UIEdgeInsets = .zero
    internal var spacing: CGFloat = .zero

    internal var reuseViewSpacing: ListCollectionViewLayout.VerticalSpacing = .zero

    /// Do not use! Index for cache in `ListCollectionViewLayout`.
    var cacheListIndex: Int = -1

    open override func copy(with zone: NSZone? = nil) -> Any {
        guard let copy = super.copy(with: zone) as? ListLayoutAttributes else {
            return NSObject()
        }
        copy.insets = insets
        copy.cacheListIndex = cacheListIndex
        copy.reuseViewSpacing = reuseViewSpacing
        return copy
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let attributes = object as? ListLayoutAttributes else { return false }
        return super.isEqual(attributes)
            && attributes.insets == insets
            && attributes.cacheListIndex == cacheListIndex
            && attributes.reuseViewSpacing == reuseViewSpacing
    }
}
