env.importPaths = [
	"/sys/lib",
	"./src",
]


import "importUtil"
import "mapUtil"
import "mathUtil"
import "stringUtil"
import "qa"
import "json"

ensureImport "constants"

ensureImport "actions"
ensureImport "Animation"
ensureImport "AnimationSet"
ensureImport "AssetFactory"
ensureImport "behaviors"
ensureImport "Chunk"
ensureImport "Class"
ensureImport "DiamondSquareNoise"
ensureImport "Dice"
ensureImport "Entity"
ensureImport "Label"
ensureImport "PerlinNoise"
ensureImport "Point"
ensureImport "Race"
ensureImport "RawFileReader"
ensureImport "RawFileWriter"
ensureImport "Rectangle"
ensureImport "Tile"
ensureImport "TileSet"
ensureImport "Timer"
ensureImport "World"
ensureImport "WorldAction"


chunk = null
world = null


// You *could* think of race and class as external mutators.  If that helps.

applyRace = function(entity, racePath)
	race = AssetFactory.loadRace(racePath)
	race.apply entity
	return entity
end function


applyClass = function(entity, classPath)
	class = AssetFactory.loadClass(classPath)
	class.apply entity
	return entity
end function


initialize = function
	display(6).mode = displayMode.tile

	text.clear
	gfx.clear
	display(4).clear

	globals.entities = []
	globals.worldActions = []
	globals.chunk = null

	globals.lastFrameTime = time
	globals.deltaTime = 0
end function


loadChunk = function(worldX, worldY, worldZ)
	if globals.chunk != null then
		globals.chunk.saveChunk
	end if

	if globals.world == null then
		seed = 0
		path = "/usr/world_{0}.raw".fill([ seed ])
		if file.exists(path) then
			print "Loading world..."
			globals.world = World.loadWorld(path)
			print "Done."
		else
			print "Generating world..."
			globals.world = World.make(256, 256, seed)
			print "Saving world..."
			globals.world.saveWorld
			print "Done."
		end if
	end if

	chunkTiles = AssetFactory.loadTileSet("chunkTiles")

	path = "/usr/chunk_{0}_{1}_{2}.raw".fill([ worldX, worldY, worldZ ])
	if file.exists(path) then
		print "Loading chunk from disk for {0},{1},{2}".fill([ worldX,worldY,worldZ ])
		globals.chunk = Chunk.loadChunk(chunkTiles, worldX, worldY, worldZ)
	else
		print "Generating chunk for {0},{1},{2}".fill([ worldX,worldY,worldZ ])
		globals.chunk = Chunk.make(chunkTiles, world, worldX, worldY, worldZ)
	end if

	chunk.render display(6)
	return chunk
end function


newGame = function
	// loadChunk 0, 0, 0
	loadChunk 64, 64, 0

	// The set of animations that makes a "person".
	person = AssetFactory.loadAnimationSet("person")

	globals.player = Entity.make(person)
	player.behaviors.push behaviors.playerInput
	player.moveTo 38, 30
	player.addToDisplay display(4)

	applyRace(player, "human")
	applyClass(player, "fighter")

	entities.push player
end function


loadGame = function(path)
	data = json.parse(file.open(path).read)

	globals.chunk = Chunk.fromJson(data.currentChunkPath)
	// globals.chunk = Chunk.fromSerializable(data.currentChunkPath)

	n = 0
	while n < len(data.entities)
		e = Entity.fromSerializable(data.entities[n])
		e.addToDisplay display(4)
		entities.push e
		n += 1
	end while
end function


saveGame = function(path)
	currentChunkPath = globals.chunk.saveChunk

	data = {}
	data.currentChunkPath = currentChunkPath

	data.entities = []
	n = 0
	while n < len(entities)
		e = entities[n]
		data.entities.push e.toSerializable
		n += 1
	end while

	file.writeLines path, json.toJSON(data)
end function


scrollTo = function(entity)
	halfWidth = gfx.width / 2
	halfHeight = gfx.height / 2

	mapWidth = display(6).extent[0] * display(6).cellSize[0]
	mapHeight = display(6).extent[1] * display(6).cellSize[1]

	spriteX = entity.sprite.x + entity.sprite.image.width / 2
	spriteY = entity.sprite.y - entity.sprite.image.height / 2

	if spriteX - halfWidth < 0 then
		scrollX = 0
	else if spriteX > mapWidth - halfWidth then
		scrollX = mapWidth - gfx.width
	else
		scrollX = spriteX - halfWidth
	end if

	if spriteY - halfHeight < 0 then
		scrollY = 0
	else if spriteY > mapHeight - halfHeight then
		scrollY = mapHeight - gfx.height
	else
		scrollY = spriteY - halfHeight
	end if

	display(4).scrollX = scrollX
	display(4).scrollY = scrollY
	display(6).scrollX = scrollX
	display(6).scrollY = scrollY
end function


transitionSouth = function(entity)
	text.clear
	ss = Image.fromScreen
	mapHeight = display(6).extent[1] * display(6).cellSize[1]
	y = 0

	// Load the new tile map data here.
	loadChunk chunk.worldX, chunk.worldY - 4, chunk.worldZ

	display(6).scrollY = mapHeight - y

	transitionStartTime = time
	while y < gfx.height
		display(6).scrollY = mapHeight - y
		gfx.fillRect 0, 0, gfx.width, y, color.clear
		gfx.drawImage ss, 0, y
		y = (time - transitionStartTime) / SCREEN_TRANSITION_TIME * gfx.height
	end while
	gfx.clear

	tileX = entity.getTileX
	tileY = entity.getTileY
	entity.moveTo tileX, display(6).extent[1] - 1
