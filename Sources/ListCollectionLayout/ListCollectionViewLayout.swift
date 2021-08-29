import UIKit

open class ListCollectionViewLayout: UICollectionViewLayout {

    public struct VerticalSpacing: Hashable {
        public var top: CGFloat = .zero
        public var bottom: CGFloat = .zero
        public init(top: CGFloat = .zero, bottom: CGFloat = .zero) {
            self.top = top
            self.bottom = bottom
        }
        public var sum: CGFloat { top + bottom }
    }

    // MARK: - Properties

    open override class var layoutAttributesClass: AnyClass {
        ListLayoutAttributes.self
    }

    open weak var delegate: ListCollectionLayoutDelegate?

    open var interSectionSpacing: CGFloat = .zero {
        didSet { invalidateLayout() }
    }

    open var itemSpacing: CGFloat = .zero {
        didSet { invalidateLayout() }
    }

    open var headerSpacing: VerticalSpacing = .init() {
        didSet { invalidateLayout() }
    }

    /// Will be returned if `delegate.heightForItem...` is not provided
    open var estimatedItemHeight: CGFloat = .zero {
        didSet { invalidateLayout() }
    }

    /// Will be returned if `headerHeight(for section...` is not provided
    open var estimatedHeaderHeight: CGFloat = .zero {
        didSet { invalidateLayout() }
    }

    open var estimatedItemInsets: UIEdgeInsets = .zero {
        didSet { invalidateLayout() }
    }
    open var estimatedHeaderInsets: UIEdgeInsets = .zero {
        didSet { invalidateLayout() }
    }

    open var defaultFooterConfig: ReuseViewConfiguration = .init()

