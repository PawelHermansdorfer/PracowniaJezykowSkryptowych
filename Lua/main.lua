local dim_x = 10
local dim_y = 20
local board = {}

love.window.setMode(960, 960, { resizable = true, vsync = true })

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

local current_block
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


function clear_lines()
    local lines_cleared = 0
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
            lines_cleared = lines_cleared + 1

            for yy = y, 2, -1 do
                for x = 1, dim_x do
                    local src = get_block(x, yy - 1)
                    local dst = get_block(x, yy)

                    dst[1] = src[1]
                    dst[2] = src[2]
                end
            end

            for x = 1, dim_x do
                local top = get_block(x, 1)
                top[1] = 0
                top[2] = {0, 0, 0, 1}
            end

        else
            y = y - 1
        end
    end

    return lines_cleared
end

function handle_block_down_move()
    if is_valid_position(current_block, current_block_field_idx, current_block_x, current_block_y + 1) then
        current_block_y = current_block_y + 1
    else
        finish_block()
        local points = clear_lines()
        points = points * points
        score = score + (points*100)
        next_block()
    end
end


function love.keypressed(key)
    if key == "left" then
        local nx = current_block_x - 1
        if is_valid_position(current_block, current_block_field_idx, nx, current_block_y) then
            current_block_x = nx
        end

    elseif key == "right" then
        local nx = current_block_x + 1
        if is_valid_position(current_block, current_block_field_idx, nx, current_block_y) then
            current_block_x = nx
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

function love.update(dt)
    if finished then 
        finished = false
        clear_board()
        next_block()
        time_since_last_drop = 0
        score = 0
    else
        time_since_last_drop = time_since_last_drop + dt
        if time_since_last_drop >= 1 then
            time_since_last_drop = 0
            handle_block_down_move()
        end
    end

end


local ui_font = love.graphics.newFont(32)
love.graphics.setFont(ui_font)
function love.draw()
    local w, h = love.graphics.getDimensions()
    local cell_size = math.min(h / dim_y, (w * 0.7) / dim_x)

    love.graphics.clear(0, 0, 0)

    local text = "Score: " .. score
    local text_width = ui_font:getWidth(text)
    local text_height = ui_font:getHeight()

    local text_x = (dim_x*cell_size) + (w - dim_x*cell_size)/2 - text_width/2
    local text_y = 0
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(text, text_x, text_y)

    -- Draw board
    for y = 1, dim_y do
        for x = 1, dim_x do
            local block = get_block(x, y)
            if block and block[1] == 1 then
                love.graphics.setColor(block[2])
                love.graphics.rectangle(
                    "fill",
                    (x - 1) * cell_size,
                    (y - 1) * cell_size,
                    cell_size,
                    cell_size
                )
            end
        end
    end

    -- Draw block
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

end

next_block()
