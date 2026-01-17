import UIKit

class CompteViewController: UIViewController {
    
    @IBOutlet weak var typeCompteSegmentedControl: UISegmentedControl!
    @IBOutlet weak var actionSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        self.navigationItem.hidesBackButton = true
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        super.viewDidLoad()
    }
    
    @IBAction func validerButtonTapped(_ sender: UIButton) {
        let typeIndex = typeCompteSegmentedControl.selectedSegmentIndex
        let actionIndex = actionSegmentedControl.selectedSegmentIndex
        
        var viewControllerIdentifier = ""
        
        switch (typeIndex, actionIndex) {
        case (0, 0):
            viewControllerIdentifier = "ComptePersoViewController"
        case (0, 1):
            viewControllerIdentifier = "CompteConnexionPersoViewController"
        case (1, 0):
            viewControllerIdentifier = "CompteAssoViewController"
        case (1, 1):
            viewControllerIdentifier = "CompteConnexionAssoViewController"
        default:
            break
        }
        
        if !viewControllerIdentifier.isEmpty,
           let nextVC = storyboard?.instantiateViewController(withIdentifier: viewControllerIdentifier) {
            navigationController?.pushViewController(nextVC, animated: true)
        }
    }
}
