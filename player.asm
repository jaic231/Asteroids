.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Player
# =================================================================================================

.globl player_init
player_init:
enter
	# NOTE: this is unique to the player object. All other objects are made using
	# Object_new. it's just a special object.

	la t0, player
	# player.type = TYPE_PLAYER
	li t1, TYPE_PLAYER
	sw t1, Object_type(t0)

	# player.hw = PLAYER_HW, player.hh = PLAYER_HH
	li t1, PLAYER_HW
	sw t1, Object_hw(t0)
	li t1, PLAYER_HH
	sw t1, Object_hh(t0)

	# reset lives
	li t1, PLAYER_INIT_LIVES
	sw t1, player_lives

	# reset the rest
	jal player_respawn
leave

# ------------------------------------------------------------------------------
player_respawn:
enter
	la t0, player

	# player.x = player.y = 32.0
	li t1, 0x2000
	sw t1, Object_x(t0)
	sw t1, Object_y(t0)

	# player.vx = player.vy = 0
	sw zero, Object_vx(t0)
	sw zero, Object_vy(t0)

	# reset the other variables
	sw zero, player_iframes
	sw zero, player_fire_time
	sw zero, player_deadframes
	sw zero, player_angle
	sw zero, player_accel
	li t1, PLAYER_MAX_HEALTH
	sw t1, player_health
leave

# ------------------------------------------------------------------------------
.globl player_update
player_update:
enter
	lw t0, player_deadframes
	bnez, t0, _player_update_change_deadframes
	lw t0, player_fire_time
	ble t0, 0, _player_update_check_iframes
	dec t0
	sw t0, player_fire_time
_player_update_check_iframes:
	lw t0, player_iframes
	ble t0, 0, _player_update_continue
	dec t0
	sw t0, player_iframes
_player_update_continue:
	jal player_check_input
	jal player_update_thrust

	la a0, player
	li a1, PLAYER_DRAG
	jal Object_damp_velocity
	jal Object_accumulate_velocity
	li a1, PLAYER_MAX_POS
	li a2, PLAYER_MAX_POS
	jal Object_wrap_position
	j _player_update_return
_player_update_change_deadframes:
	lw t0, player_deadframes
	dec t0
	sw t0, player_deadframes
	bnez t0, _player_update_return
	lw t0, player_lives
	ble t0, 0, _player_update_lose
	jal player_respawn
	li t0, PLAYER_RESPAWN_IFRAMES
	sw t0, player_iframes
	j _player_update_return
_player_update_lose:
	jal lose_game
_player_update_return:
leave

# ------------------------------------------------------------------------------
.globl player_draw
player_draw:
enter
	# don't draw the player if they're dead.
	lw   t0, player_deadframes
	bnez t0, _player_draw_return

	# if they're invulnerable, draw them 4 frames on, 4 frames off.
	lw   t0, player_iframes
	beqz t0, _player_draw_doit
	lw   t0, frame_counter
	and  t0, t0, 4
	beqz t0, _player_draw_return

	_player_draw_doit:
		# there are 16 different directions in the rotation animation.
		# this chooses which frame to use based on the player's angle (0 = up, 90 = right)
		# a1 = spr_player[((player_angle + 11) % 360) / 23]
		lw  t0, player_angle
		add t0, t0, 11
		blt t0, 360, _player_draw_a_nowrap
			sub t0, t0, 360
		_player_draw_a_nowrap:
		div t0, t0, 23
		sll t0, t0, 2
		la  a1, spr_player
		add a1, a1, t0
		lw  a1, (a1)
		jal Object_blit_5x5_trans

	_player_draw_return:
leave

# ------------------------------------------------------------------------------
.globl player_check_input
player_check_input:
enter
	jal input_get_keys
_check_b:
	and t0, v0, KEY_B
	beq t0, 0, _check_u
	jal player_fire
_check_u:
	and t0, v0, KEY_U
	beq t0, 0, _player_accel_else
	li t1, 1
	sw t1, player_accel
	j _check_l
