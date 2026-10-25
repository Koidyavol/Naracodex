extends Node2D

const COLS := 8
const ROWS := 6
const TILE_W := 88.0
const TILE_H := 44.0
const ORIGIN := Vector2(480.0, 115.0)

var units: Array[Dictionary] = []
var selected_id := -1
var phase := "player"
var message := "Pilih unit biru, lalu pilih petak tujuan."
var action_mode := "move"
var round_no := 1
var ui_font: Font

func _ready() -> void:
    ui_font = ThemeDB.fallback_font
    units = [
        {"id": 0, "name": "Astra", "team": "player", "pos": Vector2i(2, 3), "hp": 100, "max_hp": 100, "atk": 25, "move": 3, "alive": true},
        {"id": 1, "name": "Rin", "team": "player", "pos": Vector2i(1, 4), "hp": 80, "max_hp": 80, "atk": 18, "move": 3, "alive": true},
        {"id": 2, "name": "Slime", "team": "enemy", "pos": Vector2i(5, 2), "hp": 65, "max_hp": 65, "atk": 12, "move": 2, "alive": true},
        {"id": 3, "name": "Goblin", "team": "enemy", "pos": Vector2i(6, 4), "hp": 85, "max_hp": 85, "atk": 16, "move": 2, "alive": true}
    ]
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("#171c2a"))
    _draw_grid()
    _draw_units()
    _draw_hud()

func _tile_center(tile: Vector2i) -> Vector2:
    return ORIGIN + Vector2((tile.x - tile.y) * TILE_W * 0.5, (tile.x + tile.y) * TILE_H * 0.5)

func _draw_grid() -> void:
    for y in range(ROWS):
        for x in range(COLS):
            var p := _tile_center(Vector2i(x, y))
            var points := PackedVector2Array([
                p + Vector2(0, -TILE_H * 0.5),
                p + Vector2(TILE_W * 0.5, 0),
                p + Vector2(0, TILE_H * 0.5),
                p + Vector2(-TILE_W * 0.5, 0)
            ])
            var fill := Color("#28364a") if (x + y) % 2 == 0 else Color("#303f52")
            if selected_id >= 0:
                var u := _unit_by_id(selected_id)
                if u.size() > 0 and action_mode == "move" and _manhattan(u.pos, Vector2i(x, y)) <= u.move and _is_empty(Vector2i(x, y)):
                    fill = Color("#315c69")
            draw_colored_polygon(points, fill)
            for i in range(4):
                draw_line(points[i], points[(i + 1) % 4], Color("#52647b"), 1.5)

func _draw_units() -> void:
    for u in units:
        if not u.alive:
            continue
        var p := _tile_center(u.pos)
        var c := Color("#63b8ff") if u.team == "player" else Color("#ff7777")
        if u.id == selected_id:
            c = Color("#ffe17a")
            draw_circle(p + Vector2(0, 3), 25, Color(1, 0.86, 0.36, 0.2))
        # Simple placeholder tactical tokens; replace with sprites later.
        draw_circle(p + Vector2(0, 3), 18, Color("#101621"))
        draw_circle(p, 16, c)
        draw_string(ui_font, p + Vector2(-13, 5), u.name.substr(0, 1), HORIZONTAL_ALIGNMENT_CENTER, 26, 18, Color("#18202d"))
        draw_rect(Rect2(p + Vector2(-22, -29), Vector2(44, 5)), Color("#11151d"))
        draw_rect(Rect2(p + Vector2(-22, -29), Vector2(44.0 * float(u.hp) / float(u.max_hp), 5)), Color("#6de09a"))

func _draw_hud() -> void:
    draw_rect(Rect2(18, 18, 310, 90), Color("#202b3d"))
    draw_string(ui_font, Vector2(34, 45), "NARACODEX  •  ROUND %d" % round_no, HORIZONTAL_ALIGNMENT_LEFT, 290, 17, Color("#f2d99a"))
    draw_string(ui_font, Vector2(34, 70), "Phase: %s" % ("Pemain" if phase == "player" else "Musuh"), HORIZONTAL_ALIGNMENT_LEFT, 280, 16, Color.WHITE)
    draw_string(ui_font, Vector2(34, 92), message, HORIZONTAL_ALIGNMENT_LEFT, 900, 14, Color("#c9d5e7"))
    draw_rect(Rect2(18, 510, 924, 70), Color("#202b3d"))
    draw_string(ui_font, Vector2(34, 535), "Aksi: %s" % ("GERAK" if action_mode == "move" else "SERANG"), HORIZONTAL_ALIGNMENT_LEFT, 250, 16, Color("#f2d99a"))
    draw_string(ui_font, Vector2(34, 560), "Tap unit biru untuk memilih • Tombol M: gerak/serang • E: akhiri giliran", HORIZONTAL_ALIGNMENT_LEFT, 880, 15, Color.WHITE)
    var selected := _unit_by_id(selected_id)
    if selected.size() > 0:
        draw_string(ui_font, Vector2(650, 535), "%s  HP %d/%d  ATK %d" % [selected.name, selected.hp, selected.max_hp, selected.atk], HORIZONTAL_ALIGNMENT_LEFT, 270, 15, Color.WHITE)

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_M and phase == "player":
            action_mode = "attack" if action_mode == "move" else "move"
            message = "Pilih petak/unit target." if action_mode == "attack" else "Pilih petak tujuan."
            queue_redraw()
        elif event.keycode == KEY_E and phase == "player":
            _end_player_turn()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _handle_click(event.position)