    private var contentHeight: CGFloat = .zero

    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return .zero }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }

    public var contentSize: CGSize {
        collectionViewContentSize
    }

    open override var collectionViewContentSize: CGSize {
        CGSize(width: contentWidth, height: contentHeight)
    }

    private(set) var cache: LayoutCache<ListLayoutAttributes> = .init()

    private var insertingIndexPaths: [IndexPath] = []
    private var deletingIndexPaths: [IndexPath] = []

    // MARK: - Configuration

    public enum LayoutType: CaseIterable {
        case straight, reverse
    }

    open var layoutType: LayoutType = .straight {
        didSet { invalidateLayout() }
    }

    /// Indicates if all content should be aligned to the bottom.
    /// E.g. first cells will appear on the bottom, not on the top as default.
    open var bottomAlignedContent: Bool = false {
        didSet { invalidateLayout() }
    }

    /// Indicates if CollectionView should allow content to scroll down
    /// when new items are being added to the top. Default is `true`.
    open var allowScrollOnTopInsert: Bool = true

    /// Defines the cases when collectionView schould be scrolled to bottom
    /// when new boottom items are being added.
    public enum BottomScrollStrategy {
        /// Default behaviour of UICollectionView (not scrolled to bottom).
        case none
        /// Always scroll to bottom when new bottom items added.
        case always
        /// Scroll to bottom only if collectionView was bottom-aligned.
        case aligned
    }

    open var scrollDownStrategy: BottomScrollStrategy = .none {
        didSet { invalidateLayout() }
    }

    public enum LayoutAttributesSearch {
        case plain, bin
    }

    open var scrollDownDelta: CGFloat { 10.0 }

    /// The strategy on how layout attributes, which are being prepared for displaying (in CGRect), will be calculated.
    /// Default is `.intersection`.
    open var layoutAttributesSearch = LayoutAttributesSearch.plain

    open var itemSeparator: ListLayoutSeparatorConfiguration?

    // MARK: - LifeCycle

    public convenience init(layoutType: LayoutType = .straight, bottomAlignedContent: Bool = false) {
        self.init()
        self.layoutType = layoutType
        self.bottomAlignedContent = bottomAlignedContent
    }

    public override init() {
        super.init()
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Methods

    private func orderedList(for itemsCount: Int) -> [Int] {
        switch layoutType {
        case .straight:
            return (0 ..< itemsCount).reversed()
        case .reverse:
            return (0 ..< itemsCount).map { $0 }
        }
    }

    open override func prepare() {
        super.prepare()
        // Check if we really can make a layout
        guard cache.isEmpty, let collectionView = self.collectionView else {
            return
        }

        let sectionCount = collectionView.numberOfSections
        cache = .init(capacity: sectionCount)

        for si in 0 ..< sectionCount { // Build a sections cache
            let cachedSection = cache[si]
            let itemsCount = collectionView.numberOfItems(inSection: si)
            // Do not show anything if there're no items in section
            guard itemsCount > .zero else { continue }
            contentHeight += interSectionSpacing
            // Section Header
            let headerHeight = delegate?.headerHeight(for: si, in: collectionView) ?? estimatedHeaderHeight
            if headerHeight > .zero {
                let headerSpacing = delegate?.spacingForHeader(at: si, in: collectionView) ?? self.headerSpacing
                let fullHeaderHeight = headerHeight + (headerSpacing.top + headerSpacing.bottom)
                contentHeight += fullHeaderHeight // Calculate an overall sections content size
                let indexPath = IndexPath(item: 0, section: si)
                let headerAttributes = ListLayoutAttributes(
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    with: indexPath
                )
                headerAttributes.insets = delegate?.insetsForSectionHeader(at: si, in: collectionView) ?? estimatedHeaderInsets
                headerAttributes.frame = CGRect(x: 0, y: 0, width: contentWidth, height: headerHeight)
                headerAttributes.reuseViewSpacing = headerSpacing
                cachedSection.header = headerAttributes
            }
            // Section Footer
            let footerConf = delegate?.footerConfiguration(for: si, in: collectionView) ?? defaultFooterConfig
            if footerConf.height > .zero {
                let fullFooterHeight = footerConf.height + footerConf.spacing.sum
                contentHeight += fullFooterHeight
                let indexPath = IndexPath(item: 0, section: si)
                let footerAttibutes = ListLayoutAttributes(
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                    with: indexPath
                )
                footerAttibutes.insets = footerConf.insets
                footerAttibutes.frame = CGRect(x: 0, y: 0, width: contentWidth, height: footerConf.height)
                footerAttibutes.reuseViewSpacing = footerConf.spacing
                cachedSection.footer = footerAttibutes
            }
            // Items
            for ii in 0 ..< itemsCount {
                // Pre-configure item attributes
                let indexPath = IndexPath(item: ii, section: si)
                let itemHeight = delegate?.heightForItem(at: indexPath, in: collectionView) ?? estimatedItemHeight
                let itemSpacing = delegate?.spacingForItem(at: indexPath, in: collectionView) ?? self.itemSpacing
                let fullItemHeight = itemHeight + itemSpacing
                contentHeight += fullItemHeight // Calculate overall items size
                let itemAttributes = ListLayoutAttributes(forCellWith: indexPath)
                itemAttributes.insets = delegate?.insetsForItem(at: indexPath, in: collectionView) ?? estimatedItemInsets
                itemAttributes.spacing = itemSpacing
                itemAttributes.frame = CGRect(x: 0, y: 0, width: contentWidth, height: itemHeight)
                cachedSection.items.append(itemAttributes)
            }
        }

        // Collection View capacity
        let capacity = cache.compactMap({ $0.items.count }).reduce(0, +)
        if capacity == 0 {
            contentHeight = 0
            cache.removeAll()
            return
        }

        // Content height
        if bottomAlignedContent {
            contentHeight = max(contentHeight, collectionView.frame.height)
        }

        // Item position calculations
        var yOffset: CGFloat = contentHeight

        let allSections = orderedList(for: sectionCount)
        for si in allSections { // Enumerate sections
            let cachedSection = cache[si]
            let itemsCount = cachedSection.items.count
            // Do not show anything if there're no items in section
            guard itemsCount > .zero else { continue }
            // Prepare
            let allItems = orderedList(for: itemsCount)

            // Inter-Section Spacing
            yOffset -= interSectionSpacing

            // Set origin for every section footer
            if let footer = cachedSection.footer {
                let footerSpacing = cachedSection.footer?.reuseViewSpacing ?? self.defaultFooterConfig.spacing
                let fullFooterHeight = footer.frame.height + footerSpacing.sum
                let yPos = (yOffset - fullFooterHeight) + footerSpacing.top
                footer.frame.origin = CGPoint(x: 0, y: yPos)
                footer.frame = footer.frame.inset(by: footer.insets)
                yOffset -= fullFooterHeight
            }

            for ii in allItems { // Set origin of every item in section
                let cachedItem = cachedSection.items[ii]
                let spacing = cachedItem.spacing
                let height = cachedItem.frame.height
                let yPos = yOffset - (height + spacing)
                cachedItem.frame.origin = CGPoint(x: 0, y: yPos)
                cachedItem.frame = cachedItem.frame.inset(by: cachedItem.insets)
                yOffset -= height + spacing // Align to the top of the section
            }

            // Set origin for every section header
            if let header = cachedSection.header {
                let headerSpacing = cachedSection.header?.reuseViewSpacing ?? self.headerSpacing
                let fullHeaderHeight = header.frame.height + headerSpacing.sum
                let yPos = (yOffset - fullHeaderHeight) + headerSpacing.top
                header.frame.origin = CGPoint(x: 0, y: yPos)
                header.frame = header.frame.inset(by: header.insets)
                yOffset -= fullHeaderHeight
            }
        }
    }

    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // Search for attributes of items
        let result: [UICollectionViewLayoutAttributes]?
        switch layoutAttributesSearch {
        case .bin:
            result = binSearchedAttributesFor(elementsIn: rect)
        case .plain:
            result = intersectionSearchFor(elementsIn: rect)
        }
        guard let arr = result else { return nil }
        // Check decoration attributes
        var decorationAttributes: [UICollectionViewLayoutAttributes] = []
        for layoutAttributes in arr {
            let indexPath = layoutAttributes.indexPath
            if let separatorAttributes = layoutAttributesForDecorationView(ofKind: UICollectionView.elementKindSeparatorView, at: indexPath) {
                if rect.intersects(separatorAttributes.frame) {
                    decorationAttributes.append(separatorAttributes)
                }
            }
        }
        return arr + decorationAttributes
    }

    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.section < cache.data.count, indexPath.item < cache.data[indexPath.section].items.count else { return nil }
        return cache[indexPath]
    }

    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            return cache[indexPath.section].header
        case UICollectionView.elementKindSectionFooter:
            return cache[indexPath.section].footer
        default:
            return nil
        }
    }

    open override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        switch elementKind {
        case UICollectionView.elementKindSeparatorView:
            guard let cellAttributes = layoutAttributesForItem(at: indexPath) else {
                return createAttributesForSeparator(at: indexPath)
            }
            return layoutAttributesSeparatorView(at: indexPath, for: cellAttributes.frame, state: .normal)
        default:
            return nil
        }
    }

    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        let offset = super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        guard let collectionView = self.collectionView, contentHeight > collectionView.frame.height else {
            return offset
        }
        // Determine a desired contentOffset by calculating heights of all newly inserted items
        let yPos = contentHeight - collectionView.bounds.size.height + collectionView.contentInset.bottom

        let lastItemHeight: CGFloat
        switch layoutType {
        case .straight:
            let attributes = cache.last?.items.last ?? UICollectionViewLayoutAttributes()
            lastItemHeight = round(attributes.frame.height + itemSpacing)
        case .reverse:
            let attributes = cache.first?.items.last ?? UICollectionViewLayoutAttributes()
            lastItemHeight = round(attributes.frame.height + itemSpacing)
        }

        let lastCachedItemIndexPath: IndexPath = {
            let section = cache.count - 1
            return IndexPath(item: cache[section].items.count, section: section)
        }()

        let bottomIndexPath: IndexPath
        switch layoutType {
        case .straight:
            bottomIndexPath = lastCachedItemIndexPath
        case .reverse:
            bottomIndexPath = IndexPath(item: 0, section: 0)
        }

        let delta: CGFloat
        if #available(iOS 11.0, *) {
            delta = scrollDownDelta + collectionView.adjustedContentInset.bottom
        } else {
            delta = scrollDownDelta
        }
        let isBottomPositioned = abs(round(collectionView.contentOffset.y - yPos)) - lastItemHeight <= delta

        let needScrollDown: Bool
        switch scrollDownStrategy {
        case .always: needScrollDown = insertingIndexPaths.contains(bottomIndexPath)
        case .none: needScrollDown = false
        case .aligned: needScrollDown = isBottomPositioned
        }

        // Bottom Positioning & Offset (for "scroll down" strategy)
        if needScrollDown {
            let bottomOffset = CGPoint(x: -collectionView.contentInset.left, y: yPos)
            return bottomOffset
        } else if !allowScrollOnTopInsert { // Top positioning (Stay in-place while adding new items)
            let topItemIndexPath: IndexPath
            switch layoutType {
            case .straight:
                topItemIndexPath = IndexPath(item: 0, section: 0)
            case .reverse:
                topItemIndexPath = IndexPath(item: lastCachedItemIndexPath.item - 1,
                                             section: lastCachedItemIndexPath.section)
            }

            if insertingIndexPaths.contains(topItemIndexPath) {
                let inserts: [CGFloat] = insertingIndexPaths.compactMap {
                    self.cache[$0].frame.height + itemSpacing
                }
                let totalHeight = inserts.reduce(0, +)
                return .init(x: collectionView.contentOffset.x, y: collectionView.contentOffset.y + totalHeight)
            }
        }
        return offset
    }

    // MARK: - CollectionView Updates (Overrides)

    open override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        insertingIndexPaths.removeAll()
        deletingIndexPaths.removeAll()

        for item in updateItems {
            switch item.updateAction {
            case .delete:
                if let indexPath = item.indexPathBeforeUpdate {
                    deletingIndexPaths.append(indexPath)
                }
            case .insert:
                if let indexPath = item.indexPathAfterUpdate {
                    insertingIndexPaths.append(indexPath)
                }
            case .move, .reload, .none:
                break
            @unknown default:
                break
            }
        }
    }

    open override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()
        insertingIndexPaths.removeAll()
        deletingIndexPaths.removeAll()
    }

    open override func indexPathsToDeleteForDecorationView(ofKind elementKind: String) -> [IndexPath] {
        return deletingIndexPaths
    }

    open override func indexPathsToInsertForDecorationView(ofKind elementKind: String) -> [IndexPath] {
        return insertingIndexPaths
    }

    open override func initialLayoutAttributesForAppearingDecorationElement(ofKind elementKind: String, at decorationIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let cellAttributes = initialLayoutAttributesForAppearingItem(at: decorationIndexPath) else {
            return createAttributesForSeparator(at: decorationIndexPath)
        }
        return layoutAttributesSeparatorView(at: decorationIndexPath, for: cellAttributes.frame, state: .initial)
    }

    open override func finalLayoutAttributesForDisappearingDecorationElement(ofKind elementKind: String, at decorationIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let cellAttributes = finalLayoutAttributesForDisappearingItem(at: decorationIndexPath) else {
            return createAttributesForSeparator(at: decorationIndexPath)
        }
        return layoutAttributesSeparatorView(at: decorationIndexPath, for: cellAttributes.frame, state: .final)
    }

    // MARK: - Layout Invalidation

    open override func invalidateLayout() {
        super.invalidateLayout()
        contentHeight = 0
        cache.removeAll()
    }

    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else {
            assertionFailure()
            return false
        }
        return newBounds.size != collectionView.bounds.size
    }

    open override class var invalidationContextClass: AnyClass {
        ListCollectionLayoutInvalidationContext.self
    }

    open override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        guard let t_Context = context as? ListCollectionLayoutInvalidationContext else { return context }
        t_Context.invalidateLayoutDelegateMetrics = shouldInvalidateLayout(forBoundsChange: newBounds)
        return t_Context
    }

    open override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        super.invalidateLayout(with: context)
        // TODO: Implement partial invalidation (visible items only?)
    }
}