end function


transitionNorth = function(entity)
	text.clear
	ss = Image.fromScreen
	mapHeight = display(6).extent[1] * display(6).cellSize[1]
	height = gfx.height

	// TODO: Load the new tile map data here.
	loadChunk chunk.worldX, chunk.worldY + 4, chunk.worldZ

	display(6).scrollY = -height

	transitionStartTime = time
	while height >= 0
		display(6).scrollY = -height
		gfx.fillRect 0, height, gfx.width, gfx.height - height, color.clear
		gfx.drawImage ss, 0, 0, gfx.width, height, 0, ss.height - height, gfx.width, height
		height = (1 - (time - transitionStartTime) / SCREEN_TRANSITION_TIME) * gfx.height
	end while
	gfx.clear
	
	tileX = entity.getTileX
	tileY = entity.getTileY
	entity.moveTo tileX, 0
end function


transitionWest = function(entity)
	text.clear
	ss = Image.fromScreen
	mapWidth = display(6).extent[0] * display(6).cellSize[0]
	x = 0

	// TODO: Load the new tile map data here.
	loadChunk chunk.worldX - 4, chunk.worldY, chunk.worldZ

	display(6).scrollX = mapWidth - x

	transitionStartTime = time
	while x < gfx.width
		display(6).scrollX = mapWidth - x
		gfx.fillRect 0, 0, x, gfx.height, color.clear
		gfx.drawImage ss, x, 0
		x = (time - transitionStartTime) / SCREEN_TRANSITION_TIME * gfx.width
	end while
	gfx.clear

	tileX = entity.getTileX
	tileY = entity.getTileY
	entity.moveTo display(6).extent[0] - 1, tileY
end function


transitionEast = function(entity)
	text.clear
	ss = Image.fromScreen
	mapWidth = display(6).extent[0] * display(6).cellSize[0]
	width = gfx.width

	// TODO: Load the new tile map data here.
	loadChunk chunk.worldX + 4, chunk.worldY, chunk.worldZ

	display(6).scrollX = -width

	transitionStartTime = time
	while width >= 0
		display(6).scrollX = -width
		gfx.fillRect width, 0, gfx.width - width, gfx.height, color.clear
		gfx.drawImage ss, 0, 0, width, gfx.height, ss.width - width, 0, width, gfx.height
		width = (1 - (time - transitionStartTime) / SCREEN_TRANSITION_TIME) * gfx.width
	end while
	gfx.clear

	tileX = entity.getTileX
	tileY = entity.getTileY
	entity.moveTo 0, tileY
end function


main = function
	worldMiniMap = globals.world.generateMiniMap

	// boredTimerLabel = Label.make("bored timer: {value}", 25, 0, 20)
	// isBoredLabel = Label.make("is bored: {value}", 24, 0, 15)
	// energyLabel = Label.make("energy: {value}", 23, 0, 15)
	positionLabel = Label.make("player: {0},{1} ({2},{3})", 25, 0, 25)

	isDone = false
	while not isDone
		if key.pressed("escape") then
			isDone = true
		end if

		// boredTimerLabel.draw({ "value": entities[0].behaviors[0].boredTimer.remainingTime })
		// isBoredLabel.draw({ "value": entities[0].behaviors[0].boredTimer.isTriggered })
		// energyLabel.draw({ "value": entities[0].currentEnergy })
		positionLabel.draw([player.getTileX, player.getTileY, chunk.worldX, chunk.worldY])

		// Animation instances are shared globally, so they need a single update path.
		AssetFactory.updateAnimations deltaTime
		
		// First loop to update the entities and build the action queue.
		n = 0
		while n < len(entities)
			e = entities[n]
			globals.worldActions += e.update(deltaTime, globals.chunk)
			n += 1
		end while

		// Second loop to flush the action queue.
		while len(worldActions) > 0
			act = worldActions.pop
			act.action.execute act.entity
		end while
		
		tx = player.getTileX
		ty = player.getTileY
		if tx < 0 then
			transitionWest player
		else if tx >= display(6).extent[0] then
			transitionEast player
		else if ty < 0 then
			transitionSouth player
		else if ty >= display(6).extent[1] then
			transitionNorth player
		else
			scrollTo player
		end if

		chunkScale = 4
		gfx.drawImage worldMiniMap, 0, 0, worldMiniMap.width, worldMiniMap.height
        left = (globals.chunk.worldX - chunkScale / 2)
        bottom = (globals.chunk.worldY - chunkScale / 2)
        width = 2 * chunkScale
        height = 2 * chunkScale
        isBlinking = floor(time) % 2
        if isBlinking then
            gfx.drawRect left, bottom, width, height, color.red
        else
            gfx.drawRect left, bottom, width, height, color.yellow
        end if

		deltaTime = time - lastFrameTime
		lastFrameTime = time
		yield
	end while
end function


initialize

// The environment needs to be basically setup before a game can either be initialized or loaded.
newGame
// loadGame "save.json"

// Start the main loop.
main

// Before end of first iteration, the world state must be serializable.
// This is where we will save the game state.
saveGame "save.json"
