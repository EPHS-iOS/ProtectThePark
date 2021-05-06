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
        
        let retryButton = SKShapeNode(rectOf: CGSize(width: self.frame.width/3 + 80, height: self.frame.height/12 + 20), cornerRadius: CGFloat(15))
        retryButton.position = CGPoint(x: 0, y: -self.frame.width/10 - 15)
        retryButton.fillColor = .blue
        retryButton.alpha = 0.7
        retryButton.name = "retry"
        
        let retryLabel = SKLabelNode()
        retryLabel.position = CGPoint(x: retryButton.position.x, y: retryButton.position.y - 15)
        retryLabel.fontName = "HelveticaNeue-Bold"
        retryLabel.text = "Retry"
        
        addChild(retryButton)
        addChild(retryLabel)
        
    }
    
    override func didMove(to view: SKView) {
        
        let victoryImage = SKSpriteNode(imageNamed:"Victory")
        victoryImage.size = CGSize(width: self.frame.width, height: self.frame.height)
        victoryImage.zPosition = -1

        addChild(victoryImage)
        
        label1.text = "YOU BEAT THE GEESE!!!"
        label1.fontName = "HelveticaNeue-Bold"
        label1.position = CGPoint(x: 0, y: 30)
        label1.fontSize = 45
        label1.fontColor = .white
        
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

            }
            
        }
    
    }
    
    func switchScreen(scene : String){
        
        self.view!.presentScene(GameScene(fileNamed: scene))
        
    }
    
}