// MARK: - Private

private extension ListCollectionViewLayout {

    func setup() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange(_:)),
            name: UIApplication.didChangeStatusBarOrientationNotification,
            object: nil
        )
        register(ListLayoutSeparatorView.self, forDecorationViewOfKind: UICollectionView.elementKindSeparatorView)
        register(ListLayoutBlankHeaderView.self, forDecorationViewOfKind: UICollectionView.elementKindSectionHeader)
    }

    @objc
    private func handleOrientationChange(_ notification: Notification) {
        invalidateLayout()
    }

    enum State {
        case initial
        case normal
        case final
    }

    private func createAttributesForSeparator(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let conf: ListLayoutSeparatorConfiguration?
        if let collectionView = self.collectionView, let c = delegate?.separatorForItem(at: indexPath, in: collectionView) {
            conf = c
        } else {
            conf = itemSeparator
        }
        return conf?.attributes(forDecorationViewOfKind: UICollectionView.elementKindSeparatorView, with: indexPath)
    }

    func layoutAttributesSeparatorView(at indexPath: IndexPath, for cellFrame: CGRect, state: State) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = self.collectionView else {
            return nil
        }
        // Create attributes
        guard let separatorAttributes = createAttributesForSeparator(at: indexPath) else {
            return nil
        }
        // Add separator for every row except the first
        guard indexPath.item > 0 else {
            separatorAttributes.alpha = 0.0
            separatorAttributes.isHidden = true
            return separatorAttributes
        }

        let itemSpacing = delegate?.spacingForItem(at: indexPath, in: collectionView) ?? self.itemSpacing
        let rect = collectionView.bounds
        separatorAttributes.alpha = 1.0
        separatorAttributes.isHidden = false
        separatorAttributes.frame.origin = .init(x: rect.minX, y: cellFrame.origin.y - itemSpacing / 2)
        separatorAttributes.frame.size.width = rect.width
        let insets = UIEdgeInsets(top: .zero, left: collectionView.contentInset.left, bottom: .zero, right: collectionView.contentInset.right)
        separatorAttributes.frame = separatorAttributes.frame.inset(by: insets)
        separatorAttributes.zIndex = 1000
        // Sync the decorator animation with the cell animation in order to avoid blinkining
        switch state {
        case .normal:
            separatorAttributes.alpha = 1
        default:
            separatorAttributes.alpha = 0.1
        }
        return separatorAttributes
    }
}

