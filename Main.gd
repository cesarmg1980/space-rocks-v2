extends Node

export (PackedScene) var Rock
export (PackedScene) var Enemy

const ROCK_SIZE_BIG = 3

var screensize = Vector2()
var level = 0
var playing = false
var number_of_rocks_on_level = 0
var scoring_for_rocks = {3: 10, 2: 20, 1: 30}
var scoring_for_enemies = 50

signal update_score


func new_game():
	$GameMusic.play()
	for rock in $Rocks.get_children():
		rock.queue_free()
	level = 0
	$Hud.update_score(0)
	$Player.start()
	$Hud.show_message("Get Ready!")
	yield($Hud/MessageTimer, "timeout")
	playing = true
	new_level()


func new_level():
	level += 1
	for rock in $Rocks.get_children():
		rock.queue_free()
	$Hud.show_message("Wave %s" % level)
	for i in range(level):
		spawn_rock(ROCK_SIZE_BIG)
		number_of_rocks_on_level += 1
	$EnemyTimer.wait_time = rand_range(5, 10)
	$EnemyTimer.start()


func game_over():
	playing = false
	$Hud.game_over()
	$GameMusic.stop()


func _process(delta):
	self.connect("update_score", get_node("Hud"), "update_score")
	if playing and $Rocks.get_child_count() == 0:
		new_level()


func _ready():
	randomize()
	screensize = get_viewport().get_visible_rect().size
	$Player.screensize = screensize


func spawn_rock(size, pos=null, vel=null):
	if !pos:
		$RockPath/RockSpawn.set_offset(randi())
		pos = $RockPath/RockSpawn.position
	if !vel:
		vel = Vector2(1, 0).rotated(
			rand_range(0, 2*PI)) * rand_range(100,150)
	var r = Rock.instance()
	r.screensize = screensize
	r.start(pos, vel, size)
	$Rocks.add_child(r)
	r.connect('exploded', self, '_on_Rock_exploded')


func _on_Player_shoot(bullet, pos, dir):
	var b = bullet.instance()
	b.start(pos, dir)
	add_child(b)


func _on_Rock_exploded(size, radius, pos, vel):
	emit_signal("update_score", scoring_for_rocks.get(size))
	if size <= 1:
		return
	for offset in [-1, 1]:
		var dir = (pos - $Player.position).normalized().tangent() * offset
		var newpos = pos + dir * radius
		var newvel = dir * vel.length() * 1.1
		spawn_rock(size - 1, newpos, newvel)
	
	

func _input(event):
	if event.is_action_pressed("pause"):
		if not playing:
			return
		get_tree().paused = not get_tree().paused
	if get_tree().paused:
		$Hud/MessageLabel.text = "Paused"
		$Hud/MessageLabel.show()
	else:
		$Hud/MessageLabel.text = ""
		$Hud/MessageLabel.hide()


func _on_EnemyTimer_timeout():
	var e = Enemy.instance()
	add_child(e)
	e.target = $Player
	e.connect('shoot', self, '_on_Player_shoot')
	e.connect("destroyed", self, "_on_enemy_destroyed")
	$EnemyTimer.wait_time = rand_range(20, 40)
	$EnemyTimer.start()

func _on_enemy_destroyed():
	emit_signal("update_score", scoring_for_enemies)
