import UIKit

public protocol ListCollectionLayoutDelegate: AnyObject {
    func headerHeight(for section: Int, in collectionView: UICollectionView) -> CGFloat
    func heightForItem(at indexPath: IndexPath, in collectionView: UICollectionView) -> CGFloat

    func insetsForItem(at indexPath: IndexPath, in collectionView: UICollectionView) -> UIEdgeInsets
    func insetsForSectionHeader(at index: Int, in collectionView: UICollectionView) -> UIEdgeInsets

    func spacingForItem(at indexPath: IndexPath, in collectionView: UICollectionView) -> CGFloat

    func spacingForHeader(at index: Int, in collectionView: UICollectionView) -> ListCollectionViewLayout.VerticalSpacing
    func separatorForItem(at indexPath: IndexPath, in collectionView: UICollectionView) -> ListLayoutSeparatorConfiguration?

    func footerConfiguration(for section: Int, in collectionView: UICollectionView) -> ListCollectionViewLayout.ReuseViewConfiguration?
}

public extension ListCollectionLayoutDelegate {
    func headerHeight(for section: Int, in collectionView: UICollectionView) -> CGFloat {
        (collectionView.collectionViewLayout as? ListCollectionViewLayout)?.estimatedHeaderHeight ?? .zero
    }
    func heightForItem(at indexPath: IndexPath, in collectionView: UICollectionView) -> CGFloat {
        (collectionView.collectionViewLayout as? ListCollectionViewLayout)?.estimatedItemHeight ?? .zero
    }
    func insetsForItem(at indexPath: IndexPath, in collectionView: UICollectionView) -> UIEdgeInsets { .zero }
    func insetsForSectionHeader(at index: Int, in collectionView: UICollectionView) -> UIEdgeInsets { .zero }
    func spacingForItem(at indexPath: IndexPath, in collectionView: UICollectionView) -> CGFloat { .zero }
    func spacingForHeader(at index: Int, in collectionView: UICollectionView) -> ListCollectionViewLayout.VerticalSpacing {
        (collectionView.collectionViewLayout as? ListCollectionViewLayout)?.headerSpacing ?? .zero
    }
    func separatorForItem(at indexPath: IndexPath, in collectionView: UICollectionView) -> ListLayoutSeparatorConfiguration? {
        (collectionView.collectionViewLayout as? ListCollectionViewLayout)?.itemSeparator ?? nil
    }

    func footerConfiguration(for section: Int, in collectionView: UICollectionView) -> ListCollectionViewLayout.ReuseViewConfiguration? { nil }
}

public extension ListCollectionViewLayout.VerticalSpacing {
    static var zero: Self {
        .init(top: .zero, bottom: .zero)
    }
}

extension ListCollectionViewLayout {

    public struct ReuseViewConfiguration {
        public var height: CGFloat
        public var insets: UIEdgeInsets
        public var spacing: VerticalSpacing

        public init(height: CGFloat = 0,
                    insets: UIEdgeInsets = .zero,
                    spacing: VerticalSpacing = .zero) {
            self.height = height
            self.insets = insets
            self.spacing = spacing
        }
    }
}
