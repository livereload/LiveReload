import Cocoa
import LRProjectKit

public class NoSelectionViewController: NSViewController {

    private let label = NSTextField()

    public init() {
        super.init(nibName: nil, bundle: nil)!
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = NSView()

        label.translatesAutoresizingMaskIntoConstraints = false
        label.stringValue = NSLocalizedString("No selection", comment: "")
        label.bezeled = false
        label.drawsBackground = false
        label.editable = false
        label.selectable = false
        view.addSubview(label)

        NSLayoutConstraint.activateConstraints([
            label.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            label.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor),
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        print("\(self.dynamicType).viewDidLoad")
    }
    
}

