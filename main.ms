env.importPaths = [
	"/sys/lib",
	"./src",
]


import "importUtil"
import "mathUtil"
import "stringUtil"
import "qa"
import "json"

ensureImport "constants"

ensureImport "actions"
ensureImport "AnimationSet"
ensureImport "AssetFactory"
ensureImport "behaviors"
ensureImport "Dice"
ensureImport "Entity"
ensureImport "Label"
ensureImport "Animation"
ensureImport "TileSet"
ensureImport "Timer"
ensureImport "WorldAction"


text.clear
display(4).clear


// The set of animations that makes a "person".
person = AssetFactory.loadAnimationSet("animationSets/person.json")

// You *could* think of race and class as external mutators.  If that helps.

applyRace = function(entity)
	// Human
	entity.constitution += Dice.const(10).roll
	return entity
end function

applyClass = function(entity)
	// Fighter
	entity.constitution += dice.make(3, 6).roll
	return entity
end function

player = Entity.make
player.behaviors.push behaviors.playerInput
player.moveTo 8, 8
player.addToDisplay display(4)

player = applyRace(player)
player = applyClass(player)

entities = []
entities.push player

worldActions = []

lastFrameTime = time
deltaTime = 0
boredTimer = Timer.make(3)

boredTimerLabel = Label.make("bored timer: {value}", 25, 0, 20)
isBoredLabel = Label.make("is bored: {value}", 24, 0, 15)
energyLabel = Label.make("energy: {value}", 23, 0, 15)


while true
	boredTimerLabel.draw({ "value": player.behaviors[0].boredTimer.remainingTime })
	isBoredLabel.draw({ "value": player.behaviors[0].boredTimer.isTriggered })
	energyLabel.draw({ "value": player.currentEnergy })

	// Animation instances are shared globally, so they need a single update path.
	AssetFactory.updateAnimations deltaTime
	
	// First loop to update the entities and build the action queue.
	n = 0
	while n < len(entities)
		e = entities[n]
		worldActions += e.update(deltaTime)
		n += 1
	end while

	// Second loop to flush the action queue.
	while len(worldActions) > 0
		act = worldActions.pop
		act.action.execute act.entity
	end while

	deltaTime = time - lastFrameTime
	lastFrameTime = time
	yield
end while
