const config = {
    type: Phaser.AUTO,
    scale: {
        mode:       Phaser.Scale.RESIZE,
        autoCenter: Phaser.Scale.CENTER_BOTH
    },
    physics: {
        default: 'arcade',
        arcade: {
            gravity: { y: 1000 },
            debug: false
        }
    },
    backgroundColor: '#00AAAA',
    scene: {
        create: create,
        update: update,
        preload: preload,
    }
};
new Phaser.Game(config);


let player;
let start_x;
let start_y;
let cursors;
let enemies;
let platforms;
let obstacles;
let coins;

let jump_vel;
let high_jump_vel;
let move_vel;

let enemy_move_vel;

let doors;

let score = 0;
let score_plus = 0;
let score_text;

let lives = 3;
let lives_text;

let level_layout;
let level = 1;
let max_level = 2;

function
rand(min, max)
{
    return Math.floor(Math.random() * (max - min + 1)) + min;
}


function
generate_level()
{
    let w = 20;
    let h = 9;
    const grid = Array.from({ length: h }, () => Array(w).fill('0'));

    ////////////////////////////////////////
    // X 1 M C I
    let coin1 = rand(1, w-2);
    let coin2 = rand(1, w-2);
    while(coin2 == coin1)
    {
        coin2 = rand(1, w-2);
    }
    let coin3 = rand(1, w-2);
    while(coin3 == coin1 || coin3 == coin2)
    {
        coin3 = rand(1, w-2);
    }

    let y;
    let prev_y = rand(2, h-1);
    for(let x = 0; x < w; ++x)
    {
        let place_player   = (x == 0);
        let place_doors    = (x == w-1);
        let empty_above    = !place_player && !place_doors;

        let gap            = empty_above && (Math.random() > 0.85)
        let same_y         = (!(x == 0) && (Math.random() > 0.8)) || place_doors;
        let place_obstacle = !gap && empty_above && (Math.random() > 0.85);
        let place_enemy    = !gap && empty_above && !place_obstacle && (Math.random() > 0.8);

        y = rand(Math.max(prev_y - 2, 2), Math.min(prev_y + 1, h-2));
        if(same_y) y = prev_y;

        let place_coin = false;
        let coin_y = y - 1;
        if(x == coin1 || x == coin2 || x == coin3)
        {
            place_coin = true;
            if(place_obstacle || place_enemy) coin_y -= 1;
            if(coin_y < 0)
            {
                y -= 1;
                coin_y -= 1;
            }
        }

        if(!gap) grid[y][x] = '1';
        if(place_player) grid[y-1][x] = 'X';
        if(place_doors)  grid[y-1][x] = 'M';
        if(place_obstacle) grid[y-1][x] = 'I';
        if(place_enemy) grid[y-1][x]    = 'E';
        if(place_coin) grid[coin_y][x]  = 'C';

        prev_y = y;
    }

    return(grid.map(row => row.join(' ')).join('\n') + '\n');
}


function
rectOverlap(a, b)
{
    return(Phaser.Geom.Intersects.RectangleToRectangle(a.getBounds(), b.getBounds()));
}


function
createRect(scene, x, y, w, h, color, group)
{
    const rect = scene.add.rectangle(x, y, w, h, color);
    rect.setOrigin(0.5, 0.5);
    scene.physics.add.existing(rect, true);
    rect.body.setSize(w, h);
    rect.body.updateFromGameObject();
    group.add(rect);
    return(rect);
}


function
finish_level()
{

    score += score_plus;
    score_plus = 0;
    score_text.setText('Score: ' + score);

    lives = 3;
    lives_text.setText('❤️'.repeat(lives));

    level += 1;
    next_level(player.scene);
    this.scene.restart();
}


function
collect_coins(player, coin)
{
    coin.destroy();
    score_plus += 1;
    score_text.setText('Score: ' + score + ' + ' + score_plus);
}


function
hit_enemy(player, enemy)
{
    let player_bottom = player.body.y + player.body.height;
    let enemy_top = enemy.body.y;

    let wasAbove = (player_bottom <= enemy_top);
    let is_above = (player.body.y < enemy.body.y);
    let kill_enemy = wasAbove && is_above;

    if(kill_enemy)
    {
        enemy.left_foot.destroy();
        enemy.right_foot.destroy();
        enemy.destroy();

        player.body.setVelocityY(-high_jump_vel);
    }
    else
    {
        die(player.scene);
    }
}

