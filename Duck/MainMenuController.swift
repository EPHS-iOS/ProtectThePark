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
        
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: self.view.frame.size.width/2 - 70, y: self.view.frame.size.height/2 + 80, width: 130, height: 110)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        button.backgroundColor = .systemRed
        button.setTitle("START", for: .normal)
        button.addTarget(self, action: #selector(startButtonPressed), for: .touchUpInside)
        view.addSubview(button)
        
        print("BUTTON")
        // Do any additional setup after loading the view.
    }
    
    @objc func startButtonPressed() {
        performSegue(withIdentifier: "toGameScene", sender: nil)
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
