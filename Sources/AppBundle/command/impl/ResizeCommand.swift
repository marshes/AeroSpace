import AppKit
import Common

struct ResizeCommand: Command { // todo cover with tests
    let args: ResizeCmdArgs

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }

        let candidates = target.windowOrNil?.parentsWithSelf
            .filter { ($0.parent as? TilingContainer)?.layout == .tiles }
            ?? []

        let orientation: Orientation
        let parent: TilingContainer
        let node: TreeNode
        switch args.dimension.val {
            case .width:
                orientation = .h
                guard let first = candidates.first(where: { ($0.parent as! TilingContainer).orientation == orientation }) else { return false }
                node = first
                parent = first.parent as! TilingContainer
            case .height:
                orientation = .v
                guard let first = candidates.first(where: { ($0.parent as! TilingContainer).orientation == orientation }) else { return false }
                node = first
                parent = first.parent as! TilingContainer
            case .smart:
                guard let first = candidates.first else { return false }
                node = first
                parent = first.parent as! TilingContainer
                orientation = parent.orientation
            case .smartOpposite:
                guard let _orientation = (candidates.first?.parent as? TilingContainer)?.orientation.opposite else { return false }
                orientation = _orientation
                guard let first = candidates.first(where: { ($0.parent as! TilingContainer).orientation == orientation }) else { return false }
                node = first
                parent = first.parent as! TilingContainer
            // add one sided resize cases
            case .left:
                orientation = .h
                guard let first = candidates.first(where: { ($0.parent as! TilingContainer).orientation == orientation }) else { return false }
                node = first
                parent = first.parent as! TilingContainer
                singleSided = true
                
                // Find the node to the left
                if let index = parent.children.firstIndex(of: node), index > 0 {
                    adjacentNode = parent.children[index - 1]
                } else {
                    return false // No left node to resize with
                }
                
            case .right:
                orientation = .h
                guard let first = candidates.first(where: { ($0.parent as! TilingContainer).orientation == orientation }) else { return false }
                node = first
                parent = first.parent as! TilingContainer
                singleSided = true
                
                // Find the node to the right
                if let index = parent.children.firstIndex(of: node), index < parent.children.count - 1 {
                    adjacentNode = parent.children[index + 1]
                } else {
                    return false // No right node to resize with
                }
                
            case .top:
                orientation = .v
                guard let first = candidates.first(where: { ($0.parent as! TilingContainer).orientation == orientation }) else { return false }
                node = first
                parent = first.parent as! TilingContainer
                singleSided = true
                
                // Find the node above
                if let index = parent.children.firstIndex(of: node), index > 0 {
                    adjacentNode = parent.children[index - 1]
                } else {
                    return false // No top node to resize with
                }
                
            case .bottom:
                orientation = .v
                guard let first = candidates.first(where: { ($0.parent as! TilingContainer).orientation == orientation }) else { return false }
                node = first
                parent = first.parent as! TilingContainer
                singleSided = true
                
                // Find the node below
                if let index = parent.children.firstIndex(of: node), index < parent.children.count - 1 {
                    adjacentNode = parent.children[index + 1]
                } else {
                    return false // No bottom node to resize with
                }
        }

        let diff: CGFloat = switch args.units.val {
            case .set(let unit): CGFloat(unit) - node.getWeight(orientation)
            case .add(let unit): CGFloat(unit)
            case .subtract(let unit): -CGFloat(unit)
        }

        guard let childDiff = diff.div(parent.children.count - 1) else { return false }
        parent.children.lazy
            .filter { $0 != node }
            .forEach { $0.setWeight(parent.orientation, $0.getWeight(parent.orientation) - childDiff) }

        node.setWeight(orientation, node.getWeight(orientation) + diff)
        return true
    }
}
