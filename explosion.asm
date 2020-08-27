.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Explosions
# =================================================================================================

# void explosion_new(x, y)
.globl explosion_new
explosion_new:
enter s0, s1
    move s0, a0
    move s1, a1
    li a0, TYPE_EXPLOSION
    jal Object_new
    sw s0, Object_x(v0)
    sw s1, Object_y(v0)
    li t0, EXPLOSION_HW
    sw t0, Object_hw(v0)
    li t0, EXPLOSION_HH
    sw t0, Object_hh(v0)
    li t0 EXPLOSION_ANIM_DELAY
    sw t0, Explosion_timer(v0)
    sw zero Explosion_frame(v0)
leave s0, s1

# ------------------------------------------------------------------------------

.globl explosion_update
explosion_update:
enter
    lw t0, Explosion_timer(a0)
    dec t0
    sw t0, Explosion_timer(a0)
    bnez t0, _explosion_update_return
    li t0, EXPLOSION_ANIM_DELAY
    sw t0, Explosion_timer(a0)
    lw t0, Explosion_frame(a0)
    inc t0
    sw t0, Explosion_frame(a0)
    blt t0, 6, _explosion_update_return
    jal Object_delete
_explosion_update_return:
leave

# ------------------------------------------------------------------------------

.globl explosion_draw
explosion_draw:
enter
    la t0, spr_explosion_frames
    lw t1, Explosion_frame(a0)
    mul t1, t1, 4
    add t0, t0, t1
    lw a1, (t0)
    jal Object_blit_5x5_trans
leave