// MARK: - Search functions

private extension ListCollectionViewLayout {

    func intersectionSearchFor(elementsIn rect: CGRect) -> [UICollectionViewLayoutAttributes] {
        var result: [UICollectionViewLayoutAttributes] = []
        for i in cache {
            result.append(contentsOf: i.items.filter { $0.frame.intersects(rect) })
            if let h = i.header, h.frame.intersects(rect) {
                result.append(h)
            }
            if let f = i.footer, f.frame.intersects(rect) {
                result.append(f)
            }
        }
        return result
    }

    func binSearchedAttributesFor(elementsIn rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributesArray = [UICollectionViewLayoutAttributes]()

        for i in cache {
            let cachedAttributes: ContiguousArray<ListLayoutAttributes> = i.items + [i.header].compactMap { $0 } + [i.footer].compactMap { $0 }
            // Find any cell that sits within the query rect.
            guard let lastIndex = cachedAttributes.indices.last,
                  let firstMatchIndex = binSearch(rect, start: 0, end: lastIndex, array: cachedAttributes) else { continue }

            // Starting from the match, loop up and down through the array until all the attributes
            // have been added within the query rect.
            for attributes in cachedAttributes[..<firstMatchIndex].reversed() {
                guard attributes.frame.maxY >= rect.minY else { continue }
                attributesArray.append(attributes)
            }

            for attributes in cachedAttributes[firstMatchIndex...] {
                guard attributes.frame.minY <= rect.maxY else { continue }
                attributesArray.append(attributes)
            }
        }

        return attributesArray
    }

    /// Perform a binary search on the cached attributes array.
    func binSearch<T: UICollectionViewLayoutAttributes>(_ rect: CGRect, start: Int, end: Int, array: ContiguousArray<T>) -> Int? {

        if end < start { return nil }

        let mid = (start + end) / 2
        let attr = array[mid]

        if attr.frame.intersects(rect) {
            return mid
        } else {
            if attr.frame.maxY < rect.minY {
                return binSearch(rect, start: (mid + 1), end: end, array: array)
            } else {
                return binSearch(rect, start: start, end: (mid - 1), array: array)
            }
        }
    }
}

// MARK: - Extensions

public extension UICollectionView {
    static var elementKindSeparatorView: String { "SeparatorView" }
}
