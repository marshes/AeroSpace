import AppKit
import Common

struct ResizeCommand: Command {
    let args: ResizeCmdArgs

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }

        let candidates = target.windowOrNil?.parentsWithSelf
            .filter { ($0.parent as? TilingContainer)?.layout == .tiles }
            ?? []

        let orientation: Orientation
        let parent: TilingContainer
        let node: TreeNode
        
        // Handle each dimension type
        switch args.dimension.val {
            case .width:
                orientation = .h
                guard let first = candidates.first(where: { ($0.parent as! TilingContainer).orientation == orientation }) else { return false }
                node = first
                parent = first.parent as! TilingContainer
                
                // Apply regular width resize (both sides)
                return applyRegularResize(node: node, parent: parent, orientation: orientation)
                
            case .height:
                orientation = .v
                guard let first = candidates.first(where: { ($0.parent as! TilingContainer).orientation == orientation }) else { return false }
                node = first
                parent = first.parent as! TilingContainer
                
                // Apply regular height resize (both sides)
                return applyRegularResize(node: node, parent: parent, orientation: orientation)
                
            case .smart:
                guard let first = candidates.first else { return false }
                node = first
                parent = first.parent as! TilingContainer
                orientation = parent.orientation
                
                // Apply regular smart resize
                return applyRegularResize(node: node, parent: parent, orientation: orientation)
                
            case .smartOpposite:
                guard let _orientation = (candidates.first?.parent as? TilingContainer)?.orientation.opposite else { return false }
                orientation = _orientation
                guard let first = candidates.first(where: { ($0.parent as! TilingContainer).orientation == orientation }) else { return false }
                node = first
                parent = first.parent as! TilingContainer
                
                // Apply regular smart-opposite resize
                return applyRegularResize(node: node, parent: parent, orientation: orientation)
                
            // New single-side resize cases
            case .left:
                orientation = .h
                guard let first = candidates.first(where: { ($0.parent as! TilingContainer).orientation == orientation }) else { return false }
                node = first
                parent = first.parent as! TilingContainer
                
                // Find the node to the left
                guard let index = parent.children.firstIndex(of: node), index > 0 else { return false }
                let leftNode = parent.children[index - 1]
                
                // Apply left-side only resize
                return applySingleSideResize(targetNode: node, adjacentNode: leftNode, orientation: orientation)
                
            case .right:
                orientation = .h
                guard let first = candidates.first(where: { ($0.parent as! TilingContainer).orientation == orientation }) else { return false }
                node = first
                parent = first.parent as! TilingContainer
                
                // Find the node to the right
                guard let index = parent.children.firstIndex(of: node), index < parent.children.count - 1 else { return false }
                let rightNode = parent.children[index + 1]
                
                // Apply right-side only resize
                return applySingleSideResize(targetNode: node, adjacentNode: rightNode, orientation: orientation)
                
            case .top:
                orientation = .v
                guard let first = candidates.first(where: { ($0.parent as! TilingContainer).orientation == orientation }) else { return false }
                node = first
                parent = first.parent as! TilingContainer
                
                // Find the node above
                guard let index = parent.children.firstIndex(of: node), index > 0 else { return false }
                let topNode = parent.children[index - 1]
                
                // Apply top-side only resize
                return applySingleSideResize(targetNode: node, adjacentNode: topNode, orientation: orientation)
                
            case .bottom:
                orientation = .v
                guard let first = candidates.first(where: { ($0.parent as! TilingContainer).orientation == orientation }) else { return false }
                node = first
                parent = first.parent as! TilingContainer
                
                // Find the node below
                guard let index = parent.children.firstIndex(of: node), index < parent.children.count - 1 else { return false }
                let bottomNode = parent.children[index + 1]
                
                // Apply bottom-side only resize
                return applySingleSideResize(targetNode: node, adjacentNode: bottomNode, orientation: orientation)
        }
    }
    
    // Helper method for regular resize (existing behavior)
    @MainActor private func applyRegularResize(node: TreeNode, parent: TilingContainer, orientation: Orientation) -> Bool {
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
    
    // Helper method for single-side resize (new behavior)
    @MainActor private func applySingleSideResize(targetNode: TreeNode, adjacentNode: TreeNode, orientation: Orientation) -> Bool {
        let diff: CGFloat = switch args.units.val {
            case .set(let unit): CGFloat(unit) - targetNode.getWeight(orientation)
            case .add(let unit): CGFloat(unit)
            case .subtract(let unit): -CGFloat(unit)
        }

        // Only adjust the target node and adjacent node
        adjacentNode.setWeight(orientation, adjacentNode.getWeight(orientation) - diff)
        targetNode.setWeight(orientation, targetNode.getWeight(orientation) + diff)
        return true
    }
}
