extends Area2D

signal shoot

export (PackedScene) var Bullet
export (int) var speed = 200
export (int) var health = 3

var follow
var target = null


func _ready():
	$Sprite.frame = randi() % 3
	var path = $EnemyPaths.get_children()[randi() % $EnemyPaths.get_child_count()]
	follow = PathFollow2D.new()
	path.add_child(follow)
	follow.loop = false
	$AnimationPlayer.play("rotate")
	

func _process(delta):
	follow.offset += speed * delta
	position = follow.global_position
	if follow.unit_offset >= 1:
		self.queue_free()


func shoot_pulse(n, delay):
	for i in range(n):
		shoot()
		yield(get_tree().create_timer(delay), 'timeout')


func shoot():
	var dir = target.global_position - global_position
	dir = dir.rotated(rand_range(-0.1, 0.1)).angle()
	emit_signal('shoot', Bullet, global_position, dir)


func take_damage(amount):
	health -= amount
	$AnimationPlayer.play("flash")
	if health <= 0:
		explode()
	yield($AnimationPlayer, 'animation_finished')
	$AnimationPlayer.play("rotate")


func explode():
	speed = 0
	$GunTimer.stop()
	$CollisionShape2D.disabled = true
	$Sprite.hide()
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	#$ExplodeSound.play()


func _on_AnimationPlayer_animation_finished(anim_name):
	self.queue_free()


func _on_GunTimer_timeout():
	shoot_pulse(3, 0.15)


func _on_Enemy_body_entered(body):
	if body.name == 'Player':
		pass
	explode()
