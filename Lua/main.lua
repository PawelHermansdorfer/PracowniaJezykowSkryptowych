local dim_x = 10
local dim_y = 20
local board = {}

local move_sound = love.audio.newSource("sound_1.wav", "static")
move_sound:setVolume(0.5)
local lock_block_sound = love.audio.newSource("sound_2.wav", "static")
lock_block_sound:setVolume(0.5)
local clear_row_sound = love.audio.newSource("sound_3.wav", "static")
clear_row_sound:setVolume(0.5)
local loose_sound = love.audio.newSource("sound_4.wav", "static")
loose_sound:setVolume(1)
function play_sound(sound)
    local s = sound:clone()
    s:play()
end

love.window.setMode(720, 720, { resizable = true, vsync = true })

local SAVE_FILE = "save.txt"
local save_button = {}
local load_button = {}

function xy_in_rect(px, py, r)
    return px >= r.x and px <= r.x + r.w and
           py >= r.y and py <= r.y + r.h
end

function clear_board()
    for y = 1, dim_y do
        for x = 1, dim_x do
            board[(y - 1) * dim_x + x] = {0, {0, 0, 0, 1}}
        end
    end
end
clear_board()

local blocks = {
    -- Bar
    {
        color = {0.9, 0.1, 0.1, 1.0},
        origin_x = 2,
        origin_y = 1,
        fields = {
            {
                {0, 0, 0, 0},
                {1, 1, 1, 1},
                {0, 0, 0, 0},
                {0, 0, 0, 0},
            },
            {
                {0, 0, 1, 0},
                {0, 0, 1, 0},
                {0, 0, 1, 0},
                {0, 0, 1, 0},
            },
            {
                {0, 0, 0, 0},
                {0, 0, 0, 0},
                {1, 1, 1, 1},
                {0, 0, 0, 0},
            },
            {
                {0, 1, 0, 0},
                {0, 1, 0, 0},
                {0, 1, 0, 0},
                {0, 1, 0, 0},
            },
        }
    },

    -- Cube
    {
        color = {0.9, 0.9, 0.1, 1.0},
        origin_x = 1,
        origin_y = 1,
        fields = {
            {
                {1, 1},
                {1, 1},
            },
        }
    },

    -- Small L
    {
        color = {0.5, 0, 0.5, 1.0},
        origin_x = 1,
        origin_y = 1,
        fields = {
            {
                {1, 0},
                {1, 1},
            },
            {
                {1, 1},
                {1, 0},
            },
            {
                {1, 1},
                {0, 1},
            },
            {
                {0, 1},
                {1, 1},
            },
        }
    },

    -- Big L right
    {
        color = {0.1, 0.3, 0.7, 1.0},
        origin_x = 1,
        origin_y = 1,
        fields = {
            {
                {1, 0, 0},
                {1, 0, 0},
                {1, 1, 0},
            },
            {
                {1, 1, 1},
                {1, 0, 0},
                {0, 0, 0},
            },
            {
                {0, 1, 1},
                {0, 0, 1},
                {0, 0, 1},
            },
            {
                {0, 0, 0},
                {0, 0, 1},
                {1, 1, 1},
            },
        }
    },

    -- Big L left
    {
        color = {0.1, 0.7, 0.3, 1.0},
        origin_x = 1,
        origin_y = 1,
        fields = {
            {
                {0, 0, 1},
                {0, 0, 1},
                {0, 1, 1},
            },
            {
                {0, 0, 0},
                {1, 0, 0},
                {1, 1, 1},
            },
            {
                {1, 1, 0},
                {1, 0, 0},
                {1, 0, 0},
            },
            {
                {1, 1, 1},
                {0, 0, 1},
                {0, 0, 0},
            },
        }
    },

    -- Part cross
    {
        color = {1, 0.7, 0.8, 1.0},
        origin_x = 1,
        origin_y = 1,
        fields = {
            {
                {1, 1, 1},
                {0, 1, 0},
                {0, 0, 0},
            },
            {
                {0, 0, 1},
                {0, 1, 1},
                {0, 0, 1},
            },
            {
                {0, 0, 0},
                {0, 1, 0},
                {1, 1, 1},
            },
            {
                {1, 0, 0},
                {1, 1, 0},
                {1, 0, 0},
            },
        }
    },

    -- Z left
    {
        color = {1, 0.55, 0.0, 1.0},
        origin_x = 1,
        origin_y = 1,
        fields = {
            {
                {1, 1, 0},
                {0, 1, 1},
                {0, 0, 0},
            },
            {
                {0, 1, 0},
                {1, 1, 0},
                {1, 0, 0},
            },
        }
    },

    -- Z right
    {
        color = {0.5, 1.0, 1.0, 1.0},
        origin_x = 1,
        origin_y = 1,
        fields = {
            {
                {0, 1, 1},
                {1, 1, 0},
                {0, 0, 0},
            },
            {
                {1, 0, 0},
                {1, 1, 0},
                {0, 1, 0},
            },
        }
    },
}

