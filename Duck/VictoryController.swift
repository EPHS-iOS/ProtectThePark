//
//  VictoryController.swift
//  Duck
//
//  Created by Randy Thai on 4/29/21.
//  Main controller for Victory screen.

import Foundation
import UIKit
import GameplayKit
import SpriteKit

class VictoryController : SKScene {
    
    let label1 = SKLabelNode()
    
    func createButtons(){
        
        let mainButton = SKShapeNode(rectOf: CGSize(width: self.frame.width/3 + 80, height: self.frame.height/12 + 20), cornerRadius: CGFloat(15))
        mainButton.position = CGPoint(x: -self.frame.width/10 - 100, y: -self.frame.width/10 - 15)
        mainButton.fillColor = .red
        mainButton.alpha = 0.7
        mainButton.name = "main"
        
        let mainLabel = SKLabelNode()
        mainLabel.position = CGPoint(x: mainButton.position.x, y: mainButton.position.y - 15)
        mainLabel.fontName = "HelveticaNeue-Bold"
        mainLabel.text = "Return to Main Menu"
        
        let retryButton = SKShapeNode(rectOf: CGSize(width: self.frame.width/3 + 80, height: self.frame.height/12 + 20), cornerRadius: CGFloat(15))
        retryButton.position = CGPoint(x: self.frame.width/10 + 100, y: -self.frame.width/10 - 15)
        retryButton.fillColor = .blue
        retryButton.alpha = 0.7
        retryButton.name = "retry"
        
        let retryLabel = SKLabelNode()
        retryLabel.position = CGPoint(x: retryButton.position.x, y: retryButton.position.y - 15)
        retryLabel.fontName = "HelveticaNeue-Bold"
        retryLabel.text = "Retry"
        
        addChild(mainButton)
        addChild(mainLabel)
        addChild(retryButton)
        addChild(retryLabel)
        
    }
    
    override func didMove(to view: SKView) {
        
        label1.text = "YOU BEAT THE GEESE!!!"
        label1.fontName = "HelveticaNeue-Bold"
        label1.position = .zero
        label1.fontSize = 45
        label1.fontColor = .green
        
        addChild(label1)
        
        createButtons()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            
        let touch:UITouch = touches.first! as UITouch
        let positionInScene = touch.location(in: self)
        let touchedNode = self.atPoint(positionInScene)
        
        if let name = touchedNode.name {

            if name == "retry" {

                switchScreen(scene: "GameScene")

            } else if name == "main" {

                print("Transferring to Main Menu.")


            }

        }
    
    }
    
    func switchScreen(scene : String){
        
        self.view!.presentScene(GameScene(fileNamed: scene))
        
    }
    
}
