//  GameScene.swift
//
//  Created by Team DUCK on 2/18/21.
//This is a change to the code



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

//For specific detections
struct PhysicsCategory {
    static let enemy : UInt32 = 0b1
    static let projectile : UInt32 = 0b10
    static let detection : UInt32 = 0b11
    static let none : UInt32 = 0b100
}

class GameScene: SKScene, SKPhysicsContactDelegate{
    var duckIDX = 0
    var currentMap = SKSpriteNode(imageNamed: "TestMap")
    var portal = SKSpriteNode(imageNamed:"portal")
    public var remainingLives = 10
    public var healthLabel = SKLabelNode()
    public var currentMoney = 100
    public var moneyLabel = SKLabelNode()
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        //Label for the lives remaining
        healthLabel.text = "Remaining Lives:  " + String(remainingLives)
        healthLabel.zPosition = 2
        healthLabel.position = CGPoint(x: self.frame.width/1.2, y:self.frame.height/1.1)
        healthLabel.fontSize = CGFloat(20)
        addChild(healthLabel)
        
        
        //Label for current money supply
        moneyLabel.text = "$: " + String(currentMoney)
        moneyLabel.zPosition = 2
        moneyLabel.position = CGPoint(x: self.frame.width/1.2, y: self.frame.height/6.5)
        moneyLabel.fontSize = CGFloat(20)
        addChild(moneyLabel)
    
        //Map
        currentMap.position = CGPoint(x: self.frame.width/2, y: self.frame.height/2)
        currentMap.size = CGSize(width: self.frame.width, height: self.frame.height)
        currentMap.name = "map"
        currentMap.zPosition = -1
        
        addChild(currentMap)
        
        portal.position = CGPoint(x: self.frame.width/8.75, y: self.frame.height/1.05)
        portal.zPosition = 0
        portal.size = CGSize(width: 100, height: 110)
        
        addChild(portal)
        
        
        
        run(SKAction.repeat(SKAction.sequence([SKAction.run(addGoose), SKAction.wait(forDuration: 5.0)]), count: 10))
        
        }
     
    //Touch recognition
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            addDuck(loc: location)
            
            //Adds a duck to the location where you tapped (temporary).
            
            
        }
    }
    
    func random() -> CGFloat {
      return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }

    func random(min: CGFloat, max: CGFloat) -> CGFloat {
      return random() * (max - min) + min
    }
    
    func addDuck(loc: CGPoint) {
        physicsWorld.contactDelegate = self
        if(duckIDX >= 5){ //Max amount of Ducks = 5
            print("Max Amount of Duck Reached")
            return
        }
        if (self.currentMoney >= 100) {
            self.currentMoney -= 100
            self.moneyLabel.text = "$: " + String(self.currentMoney)
        } else {
            return
        }
        //Makes a duck
        let duck = SKSpriteNode(imageNamed: "BasicDuckFullBody")
        duck.position = loc
        duck.size = CGSize(width: 100, height: 110)
        duck.name = "Duck\(duckIDX)"
        duck.zPosition = 1
        duckIDX+=1
        
        // Detection Circle to detect Geese that are close
        let detectionCircle = SKShapeNode(circleOfRadius: 100)
        detectionCircle.physicsBody = SKPhysicsBody(circleOfRadius: 50)
        detectionCircle.position = CGPoint(x: duck.position.x - 2, y: duck.position.y + 15)
        detectionCircle.fillColor = .cyan
        detectionCircle.physicsBody?.affectedByGravity = false
        detectionCircle.name = "DetectionCircle"
        detectionCircle.alpha = 0.1
        detectionCircle.physicsBody?.usesPreciseCollisionDetection = true
        detectionCircle.physicsBody?.isDynamic = true
        //Collisions:
        detectionCircle.physicsBody?.categoryBitMask = PhysicsCategory.detection
        detectionCircle.physicsBody?.collisionBitMask = PhysicsCategory.none
        detectionCircle.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        
        addChild(detectionCircle)
        addChild(duck)
    }
    
    func addGoose() {  // Goose Spawner
      
        physicsWorld.contactDelegate = self
        
      // Create sprite
      let goose = SKSpriteNode(imageNamed: "BasicGooseFullBody")
        goose.size = CGSize(width: 58, height: 70)
        goose.physicsBody = SKPhysicsBody(circleOfRadius: 70)
        goose.zPosition = 1
        
        goose.physicsBody?.usesPreciseCollisionDetection = true
        goose.name = "enemy"
        goose.physicsBody?.isDynamic = false

        goose.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        goose.physicsBody?.collisionBitMask = PhysicsCategory.none
        goose.physicsBody?.contactTestBitMask = PhysicsCategory.detection | PhysicsCategory.projectile
        
        
        
      // Determine where to spawn the monster along the Y axis
      //let actualY = random(min: goose.size.height/2, max: size.height - goose.size.height/2)
      
      // Position the monster slightly off-screen along the right edge,
      // and along a random position along the Y axis as calculated above

        goose.position = CGPoint(x: self.frame.width/8.75, y: self.frame.height/1.05)
      
      // Add the monster to the scene
      addChild(goose)
        
      // Determine speed of the geese. Bigger number = faster
        let actualDuration = 0.9
      
      // Create the actions
        let firstMove = SKAction.move(to: CGPoint(x: self.frame.width/8.75, y: self.frame.height/2.82),duration: TimeInterval((320.0/250.0)/actualDuration))
        let secondMove = SKAction.move(to: CGPoint(x: self.frame.width/3.3, y: self.frame.height/2.82), duration: TimeInterval((250.0/250.0)/actualDuration))
        let thirdMove = SKAction.move(to: CGPoint(x: self.frame.width/3.3, y: self.frame.height/1.35), duration: TimeInterval((245.0/250.0)/actualDuration))
        let fourthMove = SKAction.move(to: CGPoint(x: self.frame.width/1.08, y: self.frame.height/1.35), duration: TimeInterval((685.0/250.0)/actualDuration))
        let fifthMove = SKAction.move(to: CGPoint(x: self.frame.width/1.08, y: self.frame.height/5), duration: TimeInterval((320.0/250.0)/actualDuration))
        let finalAction = SKAction.sequence(
            [SKAction.run {self.remainingLives -= 1},
             SKAction.run{self.healthLabel.text = "Remaining Lives:  " + String(self.remainingLives)},
             SKAction.removeFromParent()])
      goose.run(SKAction.sequence([firstMove,secondMove,thirdMove, fourthMove, fifthMove, finalAction]))
        
    }
    
    //Used for the detection circle to indicate whether or not a goose has entered the "bread" zone
    func detectionHandler(obj: SKShapeNode, thing: SKSpriteNode){
        thing.removeFromParent()
        self.currentMoney += 50
        self.moneyLabel.text = "$: " + String(self.currentMoney)
        print("Detected")
    }
    
    //Used to actually deal damage to the goose if the breadcrumbs collide with a goose.
    func collisionHandler(proj: SKSpriteNode, enemy: SKSpriteNode){
        print("Deal Damage")
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        if (firstBody.categoryBitMask == PhysicsCategory.enemy) && (secondBody.categoryBitMask == PhysicsCategory.detection) {
            detectionHandler(obj: secondBody.node as! SKShapeNode, thing: firstBody.node as! SKSpriteNode)
        }else if (secondBody.categoryBitMask == PhysicsCategory.enemy) && (firstBody.categoryBitMask == PhysicsCategory.detection) {
            detectionHandler(obj: firstBody.node as! SKShapeNode, thing: secondBody.node as! SKSpriteNode)
        }else{
            return
        }
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
   
}
