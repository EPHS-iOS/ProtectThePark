//
//  GameOverController.swift
//  Duck
//
//  Created by Randy Thai on 4/29/21.
//  Main controller for GameOver scene.

import Foundation
import UIKit
import GameplayKit
import SpriteKit

class GameOverController : SKScene {
    
    func createButtons(){
        
        let retryButton = SKShapeNode(rectOf: CGSize(width: self.frame.width/2 + 60, height: self.frame.height/10 + 30), cornerRadius: CGFloat(15))
        retryButton.position = CGPoint(x: 0, y: -self.frame.width/10 - 50)
        retryButton.fillColor = .red
        retryButton.name = "retry"
        
        let retryLabel = SKLabelNode()
        retryLabel.position = CGPoint(x: retryButton.position.x, y: retryButton.position.y - 10)
        retryLabel.fontName = "HelveticaNeue-Bold"
        retryLabel.fontSize = 25
        retryLabel.fontColor = .white
        retryLabel.text = "Retry"

        addChild(retryButton)
        addChild(retryLabel)
        
    }
    
    override func didMove(to view: SKView) {
        
        print("Game Over!")
        
        let gameOverImage = SKSpriteNode(imageNamed:"GameOver")
        gameOverImage.size = CGSize(width: self.frame.width, height: self.frame.height)
        gameOverImage.zPosition = -1

        addChild(gameOverImage)
        
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

