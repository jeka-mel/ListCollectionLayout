import UIKit
import ListCollectionLayout

open class ListCollectionView: UICollectionView {

    // MARK: - Properties

    public private(set) var layout: ListCollectionViewLayout

    open override var collectionViewLayout: UICollectionViewLayout {
        get { layout }
        set {
            if let l = newValue as? ListCollectionViewLayout {
                layout = l
            } else {
                assertionFailure(ListCollectionView.assertMessage)
            }
        }
    }

    fileprivate static var assertMessage: String {
        "\(ListCollectionViewLayout.self) is a required baseclass for layout in this collectionView"
    }

    // MARK: - LifeCycle

    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        assert(layout is ListCollectionViewLayout, ListCollectionView.assertMessage)
        self.layout = layout as! ListCollectionViewLayout // swiftlint:disable:this all
        super.init(frame: frame, collectionViewLayout: layout)
    }

    required public init?(coder aDecoder: NSCoder) {
        let layout = ListCollectionViewLayout()
        self.layout = layout
        super.init(frame: .zero, collectionViewLayout: layout)
    }

    public convenience init(frame: CGRect) {
        self.init(frame: frame, collectionViewLayout: ListCollectionViewLayout())
    }
}
