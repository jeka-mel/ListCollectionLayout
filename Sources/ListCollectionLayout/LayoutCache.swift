import UIKit

final public class LayoutCache<A: UICollectionViewLayoutAttributes>: RandomAccessCollection, MutableCollection {

    final public class Item {
        public fileprivate(set) var index: Int = -1
        public var header: A?
        public var footer: A?
        public var items: ContiguousArray<A> = []

        public init(index: Int, header: A? = nil, footer: A? = nil) {
            self.index = index
            self.header = header
            self.footer = footer
        }
    }

    public private(set) var data: ContiguousArray<Item> = []

    public subscript(indexPath: IndexPath) -> A {
        get { data[indexPath.section].items[indexPath.item] }
        set { data[indexPath.section].items[indexPath.item] = newValue }
    }

    // MARK: - LifeCycle

    public init(capacity: Int) {
        data = .init((0 ..< capacity).map { Item(index: $0, header: nil) })
    }

    public init() { }

    // MARK: - Methods

    public func removeAll() {
        data.removeAll()
    }

    // MARK: - Collection

    public var startIndex: Int { 0 }

    public var endIndex: Int { data.count }

    public func index(after i: Int) -> Int {
        precondition(i < endIndex)
        return i + 1
    }

    public func index(before i: Int) -> Int { i - 1 }

    public subscript(position: Int) -> LayoutCache<A>.Item {
        get { data[position] }
        set { data[position] = newValue }
    }
}
