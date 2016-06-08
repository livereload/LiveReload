import Cocoa
import LRProjectKit

public class ProjectPaneViewController: NSViewController {

    public let project: Project

    private let label = NSTextField()

    public init(project: Project) {
        self.project = project
        super.init(nibName: nil, bundle: nil)!
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = NSView()

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFontOfSize(24)
        label.stringValue = project.displayName
        label.bezeled = false
        label.drawsBackground = false
        label.editable = false
        label.selectable = false
        view.addSubview(label)

        NSLayoutConstraint.activateConstraints([
            label.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: 12),
            label.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: 16),
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        print("\(self.dynamicType).viewDidLoad")
    }

}
