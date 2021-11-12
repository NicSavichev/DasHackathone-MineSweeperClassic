require daslib/media
//options debugger            // uncomment for debug in VS Code
//require daslib/debug        // uncomment for debug in VS Code
require textHlp

bitfield MinefieldCellFlags
    mined
    marked
    open

struct MinefieldCell
    flags: MinefieldCellFlags
    minesNear: uint = 0u

struct MinefieldSetup
    w, h, m: uint
    nm: string

let cFieldSetup = [[MinefieldSetup[4]
    [[MinefieldSetup w= 9u, h= 9u, m=10u, nm="F1: Beginner"]];
    [[MinefieldSetup w=16u, h=16u, m=40u, nm="F2: Intermediate"]];
    [[MinefieldSetup w=30u, h=20u, m=120u, nm="F3: Expert"]];
    [[MinefieldSetup w=40u, h=25u, m=200u, nm="F4: SuperExpert"]]
]]

class Minefield
    seed: int4
    w: uint = 0u
    h: uint = 0u
    mines: uint = 0u
    marksLeft: uint = 0u
    hiddenCellsLeft: uint = 0u
    gameOver: bool = false
    gameWon: bool = false
    gameTimeElapsed: float = 0.0
    clicksCount: uint = 0u
    selCell: int2 = int2(-1,-1)
    selType: int = 0
    headerTextScale: float = 1.0
    cells: array<MinefieldCell>

    cCellSize = float2(24,24)
    cSideMargin = 10.0
    cTopBarHt = 40.0
    cCountColor = [[uint[9] 0u; 0x0000FF; 0x008000; 0xFF0000; 0x000080; 0x800080; 0x808000; 0xFF00FF; 0xFFFF00]]
    imgCell <- create_image("cell.png")
    imgMine <- create_image("mine.png")
    imgFlag <- create_image("flag.png")

    def restartGameType(field_setup_idx: int)
        assert(field_setup_idx>=0 && field_setup_idx < length(cFieldSetup))
        let s = cFieldSetup[field_setup_idx]
        initField(s.w, s.h, s.m)

    def initField(wd, ht, mine_count: uint)
        randomize_seed(seed)
        w = wd
        h = ht
        mines = mine_count
        marksLeft = mines
        resize(cells, int(w*h))
        regenerate()

        set_font_name("sans")
        headerTextScale = 1.0-cSideMargin*2.0/cTopBarHt
        set_font_size(cTopBarHt*headerTextScale)
        let req_text_wd = get_text_size("Flags: {int(marksLeft)} Time: 3600 sec").x
        let avail_wd = getFieldScreenSize().x - cSideMargin*2.0
        if req_text_wd > avail_wd
            headerTextScale *= avail_wd/req_text_wd

    def cellIndexU(x, y: uint)
        assert(x >= 0u && y >= 0u && x < w && y < h)
        return y*w+x

    def cellIndex(x, y: int) { return cellIndexU(uint(x), uint(y)); }

    def getCell(x, y: int): MinefieldCell const { return cells[cellIndex(x,y)]; }

    def regenerate
        assert(w > 0u && h > 0u, "field size incorrect")
        // clear field
        for c in cells
            c.flags = bitfield(0)
            c.minesNear = 0u
        marksLeft = mines
        hiddenCellsLeft = w*h
        gameOver = false
        gameWon = false
        clicksCount = 0u
        gameTimeElapsed = 0.0

        // place mines
        var mines_left = mines
        while mines_left > 0u
            let x = uint(random_int(seed)) % w
            let y = uint(random_int(seed)) % h
            var c& = cells[cellIndexU(x,y)]
            if !c.flags.mined
                mines_left --
                c.flags |= MinefieldCellFlags mined
                for yc in range(y > 0u ? y-1u : 0u, min(y+2u,h))
                    for xc in range(x > 0u ? x-1u : 0u, min(x+2u,w))
                        cells[cellIndex(xc,yc)].minesNear ++
                //print("place mine at {x},{y} {c}\n")

        //for i in range(0,10)
        //    openCell(random_int(seed) % int(w), random_int(seed) % int(h))

    def getFieldScreenSize()
        return float2(cCellSize.x*float(w)+cSideMargin*2.0, cCellSize.x*float(h)+cSideMargin+cTopBarHt)

    def getCellPos(x, y: int)
        return float2(float(x)*cCellSize.x+cSideMargin, float(y)*cCellSize.y+cTopBarHt)

    def drawField(origin: float2)
        // draw hotkeys
        set_font_name("sans")
        set_font_size(20)
        var x : float = 5.0
        for s in cFieldSetup
            let cur_sel = s.w == w && s.h == h && s.m == mines
            x += 5.0+drawLabel([text =" {s.nm}: {int(s.w)}x{int(s.h)}, {int(s.m)} mines ", pos=float2(x, 5.0),
                force_text_ht=float(get_current_font_size()+6),
                text_color=cur_sel ? 0x0 : 0x000080, fill_color=cur_sel ? 0xFFFF00 : 0xB0B0B0, frame_color=0x000000, fill_back=true]).x

        drawLabel([text ="ENTER: restart game", pos=float2(5.0, float(get_screen_height()-5)), text_color=0x000080,
            fill_color=0xB0B0B0, fill_back=true,
            halign = TextAlignment left, valign=TextAlignment bottom])

        // draw game field panel
        let fieldSz = getFieldScreenSize()
        fill_rect(origin.x, origin.y, fieldSz.x, fieldSz.y, 0x808080)
        fill_rect(origin.x+cSideMargin, origin.y+cTopBarHt, fieldSz.x-cSideMargin*2.0, fieldSz.y-cSideMargin-cTopBarHt, 0xB0B0B0)
        set_font_size(cTopBarHt*headerTextScale)
        drawLabel([text ="Flags: {int(marksLeft)}", pos=float2(origin.x+cSideMargin, origin.y+cTopBarHt*0.5),
            text_color=0xFF0000, valign=TextAlignment center])
        drawLabel([text ="Time: {int(gameTimeElapsed)} sec", pos=float2(origin.x+fieldSz.x-cSideMargin, origin.y+cTopBarHt*0.5),
            text_color=0x0, halign = TextAlignment right, valign=TextAlignment center])
        drawLabel([text ="Hidden cells: {int(hiddenCellsLeft)}, clicks={int(clicksCount)}", pos=float2(get_screen_width()-5, get_screen_height()-5),
            text_color=0x0, halign = TextAlignment right, valign=TextAlignment bottom])

        // draw grid
        let wf = float(w)*cCellSize.x
        let hf = float(h)*cCellSize.y
        for x in range(0u, w)
            let pos = getCellPos(x, 0)+origin
            line(pos.x, pos.y, pos.x, pos.y+hf, 0x818181)
        for y in range(0u, h)
            let pos = getCellPos(0, y)+origin
            line(pos.x, pos.y, pos.x+wf, pos.y, 0x818181)

        // draw cells
        set_font_name("sans")
        set_font_size(int(cCellSize.y)*2/3)
        let text_ofs = (cCellSize - get_text_size("0"))*0.5
        enable_alpha_blend()
        for y in range(0u, h)
            for x in range(0u, w)
                let c = getCell(x, y)
                let pos = getCellPos(x, y)+origin
                if !gameOver && selCell.x == x && selCell.y == y
                    if !c.flags.open
                        if selType == 2
                            imgFlag |> draw_image(pos.x, pos.y, 0x80ffffff, cCellSize)
                        continue

                if gameOver && (c.flags.mined || c.flags.marked)
                    if c.flags.mined && c.flags.marked
                        imgCell |> draw_image(pos.x, pos.y, 0xffffffff, cCellSize)
                        imgFlag |> draw_image(pos.x, pos.y, 0xffffffff, cCellSize)
                    else
                        imgMine |> draw_image(pos.x, pos.y, 0xffffffff, cCellSize)
                        if !c.flags.mined
                            line(pos.x, pos.y, pos.x+cCellSize.x, pos.y+cCellSize.y, 0xFFFF0000)
                            line(pos.x, pos.y+cCellSize.y, pos.x+cCellSize.x, pos.y, 0xFFFF0000)
                elif !c.flags.open
                    imgCell |> draw_image(pos.x, pos.y, 0xffffffff, cCellSize)
                    if c.flags.marked
                        imgFlag |> draw_image(pos.x, pos.y, 0xffffffff, cCellSize)
                elif c.flags.mined
                    imgMine |> draw_image(pos.x, pos.y, 0xffffffff, cCellSize)
                elif c.minesNear > 0u
                    text_out(pos.x+text_ofs.x, pos.y+text_ofs.y, "{int(c.minesNear)}", cCountColor[c.minesNear]|0xFF000000)
        if gameOver
            if gameWon
                set_font_size(60)
                drawLabel([text =" You have won! Congratulations!!! ", pos=float2(get_screen_width()/2, get_screen_height()/2),
                    text_color=0xC0FF4000, fill_color=0x20C0C000, frame_color=0x0, fill_back=true,
                    halign = TextAlignment center, valign=TextAlignment center])
            else
                fill_rect(origin.x+cSideMargin, origin.y+cTopBarHt, fieldSz.x-cSideMargin*2.0, fieldSz.y-cSideMargin-cTopBarHt, 0x40FF0000)
        disable_alpha_blend()

    def selectCellByMouse(mpos: float2; btn: int)
        let cpos = int2((mpos-getCellPos(0,0))/cCellSize)
        if cpos.x < 0 || cpos.x >= int(w) || cpos.y < 0 || cpos.y >= int(h)
            selCell = int2(-1,-1)
            return
        selCell = cpos
        selType |= btn

    def finalizeSelection()
        if selCell == int2(-1,-1) || selType == 0
            return
        var c& = cells[cellIndex(selCell.x, selCell.y)]
        if selType == 1 && !c.flags.open && !c.flags.marked // open cell
            openCell(selCell.x, selCell.y)

        elif selType == 2 && !c.flags.open && marksLeft > 0u // mark cell
            marksLeft += c.flags.marked ? 1u : -1u
            c.flags ^= MinefieldCellFlags marked;

        elif selType == 3 && c.flags.open // open "safe" cells around
            var num_marked: uint = 0u
            for yc in range(max(selCell.y-1, 0), min(selCell.y+2,int(h)))
                for xc in range(max(selCell.x-1, 0), min(selCell.x+2,int(w)))
                    if getCell(xc, yc).flags.marked
                        num_marked ++
            if num_marked == c.minesNear
                for yc in range(max(selCell.y-1, 0), min(selCell.y+2,int(h)))
                    for xc in range(max(selCell.x-1, 0), min(selCell.x+2,int(w)))
                        let flags = getCell(xc, yc).flags
                        if !flags.open && !flags.marked
                            openCell(xc, yc)
        clicksCount ++

    finally
        selType = 0
        selCell = int2(-1,-1)

    def private openCell(x, y: int)
        var c& = cells[cellIndex(x,y)]
        c.flags |= MinefieldCellFlags open;
        hiddenCellsLeft --
        if c.flags.mined
            gameOver = true
        elif c.minesNear == 0u
            for yc in range(max(y-1, 0), min(y+2,int(h)))
                for xc in range(max(x-1, 0), min(x+2,int(w)))
                    if !getCell(xc, yc).flags.open
                        openCell(xc, yc)


