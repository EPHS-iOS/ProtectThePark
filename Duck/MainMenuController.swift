//
//  MainMenuController.swift
//  Duck
//
//  Created by 90307988 on 3/3/21.
//

import UIKit

let image = UIImage(named:"MenuArt")
let MainMenuArt = UIImageView(image: image!)

class MainMenuController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        MainMenuArt.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        view.addSubview(MainMenuArt)
        // Do any additional setup after loading the view.
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
