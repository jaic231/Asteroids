.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Bullet
# =================================================================================================

# void bullet_new(x: a0, y: a1, angle: a2)
.globl bullet_new
bullet_new:
enter s0, s1, s2
    move s0, a0 #s0 = x
    move s1, a1 #s1 = y
    move s2, a2 #s2 = angle
    li a0, TYPE_BULLET
    jal Object_new
    move t0, v0 #t0 = address of bullet
    beqz t0, _bullet_new_break
    sw s0, Object_x(t0) #save x value of bullet
    sw s1, Object_y(t0) #" y "
    move s0, t0 #s0 = address of bullet
    li t0, BULLET_LIFE
    sw t0, Bullet_frame(s0)
    li a0, BULLET_THRUST
    move a1, s2
    jal to_cartesian
    sw v0, Object_vx(s0)
    sw v1, Object_vy(s0)
_bullet_new_break:
leave s0, s1, s2

# ------------------------------------------------------------------------------

.globl bullet_update
bullet_update:
enter s0
    move s0, a0
    lw t0, Bullet_frame(s0)
    sub t0, t0, 1
    sw t0, Bullet_frame(s0)
    beqz t0, _bullet_delete
    jal Object_accumulate_velocity
    move a0, s0
    jal Object_wrap_position
    j _bullet_update_end
_bullet_delete:
    move a0, s0
    jal Object_delete
_bullet_update_end:
leave s0

# ------------------------------------------------------------------------------

.globl bullet_draw
bullet_draw:
enter
    lw t0, Object_x(a0)
    lw a1, Object_y(a0)
    li a2, COLOR_RED
    sra a0, t0, 8
    sra a1, a1, 8
    jal display_set_pixel
leave
