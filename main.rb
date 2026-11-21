require 'gosu'

class TicTacToeWindow < Gosu::Window

  WIDTH  = 750
  HEIGHT = 500

  GRID_X = 236
  GRID_Y = 99
  CELL_W = 97
  CELL_H = 95
  PIECE_SIZE = 64.0

  WINS_TO_FINISH = 3
  END_DELAY      = 80
  WIN_LINES = [[0,1,2], [3,4,5], [6,7,8], [0,3,6], [1,4,7], [2,5,8], [0,4,8], [2,4,6]]

  LEVELS = [
    { key: :easy,   label: "EASY",   y: 150, color: Gosu::Color.rgb(0, 200, 0) },
    { key: :medium, label: "MEDIUM", y: 260, color: Gosu::Color.rgb(255, 200, 0) },
    { key: :hard,   label: "HARD",   y: 370, color: Gosu::Color.rgb(200, 0, 0) }
  ]
  LEVEL_BTN_X = 225
  LEVEL_BTN_W = 300
  LEVEL_BTN_H = 70

  TITLE_MUSIC_FILE = "music_title.mp3"
  GAME_MUSIC_FILE  = "music_game.mp3"
  MUSIC_VOLUME     = 0.5
  MUSIC_TALK_VOLUME = 0.1
  MUSIC_FADE_STEP  = 0.03

  MENU_SPONGEBOB_GROUND_Y = 385

  BACK_BTN = [10, 5, 95, 35]

  TALKER_IMAGE = "krabs.png"
  TALK_LINES = [
    "Ahoy, me boy! That Plankton be after me secret formula, and ye have to stop him!",
    "First, pick a level. Easy, Medium or Hard. That Plankton gets sneakier on Hard!",
    "Click a square to place yer piece. Get three in a row to win the round!",
    "Win #{WINS_TO_FINISH} rounds to finish the level. Now get to it, me boy, time is money!"
  ]
  TALK_SPEED = 0.5
  BUBBLE   = [265, 75, 460, 205]
  SKIP_BTN = [640, 455, 95, 35]
  TALK_TEXT_COLOR = Gosu::Color.rgb(60, 35, 10)

  TEXT_SIZES = { title: 70, big: 50, small: 30, tiny: 24 }
  OUTLINE_BROWN = Gosu::Color.rgb(95, 50, 10)
  TEXT_SHADOW   = Gosu::Color.rgba(0, 0, 0, 110)
  OUTLINE_DARK  = Gosu::Color.rgb(25, 25, 50)

  SPONGE_TINTS = {
    yellow: nil, green:  [90, 215, 80], red:    [240, 75, 65],
    orange: [255, 160, 45], white:  [250, 250, 240]
  }
  RESULT_COLORS = {
    green:  Gosu::Color.rgb(60, 190, 90), red:    Gosu::Color.rgb(220, 60, 55),
    blue:   Gosu::Color.rgb(70, 150, 230), orange: Gosu::Color.rgb(240, 150, 40)
  }
  RESULT_CARD_ALPHA = 140
  RESULT_DIM_ALPHA  = 40
  OUTLINE_OFFSETS = [[3,0],[-3,0],[0,3],[0,-3],[2,2],[-2,2],[2,-2],[-2,-2],
                     [3,1],[3,-1],[-3,1],[-3,-1],[1,3],[-1,3],[1,-3],[-1,-3]]

  def initialize
    super WIDTH, HEIGHT
    self.caption = "SpongeBob Tic-Tac-Toe"

    if File.exist?("spongeboy.ttf")
      @font_name = "spongeboy.ttf"
      @title_font = Gosu::Font.new(70, name: "spongeboy.ttf")
      @font = Gosu::Font.new(50, name: "spongeboy.ttf")
      @small_font = Gosu::Font.new(30, name: "spongeboy.ttf")
      @tiny_font = Gosu::Font.new(24, name: "spongeboy.ttf")
    else
      @font_name = Gosu.default_font_name
      @title_font = Gosu::Font.new(70, bold: true)
      @font = Gosu::Font.new(50, bold: true)
      @small_font = Gosu::Font.new(30)
      @tiny_font = Gosu::Font.new(24)
    end

    @sponge_tex = build_sponge_texture
    @sponge_cache = {}

    @bg_image = load_image("bg.jpg")
    @spongebob_img = load_image("spongebob.png")

    @talker_img = load_image(TALKER_IMAGE) || @spongebob_img

    @win_img = load_image("win.jpg")
    @lose_img = load_image("lose.jpg")
    @draw_img = load_image("draw.jpg")
    @todo_img = load_image("todo.jpg")
    @title_logo = load_image("title.png")
    @start_btn = load_image("start.png")
    @game_bg = load_image("game_bg.png")

    @patty_img = load_image("patty.png")
    @spatula_img = load_image("spatula.png")
    @lifering_img = load_image("lifering.png")
    @bones_img = load_image("bones.png")

    @x_pool = [@spatula_img, @bones_img].compact
    @o_pool = [@lifering_img, @patty_img].compact

    @pop_snd  = load_sample("pop.wav")
    @win_snd  = load_sample("win.wav")
    @lose_snd = load_sample("lose.wav")
    @draw_snd = load_sample("draw.wav")

    @talk_snds = [
      load_sample("talk1.wav"),
      load_sample("talk2.wav"),
      load_sample("talk3.wav"),
      load_sample("talk4.wav")
    ]

    @title_music = load_song(TITLE_MUSIC_FILE)
    @game_music  = load_song(GAME_MUSIC_FILE)
    @current_music = nil
    @music_volume = MUSIC_VOLUME

    @state = :menu
    @global_timer = 0

    @talk_index = 0
    @talk_chars = 0.0
    @talk_total = 1
    @talk_wrapped = []
    @talk_instance = nil

    @total_wins = 0
    @total_losses = 0
    @total_draws = 0

    @level = :easy
    @level_wins = 0

    reset_game
  end

  def needs_cursor?
    true
  end

  def load_image(filename)
    begin
      return Gosu::Image.new(filename)
    rescue
      puts "WARNING: Could not find #{filename}."
      return nil
    end
  end

  def load_sample(filename)
    return nil unless File.exist?(filename)
    Gosu::Sample.new(filename)
  rescue
    nil
  end

  def load_song(filename)
    return nil unless File.exist?(filename)
    Gosu::Song.new(filename)
  rescue
    nil
  end

  def play(sound)
    sound.play if sound
  end

  def play_end_sound(sound)
    stop_end_sound
    @end_channel = sound.play if sound
  end

  def stop_end_sound
    @end_channel.stop if @end_channel
    @end_channel = nil
  end

  def clamp_byte(v)
    v = v.to_i
    v < 0 ? 0 : (v > 255 ? 255 : v)
  end

  def build_sponge_texture
    w = 96
    h = 96
    rng = Random.new(7)
    px = Array.new(w * h * 4, 255)

    h.times do |y|
      w.times do |x|
        n = rng.rand(-10..10)
        i = (y * w + x) * 4
        px[i]     = clamp_byte(250 + n)
        px[i + 1] = clamp_byte(212 + n)
        px[i + 2] = clamp_byte(40 + n / 2)
        px[i + 3] = 255
      end
    end

    28.times do
      cx = rng.rand(w)
      cy = rng.rand(h)
      r = rng.rand(3.0..7.0)
      reach = r.ceil + 1
      (-reach..reach).each do |dy|
        (-reach..reach).each do |dx|
          d = Math.hypot(dx, dy)
          next if d > r
          i = (((cy + dy) % h) * w + ((cx + dx) % w)) * 4
          depth = 1.0 - d / r
          if d / r > 0.8
            px[i]     = clamp_byte(px[i] * 0.5 + 255 * 0.5)
            px[i + 1] = clamp_byte(px[i + 1] * 0.5 + 240 * 0.5)
            px[i + 2] = clamp_byte(px[i + 2] * 0.5 + 130 * 0.5)
          else
            b = [depth**0.5 * 0.85, 1.0].min
            px[i]     = clamp_byte(px[i] * (1 - b) + 175 * b)
            px[i + 1] = clamp_byte(px[i + 1] * (1 - b) + 120 * b)
            px[i + 2] = clamp_byte(px[i + 2] * (1 - b) + 10 * b)
          end
        end
      end
    end

    { w: w, h: h, px: px }
  end

  def sponge_pixels(src, w, h, tint = :yellow)
    tint_rgb = SPONGE_TINTS[tint]
    tex = @sponge_tex
    tw = tex[:w]
    th = tex[:h]
    tpx = tex[:px]
    out = Array.new(w * h * 4, 0)

    h.times do |y|
      shade = 1.12 - 0.30 * (y.to_f / h)
      row = (y % th) * tw
      w.times do |x|
        i = (y * w + x) * 4
        a = src[i + 3]
        next if a == 0
        ti = (row + (x % tw)) * 4
        if tint_rgb
          lum = (tpx[ti] * 0.30 + tpx[ti + 1] * 0.59 + tpx[ti + 2] * 0.11) / 205.0
          out[i]     = clamp_byte(tint_rgb[0] * lum * shade)
          out[i + 1] = clamp_byte(tint_rgb[1] * lum * shade)
          out[i + 2] = clamp_byte(tint_rgb[2] * lum * shade)
        else
          out[i]     = clamp_byte(tpx[ti] * shade)
          out[i + 1] = clamp_byte(tpx[ti + 1] * shade)
          out[i + 2] = clamp_byte(tpx[ti + 2] * shade)
        end
        out[i + 3] = a
      end
    end

    out.pack("C*")
  end

  def build_sponge_text(text, line_height, tint = :yellow)
    mask = Gosu::Image.from_text(text, line_height, font: @font_name)
    w = mask.width
    h = mask.height
    packed = sponge_pixels(mask.to_blob.bytes, w, h, tint)
    { mask: mask, tex: Gosu::Image.from_blob(w, h, packed), w: w, h: h }
  end

  def sponge_entry(text, size, tint = :yellow)
    key = [text, size, tint]
    return @sponge_cache[key] if @sponge_cache.key?(key)
    @sponge_cache[key] = begin
      build_sponge_text(text, TEXT_SIZES[size], tint)
    rescue => e
      puts "WARNING: sponge text failed (#{e.message}), using plain text."
      nil
    end
  end

  def plain_font(size)
    { title: @title_font, big: @font, small: @small_font, tiny: @tiny_font }[size]
  end

  def sponge_width(text, size, tint = :yellow)
    e = sponge_entry(text, size, tint)
    e ? e[:w] : plain_font(size).text_width(text)
  end

  def sponge_text(text, x, y, z, size = :small, outline = OUTLINE_BROWN, tint = :yellow)
    e = sponge_entry(text, size, tint)
    if e
      e[:mask].draw(x + 4, y + 5, z, 1.0, 1.0, TEXT_SHADOW)
      OUTLINE_OFFSETS.each { |dx, dy| e[:mask].draw(x + dx, y + dy, z, 1.0, 1.0, outline) }
      e[:tex].draw(x, y, z + 0.01)
    else
      plain_font(size).draw_text(text, x, y, z, 1.0, 1.0, Gosu::Color::WHITE)
    end
  end

  def sponge_text_centered(text, center_x, y, z, size = :small, outline = OUTLINE_BROWN, tint = :yellow)
    sponge_text(text, center_x - sponge_width(text, size, tint) / 2.0, y, z, size, outline, tint)
  end

  def plain_width(text, size)
    plain_font(size).text_width(text)
  end

  def plain_text(text, x, y, z, size = :small, color = Gosu::Color::WHITE)
    font = plain_font(size)
    [[-2, 0], [2, 0], [0, -2], [0, 2], [2, 2], [-2, -2], [2, -2], [-2, 2]].each do |dx, dy|
      font.draw_text(text, x + dx, y + dy, z, 1.0, 1.0, OUTLINE_DARK)
    end
    font.draw_text(text, x, y, z + 0.01, 1.0, 1.0, color)
  end

  def plain_text_centered(text, center_x, y, z, size = :small, color = Gosu::Color::WHITE)
    plain_text(text, center_x - plain_width(text, size) / 2.0, y, z, size, color)
  end

  def reset_game
    stop_end_sound
    @board = ["", "", "", "", "", "", "", "", ""]
    @board_images = Array.new(9, nil)
    @turn = "X"
    @computer_timer = 0
    @animations = Array.new(9, 0)
    @win_line = nil
    @result = nil
    @end_timer = 0
    @level_cleared = false

    @x_piece = @x_pool.sample
    @o_piece = @o_pool.sample
  end

  def start_game(level)
    @level = level
    @level_wins = 0
    reset_game
    @state = :playing
  end

  def music_for_state
    case @state
    when :menu, :todo, :level_select then @title_music
    else @game_music
    end
  end

  def update_music
    wanted = music_for_state
    unless wanted.equal?(@current_music)
      @current_music = wanted
      if wanted
        wanted.volume = @music_volume
        wanted.play(true)
      else
        Gosu::Song.current_song.stop if Gosu::Song.current_song
      end
    end

    return unless @current_music
    target = music_target_volume
    diff = target - @music_volume
    if diff.abs > 0.001
      @music_volume += [[diff, MUSIC_FADE_STEP].min, -MUSIC_FADE_STEP].max
      @current_music.volume = @music_volume
    end
  end

  def music_target_volume
    return 0.0 if @end_channel && @end_channel.playing?
    return MUSIC_TALK_VOLUME if krabs_talking?
    MUSIC_VOLUME
  end

  def krabs_talking?
    return false unless @state == :todo
    if @talk_instance
      @talk_instance.playing?
    else
      talking?
    end
  end

  def update
    @global_timer += 1
    update_music
    @animations.map! { |t| t > 0 ? t - 1 : 0 }

    case @state
    when :playing
      if @turn == "O"
        @computer_timer += 1
        if @computer_timer > 60
          computer_move
          @computer_timer = 0
        end
      end
    when :todo
      update_talk
    when :ending
      @end_timer += 1
      @state = @result if @end_timer >= END_DELAY
    end
  end

  def draw
    in_game = (@state == :playing || @state == :ending)

    if in_game && @game_bg
      @game_bg.draw(0, 0, 0, WIDTH.to_f / @game_bg.width, HEIGHT.to_f / @game_bg.height)
    elsif @bg_image
      @bg_image.draw(0, 0, 0, WIDTH.to_f / @bg_image.width, HEIGHT.to_f / @bg_image.height)
    else
      draw_rect(0, 0, WIDTH, HEIGHT, Gosu::Color.rgb(0, 150, 255), 0)
    end

    case @state
    when :menu         then draw_menu
    when :todo         then draw_todo
    when :level_select then draw_level_select
    when :playing, :ending then draw_game
    when :win
      if @level_cleared
        draw_end_screen(@win_img, "LEVEL CLEARED!", :green, "Click anywhere to return to Menu")
      else
        draw_end_screen(@win_img, "YOU WIN!", :green, "Click anywhere to play again")
      end
    when :lose
      draw_end_screen(@lose_img, "YOU LOSE!", :red, "Click anywhere to try again")
    when :draw
      draw_end_screen(@draw_img, "IT'S A DRAW!", :orange, "Click anywhere to play again")
    end
  end

  def draw_menu
    if @title_logo
      scale = 400.0 / @title_logo.width
      w = @title_logo.width * scale
      @title_logo.draw((WIDTH - w) / 2, 20, 2, scale, scale)
    end

    if @spongebob_img
      scale = 250.0 / @spongebob_img.width
      w = @spongebob_img.width * scale
      h = @spongebob_img.height * scale
      @spongebob_img.draw((WIDTH - w) / 2, MENU_SPONGEBOB_GROUND_Y - h, 1, scale, scale)
    end

    if @start_btn
      pulse_scale = 1.0 + (Math.sin(@global_timer * 0.1) * 0.05)
      base_scale = 220.0 / @start_btn.width
      final_scale = base_scale * pulse_scale

      w = @start_btn.width * final_scale
      x = (WIDTH - w) / 2
      y = 400

      @start_btn.draw(x, y, 3, final_scale, final_scale)
    end
  end

  def wrap_text(text, font, max_width)
    lines = []
    line = ""
    text.split(" ").each do |word|
      test = line.empty? ? word : "#{line} #{word}"
      if font.text_width(test) > max_width && !line.empty?
        lines << line
        line = word
      else
        line = test
      end
    end
    lines << line unless line.empty?
    lines
  end

  def start_talk_line(index)
    @talk_index = index
    @talk_wrapped = wrap_text(TALK_LINES[index], @tiny_font, BUBBLE[2] - 36)
    @talk_total = @talk_wrapped.sum { |l| l.length + 1 }
    @talk_chars = 0.0

    if @talk_snds && @talk_snds[@talk_index]
      @talk_instance.stop if @talk_instance
      @talk_instance = @talk_snds[@talk_index].play(1.0, 1.0)
    end
  end

  def talking?
    @talk_chars < @talk_total
  end

  def update_talk
    return unless talking?
    @talk_chars = [@talk_chars + TALK_SPEED, @talk_total.to_f].min
  end

  def draw_todo
    sponge_text_centered("HOW TO PLAY", WIDTH / 2, 8, 2, :big)

    sx = sy = sw = sh = nil
    if @talker_img
      scale = [230.0 / @talker_img.width, 300.0 / @talker_img.height].min
      sw = @talker_img.width * scale
      sh = @talker_img.height * scale
      hop = talking? ? -(Math.sin(@global_timer * 0.45).abs * 7) : 0
      sx = 25
      sy = HEIGHT - sh - 15 + hop
      @talker_img.draw(sx, sy, 2, scale, scale)
    end

    bx, by, bw, bh = BUBBLE
    edge = OUTLINE_BROWN
    paper = Gosu::Color.rgb(255, 255, 245)

    tip_x = sx ? sx + sw * 0.8 : bx - 20
    tip_y = sy ? [sy + sh * 0.25, by + bh + 20].max : by + bh + 20
    draw_triangle(bx + 21, by + bh + 2, edge, bx + 84, by + bh + 2, edge, tip_x - 3, tip_y + 4, edge, 2)
    draw_triangle(bx + 25, by + bh - 2, paper, bx + 80, by + bh - 2, paper, tip_x, tip_y, paper, 2.2)

    draw_rect(bx - 4, by - 4, bw + 8, bh + 8, edge, 2)
    draw_rect(bx, by, bw, bh, paper, 2.1)

    remaining = @talk_chars.to_i
    @talk_wrapped.each_with_index do |line, i|
      break if remaining <= 0
      @tiny_font.draw_text(line[0, remaining], bx + 18, by + 16 + i * 30, 3, 1.0, 1.0, TALK_TEXT_COLOR)
      remaining -= line.length + 1
    end

    counter = "#{@talk_index + 1}/#{TALK_LINES.length}"
    @tiny_font.draw_text(counter, bx + 18, by + bh - 32, 3, 0.8, 0.8, Gosu::Color.rgb(140, 120, 90))
    if !talking? && (@global_timer / 20) % 2 == 0
      ax = bx + bw - 34
      ay = by + bh - 30
      draw_triangle(ax, ay, edge, ax + 20, ay, edge, ax + 10, ay + 14, edge, 3)
    end

    unless talking?
      last = (@talk_index == TALK_LINES.length - 1)
      sponge_text_centered(last ? "Click to play!" : "Click to continue", bx + bw / 2, 315, 2, :small, OUTLINE_DARK, :white)
    end

    kx, ky, kw, kh = SKIP_BTN
    hover = over_rect?(mouse_x, mouse_y, kx, ky, kw, kh)
    draw_rect(kx, ky, kw, kh, Gosu::Color.rgba(0, 0, 0, hover ? 170 : 110), 2)
    plain_text_centered("SKIP", kx + kw / 2, ky + 4, 3, :tiny)
  end

  def draw_level_select
    sponge_text_centered("SELECT LEVEL", WIDTH / 2, 45, 2, :title)

    LEVELS.each do |lv|
      draw_rect(LEVEL_BTN_X, lv[:y], LEVEL_BTN_W, LEVEL_BTN_H, lv[:color], 3)

      if over_rect?(mouse_x, mouse_y, LEVEL_BTN_X, lv[:y], LEVEL_BTN_W, LEVEL_BTN_H)
        draw_rect(LEVEL_BTN_X, lv[:y], LEVEL_BTN_W, LEVEL_BTN_H, Gosu::Color.rgba(255, 255, 255, 80), 3)
      end

      sponge_text_centered(lv[:label], LEVEL_BTN_X + LEVEL_BTN_W / 2, lv[:y] + 8, 4, :big, OUTLINE_DARK, :white)
    end
  end

  def draw_game
    if @state == :playing && @turn == "X"
      idx = cell_at(mouse_x, mouse_y)
      if idx && @board[idx] == ""
        col = idx % 3
        row = idx / 3
        draw_rect(GRID_X + col * CELL_W + 4, GRID_Y + row * CELL_H + 4, CELL_W - 8, CELL_H - 8,
                  Gosu::Color.rgba(255, 255, 255, 70), 1)
      end
    end

    @board.each_with_index do |spot, index|
      next if spot == ""

      cx, cy = cell_center(index)
      img = @board_images[index]

      if img
        scale = (@animations[index] > 0) ? (15 - @animations[index]) / 15.0 : 1.0
        base_scale = [PIECE_SIZE / img.width, PIECE_SIZE / img.height].min
        final_scale = base_scale * scale

        w = img.width * final_scale
        h = img.height * final_scale
        img.draw(cx - (w / 2), cy - (h / 2), 2, final_scale, final_scale)
      else
        spot_color = (spot == "X") ? Gosu::Color::YELLOW : Gosu::Color::CYAN
        @title_font.draw_text(spot, cx - 25, cy - 35, 2, 1.0, 1.0, spot_color)
      end
    end

    draw_win_line if @win_line

    draw_rect(0, 0, WIDTH, 45, Gosu::Color.rgba(0, 0, 0, 150), 2)

    bx, by, bw, bh = BACK_BTN
    hover = over_rect?(mouse_x, mouse_y, bx, by, bw, bh)
    draw_rect(bx, by, bw, bh, Gosu::Color.rgba(255, 255, 255, hover ? 110 : 60), 3)
    plain_text_centered("MENU", bx + bw / 2, by + 3, 4, :tiny)

    if @state == :ending
      case @result
      when :win  then msg, tint = "You got three in a row!", :green
      when :lose then msg, tint = "Plankton wins this one...", :red
      else            msg, tint = "It's a tie!", :orange
      end
    elsif @turn == "X"
      msg = "It's your turn! (X)"
      tint = :green
    else
      msg = "Plankton is thinking... (O)"
      tint = :red
    end

    sponge_text_centered(msg, WIDTH / 2, 6, 3, :small, OUTLINE_DARK, tint)

    draw_rect(0, 455, WIDTH, 45, Gosu::Color.rgba(0, 0, 0, 150), 2)
    score = "Level: #{@level.to_s.upcase}   Finish: #{@level_wins}/#{WINS_TO_FINISH}   W:#{@total_wins}  L:#{@total_losses}  D:#{@total_draws}"
    plain_text_centered(score, WIDTH / 2, 462, 3, :tiny)
  end

  def draw_win_line
    x1, y1 = cell_center(@win_line[0])
    x2, y2 = cell_center(@win_line[2])

    progress = [@end_timer / 20.0, 1.0].min
    ex = x1 + (x2 - x1) * progress
    ey = y1 + (y2 - y1) * progress

    color = (@result == :win) ? Gosu::Color.rgba(0, 255, 0, 220) : Gosu::Color.rgba(255, 40, 40, 220)
    draw_thick_line(x1, y1, ex, ey, 10, color, 4)
  end

  def draw_thick_line(x1, y1, x2, y2, thickness, color, z)
    dx = x2 - x1
    dy = y2 - y1
    len = Math.sqrt(dx * dx + dy * dy)
    return if len == 0

    nx = -dy / len * thickness / 2.0
    ny =  dx / len * thickness / 2.0
    draw_quad(x1 + nx, y1 + ny, color,
              x1 - nx, y1 - ny, color,
              x2 - nx, y2 - ny, color,
              x2 + nx, y2 + ny, color, z)
  end

  def draw_end_screen(image, text, tint, subtitle)
    if image
      image.draw(0, 0, 1, WIDTH.to_f / image.width, HEIGHT.to_f / image.height)
    elsif @bg_image
      @bg_image.draw(0, 0, 1, WIDTH.to_f / @bg_image.width, HEIGHT.to_f / @bg_image.height)
    else
      draw_rect(0, 0, WIDTH, HEIGHT, Gosu::Color::BLACK, 1)
    end

    draw_rect(0, 0, WIDTH, HEIGHT, Gosu::Color.rgba(0, 0, 20, RESULT_DIM_ALPHA), 1.5)

    cx, cy, cw, ch = 75, 150, 600, 270
    draw_rect(cx, cy, cw, ch, Gosu::Color.rgba(10, 20, 55, RESULT_CARD_ALPHA), 2.1)

    sponge_text_centered(text, WIDTH / 2, cy + 18, 3, :title, OUTLINE_DARK, tint)

    chips = [["WINS", @total_wins, :green], ["LOSSES", @total_losses, :red], ["DRAWS", @total_draws, :blue]]
    chip_w = 160
    gap = 20
    start_x = (WIDTH - (chip_w * 3 + gap * 2)) / 2
    chips.each_with_index do |(label, value, color), i|
      x = start_x + i * (chip_w + gap)
      draw_rect(x, cy + 118, chip_w, 68, RESULT_COLORS[color], 3)
      plain_text_centered(label, x + chip_w / 2, cy + 121, 3.1, :tiny)
      plain_text_centered(value.to_s, x + chip_w / 2, cy + 148, 3.1, :small)
    end

    alpha = (190 + 65 * Math.sin(@global_timer * 0.1)).to_i
    plain_text_centered(subtitle, WIDTH / 2, cy + ch - 62, 3, :small, Gosu::Color.rgba(255, 255, 255, alpha))
  end

  def button_down(id)
    if id == Gosu::KB_ESCAPE
      if @state == :menu
        close
      else
        stop_end_sound
        @state = :menu
      end
    elsif id == Gosu::MS_LEFT
      handle_mouse_click(mouse_x, mouse_y)
    end
  end

  def handle_mouse_click(x, y)
    case @state
    when :menu
      rx, ry, rw, rh = start_button_rect
      if over_rect?(x, y, rx - 10, ry - 10, rw + 20, rh + 20)
        start_talk_line(0)
        @state = :todo
      end
    when :todo
      if over_rect?(x, y, *SKIP_BTN)
        @talk_instance.stop if @talk_instance
        @state = :level_select
      elsif talking?
        @talk_chars = @talk_total.to_f
      elsif @talk_index < TALK_LINES.length - 1
        start_talk_line(@talk_index + 1)
      else
        @talk_instance.stop if @talk_instance
        @state = :level_select
      end
    when :level_select
      LEVELS.each do |lv|
        if over_rect?(x, y, LEVEL_BTN_X, lv[:y], LEVEL_BTN_W, LEVEL_BTN_H)
          start_game(lv[:key])
          break
        end
      end
    when :playing
      bx, by, bw, bh = BACK_BTN
      if over_rect?(x, y, bx, by, bw, bh)
        stop_end_sound
        @state = :menu
        return
      end

      if @turn == "X"
        index = cell_at(x, y)
        if index && @board[index] == ""
          @board[index] = "X"
          @board_images[index] = @x_piece
          @animations[index] = 15
          play(@pop_snd)
          check_winner
          @turn = "O" if @state == :playing
        end
      end
    when :win, :lose, :draw
      stop_end_sound
      if @level_cleared
        @state = :menu
      else
        reset_game
        @state = :playing
      end
    end
  end

  def over_rect?(px, py, x, y, w, h)
    px >= x && px <= x + w && py >= y && py <= y + h
  end

  def cell_at(x, y)
    return nil unless x >= GRID_X && x < GRID_X + CELL_W * 3 &&
                      y >= GRID_Y && y < GRID_Y + CELL_H * 3
    col = ((x - GRID_X) / CELL_W.to_f).floor
    row = ((y - GRID_Y) / CELL_H.to_f).floor
    (row * 3) + col
  end

  def cell_center(index)
    col = index % 3
    row = index / 3
    [GRID_X + (col * CELL_W) + (CELL_W / 2.0), GRID_Y + (row * CELL_H) + (CELL_H / 2.0)]
  end

  def start_button_rect
    if @start_btn
      w = 220.0
      h = @start_btn.height * (w / @start_btn.width)
      [(WIDTH - w) / 2, 400, w, h]
    else
      [150, 380, 450, 100]
    end
  end

  def computer_move
    chosen_index = choose_computer_move
    return if chosen_index.nil?

    @board[chosen_index] = "O"
    @board_images[chosen_index] = @o_piece
    @animations[chosen_index] = 15
    play(@pop_snd)
    check_winner
    @turn = "X" if @state == :playing
  end

  def choose_computer_move
    empty_spots = []
    @board.each_with_index { |spot, index| empty_spots << index if spot == "" }
    return nil if empty_spots.empty?

    case @level
    when :easy
      empty_spots.sample
    when :medium
      find_winning_move("O") || find_winning_move("X") || empty_spots.sample
    else
      corners = [0, 2, 6, 8] & empty_spots
      find_winning_move("O") ||
        find_winning_move("X") ||
        (empty_spots.include?(4) ? 4 : nil) ||
        corners.sample ||
        empty_spots.sample
    end
  end

  def find_winning_move(symbol)
    WIN_LINES.each do |combo|
      marks = combo.map { |i| @board[i] }
      if marks.count(symbol) == 2 && marks.count("") == 1
        return combo[marks.index("")]
      end
    end
    nil
  end

  def check_winner
    WIN_LINES.each do |combo|
      a, b, c = combo.map { |i| @board[i] }
      if a != "" && a == b && b == c
        finish_round(a == "X" ? :win : :lose, combo)
        return
      end
    end

    finish_round(:draw, nil) unless @board.include?("")
  end

  def finish_round(result, line)
    @result = result
    @win_line = line
    @end_timer = 0
    @state = :ending

    case result
    when :win
      @total_wins += 1
      @level_wins += 1
      @level_cleared = true if @level_wins >= WINS_TO_FINISH
      play_end_sound(@win_snd)
    when :lose
      @total_losses += 1
      play_end_sound(@lose_snd)
    when :draw
      @total_draws += 1
      play_end_sound(@draw_snd)
    end
  end
end

TicTacToeWindow.new.show