function 
die(scene)
{
    lives -= 1;
    score_plus = 0;

    if(lives <= 0)
    {
        lives = 3;
        score = 0;
        level = 1;
        next_level(player.scene);
        score_text.setText('Score: ' + score + ' + ' + score_plus);
    }

    lives_text.setText('❤️'.repeat(lives));
    scene.scene.restart();
}


function
load_level(scene, layout)
{
    let w = scene.scale.width;
    let h = scene.scale.height;

    // Find size of level
    let dim_x = 0;
    let current_dim_x = 0;
    let dim_y = 0;
    for(const ch of layout)
    {
        if (ch === '0' || ch === '1' || ch === 'X' || ch === 'M' || ch === 'I' || ch === 'C' || ch === 'E')
        {
            current_dim_x += 1;
        }
        else if (ch === '\n')
        {
            dim_x = Math.max(dim_x, current_dim_x);
            current_dim_x = 0;
            dim_y += 1;
        }
    }
    let tile_dim_x = (w/(dim_x));
    let tile_dim_y = (h/(dim_y));

    // Load level
    let result_player;
    let result_enemies   = scene.physics.add.group();
    let result_platforms = scene.physics.add.staticGroup();
    let result_doors     = scene.physics.add.staticGroup();
    let result_obstacles = scene.physics.add.staticGroup();
    let result_coins     = scene.physics.add.staticGroup();
    let result_jump_vel  = Math.sqrt(2*scene.physics.world.gravity.y *  2*tile_dim_y * 1.1);
    let result_high_jump_vel = Math.sqrt(2*scene.physics.world.gravity.y *  3*tile_dim_y * 1.1);
    let result_move_vel = w/5;
    let result_start_x  = 0;
    let result_start_y  = 0;
    let pos_x = 0;
    let pos_y = 0;
    for(const ch of layout)
    {
        let tile_center_x = pos_x*tile_dim_x + tile_dim_x/2;
        let tile_center_y = pos_y*tile_dim_y + tile_dim_y/2;

        if(ch === '1')
        {
            createRect(scene, tile_center_x, tile_center_y, tile_dim_x, tile_dim_y, 0x00ff00, result_platforms);
            pos_x += 1;
        }
        else if(ch === 'I')
        {
            createRect(scene, tile_center_x, tile_center_y, tile_dim_x/2, tile_dim_y, 0x333333, result_obstacles);
            pos_x += 1;
        }
        else if(ch === 'C')
        {
            let radius = Math.min(tile_dim_x, tile_dim_y) / 6;
            const coin = scene.add.circle(tile_center_x, tile_center_y, radius, 0xFFFF00);
            scene.physics.add.existing(coin, true);
            result_coins.add(coin);
            pos_x += 1;
        }
        else if(ch === 'X')
        {
            let size = Math.min(tile_dim_x/4, tile_dim_y/2);
            result_player = scene.add.rectangle(tile_center_x, tile_center_y, size, size*2, 0x0000ff);
            scene.physics.add.existing(result_player);
            result_player.body.setDragX(5000);

            result_start_x = tile_center_x;
            result_start_y = tile_center_y;
            pos_x += 1;
        }
        else if(ch === 'E')
        {
            let size = Math.min(tile_dim_x/2, tile_dim_y/4);
            let x_size = size * 2;
            let y_size = size;
            let enemy = scene.add.rectangle(tile_center_x, tile_center_y, x_size, y_size, 0xff0000);
            scene.physics.add.existing(enemy);
            enemy.body.setCollideWorldBounds(true);
            enemy.direction = 1;

            let foot_size = size / 2;

            let left_foot = scene.add.rectangle(tile_center_x - size, tile_center_y + size, foot_size, 2, 0x000000);
            left_foot.visible = false;
            left_foot.isSensor = true;

            let right_foot = scene.add.rectangle(tile_center_x + size, tile_center_y + size, foot_size, 2, 0x000000);
            right_foot.visible = false;
            right_foot.isSensor = true;

            enemy.size = size;
            enemy.left_foot = left_foot;
            enemy.right_foot = right_foot;
            result_enemies.add(enemy);
            pos_x += 1;
        }
        else if(ch === 'M')
        {
            createRect(scene, tile_center_x, tile_center_y, tile_dim_x, tile_dim_y, 0x020202, result_doors);
            pos_x += 1;
        }
        else if(ch === '0')
        {
            pos_x += 1;
        }
        else if (ch === '\n')
        {
            pos_x = 0;
            pos_y += 1;
        }
    }

    // Pack and send
    scene.physics.add.collider(result_player, result_platforms);
    scene.physics.add.collider(result_player, result_obstacles);

    scene.physics.add.overlap(result_player, result_doors, finish_level, 0, scene);
    scene.physics.add.overlap(result_player, result_coins, collect_coins, 0, scene);

    scene.physics.add.collider(result_enemies, result_platforms);
    scene.physics.add.collider(result_enemies, result_obstacles);
    scene.physics.add.collider(result_player, result_enemies, hit_enemy, 0, scene);

    let result = [
        result_player,
        result_enemies,
        result_platforms,
        result_doors,
        result_obstacles,
        result_coins,
        result_jump_vel,
        result_high_jump_vel,
        result_move_vel,
        result_start_x,
        result_start_y,
    ];
    return result;
}

