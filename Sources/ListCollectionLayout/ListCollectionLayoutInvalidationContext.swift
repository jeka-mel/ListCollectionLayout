import UIKit

open class ListCollectionLayoutInvalidationContext: UICollectionViewLayoutInvalidationContext {

    /// A Boolean indicating whether to recompute the size of items and views in the layout.
    var invalidateLayoutDelegateMetrics: Bool = true

    open override var invalidateEverything: Bool {
        return invalidateLayoutDelegateMetrics
    }
}
