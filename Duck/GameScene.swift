//  GameScene.swift
//
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

//For specific detections
struct PhysicsCategory {
    static let enemy : UInt32 = 0b1
    static let projectile : UInt32 = 0b10
    static let detection : UInt32 = 0b11
    static let none : UInt32 = 0
}

struct Nests {
    let loc : CGPoint
    let name : String
    let sprite : SKSpriteNode
    let nestNumber : Int
}

struct Ducks {
    var canFire = true
    let name: String
    let sprite: SKSpriteNode
}

struct Buttons {
    let loc : CGPoint
    let sprite: SKSpriteNode
    var isPresent : Bool
    let parentButton : String
    let name : String
}

struct Gooses {
    var health : CGFloat
    let sprite : SKSpriteNode
}

struct breadcrumb  {
    let damage : CGFloat
    let sprite : SKSpriteNode
}

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    //Unique Duck Identifier
    var duckIDX = 0
    //Unique Nest Identifier
    var nestIDX = 0
    
    var currentMap = SKSpriteNode(imageNamed: "TestMap")
    var portal = SKSpriteNode(imageNamed:"portal")
    
    public var remainingLives = 10
    public var healthLabel = SKLabelNode()
    public var currentMoney = 10000
    public var moneyLabel = SKLabelNode()
    //How much 1 duck costs and how much money you get per goose
    var duckCost = 100
    var gooseReward = 100
    
    //Stores Information on Ducks and their corresponding detection radiuses in an array
    //Stored in a swift lock-key system
    var duckInfo = [(SKSpriteNode,SKShapeNode)]()
    
    //An array of all the buttons
    var currentButtons: [Buttons] = []
    
    //An array of all the nests CURRENTLY on the screen
    var currentNests: [Nests] = []
    //array of geese
    var currentGeese: [Gooses] = []
    
    var currentDucks: [Ducks] = []
    
    /* -------------------- FUNCTIONS -------------------- */
    
    func random() -> CGFloat {
      return CGFloat(Float(arc4random()) / 4294967296)
    }

    func random(min: CGFloat, max: CGFloat) -> CGFloat {
      return random() * (max - min) + min
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self

        //Adding nest to appropriate spots
        addNest(location: CGPoint(x: self.frame.width/12, y: self.frame.height/8.5))
        addNest(location: CGPoint(x: self.frame.width/4.9, y: self.frame.height/1.8))
        addNest(location: CGPoint(x: self.frame.width/2.5, y: self.frame.height/2.2))
        addNest(location: CGPoint(x: self.frame.width/1.4, y: self.frame.height/1.75))
        addNest(location: CGPoint(x: self.frame.width/1.25, y: self.frame.height/3.75))
        
        //Label for the lives remaining
        healthLabel.text = "Remaining Lives:  " + String(remainingLives)
        healthLabel.zPosition = 2
        healthLabel.position = CGPoint(x: self.frame.width/1.2, y:self.frame.height/1.1)
        healthLabel.fontSize = CGFloat(20)
        healthLabel.fontColor = .black
        addChild(healthLabel)
        
        //Label for current money supply
        moneyLabel.text = "$: " + String(currentMoney)
        moneyLabel.zPosition = 2
        moneyLabel.position = CGPoint(x: self.frame.width/1.7, y: self.frame.height/1.1)
        moneyLabel.fontSize = CGFloat(20)
        moneyLabel.fontColor = .black
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
 
        run(firstWave())

        }
    
    //Detects any COLLISIONS and CONTACTS
    func didBegin(_ contact: SKPhysicsContact) {
        
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        if (firstBody.categoryBitMask == PhysicsCategory.enemy) && (secondBody.categoryBitMask == PhysicsCategory.detection) {
        
            var aDuck : SKSpriteNode
            let id = secondBody.node!.name?.suffix(1)
            for duck in currentDucks {
                if duck.sprite.name!.suffix(1) == id {
                    aDuck = duck.sprite
                    detectionHandler(circle: secondBody.node as! SKShapeNode, goose: firstBody.node as! SKSpriteNode, duck: aDuck)
                }
            }
            
            
        }else if (secondBody.categoryBitMask == PhysicsCategory.enemy) && (firstBody.categoryBitMask == PhysicsCategory.detection) {
            
            var aDuck : SKSpriteNode
            let id = firstBody.node!.name?.suffix(1)
            for duck in currentDucks {
                if duck.sprite.name!.suffix(1) == id {
                    aDuck = duck.sprite
                    detectionHandler(circle: firstBody.node as! SKShapeNode, goose: secondBody.node as! SKSpriteNode, duck: aDuck)
                }
            }
            
            
        }else if (firstBody.categoryBitMask == PhysicsCategory.enemy) && (secondBody.categoryBitMask == PhysicsCategory.projectile) {
            collisionHandler(proj: secondBody.node as! SKSpriteNode, enemy: firstBody.node as! SKSpriteNode)
        }else if (secondBody.categoryBitMask == PhysicsCategory.enemy) && (firstBody.categoryBitMask == PhysicsCategory.projectile) {
            collisionHandler(proj: firstBody.node as! SKSpriteNode, enemy: secondBody.node as! SKSpriteNode)
        }else{
            return
        }
        
    }
    
    func showOptions(nn: SKSpriteNode) {
        
        if currentMoney < duckCost {
            print("Could not purchase duck: Insufficient Costs")
            return
        }
        
        if nn.name?.suffix(4) == "true" {
            print("Could not purchase duck: Duck is already there!")
        }
        
        if nn.name?.suffix(1) == "0" {
            for button in currentButtons{
                if button.name.suffix(1) == "0"{
                    if button.sprite.alpha == 1 {
                        button.sprite.alpha = 0
                        return
                    }
                    
                    button.sprite.alpha = 1
                    nn.name = nn.name! + "true"
                }
            }
        } else if nn.name?.suffix(1) == "1" {
            for button in currentButtons{
                if button.name.suffix(1) == "1"{
                    if button.sprite.alpha == 1 {
                        button.sprite.alpha = 0
                        return
                    }
                    
                    button.sprite.alpha = 1
                    nn.name = nn.name! + "true"
                }
            }
        } else if nn.name?.suffix(1) == "2" {
            for button in currentButtons{
                if button.name.suffix(1) == "2"{
                    if button.sprite.alpha == 1 {
                        button.sprite.alpha = 0
                        return
                    }
                    
                    button.sprite.alpha = 1
                    nn.name = nn.name! + "true"
                }
            }
        } else if nn.name?.suffix(1) == "3" {
            for button in currentButtons{
                if button.name.suffix(1) == "3"{
                    if button.sprite.alpha == 1 {
                        button.sprite.alpha = 0
                        return
                    }
                    
                    button.sprite.alpha = 1
                    nn.name = nn.name! + "true"
                }
            }
        } else if nn.name?.suffix(1) == "4" {
            for button in currentButtons{
                if button.name.suffix(1) == "4"{
                    if button.sprite.alpha == 1 {
                        button.sprite.alpha = 0
                        return
                    }
                    
                    button.sprite.alpha = 1
                    nn.name = nn.name! + "true"
                }
            }
        }

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            
            let location = touch.location(in: self)
            
            //For buttons
            enumerateChildNodes(withName: "//*", using: { (node, stop) in
                
                if node.name?.prefix(4) == "Nest" {
                    
                    if node.contains(location){
                        node.alpha = 0.5
                        self.showOptions(nn: node as! SKSpriteNode)
                    }
                    
                } else if node.name?.prefix(6) == "Option" {
                    if node.contains(touch.location(in: self)){
                        
                        if node.alpha == 0 {
                            print("Button does not exist yet...")
                            return
                            
                        }
                        
                        let upDown : CGFloat = -60
                        let leftRight: CGFloat = -3
                        
                        if node.name == "Option0" {
                            self.addDuck(loc: CGPoint(x: node.position.x + leftRight, y: node.position.y + upDown))
                            node.alpha = 0
                        } else if node.name == "Option1" {
                            self.addDuck(loc: CGPoint(x: node.position.x + leftRight, y: node.position.y + upDown))
                            node.alpha = 0
                        } else if node.name == "Option2" {
                            self.addDuck(loc: CGPoint(x: node.position.x + leftRight, y: node.position.y + upDown))
                            node.alpha = 0
                        } else if node.name == "Option3" {
                            self.addDuck(loc: CGPoint(x: node.position.x + leftRight, y: node.position.y + upDown))
                            node.alpha = 0
                        } else if node.name == "Option4" {
                            self.addDuck(loc: CGPoint(x: node.position.x + leftRight, y: node.position.y + upDown))
                            node.alpha = 0
                        }
                        
                    }
                }
                
            })
            
            //Checks if there is a duck at where you tapped.
            for duck in duckInfo {
                if location.x >= duck.0.position.x - 20 && location.x <= duck.0.position.x + 20 && location.y >= duck.0.position.y - 20 && location.y <= duck.0.position.y + 20 {
                    
                    if(duck.1.alpha > 0){
                        duck.1.alpha = 0
                    } else {
                        duck.1.alpha = 0.1
                    }
                }
            }
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            enumerateChildNodes(withName: "//*", using: { (node, stop) in
                
                if node.name?.prefix(4) == "Nest" {
                    if node.contains(touch.location(in: self)){
                        node.alpha = 1
                    }
                }
                
            })
        }
    }
    
    /* -------------------- ADD FUNCTIONS -------------------- */
 
    func addNest(location: CGPoint) {
        let posScale = CGFloat(60)
        
        //Make the actual nest
        let nest = SKSpriteNode(imageNamed: "Nest")
        nest.position = location
        nest.name = "Nest\(nestIDX)"
        nest.size = CGSize(width: nest.size.width/(self.frame.width/45), height: nest.size.height/(self.frame.width/45))
        nest.zPosition = 2
        
        //Add the buttons for upgrades or ducks at a specified location above the nest.
        addOptions(loc: CGPoint(x: nest.position.x, y: nest.position.y + posScale),pB: nest.name!, id: "Option\(nest.name!.suffix(1))");
        
        addChild(nest)
        currentNests.append(Nests(loc: nest.position, name: nest.name!, sprite: nest, nestNumber: nestIDX))
        nestIDX += 1
    }
    
    func addOptions(loc: CGPoint, pB: String, id: String){
        let heightScale = CGFloat(25)
        
        let option = SKSpriteNode(imageNamed: "Breadcrumb")
        option.name = id
        option.position = loc
        option.zPosition = 2
        option.alpha = 0
        option.size = CGSize(width: option.size.width/(self.frame.width/heightScale), height: option.size.height/(self.frame.width/heightScale))
        
        addChild(option)
        currentButtons.append(Buttons(loc: option.position, sprite: option, isPresent: true, parentButton: pB, name: option.name!))
        
    }
    
    func addDuck(loc: CGPoint) {
        
        //Only allows a duck to be placed if player has enough money and if there is not more than 5 ducks, and subtracts that money from their total
        if (self.currentMoney >= duckCost) {
            self.currentMoney -= duckCost
            self.moneyLabel.text = "$: " + String(self.currentMoney)
        } else {
            return
        }
        //Makes a duck
        var duck = SKSpriteNode(imageNamed: "BasicDuckFullBody")
        duck.position = loc
        duck.size = CGSize(width: duck.size.width/(self.frame.width/50), height: duck.size.height/(self.frame.width/50))
        duck.name = "Duck\(duckIDX)"
        duck.zPosition = 3
        
        // Detection Circle to detect Geese that are close
        var detectionCircle = SKShapeNode(circleOfRadius: 100)
        detectionCircle.physicsBody = SKPhysicsBody(circleOfRadius: 80)
        detectionCircle.position = duck.position
        detectionCircle.fillColor = .cyan
        detectionCircle.physicsBody?.affectedByGravity = false
        detectionCircle.name = "DetectionCircle\(duckIDX)"
        detectionCircle.alpha = 0.1
        detectionCircle.physicsBody?.isDynamic = true
        
        //Collisions:
        //The circle is a type of detection.
        detectionCircle.physicsBody?.categoryBitMask = PhysicsCategory.detection
        
        //Do we want it to BOUNCE off things? We don't want the detection circle to collide with anything, so we set it to none.
        detectionCircle.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        //DETECTIONS between objects; does not have an effect on if an object will or can bounce off one another or COLLIDE? Since we want the detection circle to detect geese or any enemy that are in the circle, we put the category "enemy" in.
        detectionCircle.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        
        var newDuck = Ducks(canFire: true, name: duck.name!, sprite: duck)
        currentDucks.append(newDuck)
        
        duckIDX+=1
        //Adds duck to current list of ducks
        duckInfo.append((duck, detectionCircle))
        addChild(detectionCircle)
        addChild(duck)
    }
    
    func addGoose(health: Int, speed: Double) {  // Goose Spawner
        
      // Create sprite
      let goose = SKSpriteNode(imageNamed: "BasicGooseFullBody")
        goose.size = CGSize(width: goose.size.width/(self.frame.width/65), height: goose.size.height/(self.frame.width/65))
        goose.physicsBody = SKPhysicsBody(circleOfRadius: goose.size.width - 25)
        goose.zPosition = 1
        goose.physicsBody?.affectedByGravity = false
        
        goose.name = "enemy"
        goose.physicsBody?.isDynamic = true

        //Collisions
        goose.physicsBody?.categoryBitMask = PhysicsCategory.enemy //Goose is a type of enemy
        goose.physicsBody?.collisionBitMask = PhysicsCategory.none //We want the breadcrumb to look like it's bouncing off of the goose, so we put projectile in for collisionBitMask
        goose.physicsBody?.contactTestBitMask = PhysicsCategory.projectile | PhysicsCategory.detection// We also want the goose to detect if it has been hit by a breadcrumb, not only just bouncing it off. In addition, we want the detection circle to detect if a goose is in its radius, so we add that too.

        goose.position = CGPoint(x: self.frame.width/8.75, y: self.frame.height/1.05)
      
      // Add the goose to the scene
      addChild(goose)
        let goose1 = Gooses(health : CGFloat(health), sprite: goose)
        currentGeese.append(goose1)
        
      
        let gooseSpeed = speed
      
      // Create the actions

        let firstMove = SKAction.sequence([
            SKAction.move(to: CGPoint(x: self.frame.width/8.75, y: self.frame.height/2.82),duration: TimeInterval((320.0/250.0)/gooseSpeed)),
            SKAction.run {goose.zRotation = CGFloat(Double.pi/2.0)}
        ])
            
        let secondMove = SKAction.sequence([
            SKAction.move(to: CGPoint(x: self.frame.width/3.3, y: self.frame.height/2.82), duration: TimeInterval((250.0/250.0)/gooseSpeed)),
            SKAction.run {goose.zRotation = CGFloat(Double.pi)}])
        
        let thirdMove = SKAction.sequence([
            SKAction.move(to: CGPoint(x: self.frame.width/3.3, y: self.frame.height/1.30), duration: TimeInterval((245.0/250.0)/gooseSpeed)),
            SKAction.run {goose.zRotation = CGFloat(Double.pi/2.0)}])
        
        let fourthMove = SKAction.sequence([ SKAction.move(to: CGPoint(x: self.frame.width/1.08, y: self.frame.height/1.30), duration: TimeInterval((685.0/250.0)/gooseSpeed)),
            SKAction.run {goose.zRotation = CGFloat(Double.pi * 0)}])
        
        let fifthMove = SKAction.move(to: CGPoint(x: self.frame.width/1.08, y: self.frame.height/5), duration: TimeInterval((320.0/250.0)/gooseSpeed))
        
        let finalAction = SKAction.sequence(
            [SKAction.run {self.remainingLives -= 1},
             SKAction.run{self.healthLabel.text = "Remaining Lives:  " + String(self.remainingLives)},
             SKAction.removeFromParent(),
             SKAction.run {
                if self.remainingLives <= 0 {
                    let gameOverScene = SKScene(fileNamed: "GameOver")
                    self.view?.presentScene(gameOverScene)
                    
                }
             }
            ])

      goose.run(SKAction.sequence([firstMove,secondMove,thirdMove, fourthMove, fifthMove, finalAction]))
    }
    

    /* -------------------- ACTIONS -------------------- */
    func launchBreadcrumb (startPoint: CGPoint, endPoint: CGPoint) {
        
        let crumb = SKSpriteNode (imageNamed: "Breadcrumb")
        crumb.size = CGSize(width: 30, height: 30)
        crumb.position = startPoint
        crumb.zPosition = 3
        crumb.name = "projectile"
        crumb.physicsBody = SKPhysicsBody(circleOfRadius: 1)
        crumb.physicsBody?.usesPreciseCollisionDetection = true
        crumb.physicsBody?.affectedByGravity = false
        crumb.physicsBody?.isDynamic = true
       
        crumb.physicsBody?.categoryBitMask = PhysicsCategory.projectile //Breadcrumb is type projectile
        crumb.physicsBody?.collisionBitMask = PhysicsCategory.none //We want the breadcrumb to bounce off the goose
        crumb.physicsBody?.contactTestBitMask = PhysicsCategory.enemy //We want to detect when the breadcrumb touches the goose
        
        let rotation = CGFloat (random(min: 0, max: CGFloat( 2.0 * Double.pi)))
        
        crumb.zRotation = rotation
        addChild(crumb)
        let crumb1 = breadcrumb(damage: 10, sprite : crumb)
        
        crumb.run(SKAction.sequence([SKAction.move(to: endPoint, duration: 0.2), SKAction.removeFromParent()]))
    }
    
    
    
    /* -------------------- HANDLERS -------------------- */
     //Used for the detection circle to indicate whether or not a goose has entered the "bread" zone
    //NOTE: This is where you can get the geese's position as well.
    func detectionHandler(circle: SKShapeNode, goose: SKSpriteNode, duck: SKSpriteNode){

        let circleID  = (circle.name!.replacingOccurrences(of: "DetectionCircle", with: "Duck"))
        let spinningDuck = childNode(withName: circleID)!
        let distanceX = spinningDuck.position.x - goose.position.x
        let distanceY = spinningDuck.position.y - goose.position.y
        if distanceY >= 0 {
            duck.zRotation = CGFloat(2 * Double.pi - atan(Double(distanceX/distanceY))) //If duck is above or equal to goose
        } else {
            duck.zRotation = CGFloat(Double.pi - atan(Double(distanceX/distanceY))) //If duck is below goose
        }

        //Cooldown
        var i = 0
        while i < currentDucks.count {
                
            //Check for the duck that is associated with the detection circle that was triggered.
            if currentDucks[i].sprite.name!.suffix(1) == duck.name!.suffix(1) {
                    
                print(currentDucks[i].name + " canFire = " + String(currentDucks[i].canFire))
                
                if !currentDucks[i].canFire {
                    //If there is a cooldown, do nothing.
                    return
                }
                       
                if currentDucks[i].canFire {
                    //If there is not a cooldown, shoot the breadcrumb, wait for 2 seconds, and set cooldown back to false.
//                    run(SKAction.sequence([SKAction.run {
//                        self.launchBreadcrumb(startPoint: circle.position, endPoint: goose.position)
//
//                        print(self.currentDucks[i].name + " is going to be set to false")
//                        self.currentDucks[i].canFire = false
//
//
//                    }, SKAction.wait(forDuration: 3),
//
//                    SKAction.run {
//                        self.currentDucks[i].canFire = true
//                    }
//
//                    ])
//                    )
                    
                    run(SKAction.sequence([
                        
                            SKAction.run {
                                
                                self.launchBreadcrumb(startPoint: circle.position, endPoint: goose.position)
                                //print(self.currentDucks[i].name + " is going to be set to false")
                                self.currentDucks[i].canFire = false
                                
                            }
                            ,
                            SKAction.wait(forDuration: 3)
                            ,
                            
                            SKAction.run{
                                
                                self.currentDucks[i].canFire = true
                                
                            }
                            
                        ])
                    )
                    
                }
                
            }
            i+=1
        }
        i=0
    }
    
        
    
    //Used to actually deal damage to the goose if the breadcrumbs collide with a goose.
    func collisionHandler(proj: SKSpriteNode, enemy: SKSpriteNode) {
    /*
        
        var i = 0
        while(i < currentGeese.count){
            if currentGeese[i].health <= 0{
                enemy.removeFromParent()
           
        }else{
            currentGeese[i].health = currentGeese[i].health - 50
        }
        i+=1
    
    }
    i=0
        
        
    */
       var i = 0
        while (i < currentGeese.count) {
            if currentGeese[i].sprite == enemy {
                currentGeese[i].health -= 50
                if currentGeese[i].health <= 0 {
                    enemy.removeFromParent()
                }
            }
            i += 1
        }
        proj.removeFromParent()
        self.currentMoney += gooseReward
        self.moneyLabel.text = "$: " + String(self.currentMoney)
      
        
        
        
    }
      
    //Adds a series of geese with number "amt" and waits for "gap" seconds between each goose. All geese in the series will have health of "hp" and move at speed "spd"
    public func gooseSeries(amt: Int, gap: Double, hp: Int, spd: Double) -> SKAction {
       // SKAction.repeat(SKAction.sequence([SKAction.run(addGoose(health: hp, speed: spd)), SKAction.wait(forDuration: gap)]), count: amt)
        let gooseWait = SKAction.sequence([SKAction.run {
            self.addGoose(health: hp, speed: spd)
        },
        SKAction.wait(forDuration: gap)
        ])
        return SKAction.repeat(gooseWait, count: amt)
    }
    
    func firstWave() -> SKAction{
        SKAction.sequence([
            gooseSeries(amt: 5, gap: 1.5, hp: 50, spd: 1.0),
            gooseSeries(amt: 5, gap: 1.0, hp : 100, spd: 1.1),
            gooseSeries(amt: 200, gap: 0.7, hp : 150, spd: 1.3)
        ])
    }

}
