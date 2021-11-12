require daslib/media

enum TextAlignment
    top
    bottom
    left
    right
    center

def drawLabel(text: string; pos: float2; force_text_ht=-1.0;
              text_color: uint; fill_color=0u; frame_color=0u;
              fill_back=false; halign = TextAlignment left; valign=TextAlignment top)
    var eff_pos = pos;
    var sz = get_text_size(text) + float2(2,2)
    if force_text_ht > 0.0
        sz.y = force_text_ht

    if halign == TextAlignment right
        eff_pos.x -= sz.x
    elif halign == TextAlignment center
        eff_pos.x -= sz.x*0.5
    else
        assert(halign == TextAlignment left)
    if valign == TextAlignment bottom
        eff_pos.y -= sz.y
    elif valign == TextAlignment center
        eff_pos.y -= sz.y*0.5
    else
        assert(valign == TextAlignment top)

    if fill_back
        fill_rect(eff_pos.x, eff_pos.y, sz.x+2.0, sz.y+2.0, frame_color)
        fill_rect(eff_pos.x+1.0, eff_pos.y+1.0, sz.x, sz.y, fill_color)
    text_out(eff_pos.x+1.0, eff_pos.y+1.0, text, text_color)
    return sz
