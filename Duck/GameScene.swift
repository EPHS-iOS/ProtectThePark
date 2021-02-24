//
//  GameScene.swift
//  Test
//Randy?
//  Created by Team DUCK on 2/18/21.

import SpriteKit
import GameplayKit
import UIKit

func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
  func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
  }
#endif

extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }
  
  func normalized() -> CGPoint {
    return self / length()
  }
}

class GameScene: SKScene {
    var duckIDX = 0
    
    var currentMap = SKSpriteNode(imageNamed: "TestMap")
    
    override func didMove(to view: SKView) {
        
        //Map
        currentMap.position = CGPoint(x: self.frame.width/2, y: self.frame.height/2)
        currentMap.size = CGSize(width: self.frame.width, height: self.frame.height)
        currentMap.zPosition = -1
        
        addChild(currentMap)
        
        run(SKAction.repeatForever(
              SKAction.sequence([
                SKAction.run(addGoose),
                SKAction.wait(forDuration: 1.0)
                ])
            ))
        }
        
    
    //Touch recognition
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            addDuck(loc: location)
            
        }
    }
    
   /* override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
      // 1 - Choose one of the touches to work with
      guard let touch = touches.first else {
        return
      }
      let touchLocation = touch.location(in: self)
      
      // 2 - Set up initial location of projectile
      let projectile = SKSpriteNode(imageNamed: "Breadcrumb")
      projectile.position = duck.position
        projectile.size = CGSize(width: 40, height: 40)
      
      // 3 - Determine offset of location to projectile
      let offset = touchLocation - projectile.position
      
      // 5 - OK to add now - you've double checked position
      addChild(projectile)
      
      // 6 - Get the direction of where to shoot
      let direction = offset.normalized()
      
      // 7 - Make it shoot far enough to be guaranteed off screen
      let shootAmount = direction * 1000
      
      // 8 - Add the shoot amount to the current position
      let realDest = shootAmount + projectile.position
      
      // 9 - Create the actions
      let actionMove = SKAction.move(to: realDest, duration: 2.0)
      let actionMoveDone = SKAction.removeFromParent()
      projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
    } */
    
    func random() -> CGFloat {
      return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }

    func random(min: CGFloat, max: CGFloat) -> CGFloat {
      return random() * (max - min) + min
    }
    
    func addDuck(loc: CGPoint) {
        if(duckIDX >= 5){ //Max amount of Ducks = 5
            print("Max Amount of Duck Reached")
            return
        }
        
        //Makes a duck
        let duck = SKSpriteNode(imageNamed: "BasicDuckFullBody")
        duck.position = loc
        duck.size = CGSize(width: 100, height: 110)
        duck.name = "Duck\(duckIDX)"
        duck.zPosition = 1
        duckIDX+=1
        print(duck.name)
        
        // Detection Circle to detect Geese that are close
        let detectionCircle = SKShapeNode(circleOfRadius: 100)
        detectionCircle.position = CGPoint(x: duck.position.x - 2, y: duck.position.y + 15)
        detectionCircle.fillColor = .blue
        detectionCircle.name = "DetectionCircle_\(duck.name)"
        detectionCircle.zPosition = 0
        detectionCircle.alpha = 0.2
        print(detectionCircle.name)
        
        addChild(detectionCircle)
        addChild(duck)
    }
    
    func addGoose() {  // Goose Spawner
      
      // Create sprite
      let goose = SKSpriteNode(imageNamed: "BasicGooseFullBody")
      
      // Determine where to spawn the monster along the Y axis
      let actualY = random(min: goose.size.height/2, max: size.height - goose.size.height/2)
      
      // Position the monster slightly off-screen along the right edge,
      // and along a random position along the Y axis as calculated above
      goose.position = CGPoint(x: size.width + goose.size.width/2, y: actualY)
      
      // Add the monster to the scene
      addChild(goose)
        goose.size = CGSize(width: 100, height: 110)
      
      // Determine speed of the monster
      let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
      
      // Create the actions
      let actionMove = SKAction.move(to: CGPoint(x: -goose.size.width/2, y: actualY),
                                     duration: TimeInterval(actualDuration))
      let actionMoveDone = SKAction.removeFromParent()
      goose.run(SKAction.sequence([actionMove, actionMoveDone]))
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