local current_block = nil
local current_block_field_idx = 1
local current_block_x = 0
local current_block_y = 0
local time_since_last_drop = 0

local score = 0
local finished = false

math.randomseed(os.time())

local function get_block(x, y)
    if x < 1 or x > dim_x or y < 1 or y > dim_y then
        return nil
    end
    return board[(y - 1) * dim_x + x]
end

function is_valid_position(block, field_idx, pos_x, pos_y)
    local shape = block.fields[field_idx]

    for y = 1, #shape do
        for x = 1, #shape[y] do
            if shape[y][x] == 1 then
                local bx = pos_x + x
                local by = pos_y + y

                if bx < 1 or bx > dim_x or by < 1 or by > dim_y then
                    return false
                end

                local block = get_block(bx, by)
                if block and block[1] == 1 then
                    return false
                end
            end
        end
    end

    return true
end

function next_block()
    current_block = blocks[math.random(1, #blocks)]
    current_block_field_idx = 1
    current_block_x = 5 - current_block.origin_x
    current_block_y = 0 - current_block.origin_y


    local shape = current_block.fields[current_block_field_idx]
    for y = 1, #shape do
        for x = 1, #shape[y] do
            if shape[y][x] == 1 then
                local bx = current_block_x + x
                local by = current_block_y + y

                local block = get_block(bx, by)
                if block and block[1] == 1 then
                    finished = true
                    break
                end
            end
        end
    end
end
next_block()

function finish_block()
    local shape = current_block.fields[current_block_field_idx]
    for y = 1, #shape do
        for x = 1, #shape[y] do
            if shape[y][x] == 1 then
                local bx = current_block_x + x
                local by = current_block_y + y

                local block = get_block(bx, by)
                if block then
                    block[1] = 1
                    block[2] = current_block.color
                end
            end
        end
    end
end

local clearing_lines = false
local lines_to_clear = {}
local clearing_lines_t = 0
local clearing_lines_total_t = 1

function easeInBack(x)
    local c1 = 1.70158
    local c3 = c1 + 1

    return c3 * x * x * x - c1 * x * x
end

function is_row_clearing(y)
    local result = false
    for _, row_idx in ipairs(lines_to_clear) do
        if row_idx == y then
            result = true
            break
        end
    end
    return result
end

function clear_lines()
    local y = dim_y

    while y >= 1 do
        local full = true

        for x = 1, dim_x do
            local cell = get_block(x, y)
            if not cell or cell[1] == 0 then
                full = false
                break
            end
        end

        if full then
            table.insert(lines_to_clear, y)
            clearing_lines = true
        end
        y = y - 1
    end
end

function handle_block_down_move()
    if is_valid_position(current_block, current_block_field_idx, current_block_x, current_block_y + 1) then
        current_block_y = current_block_y + 1
        play_sound(move_sound)
    else
        finish_block()
        clear_lines()
        next_block()
        play_sound(lock_block_sound)
    end
end


function save_game()
    local block_index = 1

    for i, block in ipairs(blocks) do
        if block == current_block then
            block_index = i
            break
        end
    end

    local data = ""

    data = data .. score .. "\n"
    data = data .. block_index .. "\n"
    data = data .. current_block_field_idx .. "\n"
    data = data .. current_block_x .. "\n"
    data = data .. current_block_y .. "\n"

    for y = 1, dim_y do
        for x = 1, dim_x do
            local b = get_block(x, y)

            data = data .. b[1]  .. "," .. b[2][1] .. "," .. b[2][2] .. "," .. b[2][3] .. "," .. b[2][4] .. "\n"
        end
    end

    love.filesystem.write("save.txt", data)
end

function load_game()
    if not love.filesystem.getInfo("save.txt") then
        return false
    end

    local data = love.filesystem.read("save.txt")

    local lines = {}

    for line in data:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    local idx = 1

    score = tonumber(lines[idx]); idx = idx + 1

    local block_index = tonumber(lines[idx]); idx = idx + 1
    current_block = blocks[block_index]

    current_block_field_idx = tonumber(lines[idx]); idx = idx + 1
    current_block_x = tonumber(lines[idx]); idx = idx + 1
    current_block_y = tonumber(lines[idx]); idx = idx + 1

    for y = 1, dim_y do
        for x = 1, dim_x do
            local line = lines[idx]
            idx = idx + 1

            local values = {}

            for v in line:gmatch("[^,]+") do
                table.insert(values, tonumber(v))
            end

            local b = get_block(x, y)

            b[1] = values[1]
            b[2] = {
                values[2],
                values[3],
                values[4],
                values[5]
            }
        end
    end

    return true
end

function love.keypressed(key)
    if not clearing_lines then
        if key == "left" then
            local nx = current_block_x - 1
            if is_valid_position(current_block, current_block_field_idx, nx, current_block_y) then
                current_block_x = nx
                play_sound(move_sound)
            end
        elseif key == "right" then
            local nx = current_block_x + 1
            if is_valid_position(current_block, current_block_field_idx, nx, current_block_y) then
                current_block_x = nx
                play_sound(move_sound)
            end
        elseif key == "down" then
            handle_block_down_move()
            time_since_last_drop = 0
        elseif key == "up" then
            local next_idx = 1 + (current_block_field_idx % #current_block.fields)
            if is_valid_position(current_block, next_idx, current_block_x, current_block_y) then
                current_block_field_idx = next_idx
            end
        end
    end
end

function love.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    if xy_in_rect(x, y, save_button) then
        save_game()
    elseif xy_in_rect(x, y, load_button) then
        load_game()
    end
end

function love.update(dt)
    if clearing_lines then
        clearing_lines_t = clearing_lines_t + dt
        if clearing_lines_t >= clearing_lines_total_t then
            -- Clear
            local y = dim_y
            while y >= 1 do
                local full = true

                for x = 1, dim_x do
                    local cell = get_block(x, y)
                    if not cell or cell[1] == 0 then
                        full = false
                        break
                    end
                end

                if full then
                    for yy = y, 2, -1 do
                        for x = 1, dim_x do
                            local src = get_block(x, yy - 1)
                            local dest = get_block(x, yy)

                            dest[1] = src[1]
                            dest[2] = src[2]
                        end
                    end

                    for x = 1, dim_x do
                        local top = get_block(x, 1)
                        top[1] = 0
                        top[2] = {0, 0, 0, 0}
                    end
                else
                    y = y - 1
                end
            end

            score = score + (#lines_to_clear * #lines_to_clear * 100)
            clearing_lines = false
            clearing_lines_t = 0
            lines_to_clear = {}

            play_sound(clear_row_sound)
        end
    else
        if finished then 
            finished = false
            clear_board()
            next_block()
            time_since_last_drop = 0
            score = 0
            play_sound(loose_sound)
        else
            time_since_last_drop = time_since_last_drop + dt
            if time_since_last_drop >= 1 then
                time_since_last_drop = 0
                handle_block_down_move()
            end
        end
    end
end


local ui_font = love.graphics.newFont(32)
love.graphics.setFont(ui_font)
function love.draw()
    local w, h = love.graphics.getDimensions()
    local cell_size = math.min(h / dim_y, (w * 0.7) / dim_x)
    local center_bar = (dim_x*cell_size)
    local right_center = center_bar + (w - dim_x*cell_size)/2 

    love.graphics.clear(0, 0, 0)

    local text = "Score: " .. score
    local text_width = ui_font:getWidth(text)
    local text_height = ui_font:getHeight()

    local text_x =  right_center - text_width/2
    local text_y = 0
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(text, text_x, text_y)

    -- Draw board
    for y = 1, dim_y do
        local a = 1.0
        local offset_y = 0
        if is_row_clearing(y) then
            local t = (clearing_lines_t/clearing_lines_total_t)
            a = 1 - t
            offset_y = easeInBack(t)*2 * cell_size*5
        end

        for x = 1, dim_x do
            local block = get_block(x, y)
            if block and block[1] == 1 then
                love.graphics.setColor(block[2][1],
                                       block[2][2],
                                       block[2][3],
                                       a)
                love.graphics.rectangle(
                    "fill",
                    (x - 1) * cell_size,
                    (y - 1) * cell_size + offset_y,
                    cell_size, 
                    cell_size
                )
            end
        end
    end

    -- Draw block
    if not clearing_lines then
        local shape = current_block.fields[current_block_field_idx]
        for y = 1, #shape do
            for x = 1, #shape[y] do
                if shape[y][x] == 1 then
                    love.graphics.setColor(current_block.color)
                    love.graphics.rectangle(
                        "fill",
                        (current_block_x + x - 1) * cell_size,
                        (current_block_y + y - 1) * cell_size,
                        cell_size,
                        cell_size
                    )
                end
            end
        end
    end

    -- Draw borders
    for y = 1, dim_y do
        for x = 1, dim_x do
            love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
            love.graphics.rectangle(
                "line",
                (x - 1) * cell_size,
                (y - 1) * cell_size,
                cell_size,
                cell_size
            )
        end
    end

    -- Save/load
    local button_width = w * 0.3 * 0.9

    save_button.x = right_center - button_width/2
    save_button.y = 80
    save_button.w = button_width
    save_button.h = 50

    love.graphics.setColor(0.2, 0.6, 0.2)
    love.graphics.rectangle(
        "fill",
        save_button.x,
        save_button.y,
        save_button.w,
        save_button.h
    )

    love.graphics.setColor(1,1,1)
    love.graphics.printf(
        "SAVE",
        save_button.x,
        save_button.y + 12,
        save_button.w,
        "center"
    )

    load_button.x = right_center - button_width/2
    load_button.y = 150
    load_button.w = button_width
    load_button.h = 50

    love.graphics.setColor(0.2, 0.2, 0.8)
    love.graphics.rectangle(
        "fill",
        load_button.x,
        load_button.y,
        load_button.w,
        load_button.h
    )

    love.graphics.setColor(1,1,1)
    love.graphics.printf(
        "LOAD",
        load_button.x,
        load_button.y + 12,
        load_button.w,
        "center"
    )
end