_player_accel_else:
	sw zero, player_accel
_check_l:
	and t0, v0, KEY_L
	beq t0, 0, _check_r
	lw t1, player_angle
	sub t1, t1, PLAYER_ANG_VEL
	sw t1, player_angle
	bge t1, 0, _check_r
	add t1, t1, 360
	sw t1, player_angle
_check_r:
	and t0, v0, KEY_R
	beq t0, 0, _check_input_end
	lw t1, player_angle
	add t1, t1, PLAYER_ANG_VEL
	sw t1, player_angle
	blt t1, 360, _check_input_end
	sub t1, t1, 360
	sw t1, player_angle
_check_input_end:
leave

# ------------------------------------------------------------------------------
.globl player_fire
player_fire:
enter
	la t0, player
	lw t1, player_fire_time
	bnez t1, _player_fire_end
	li t1, PLAYER_FIRE_DELAY
	sw t1, player_fire_time
	lw a0, Object_x(t0)
	lw a1, Object_y(t0)
	lw a2, player_angle
	jal bullet_new
_player_fire_end:
leave

# ------------------------------------------------------------------------------
.globl player_update_thrust
player_update_thrust:
enter
	lw t0, player_accel
	beqz t0, _update_thrust_end
	li a0, PLAYER_THRUST
	lw a1, player_angle
	jal to_cartesian
	la a0, player
	move a1, v0
	move a2, v1
	jal Object_apply_acceleration
_update_thrust_end:
leave

# ------------------------------------------------------------------------------
# void player_damage(int dmg)
#   can be called by other objects (like rocks) to damage the player.
#   the argument is how many points of damage to do.
.globl player_damage
player_damage:
enter
	lw t0, player_iframes
	bnez t0, _player_damage_exit
	lw t0, player_health
	sub t0, t0, a0
	maxi t0, t0, 0
	sw t0, player_health
	bnez t0, _player_damage_change_iframes
	la t0, player
	lw a0, Object_x(t0)
	lw a1, Object_y(t0)
	jal explosion_new
	lw t0, player_lives
	dec t0
	maxi t0, t0, 0
	sw t0, player_lives
	la t0, objects
	li t0, PLAYER_RESPAWN_TIME
	sw t0, player_deadframes
	j _player_damage_exit
_player_damage_change_iframes:
	li t0, PLAYER_HURT_IFRAMES
	sw t0, player_iframes
_player_damage_exit:
leave

# ------------------------------------------------------------------------------
# player_collide_all()
# checks if the player collides with anything.
# call the appropriate player-collision function on all active objects that have one.
.globl player_collide_all
player_collide_all:
enter s0, s1, s2
	# s0 = obj
	# s1 = i
	# s2 = collision function

	# start at objects[1]
	la s0, objects
	add s0, s0, Object_sizeof
	li s1, 1
_player_collide_all_loop:
		# don't collide if the player is invulnerable or dead.
		lw   t0, player_deadframes
		bnez t0, _player_collide_all_return
		lw   t0, player_iframes
		bnez t0, _player_collide_all_return

		# s2 = player_collide_funcs[obj.type]
		lw  s2, Object_type(s0)
		sll s2, s2, 2
		la  t0, player_collide_funcs
		add s2, s2, t0
		lw  s2, (s2)

		# skip objects without a collision function
		beq s2, 0, _player_collide_all_continue

		# if Objects_overlap(obj, player)
		move a0, s0
		la   a1, player
		jal  Objects_overlap
		beq  v0, 0, _player_collide_all_continue

			# OKAY, we hit the player
			# call the function (in s2) with the object as the argument
			move a0, s0
			jalr s2

_player_collide_all_continue:
	add s0, s0, Object_sizeof
	inc s1
	blt s1, MAX_OBJECTS, _player_collide_all_loop

_player_collide_all_return:
leave s0, s1, s2
