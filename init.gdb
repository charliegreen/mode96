# INIT GDB

display/6i $pc-2
# break main
# break sub_video_mode96_entry
# break begin_code_tile_row
# break begin_code_tile_row_bkpt
break render_scanline

continue