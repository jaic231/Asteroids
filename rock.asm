.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Rocks
# =================================================================================================

.globl rocks_count
rocks_count:
enter
	la t0, objects
	li t1, 0
	li v0, 0

	_rocks_count_loop:
		lw t2, Object_type(t0)
		beq t2, TYPE_ROCK_L, _rocks_count_yes
		beq t2, TYPE_ROCK_M, _rocks_count_yes
		bne t2, TYPE_ROCK_S, _rocks_count_continue
		_rocks_count_yes:
			inc v0
	_rocks_count_continue:
	add t0, t0, Object_sizeof
	inc t1
	blt t1, MAX_OBJECTS, _rocks_count_loop
leave

# ------------------------------------------------------------------------------

# void rocks_init(int num_rocks)
.globl rocks_init
rocks_init:
enter s0, s1, s2
	move s0, a0
	li s1, 0
_rocks_init_loop:
	li a0, 0x2000
	jal random
	add v0, v0, 0x3000
	li t0, 0x4000
	div v0, t0
	mfhi s2
	li a0, 0x2000
	jal random
	add v0, v0, 0x3000
	li t0, 0x4000
	div v0, t0
	mfhi a1
	move a0, s2
	li a2, TYPE_ROCK_L
	jal rock_new
	inc s1
	blt s1, s0, _rocks_init_loop
leave s0, s1, s2

# ------------------------------------------------------------------------------

# void rock_new(x, y, type)
rock_new:
enter s0, s1, s2, s3
	move s0, a0
	move s1, a1
	move s2, a2
	move a0, s2
	jal Object_new
	move s3, v0
	sw s0, Object_x(s3)
	sw s1, Object_y(s3)
	beq s2, TYPE_ROCK_S, _rock_new_s
	beq s2, TYPE_ROCK_M, _rock_new_m

	li t0, ROCK_L_HW
	sw t0, Object_hw(s3)
	li t0, ROCK_L_HH
	sw t0, Object_hh(s3)
	j _rock_new_random_angle
_rock_new_m:
	li t0, ROCK_M_HW
	sw t0, Object_hw(s3)
	li t0, ROCK_M_HH
	sw t0, Object_hh(s3)
	j _rock_new_random_angle
_rock_new_s:
	li t0, ROCK_S_HW
	sw t0, Object_hw(s3)
	li t0, ROCK_S_HH
	sw t0, Object_hh(s3)
	j _rock_new_random_angle
_rock_new_random_angle:
	li a0, 360
	jal random
	move a1, v0
	li a0, ROCK_VEL
	beq s2, TYPE_ROCK_S, _rock_new_s_vel
	beq s2, TYPE_ROCK_M, _rock_new_m_vel
	j _rock_new_get_cartesian
_rock_new_s_vel:
	mul a0, a0, 12
	j _rock_new_get_cartesian
_rock_new_m_vel:
	mul a0, a0, 4
_rock_new_get_cartesian:
	jal to_cartesian
	sw v0, Object_vx(s3)
	sw v1, Object_vy(s3)
leave s0, s1, s2, s3

# ------------------------------------------------------------------------------

.globl rock_update
rock_update:
enter
	jal Object_accumulate_velocity
	jal Object_wrap_position
	jal rock_collide_with_bullets
leave

# ------------------------------------------------------------------------------

rock_collide_with_bullets:
enter s0, s1, s2
	la s0, objects
	li s1, 0
	move s2, a0
_rock_collide_with_bullets_loop:
	lw t0, Object_type(s0)
	bne t0, TYPE_BULLET, _next_object
	move a0, s2
	lw a1, Object_x(s0)
	lw a2, Object_y(s0)
	jal Object_contains_point
	beqz v0, _next_object
	move a0, s2
	jal rock_get_hit
	move a0, s0
	jal Object_delete
_next_object:
	add s0, s0, Object_sizeof
	inc s1
	blt s1, MAX_OBJECTS, _rock_collide_with_bullets_loop
_rock_collide_with_bullets_exit:
leave s0, s1, s2

# ------------------------------------------------------------------------------

rock_get_hit:
enter s0, s1, s2, s3
	move s0, a0
	lw t0, Object_type(s0)
	lw s1, Object_x(s0)
	lw s2, Object_y(s0)
	beq t0, TYPE_ROCK_L, _rock_get_hit_large
	beq t0, TYPE_ROCK_M, _rock_get_hit_medium
	j _rock_get_hit_delete
_rock_get_hit_large:
	li s3, TYPE_ROCK_M
	j _rock_get_hit_split
_rock_get_hit_medium:
	li s3, TYPE_ROCK_S
_rock_get_hit_split:
	move a0, s1
	move a1, s2
	move a2, s3
	jal rock_new
	move a0, s1
	move a1, s2
	move a2, s3
	jal rock_new
_rock_get_hit_delete:
	move a0, s1
	move a1, s2
	jal explosion_new
	move a0, s0
	jal Object_delete
leave s0, s1, s2, s3

# ------------------------------------------------------------------------------

.globl rock_collide_l
rock_collide_l:
enter
	jal rock_get_hit
	li a0, 3
	jal player_damage
leave

# ------------------------------------------------------------------------------

.globl rock_collide_m
rock_collide_m:
enter
	jal rock_get_hit
	li a0, 2
	jal player_damage
leave

# ------------------------------------------------------------------------------

.globl rock_collide_s
rock_collide_s:
enter
	jal rock_get_hit
	li a0, 1
	jal player_damage
leave

# ------------------------------------------------------------------------------

.globl rock_draw_l
rock_draw_l:
enter
	la a1, spr_rock_l
	jal Object_blit_5x5_trans
leave

# ------------------------------------------------------------------------------

.globl rock_draw_m
rock_draw_m:
enter
	la a1, spr_rock_m
	jal Object_blit_5x5_trans
leave

# ------------------------------------------------------------------------------

.globl rock_draw_s
rock_draw_s:
enter
	la a1, spr_rock_s
	jal Object_blit_5x5_trans
leave