func _handle_click(mouse_pos: Vector2) -> void:
    if phase != "player":
        return
    var tile := _tile_from_point(mouse_pos)
    if tile.x < 0:
        return
    var clicked_unit := _unit_at(tile)
    if selected_id == -1:
        if clicked_unit.size() > 0 and clicked_unit.team == "player":
            selected_id = clicked_unit.id
    elif action_mode == "attack":
        if clicked_unit.size() > 0 and clicked_unit.team == "enemy":
            _attack(selected_id, clicked_unit.id)
    elif clicked_unit.size() > 0 and clicked_unit.team == "player":
        selected_id = clicked_unit.id
    else:
        var u := _unit_by_id(selected_id)
        if u.size() > 0 and _is_empty(tile) and _manhattan(u.pos, tile) <= u.move:
            u.pos = tile
            message = "%s bergerak." % u.name
            action_mode = "attack"
        else:
            message = "Petak tidak valid atau di luar jangkauan."
    queue_redraw()
    if _all_team_dead("enemy"):
        message = "MENANG! Semua musuh dikalahkan."
        phase = "done"
        queue_redraw()

func _tile_from_point(point: Vector2) -> Vector2i:
    var best := Vector2i(-1, -1)
    var best_dist := 999999.0
    for y in range(ROWS):
        for x in range(COLS):
            var d := point.distance_to(_tile_center(Vector2i(x, y)))
            if d < best_dist:
                best_dist = d
                best = Vector2i(x, y)
    if best_dist <= 35.0:
        return best
    return Vector2i(-1, -1)

func _unit_at(tile: Vector2i) -> Dictionary:
    for u in units:
        if u.alive and u.pos == tile:
            return u
    return {}

func _unit_by_id(unit_id: int) -> Dictionary:
    for u in units:
        if u.id == unit_id and u.alive:
            return u
    return {}

func _is_empty(tile: Vector2i) -> bool:
    if tile.x < 0 or tile.x >= COLS or tile.y < 0 or tile.y >= ROWS:
        return false
    return _unit_at(tile).is_empty()

func _manhattan(a: Vector2i, b: Vector2i) -> int:
    return abs(a.x - b.x) + abs(a.y - b.y)

func _attack(attacker_id: int, target_id: int) -> void:
    var attacker := _unit_by_id(attacker_id)
    var target := _unit_by_id(target_id)
    if attacker.is_empty() or target.is_empty():
        return
    if _manhattan(attacker.pos, target.pos) > 1:
        message = "Target harus bersebelahan. Dekati musuh dulu."
        return
    target.hp = max(0, target.hp - attacker.atk)
    if target.hp == 0:
        target.alive = false
        message = "%s mengalahkan %s!" % [attacker.name, target.name]
    else:
        message = "%s menyerang %s (-%d HP)." % [attacker.name, target.name, attacker.atk]
    action_mode = "move"
    selected_id = -1
    queue_redraw()
    if _all_team_dead("enemy"):
        phase = "done"
        message = "MENANG! Semua musuh dikalahkan."
        queue_redraw()

func _end_player_turn() -> void:
    phase = "enemy"
    selected_id = -1
    action_mode = "move"
    message = "Musuh mengambil giliran..."
    queue_redraw()
    await get_tree().create_timer(0.35).timeout
    for enemy in units:
        if not enemy.alive or enemy.team != "enemy":
            continue
        var target := _nearest_player(enemy)
        if target.is_empty():
            continue
        if _manhattan(enemy.pos, target.pos) <= 1:
            target.hp = max(0, target.hp - enemy.atk)
            if target.hp == 0:
                target.alive = false
                message = "%s tumbang!" % target.name
        else:
            var next_tile := _step_toward(enemy.pos, target.pos)
            if _is_empty(next_tile):
                enemy.pos = next_tile
    if _all_team_dead("player"):
        phase = "done"
        message = "KALAH! Seluruh unit pemain tumbang."
    else:
        phase = "player"
        round_no += 1
        message = "Giliran pemain. Pilih unit biru."
    queue_redraw()

func _nearest_player(enemy: Dictionary) -> Dictionary:
    var best: Dictionary = {}
    var best_dist := 999
    for u in units:
        if u.alive and u.team == "player":
            var d := _manhattan(enemy.pos, u.pos)
            if d < best_dist:
                best_dist = d
                best = u
    return best

func _step_toward(from: Vector2i, to: Vector2i) -> Vector2i:
    var candidates := [from + Vector2i(1, 0), from + Vector2i(-1, 0), from + Vector2i(0, 1), from + Vector2i(0, -1)]
    var best := from
    var best_dist := _manhattan(from, to)
    for p in candidates:
        if p.x >= 0 and p.x < COLS and p.y >= 0 and p.y < ROWS and _is_empty(p):
            var d := _manhattan(p, to)
            if d < best_dist:
                best_dist = d
                best = p
    return best

func _all_team_dead(team: String) -> bool:
    for u in units:
        if u.alive and u.team == team:
            return false
    return true