var field = new Minefield()

// 'initialize' runs once when game starts and every hot-reload
[export]
def initialize
    set_window_title("MineSweeperClassic")
    field->restartGameType(2)
    return

// this function is called to update game data,
// dt - time elapsed since the previous update (in seconds)
[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()

    if get_key(VK_RETURN)
        field->regenerate()
    if get_key(VK_F1)
        field->restartGameType(0)
    if get_key(VK_F2)
        field->restartGameType(1)
    if get_key(VK_F3)
        field->restartGameType(2)
    if get_key(VK_F4)
        field->restartGameType(3)

    if field.gameOver
        return
    if field.hiddenCellsLeft == field.mines
        field.gameWon = true
        field.gameOver = true
        for c in field.cells
            if !c.flags.open && !c.flags.marked
                c.flags |= MinefieldCellFlags marked;
                field.marksLeft --
        return

    if field.clicksCount > 0u
        field.gameTimeElapsed += dt

    let field_origin = (float2(get_screen_width(), get_screen_height())-field->getFieldScreenSize())*0.5
    if get_mouse_button(MB_LEFT)
        field->selectCellByMouse(get_mouse_position()-field_origin, 1)
    if get_mouse_button(MB_RIGHT)
        field->selectCellByMouse(get_mouse_position()-field_origin, 2)
    if !get_mouse_button(MB_LEFT) && !get_mouse_button(MB_RIGHT) && field.selType != 0
        field->selectCellByMouse(get_mouse_position()-field_origin, 0)
        field->finalizeSelection()
    return

// this function will be called every frame after 'act',
// you can draw anything in this function
[export]
def draw
    fill_rect(0, 0, get_screen_width(), get_screen_height(), 0x404040)
    field->drawField((float2(get_screen_width(), get_screen_height())-field->getFieldScreenSize())*0.5)
    return
