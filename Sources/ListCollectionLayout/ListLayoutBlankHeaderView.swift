import UIKit

open class ListLayoutBlankHeaderView: UICollectionReusableView {

    open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        assert(layoutAttributes is ListLayoutAttributes)
        guard let attrs = layoutAttributes as? ListLayoutAttributes else { return }
        frame = attrs.frame.inset(by: attrs.insets)
    }
}