function
next_level(scene)
{
    if(level > max_level)
    {
        level_layout = generate_level();
    }
    else
    {
        level_layout = scene.cache.text.get('level_' + level);
    }
}


////////////////////////////////////////
function preload()
{
    this.load.text('level_1', 'levels/level_1.txt');
    this.load.text('level_2', 'levels/level_2.txt');
}

////////////////////////////////////////
function
create()
{
    let w = this.scale.width;
    let h = this.scale.height;

    cursors = this.input.keyboard.createCursorKeys();

    if(!level_layout) level_layout = this.cache.text.get('level_' + level);
    let level_data = load_level(this, level_layout);

    player    = level_data[0];
    enemies   = level_data[1];
    platforms = level_data[2];
    doors     = level_data[3];
    obstacles = level_data[4];
    coins     = level_data[5];
    jump_vel  = level_data[6];
    high_jump_vel = level_data[7];
    move_vel  = level_data[8];
    start_x = level_data[9];
    start_y = level_data[10];
    enemy_move_vel = move_vel / 2;

    score_text = this.add.text(w/2, h*0.1, 'Score: ' + score, { fontSize: '46px', fill: '#ffffff' });
    score_text.setOrigin(0.5, 0.5);
    score_text.setScrollFactor(0);

    lives_text = this.add.text(0, 0, '❤️'.repeat(lives), { fontSize: '48px', fill: '#ffffff' });
    lives_text.setScrollFactor(0);
}


////////////////////////////////////////
function
update()
{
    let w = this.scale.width;
    let h = this.scale.height;

    // Player
    let x_dir = 0;
    if(cursors.right.isDown)
    {
        x_dir += 1;
    }
    if(cursors.left.isDown)
    {
        x_dir -= 1;
    }
    player.body.setVelocityX(x_dir * move_vel);


    if(cursors.up.isDown && player.body.touching.down)
    {
        player.body.setVelocityY(-jump_vel);
    }


    if(player.y > h + 200)
    {
        die(this);
    }

    // Enemies
    enemies.children.iterate(function(enemy)
    {
        let dir = enemy.direction;

        if(enemy.body.blocked.left)
        {
            enemy.direction = 1;
        }
        else if (enemy.body.blocked.right)
        {
            enemy.direction = -1;
        }


        // Feet
        let left_grounded = false;
        let right_grounded = false;
        platforms.children.iterate(function(p) {
            if (rectOverlap(enemy.left_foot, p)) left_grounded = true;
            if (rectOverlap(enemy.right_foot, p)) right_grounded = true;
        });

        if(enemy.direction === 1 && !right_grounded) 
        {
            enemy.direction = -1;
        }

        if(enemy.direction === -1 && !left_grounded)
        {
            enemy.direction = 1;
        }

        enemy.body.setVelocityX(enemy.direction * enemy_move_vel);

        enemy.left_foot.x = enemy.x - enemy.size;
        enemy.left_foot.y = enemy.y + enemy.size;

        enemy.right_foot.x = enemy.x + enemy.size;
        enemy.right_foot.y = enemy.y + enemy.size;
    });
}
