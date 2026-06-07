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
        update: update
    }
};
new Phaser.Game(config);


let level_layout = ` 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                     0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                     0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                     0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                     0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                     0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                     0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 M
                     0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1
                     0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                     0 0 0 0 0 0 1 1 1 0 0 0 I 0 0 0 1 1 0 0 0
                     X 0 0 0 0 0 0 0 0 0 0 0 I 0 0 0 0 0 0 0 0
                     1 1 1 1 1 0 0 0 0 0 1 1 1 1 1 0 0 0 0 0 0`;


let player;
let cursors;
let platforms;
let obstacles;

let jump_vel;
let move_vel;

let doors;


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
    this.scene.restart();
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
        if (ch === '0' || ch === '1' || ch === 'X' || ch === 'M')
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
    let tile_dim_y = (h/(dim_y+1));

    // Load level
    let result_player;
    let result_platforms = scene.physics.add.staticGroup();
    let result_doors     = scene.physics.add.staticGroup();
    let result_obstacles = scene.physics.add.staticGroup();
    let result_jump_vel = Math.sqrt(2*scene.physics.world.gravity.y *  2*tile_dim_y * 1.1);
    let result_move_vel = tile_dim_x * 3;
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
        else if(ch === 'X')
        {
            result_player = scene.add.rectangle(tile_center_x, tile_center_y, 20, 40, 0x0000ff);
            scene.physics.add.existing(result_player);
            result_player.body.setDragX(5000);
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
    let result = [
        result_player,
        result_platforms,
        result_doors,
        result_obstacles,
        result_jump_vel,
        result_move_vel,
    ];
    return result;
}



////////////////////////////////////////
function
create()
{
    let w = this.scale.width;
    let h = this.scale.height;

    cursors = this.input.keyboard.createCursorKeys();

    let level_data = load_level(this, level_layout);
    player = level_data[0];
    platforms = level_data[1];
    doors = level_data[2];
    obstacles = level_data[3]
    jump_vel = level_data[4];
    move_vel = level_data[5];
}


////////////////////////////////////////
function
update()
{
    let w = this.scale.width;
    let h = this.scale.height;

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


    if (cursors.up.isDown && player.body.touching.down)
    {
        player.body.setVelocityY(-jump_vel);
    }


    if(player.y > h + 200)
    {
        this.scene.restart();
    }
}
